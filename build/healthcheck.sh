#!/bin/bash

_mem_process_json()         { for prcss in $@;do ps -ylC  "${prcss}" | grep "$prcss" |wc -l|grep -q  ^0|| ps -ylC  "${prcss}" | awk '{x += $8;y += 1} END {print "{ \"mem_mb_sum_'${prcss}'\": \""x/1024"\" }"; print "{ \"mem_mb_avg_'${prcss}'\": \""x/((y-1)*1024)"\" }"}' ; done ; } ;
health_ok=yes
fail_reasons=""
supervisorctl status |grep -v "RUNNING"|wc -l |grep -v 0 || { health_ok=no ; supervisorctl status |grep -v "RUNNING" |sed 's/^/ERR-SUPERV-/g'; } ;
ps aux|grep -v grep |grep -e nginx -e apache -e httpd && {
  /usr/bin/curl --fail -H "User-Agent: docker-health-check/over9000" -kL https://127.0.0.1/  > /dev/null ||  { health_ok=no ; fail_reasons=${fail_reasons}" FAIL80"   ; } ;
  /usr/bin/curl --fail -H "User-Agent: docker-health-check/over9000" -kL https://127.0.0.1/  > /dev/null ||  { health_ok=no ; fail_reasons=${fail_reasons}" FAIL443"  ; } ;
echo -n ; } ;
_mem_process_json apache2 nginx memcached mysqld redis-server php php-fpm$(php --version|grep ^PHP|head -n1|cut -d" " -f2|cut -d. -f1-2)
[[ -z "${fail_reasons// /}" ]] || { echo '{ "health" : "OK"  }'  ;                                    exit  0                                    ; } ;
[[ -z "${fail_reasons// /}" ]] && { echo '{ "health" : "FAIL" , "fail_reasons":"'$fail_reasons'" }'  ;exit  $((1+$(echo "$fail_reasons"|wc -w))) ; } ;
