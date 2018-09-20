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
			(echo "AuthUser=${MAIL_USERNAME}";echo "AuthPass=${MAIL_PASSWORD}"; echo "AuthMethod=LOGIN";echo "FromLineOverride=YES";echo "mailhub=${MAIL_HOST}";echo "hostname=${APP_URL}";echo "UseTLS=YES";echo "UseSTARTTLS=YES"; ) > /etc/dockermail/ssmtp.conf
		fi
	fi

	if [ -f /etc/dockermail/ssmtp.conf ]; then
	    ln -sf /etc/dockermail/ssmtp.conf /etc/ssmtp/ssmtp.conf
	fi

fi


if [ "$MAIL_DRIVER" = "msmtp" ] ; then 
	if [ ! -f /etc/dockermail/php-mail.conf ]; then
	    echo "creating phpmail ssmtp entry"
	    echo "c2VuZG1haWxfcGF0aCA9IC91c3IvYmluL21zbXRwIC10Cg=="|base64 -d > /etc/dockermail/php-mail.conf 
	fi
	grep ssmtp /etc/dockermail/php-mail.conf -q && ( echo "c2VuZG1haWxfcGF0aCA9IC91c3IvYmluL21zbXRwIC10Cg=="|base64 -d > /etc/dockermail/php-mail.conf  )

	if [ -z "${MAIL_HOST}" ]; then
		echo "MAIL_HOST NOT SET in .env, not setting up MSMTP"
	else
		if [ -z "${APP_URL}" ]; then
			echo "APP_URL NOT SET in .env, not setting up MSMTP"
		else
			(echo "YWxpYXNlcyAgICAgICAgICAgICAgIC9ldGMvYWxpYXNlcy5tc210cAoKIyBVc2UgVExTIG9uIHBvcnQgNTg3CnBvcnQgNTg3CnRscyBvbgp0bHNfc3RhcnR0bHMgb24KdGxzX3RydXN0X2ZpbGUgL2V0Yy9zc2wvY2VydHMvY2EtY2VydGlmaWNhdGVzLmNydAojIFRoZSBTTVRQIHNlcnZlciBvZiB5b3VyIElTUAo="|base64 -d ;
			echo "host ${MAIL_HOST}";
			echo "domain ${APP_URL}";
			echo "user ${MAIL_USERNAME}";
			echo "password ${MAIL_PASSWORD}";
			echo "auth on";
			if [ -z "${MAIL_FROM}" ]; 
				then echo "from ${MAIL_USERNAME}";
				else echo "from ${MAIL_FROM}"
			fi
			 ) > /etc/dockermail/msmtprc
		fi
		if [ -z "${MAIL_ADMINISTRATOR}" ]; 
			then echo "::MAIL_ADMINISTRATOR not set FIX THIS !(msmtp)"
			else for user in www-data mailer-daemon postmaster nobody hostmaster usenet news webmaster www ftp abuse noc security root default;	do echo "$user: "${MAIL_ADMINISTRATOR} >> /etc/aliases.msmtp;done
		fi
	fi

	if [ -f /etc/dockermail/msmtprc ]; then
	    ln -sf /etc/dockermail/msmtprc /etc/msmtprc
	fi

fi

if [ -f /etc/dockermail/php-mail.conf ]; then
    test -d /usr/local/etc/php/conf.d/ && ln -sf /etc/dockermail/php-mail.conf /usr/local/etc/php/conf.d/mail.ini
    test -d /etc/php5/cli/conf.d/ && ln -sf /etc/dockermail/php-mail.conf /etc/php5/cli/conf.d/
    test -d /etc/php5/apache2/conf.d/ && ln -sf /etc/dockermail/php-mail.conf /etc/php5/apache2/conf.d/
    test -d /etc/php/7.0/apache2/conf.d/ && ln -sf /etc/dockermail/php-mail.conf /etc/php/7.0/apache2/conf.d/
    test -d /etc/php/7.0/cli/conf.d/ && ln -sf /etc/dockermail/php-mail.conf /etc/php/7.0/cli/conf.d/
    test -d /etc/php/7.2/apache2/conf.d/ && ln -sf /etc/dockermail/php-mail.conf /etc/php/7.2/apache2/conf.d/
    test -d /etc/php/7.2/cli/conf.d/ && ln -sf /etc/dockermail/php-mail.conf /etc/php/7.2/cli/conf.d/

fi


if [ "${INSTALL_MARIADB}" = "true" ]; then
        (test -d  /var/lib/mysql && chown -R mysql:mysql /var/lib/mysql ) &
	if [ -z "${MARIADB_ROOT_PASSWORD}" ]; then
	    echo "MARIADB marked for installation , but no root password supplied, please set your own from command line (docker exec -it CONTAINER mysql -u root -p), dont forget to set it in /etc/mysql/debian.cnf and make that file persistent"
	    [ "$(ls -A /var/lib/mysql)" ] && echo "/var/lib/mysql already filled" || mysql_install_db ;
	    exec /etc/init.d/mysql start &
	else
	     echo "SETTING MARIA ROOT PASSWORD FROM ENV"
	     (	[ "$(ls /var/lib/mysql/mysql/user*)" ] && echo "/var/lib/mysql already filled" || mysql_install_db ; mysqld_safe &  sleep 7; 
		echo "trying to select current root password, if empty, none is set"
	      	mysql --batch --silent -uroot -e "select password from mysql.user where user='root'"
        	echo "setting root password"
		mysqladmin -u root password $MARIADB_ROOT_PASSWORD
		#mysql --batch --silent -uroot -e "use mysql;update user set authentication_string=password('"${MARIADB_ROOT_PASSWORD}"') where user='root'; flush privileges;" || echo "seems like MARIADB_ROOT_PASSWORD was already set" 
		sed -i 's/^password.\+/password = '$MARIADB_ROOT_PASSWORD'/g' /etc/mysql/debian.cnf ; ) & 
	fi 

	if [ -z "${MARIADB_DATABASE}" ] ; then 
			    echo "NO DATABASE IN .env"
			else

			    ( sleep 15;
 			    echo creating db ${MARIADB_DATABASE};
			    SQL1="CREATE DATABASE IF NOT EXISTS ${MARIADB_DATABASE};"
			    SQL2="CREATE USER '${MARIADB_USERNAME}'@'localhost' IDENTIFIED BY '${MARIADB_PASSWORD}';"
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
			        ln -s /etc/mysql/debian.cnf /root/.my.cnf
    				fi
			  ) &
			fi 
	
else
   echo MARIADB not marked for installation ,
fi
test -e /root/.my.cnf|| ln -s /etc/mysql/debian.cnf /root/.my.cnf
#ls -lh1 /etc/apache2/sites*/*conf
test -f /etc/apache2/sites-available/default-ssl.conf || cp /etc/apache2/sites-available.default/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf 
test -f /etc/apache2/sites-available/000-default.conf || cp /etc/apache2/sites-available.default/000-default.conf /etc/apache2/sites-available/000-default.conf 

grep  "php_admin_value error_log" /etc/apache2/sites-available/000-default.conf || sed -i 's/AllowOverride All/AllowOverride All\nphp_admin_value error_log ${APACHE_LOG_DIR}\/php.error.log/g' /etc/apache2/sites-available/000-default.conf
grep  "php_admin_value error_log" /etc/apache2/sites-available/default-ssl.conf || sed -i 's/AllowOverride All/AllowOverride All\nphp_admin_value error_log ${APACHE_LOG_DIR}\/php.error.log/g' /etc/apache2/sites-available/default-ssl.conf

sed 's/CustomLog \/dev\/stdout/CustomLog ${APACHE_LOG_DIR}\/access.log/g' -i /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/default-ssl.conf
sed 's/ErrorLog \/dev\/stdout/ErrorLog ${APACHE_LOG_DIR}\/error.log/g'  -i /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/default-ssl.conf

if [ -z "${MAIL_ADMINISTRATOR}" ]; 
		then echo "::MAIL_ADMINISTRATOR not set FIX THIS !(apache ServerAdmin)"
		else sed 's/ServerAdmin webmaster@localhost/ServerAdmin '${MAIL_ADMINISTRATOR}'/g' -i /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/default-ssl.conf
fi	
exec a2ensite 000-default &
exec a2ensite default-ssl &

exec /etc/init.d/apache2 start &
exec service cron start &
exec /usr/sbin/dropbear -j -k -s -g -m -E -F 
