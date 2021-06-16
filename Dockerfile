# Base image for running tests.
#
# We are using docker as way to test scripts desinged to run inside a regular
# ubuntu VM. We could user lxd or similar instead, but docker runs OOTB in GH
# actions and across all our developers laptops.
#
# So we use an ubuntu:20.04 docker image that has been modified to run systemd
# as PID 1, like a regular VM. This allows our scripts to install and run
# systemd services of their own. We also install a set of packages to convert
# the minimal ubuntu docker image into a full ubuntu-server image.
# 
# Note: running systemd as PID 1 means we need to run this image with some
# specific options:
# 
#   --cap-add SYS_ADMIN \
#   --tmpfs /tmp --tmpfs /run --tmpfs /run/lock \
#   -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
#
FROM jrei/systemd-ubuntu:20.04

# This is docker image optimisation that breaks command-not-found, which breaks
# apt-update when installed :headdesk:
# https://bugs.launchpad.net/ubuntu/+source/command-not-found/+bug/1876034
RUN rm /etc/apt/apt.conf.d/docker-gzip-indexes

# Make the docker image look like a regular ubuntu server. We could run
# unminimize also, but it's just local documentation, so not worth it
RUN apt-get update && \
    apt-get upgrade -y && \
    apt install -y ubuntu-server ubuntu-standard ubuntu-minimal ubuntu-advantage-tools cloud-init openssh-server

# Pre-purge the packages we want to purge for speed in tests
COPY purge-packages.txt /tmp/purge-packages.txt
RUN sed 's/^#.*//' /tmp/purge-packages.txt | xargs apt-get purge -y

# Preinstall backend-server packages for speed when running tests
COPY core-packages.txt /tmp/core-packages.txt
RUN sed 's/^#.*//' /tmp/core-packages.txt | xargs apt-get install -y
COPY packages.txt /tmp/packages.txt
RUN sed 's/^#.*//' /tmp/packages.txt | xargs apt-get install -y

RUN apt-get autoremove -y

# this allows use to avoid docker in docker
# ensure docker gid inside container matches host docker gid
ARG DOCKER_GID
RUN groupmod -g $DOCKER_GID docker
