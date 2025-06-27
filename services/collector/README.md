# OTel Collector


We run an otel collector instance in our secure environments. It has two jobs:

- collect and emit host metrics (cpu, memory, disk) to honeycomb
- buffer and forward traces from applications (agent, airlock) to honeycomb.

It provides a single place to route and configure telemetry from within the secure environment.

This directory containst the config and service files to run the collector.


## Honeycomb otel collector build

We use https://github.com/honeycombio/opentelemetry-collector-configs/ as the
source for this collector binary and the basis of our configuration.  This is
ensures that the metrics we emit are compatible with honeycomb.

We commit the binary in `bin/collector`, and ship it into the secure
environments via this github repo.

Via systemd, we run the binary directly, rather than inside a docker container,
so that it has access to the host metrics, not the container metrics.

