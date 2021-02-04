#!/usr/bin/env bash



test -d /var/lib/mysql || echo " init.sql | SOFTFAIL: /var/lib/mysql not present"
grep  /var/lib/mysql /etc/mtab -q || echo " init.sql | SOFTFAIL: /var/lib/mysql not a volume "
test -d /var/lib/mysql || mkdir -p /var/lib/mysql

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

# DEBUG&&export |grep -e MARIADB -e MYSQL|grep -v PASS


##let other machines reach mariadb via network
if [ "$MYSQL_REMOTE_ACCESS" = "true"  ]; then
    sed 's/bind-address.\+/bind-adress = 0.0.0.0/g' /etc/mysql/*.cnf -i
fi

test -e /etc/mysql/mariadb.conf.d/51-perfomane.cnf  && echo '
[mariadb]

table_open_cache_instances=4
table_open_cache=512  ## you could have 4x100 tables plus temporary

thread_pool_max_threads = 8
#thread_pool_min_threads = 2

innodb_buffer_pool_size = 192M
innodb_buffer_pool_instances = 2
thread_cache_size=128  # from 50 per 10.n.nn MaridDB refman minimum
innodb_io_capacity=1900  # from 400 to enable higher SSD IOPS
innodb_lru_scan_depth=100  # from 1024 to conserve 90% of CPU cycles used for function
##DANGER###innodb_buffer_pool_size=24G  # from 12G to reduce innodb_buffer_pool_reads RPS of 14
innodb_flushing_avg_loops=5  # from 30 to reduce innodb_buffer_pool_pages_dirty of 61,297

#########' > /etc/mysql/mariadb.conf.d/51-perfomane.cnf



_kill_maria() {
service mariadb stop &>/dev/null &
service mysql stop &>/dev/null &
wait

## since process manager shows /usr/bin/mysql instead of the basename mysqld , find all pids
mariapids() { echo $(pidof $(which mysqld mysqld_safe mariadbd ) mysqld mysqld_safe mariadbd )  ; } ;
[[ -z $(mariapids) ]] ||  kill -QUIT $(mariapids) &>/dev/null &
sleep 0.3
ps aux|grep -q -e mysqld -e mariadbd && {
kill  -QUIT  2>/dev/null &
sleep 1
[[ -z $(mariapids) ]] ||  kill -QUIT $(mariapids) &>/dev/null
[[ -z $(mariapids) ]] ||  kill -KILL $(mariapids) 2>/dev/null &
sleep 0.1 ; } ;
wait ;

echo ; } ;


###MARIADB  /MYSQL
## mariadb renamed their init service in the 10.x line
test -e /etc/init.d/mysql || test -e /etc/init.d/mariadb && ln -s /etc/init.d/mariadb /etc/init.d/mysql


## in case there is a failure (double run in instance or user just wants to re-init)
timeout 5 /etc/init.d/mariadb stop &>/dev/null &
timeout 5 /etc/init.d/mysql stop &>/dev/null &
sleep 1
_kill_maria  &

wait


test -f /var/run/mysqld/mysqld.pid  && rm /var/run/mysqld/mysqld.pid

if [ "$(which mysqld |grep mysql|wc -l)" -gt 0 ] ;then echo -n "mysql found :"

      test -e /etc/mysql/mariadb.cnf && sed 's/!include \/etc\/mysql\/mariadb.cnf//g' /etc/mysql/mariadb.cnf -i

      # fix possibly wrong permissions ( docker volumes)
      ( test -d  /var/lib/mysql && chown -R mysql:mysql /var/lib/mysql ) &
      ( mkdir /var/run/mysqld/ && chown -R mysql:mysql /var/run/mysqld/  ) &

    if [ -z "${MYSQL_ROOT_PASSWORD}" ]; then
        echo "MARIADB marked for installation , but no root password supplied, please set your own from command line (docker exec -it CONTAINER mysql -u root -p), dont forget to set it in /etc/mysql/debian.cnf and make that file persistent"
        [ "$(ls -A /var/lib/mysql 2>/dev/null)" ] && echo -n "/var/lib/mysql already filled"
        [ "$(ls -A /var/lib/mysql 2>/dev/null)" ] || mysql_install_db  2>&1 | tr -d '\n' ;


        # exec /etc/init.d/mysql start &
    else
        echo -n "MYSQL HAVE DATABASE AND ROOT PARAMETERS"
         (	[ "$(ls /var/lib/mysql/mysql/user* 2>/dev/null )" ] && { echo -n " /var/lib/mysql user table already exist"  ;             /etc/init.d/mysql start 2>&1 | tr -d '\n'  & sleep 4 ; } ;

            [ "$(ls /var/lib/mysql/mysql/user* 2>/dev/null )" ] || {
            echo "empty /var/lib/mysql , doing mysql_install_db"
            mysql_install_db 2>&1 |grep -v -e sudo -e mariadb.org -e mysqld_safe -e connecting | tr -d '\n'
            /etc/init.d/mysql start 2>&1 | tr -d '\n'  &
            sleep 5
            echo -n "setting root pass after instal... :" ;echo -e '[client]\nuser=root\npassword=' | mysqladmin --defaults-file=/dev/stdin -u root password "$MYSQL_ROOT_PASSWORD";echo
            echo -n ; } ;


        #mysqld_safe --skip-grant-tables &  sleep 3;
        start=$(date +%u)
        echo waiting for mysql
        while ! test -f "/run/mysqld/mysqld.sock" ; do
          [[ $(($(date -u +%s)-${start})) -gt 120 ]] && break
              echo -ne "init:waiting since "$(($(date -u +%s)-${start}))" seconds for mysql socket"|red ;echo -ne $(tail -n2 /dev/shm/startlog|tail -c 99  |tr -d '\r\n' ) '\r';sleep 2;
        done

        echo -n "SETTING MARIA ROOT PASSWORD FROM ENV: "
        no_passwd_set=no
        echo -n "trying our root password from env :"
        mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "SHOW GLOBAL STATUS LIKE 'Uptime';" |grep -q Uptime && no_passwd_set=yes
        echo
        echo -n "testing passwordless root:"    echo -e '[client]\nuser=root\npassword='"$MYSQL_ROOT_PASSWORD" | mysql --defaults-file=/dev/stdin --batch --silent -e "SHOW GLOBAL STATUS LIKE 'Uptime';" |grep -q Uptime && no_passwd_set=yes
        echo
        echo -n "testing passwordless (socket) root: "    ;mysql --batch --silent -u root -e "SHOW GLOBAL STATUS LIKE 'Uptime';" 2>&1 |grep -q Uptime && no_passwd_set=yes
        #mysql --batch --silent -u root -e "select password from mysql.user where user='root'"
        echo "$no_passwd_set"|grep -q ^yes$ && (
       	echo "setting root password"
#            kill -QUIT $(pidof mysqld mysqld_safe ) 2>/dev/null;
#    sleep 0.2
#        kill -KILL $(pidof mysqld mysqld_safe ) 2>/dev/null;
#        /etc/init.d/mysql start;sleep 2
       echo -e '[client]\nuser=root\npassword='"" | mysqladmin --defaults-file=/dev/stdin -u root password $MYSQL_ROOT_PASSWORD

           )
        echo -e '[client]\nuser=root\npassword='"$MYSQL_ROOT_PASSWORD" | mysql --defaults-file=/dev/stdin --batch --silent -e "SHOW GLOBAL STATUS LIKE 'Uptime';" |grep -q Uptime && echo "MYSQL ROOT PASSWORD WORKS"|| echo "MYSQL ROOT PASSWORD NOT SET"
        echo -e '[client]\nuser=root\npassword='"$MYSQL_ROOT_PASSWORD" | mysql --defaults-file=/dev/stdin -u root -e "GRANT ALL ON *.* TO 'debian-sys-maint'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' WITH GRANT OPTION; FLUSH PRIVILEGES;"
        echo -n "testing mysql user pass :"
        echo -e '[client]\nuser='$MYSQL_USERNAME'\npassword='$MYSQL_PASSWORD | mysql --defaults-file=/dev/stdin --batch --silent -e "SHOW GLOBAL STATUS LIKE 'Uptime';" |grep -q Uptime && echo "MYSQL USER PASSWORD WORKS"|| echo "MYSQL USER PASSWORD NOT SET"
        echo -n "trying mysql status : "
        /etc/init.d/mysql status 2>&1 |grep -e Uptime  -e socket
        #mysql --batch --silent -u root -e "use mysql;update user set authentication_string=password('"${MYSQL_ROOT_PASSWORD}"') where user='root'; flush privileges;" || echo "seems like MYSQL_ROOT_PASSWORD was already set"
        sed -i 's/^password.\+/password = '$MYSQL_ROOT_PASSWORD'/g' /etc/mysql/debian.cnf ;

        )
    fi

if [ -z "${MYSQL_DATABASE}" ] ; then
                echo "NO DATABASE IN .env"
            else
      (   echo "creating db ${MYSQL_DATABASE}";

      ##### statements 2 3 and 5 hidden in output ( credentials ) -> $MSG_SQLn
                SQL1="CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\` CHARACTER SET utf8mb4 ;"
                SQL2="CREATE USER \`${MYSQL_USERNAME}\`@\`localhost\` IDENTIFIED BY '${MYSQL_PASSWORD}' ;CREATE USER \`${MYSQL_USERNAME}\`@\`%\` IDENTIFIED BY '${MYSQL_PASSWORD}' ;"
            MSG_SQL2="CREATE USER \`${MYSQL_USERNAME}\`@\`localhost\` IDENTIFIED BY *******MASKED****** ;CREATE USER \`${MYSQL_USERNAME}\`@\`%\` IDENTIFIED BY *******MASKED****** ;"
                SQL3="GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USERNAME}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USERNAME}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';"
            MSG_SQL3="GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USERNAME}'@'localhost' IDENTIFIED BY *******MASKED******;GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USERNAME}'@'%' IDENTIFIED BY *******MASKED******;"
                SQL4="FLUSH PRIVILEGES;SHOW GRANTS FOR \`${MYSQL_USERNAME}\`@'localhost' ;SHOW GRANTS FOR \`${MYSQL_USERNAME}\`@'%' ; "
                SQL5="GRANT ALL ON *.* TO 'debian-sys-maint'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' WITH GRANT OPTION; FLUSH PRIVILEGES;SHOW GRANTS"
            MSG_SQL5="GRANT ALL ON *.* TO 'debian-sys-maint'@'localhost' IDENTIFIED BY **********MASKED*******  WITH GRANT OPTION; FLUSH PRIVILEGES;SHOW GRANTS"

            	 echo "executing ""${SQL1}" "${MSG_SQL2}" "${MSG_SQL3}""${SQL4}""${MSG_SQL5}"
                if [ -f /root/.my.cnf ]; then
                  echo "dbinit: using my.cnf"
                    echo -n 1:
                    mysql -e "${SQL1}"
                    echo -n 2:
                    mysql -e "${SQL2}"
                    echo -n 3:
                    mysql -e "${SQL3}"
                    echo -n 4:
                    mysql -e "${SQL4}"
                    echo -n 5:
                    mysql -e "${SQL5}"
                    echo -n w:
                    mysql -e "SHOW WARNINGS;"
                else
                  echo "dbinit: not using my.cnf"
                    # If /root/.my.cnf doesn't exist then it'll take .env setting
                    echo -n 1:
                    mysql -h ${MYSQL_HOST} -u root -p${MYSQL_ROOT_PASSWORD} -e "${SQL1}"
                    echo -n 2:
                    mysql -h ${MYSQL_HOST} -u root -p${MYSQL_ROOT_PASSWORD} -e "${SQL2}"
                    echo -n 3:
                    mysql -h ${MYSQL_HOST} -u root -p${MYSQL_ROOT_PASSWORD} -e "${SQL3}"
                    echo -n 4:
                    mysql -h ${MYSQL_HOST} -u root -p${MYSQL_ROOT_PASSWORD} -e "${SQL4}"
                    echo -n 5:
                    mysql -h ${MYSQL_HOST} -u root -p${MYSQL_ROOT_PASSWORD} -e "${SQL5}"
                    echo -n w:
                    mysql -h ${MYSQL_HOST} -u root -p${MYSQL_ROOT_PASSWORD} -e "SHOW WARNINGS;"
                    ln -s /etc/mysql/debian.cnf /root/.my.cnf
                fi
              )
            fi

echo " init.sql | TEARDOWN INIT SQL"; _kill_maria

##fix recursive inclusion by ubuntu/mariadb quirks
test -e /etc/mysql/mariadb.cnf && sed 's/!include \/etc\/mysql\/mariadb.cnf//g' /etc/mysql/mariadb.cnf -i

which mysql 2>&1  | grep mysql && {

    test -e /root/.my.cnf || ln -s /etc/mysql/debian.cnf /root/.my.cnf
    grep -q "password" /root/.my.cnf 2>/dev/null && grep -q "${MYSQL_ROOT_PASSWORD}" /root/.my.cnf 2>/dev/null || { /bin/bash -c 'echo -e  "[client]\nhost     = ${MYSQL_HOST}\nuser     = root\npassword = "$MYSQL_ROOT_PASSWORD"\nsocket   = /var/run/mysqld/mysqld.sock" >> /root/.my.cnf ;' ; } ;
    test -f /var/www/.my.cnf || ( /bin/bash -c 'echo -e  "[client]\nhost     = ${MYSQL_HOST}\nuser     = "$MYSQL_USERNAME"\npassword = "$MYSQL_PASSWORD"\nsocket   = /var/run/mysqld/mysqld.sock" > /var/www/.my.cnf ;chown www-data /var/www/.my.cnf ;chmod ugo-w  /var/www/.my.cnf' )
echo -n ; } ;


else
   echo MARIADB not marked for installation ,
fi
