# OTel Collector

We run an OTel Collector instance in our secure environments. It has two jobs:

 * collect and emit host metrics (cpu, memory, disk) to Honeycomb;
 * buffer and forward traces from applications (RAP Agent, Airlock) to Honeycomb.

It provides a single place to route and configure telemetry from within the secure environment.

This directory contains the config and service files to run the collector.

## Deployment

We use the latest official OTel Collector release from:<br>
https://github.com/open-telemetry/opentelemetry-collector-releases/releases/

This currently runs as a native binary so it has direct access to host system metrics.
It runs as a standard, unprivileged user under SystemD. In future, we plan to deploy
this as Docker container for consistency with our other services.

The configuration is specified in `collector.yaml`.

Additionally, two environment variables are required:
```
COLLECTOR_AUTH_USER=
COLLECTOR_AUTH_TOKEN=
```
These are used for authenticating to our OTel Gateway which will then forward the
traffic to Honeycomb with the appropriate Honeycomb authentication.

There are two further optional environment variables with default values:
```
COLLECTOR_GATEWAY_ENDPOINT=collector.opensafely.org:443
DOCKER_BRIDGE_IP=172.17.0.1
```

`COLLECTOR_GATEWAY_ENDPOINT` will need customising if the deployment is connecting to
staging infrastructure.

`DOCKER_BRIDGE_IP` may need customising if the Docker bridge network has a nonstandard
gateway IP. This is used so that applications running in Docker can sent telemetry to
the collector.
