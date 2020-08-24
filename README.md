# Monitor Your Coherence Clusters using Grafana and Prometheus (Coherence CE)

## Introduction

This document is a step by step example of how to enable metrics on Coherence cluster
members, capture those metrics via Prometheus and display then in Grafana
using the dashboards from the [Coherence Operator](https://github.com/oracle/coherence-operator) project.

> Note: This release of the coherence-grafana-metrics repository has instructions specifically for the
> Community Edition (CE) of Coherence. Please change to the [v1.0.0](https://github.com/tmiddlet2666/coherence-grafana-metrics/tree/v1.0.0) branch for Commercial Coherence instructions.

**This is an example only and you can use this as a guide to adding Grafana monitoring to your cluster.**

See the following for more information:
* [Coherence Community Edition on GitHub](https://github.com/oracle/coherence)
* [Coherence Community Home Page](https://coherence.community/)
* [Coherence documentation on Metrics](https://docs.oracle.com/en/middleware/standalone/coherence/14.1.1.0/manage/using-coherence-metrics.html)
* [Coherence Operator on GitHub](https://github.com/oracle/coherence-operator)
* [Coherence Operator Metrics Documentation](https://oracle.github.io/coherence-operator/docs/3.0.0/#/metrics/010_overview)
* [Grafana](https://grafana.com/)


> Note: These will work for Coherence CE versions 14.1.1-0-1 and above.

If you notice any errors in this documentation, please raise a P/R or issue.

## Prerequisites

You must have the following:

* Docker Desktop for Mac or the equivalent Docker environment for you O/S.
* Maven 3.5.4+
* JDK 11
* Cloned this repository via `git clone https://github.com/tmiddlet2666/coherence-grafana-metrics.git`

> Note: This document has been written for Mac/Linux. Where appropriate, alternative Windows commands have been shown.

## 1. Generate the required dependencies

Follow the instructions from the Coherence 12.2.1.4 metrics documentation https://docs.oracle.com/en/middleware/fusion-middleware/coherence/12.2.1.4/manage/using-coherence-metrics.html and create a pom.xml.

The above instructions have been included below for convenience:

```bash
mvn dependency:build-classpath -P jdk11
```

Remove `-P jdk11` if you are using JDK8.

Save the output of `[INFO] Dependencies classpath:` above to the `METRICS_CP` variable in `start-server.sh` or `start-server.cmd`.

Eg. replace `<INSERT FULL CLASSPATH HERE>` with the classpath contents.

```bash
export METRICS_CP="<INSERT FULL CLASSPATH HERE>"
```

Also ensure COHERENCE_HOME is set correctly to the coherence directory as below:

```bash
export COHERENCE_HOME=/u01/oracle/product/coherence/coherence12.2.1.4.0/coherence
```

## 2. Start Coherence cache servers

> Note: For Windows, replace start-server.sh with start-server.cmd.

Startup a cache server with metrics enabled on port 9612 with a role of CoherenceServer

```bash
./start-server.sh 9612 member1 CoherenceServer
```     


Startup a second cache server with metrics enabled on port 9613

```bash
./start-server.sh 9613 member2 CoherenceServer
```

Optionally startup a third cache server with metrics enabled on port 9613

```bash
./start-server.sh 9614 member3 CoherenceServer
```

You should see the following indicating the metrics service is started in each of the cache server logs.

```bash
  ProxyService{Name=MetricsHttpProxy, State=(SERVICE_STARTED), Id=5, OldestMemberId=1}
```     

## 3. Start the Console to Add Data

> Note: change the full path to your coherence.jar

```bash
export COH_JAR=~/.m2/repository/com/oracle/coherence/ce/coherence/20.06/coherence-20.06.jar
java -Dcoherence.distributed.localstorage=false -cp $COH_JAR  com.tangosol.net.CacheFactory
```

Enter the following at the prompt to create a cache and add 100,000 random objects:
```bash
cache test
bulkput 100000 100 0 100
```

## 4. Create the Prometheus Docker image

> Note: Ensure you have docker running.

Edit `prometheus.yml` and ensure the static configs are set as below:

```yaml
    static_configs:
    - targets: ['host.docker.internal:9612', 'host.docker.internal:9613', 'host.docker.internal:9614', 'host.docker.internal:9615']
```

> Note: replace `host.docker.internal` with the actual IP and host if you are running a Coherence cluster a separate machine.

Build the docker image using:

```bash
docker build -t prometheus_coherence .
```

This will create the image `prometheus_coherence:latest` with the above `prometheus.yaml`.

## 5. Run the docker images

```bash
export HOST=127.0.0.1
docker run -d -p $HOST:9090:9090 prometheus_coherence:latest

docker run -d -p $HOST:3000:3000 grafana/grafana:7.1.4
```

> Note: Change HOST to a value that is suitable for your setup.

## 6. Clone the Coherence Operator repository

Issue the following to clone the Coherence Operator repository.

```bash
git clone https://github.com/oracle/coherence-operator.git
```

## 7. Access Prometheus

Login to Prometheus and confirm that the targets have been discovered by
going to the following URL: `http://127.0.0.1:9090/targets`

You should see the targets you started in an `UP` state.

## 8. Access Grafana and Create a datasource

Login to Grafana using the following URL: `http://127.0.0.1:3000/`  - default user admin/admin

Add a default Prometheus data source called `Prometheus` with an endpoint of `http://host.docker.internal:9090`.

Ensure that you make this datasource the default datasource if it is not already.

> Note: Change the `host.docker.internal` to an actual host name if you are running Prometheus outside of docker.

## 9. Import the Grafana Dashboards

Login to Grafana and click on the `+` then `Import` and `Upload JSON File`.
Select each of the dashboards in the `coherence-operator/dashboards/grafana` directory you cloned above
and import them into Grafana.

> Note: The Federation and Elastic Data dashboards will not display anything as this functionality is not available in Coherence CE.

## 10. Access the Main Grafana dashboards

Access Grafana using the following URL: `http://127.0.0.1:3000/d/coh-main/coherence-dashboard-main`.

## 11. Cleanup

Ensure you kill your docker images you started.
