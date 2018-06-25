#!/bin/sh

CONF_DIR="/etc/dropbear"
SSH_KEY_DSS="${CONF_DIR}/dropbear_dss_host_key"
SSH_KEY_RSA="${CONF_DIR}/dropbear_rsa_host_key"
SSH_KEY_ECDSA="${CONF_DIR}/dropbear_ecdsa_host_key"
# Check if conf dir exists
if [ ! -d ${CONF_DIR} ]; then
    mkdir -p ${CONF_DIR}
fi
chown root:root ${CONF_DIR}
chmod 755 ${CONF_DIR}

# Check if keys exists
if [ ! -f ${SSH_KEY_DSS} ]; then
    dropbearkey  -t dss -f ${SSH_KEY_DSS}
fi
chown root:root ${SSH_KEY_DSS}
chmod 600 ${SSH_KEY_DSS}


if [ ! -f ${SSH_KEY_RSA} ]; then
    dropbearkey  -t rsa -f ${SSH_KEY_RSA} -s 2048
fi
if [ ! -f ${SSH_KEY_ECDSA} ]; then
    dropbearkey  -t ecdsa -f ${SSH_KEY_ECDSA}
fi

chown root:root ${SSH_KEY_RSA}
chmod 600 ${SSH_KEY_RSA}

test -d /var/www/html || ( mkdir /var/www/html;chown www-data:www-data /var/www/ /var/www/html) && (chown www-data:www-data /var/www/ /var/www/html)

if [ "$INSTALL_MONGOB" = "true" ] ; then 
	test -d /etc/mongodb || mkdir /etc/mongodb
	test -f /etc/mongodb/mongodb.conf || (mv /etc/mongodb.conf /etc/mongodb/mongodb.conf ; ln -s /etc/mongodb/mongodb.conf /etc/mongodb.conf )
fi


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
			(echo "FromLineOverride=YES";echo "mailhub=${MAIL_HOST}";echo "hostname=${APP_URL}";echo "UseTLS=YES";echo "UseSTARTTLS=YES" ) > /etc/dockermail/ssmtp.conf
		fi
	fi

	if [ -f /etc/dockermail/ssmtp.conf ]; then
	    ln -sf /etc/dockermail/ssmtp.conf /etc/ssmtp/ssmtp.conf
	fi

fi
if [ -f /etc/dockermail/php-mail.conf ]; then
    test -d /usr/local/etc/php/conf.d/ && ln -sf /etc/dockermail/php-mail.conf /usr/local/etc/php/conf.d/mail.ini
    test -d /etc/php5/cli/conf.d/ && ln -sf /etc/dockermail/php-mail.conf /etc/php5/cli/conf.d/
    test -d /etc/php5/apache2/conf.d/ && ln -sf /etc/dockermail/php-mail.conf /etc/php5/apache2/conf.d/
    test -d /etc/php/7.0/apache2/conf.d/ && ln -sf /etc/dockermail/php-mail.conf /etc/php/7.0/apache2/conf.d/
    test -d /etc/php/7.0/cli/conf.d/ && ln -sf /etc/dockermail/php-mail.conf /etc/php/7.0/cli/conf.d/

fi


if [ "${INSTALL_MARIADB}" = "true" ]; then
        (test -d  /var/lib/mysql && chown -R mysql:mysql /var/lib/mysql ) &
	if [ -z "${MARIADB_ROOT_PASSWORD}" ]; then
	    echo "MARIADB marked for installation , but no root password supplied, please set your own from command line (docker exec -it CONTAINER mysql -u root -p), dont forget to set it in /etc/mysql/debian.cnf and make that file persistent"
	    [ "$(ls -A /var/lib/mysql)" ] && echo "/var/lib/mysql already filled" || mysql_install_db ;
	    exec /etc/init.d/mysql start &
	else
	     echo "SETTING MARIA ROOT PASSWORD FROM ENV"
	     (	[ "$(ls -A /var/lib/mysql)" ] && echo "/var/lib/mysql already filled" || mysql_install_db ; mysqld_safe &  sleep 2; 
		echo "trying to select current root password, if empty, none is set"
	      	mysql --batch --silent -uroot -e "select password from mysql.user where user='root'"
        	echo "setting root password"
		mysqladmin -u root password $MARIADB_ROOT_PASSWORD
		#mysql --batch --silent -uroot -e "use mysql;update user set authentication_string=password('"${MARIADB_ROOT_PASSWORD}"') where user='root'; flush privileges;" || echo "seems like MARIADB_ROOT_PASSWORD was already set" 
		sed -i 's/^password.\+/password = '$MARIADB_ROOT_PASSWORD'/g' /etc/mysql/debian.cnf ; kill $(pidof mysqld);sleep 3 ;/etc/init.d/mysql start ) & 
	fi 

	if [ -z "${MARIADB_DATABASE}" ] ; then 
			    echo "NO DATABASE IN .env"
			else

			    (sleep 10;## to wait for mariadb
 			    echo creating db ${MARIADB_DATABASE};
			    SQL1="CREATE DATABASE IF NOT EXISTS ${MARIADB_DATABASE};"
			    SQL2="CREATE USER ${MARIADB_USERNAME} IDENTIFIED BY '${MARIADB_PASSWORD}';"
			    SQL3="GRANT ALL PRIVILEGES ON ${MARIADB_DATABASE}.* TO '${MARIADB_USERNAME}'@'%';"
			    SQL4="FLUSH PRIVILEGES;"

echo "executing ""${SQL1}""${SQL2}""${SQL3}""${SQL4}"
			    if [ -f /root/.my.cnf ]; then
			        mysql -e "${SQL1}"
			        mysql -e "${SQL2}"
			        mysql -e "${SQL3}"
			        mysql -e "${SQL4}"
			        mysql -e "SHOW WARNINGS;"
			    else
			        # If /root/.my.cnf doesn't exist then it'll take .env setting
			        mysql -h $MARIADB_HOST -u root -p${MARIADB_ROOT_PASSWORD} -e "${SQL1}"
			        mysql -h $MARIADB_HOST -u root -p${MARIADB_ROOT_PASSWORD} -e "${SQL2}"
			        mysql -h $MARIADB_HOST -u root -p${MARIADB_ROOT_PASSWORD} -e "${SQL3}"
			        mysql -h $MARIADB_HOST -u root -p${MARIADB_ROOT_PASSWORD} -e "${SQL4}"
			        mysql -h $MARIADB_HOST -u root -p${MARIADB_ROOT_PASSWORD} -e "SHOW WARNINGS;"
    				fi
			  ) &
			fi 
	
else
   echo MARIADB not marked for installation ,
fi
test -f /etc/apache2/sites-available/default-ssl.conf || cp /etc/apache2/sites-available.default/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf 
test -f /etc/apache2/sites-available/000-default.conf || cp /etc/apache2/sites-available.default/000-default.conf /etc/apache2/sites-available/000-default.conf 

exec a2ensite 000-default &
exec a2ensite default-ssl &

exec /etc/init.d/apache2 start &
exec service cron start &
exec /usr/sbin/dropbear -j -k -s -E -F
