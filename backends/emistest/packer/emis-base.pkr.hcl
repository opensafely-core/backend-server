# Required Packer plugins
packer {
  required_plugins {
    amazon = {
      version = ">= 1.8.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

# Variables for customization
variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

variable "build_version" {
  type    = string
  default = "latest"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "user" {
  type    = string
  default = "unknown"
}

variable "backend_server_branch" {
  type    = string
  default = "main"
}


# Data source to find the latest 24.04 Ubuntu AMI
data "amazon-ami" "ubuntu" {
  filters = {
    name                = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = ["099720109477"]  # Canonical
  region      = var.aws_region
}

# Define the builders
source "amazon-ebs" "emis-base" {
  ami_name      = "emis-base-${formatdate("YYYYMMDD-hhmmss", timestamp())}"
  instance_type = var.instance_type
  region        = var.aws_region
  source_ami    = data.amazon-ami.ubuntu.id

  ssh_username = "ubuntu"

  # Tag the AMI
  tags = {
    Name        = "${var.user}-emis-base"
    Environment = "test"
    Builder     = "packer"
    BuildVersion  = var.build_version
    BuildTime   = timestamp()
  }

  # Tag the snapshot
  snapshot_tags = {
    Name = "emis-base-snapshot"
  }
}

source "vagrant" "emis-test" {
  communicator = "ssh"
  source_path = "bento/ubuntu-24.04"
  provider = "virtualbox"
  output_dir = "vagrant_output"
  # add_force = true
  skip_add = true
}

# Data source to retrieve config from parameter store
data "amazon-parameterstore" "test" {
  name = "/emis/test"
  with_decryption = false
}

data "amazon-parameterstore" "test1" {
  name = "/emis/test1"
  with_decryption = false
}

# Define how to build
build {
  sources = [
    "source.amazon-ebs.emis-base", 
    "source.vagrant.emis-test"
  ]

  # Create /srv folder for backend-server
  provisioner "shell" {
    # Allows running as root: https://developer.hashicorp.com/packer/docs/provisioners/shell#sudo-example
    execute_command = "echo 'packer' | sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
    environment_vars = [
      "TEST=true",  # means airlock/install.sh will create test certificates for airlock
    ]
    inline = [
      "mkdir -p /srv/",
      "git clone https://github.com/opensafely-core/backend-server.git /srv/backend-server",
      "cd /srv/backend-server",
      "git checkout ${var.backend_server_branch}",
      "./scripts/bootstrap.sh emistest",
      "./backends/emistest/scripts/install_aws_cli.sh",
      "just manage",
      # note just manage doesn't upgrade anything; we don't use just apt-upgrade here
      # because it's deliberately interactive and intended for a running backend instance
      "apt update && apt upgrade -y && apt autoremove -y"
    ]
  }

  # Clean up and set cloud-init (different for vagrant/aws)
  provisioner "shell" {
    # Allows running as root: https://developer.hashicorp.com/packer/docs/provisioners/shell#sudo-example
    execute_command = "echo 'packer' | sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
    environment_vars = [
      "BACKEND=emistest",
      "CLOUD_INIT_SRC_DIR=/srv/backend-server/backends/emistest/cloud-init-vagrant",
      "COPY_CLOUD_INIT=true"
    ]
    only = ["vagrant.emis-test"]
    inline = [
      # clean up, set cloud-init
      "/srv/backend-server/backends/emistest/scripts/clean-image.sh",
    ]
  }

  provisioner "shell" {
    # Allows running as root: https://developer.hashicorp.com/packer/docs/provisioners/shell#sudo-example
    execute_command = "echo 'packer' | sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
    environment_vars = [
      "BACKEND=emistest",
      "CLOUD_INIT_SRC_DIR=/srv/backend-server/backends/emistest/cloud-init-emis"
    ]
    only = ["amazon-ebs.emis-base"]
    inline = [
      # clean up, set cloud-init
      "/srv/backend-server/backends/emistest/scripts/clean-image.sh",
    ]
  }

  # Output build info
  post-processor "manifest" {
    output     = "packer/manifest.json"
    strip_path = true
  }
}
