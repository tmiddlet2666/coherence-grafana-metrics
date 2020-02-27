FROM prom/prometheus:v2.4.3

# Add in the configuration file from the local directory.
ADD prometheus.yml /etc/prometheus/prometheus.yml
