#!/bin/bash
echo Sorry .. hanging up;sleep 0.5 &

echo stopping webservers ;  supervisorctl stop apache &>/dev/null &  supervisorctl stop nginx &
sleep 0.5 # so fpm might drain last requests
echo "stopping fpm ";       supervisorctl stop php-fpm &
echo "stopping db"  ;       mysql -e shutdown &

sleep 5 ## this could be quiet longer .. but docker :(

supervisorctl stop mariadb 2>/dev/null
supervisorctl stop mysql 2>/dev/null

sync &
sleep 3

[[ -z $(supervisorctl pid|grep ^[0-9]) ]] || kill -SIGTERM $(supervisorctl pid|grep ^[0-9]) ;
[[ -z "$(pidof supervisord)" ]] || kill -SIGQUIT $(pidof supervisord) &
