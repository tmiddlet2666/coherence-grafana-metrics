
REM Start a cache server with metrics enabled
REM Author: Tim Middleton 2020-05-14

IF "%1"=="" GOTO Usage
IF "%2"=="" GOTO Usage
IF "%3"=="" GOTO Usage

SET PORT=%1
SET MEMBER=%2
SET ROLE=%3

set METRICS_CP="<INSERT FULL CLASSPATH HERE>"

java -Dcoherence.metrics.http.enabled=true -Dcoherence.metrics.http.port=%PORT% ^
     -Dcoherence.metrics.legacy.names=false ^
     -Dcoherence.machine=localhost -Dcoherence.role=%ROLE% -Dcoherence.member=%MEMBER% ^
     -Dcoherence.site=PrimarySite ^
     -cp "%METRICS_CP%" com.tangosol.net.DefaultCacheServer

EXIT /b 0


:Usage
ECHO "Please provide metrics port, member name and role"
