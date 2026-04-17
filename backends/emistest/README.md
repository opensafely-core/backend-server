# EMIS backend

Builds an EC2 AMI for running an EMIS backend. Currently configured to set up an `emistest` backend, using the
same configuration as for the official OpenSAFELY test backend.

We use packer to build the AMI, and the same shell scripts used for the test backend to provision.


## Install Packer
```
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install packer
```

Verify installation
```
packer version
```

## Install vagrant and virtualbox

(Only required for testing with vagrant)

```
apt install vagrant virtualbox
```

### Set AWS credentials (using dev role credentials)

```
just aws-configure
```

This will add the credentials manually to ~/.aws/credentials. Set default region to eu-west-1.

If it doesn't ask to configure the session token, set it with:

```
just aws-session-token
```

Note that our dev account credentials are temporary; if commands fail with an error similar to
`Error: Datasource.Execute failed: validating provider credentials...`, re-run
the configure commands.

## Set up packer

### Initialize
```
just packer-init
``` 

### Validate the template
```
just packer-validate
```

## Running on aws

### Build the AMI
```
just packer-build-aws
```

It will clone this repo in order to run the backend management just recipes (in
the top-level justfile). By default, it uses the `main` branch. To use a different branch, run:

```
just packer-build-aws -var backend_server_branch=<my branch>
```

When it's done, it will write build details to `packer/manifest.json`.

To build using a larger temporary instance (which will make the build a bit faster -
but not much, as most of the time is spent waiting for the AMI to become ready):

```
just packer-build-aws -var instance_type=t3.medium
```

Note you may need different credentials in order to use larger instance types.

## Launch an instance

```
just launch-instance
```

Note: this requires admin credentials.

This will use the build data at packer/manifest.json to find the latest `emis-base` AMI ID.
It will use a test security group which is too open, and will warn you about it. By default it
will launch a t3.micro instance.

Note old AMIs may have been deregistered, so if you didn't build
the last AMI, it may try to use an invalid one.

To provide a custom ami/security group/instance type:

```
just launch-instance ami-xxxxx sg-xxxxx <instance_type>
```


## Running on vagrant

Test the provisioning by running with vagant/virtualbox.


### Build the vagrant box
```
just packer-build-vagrant
```

When it's done, it will output the new box file and Vagrantfile to `vagrant_output/`.
It will write build details to `packer/manifest.json`.


### Add, up and ssh to the new box
```
just vagrant-run <your-username>
```

If you have a user set up on opensafely backends, this will ssh as your user. As with 
real backends, it will make you set your password and will kick you out. To re-login, run:

```
just vagrant-ssh <your-username>
```

If you don't have a backend user, just run:
```
just vagrant-run
```

This will ssh as the vagrant user. 

Clean up the vagrant output with:
```
just vagrant-clean
```

## Notes on EFS

In this backend, the storage dirs mounted into running jobs and Airlock are
located in a mounted EFS file system. During the AMI build, local directories
are created at the relevant locations so that Airlock/job-runner can be installed
and started up. The userdata at [cloud-init-emis/user-data](cloud-init-emis/user-data)
is used when an instance is launched from the AMI, and mounts the EFS filesystem (to `/efs`).

The test EFS for this backend was created manually in the AWS console, with its own
security group, which has a single inbound rule, allowing access from the security
group assigned to the launched EC2 instances. It is in a single availabilty zone for
cost purposes during testing.