#!/bin/bash

## docker run -v /path/to/build/_1_php-initprep.sh:/_1_php-initprep.sh:ro -v /tmp/_image_tests.sh:/_image_tests.sh --rm -it thefoundation/hocker:php7.4-dropbear-fpm /bin/bash /_image_tests.sh

/bin/bash /usr/local/bin/run.sh   &>/dev/shm/startlog &

start=$(date -u +%s);
scriptstart=$start
echo "docker CI test started at "$(date)
while  ( supervisorctl status 2>&1 | grep -qv "RUNNING "  )   ;do
  [[ $(($(date -u +%s)-${start})) -gt 120 ]] && exit 999
      echo -ne "waiting since "$(($(date -u +%s)-${start}))" seconds "$(tail -n2 /dev/shm/startlog|tail -c 50  |tr -d '\r\n' ) '\r';sleep 2; done

###
CRONCMD='*/1 * * * * touch /tmp/crontest.file'
#(echo ;echo "${CRONCMD}" )  |tee -a /var/spool/cron/crontabs/www-data ;chown www-data /var/spool/cron/crontabs/www-data

(crontab -l -u www-data 2>/dev/null; echo "${CRONCMD}") | crontab -u www-data -

which supervisorctl 2>&1 | grep -q supervisorctl && supervisorctl restart cron
which supervisorctl 2>&1 | grep -q supervisorctl || service cron restart

which apachectl && {
echo "##########"
echo "APACHE:"
  apache_modules=$(apachectl -M 2>/dev/null)
  for term in headers ssl remoteip;do
    echo "${apache_modules}" | grep "${term}_module" || { build_ok=no ;fail_reasons=${fail_reasons}" apache_mod_${term}" ;echo FAIL; }
  done

echo ; } ;

uptime
sleep 5
supervisorctl status

build_ok=yes
fail_reasons=""



which php &>/dev/null || {
runtst=no
which apache 2>/dev/null && runtst=yes
which nginx 2>/dev/null && runtst=yes

  [[ "${runtst}" = "yes" ]] && {
  TOKEN=$(for rounds in $(seq 1 24);do cat /dev/urandom |tr -cd '[:alnum:]_\-.'  |head -c48;echo ;done|grep -e "_" -e "\-" -e "\."|grep ^[a-zA-Z0-9]|grep [a-zA-Z0-9]$|tail -n1|head -c40)
  (echo "<html><body>CI Static test<br>";echo "$TOKEN";echo "</body></html>") > /var/www/html/index.html
  curl_result=$(curl -kLv https://127.0.0.1/index.html 2>/dev/shm/curl_ERR_log)
   echo ; } ;
echo -n ; } ;

which php &>/dev/null && {
runtst=no
which apache 2>/dev/null && runtst=yes
which nginx 2>/dev/null && runtst=yes

[[ "${runtst}" = "yes" ]] && {

echo "###################"
echo "PHP:"
  echo '<?php
phpinfo(); ' > /var/www/html/phi.php
curl_result=$(curl -kLv https://127.0.0.1/phi.php 2>/dev/shm/curl_ERR_log)

  echo "$curl_result" |grep -q "phpinfo" || { build_ok=no ;fail_reasons=${fail_reasons}" phpinfo_grep_phpinfo" ; } ;
  echo "$curl_result" |grep -q "display_errors" || { build_ok=no ;fail_reasons=${fail_reasons}" phpinfo_grep_display_errors" ; } ;


echo -n ; } ;
echo ; } ;


echo "###################"
echo "IMAGICK"

which identify  &>/dev/null && {
  echo "imagick present ..";
  echo " testing webp in build:"
  echo -n "imagick-cli:"
  identify --version |grep -i -q webp || { build_ok=no ;fail_reasons=${fail_reasons}" webp_build" ;echo FAIL; }
  identify --version |grep -i -q webp && echo OK ;

  which php &>/dev/null && {

    echo "testing php-imagick_webp"
    phpclires=$(php -r 'phpinfo();' )
    echo "${phpclires}" |grep -q -i webp || { build_ok=no ;fail_reasons=${fail_reasons}" webp_phpcli" ; } ;
    echo "CLI:"$(echo "${phpclires}" |grep -q -i webp && { echo OK ; } || { echo FAIL ; } ; );

    phpwebres=$(echo "$curl_result" )
    echo "${phpwebres}" |grep -q -i webp || { build_ok=no ;fail_reasons=${fail_reasons}" webp_curl" ; } ;
    echo "PHP(-FPM):"$(echo "${phpwebres}" |grep -q -i webp && { echo OK ; } || { echo FAIL ; } ; );

  echo -n ; } ;

echo ; } ;



supervisorctl status 2>&1 | grep -q -e mysql -e mariadb && {
echo "##########"
echo "SQL: mariadb OR mysql detected"
mysql -e "show databases;use mysql;show tables" |grep -q user  || { build_ok=no ;fail_reasons=${fail_reasons}" mysql_no_user_in_mysql_mysql" ; }  ;
mysql -e "use mysql;select * from user " |grep -q  user  || { build_ok=no ;fail_reasons=${fail_reasons}" mysql_no_user_in_mysql_user" ;  }  ;
echo ; };

echo "waiting for cron verification"
start=$(date -u +%s);
#echo "started at "$start

## wait 120 seconds for cron to start ( should do it after 1 minute)
  while  ( test -f /tmp/crontest.file || true )   ;do
       [[ $(($(date -u +%s)-${start})) -gt 120 ]] && { echo CRON::"TIMEOUT" ;  touch  /tmp/crontest.file ; } ;
      echo -ne "waiting since "$(($(date -u +%s)-${start}))" seconds "$(tail -c 50 /dev/shm/startlog |tr -d '\r\n' )'\r' ;sleep 2; done

test -e /tmp/crontest.file && ls -lh1 /tmp/crontest.file
test -e /tmp/crontest.file || { build_ok=no ;fail_reasons=${fail_reasons}" cron_not_running" ; }  ;

echo "################"

echo

echo "result after "$(($(date -u +%s)-${scriptstart}))" seconds "
echo "build_ok:"$build_ok
[[ -z "${fail_reasons// /}" ]] || echo "FAILED: "${fail_reasons}
