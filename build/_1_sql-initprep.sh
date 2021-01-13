
##let other machines reach mariadb via network
if [ "$MARIADB_REMOTE_ACCESS" = "true"  ]; then
    sed 's/bind-address.\+/bind-adress = 0.0.0.0/g' /etc/mysql/*.cnf -i
fi

_kill_maria() {

kill -QUIT $(pidof $(which mysqld mysqld_safe mariadbd ) mysqld mysqld_safe mariadbd ) &
sleep 0.3
ps aux|grep -q -e mysqld -e mariadbd && {
kill  -QUIT $(pidof $(which mysqld mysqld_safe mariadbd ) mysqld mysqld_safe mariadbd ) 2>/dev/null &
sleep 0.2
kill  -QUIT $(pidof mysqld mysqld_safe mariadbd )
kill  -KILL $(pidof $(which mysqld mysqld_safe mariadbd ) mysqld mysqld_safe mariadbd ) 2>/dev/null &
sleep 0.1 ; } ;
wait ;

echo ; } ;
###MARIADB  /MYSQL
echo "mariadb install setting :"${INSTALL_MARIADB}

test -f /etc/init.d/mysql || test /etc/init.d/mariadb && ln -s /etc/init.d/mariadb /etc/init.d/mysql
/etc/init.d/mariadb stop &
/etc/init.d/mysql stop &

_kill_maria  &

wait


rm /var/run/mysqld/mysqld.pid

if [ "$(which mysqld |grep mysql|wc -l)" -gt 0 ] ;then echo -n "mysql found :"

      # fix possibly wrong permissions ( docker volumes)
        ( test -d  /var/lib/mysql && chown -R mysql:mysql /var/lib/mysql ) &
        ( mkdir /var/run/mysqld/ && chown -R mysql:mysql /var/run/mysqld/  ) &

    if [ -z "${MARIADB_ROOT_PASSWORD}" ]; then
        echo "MARIADB marked for installation , but no root password supplied, please set your own from command line (docker exec -it CONTAINER mysql -u root -p), dont forget to set it in /etc/mysql/debian.cnf and make that file persistent"
        [ "$(ls -A /var/lib/mysql)" ] && echo -n "/var/lib/mysql already filled" || mysql_install_db ;
        # exec /etc/init.d/mysql start &
    else
         echo -n "SETTING MARIA ROOT PASSWORD FROM ENV: "
         (	[ "$(ls /var/lib/mysql/mysql/user*)" ] && echo -n " /var/lib/mysql already filled" || mysql_install_db ;
        #mysqld_safe --skip-grant-tables &  sleep 3;
        /etc/init.d/mysql start
        sleep 2
        no_passwd_set=no
        echo -n "trying our root password from env"
        echo -e "[client]user=root\npassword=" | mysql --defaults-file=/dev/stdin --batch --silent -e "SHOW GLOBAL STATUS LIKE 'Uptime';" |grep -q Uptime && no_passwd_set=yes
        mysql --batch --silent -uroot -e "SHOW GLOBAL STATUS LIKE 'Uptime';" |grep -q Uptime && no_passwd_set=yes
        #mysql --batch --silent -uroot -e "select password from mysql.user where user='root'"
        echo "$no_passwd_set"|grep -q ^yes$ && (
       	echo "setting root password"
#            kill -QUIT $(pidof mysqld mysqld_safe ) 2>/dev/null;
#    sleep 0.2
#        kill -KILL $(pidof mysqld mysqld_safe ) 2>/dev/null;
#        /etc/init.d/mysql start;sleep 2
       echo -e "[client]user=root\npassword=" | mysqladmin --defaults-file=/dev/stdin -u root password $MARIADB_ROOT_PASSWORD

           )
        echo -e "[client]user=root\npassword=$MARIADB_ROOT_PASSWORD" | mysql --defaults-file=/dev/stdin --batch --silent -e "SHOW GLOBAL STATUS LIKE 'Uptime';" |grep -q Uptime && echo "MYSQL ROOT PASSWORD WORKS"|| echo "ERROR:MYSQL ROOT PASSWORD DOES NOT WORK WITH uptime COMMAND"

        echo -e "[client]user=root\npassword=$MARIADB_ROOT_PASSWORD" | mysql --defaults-file=/dev/stdin -u root -e "GRANT ALL ON *.* TO 'debian-sys-maint'@'localhost' IDENTIFIED BY '${MARIADB_ROOT_PASSWORD}' WITH GRANT OPTION; FLUSH PRIVILEGES;"
        echo "tryng mysql status"
        /etc/init.d/mysql status
        #mysql --batch --silent -uroot -e "use mysql;update user set authentication_string=password('"${MARIADB_ROOT_PASSWORD}"') where user='root'; flush privileges;" || echo "seems like MARIADB_ROOT_PASSWORD was already set"
        sed -i 's/^password.\+/password = '$MARIADB_ROOT_PASSWORD'/g' /etc/mysql/debian.cnf ;

        )
    fi

    if [ -z "${MARIADB_DATABASE}" ] ; then
                echo "NO DATABASE IN .env"
            else
      (   echo creating db ${MARIADB_DATABASE};
                SQL1="CREATE DATABASE IF NOT EXISTS \`${MARIADB_DATABASE}\` CHARACTER SET utf8 ;"
                SQL2="CREATE USER \`${MARIADB_USERNAME}\`@\`localhost\` IDENTIFIED BY '${MARIADB_PASSWORD}' ;CREATE USER \`${MARIADB_USERNAME}\`@\`%\` IDENTIFIED BY '${MARIADB_PASSWORD}' ;"
                SQL3="GRANT ALL PRIVILEGES ON \`${MARIADB_DATABASE}\`.* TO '${MARIADB_USERNAME}'@'localhost' IDENTIFIED BY '${MARIADB_PASSWORD}';GRANT ALL PRIVILEGES ON \`${MARIADB_DATABASE}\`.* TO '${MARIADB_USERNAME}'@'%' IDENTIFIED BY '${MARIADB_PASSWORD}';"
                SQL4="FLUSH PRIVILEGES;SHOW GRANTS FOR \`${MARIADB_USERNAME}\`@'localhost' ;SHOW GRANTS FOR \`${MARIADB_USERNAME}\`@'%' ; "
                SQL5="GRANT ALL ON *.* TO 'debian-sys-maint'@'localhost' IDENTIFIED BY '${MARIADB_ROOT_PASSWORD}' WITH GRANT OPTION; FLUSH PRIVILEGES;SHOW GRANTS"
            	 echo "executing ""${SQL1}""CREATE USER \`${MARIADB_USERNAME}\`@\`localhost\` IDENTIFIED BY ***MASKED***""${SQL3}""${SQL4}""GRANT ALL ON *.* TO 'debian-sys-maint'@'localhost' IDENTIFIED BY  ***MASKED*** WITH GRANT OPTION; FLUSH PRIVILEGES;SHOW GRANTS"
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
                    mysql -h $MARIADB_HOST -u root -p${MARIADB_ROOT_PASSWORD} -e "${SQL1}"
                    echo -n 2:
                    mysql -h $MARIADB_HOST -u root -p${MARIADB_ROOT_PASSWORD} -e "${SQL2}"
                    echo -n 3:
                    mysql -h $MARIADB_HOST -u root -p${MARIADB_ROOT_PASSWORD} -e "${SQL3}"
                    echo -n 4:
                    mysql -h $MARIADB_HOST -u root -p${MARIADB_ROOT_PASSWORD} -e "${SQL4}"
                    echo -n 5:
                    mysql -h $MARIADB_HOST -u root -p${MARIADB_ROOT_PASSWORD} -e "${SQL5}"
                    echo -n w:
                    mysql -h $MARIADB_HOST -u root -p${MARIADB_ROOT_PASSWORD} -e "SHOW WARNINGS;"
                    ln -s /etc/mysql/debian.cnf /root/.my.cnf
                fi
              )
            fi

test -e /root/.my.cnf || ln -s /etc/mysql/debian.cnf /root/.my.cnf
test -f /var/www/.my.cnf || ( /bin/bash -c 'echo -e  "[client]\nhost     = $MARIADB_HOST\nuser     = "$MARIADB_USERNAME"\npassword = "$MARIADB_PASSWORD"\nsocket   = /var/run/mysqld/mysqld.sock" > /var/www/.my.cnf ;chown www-data /var/www/.my.cnf ;chmod ugo-w  /var/www/.my.cnf' )

echo -n "TEARDOWN INIT SQL";
_kill_maria




else
   echo MARIADB not marked for installation ,
fi
