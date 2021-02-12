# Base image for running tests.
#
# We are using docker as way to test scripts desinged to run inside a regular
# ubuntu VM. We could user lxd or similar instead, but docker runs OOTB in GH
# actions.So we install ubuntu-server on top of the ubuntu:20.04 image, and
# this gets us much closer to a regular VM image.
#
# Importantly, we run system as PID 1, like a regular VM. This allows our
# scripts to install and run systemd services of their own.
# 
# Note: this means we need to run this image with some specific options:
# 
#   --cap-add SYS_ADMIN \
#   --tmpfs /tmp --tmpfs /run --tmpfs /run/lock \
#   -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
#
# We also pre-install our packages, so that tests run faster.
FROM ubuntu:20.04

ENV container docker
ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive

RUN sed -i 's/# deb/deb/g' /etc/apt/sources.list

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y ubuntu-server

VOLUME [ "/sys/fs/cgroup" ]

CMD ["/lib/systemd/systemd"]

# preinstall our packages for speed when running tests
COPY packages.txt /tmp/packages.txt
RUN sed 's/^#.*//' /tmp/packages.txt | xargs apt-get install -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
