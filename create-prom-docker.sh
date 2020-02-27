#!/bin/bash
# Create the Prometheus Docker image
# Author: Tim Middleton 2020-02-27
#
cat <<EOF > Dockerfile
FROM prom/prometheus:v2.4.3

# Add in the configuration file from the local directory.
ADD prometheus.yml /etc/prometheus/prometheus.yml
EOF

docker build -t prometheus_coherence .
