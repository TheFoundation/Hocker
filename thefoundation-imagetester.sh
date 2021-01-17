#!/bin/bash

# Trap interrupts and exit instead of continuing the loop
#trap "echo Sorry .. hanging up ; exit;" SIGINT SIGTERM

## docker run -v /path/to/build/_1_php-initprep.sh:/_1_php-initprep.sh:ro -v /tmp/_image_tests.sh:/_image_tests.sh --rm -it thefoundation/hocker:php7.4-dropbear-fpm /bin/bash /_image_tests.sh

## Colors ;
uncolored="\033[0m" ; black="\033[0;30m" ; blackb="\033[1;30m" ; white="\033[0;37m" ; whiteb="\033[1;37m" ; red="\033[0;31m" ; redb="\033[1;31m" ; green="\033[0;32m" ; greenb="\033[1;93m" ; yellow="\033[0;33m" ; yellowb="\033[1;33m" ; blue="\033[0;34m" ; blueb="\033[1;34m" ; purple="\033[0;35m" ; purpleb="\033[1;35m" ; lightblue="\033[0;36m" ; lightblueb="\033[1;36m" ;  function black {   echo -en "${black}${1}${uncolored}" ; } ;    function blackb {   echo -en "${blackb}";cat;echo -en "${uncolored}" ; } ;   function white {   echo -en "${white}";cat;echo -en "${uncolored}" ; } ;   function whiteb {   echo -en "${whiteb}";cat;echo -en "${uncolored}" ; } ;   function red {   echo -en "${red}";cat;echo -en "${uncolored}" ; } ;   function redb {   echo -en "${redb}";cat;echo -en "${uncolored}" ; } ;   function green {   echo -en "${green}";cat;echo -en "${uncolored}" ; } ;   function greenb {   echo -en "${greenb}";cat;echo -en "${uncolored}" ; } ;   function yellow {   echo -en "${yellow}";cat;echo -en "${uncolored}" ; } ;   function yellowb {   echo -en "${yellowb}";cat;echo -en "${uncolored}" ; } ;   function blue {   echo -en "${blue}";cat;echo -en "${uncolored}" ; } ;   function blueb {   echo -en "${blueb}";cat;echo -en "${uncolored}" ; } ;   function purple {   echo -en "${purple}";cat;echo -en "${uncolored}" ; } ;   function purpleb {   echo -en "${purpleb}";cat;echo -en "${uncolored}" ; } ;   function lightblue {   echo -en "${lightblue}";cat;echo -en "${uncolored}" ; } ;   function lightblueb {   echo -en "${lightblueb}";cat;echo -en "${uncolored}" ; } ;  function echo_black {   echo -en "${black}${1}${uncolored}" ; } ; function echo_blackb {   echo -en "${blackb}${1}${uncolored}" ; } ;   function echo_white {   echo -en "${white}${1}${uncolored}" ; } ;   function echo_whiteb {   echo -en "${whiteb}${1}${uncolored}" ; } ;   function echo_red {   echo -en "${red}${1}${uncolored}" ; } ;   function echo_redb {   echo -en "${redb}${1}${uncolored}" ; } ;   function echo_green {   echo -en "${green}${1}${uncolored}" ; } ;   function echo_greenb {   echo -en "${greenb}${1}${uncolored}" ; } ;   function echo_yellow {   echo -en "${yellow}${1}${uncolored}" ; } ;   function echo_yellowb {   echo -en "${yellowb}${1}${uncolored}" ; } ;   function echo_blue {   echo -en "${blue}${1}${uncolored}" ; } ;   function echo_blueb {   echo -en "${blueb}${1}${uncolored}" ; } ;   function echo_purple {   echo -en "${purple}${1}${uncolored}" ; } ;   function echo_purpleb {   echo -en "${purpleb}${1}${uncolored}" ; } ;   function echo_lightblue {   echo -en "${lightblue}${1}${uncolored}" ; } ;   function echo_lightblueb {   echo -en "${lightblueb}${1}${uncolored}" ; } ;    function colors_list {   echo_black "black";   echo_blackb "blackb";   echo_white "white";   echo_whiteb "whiteb";   echo_red "red";   echo_redb "redb";   echo_green "green";   echo_greenb "greenb";   echo_yellow "yellow";   echo_yellowb "yellowb";   echo_blue "blue";   echo_blueb "blueb";   echo_purple "purple";   echo_purpleb "purpleb";   echo_lightblue "lightblue";   echo_lightblueb "lightblueb"; } ;


/bin/bash /usr/local/bin/run.sh   &>/dev/shm/startlog &


start=$(date -u +%s);
scriptstart=$start
echo "docker CI test started at "$(date) | green
sleep 2
while  ( supervisorctl status 2>&1 | grep -i -e cron -e mysql -e fpm -e mariadb -e dropbear -e openssh -e nginx -e apache -e redis -e mongo |grep  -qv "RUNNING "  )   ;do
  [[ $(($(date -u +%s)-${start})) -gt 120 ]] && exit 999
      echo -ne "init:waiting since "$(($(date -u +%s)-${start}))" seconds for "$(supervisorctl status 2>&1 | grep -i -e mysql -e fpm -e mariadb -e dropbear -e openssh -e nginx -e apache -e redis -e mongo|cut -f1|cut -d" " -f1)|red ;echo -ne $(tail -n2 /dev/shm/startlog|tail -c 84  |tr -d '\r\n' ) '\r';sleep 2;
    done

(sleep 15;
### cron started in advance
CRONCMD='*/1 * * * * touch /tmp/crontest.file'
#(echo ;echo "${CRONCMD}" )  |tee -a /var/spool/cron/crontabs/www-data ;chown www-data /var/spool/cron/crontabs/www-data

(crontab -l -u www-data 2>/dev/null; echo "${CRONCMD}") | crontab -u www-data -

which supervisorctl 2>&1 | grep -q supervisorctl && supervisorctl restart cron 2>&1 |tr -d '\n'
which supervisorctl 2>&1 | grep -q supervisorctl || service cron restart |tr -d '\n'
##############################################
) &



sleep 5

while  ( supervisorctl status 2>&1 | grep -i -e php-fpm -e apache -e nginx |grep  -qv "RUNNING "  )   ;do
  [[ $(($(date -u +%s)-${start})) -gt 120 ]] && exit 999
      echo -ne "init:waiting since "$(($(date -u +%s)-${start}))" seconds for "$(supervisorctl status 2>&1 | grep -i -e mysql -e fpm -e mariadb -e dropbear -e openssh -e nginx -e apache -e redis -e mongo|cut -f1|cut -d" " -f1)|red ;echo -ne $(tail -n2 /dev/shm/startlog|tail -c 84  |tr -d '\r\n' ) '\r';sleep 2;
    done
echo
sleep 5
build_ok=yes

touch /dev/shm/apache_fails
echo "##########"
echo -n "APACHE MODULES:" | green
apache_modules=$(apachectl -M 2>/dev/null)
        for term in ssl remoteip actions fastcgi alias setenvif proxy  remoteip rewrite expires  headers   proxy_http proxy_wstunnel  ;do
          fail_reasons=${fail_reasons}" apache_mod_${term}" ;
          which apachectl &>/dev/null && { echo "${apache_modules}" |sed 's/(shared)//g'| grep -q "${term}_module" || { build_ok=no ;
                                                                          echo -n " apache_mod_${term}"  >> /dev/shm/apache_fails ;
                                                                          echo "FAIL( $term )" |red; } ;
                             echo "${apache_modules}" |sed 's/(shared)//g'| grep -q "${term}_module" && echo "OK($term)" ;
                             echo -n " " ; } ;
        done |tr -d '\n'
echo

fail_reasons="$(cat /dev/shm/apache_fails)"
echo "$fail_reasons" |wc -w|grep ^0 || build_ok=no
#echo "fails round 1 :"$fail_reasons

#supervisorctl status




runtst=no
which apache2ctl &>/dev/null && runtst=yes
which nginx &>/dev/null && runtst=yes

  [[ "${runtst}" = "yes" ]] && {
  TOKEN=$(for rounds in $(seq 1 24);do cat /dev/urandom |tr -cd '[:alnum:]_\-.'  |head -c48;echo ;done|grep -e "_" -e "\-" -e "\."|grep ^[a-zA-Z0-9]|grep [a-zA-Z0-9]$|tail -n1|head -c40)
  (echo "<html><body>CI Static test<br>";echo "$TOKEN";echo "</body></html>") > /var/www/html/index.html
  curl_result=$(curl -kLv https://127.0.0.1/index.html 2>/dev/shm/curl_ERR_log)
  echo "${curl_result}" | grep -q "${TOKEN}" || { build_ok=no ;fail_reasons=${fail_reasons}" wget_443" ; } ;
  curl_result=$(curl -kLv http://127.0.0.1/index.html 2>/dev/shm/curl_ERR_log)
  echo "${curl_result}" | grep -q "${TOKEN}" || { build_ok=no ;fail_reasons=${fail_reasons}" wget_80" ; } ;

   echo ; } ;


which php &>/dev/null && {

runtst=no
which apache2ctl &>/dev/null && runtst=yes
which nginx &>/dev/null && runtst=yes

[[ "${runtst}" = "yes" ]] && {

phpmoduleswanted="sqlite3 mysqli pgsql pdo_mysql pdo_pgsql soap sockets dom fileinfo imap zip   xml xmlreader xmlwriter  redis memcached imagick imap gd ldap gnupg "
echo "###################"
echo "PHP:"$(php --version|cut -d" " -f2) | yellow
echo -n "PHP_CLI_MODULES:"|purple ;
phpcliinfo=$(php -r 'phpinfo();')
for modtest in ${phpmoduleswanted} ;do
  echo "$phpcliinfo"|grep -i "${modtest}\.ini" -q  || { build_ok=no ;fail_reasons=${fail_reasons}" php_cli_phpinfo_grep_$modtest" ;
                                                          echo -n " $modtest";echo -n ":FAIL"|red; } ;
  echo "$phpcliinfo"|grep  "${modtest}\.ini"   -q  && {   echo -n " $modtest" ; echo -n ":OK"|blue ; } ;
done

echo

echo -n "PHP_CURL_MODULES:"|lightblue ;
echo '<?php
phpinfo(); ' > /var/www/html/phi.php
curl_result=$(curl -kLv https://127.0.0.1/phi.php 2>/dev/shm/curl_ERR_log)

for modtest in ${phpmoduleswanted};do

  echo "$curl_result"|grep  "${modtest}\.ini" -q  || { build_ok=no ;fail_reasons=${fail_reasons}" php_curl_phpinfo_grep_$modtest" ;
                                                          echo -n " $modtest" ; echo -n ":FAIL"|red ; } ;
  echo "$curl_result"|grep  "${modtest}\.ini" -q  && {    echo -n " $modtest" ; echo -n ":OK"|blue ; } ;
done

echo

echo "$curl_result" |grep -q "phpinfo" || { build_ok=no ;fail_reasons=${fail_reasons}" phpinfo_grep_phpinfo_443" ; } ;
echo "$curl_result" |grep -q "display_errors" || { build_ok=no ;fail_reasons=${fail_reasons}" phpinfo_grep_display_errors_443" ; } ;

curl_result=$(curl -kLv http://127.0.0.1/phi.php 2>/dev/shm/curl_ERR_log)
echo "$curl_result" |grep -q "phpinfo" || { build_ok=no ;fail_reasons=${fail_reasons}" phpinfo_curl_grep_phpinfo_80" ; } ;
echo "$curl_result" |grep -q "display_errors" || { build_ok=no ;fail_reasons=${fail_reasons}" phpinfo_curl_grep_display_errors_80" ; } ;

echo -n ; } ;
echo ; } ;


echo "###################"
echo -n "IMAGICK:" | yellow
which identify  &>/dev/null || { echo "FAILED"|red ; } ;
which identify  &>/dev/null && {
  echo -n " binary present .."|blue ;echo -n " testing webp in build:  "|yellow;
  echo
  echo -n "IMAGICK_CLI_WEBP"
  identify --version |grep -i -q webp || { build_ok=no ;fail_reasons=${fail_reasons}" webp_build" ;echo FAIL |red ; }
  identify --version |grep -i -q webp && echo OK |green ;

  which php &>/dev/null && {

    echo -n "IMAGICK_PHP_CLI:"   | yellow
    phpclires=$(php -r 'phpinfo();' )
    echo "${phpclires}" |grep -q -i webp || { build_ok=no ;fail_reasons=${fail_reasons}" webp_phpcli" ; } ;
    echo "${phpclires}" |grep -q -i webp && { echo OK |green ; } || { echo FAIL |red ; } ;

    echo -n "IMAGICK_PHP_CURL:"  | yellow
    echo '<?php
  phpinfo(); ' > /var/www/html/phi.php
  curl_result=$(curl -kLv https://127.0.0.1/phi.php 2>/dev/shm/curl_ERR_log)
    phpwebres=$(echo "$curl_result" )
    echo "${phpwebres}" |grep -q -i webp || { build_ok=no ;fail_reasons=${fail_reasons}" webp_curl" ; } ;
    echo "PHP(-FPM):"$(echo "${phpwebres}" |grep -q -i webp && { echo OK |green ; } || { echo FAIL |red ; } ; );

  echo -n ; } ;

echo ; } ;



test_sql=no
supervisorctl status 2>&1 | grep -q -e mysql -e mariadb  && test_sql=yes
which mysqld mariadbd|grep -q -e mysql -e mariadb && test_sql=yes
[[ "${test_sql}" = "yes" ]] && {
echo "##########"
echo "SQL: mariadb OR mysql detected"|blue
mysql -e "show databases;use mysql;show tables" |grep -q user  || { build_ok=no ;fail_reasons=${fail_reasons}" mysql_no_user_in_mysql_mysql" ; }  ;
mysql -e "use mysql;select * from user " |grep -q  user  || { build_ok=no ;fail_reasons=${fail_reasons}" mysql_no_user_in_mysql_user" ;  }  ;
echo ; };

echo -n "CRON:" | green
echo "waiting for cron verification" |red
start=$(date -u +%s);
#echo "started at "$start

## wait 120 seconds for cron to start ( should do it after 1 minute after init , see above )
while ! test -f "/tmp/crontest.file" ; do
    # just create it after 120 seconds to get out of loop hell
    [[ $(($(date -u +%s)-${start})) -gt 120 ]] && { echo;echo CRON::"TIMEOUT $(($(date -u +%s)-${start}))" ;  echo TIMEOUT >  /tmp/crontest.file ; } ;
    echo -ne $(
      echo -n "waiting since "$(($(date -u +%s)-${start}))" seconds | cron:"| blue |tr -d '\r\n';
      ps aux|grep cron |grep -v grep|red |tr -d '\r\n';
      echo -e " |logs: ";tail -c 70 /dev/shm/startlog |green |tr -d '\r\n'
    )'\r'  ;sleep 1;sleep 0.5; ## openwrt might not sleep 0.x
done

test -f /tmp/crontest.file && ls -lh1 /tmp/crontest.file && cat /tmp/crontest.file
test -f /tmp/crontest.file || { build_ok=no ;fail_reasons=${fail_reasons}" cron_not_running" ; }  ;

echo "################"

echo

echo "result after "$(($(date -u +%s)-${scriptstart}))" seconds " |lightblue
echo "build_ok:"$build_ok
[[ -z "${fail_reasons// /}" ]] || echo "FAILED: "${fail_reasons}|red
