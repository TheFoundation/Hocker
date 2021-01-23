#!/bin/bash
echo Sorry .. hanging up;sleep 0.5 & supervisorctl stop apache &
mysql -e shutdown & supervisorctl stop php-fpm & sync &
sleep 5
supervisorctl stop mariadb 2>/dev/null
supervisorctl stop mysql 2>/dev/null

sleep 3

[[ -z $(supervisorctl pid) ]] || kill -SIGTERM $(supervisorctl pid) ;
[[ -z "$(pidof supervisord)" ]] || kill -SIGQUIT $(pidof supervisord) &
