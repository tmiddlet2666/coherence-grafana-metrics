# Monitor Your Coherence Clusters using Grafana and Prometheus

## Introduction

This document is a step by step example of how to enable metrics on Coherence cluster
members, capture those metrics via Prometheus and display then in Grafana
using the dashboards from the [Coherence Operator](https://github.com/oracle/coherence-operator) project.

**This is an example only and you can use this as a guide to adding Grafana monitoring to your cluster.**
**You should ensure you apply**

See the following for more information:
* [Coherence documentation on Metrics](https://docs.oracle.com/en/middleware/fusion-middleware/coherence/12.2.1.4/manage/using-coherence-metrics.html)
* [Coherence Operator GitHub Page](https://github.com/oracle/coherence-operator)
* [Coherence Operator Metrics Documentation](https://oracle.github.io/coherence-operator/docs/2.1.0/#/metrics/010_overview)

> Note: These will work for Coherence versions 12.2.1.4.0 and above.

If you notice any errors in this documentation, please raise a P/R.

## Prerequisites

You must have the following:

* Docker Desktop for Mac or the equivalent Docker environment for you O/S.
* Maven 3.5.4+
* JDK 11 or 8
* Oracle Coherence 12.2.1.4.+ installed
* Cloned this repository via `git clone https://github.com/tmiddlet2666/coherence-grafana-metrics.git`

> Note: This document has been written for Mac/Linux. Where appropriate, alternative Windows commands have been shown.

## 1. Install Coherence and metrics dependencies

Download and install Coherence from [https://www.oracle.com/middleware/technologies/coherence-downloads.html](https://www.oracle.com/middleware/technologies/coherence-downloads.html)

Set the COHERENCE_HOME environment variable to the `coherence` directory you just installed and run the Maven commands below to import the coherence.jar and coherence-metrics.jar in your local repository.

> Note: In the example below Coherence was installed into /u01/oracle/product/coherence/coherence12.2.1.4.0 for Mac/Linux and
> C:\Tim\coherence12214 for Windows.

For Mac/Linux

```bash
export COHERENCE_HOME=/u01/oracle/product/coherence/coherence12.2.1.4.0/coherence

mvn install:install-file -Dfile=$COHERENCE_HOME/lib/coherence.jar         -DpomFile=$COHERENCE_HOME/plugins/maven/com/oracle/coherence/coherence/12.2.1/coherence.12.2.1.pom
mvn install:install-file -Dfile=$COHERENCE_HOME/lib/coherence-metrics.jar -DpomFile=$COHERENCE_HOME/plugins/maven/com/oracle/coherence/coherence-metrics/12.2.1/coherence-metrics.12.2.1.pom
```

Windows

```bash
SET COHERENCE_HOME=c:\Tim\coherence12214
mvn install:install-file -Dfile=%COHERENCE_HOME%\lib\coherence.jar         -DpomFile=%COHERENCE_HOME%\plugins\maven\com\oracle\coherence\coherence\12.2.1\coherence.12.2.1.pom
mvn install:install-file -Dfile=%COHERENCE_HOME%\lib\coherence-metrics.jar -DpomFile=%COHERENCE_HOME%\plugins\maven\com\oracle\coherence\coherence-metrics\12.2.1\coherence-metrics.12.2.1.pom

```

> Note: If your Coherence version is greater than 12.2.1, then change the 12.2.1 to the correct version.

## 2. Generate the required dependencies

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

## 3. Start Coherence cache servers

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

## 4. Start the Console to Add Data

> Note: change the full path to your coherence.jar

```bash
java -Dcoherence.distributed.localstorage=false -cp /u01/oracle/product/coherence/coherence12.2.1.4.0/coherence/lib/coherence.jar com.tangosol.net.CacheFactory
```

Enter the following at the prompt to create a cache and add 100,000 random objects:
```bash
cache test
bulkput 100000 100 0 100
```

## 5. Create the Prometheus Docker image

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

## 6. Run the docker images

```bash
export HOST=127.0.0.1
docker run -d -p $HOST:9090:9090 prometheus_coherence:latest

docker run -d -p $HOST:3000:3000 grafana/grafana:6.6.2
```

> Note: Change HOST to a value that is suitable for your setup. 

## 7 Clone the Coherence Operator repository

Issue the following to clone the Coherence Operator repository.

```bash
git clone https://github.com/oracle/coherence-operator.git
```

## 8. Access Prometheus

Login to Prometheus and confirm that the targets have been discovered by
going to the following URL: `http://127.0.0.1:9090/targets`

You should see the targets you started in an `UP` state.

## 9. Access Grafana and Create a datasource

Login to Grafana using the following URL: `http://127.0.0.1:3000/`  - default user admin/admin

Add a default Prometheus data source called `Prometheus` with an endpoint of `http://host.docker.internal:9090`.

Ensure that you make this datasource the default datasource if it is not already.

> Note: Change the `host.docker.internal` to an actual host name if you are running Prometheus outside of docker.

## 10. Import the Grafana Dashboards

Login to Grafana and click on the `+` then `Import` and `Upload JSON File`.
Select each of the dashboards in the `coherence-operator/helm-charts/coherence-operator/dashboards` directory you cloned above
and import them into Grafana.

## 11. Access the Main Grafana dashboards

Access Grafana using the following URL: `http://127.0.0.1:3000/d/coh-main/coherence-dashboard-main`.

## 12. Cleanup

Ensure you kill your docker images you started.
