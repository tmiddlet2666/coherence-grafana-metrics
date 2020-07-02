#!/bin/bash
# Start a cache server with metrics enabled
# Author: Tim Middleton 2020-02-27

if [ $# -ne 3 ] ; then
   echo "Please provide metrics port, member name and role"
   exit 1
fi

PORT=$1
MEMBER=$2
ROLE=$3

# Ensure you replace the following with your COHERENCE_HOME
export COHERENCE_HOME=/u01/oracle/product/coherence/coherence12.2.1.4.0/coherence
export METRICS_CP="<INSERT FULL CLASSPATH HERE>"

java -Dcoherence.metrics.http.enabled=true -Dcoherence.metrics.http.port=$PORT \
    -Dcoherence.metrics.legacy.names=false \
    -Dcoherence.machine=localhost -Dcoherence.role=$ROLE -Dcoherence.member=$MEMBER -Dcoherence.site=PrimarySite \
    -cp "$COHERENCE_HOME/lib/coherence.jar:$METRICS_CP" com.tangosol.net.DefaultCacheServer
