#!/bin/bash

_mem_process_json()         { for prcss in $@;do ps -ylC  "${prcss}" | grep "$prcss" |wc -l|grep -q  ^0|| ps -ylC  "${prcss}" | awk '{x += $8;y += 1} END {print "{ \"mem_mb_sum_'${prcss}'\": \""x/1024"\" }"; print "{ \"mem_mb_avg_'${prcss}'\": \""x/((y-1)*1024)"\" }"}' ; done ; } ;
fail_reasons=""
health_ok=yes
supervisorctl status |grep -v "RUNNING"|wc -l |grep ^0 -q || { health_ok=no ; fail_reasons=${fail_reasons}" SUPERVISOR"$(supervisorctl status |grep -v "RUNNING" |sed 's/^/ ERR-SUPERV-/g') ; } ;

ps aux|grep -v grep |grep -q -e nginx -e apache -e httpd && {

#timeout 10 /usr/bin/curl -s --fail -H "User-Agent: docker-health-check/over9000" -kL https://127.0.0.1/  > /dev/null ||  { health_ok=no ; fail_reasons=${fail_reasons}" FAIL80"  & } ;

timeout 10 /usr/bin/curl -s --fail -H "User-Agent: docker-health-check/over9000" -kL https://127.0.0.1/  > /dev/null ||  { health_ok=no ; fail_reasons=${fail_reasons}" FAIL443" & } ;
echo -n ; } ;

#_mem_process_json apache2 nginx  mysqld redis-server memcached php php-fpm$(php --version|grep ^PHP|head -n1|cut -d" " -f2|cut -d. -f1-2)|sed 's/'
health_json=","$(_mem_process_json apache2 nginx  mysqld redis-server memcached php php-fpm$(php --version|grep ^PHP|head -n1|cut -d" " -f2|cut -d. -f1-2)|tr -d '\n'|sed 's/}{/},{/g')
[[ "${health_json}" = "," ]] && health_json=""

wait
[[ "${health_ok}" = "yes" ]]  &&  { echo '[ { "health": "OK"  }'${health_json}']' ; exit 0  ; } ;
[[ "${health_ok}" = "no" ]]   &&  { echo '[ { "health": "FAIL" , "fail_reasons":"'$fail_reasons'"  } '${health_json}']'  ;exit  $((1+$(echo "$fail_reasons"|wc -w))) ; } ;
