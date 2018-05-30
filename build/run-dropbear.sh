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

if [ ! -f /etc/dockermail/php-mail.conf ]; then
    ln -sf /etc/dockermail/php-mail.conf /usr/local/etc/php/conf.d/mail.ini
    ln -sf /etc/dockermail/php-mail.conf /etc/php5/cli/conf.d/
    ln -sf /etc/dockermail/php-mail.conf /etc/php5/apache2/conf.d/
    ln -sf /etc/dockermail/php-mail.conf /etc/php/7.0/apache2/conf.d/
    ln -sf /etc/dockermail/php-mail.conf /etc/php/7.0/cli/conf.d/

fi
if [ ! -f /etc/dockermail/ssmtp.conf ]; then
    ln -sf /etc/dockermail/ssmtp.conf /etc/ssmtp/ssmtp.conf
fi


exec /etc/init.d/apache2 start &
exec service cron start &
exec /usr/sbin/dropbear -j -k -s -E -F
