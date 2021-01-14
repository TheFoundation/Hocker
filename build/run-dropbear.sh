#!/bin/bash
#set -x
#trap read debug

test -e /etc/rc.local.fg && cat /etc/rc.local |grep ^exit && { echo "DETECTED rc.local ..running forked" ; /bin/bash /etc/rc.local & echo ; } ;

test -e /etc/rc.local && cat /etc/rc.local |grep ^exit && { echo "DETECTED rc.local ..running forked" ; /bin/bash /etc/rc.local & echo ; } ;



## FUNCTIONS
_supervisor_update() { supervisorctl reread;supervisorctl update;supervisorctl start all ; } ;
_supervisor_generate_artisanqueue() { ###supervisor queue:work
                   echo -n "->artisan:queue"

                    for artisanfile in $(ls /var/www/html/artisan /var/www/$(hostname -f)/ /var/www/*/artisan -1 2>/dev/null|grep -v  -e "\.bak/artisan" -e "OLD/artisan" -e  "old/artisan"  |head -n1 ) ;do
                        php ${artisanfile} 2>&1 |grep -q queue:work  && test -e $(dirname $artisanfile)/.env &&  grep -e QUEUE_CONNECTION=sync -e QUEUE_DRIVER=sync  $(dirname $artisanfile)/.env ||  (
                        cat > /etc/supervisor/conf.d/queue_${artisanfile//\//_}.conf << EOF
[program:laravel-worker]
process_name=%(program_name)s_%(process_num)02d
command=/usr/bin/php '${artisanfile}' queue:work --timeout 0 --sleep=3 --tries=3 --daemon
autostart=true
autorestart=true
user=www-data
numprocs=2
redirect_stderr=true
stdout_logfile=/dev/stdout
stderr_logfile=/dev/stderr
stdout_logfile_maxbytes=0
stderr_logfile_maxbytes=0
EOF
                    ) ; done ; _supervisor_update  ; } ;


_supervisor_generate_websockets() { ## supervisor:websockets.chat

                   echo -n "->artisan:websock"
                    for artisanfile in $(ls /var/www/html/artisan /var/www/$(hostname -f)/ /var/www/*/artisan -1 2>/dev/null|grep -v  -e "\.bak/artisan" -e "\.OLD/artisan" -e  "\.old/artisan"  |head -n1 ) ;do
                        php ${artisanfile} 2>&1 |grep -q websockets:run  && (
                        cat > /etc/supervisor/conf.d/websockets_${artisanfile//\//_}.conf << EOF
[program:websockets]
command=su -s /bin/bash -c 'cd /var/www/html/;php artisan websockets:run' www-data
stdout_logfile=/dev/stdout
stderr_logfile=/dev/stderr
stdout_logfile_maxbytes=0
stderr_logfile_maxbytes=0
autorestart=true

EOF
                     ) ;done  ; _supervisor_update  ; } ;




##

echo "::STARTING"


### www shell shortcut
echo "su -s /bin/bash www-data" > /usr/bin/wwwsh;chmod +x /usr/bin/wwwsh


###TIME
if [ -z "${APP_TIMEZONE}" ] ; then
    echo "TIMEZONE NOT SET, USE APP_TIMEZONE= in .env, setting  default";
    /bin/ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime  ;
else
    echo "SETTING TIMEZONE  ";
    test -f /usr/share/zoneinfo/${APP_TIMEZONE} || echo "TIMEZONE GIVEN DOES NOT EXIST"
    test -f /usr/share/zoneinfo/${APP_TIMEZONE} && /bin/ln -sf /usr/share/zoneinfo/${APP_TIMEZONE} /etc/localtime;
fi



mkdir /dev/shm/startlogs

##get toolkit
_get_toolkit() {  /bin/bash /_0_get-toolkit.sh  2>&1 |tee /dev/shm/startlogs/toolkit |sed 's/$/|/g'|tr -d '\n' ; } ;
_get_toolkit &
##fix snakeoil certs
_setup_cert() { /bin/bash /_0_crt-snakeoil.sh 2>&1   |tee /dev/shm/startlogs/certs   |sed 's/$/|/g'|tr -d '\n' ; } ;
_setup_cert &

##fix dropbear and composer
_init_drpbr()  { /bin/bash /_0_fix-dropbear.sh 2>&1  |tee /dev/shm/startlogs/drobear |sed 's/$/|/g'|tr -d '\n' ; } ;
_init_drpbr &

_fix_composr() { /bin/bash /_0_fix-composer.sh 2>&1 |tee /dev/shm/startlogs/composer |sed 's/$/|/g'|tr -d '\n' ; } ;
_fix_composr &


##fix www-data user commons
_init_user()   { /bin/bash /_1_www-userprep.sh 2>&1 |tee /dev/shm/startlogs/userinit |sed 's/$/|/g'|tr -d '\n' ; } ;
_init_user &


#MAIL

##fix mail
_fix_mail()    { /bin/bash /_0_sys-mailprep.sh 2>&1 |tee /dev/shm/startlogs/mail     |sed 's/$/|/g'|tr -d '\n' ; } ;
_fix_mail &

# 2>&1 |tr -d '\n' &


####NOW THE .env party


##prepare mongodb
_prep_mongo()  { /bin/bash /_1_sys-mongopre.sh 2>&1 |tee /dev/shm/startlogs/mongo    |sed 's/$/|/g'|tr -d '\n' ; } ;
_prep_mongo &
##prepare mariadb/mysql
_prep_sql()    { /bin/bash /_1_sql-initprep.sh 2>&1 |tee /dev/shm/startlogs/sql  |sed 's/$/|/g'|tr -d '\n' ; } ;
_prep_sql &

##php apache fixes
_prep_apache() { /bin/bash /_1_php-initprep.sh 2>&1 |tee /dev/shm/startlogs/phpfix |sed 's/$/|/g'|tr -d '\n' ; } ;
_prep_apache &

sleep 5

echo "WAITING FOR :"
jobs 2>&1 |grep -v "Done"
wait



    echo "artisan:schedule:loop"
    ## artisan schedule commands
  while (true);do
    for artisanfile in $(ls /var/www/html/artisan /var/www/$(hostname -f)/ /var/www/*/artisan -1 2>/dev/null|grep -v  -e "\.bak/artisan" -e "OLD/artisan" -e  "old/artisan"  |head -n1 ) ;do
        CRONCMD='*/5 * * * * /usr/bin/php '${artisanfile}' schedule:run &>/dev/shm/cron_artisan.sched.log'
        #grep '/usr/bin/php '${artisanfile}' schedule:run ' /var/spool/cron/crontabs/www-data  || ( (echo ;echo "${CRONCMD}" )  |tee -a /var/spool/cron/crontabs/www-data ;
        crontab -l -u www-data 2>/dev/null | grep -q '/usr/bin/php '${artisanfile}' schedule:run '  || { (crontab -l -u www-data 2>/dev/null; echo "${CRONCMD}") | crontab -u www-data - ; } ;
        which supervisorctl 2>&1 | grep -q supervisorctl && supervisorctl restart cron |tr d '\n' &
        which supervisorctl 2>&1 | grep -q supervisorctl || service cron restart |tr -d '\n' &
    sleep 120;
    done
  done &

echo ":LOGFIFO:"
##APACHE LOGGING THROUGH FIFO's
(
lgf_ngx=/var/log/access.log
erl_ngx=/var/log/error.log
lgf_apa=/var/log/apache2/access.log
erl_apa=/var/log/apache2/error.log
oth_apa=/var/log/apache2/other_vhosts_access.log
sym_apa=/etc/apache2/sites-enabled/symfony.conf

for logfile in ${lgf_ngx} ${erl_ngx} ${lgf_apa} ${erl_apa} ${oth_apa} ${sym_apa} ;do
    test -e ${logfile} && rm ${logfile}   2>/dev/null
done

which nginx   && for logfile in ${lgf_ngx} ${erl_ngx}  ;do
    mkfifo ${logfile}
done

which apache2 && for logfile in ${lgf_apa} ${erl_apa} ${oth_apa}  ;do
    mkfifo ${logfile}
done

( while (true);do cat /var/log/apache2/access.log              |grep --line-buffered -v -e 'StatusCabot' -e '"cabot/' -e '"HEAD / HTTP/1.1" 200 - "-" "curl/' -e "UptimeRobot/" -e "docker-health-check/over9000" -e "/favicon.ico" ;sleep 0.2;done ) &
( while (true);do cat /var/log/apache2/other_vhosts_access.log |grep --line-buffered -v -e 'StatusCabot' -e '"cabot/' -e '"HEAD / HTTP/1.1" 200 - "-" "curl/' -e "UptimeRobot/" -e "docker-health-check/over9000" -e "/favicon.ico" ;sleep 0.2;done ) &
( while (true);do cat /var/log/apache2/error.log               |grep --line-buffered -v -e 'StatusCabot' -e '"cabot/' -e '"HEAD / HTTP/1.1" 200 - "-" "curl/' -e "UptimeRobot/" -e "docker-health-check/over9000" -e "/favicon.ico" 1>&2;sleep 0.2;done ) &

) &


test -f /usr/sbin/sendmail.real || (test -f /usr/sbin/sendmail.cron && (mv /usr/sbin/sendmail /usr/sbin/sendmail.real;ln -s /usr/sbin/sendmail.cron /usr/sbin/sendmail))
head -n1 /usr/sbin/sendmail |grep -q bash && { sed 's/\r$//g' -i /usr/sbin/sendmail ; } ;

#ln -sf /dev/stdout /var/log/apache2/access.log
#ln -sf /dev/stderr /var/log/apache2/error.log
#ln -sf /dev/stdout /var/log/apache2/other_vhosts_access.log


log_rotate_loop() {
sleep 20;
date +%H|grep ^00 && {
  sleep 20
  for web_app_log in $( find ${logdir} -type f -1 -name "laravel*.log"   ;find /var/www/html/typo3temp/var/log -name "*.log" -mtime -1 -delete); do
    mv "${web_app_log}" "${web_app_log}".$(date +%F -d "1 day ago").rotated.log
  done
echo -n; } ; &


sleep 14380

echo -n ; } ;

  service_loop() {

##fix perissions
  chmod g+rx /root/ /root/.ssh/;
  chgrp www-data /root/ /root/.ssh/

  ## IF /root/.ssh is a volume, move all the ssh-privkeys out of /var/www , so php-fpm / apache cannot read them  with open_basedir in use
  ( while (true);do
  grep  -q /root/.ssh /etc/mtab  && for file in /var/www/.ssh/id_* ;do
                                      test -e ${file} && {
                                        test -e  /root/.ssh/${file//\//_} || { mv ${file} /root/.ssh/${file//\//_} && ln -s /root/.ssh/${file//\//_} ${file} ; }  ; } ;
                                    done


  ## INSTALLERS MIGHT DELAY PRESENCE OF artisan file , so we loop and start when coming up
  which supervisorctl &&
                    ( for run in A B ;do
                      test -f /var/run/supervisor.sock &&  {
                        _supervisor_generate_artisanqueue ;
                        _supervisor_generate_websockets ;
                        echo -n ; } ;
                    sleep 123 ;
                    done ) &


  ##delete web app  logs
  for logdir in $(find /var/www/ -maxdepth 3 -name logs -type d |grep -v git|grep storage/logs);do
      find ${logdir} -type f -mtime +14 -name "laravel*.log" -delete  &
      find /var/www/html/typo3temp/var/log -name "*.log" -mtime +14 -delete &
  done &

sleep 300

done )     echo -n   ; } ;

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
                    exec /usr/sbin/dropbear -j -k -s -g -m -E -F
                    service_loop &
            ##artisan queue:work without supervisor
            for artisanfile in $(ls /var/www/html/artisan /var/www/$(hostname -f)/ /var/www/*/artisan -1 2>/dev/null|grep -v  -e "\.bak/artisan" -e "OLD/artisan" -e  "old/artisan"  |head -n1 ) ;do
                    php ${artisanfile} 2>&1 |grep -q queue:work  && ( while (true) ;do
                                                                            su -s /bin/bash -c '/usr/bin/php '${artisanfile}' queue:work --timeout 0 --sleep=3 --tries=3 --daemon' www-data ;sleep 5;done ) &
                    done

else
##supervisord section

                    echo -n "supervisord init"
                    ##config init
                    mkdir -p /etc/supervisor/conf.d/




    echo -n "->supervisor:redis"

                    ### FIX REDIS CONFIG - LOGFILE DIR NONEXISTENT (and stderr is wanted for now) - DOCKER HAS NO ::1 BY DEFAULT - "daemonize no" HAS TO BE SET TO run  with supervisor

                    ## supervisor:redis
                    which /usr/bin/redis-server >/dev/null &&  (
                                                              (echo  "[program:redis]";
                                                              echo "command=/bin/bash -c 'killall -QUIT redis-server;sleep 1 ;/usr/bin/redis-server /etc/docker_redis.conf|grep -e Background -e saved -e Saving '";echo "stdout_logfile=/dev/stdout" ;echo "stderr_logfile=/dev/stderr" ;echo "stdout_logfile_maxbytes=0";echo "stderr_logfile_maxbytes=0";echo "autorestart=true" ) > /etc/supervisor/conf.d/redis.conf  ;  sed 's/^daemonize.\+/daemonize no/g;s/bind.\+/bind 127.0.0.1/g;s/logfile.\+/logfile \/dev\/stderr/g' /etc/redis/redis.conf > /etc/docker_redis.conf ; echo never > /sys/kernel/mm/transparent_hugepage/enabled ) &

                    echo -n "->supervisor:mysql"
                    ## supervisor:mysql
                    which /usr/sbin/mysqld >/dev/null &&  ( ( echo  "[program:mysql]";echo "command=/usr/sbin/mysqld --basedir=/usr --datadir=/var/lib/mysql --plugin-dir=/usr/lib/mysql/plugin --user=mysql --skip-log-error --pid-file=/var/run/mysqld/mysqld.pid --socket=/var/run/mysqld/mysqld.sock --port=3306";echo "stdout_logfile=/dev/stdout" ;echo "stderr_logfile=/dev/stderr" ;echo "stdout_logfile_maxbytes=0";echo "stderr_logfile_maxbytes=0";echo "autorestart=true" ) > /etc/supervisor/conf.d/mariadb.conf  ; service mysql stop &  killall -KILL mysqld mysqld_safe mariadbd & kill -QUIT $(pidof mysqld mysqld_safe mariadbd) ;sleep 1) &
    echo -n "->supervisor:dropbear"

                    ## supervisor:dropbear
                    which /usr/sbin/dropbear >/dev/null &&  ( ( echo  "[program:dropbear]";echo "command=/usr/sbin/dropbear -j -k -s -g -m -E -F";echo "stdout_logfile=/dev/stdout" ;echo "stderr_logfile=/dev/stderr" ;echo "stdout_logfile_maxbytes=0";echo "stderr_logfile_maxbytes=0";echo "autorestart=true" ) > /etc/supervisor/conf.d/dropbear.conf   ) &

    echo -n "->supervisor:php-fpm"

                    if [ "$(ls -1 /usr/sbin/php-fpm* 2>/dev/null|wc -l)" -eq 0 ];then
                        echo "no FPM";
                    else
                        fpmexec=$(ls -1 /usr/sbin/php-fpm* |sort -n|tail -n1 )" -F" ;
                        echo "==" "$fpmexec"
                        ( ( echo  "[program:php-fpm]";
                            echo "command="$fpmexec;
                            echo "stdout_logfile=/dev/stdout" ;
                            echo "stderr_logfile=/dev/stderr" ;
                            echo "stdout_logfile_maxbytes=0";
                            echo "stderr_logfile_maxbytes=0";
                            echo "autorestart=true" ) > /etc/supervisor/conf.d/php-fpm.conf ) &
                    echo "waiting for "$(jobs)" "
                  fi
                wait




                  ( sleep 10;service_loop ) &
                  exec $(which supervisord || echo /usr/bin/supervisord) -c /etc/supervisor/supervisord.conf |grep -v "reaped unknown PID"
fi
