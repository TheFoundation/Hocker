#!/bin/bash


uncolored="\033[0m" ; black="\033[0;30m" ; blackb="\033[1;30m" ; white="\033[0;37m" ; whiteb="\033[1;37m" ; red="\033[0;31m" ; redb="\033[1;31m" ; green="\033[0;32m" ; greenb="\033[1;93m" ; yellow="\033[0;33m" ; yellowb="\033[1;33m" ; blue="\033[0;34m" ; blueb="\033[1;34m" ; purple="\033[0;35m" ; purpleb="\033[1;35m" ; lightblue="\033[0;36m" ; lightblueb="\033[1;36m" ;
function black {   echo -en "${black}${1}${uncolored}" ; } ;    function blackb {   echo -en "${blackb}";cat;echo -en "${uncolored}" ; } ;   function white {   echo -en "${white}";cat;echo -en "${uncolored}" ; } ;   function whiteb {   echo -en "${whiteb}";cat;echo -en "${uncolored}" ; } ;   function red {   echo -en "${red}";cat;echo -en "${uncolored}" ; } ;   function redb {   echo -en "${redb}";cat;echo -en "${uncolored}" ; } ;   function green {   echo -en "${green}";cat;echo -en "${uncolored}" ; } ;   function greenb {   echo -en "${greenb}";cat;echo -en "${uncolored}" ; } ;   function yellow {   echo -en "${yellow}";cat;echo -en "${uncolored}" ; } ;   function yellowb {   echo -en "${yellowb}";cat;echo -en "${uncolored}" ; } ;   function blue {   echo -en "${blue}";cat;echo -en "${uncolored}" ; } ;   function blueb {   echo -en "${blueb}";cat;echo -en "${uncolored}" ; } ;   function purple {   echo -en "${purple}";cat;echo -en "${uncolored}" ; } ;   function purpleb {   echo -en "${purpleb}";cat;echo -en "${uncolored}" ; } ;   function lightblue {   echo -en "${lightblue}";cat;echo -en "${uncolored}" ; } ;   function lightblueb {   echo -en "${lightblueb}";cat;echo -en "${uncolored}" ; } ;  function echo_black {   echo -en "${black}${1}${uncolored}" ; } ; function echo_blackb {   echo -en "${blackb}${1}${uncolored}" ; } ;   function echo_white {   echo -en "${white}${1}${uncolored}" ; } ;   function echo_whiteb {   echo -en "${whiteb}${1}${uncolored}" ; } ;   function echo_red {   echo -en "${red}${1}${uncolored}" ; } ;   function echo_redb {   echo -en "${redb}${1}${uncolored}" ; } ;   function echo_green {   echo -en "${green}${1}${uncolored}" ; } ;   function echo_greenb {   echo -en "${greenb}${1}${uncolored}" ; } ;   function echo_yellow {   echo -en "${yellow}${1}${uncolored}" ; } ;   function echo_yellowb {   echo -en "${yellowb}${1}${uncolored}" ; } ;   function echo_blue {   echo -en "${blue}${1}${uncolored}" ; } ;   function echo_blueb {   echo -en "${blueb}${1}${uncolored}" ; } ;   function echo_purple {   echo -en "${purple}${1}${uncolored}" ; } ;   function echo_purpleb {   echo -en "${purpleb}${1}${uncolored}" ; } ;   function echo_lightblue {   echo -en "${lightblue}${1}${uncolored}" ; } ;   function echo_lightblueb {   echo -en "${lightblueb}${1}${uncolored}" ; } ;    function colors_list {   echo_black "black";   echo_blackb "blackb";   echo_white "white";   echo_whiteb "whiteb";   echo_red "red";   echo_redb "redb";   echo_green "green";   echo_greenb "greenb";   echo_yellow "yellow";   echo_yellowb "yellowb";   echo_blue "blue";   echo_blueb "blueb";   echo_purple "purple";   echo_purpleb "purpleb";   echo_lightblue "lightblue";   echo_lightblueb "lightblueb"; } ;

_clock() { echo -n WALLCLOCK : |redb ;echo  $( date -u "+%F %T" ) |yellow ; } ;


##supervisord section
echo  " sys.init  | ->supervisord init" |red
##config init
mkdir -p /etc/supervisor/conf.d/ &>/dev/null ||true
which apache2ctl &>/dev/null && {
 echo '[program:apache]
command=/usr/bin/pidproxy /var/run/apache2/apache2.pid /supervisor-logger /bin/bash /run-apache.sh
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
autostart=true
autorestart=true
killasgroup=true
stopasgroup=true
 ' > /etc/supervisor/conf.d/apache.conf ; } ;


                    ### FIX REDIS CONFIG - LOGFILE DIR NONEXISTENT (and stderr is wanted for now) - DOCKER HAS NO ::1 BY DEFAULT - "daemonize no" HAS TO BE SET TO run  with supervisor

                    ## supervisor:redis
which /usr/bin/redis-server >/dev/null &&  (
  echo " sys.info  | ->supervisor:redis" |red

                    ### we only dump (persistence) to volumes:
                    REDISPARM=""
                    grep -q /var/lib/redis /etc/mtab && { echo " sys.info  | ->supervisor:redis: ++REDIS persistence++"; REDISPARM=/etc/docker_redis.conf ; } ;
                    grep -q /var/lib/redis /etc/mtab || { echo " sys.info  | ->supervisor:redis: no REDIS persistence" ; REDISPARM=' --save "" --appendonly no' ; } ;
                                                            ( echo  "[program:redis]";
                                                              echo "command=/supervisor-logger /bin/bash -c 'killall -QUIT redis-server;sleep 1 ;/usr/bin/redis-server "$REDISPARM"  '";
                                                              echo "stdout_logfile=/dev/stdout" ;
                                                              echo "stderr_logfile=/dev/stderr" ;
                                                              echo "stdout_logfile_maxbytes=0";
                                                              echo "stderr_logfile_maxbytes=0";
                                                              echo "autorestart=true" ) > /etc/supervisor/conf.d/redis.conf  ;  sed 's/^daemonize.\+/daemonize no/g;s/bind.\+/bind 127.0.0.1/g;s/logfile.\+/logfile \/dev\/stderr/g' /etc/redis/redis.conf > /etc/docker_redis.conf ;
                                                        ## since priviliged mode is needed for /sys/kernel , catch stderr
                                                        ( echo never > /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null ) &>/dev/null ) &


which /usr/sbin/mysqld >/dev/null &&  (
  echo  " sys.info  | ->supervisor:mysql"|red

                      ( echo "[program:mysql]";
                        echo "command=/supervisor-logger /usr/bin/pidproxy /var/run/mysqld/mysqld.pid /usr/sbin/mysqld --basedir=/usr --datadir=/var/lib/mysql --plugin-dir=/usr/lib/mysql/plugin --user=mysql --skip-log-error --pid-file=/var/run/mysqld/mysqld.pid --socket=/var/run/mysqld/mysqld.sock --port=3306";
                        echo "stopsignal=TERM";
                        echo "stopcommand=mysqladmin shutdown"
                        echo "stopwaitsecs=20" ;
                        echo "stdout_logfile=/dev/stdout" ;
                        echo "stderr_logfile=/dev/stderr" ;
                        echo "stdout_logfile_maxbytes=0";
                        echo "stderr_logfile_maxbytes=0";
                        echo "autorestart=true" ) > /etc/supervisor/conf.d/mariadb.conf  ; service mysql stop  &  killall -KILL mysqld mysqld_safe mariadbd  & kill -QUIT $(pidof mysqld mysqld_safe mariadbd) &>/dev/null;sleep 1) &

which /usr/bin/memcached >/dev/null &&  (
  echo  " sys.info  | ->supervisor:memcached"|red

                     (
                            echo  "[program:memcached]";
                            echo "command=/usr/bin/memcached -p 11211 -u memcache -m 64 -c 1024";
                            echo "stopsignal=TERM";
                            echo "stopwaitsecs=5" ;
                            echo "stdout_logfile=/dev/stdout" ;
                            echo "stderr_logfile=/dev/stderr" ;
                            echo "stdout_logfile_maxbytes=0";
                            echo "stderr_logfile_maxbytes=0";
                            echo "autorestart=true" ) > /etc/supervisor/conf.d/memached.conf  ;
                    timeout 5 service mysql stop  &
                    killall -KILL mysqld mysqld_safe mariadbd  &
                    sleep 1; kill -QUIT $(pidof mysqld mysqld_safe mariadbd) &>/dev/null;sleep 1
                            ) &

echo " sys.info  | ->supervisor:dropbear"|blue
                    ## supervisor:dropbear
which /usr/sbin/dropbear >/dev/null &&  ( ( echo  "[program:dropbear]";echo "command=/supervisor-logger /usr/sbin/dropbear -j -k -s -g -m -E -F";echo "stdout_logfile=/dev/stdout" ;echo "stderr_logfile=/dev/stderr" ;echo "stdout_logfile_maxbytes=0";echo "stderr_logfile_maxbytes=0";echo "autorestart=true" ) > /etc/supervisor/conf.d/dropbear.conf   ) &

echo " sys.info  | ->supervisor:php-fpm"|green

                    if [ "$(ls -1 /usr/sbin/php-fpm* 2>/dev/null|wc -l)" -eq 0 ];then
                        echo "no FPM";
                    else
                        fpmexec=$(ls -1 /usr/sbin/php-fpm* |sort -n|tail -n1 )" -F" ;
                        echo "==" "$fpmexec"
                        ( ( echo  "[program:php-fpm]";
                            echo "command=/supervisor-logger "$fpmexec;
                            echo "stopsignal=TERM";
                            echo "stopwaitsecs=5" ;
                            echo "stdout_logfile=/dev/stdout" ;
                            echo "stderr_logfile=/dev/stderr" ;
                            echo "stdout_logfile_maxbytes=0";
                            echo "stderr_logfile_maxbytes=0";
                            echo "autorestart=true" ) > /etc/supervisor/conf.d/php-fpm.conf ) &
                    echo "waiting for "$(jobs)" "
                  fi
wait
