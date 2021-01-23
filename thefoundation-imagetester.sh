#!/bin/bash


waittime="$1"
[[ -z "$waittime" ]] && waittime=2



[[ -z "${MAIL_HOST}" ]]             && export MAIL_HOST=localhost
[[ -z "${APP_URL}" ]]               && export APP_URL=localtest.lan
[[ -z "${MAIL_USERNAME}" ]]         && export MAIL_USERNAME=testLocalImage
[[ -z "${MAIL_PASSWORD}" ]]         && export MAIL_PASSWORD=testLocalPass
[[ -z "${MYSQL_ROOT_PASSWORD}" ]]   && export MYSQL_ROOT_PASSWORD=ImageTesterRoot
[[ -z "${MYSQL_USERNAME}" ]]        && export MYSQL_USERNAME=ImageTestUser
[[ -z "${MYSQL_PASSWORD}" ]]        && export MYSQL_PASSWORD=ImageTestPW
[[ -z "${MYSQL_DATABASE}" ]]        && export MYSQL_DATABASE=ImageTestDB
[[ -z "${MARIADB_REMOTE_ACCESS}" ]] && export MARIADB_REMOTE_ACCESS=true

## docker run -v /path/to/build/_1_php-initprep.sh:/_1_php-initprep.sh:ro -v /tmp/_image_tests.sh:/_image_tests.sh --rm -it thefoundation/hocker:php7.4-dropbear-fpm /bin/bash /_image_tests.sh

## Colors ;
uncolored="\033[0m" ; black="\033[0;30m" ; blackb="\033[1;30m" ; white="\033[0;37m" ; whiteb="\033[1;37m" ; red="\033[0;31m" ; redb="\033[1;31m" ; green="\033[0;32m" ; greenb="\033[1;93m" ; yellow="\033[0;33m" ; yellowb="\033[1;33m" ; blue="\033[0;34m" ; blueb="\033[1;34m" ; purple="\033[0;35m" ; purpleb="\033[1;35m" ; lightblue="\033[0;36m" ; lightblueb="\033[1;36m" ;  function black {   echo -en "${black}${1}${uncolored}" ; } ;    function blackb {   echo -en "${blackb}";cat;echo -en "${uncolored}" ; } ;   function white {   echo -en "${white}";cat;echo -en "${uncolored}" ; } ;   function whiteb {   echo -en "${whiteb}";cat;echo -en "${uncolored}" ; } ;   function red {   echo -en "${red}";cat;echo -en "${uncolored}" ; } ;   function redb {   echo -en "${redb}";cat;echo -en "${uncolored}" ; } ;   function green {   echo -en "${green}";cat;echo -en "${uncolored}" ; } ;   function greenb {   echo -en "${greenb}";cat;echo -en "${uncolored}" ; } ;   function yellow {   echo -en "${yellow}";cat;echo -en "${uncolored}" ; } ;   function yellowb {   echo -en "${yellowb}";cat;echo -en "${uncolored}" ; } ;   function blue {   echo -en "${blue}";cat;echo -en "${uncolored}" ; } ;   function blueb {   echo -en "${blueb}";cat;echo -en "${uncolored}" ; } ;   function purple {   echo -en "${purple}";cat;echo -en "${uncolored}" ; } ;   function purpleb {   echo -en "${purpleb}";cat;echo -en "${uncolored}" ; } ;   function lightblue {   echo -en "${lightblue}";cat;echo -en "${uncolored}" ; } ;   function lightblueb {   echo -en "${lightblueb}";cat;echo -en "${uncolored}" ; } ;  function echo_black {   echo -en "${black}${1}${uncolored}" ; } ; function echo_blackb {   echo -en "${blackb}${1}${uncolored}" ; } ;   function echo_white {   echo -en "${white}${1}${uncolored}" ; } ;   function echo_whiteb {   echo -en "${whiteb}${1}${uncolored}" ; } ;   function echo_red {   echo -en "${red}${1}${uncolored}" ; } ;   function echo_redb {   echo -en "${redb}${1}${uncolored}" ; } ;   function echo_green {   echo -en "${green}${1}${uncolored}" ; } ;   function echo_greenb {   echo -en "${greenb}${1}${uncolored}" ; } ;   function echo_yellow {   echo -en "${yellow}${1}${uncolored}" ; } ;   function echo_yellowb {   echo -en "${yellowb}${1}${uncolored}" ; } ;   function echo_blue {   echo -en "${blue}${1}${uncolored}" ; } ;   function echo_blueb {   echo -en "${blueb}${1}${uncolored}" ; } ;   function echo_purple {   echo -en "${purple}${1}${uncolored}" ; } ;   function echo_purpleb {   echo -en "${purpleb}${1}${uncolored}" ; } ;   function echo_lightblue {   echo -en "${lightblue}${1}${uncolored}" ; } ;   function echo_lightblueb {   echo -en "${lightblueb}${1}${uncolored}" ; } ;    function colors_list {   echo_black "black";   echo_blackb "blackb";   echo_white "white";   echo_whiteb "whiteb";   echo_red "red";   echo_redb "redb";   echo_green "green";   echo_greenb "greenb";   echo_yellow "yellow";   echo_yellowb "yellowb";   echo_blue "blue";   echo_blueb "blueb";   echo_purple "purple";   echo_purpleb "purpleb";   echo_lightblue "lightblue";   echo_lightblueb "lightblueb"; } ;


echo "INIT:imagetester"|yellow
test -e /etc/container-build-time && echo "MAIN CONTAINER WAS BUILT AT:"$(cat  /etc/container-build-time)

start=$(date -u +%s);
scriptstart=$start

/bin/bash /usr/local/bin/run.sh   &>/dev/shm/startlog &

echo "docker CI test started at "$(date) | green
sleep 3
# wait for supervisor socket
while ! test -f "/var/run/supervisord.pid" ; do
  [[ $(($(date -u +%s)-${start})) -gt 120 ]] && exit 999
      echo -ne "init:waiting since "$(($(date -u +%s)-${start}))" seconds for supervisor socket"|red ;echo -ne $(tail -n2 /dev/shm/startlog|tail -c 99  |tr -d '\r\n' ) '\r';sleep 2;
    done
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
      echo -ne "init:waiting since "$(($(date -u +%s)-${start}))" seconds for "$(supervisorctl status 2>&1 | grep -i -e php-fpm -e apache -e nginx |cut -f1|cut -d" " -f1)|red ;echo -ne $(tail -n2 /dev/shm/startlog|tail -c 84  |tr -d '\r\n' ) '\r';sleep 2;
    done

echo sleeping 5s

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
                                                                          echo;echo "FAIL( $term )" |red; } ;
                             echo "${apache_modules}" |sed 's/(shared)//g'| grep -q "${term}_module" && echo "OK($term)" ;
                             echo -n " " ; } ;
        done |tr -d '\n'
echo


for apaconfig in $(find /etc/apache2/sites-enabled/ -mindepth 1 );do
grep -q "AccessLog" ${apaconfig} && grep "AccessLog" ${apaconfig} |  grep -q "stdout" || {  echo -n " apache_log_not_stdout_"$(echo ${apaconf//.conf}|sed 's/.\+\///g' )  >> /dev/shm/apache_fails ;
                                                  echo;echo "FAIL( missing  AccessLog STDOUT redirect in $apaconfig ,val: "$(grep AccessLog ${apaconfig} )" )" |red ; } ;
grep -q "CustomLog" ${apaconfig} && grep "CustomLog" ${apaconfig} |  grep -q "stdout" || {  echo -n " apache_log_not_stdout_"$(echo ${apaconf//.conf}|sed 's/.\+\///g' )  >> /dev/shm/apache_fails ;
                                                  echo;echo "FAIL( missing  CustomLog STDOUT redirect in $apaconfig ,val: "$(grep CustomLog ${apaconfig} )" )" |red ; } ;
grep -q "ErrorLog"  ${apaconfig} && grep "ErrorLog"  ${apaconfig} |  grep -q "stderr" || {  echo -n " apache_errlog_not_stderr_"$(echo ${apaconf//.conf}|sed 's/.\+\///g' )  >> /dev/shm/apache_fails ;
                                                  echo;echo "FAIL( missing   ErrorLog STDERR redirect in $apaconfig ,val: "$(grep ErrorLog  ${apaconfig} ) " )" |red ; } ;
done

fail_reasons="$(cat /dev/shm/apache_fails)"
echo "$fail_reasons" |wc -w|grep ^0 || build_ok=no
#echo;echo "FAILs round 1 :"$fail_reasons

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
PHPLONGVersion=$(php -r'echo PHP_VERSION;')
PHPVersion=$(echo $PHPLONGVersion|sed 's/^\([0-9]\+.[0-9]\+\).\+/\1/g');
[[ -z "${PHPVersion}" ]] &&  { build_ok=no ;fail_reasons=${fail_reasons}" php_version_not_found" ; } ;

echo "PHP:"${PHPVersion} | yellow
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


echo ; } ; ## end which php


echo "###################"
echo -n "IMAGICK:" | yellow
which identify  &>/dev/null || { echo;echo "FAILED"|red ; } ;
which identify  &>/dev/null && {
  echo -n " binary present .."|blue ;echo -n " testing webp in build:  "|yellow;
  echo
  echo -n "IMAGICK_CLI_WEBP:"|green
  identify --version |grep -i -q webp || { build_ok=no ;fail_reasons=${fail_reasons}" webp_build" ;echo FAIL |red ; }
  identify --version |grep -i -q webp && echo OK |green ;

which php &>/dev/null && {
    echo -n "IMAGICK_PHP_CLI:"   | blue
    phpclires=$(php -r 'phpinfo();' )
    echo "${phpclires}" |grep -q -i webp || { build_ok=no ;fail_reasons=${fail_reasons}" webp_phpcli" ; } ;
    echo "${phpclires}" |grep -q -i webp && { echo OK |green ; } || { echo FAIL |red ; } ;

    echo -n "IMAGICK_PHP_CURL:"  | purple
    echo '<?php
  phpinfo(); ' > /var/www/html/phi.php
  curl_result=$(curl -kLv https://127.0.0.1/phi.php 2>/dev/shm/curl_ERR_log)
    phpwebres=$(echo "$curl_result" )
    echo "${phpwebres}" |grep -q -i webp || { build_ok=no ;fail_reasons=${fail_reasons}" webp_curl" ; } ;
    echo "PHP(-FPM):"$(echo "${phpwebres}" |grep -q -i webp && { echo OK |green ; } || { echo FAIL |red ; } ; );

  echo -n ; } ;

echo ; } ;

### MAIL

echo "#########"
echo -n "MAILS:";echo -n $(echo " | sendmail: " $(which sendmail && file $(which sendmail|cut -d, -f1) );echo)
echo -n "MAILS:"echo -n " | msmtp: ";which msmtp && file $(which msmtp) ;echo " |";echo
### see if the configs have sendmail_path
mail_setting_found=false

for configtype in apache2 cli fpm;do
    configdir=/etc/php/${PHPVersion}/${configtype}
    echo -n "MAIL_PHP_$configtype :"|blue
    configfile=""
    test -d ${configdir}/conf.d || { build_ok=no ;fail_reasons=${fail_reasons}" NOT_FOUND_$configdir" ; } ;
    mailini=${configdir}/conf.d/30-php-mail.ini
    test -d ${configdir}/conf.d && test -e ${mailini} && grep  -q "/usr/bin/msmtp" ${mailini} && configfile="${configdir}/conf.d/30-php-mail.ini"
    test -d ${configdir}/conf.d && test -e ${mailini} || mailini=${configdir}/php.ini
    ##
    grep "^sendmail_path" ${mailini} |grep -q "/usr/bin/msmtp -t" || { build_ok=no ;fail_reasons=${fail_reasons}" sendmail_path_$mailini" ; echo;echo "FAIL(sendmail_path ${mailini} )" | red   ; }
    grep "^sendmail_path" ${mailini} |grep -q "/usr/bin/msmtp -t" && {  echo "OK(${mailini})"  ; } ;
done



###### SQL TEST


test_sql=no
supervisorctl status 2>&1 | grep -q -e mysql -e mariadb  && test_sql=yes
which mysqld mariadbd|grep -q -e mysql -e mariadb && test_sql=yes
[[ "${test_sql}" = "yes" ]] && {

echo "Y3JlYXRlIHRhYmxlIHRibEVtcGxveWVlCigKRW1wbG95ZWVfaWQgaW50IGF1dG9faW5jcmVtZW50IHByaW1hcnkga2V5LApFbXBsb3llZV9maXJzdF9uYW1lIHZhcmNoYXIoNTAwKSBOT1QgbnVsbCwKRW1wbG95ZWVfbGFzdF9uYW1lIHZhcmNoYXIoNTAwKSBOT1QgbnVsbCwKRW1wbG95ZWVfQWRkcmVzcyB2YXJjaGFyKDEwMDApLApFbXBsb3llZV9lbWFpbElEIHZhcmNoYXIoNTAwKSwKRW1wbG95ZWVfZGVwYXJ0bWVudF9JRCBpbnQgZGVmYXVsdCA5LApFbXBsb3llZV9Kb2luaW5nX2RhdGUgZGF0ZSAKKTsKSU5TRVJUIElOVE8gdGJsRW1wbG95ZWUgKGVtcGxveWVlX2ZpcnN0X25hbWUsIGVtcGxveWVlX2xhc3RfbmFtZSkgdmFsdWVzICgnTmlzYXJnJywnVXBhZGh5YXknKTsKCg==" | base64 -d > /tmp/sqlstatement.sql


echo "##########"
echo "SQL: mariadb OR mysql detected"|blue
### imort our test file
echo                      | mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "create database $MYSQL_DATABASE ; use $MYSQL_DATABASE ;" &>/dev/null
cat /tmp/sqlstatement.sql | mysql -u root -p${MYSQL_ROOT_PASSWORD} $MYSQL_DATABASE  2>&1
### try to blindly create it again should say "database exists" since init did that for us
mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "create database $MYSQL_DATABASE ;use $MYSQL_DATABASE ;" 2>&1  |grep "ImageTestDB" |grep -q "database exists"  || { build_ok=no ;fail_reasons=${fail_reasons}" mysql_database_not_existing_after_import" ; }  ;

su -s /bin/bash -c 'mysql -e "show databases;use ${MYSQL_DATABASE} ; select * from tblEmployee where 1 = 1 ;"' www-data |grep -q Upadhya  || { build_ok=no ;fail_reasons=${fail_reasons}" mysql_no_user_in_mysql_mysql" ; }  ;
mysql -e "use mysql;select * from user " |grep  -e mysql -e native -e root |wc -l |grep -q ^0 && { build_ok=no ;fail_reasons=${fail_reasons}" mysql_no_searchtermss_in_mysql_user" ;  }  ;
echo ; };

echo -n "CRON:" | green
echo "waiting for cron verification" |red


start=$(date -u +%s);
#echo "started at "$start

## wait 120 seconds for cron to start ( should do it after 1 minute after init , see above )
while ! test -f "/tmp/crontest.file" ; do
    # just create it after 120 seconds to get out of loop hell
    [[ $(($(date -u +%s)-${start})) -gt 120 ]] && { echo;echo CRON::"TIMEOUT $(($(date -u +%s)-${start}))" ;  echo TIMEOUT >  /tmp/crontest.file ; } ;

    echo -n " |logs: ";tail -c 70 /dev/shm/startlog |green |tr -d '\r\n'
    echo -n "waiting since "$(($(date -u +%s)-${start}))" seconds | cron:"| blue |tr -d '\r\n';
    ps aux|grep cron |grep -v grep| head -c 50|red |tr -d '\r\n';
    echo -ne '\r'  ;
    sleep 1;sleep 0.5; ## openwrt might not sleep 0.x
done

test -f /tmp/crontest.file && ls -lh1 /tmp/crontest.file && cat /tmp/crontest.file
test -f /tmp/crontest.file || { build_ok=no ;fail_reasons=${fail_reasons}" cron_not_running" ; }  ;

echo "################"

echo

echo "result after "$(($(date -u +%s)-${scriptstart}))" seconds " |lightblue
echo "build_ok:"$build_ok
[[ -z "${fail_reasons// /}" ]] || echo;echo "FAILED: "${fail_reasons}|red


echo sleeping $waittime
sleep $waittime
