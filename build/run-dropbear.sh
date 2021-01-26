#!/bin/bash
#set -x
#trap read debug

# Trap interrups
trap 'bash /shutdown.sh ; sleep 4  ; exit;'  SIGINT
trap 'bash /shutdown.sh  ; sleep 4  ; exit;' SIGTERM

test -e /etc/rc.local.fg && cat /etc/rc.local |grep ^exit && { echo " sys.info  | DETECTED rc.local.fg ..running in foreground" ; /bin/bash /etc/rc.local & echo ; } ;

test -e /etc/rc.local   && cat /etc/rc.local  |grep ^exit && { echo " sys.info  | DETECTED rc.local    ..running forked       " ; /bin/bash /etc/rc.local & echo ; } ;



## FUNCTIONS
## Colors ;
_kill_maria() {
service mariadb stop &>/dev/null &
service mysql stop &>/dev/null &
wait

mariapids() { $(pidof $(which mysqld mysqld_safe mariadbd ) mysqld mysqld_safe mariadbd )  ; } ;
[[ -z $(mariapids) ]] ||  kill -QUIT $(mariapids) &
sleep 0.3
ps aux|grep -q -e mysqld -e mariadbd && {
kill  -QUIT  2>/dev/null &
sleep 1
[[ -z $(mariapids) ]] ||  kill -QUIT $(mariapids)
[[ -z $(mariapids) ]] ||  kill -KILL $(mariapids) 2>/dev/null &
sleep 0.1 ; } ;
wait ;

echo ; } ;

[[ -z "$MARIADB_HOST" ]]          && [[ -z "$MYSQL_HOST" ]]   && MYSQL_HOST=127.0.0.1
## be standards compatible ;)
[[ -z "$MARIADB_HOST" ]]          && [[ ! -z "$MYSQL_HOST" ]]             &&   export MARIADB_HOST=${MYSQL_HOST}
[[ -z "$MARIADB_USERNAME" ]]      && [[ ! -z "$MYSQL_USER" ]]             &&   export MARIADB_USER=${MYSQL_USERNAME}
[[ -z "$MARIADB_DATABASE" ]]      && [[ ! -z "$MYSQL_DATABASE" ]]         &&   export MARIADB_DATABASE=${MYSQL_DATABASE}
[[ -z "$MARIADB_PASSWORD" ]]      && [[ ! -z "$MYSQL_PASSWORD" ]]         &&   export MARIADB_PASSWORD=${MYSQL_PASSWORD}
[[ -z "$MARIADB_ROOT_PASSWORD" ]] && [[ ! -z "$MYSQL_ROOT_PASSWORD" ]]    &&   export MARIADB_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
[[ -z "$MARIADB_REMOTE_ACCESS" ]] && [[ ! -z "$MYSQL_REMOTE_ACCESS" ]]    &&   export MARIADB_REMOTE_ACCESS=${MYSQL_REMOTE_ACCESS}
[[ -z "$MYSQL_HOST" ]]            && [[ ! -z "$MARIADB_HOST" ]]           &&   export MYSQL_HOST=${MARIADB_HOST}
[[ -z "$MYSQL_USERNAME" ]]        && [[ ! -z "$MARIADB_USERNAME" ]]       &&   export MYSQL_USERNAME=${MARIADB_USERNAME}
[[ -z "$MYSQL_DATABASE" ]]        && [[ ! -z "$MARIADB_DATABASE" ]]       &&   export MYSQL_DATABASE=${MARIADB_DATABASE}
[[ -z "$MYSQL_PASSWORD" ]]        && [[ ! -z "$MARIADB_PASSWORD" ]]       &&   export MYSQL_PASSWORD=${MARIADB_PASSWORD}
[[ -z "$MYSQL_ROOT_PASSWORD" ]]   && [[ ! -z "$MARIADB_ROOT_PASSWORD" ]]  &&   export MYSQL_ROOT_PASSWORD=${MARIADB_ROOT_PASSWORD}
[[ -z "$MYSQL_REMOTE_ACCESS" ]]   && [[ ! -z "$MARIADB_REMOTE_ACCESS" ]]  &&   export MYSQL_REMOTE_ACCESS=${MARIADB_REMOTE_ACCESS}

###
## laravel renamed from APP_MAIL_DRIVER to APP_MAIL_MAILER , dizzy devs may only define MAIL_DRIVER
[[ -z "$APP_MAIL_MAILER" ]]   && [[ ! -z "$MAIL_DRIVER" ]] && export APP_MAIL_MAILER=${MAIL_DRIVER}
## inverse fill
[[ -z "$MAIL_DRIVER" ]]   && [[ ! -z "$APP_MAIL_DRIVER" ]] && export MAIL_DRIVER=${APP_MAIL_DRIVER}




uncolored="\033[0m" ; black="\033[0;30m" ; blackb="\033[1;30m" ; white="\033[0;37m" ; whiteb="\033[1;37m" ; red="\033[0;31m" ; redb="\033[1;31m" ; green="\033[0;32m" ; greenb="\033[1;93m" ; yellow="\033[0;33m" ; yellowb="\033[1;33m" ; blue="\033[0;34m" ; blueb="\033[1;34m" ; purple="\033[0;35m" ; purpleb="\033[1;35m" ; lightblue="\033[0;36m" ; lightblueb="\033[1;36m" ;
function black {   echo -en "${black}${1}${uncolored}" ; } ;    function blackb {   echo -en "${blackb}";cat;echo -en "${uncolored}" ; } ;   function white {   echo -en "${white}";cat;echo -en "${uncolored}" ; } ;   function whiteb {   echo -en "${whiteb}";cat;echo -en "${uncolored}" ; } ;   function red {   echo -en "${red}";cat;echo -en "${uncolored}" ; } ;   function redb {   echo -en "${redb}";cat;echo -en "${uncolored}" ; } ;   function green {   echo -en "${green}";cat;echo -en "${uncolored}" ; } ;   function greenb {   echo -en "${greenb}";cat;echo -en "${uncolored}" ; } ;   function yellow {   echo -en "${yellow}";cat;echo -en "${uncolored}" ; } ;   function yellowb {   echo -en "${yellowb}";cat;echo -en "${uncolored}" ; } ;   function blue {   echo -en "${blue}";cat;echo -en "${uncolored}" ; } ;   function blueb {   echo -en "${blueb}";cat;echo -en "${uncolored}" ; } ;   function purple {   echo -en "${purple}";cat;echo -en "${uncolored}" ; } ;   function purpleb {   echo -en "${purpleb}";cat;echo -en "${uncolored}" ; } ;   function lightblue {   echo -en "${lightblue}";cat;echo -en "${uncolored}" ; } ;   function lightblueb {   echo -en "${lightblueb}";cat;echo -en "${uncolored}" ; } ;  function echo_black {   echo -en "${black}${1}${uncolored}" ; } ; function echo_blackb {   echo -en "${blackb}${1}${uncolored}" ; } ;   function echo_white {   echo -en "${white}${1}${uncolored}" ; } ;   function echo_whiteb {   echo -en "${whiteb}${1}${uncolored}" ; } ;   function echo_red {   echo -en "${red}${1}${uncolored}" ; } ;   function echo_redb {   echo -en "${redb}${1}${uncolored}" ; } ;   function echo_green {   echo -en "${green}${1}${uncolored}" ; } ;   function echo_greenb {   echo -en "${greenb}${1}${uncolored}" ; } ;   function echo_yellow {   echo -en "${yellow}${1}${uncolored}" ; } ;   function echo_yellowb {   echo -en "${yellowb}${1}${uncolored}" ; } ;   function echo_blue {   echo -en "${blue}${1}${uncolored}" ; } ;   function echo_blueb {   echo -en "${blueb}${1}${uncolored}" ; } ;   function echo_purple {   echo -en "${purple}${1}${uncolored}" ; } ;   function echo_purpleb {   echo -en "${purpleb}${1}${uncolored}" ; } ;   function echo_lightblue {   echo -en "${lightblue}${1}${uncolored}" ; } ;   function echo_lightblueb {   echo -en "${lightblueb}${1}${uncolored}" ; } ;    function colors_list {   echo_black "black";   echo_blackb "blackb";   echo_white "white";   echo_whiteb "whiteb";   echo_red "red";   echo_redb "redb";   echo_green "green";   echo_greenb "greenb";   echo_yellow "yellow";   echo_yellowb "yellowb";   echo_blue "blue";   echo_blueb "blueb";   echo_purple "purple";   echo_purpleb "purpleb";   echo_lightblue "lightblue";   echo_lightblueb "lightblueb"; } ;

_clock() { echo -n WALLCLOCK : |redb ;echo  $( date -u "+%F %T" ) |yellow ; } ;

_supervisor_update() { ( supervisorctl reread;supervisorctl update;supervisorctl start all ) 2>&1 |grep -vi "no config updates" ; } ;
_supervisor_generate_artisanqueue() { ###supervisor queue:work

    for artisanfile in $(find /var/www -maxdepth 2 -name artisan 2>/dev/null|grep -v   -e "\.failed/artisan" -e "\.backup/artisan" -e "\.bak/artisan" -e "OLD/artisan" -e  "old/artisan"  |head -n1 ) ;do

          #
          test -e /dev/shm/.notified.queuedriver_${artisanfile//\//_} || {
              grep -e ^QUEUE_CONNECTION=sync -e ^QUEUE_DRIVER=sync  $(dirname $artisanfile)/.env -q && { sleep 20; echo "  sys.hint | NOT ENABLING SUPERVISOR ARTISAN QUEUE BECAUSE QUEUE=sync in .env" |lightblue; touch /dev/shm/.notified.queuedriver_${artisanfile//\//_} ; } &
                                                                                  echo -ne $uncolored ; } ;

          grep -q -e QUEUE_CONNECTION=sync -e QUEUE_DRIVER=sync  $(dirname $artisanfile)/.env  && test -e /etc/supervisor/conf.d/queue_${artisanfile//\//_}.conf || php ${artisanfile} 2>&1 |grep -q queue:work  && test -e $(dirname $artisanfile)/.env &&  grep -q -e ^QUEUE_CONNECTION=sync -e ^QUEUE_DRIVER=sync  $(dirname $artisanfile)/.env ||  (
          test -e  /etc/supervisor/conf.d/queue_${artisanfile//\//_}.conf || {
          echo " sys.info  | generating queue for $artisanfile"
## NOTE : max-jobs seems missing often , so restart helps to free memory , stop when empty heats up supervisor
##
##command=/supervisor-logger /usr/bin/php ${artisanfile} queue:work --timeout=14400 --sleep=0 --tries=2 --no-interaction --memory=2048
                         cat > /etc/supervisor/conf.d/queue_${artisanfile//\//_}.conf << EOF
[program:laravel-worker]
process_name=%(program_name)s_%(process_num)02d
command=/usr/bin/php ${artisanfile} queue:work --timeout=14400 --sleep=3 --tries=3 --no-interaction --memory=2048
autostart=true
autorestart=true
user=www-data
numprocs=2
redirect_stderr=true
stdout_logfile=/dev/stdout
stderr_logfile=/dev/stderr
stdout_logfile_maxbytes=0
stderr_logfile_maxbytes=0
stopasgroup=true
killasgroup=true
EOF

 _supervisor_update
echo -ne $uncolored ; } ;
                    ) ; done   ; } ;


_supervisor_generate_websockets() { ## supervisor:websockets:run

                    for artisanfile in $(find /var/www -maxdepth 2 -name artisan 2>/dev/null|grep -v  -e "\.bak/artisan" -e "\.OLD/artisan" -e  "\.old/artisan"  |head -n1 ) ;do
                        php ${artisanfile} 2>&1 |grep -q websockets:run  && (
                        test -e /etc/supervisor/conf.d/websockets_${artisanfile//\//_}.conf || echo "sys.info   | ->artisan:websockets starting"
                        test -e /etc/supervisor/conf.d/websockets_${artisanfile//\//_}.conf || cat > /etc/supervisor/conf.d/websockets_${artisanfile//\//_}.conf << EOF
[program:websockets]
command=/supervisor-logger bin/bash -c 'cd /var/www/html/;php artisan websockets:run'
user=www-data
stdout_logfile=/dev/stdout
stderr_logfile=/dev/stderr
stdout_logfile_maxbytes=0
stderr_logfile_maxbytes=0
autorestart=true

EOF

_supervisor_update

  ) ;done   ; } ;




##

echo "::STARTING"


### www shell shortcut
(echo '#!/bin/bash' ;echo "su -s /bin/bash www-data")> /usr/bin/wwwsh;chmod +x /usr/bin/wwwsh


###TIME
if [ -z "${APP_TIMEZONE}" ] ; then
    echo "TIMEZONE NOT SET, USE APP_TIMEZONE= in .env, setting  default";
    /bin/ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime  ;
else
    echo "SETTING TIMEZONE  ";
    test -e /usr/share/zoneinfo/${APP_TIMEZONE} || echo "TIMEZONE GIVEN DOES NOT EXIST"
    test -e /usr/share/zoneinfo/${APP_TIMEZONE} && /bin/ln -sf /usr/share/zoneinfo/${APP_TIMEZONE} /etc/localtime;
fi



mkdir /dev/shm/startlogs

##prepare mariadb/mysql
_prep_sql()    { /bin/bash /_1_sql-initprep.sh 2>&1 |tee /dev/shm/startlogs/sql      |sed -u  's/^/ init.sql  | /g;s/$/ |/g' ; } ;
_prep_sql  | blueb | yellow &

##get toolkit
_get_toolkit() {  /bin/bash /_0_get-toolkit.sh  2>&1 |tee /dev/shm/startlogs/toolkit |sed -u  's/^/ init.tool | /g;s/$/ |/g' ; } ;
_get_toolkit | purple &
##fix snakeoil certs
_setup_cert() { /bin/bash /_0_crt-snakeoil.sh 2>&1   |tee /dev/shm/startlogs/certs   |sed -u  's/^/ init.crt  | /g;s/$/ |/g' ; } ;
_setup_cert  | redb |black &


##prepare mongodb
_prep_mongo()  { /bin/bash /_1_sys-mongopre.sh 2>&1 |tee /dev/shm/startlogs/mongo    |sed -u  's/^/ init.mngo | /g;s/$/ |/g' ; } ;
_prep_mongo  | greenb &


##fix dropbear and composer
_init_drpbr()  { /bin/bash /_0_fix-dropbear.sh 2>&1  |tee /dev/shm/startlogs/drobear |sed -u  's/^/ init.ssh  | /g;s/$/ |/g' |tr -d '\n' ;echo ; } ;
_init_drpbr | lightblueb  &

_fix_composr() { /bin/bash /_0_fix-composer.sh &>        /dev/shm/startlogs/composer |sed -u  's/^/ init.cmps | /g;s/$/ |/g' ; } ;
_fix_composr | yellow &


##fix www-data user commons
_init_user()   { /bin/bash /_1_www-userprep.sh 2>&1 |tee /dev/shm/startlogs/userinit |sed -u  's/^/ init.usr  | /g;s/$/ |/g' ; } ;
_init_user &


#MAIL

##fix mail
_fix_mail()    { /bin/bash /_0_sys-mailprep.sh 2>&1 |tee /dev/shm/startlogs/mail     |sed -u  's/^/ init.mail | /g;s/$/ |/g' ; } ;
_fix_mail &

# 2>&1 |tr -d '\n' &


####NOW THE .env party


##php apache fixes
_prep_apache() { /bin/bash /_1_php-initprep.sh 2>&1 |tee /dev/shm/startlogs/phpfix   |sed -u  's/^/ init.web  | /g;s/$/ | /g' ; } ;
_prep_apache | yellowb &

sleep 5

echo "WAITING FOR :"
jobs 2>&1 |grep -e "_fix" -e _init -e _get -e _prep |grep -v "Done"
wait


log_rotate_loop() {
    sleep 20;
    date +%H|grep ^00 && {
      sleep 20
      ( for web_app_log in $( find /var/www/*/storage/logs/ -type f -mtime -1 -name "laravel*.log"  2>/dev/null  ;
                              find /var/www/*/storage/logs/ -type f -mtime -1 -name "system.log"  2>/dev/null
                              find /var/www/html/typo3temp/var/log -name "*.log" -mtime -1 2>/dev/null
                              ); do
        echo " logrotate  | rotating " "${web_app_log}" TO: "${web_app_log}".$(date +%F -d "1 day ago").rotated.log
        mv "${web_app_log}" "${web_app_log}".$(date +%F -d "1 day ago").rotated.log
        done ;

      find /var/www/*/storage/logs/ /var/www/html/typo3temp/var/log -name "*rotated.log" -mtime +30 -delete
      ) &

    echo -ne $uncolored ; } ;
    sleep 14380
echo -ne $uncolored ; } ;

service_loop() {
  ##fix perissions
  chmod g+rx /root/ /root/.ssh/;chgrp www-data /root/ /root/.ssh/
  while (true);do
    sleep 25;
   ## sshmove action
    action=sshmove;
    interval=120
    do_action=false
    test -f /dev/shm/.looptime_$action || { echo 0 > /dev/shm/.looptime_$action ; } ;
    [[ "$(cat /dev/shm/.looptime_$action)" -le $(($(date -u +%s)-${interval})) ]] && do_action=true

    [[ "${do_action}" = "true" ]] && {
        #echo doing $action
        grep  -q /root/.ssh /etc/mtab  && for file in /var/www/.ssh/id_* ;do
        test -e ${file} && {
            test -e  /root/.ssh/${file//\//_} || {
                mv "${file}" "/root/.ssh/${file//\//_}" && ln -s "/root/.ssh/${file//\//_}" "${file}" ; } ;
            chown www-data:www-data /root/.ssh/_var_www_.ssh_id_rsa* 2>/dev/null
            chmod ugo-w /root/.ssh/_var_www_.ssh_id_rsa* 2>/dev/null
            chmod u+r /root/.ssh/_var_www_.ssh_id_rsa* 2>/dev/null
        echo -ne $uncolored ; } ;

      done
    date -u +%s > /dev/shm/.looptime_$action
    echo -ne $uncolored ; } ;
   ##END sshmove action

   ## artisan supervisor action
    action=artisansupervisor;
    interval=180
    do_action=false
    test -f /dev/shm/.looptime_$action || { echo 0 > /dev/shm/.looptime_$action ; } ;
    [[ "$(cat /dev/shm/.looptime_$action)" -le $(($(date -u +%s)-${interval})) ]] && do_action=true

    [[ "${do_action}" = "true" ]] && {
        #echo doing $action
        _supervisor_generate_artisanqueue ;
        _supervisor_generate_websockets ;
    date -u +%s > /dev/shm/.looptime_$action
    echo -ne $uncolored ; } ;
   ##END artisan supervisor action

   ## artisan restartqueue action
    action=artisanqueuerestart;
    interval=3600
    do_action=false
    test -f /dev/shm/.looptime_$action || { echo 0 > /dev/shm/.looptime_$action ; } ;
    [[ "$(cat /dev/shm/.looptime_$action)" -le $(($(date -u +%s)-${interval})) ]] && do_action=true

    [[ "${do_action}" = "true" ]] && {
        #echo doing $action
        echo " sys.info  | queue graceful restart ";
		for artisanfile in $(find /var/www -maxdepth 2 -name artisan 2>/dev/null|grep -v  -e "\.bak/artisan" -e "\.OLD/artisan" -e  "\.old/artisan"  |head -n1 ) ;do
            test -e  /etc/supervisor/conf.d/queue_${artisanfile//\//_}.conf && {
                su -s /bin/bash -c "/usr/bin/php ${artisanfile} queue:restart" www-data ;  } ;
        done
    date -u +%s > /dev/shm/.looptime_$action
    echo -ne $uncolored ; } ;
   ##END artisan restartqueue action

   ## artisan cron action
    action=artisancron;
    interval=180
    do_action=false
    test -f /dev/shm/.looptime_$action || { echo 0 > /dev/shm/.looptime_$action ; } ;
    [[ "$(cat /dev/shm/.looptime_$action)" -le $(($(date -u +%s)-${interval})) ]] && do_action=true

    [[ "${do_action}" = "true" ]] && {
        #echo doing $action
		for artisanfile in $(find /var/www -maxdepth 2 -name artisan 2>/dev/null|grep -v  -e "\.bak/artisan" -e "\.OLD/artisan" -e  "\.old/artisan"  |head -n1 ) ;do
            test -e  /dev/shm.cron.setup.${artisanfile//\//_} ||  {
                CRONCMD='* * * * * /usr/bin/php '${artisanfile}' schedule:run &>/dev/shm/cron_'${artisanfile//\//_}'.sched.log'
                [[ -z "${CRON_ARTISAN_TIMEOUT}" ]] || CRONCMD='* * * * * timeout '${CRON_ARTISAN_TIMEOUT}' /usr/bin/php '${artisanfile}' schedule:run &>/dev/shm/cron_'${artisanfile//\//_}'.sched.log'
                crontab -l -u www-data |grep "schedule:run"|grep "${artisanfile}" -q && { echo " sys.cron  | artisan:schedule:loop -> ALREADY ADDED check manually with: crontab -l -u www-data "|green ;touch /dev/shm.cron.setup.${artisanfile//\//_} ; } ;
                crontab -l -u www-data |grep "schedule:run"|grep "${artisanfile}" -q || {
                echo " sys.cron  | artisan:schedule:loop -> ADDING: $CRONCMD" | lightblue

                (crontab -l -u www-data 2>/dev/null; echo "${CRONCMD}") | crontab -u www-data - ;
                echo -n "restarting cron:";which supervisorctl 2>&1 | grep -q supervisorctl && supervisorctl restart cron |tr -d '\n' &
                touch /dev/shm.cron.setup.${artisanfile//\//_}
                echo -ne $uncolored ; } ;
            ##
            echo -ne $uncolored ; } ;
        done
    date -u +%s > /dev/shm/.looptime_$action
    echo -ne $uncolored ; } ;
   ##END artisan cron action

    sleep 5
  done
echo -ne $uncolored ; } ;
###### END service_loop() ####


test -e /usr/sbin/sendmail.real || (test -e /usr/sbin/sendmail.cron && (mv /usr/sbin/sendmail /usr/sbin/sendmail.real;ln -s /usr/sbin/sendmail.cron /usr/sbin/sendmail))
head -n1 /usr/sbin/sendmail |grep -q bash && { sed 's/\r$//g' -i /usr/sbin/sendmail ; } ;

#ln -sf /dev/stdout /var/log/apache2/access.log
#ln -sf /dev/stderr /var/log/apache2/error.log
#ln -sf /dev/stdout /var/log/apache2/other_vhosts_access.log

echo;

echo ":STARTING:"

if [ "$(which supervisord >/dev/null |wc -l)" -lt 0 ] ;then
## no supervisord section
                    echo "no supervisord,classic start==foregrounding dropbear"
                    /etc/init.d/apache2 start &
                    ##in case of fpm , Dockerfile inserts fpm start right after cron( 2 lines below ), but supervisord should be used anyway
                    service php7.4-fpm start &
                    service cron start &
                    which /etc/init.d/mysql >/dev/null && /etc/init.d/mysql start &
                    which /etc/init.d/mariadb >/dev/null && /etc/init.d/mysql start &
                    which /etc/inid.d/redis-server && { /etc/init.d/redis-server start ; echo never > /sys/kernel/mm/transparent_hugepage/enabled ; } &
                    service_loop &
                    ##artisan queue:work without supervisor
                    for artisanfile in $(ls /var/www/html/artisan /var/www/$(hostname -f)/ /var/www/*/artisan -1 2>/dev/null|grep -v  -e "\.bak/artisan" -e "OLD/artisan" -e  "old/artisan"  |head -n1 ) ;do
                      php ${artisanfile} 2>&1 |grep -q queue:work  && ( while (true) ;do
                        su -s /bin/bash -c '/usr/bin/php '${artisanfile}' queue:work --timeout 0 --sleep=3 --tries=3 --daemon' www-data ;sleep 5;done ) &
                      done
                    exec /usr/sbin/dropbear -j -k -s -g -m -E -F

else

/bin/bash /_2_supervisor_prep.sh

( sleep 30 ;echo " sys.info  | spawning logrotate loop"|green ;log_rotate_loop ) &

( sleep 40 ;echo " sys.info  | spawning service loop"  |green ;service_loop    ) &

##bash dislikes this as a function
#                  _supervisor_logger_err() { sed 's/^[[:digit:]]\{4\}-[[:digit:]]\{2\}-[[:digit:]]\{2\} [[:digit:]]\{2\}:[[:digit:]]\{2\}:[[:digit:]]\{2\},[[:digit:]]\{3\} [[:upper:]]/  sys.err   |\0/g' ; } ;
#                  _supervisor_logger_std() { sed 's/^[[:digit:]]\{4\}-[[:digit:]]\{2\}-[[:digit:]]\{2\} [[:digit:]]\{2\}:[[:digit:]]\{2\}:[[:digit:]]\{2\},[[:digit:]]\{3\} [[:upper:]]/ sys.info   |\0/g' ; } ;
#                   exec $(which supervisord || echo /usr/bin/supervisord) -c /etc/supervisor/supervisord.conf   )  2> >( /usr/bin/_supervisor_logger_err >&2) | /usr/bin/_supervisor_logger_std
#echo "sed 's/^[[:digit:]]\{4\}-[[:digit:]]\{2\}-[[:digit:]]\{2\} [[:digit:]]\{2\}:[[:digit:]]\{2\}:[[:digit:]]\{2\},[[:digit:]]\{3\} [[:upper:]]/ sys.err   | \0/g'" > /usr/bin/_supervisor_logger_err ; chmod +x /usr/bin/_supervisor_logger_err; ls -lh1 /usr/bin/_supervisor_logger_err
#echo "sed 's/^[[:digit:]]\{4\}-[[:digit:]]\{2\}-[[:digit:]]\{2\} [[:digit:]]\{2\}:[[:digit:]]\{2\}:[[:digit:]]\{2\},[[:digit:]]\{3\} [[:upper:]]/ sys.info  | \0/g'" > /usr/bin/_supervisor_logger_std ; chmod +x /usr/bin/_supervisor_logger_std; ls -lh1 /usr/bin/_supervisor_logger_std
mkfifo /dev/shm/supervisor_stderr_pipe
mkfifo /dev/shm/supervisor_stdout_pipe

echo " sys.info  | spawning supervisor"
##failed as well
#while (true);do cat /dev/shm/supervisor_stderr_pipe | sed 's/^[[:digit:]]\{4\}-[[:digit:]]\{2\}-[[:digit:]]\{2\} [[:digit:]]\{2\}:[[:digit:]]\{2\}:[[:digit:]]\{2\},[[:digit:]]\{3\} [[:upper:]]/ sys.info  | \0/g'  >/dev/stdout;sleep 0.2;done &
#while (true);do cat /dev/shm/supervisor_stdout_pipe | sed 's/^[[:digit:]]\{4\}-[[:digit:]]\{2\}-[[:digit:]]\{2\} [[:digit:]]\{2\}:[[:digit:]]\{2\}:[[:digit:]]\{2\},[[:digit:]]\{3\} [[:upper:]]/ sys.err   | \0/g'  > /dev/stderr;sleep 0.2;done &
#    exec $(which supervisord || echo /usr/bin/supervisord) -c /etc/supervisor/supervisord.conf   2>/dev/shm/supervisor_stderr_pipe 1>/dev/shm/supervisor_stdout_pipe

exec $(which supervisord || echo /usr/bin/supervisord) -c /etc/supervisor/supervisord.conf 2>&1 | awk '!NF || !seen[$0]++' | sed -u 's/^[[:digit:]]\{4\}-[[:digit:]]\{2\}-[[:digit:]]\{2\} [[:digit:]]\{2\}:[[:digit:]]\{2\}:[[:digit:]]\{2\},[[:digit:]]\{3\} [[:upper:]]/ sys.init  | \0/g'  > /dev/stdout

fi
