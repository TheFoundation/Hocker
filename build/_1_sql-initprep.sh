#!/usr/bin/env bash

## be standards compatible ;)
[[ -z "$MARIADB_HOST" ]]          || export MYSQL_HOST=${MARIADB_HOST}
[[ -z "$MARIADB_REMOTE_ACCESS" ]] || export MYSQL_REMOTE_ACCESS=${MARIADB_REMOTE_ACCESS}
[[ -z "$MARIADB_PASSWORD" ]]      || export MYSQL_PASSWORD=${MARIADB_PASSWORD}
[[ -z "$MARIADB_USERNAME" ]]      || export MYSQL_USER=${MARIADB_USERNAME}
[[ -z "$MARIADB_DATABASE" ]]      || export MYSQL_DATABASE=${MARIADB_DATABASE}
[[ -z "$MARIADB_ROOT_PASSWORD" ]] || export MYSQL_ROOT_PASSWORD=${MARIADB_ROOT_PASSWORD}


##let other machines reach mariadb via network
if [ "$MYSQL_REMOTE_ACCESS" = "true"  ]; then
    sed 's/bind-address.\+/bind-adress = 0.0.0.0/g' /etc/mysql/*.cnf -i
fi



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
###MARIADB  /MYSQL
echo "mariadb install setting :"${INSTALL_MARIADB}

test -f /etc/init.d/mysql || test /etc/init.d/mariadb && ln -s /etc/init.d/mariadb /etc/init.d/mysql
timeout 5 /etc/init.d/mariadb stop &>/dev/null &
timeout 5 /etc/init.d/mysql stop &>/dev/null &

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
        [ "$(ls -A /var/lib/mysql)" ] && echo -n "/var/lib/mysql already filled" || mysql_install_db ;
        # exec /etc/init.d/mysql start &
    else
         echo -n "SETTING MARIA ROOT PASSWORD FROM ENV: "
         (	[ "$(ls /var/lib/mysql/mysql/user*)" ] && echo -n " /var/lib/mysql already filled" || mysql_install_db ;
        #mysqld_safe --skip-grant-tables &  sleep 3;
        /etc/init.d/mysql start
        sleep 5
        no_passwd_set=no
        echo -n "trying our root password from env"
        echo -e "[client]user=root\npassword=" | mysql --defaults-file=/dev/stdin --batch --silent -e "SHOW GLOBAL STATUS LIKE 'Uptime';" |grep -q Uptime && no_passwd_set=yes
        echo "testing passwordless root"
        mysql --batch --silent -u root -e "SHOW GLOBAL STATUS LIKE 'Uptime';" |grep -q Uptime && no_passwd_set=yes
        #mysql --batch --silent -u root -e "select password from mysql.user where user='root'"
        echo "$no_passwd_set"|grep -q ^yes$ && (
       	echo "setting root password"
#            kill -QUIT $(pidof mysqld mysqld_safe ) 2>/dev/null;
#    sleep 0.2
#        kill -KILL $(pidof mysqld mysqld_safe ) 2>/dev/null;
#        /etc/init.d/mysql start;sleep 2
       echo -e "[client]user=root\npassword=" | mysqladmin --defaults-file=/dev/stdin -u root password $MYSQL_ROOT_PASSWORD

           )
        echo -e "[client]user=root\npassword=$MYSQL_ROOT_PASSWORD" | mysql --defaults-file=/dev/stdin --batch --silent -e "SHOW GLOBAL STATUS LIKE 'Uptime';" |grep -q Uptime && echo "MYSQL ROOT PASSWORD WORKS"|| echo "ERROR:MYSQL ROOT PASSWORD DOES NOT WORK WITH uptime COMMAND"

        echo -e "[client]user=root\npassword=$MYSQL_ROOT_PASSWORD" | mysql --defaults-file=/dev/stdin -u root -e "GRANT ALL ON *.* TO 'debian-sys-maint'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' WITH GRANT OPTION; FLUSH PRIVILEGES;"
        echo "tryng mysql status"
        /etc/init.d/mysql status
        #mysql --batch --silent -u root -e "use mysql;update user set authentication_string=password('"${MYSQL_ROOT_PASSWORD}"') where user='root'; flush privileges;" || echo "seems like MYSQL_ROOT_PASSWORD was already set"
        sed -i 's/^password.\+/password = '$MYSQL_ROOT_PASSWORD'/g' /etc/mysql/debian.cnf ;

        )
    fi

    if [ -z "${MYSQL_DATABASE}" ] ; then
                echo "NO DATABASE IN .env"
            else
      (   echo creating db ${MYSQL_DATABASE};
                SQL1="CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\` CHARACTER SET utf8 ;"
                SQL2="CREATE USER \`${MYSQL_USERNAME}\`@\`localhost\` IDENTIFIED BY '${MYSQL_PASSWORD}' ;CREATE USER \`${MYSQL_USERNAME}\`@\`%\` IDENTIFIED BY '${MYSQL_PASSWORD}' ;"
                SQL3="GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USERNAME}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USERNAME}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';"
                SQL4="FLUSH PRIVILEGES;SHOW GRANTS FOR \`${MYSQL_USERNAME}\`@'localhost' ;SHOW GRANTS FOR \`${MYSQL_USERNAME}\`@'%' ; "
                SQL5="GRANT ALL ON *.* TO 'debian-sys-maint'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' WITH GRANT OPTION; FLUSH PRIVILEGES;SHOW GRANTS"
            	 echo "executing ""${SQL1}""CREATE USER \`${MYSQL_USERNAME}\`@\`localhost\` IDENTIFIED BY ***MASKED***""${SQL3}""${SQL4}""GRANT ALL ON *.* TO 'debian-sys-maint'@'localhost' IDENTIFIED BY  ***MASKED*** WITH GRANT OPTION; FLUSH PRIVILEGES;SHOW GRANTS"
                if [ -f /root/.my.cnf ]; then
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


test -e /etc/mysql/mariadb.cnf && sed 's/!include \/etc\/mysql\/mariadb.cnf//g' /etc/mysql/mariadb.cnf -i

which mysqld 2>&1  | grep mysqld && {


    test -e /root/.my.cnf || ln -s /etc/mysql/debian.cnf /root/.my.cnf
    grep -q "password" /root/.my.cnf 2>/dev/null && grep -q "${MYSQL_ROOT_PASSWORD}" /root/.my.cnf 2>/dev/null || { /bin/bash -c 'echo -e  "[client]\nhost     = ${MYSQL_HOST}\nuser     = root\npassword = "$MYSQL_ROOT_PASSWORD"\nsocket   = /var/run/mysqld/mysqld.sock" >> /root/.my.cnf ;' ; } ;
    test -f /var/www/.my.cnf || ( /bin/bash -c 'echo -e  "[client]\nhost     = ${MYSQL_HOST}\nuser     = "$MYSQL_USERNAME"\npassword = "$MYSQL_PASSWORD"\nsocket   = /var/run/mysqld/mysqld.sock" > /var/www/.my.cnf ;chown www-data /var/www/.my.cnf ;chmod ugo-w  /var/www/.my.cnf' )
echo -n ; } ;


echo -n "TEARDOWN INIT SQL";
_kill_maria

else
   echo MARIADB not marked for installation ,
fi
