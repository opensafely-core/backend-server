BACKEND_SERVER_DIR := env_var_or_default('BACKEND_SERVER_DIR', "/srv/backend-server")
# run-in-lxd.sh & tests/test require these env vars
export DEBUG := env_var_or_default('DEBUG', "")
export GITHUB_ACTIONS := env_var_or_default('GITHUB_ACTIONS', "false")
set dotenv-load := true


default:
  @just --list

[private]
check:
  #!/bin/bash
  set -euo pipefail

  test $PWD = {{ BACKEND_SERVER_DIR }}* || { echo "You must run this from {{ BACKEND_SERVER_DIR }}"; exit 1; }

  if test -z $BACKEND
  then
    echo "BACKEND is not set in .env";
    exit 1
  fi
  if [[ $BACKEND == *"-backend"* ]]; then
    echo "Please shorten BACKEND (i.e. 'test' instead of 'test-backend')"
    exit 1
  fi
  if test ! -e backends/$BACKEND
  then
    echo "Backend 'backends/$BACKEND' does not exist in this repo"
    exit 1
  fi

# install required system packages
install-packages: check
  ./scripts/install_packages.sh

# install/update groups & system level configuration 
install: check
  ./scripts/install.sh

# create opensafely user & config
install-opensafely-user: check
  ./scripts/install_opensafely_user.sh
  ./scripts/update-config.sh $BACKEND

# report which backend configuration this justfile is using
whereami: check
  @echo "Your current backend is: $BACKEND"

# disable a users permissions and ssh access
disable-user user:
  ./scripts/disable-user.sh {{ user }}

update-users: check
  ./scripts/update-users.sh $BACKEND

install-jobrunner: check install-opensafely-user install-docker-network
  ./services/jobrunner/install.sh $BACKEND

install-docker-network:
  ./services/jobrunner/sbin/jobrunner-network-config.sh

install-release-hatch: check
  ./services/release-hatch/install.sh

install-airlock: check install-opensafely-user
  ./services/airlock/install.sh

install-collector: check
  ./services/collector/install.sh

install-timers: check
  ./services/timers/install.sh

# install everything for a backend
manage: check
  #!/bin/bash
  set -euo pipefail
  if test -d /srv/jobrunner/environ -a ! -d ~opensafely/config; then
    echo "You need to manually run ./scripts/migrate.sh first"
    exit 1
  fi
  {{ just_executable() }} manage-$BACKEND


[private]
manage-test: install-packages install update-users install-jobrunner install-airlock install-collector

[private]
manage-tpp: install-packages install update-users install-jobrunner install-airlock install-collector install-timers

test:
  echo "Please see `just tests/`"

# upgrade all apt packages
apt-upgrade:
  #!/bin/bash
  set -euo pipefail

  package_to_hold='docker.io'

  apt-get update
  apt-mark hold "$package_to_hold"
  apt-get upgrade -y
  apt-get autoremove -y

  if apt list --upgradable "$package_to_hold" 2>/dev/null | grep -qF "$package_to_hold"; then
      echo
      echo "  => WARNING <="
      echo
      echo "  The '$package_to_hold' package has an update pending. This usually requires"
      echo "  a restart of all running Docker containers. To avoid disruption to user"
      echo "  jobs you should first run a prepare_for_reboot on the controller."
      echo
      echo "  Note that jobs will have to re-run from the start so if there are"
      echo "  currently jobs which have been running a long time you may wish to delay"
      echo "  upgrading."
      echo
      echo "  Choose 'n' below to decline the update, or 'Y' to proceed."
      echo
    apt-mark unhold "$package_to_hold"
    apt-get upgrade
  fi
