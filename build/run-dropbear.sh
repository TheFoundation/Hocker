#!/bin/bash

echo "::STARTING"

echo "::TOOLKIT"
test -f /var/www/.toolkit || mkdir -p /var/www/.toolkit
test -f /var/www/.toolkit/sql.php || wget -O /var/www/.toolkit/sql.php -c $(curl -kLv https://github.com/vrana/adminer/releases/latest|grep php|grep releases/download|grep [0-9]/adminer.*[0-9].php|cut -d\" -f2|sed 's/^/https:\/\/github.com/g')

apk add git
echo -n "phpmemcached"
cd /var/www/.toolkit; git clone https://github.com/elijaa/phpmemcachedadmin.git /var/www/.toolkit/cache/
echo "PD9waHAKcmV0dXJuIGFycmF5ICgKICAnc3RhdHNfYXBpJyA9PiAnU2VydmVyJywKICAnc2xhYnNfYXBpJyA9PiAnU2VydmVyJywKICAnaXRlbXNfYXBpJyA9PiAnU2VydmVyJywKICAnZ2V0X2FwaScgPT4gJ1NlcnZlcicsCiAgJ3NldF9hcGknID0+ICdTZXJ2ZXInLAogICdkZWxldGVfYXBpJyA9PiAnU2VydmVyJywKICAnZmx1c2hfYWxsX2FwaScgPT4gJ1NlcnZlcicsCiAgJ2Nvbm5lY3Rpb25fdGltZW91dCcgPT4gJzEnLAogICdtYXhfaXRlbV9kdW1wJyA9PiAnMTAwJywKICAncmVmcmVzaF9yYXRlJyA9PiAyLAogICdtZW1vcnlfYWxlcnQnID0+ICc4MCcsCiAgJ2hpdF9yYXRlX2FsZXJ0JyA9PiAnOTAnLAogICdldmljdGlvbl9hbGVydCcgPT4gJzAnLAogICdmaWxlX3BhdGgnID0+ICdUZW1wLycsCiAgJ3NlcnZlcnMnID0+IAogIGFycmF5ICgKICAgICdEZWZhdWx0JyA9PiAKICAgIGFycmF5ICgKICAgICAgJ21lbWNhY2hlZDoxMTIxMScgPT4gCiAgICAgIGFycmF5ICgKICAgICAgICAnaG9zdG5hbWUnID0+ICdtZW1jYWNoZWQnLAogICAgICAgICdwb3J0JyA9PiAnMTEyMTEnLAogICAgICApLAogICAgKSwKICApLAopOwo=" |base64 -d > /var/www/.toolkit/cache/Config/Memcache.php
chown www-data:www-data /var/www/.toolkit/cache/Temp
chmod g+w /var/www/.toolkit/cache/Temp

echo "SNAKEOIL CERT:"

#test -f /etc/ssl/certs/ssl-cert-snakeoil.pem && test -f /etc/ssl/private/ssl-cert-snakeoil.key || openssl req -new -x509 -days 365 -nodes -out /etc/ssl/certs/ssl-cert-snakeoil.pem -keyout /etc/ssl/private/ssl-cert-snakeoil.key &
which  make-ssl-cert && test -f /etc/ssl/certs/ssl-cert-snakeoil.pem && test -f /etc/ssl/private/ssl-cert-snakeoil.key || make-ssl-cert generate-default-snakeoil --force-overwrite &

echo "DROPBEAR:"
CONF_DIR="/etc/dropbear"
SSH_KEY_DSS="${CONF_DIR}/dropbear_dss_host_key"
SSH_KEY_RSA="${CONF_DIR}/dropbear_rsa_host_key"
SSH_KEY_ECDSA="${CONF_DIR}/dropbear_ecdsa_host_key"
SSH_KEY_ED25519="${CONF_DIR}/dropbear_ed25519_host_key"

# Check if conf dir exists
if [ ! -d ${CONF_DIR} ]; then
    mkdir -p ${CONF_DIR}
fi

chown root:root ${CONF_DIR}
chmod 755 ${CONF_DIR}

# Check if keys exists
if [ ! -f ${SSH_KEY_RSA} ]; then
    dropbearkey  -t rsa -f ${SSH_KEY_RSA} -s 4096
    chown root:root        ${SSH_KEY_RSA}
    chmod 600              ${SSH_KEY_RSA}
fi & 


## OpenSSH 7.0 and greater similarly disables the ssh-dss (DSA) public key algorithm. It too is weak and we recommend against its use. 
rm ${SSH_KEY_DSS} 2>/dev/null || true &
## Check if keys exists
#if [ ! -f ${SSH_KEY_DSS} ]; then
#    dropbearkey  -t dss -f   ${SSH_KEY_DSS};    chown root:root          ${SSH_KEY_DSS};    chmod 600                ${SSH_KEY_DSS} 
#fi &

if [ ! -f ${SSH_KEY_ED25519} ]; then
    dropbearkey  -t ed25519 -f ${SSH_KEY_ED25519}
    chown root:root          ${SSH_KEY_ED25519}
    chmod 600                ${SSH_KEY_ED25519}

fi &

if [ ! -f ${SSH_KEY_ECDSA} ]; then
    dropbearkey  -t ecdsa -f ${SSH_KEY_ECDSA} -s 521
    chown root:root          ${SSH_KEY_ECDSA}
    chmod 600                ${SSH_KEY_ECDSA}

fi &

test -f /usr/libexec/sftp-server || (mkdir -p /usr/libexec/ && ln -s /usr/lib/sftp-server /usr/libexec/sftp-server)

########### WEBROOT / DROPBEAR / PERMISSION HUSSLE 
test -d /var/www/.ssh || ( mkdir /var/www/.ssh ;chown www-data:www-data /var/www/.ssh;touch /var/www/.ssh/authorized_keys;chmod 0600 /var/www/.ssh/authorized_keys /var/www/.ssh )
test -f /var/www/.ssh/authorized_keys && chown www-data:www-data /var/www/.ssh/authorized_keys
test -f /var/www/.ssh/authorized_keys && ( chmod 600 /var/www/.ssh/authorized_keys ;chmod ugo-w /var/www/.ssh/authorized_keys) 
test -d /var/www/.ssh && (chown www-data:www-data /var/www/.ssh ;chmod u+x /var/www/.ssh) &
test -d /root/.ssh || ( mkdir /root/.ssh;touch /root/.ssh/authorized_keys ; chmod 0600 /root/.ssh /root/.ssh/authorized_keys ) &

## USER DIR PREPARATION #######
## ssh reads .bash_profile and misses path from standard config
test -f /var/www/.bashrc ||  cp /root/.bashrc /var/www/ 
test -e /var/www/.bash_profile || ( ln -s /var/www/.bashrc /var/www/.bash_profile )
grep -q PATH /var/www/.bashrc || ( echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" >> /var/www/.bashrc ) &

test -d /var/www/html || ( mkdir /var/www/html;chown www-data:www-data /var/www/ /var/www/html) && (chown www-data:www-data /var/www/ /var/www/html) &
########################################################################################################

##fixing legacy composer version from ubuntu / debian 
(
cd /tmp/
    EXPECTED_SIGNATURE="$(wget -q -O - https://composer.github.io/installer.sig)"
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    ACTUAL_SIGNATURE="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

    if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]
    then
        >&2 echo 'ERROR: Invalid installer signature'
        rm composer-setup.php
        ##exit 1
    fi

    php composer-setup.php --quiet
    RESULT=$?
    rm composer-setup.php

    test -f composer.phar && (

    newest=$( (./composer.phar --version 2>/dev/null;composer --version 2>/dev/null)|sed 's/Composer version/Composer/g'|cut -d" " -f2-3|sed 's/ /-/g'|sort -n |tail -n1)
    upgrade=$(./composer.phar --version 2>/dev/null |sed 's/Composer version/Composer/g'|cut -d" " -f2-3|sed 's/ /-/g' )
    sysver=$(composer --version 2>/dev/null |sed 's/Composer version/Composer/g'|cut -d" " -f2-3|sed 's/ /-/g' )
    if [ "$sysver" != "$newest" ] ;then echo UPGRADING COMPOSER ;which composer >/dev/null && ( mv composer.phar $(which composer) ) || ( mv composer.phar /usr/bin/composer)  ;fi

    ) || (echo "NO COMPOSER DOWNLOADED" > /dev/stderr)

) &

####NOW THE .env party


##let other machines reach mariadb via network
if [ "$MARIADB_REMOTE_ACCESS" = "true"  ]; then
    sed 's/bind-address.\+/bind-adress = 0.0.0.0/g' /etc/mysql/*.cnf -i
fi

###enable ssh for www-data , put keys in /var/www/.ssh/authorized keys , deploy keys also under /var/www/.ssh/id-rsa{.pub}
if [ "$ENABLE_WWW_SHELL" = "true"  ]; then
    usermod -s /bin/bash www-data
fi
### www shell shortcut
echo "su -s /bin/bash www-data" > /usr/bin/wwwsh;chmod +x /usr/bin/wwwsh



if [ "$INSTALL_MONGOB" = "true" ] ; then
    test -d /etc/mongodb || mkdir /etc/mongodb
    test -f /etc/mongodb/mongodb.conf || (mv /etc/mongodb.conf /etc/mongodb/mongodb.conf ; ln -s /etc/mongodb/mongodb.conf /etc/mongodb.conf )
fi

##MAIL

test -d /etc/dockermail || mkdir /etc/dockermail

if [ "$MAIL_DRIVER" = "ssmtp" ] ; then
    if [ ! -f /etc/dockermail/php-mail.conf ]; then
        echo "creating phpmail ssmtp entry"
        echo "W21haWwgZnVuY3Rpb25dCnNlbmRtYWlsX3BhdGggPSAiL3Vzci9zYmluL3NzbXRwIC10IgoK"|base64 -d > /etc/dockermail/php-mail.conf
    fi

    if [ -z "${MAIL_HOST}" ]; then
        echo "MAIL_HOST NOT SET in .env, not setting up SSMTP"
    else
        if [ -z "${APP_URL}" ]; then
            echo "APP_URL NOT SET in .env, not setting up SSMTP"
        else
            (echo "AuthUser=${MAIL_USERNAME}";echo "AuthPass=${MAIL_PASSWORD}"; echo "AuthMethod=LOGIN";echo "FromLineOverride=YES";echo "mailhub=${MAIL_HOST}";echo "hostname=${APP_URL}";echo "UseTLS=YES";echo "UseSTARTTLS=YES"; ) > /etc/dockermail/ssmtp.conf
        fi
    fi

    if [ -f /etc/dockermail/ssmtp.conf ]; then
        ln -sf /etc/dockermail/ssmtp.conf /etc/ssmtp/ssmtp.conf
    fi

fi


##MAIL_DRIVER IS USED BY OTHER APPS LIKE OCTOBER
if [ "$MAIL_DRIVER" = "smtp" ] ; then
    MAIL_DRIVER=msmtp;
    export MAIL_DRIVER=msmtp;
fi

##MAIL_ENCRYPTION IS USED BY OTHER APPS LIKE OCTOBER
if [ "$MAIL_ENCRYPTION" = "tls" ] ; then
    MAIL_ENCRYPTION=starttls;
    export MAIL_ENCRYPTION=starttls;

fi

if [ "$MAIL_DRIVER" = "msmtp" ] ; then
    if [ ! -f /etc/dockermail/php-mail.conf ]; then
        echo "creating phpmail ssmtp entry"
        echo "c2VuZG1haWxfcGF0aCA9IC91c3IvYmluL21zbXRwIC10Cg=="|base64 -d > /etc/dockermail/php-mail.conf
    fi
    ### AUTO-UPGRADE SSMTP(OUTDATED) CONTAINERS
    grep ssmtp /etc/dockermail/php-mail.conf -q && ( echo "c2VuZG1haWxfcGF0aCA9IC91c3IvYmluL21zbXRwIC10Cg=="|base64 -d > /etc/dockermail/php-mail.conf  )

    if [ -z "${MAIL_HOST}" ]; then
        echo "MAIL_HOST NOT SET in .env, not setting up MSMTP"
    else
        if [ -z "${APP_URL}" ]; then
            echo "APP_URL NOT SET in .env, not setting up MSMTP"
        else
        (   echo "YWxpYXNlcyAgICAgICAgICAgICAgIC9ldGMvYWxpYXNlcy5tc210cAoKIyBVc2UgVExTIG9uIHBvcnQgNTg3CnBvcnQgNTg3CnRscyBvbgp0bHNfc3RhcnR0bHMgb24KdGxzX3RydXN0X2ZpbGUgL2V0Yy9zc2wvY2VydHMvY2EtY2VydGlmaWNhdGVzLmNydAojIFRoZSBTTVRQIHNlcnZlciBvZiB5b3VyIElTUAo="|base64 -d ;
            echo "host ${MAIL_HOST}";
            echo "domain ${APP_URL}";
            echo "user ${MAIL_USERNAME}";
            echo "password ${MAIL_PASSWORD}";
            echo "auto_from off";
            echo "auth on";
            if [ -z "${MAIL_FROM}" ];
            	then echo "from ${MAIL_USERNAME}";
            	else echo "from ${MAIL_FROM}"
            fi
             ) > /etc/dockermail/msmtprc
        fi
        if [ -z "${MAIL_ADMINISTRATOR}" ];
            then echo "::MAIL_ADMINISTRATOR not set FIX THIS !(msmtp)"
        else
            test -e /etc/aliases.msmtp || touch /etc/aliases.msmtp
            for user in www-data mailer-daemon postmaster nobody hostmaster usenet news webmaster www ftp abuse noc security root default;	do
                grep -q "$user" /etc/aliases.msmtp || echo "$user: "${MAIL_ADMINISTRATOR} >> /etc/aliases.msmtp;
            done
        fi
        ## IF the special mail username is used, we send directly without auth and tls
        if [ "$MAIL_USERNAME" = "InternalNoTLSNoAuth" ] ;then echo "using direct smtp port 25 with no auth and no tls" ;sed 's/tls_starttls.\+/tls_starttls off/g;s/^tls on/tls off/g;s/^auth on/auth off/g;s/^port .\+/port 25/g'  /etc/dockermail/msmtprc -i ;fi
        ##Replace legacy /dev/stdout logfiles in msmtprc since /dev/stdout is not writable in docker containers
        sed 's/logfile \/dev\/stdout/logfile -/g' /etc/msmtprc  -i;sed 's/logfile \/dev\/stdout/logfile -/g' /etc/dockermail/msmtprc  -i
    fi

    if [ -f /etc/dockermail/msmtprc ]; then
        ln -sf /etc/dockermail/msmtprc /etc/msmtprc
    fi

fi

if [ -f /etc/dockermail/php-mail.conf ]; then
    chmod ugo+rx /etc/dockermail/ /etc/dockermail/php-mail.conf
    chown www-data  /etc/dockermail/php-mail.conf
    test -d /usr/local/etc/php/conf.d/ && ln -sf /etc/dockermail/php-mail.conf /usr/local/etc/php/conf.d/mail.ini
    test -d /etc/php5/cli/conf.d/ && ln -sf /etc/dockermail/php-mail.conf /etc/php5/cli/conf.d/30-php-mail.ini
    test -d /etc/php5/apache2/conf.d/ && ln -sf /etc/dockermail/php-mail.conf /etc/php5/apache2/conf.d/30-php-mail.ini
    #test -d /etc/php/7.0/apache2/conf.d/ && ln -sf /etc/dockermail/php-mail.conf /etc/php/7.0/apache2/conf.d/30-php-mail.ini
    #test -d /etc/php/7.2/apache2/conf.d/ && ln -sf /etc/dockermail/php-mail.conf /etc/php/7.2/apache2/conf.d/30-php-mail.ini

for apadir in $(find /etc/php/ -type d -name apache2);do echo setting up phpmail for  ${apadir}/conf.d; test -d ${apadir}/conf.d && ln -sf /etc/dockermail/php-mail.conf ${apadir}/conf.d/30-php-mail.ini ;done

    #test -d /etc/php/7.0/cli/conf.d/ && ln -sf /etc/dockermail/php-mail.conf /etc/php/7.0/cli/conf.d/30-php-mail.ini
    #test -d /etc/php/7.2/cli/conf.d/ && ln -sf /etc/dockermail/php-mail.conf /etc/php/7.2/cli/conf.d/30-php-mail.ini
    #test -d /etc/php/7.3/cli/conf.d/ && ln -sf /etc/dockermail/php-mail.conf /etc/php/7.3/cli/conf.d/30-php-mail.ini
    #test -d /etc/php/7.4/cli/conf.d/ && ln -sf /etc/dockermail/php-mail.conf /etc/php/7.4/cli/conf.d/30-php-mail.ini
    #test -d /etc/php/8.0/cli/conf.d/ && ln -sf /etc/dockermail/php-mail.conf /etc/php/8.0/cli/conf.d/30-php-mail.ini
    for clidir in $(find /etc/php/ -type d -name cli);do echo setting up phpmail for  ${clidir}/conf.d; test -d ${clidir}/conf.d && ln -sf /etc/dockermail/php-mail.conf ${clidir}/conf.d/30-php-mail.ini ;done
fi

###TIME
if [ -z "${APP_TIMEZONE}" ] ; then
    echo "TIMEZONE NOT SET, USE APP_TIMEZONE= in .env, setting  default";
    /bin/ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime  ;
else
    echo "SETTING TIMEZONE  ";
    test -f /usr/share/zoneinfo/${APP_TIMEZONE} || echo "TIMEZONE GIVEN DOES NOT EXIST"
    test -f /usr/share/zoneinfo/${APP_TIMEZONE} && /bin/ln -sf /usr/share/zoneinfo/${APP_TIMEZONE} /etc/localtime;
fi


###MARIADB
echo "mariadb install setting :"${INSTALL_MARIADB}

test -f /etc/init.d/mysql || test /etc/init.d/mariadb && ln -s /etc/init.d/mariadb /etc/init.d/mysql

/etc/init.d/mysql stop

ps -ALFc|grep -q mysqld && (
killall -QUIT $(pidof mysqld mysqld_safe) mysqld mysqld_safe 2>/dev/null &
sleep 0.2
killall -KILL $(pidof mysqld mysqld_safe) mysqld mysqld_safe 2>/dev/null &
)

rm /var/run/mysqld/mysqld.pid

if [ "$(which mysqld |grep mysql|wc -l)" -gt 0 ] ;then echo mysql found
      
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
ps -ALFc|grep -q mysqld && (
killall -QUIT $(pidof mysqld mysqld_safe) mysqld mysqld_safe 2>/dev/null &
sleep 0.2
killall -KILL $(pidof mysqld mysqld_safe) mysqld mysqld_safe 2>/dev/null &
)

else
   echo MARIADB not marked for installation ,
fi

#ls -lh1 /etc/apache2/sites*/*conf
test -f /etc/apache2/sites-available/default-ssl.conf || cp /etc/apache2/sites-available.default/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf
test -f /etc/apache2/sites-available/000-default.conf || cp /etc/apache2/sites-available.default/000-default.conf /etc/apache2/sites-available/000-default.conf

#disable exec time for shell
find /etc/php/*/cli/ -name php.ini |while read php_cli_ini ;do sed 's/max_execution_time.\+/max_execution_time = 0 /g ' -i $php_cli_ini & done

#raise upload limit for default 2M to 128M

if [  -z "${MAX_UPLOAD_MB}" ] ; then
find /etc/php/*/ -name php.ini |while read php_ini ;do sed 's/upload_max_filesize = 2M/upload_max_filesize = 128M /g;s/post_max_size.\+/post_max_size = 128M/g' -i $php_ini & done

else

find /etc/php/*/ -name php.ini |while read php_ini ;do sed 's/upload_max_filesize.*/upload_max_filesize = '${MAX_UPLOAD_MB}'M /g;s/post_max_size.\+/post_max_size = '${MAX_UPLOAD_MB}'M/g' -i $php_ini & done

fi


if [ "$(ls -1 /usr/sbin/php-fpm* 2>/dev/null|wc -l)" -eq 0 ];then echo "apache:mod-php  , no fpm executable"
    grep  "php_admin_value error_log" /etc/apache2/sites-available/000-default.conf || sed -i 's/AllowOverride All/AllowOverride All\nphp_admin_value error_log ${APACHE_LOG_DIR}\/php.error.log/g' /etc/apache2/sites-available/000-default.conf
    grep  "php_admin_value error_log" /etc/apache2/sites-available/default-ssl.conf || sed -i 's/AllowOverride All/AllowOverride All\nphp_admin_value error_log ${APACHE_LOG_DIR}\/php.error.log/g' /etc/apache2/sites-available/default-ssl.conf
    ln -sf /etc/php/$(php --version|head -n1|cut -d" " -f2|cut -d\. -f 1,2)/apache2/php.ini /var/www/php.ini
else  ### FPM DETECTED

    mkdir -p /run/php &>/dev/null 
    ## if image builder missed it: softlink version-specific php fpm sock
    PHPLONGVersion=$(php --version|head -n1 |cut -d " " -f2);
    PHPVersion=${PHPLONGVersion:0:3};
    test -f /run/php/php-fpm.sock || ln -s /run/php/php${PHPVersion}-fpm.sock /run/php/php-fpm.sock
## config fpm
    echo "apache:php-fpm or nginx fpm";
    #disable php_admin_values since apache does not start with fpm and php_admin_value
    sed 's/php_admin_value/#php_admin_value/g;s/php_value/#php_value/g' -i  /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-enabled/000-default.conf /etc/apache2/sites-enabled/default-ssl.conf
    ## idle timeout was often not set
    sed 's/sock -pass-header Authorization/sock -idle-timeout 600 -pass-header Authorization/g' /etc/apache2/sites-enabled/default-ssl.conf -i
    grep "sock -idle-timeout 600 -pass-header Authorization" /etc/apache2/sites-enabled/default-ssl.conf || (
                        echo "fpm config init" ;
                        sed 's/<VirtualHost.\+/\0\n\t\tAddType application\/x-httpd-php    .php .php7 # .phtml #.htm .html # .php5 #.php4\n\t\tAction application\/x-httpd-php \/php-fcgi\n\t\tAction php-fcgi \/php-fcgi\n\t\t\n\t\tFastCgiExternalServer \/usr\/lib\/cgi-bin\/php-fcgi -socket \/var\/run\/php\/php-fpm.sock -idle-timeout 600 -pass-header Authorization\n\t\tAlias \/php-fcgi \/usr\/lib\/cgi-bin\/php-fcgi\n\t\tSetEnv PHP_VALUE "max_execution_time = 600"\n\t\tSetEnv PHP_VALUE "include_path = ./:\/var\/www\/include_local:\/var\/www\/include"\n\n\t\t<Directory \/usr\/lib\/cgi-bin>\nRequire all granted\n<\/Directory>\n/g'   /etc/apache2/sites-enabled/default-ssl.conf -i
                          ## enable fpm error login
                          #;catch_workers_output = yes
                          #FORCE php_admin_flag[log_errors] = on
                          find /etc/php/*/fpm/ -name www.conf |while read fpmpool;do grep "^php_admin_flag\\[log_errors\\] = on" $fpmpool -q || echo "php_admin_flag[log_errors] = on" |tee -a $fpmpool;done
                          # FORCE php_admin_value[error_log] = /dev/stderr
                          find /etc/php/*/fpm/ -name www.conf |while read fpmpool;do grep "^php_admin_value\\[error_log\\] = /dev/stderr" $fpmpool  || echo "php_admin_value[error_log] = /dev/stderr" |tee -a $fpmpool;done
                          ## link php.ini
                          ln -sf /etc/php/$(php --version|head -n1|cut -d" " -f2|cut -d\. -f 1,2)/fpm/php.ini /var/www/php.ini )
                        fi


## SPAWN APACHE PRRECONFIG
( sed 's/CustomLog \/dev\/stdout/CustomLog ${APACHE_LOG_DIR}\/access.log/g' -i /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/default-ssl.conf ;
  sed 's/ErrorLog \/dev\/stdout/ErrorLog ${APACHE_LOG_DIR}\/error.log/g'    -i /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/default-ssl.conf ;
if [ -z "${MAIL_ADMINISTRATOR}" ];
        then echo "::MAIL_ADMINISTRATOR not set FIX THIS !(apache ServerAdmin)"
        else sed 's/ServerAdmin webmaster@localhost/ServerAdmin '${MAIL_ADMINISTRATOR}'/g' -i /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/default-ssl.conf
fi ) &
  
which a2enmod  2>/dev/null && a2enmod  headers &
which a2ensite 2>/dev/null && a2ensite 000-default &
which a2ensite 2>/dev/null && a2ensite default-ssl &

wait

test -f /usr/sbin/sendmail.real || (test -f /usr/sbin/sendmail.cron && (mv /usr/sbin/sendmail /usr/sbin/sendmail.real;ln -s /usr/sbin/sendmail.cron /usr/sbin/sendmail))

#ln -sf /dev/stdout /var/log/apache2/access.log
#ln -sf /dev/stderr /var/log/apache2/error.log
#ln -sf /dev/stdout /var/log/apache2/other_vhosts_access.log

rm /var/log/apache2/access.log /var/log/apache2/error.log /var/log/apache2/other_vhosts_access.log /etc/apache2/sites-enabled/symfony.conf 2>/dev/null 
mkfifo /var/log/apache2/access.log /var/log/apache2/error.log /var/log/apache2/other_vhosts_access.log
( while (true);do cat /var/log/apache2/access.log              |grep -v -e 'StatusCabot' -e '"cabot/' -e '"HEAD / HTTP/1.1" 200 - "-" "curl/' -e "UptimeRobot/" -e "docker-health-check/over9000" -e "/favicon.ico" ;sleep 0.2;done ) &
( while (true);do cat /var/log/apache2/other_vhosts_access.log |grep -v -e 'StatusCabot' -e '"cabot/' -e '"HEAD / HTTP/1.1" 200 - "-" "curl/' -e "UptimeRobot/" -e "docker-health-check/over9000" -e "/favicon.ico" ;sleep 0.2;done ) &
( while (true);do cat /var/log/apache2/error.log               |grep -v -e 'StatusCabot' -e '"cabot/' -e '"HEAD / HTTP/1.1" 200 - "-" "curl/' -e "UptimeRobot/" -e "docker-health-check/over9000" -e "/favicon.ico" 1>&2;sleep 0.2;done ) & 

if [ "$(which supervisord >/dev/null |wc -l)" -lt 0 ] ;then
                    echo "no supervisord,classic start==foregrounding dropbear"
                    /etc/init.d/apache2 start &
                    ##in case of fpm , Dockerfile inserts fpm start right after cron( 2 lines below ), but supervisord should be used anyway
                    service cron start &
                    which /etc/init.d/mysql >/dev/null && /etc/init.d/mysql start &
                    which /etc/inid.d/redis-server && /etc/inid.d/redis-server start &
                    exec /usr/sbin/dropbear -j -k -s -g -m -E -F

            else
                    echo "supervisord init"
                    ##supervisord section
                    ##config init
                    mkdir -p /etc/supervisor/conf.d/
                    ### FIX REDIS CONFIG - LOGFILE DIR NONEXISTENT (and stderr is wanted 4 now) - DOCKER HAS NO ::1 BY DEFAULT - "daemonize no" HAS TO BE SET TO  with supervisor
                    
                    ## supervisor:websockets.chat

                    for artisanfile in /var/www/*/artisan ;do php ${artisanfile} 2>&1 |grep -q websockets:run  && (
                    cat > /etc/supervisor/conf.d/websockets_${artisanfile//\//_}.conf << EOF
[program:websockets]
command=su -s /bin/bash -c 'cd /var/www/html/;php artisan websockets:run' www-data
stdout_logfile=/dev/stdout
stderr_logfile=/dev/stderr
stdout_logfile_maxbytes=0
stderr_logfile_maxbytes=0
autorestart=true                    

EOF
                     
                     ) ;done 
                    

                    
                    
                    
                    ## supervisor:redis
                    which /usr/bin/redis-server >/dev/null &&  ( ( echo  "[program:redis]";echo "command=/usr/bin/redis-server /etc/docker_redis.conf";echo "stdout_logfile=/dev/stdout" ;echo "stderr_logfile=/dev/stderr" ;echo "stdout_logfile_maxbytes=0";echo "stderr_logfile_maxbytes=0";echo "autorestart=true" ) > /etc/supervisor/conf.d/redis.conf  ;  sed 's/^daemonize.\+/daemonize no/g;s/bind.\+/bind 127.0.0.1/g;s/logfile.\+/logfile \/dev\/stderr/g' /etc/redis/redis.conf > /etc/docker_redis.conf )
                    
                    ## supervisor:mysql                    
                    sleep 2 ; which /etc/init.d/mysql >/dev/null &&  ( ( echo  "[program:mariadb]";echo "command=/usr/sbin/mysqld --basedir=/usr --datadir=/var/lib/mysql";echo "stdout_logfile=/dev/stdout" ;echo "stderr_logfile=/dev/stderr" ;echo "stdout_logfile_maxbytes=0";echo "stderr_logfile_maxbytes=0";echo "autorestart=true" ) > /etc/supervisor/conf.d/mariadb.conf  ; service mysql stop; killall -KILL mysqld mysqld_safe )
                    
                    ## supervisor:dropbear                    
                    which /usr/sbin/dropbear >/dev/null &&  ( ( echo  "[program:dropbear]";echo "command=/usr/sbin/dropbear -j -k -s -g -m -E -F";echo "stdout_logfile=/dev/stdout" ;echo "stderr_logfile=/dev/stderr" ;echo "stdout_logfile_maxbytes=0";echo "stderr_logfile_maxbytes=0";echo "autorestart=true" ) > /etc/supervisor/conf.d/dropbear.conf   )
                    
                    
                    if [ "$(ls -1 /usr/sbin/php-fpm* 2>/dev/null|wc -l)" -eq 0 ];then echo ;
                    															else fpmexec=$(ls -1 /usr/sbin/php-fpm* |sort -n|tail -n1 )" -F" ;( ( echo  "[program:php-fpm]";echo "command="$fpmexec;echo "stdout_logfile=/dev/stdout" ;echo "stderr_logfile=/dev/stderr" ;echo "stdout_logfile_maxbytes=0";echo "stderr_logfile_maxbytes=0";echo "autorestart=true" ) > /etc/supervisor/conf.d/php-fpm.conf)
                    															fi
                     #supervisord one line config  deprecated , copy from dockerfiles used
                 #echo "W3N1cGVydmlzb3JjdGxdCnNlcnZlcnVybD11bml4Oi8vL3Zhci9ydW4vc3VwZXJ2aXNvci5zb2NrIDsgdXNlIGEgdW5peDovLyBVUkwgZm9yIGEgdW5peCBzb2NrZXQKdXNlcm5hbWUgPSBkdW1teQpwYXNzd29yZCA9IGR1bW15Cgpbc3VwZXJ2aXNvcmRdCm5vZGFlbW9uPXRydWUKbG9nZmlsZT0vZGV2L3N0ZGVyciA7IChtYWluIGxvZyBmaWxlO2RlZmF1bHQgJENXRC9zdXBlcnZpc29yZC5sb2cpCnBpZGZpbGU9L3Zhci9ydW4vc3VwZXJ2aXNvcmQucGlkIDsgKHN1cGVydmlzb3JkIHBpZGZpbGU7ZGVmYXVsdCBzdXBlcnZpc29yZC5waWQpCmNoaWxkbG9nZGlyPS92YXIvbG9nL3N1cGVydmlzb3IgICAgICAgICAgICA7IChBVVRPIGNoaWxkIGxvZyBkaXIsIGRlZmF1bHQgJFRFTVApCmxvZ2ZpbGVfbWF4Ynl0ZXM9MAo7IEl0IHJlc29sdmVzIHRoZSDCq0NSSVQgU3VwZXJ2aXNvciBydW5uaW5nIGFzIHJvb3QgKG5vIHVzZXIgaW4gY29uZmlnIGZpbGUpwrsgd2FybmluZyBpbiB0aGUgbG9nLgp1c2VyID0gcm9vdAoKW3JwY2ludGVyZmFjZTpzdXBlcnZpc29yXQpzdXBlcnZpc29yLnJwY2ludGVyZmFjZV9mYWN0b3J5ID0gc3VwZXJ2aXNvci5ycGNpbnRlcmZhY2U6bWFrZV9tYWluX3JwY2ludGVyZmFjZQoKW3N1cGVydmlzb3JjdGxdCnNlcnZlcnVybD11bml4Oi8vL3Zhci9ydW4vc3VwZXJ2aXNvci5zb2NrIDsgdXNlIGEgdW5peDovLyBVUkwgIGZvciBhIHVuaXggc29ja2V0CgpbdW5peF9odHRwX3NlcnZlcl0KZmlsZT0vdmFyL3J1bi9zdXBlcnZpc29yLnNvY2sgOyAodGhlIHBhdGggdG8gdGhlIHNvY2tldCBmaWxlKQpjaG1vZD0wNzAwIDsgc29ja2VmIGZpbGUgbW9kZSAoZGVmYXVsdCAwNzAwKQp1c2VybmFtZSA9IGR1bW15CnBhc3N3b3JkID0gZHVtbXkKCgpbcHJvZ3JhbTphcGFjaGVdCmNvbW1hbmQ9L2Jpbi9iYXNoIC1jICdwaWRvZiBhcGFjaGUyIGFwYWNoZTJjdHx3YyAtY3xncmVwIF4wIC1xICYmIGtpbGxhbGwgJChwaWRvZiBhcGFjaGUyIGFwYWNoZTJjdGwgMj4vZGV2L251bGwgKSA7Z3JlcCBhcGFjaGUgL3Byb2MvJChjYXQgL3Zhci9ydW4vYXBhY2hlMi9hcGFjaGUyLnBpZCkvY21kbGluZSAtcSB8fCBybSAvdmFyL3J1bi9hcGFjaGUyL2FwYWNoZTIucGlkOyBhcGFjaGUyY3RsIC1ERk9SRUdST1VORDtzbGVlcCAwLjInCnN0ZG91dF9sb2dmaWxlPS9kZXYvc3Rkb3V0CnN0ZG91dF9sb2dmaWxlX21heGJ5dGVzPTAKc3RkZXJyX2xvZ2ZpbGU9L2Rldi9zdGRlcnIKc3RkZXJyX2xvZ2ZpbGVfbWF4Ynl0ZXM9MAphdXRvc3RhcnQ9dHJ1ZQphdXRvcmVzdGFydD10cnVlCmtpbGxhc2dyb3VwPXRydWUKc3RvcGFzZ3JvdXA9dHJ1ZQoKW3Byb2dyYW06Y3Jvbl0KY29tbWFuZD1jcm9uIC1mCmF1dG9zdGFydD10cnVlCmF1dG9yZXN0YXJ0PXRydWUKc3Rkb3V0X2xvZ2ZpbGU9L2Rldi9zdGRvdXQKc3Rkb3V0X2xvZ2ZpbGVfbWF4Ynl0ZXM9MApzdGRlcnJfbG9nZmlsZT0vZGV2L3N0ZGVycgpzdGRlcnJfbG9nZmlsZV9tYXhieXRlcz0wCgoKW2luY2x1ZGVdCmZpbGVzID0gL2V0Yy9zdXBlcnZpc29yL2NvbmYuZC8qLmNvbmYKCg==" |base64 -d> /etc/supervisor/supervisord.conf
                    exec $(which supervisord || echo /usr/bin/supervisord) -c /etc/supervisor/supervisord.conf
fi
