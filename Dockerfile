# base image for running tests
# - preinstalled packages for test speed
FROM ubuntu:20.04
ENV DEBIAN_FRONTEND="noninteractive"
RUN apt-get update && apt-get upgrade -y
COPY packages.txt /tmp/packages.txt
RUN cat /tmp/packages.txt | sed 's/^#.*//' | xargs apt-get install -y
