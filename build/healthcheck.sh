#!/bin/bash
health_ok=yes
supervisorctl status |grep -v "RUNNING"|wc -l |grep -v 0 || { health_ok=no ; supervisorctl status |grep -v "RUNNING" |sed 's/^/ERR-SUPERV-/g'; } ;
/usr/bin/curl --fail -H "User-Agent: docker-health-check/over9000" -kL https://127.0.0.1/  > /dev/null ||  { health_ok=no ; echo FAIL80; } ;
/usr/bin/curl --fail -H "User-Agent: docker-health-check/over9000" -kL https://127.0.0.1/  > /dev/null ||  { health_ok=no ; echo FAIL443; } ;
