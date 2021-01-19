##MAIL

test -d /etc/dockermail || mkdir /etc/dockermail


if [ -z "$MAIL_DRIVER" ] ; then
    MAIL_DRIVER=msmtp;export MAIL_DRIVER=msmtp;
fi

if [ "$MAIL_DRIVER" = "ssmtp" ] ; then
    if [ ! -f /etc/dockermail/php-mail.conf ]; then
        echo "creating phpmail ssmtp entry"
        echo "W21haWwgZnVuY3Rpb25dCnNlbmRtYWlsX3BhdGggPSAiL3Vzci9zYmluL3NzbXRwIC10IgoK"|base64 -d > /etc/dockermail/php-mail.conf
    fi

    if [ -z "${MAIL_HOST}" ]; then   echo "MAIL_HOST NOT SET in .env, not setting up SSMTP"
    else
        if [ -z "${APP_URL}" ]; then
                                     echo "APP_URL NOT SET in .env  , not setting up SSMTP"
        else
            (echo "AuthUser=${MAIL_USERNAME}";echo "AuthPass=${MAIL_PASSWORD}"; echo "AuthMethod=LOGIN";echo "FromLineOverride=YES";echo "mailhub=${MAIL_HOST}";echo "hostname=${APP_URL}";echo "UseTLS=YES";echo "UseSTARTTLS=YES"; ) > /etc/dockermail/ssmtp.conf
        fi
    fi

    if [ -f /etc/dockermail/ssmtp.conf ]; then
        ln -sf /etc/dockermail/ssmtp.conf /etc/ssmtp/ssmtp.conf
    fi

fi


##MAIL_DRIVER IS USED BY OTHER APPS LIKE OCTOBER     , swap
if [ "$MAIL_DRIVER" = "smtp" ] ; then
    MAIL_DRIVER=msmtp;export MAIL_DRIVER=msmtp;
fi

##MAIL_ENCRYPTION IS USED BY OTHER APPS LIKE OCTOBER ,swap
if [ "$MAIL_ENCRYPTION" = "tls" ] ; then
    MAIL_ENCRYPTION=starttls;export MAIL_ENCRYPTION=starttls;
fi
##MSMTP SETUP
if [ "$MAIL_DRIVER" = "msmtp" ] ; then
    if [ ! -f /etc/dockermail/php-mail.conf ]; then
        echo "creating phpmail msmtp entry"
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
            echo "maildomain ${APP_URL}"
            echo "auto_from off";
            echo "auth on";
            echo "logfile -"
            if [ -z "${MAIL_FROM}" ];
            	then echo 'from '${MAIL_USERNAME};
            	else echo 'from '${MAIL_FROM}
            fi
             ) > /etc/dockermail/msmtprc
        fi
        if [ -z "${MAIL_ADMINISTRATOR}" ];
            then echo "::MAIL_ADMINISTRATOR not set FIX THIS !(msmtp)"
        else
            test -e /etc/aliases.msmtp || touch /etc/aliases.msmtp
            for user in www-data mailer-daemon postmaster nobody hostmaster usenet news webmaster www ftp abuse noc security root default;	do
                grep -q "^${user}" /etc/aliases.msmtp || echo "${user}: "${MAIL_ADMINISTRATOR} >> /etc/aliases.msmtp;
            done
        fi
        ## IF the special mail username is used, we send directly without auth and tls
        if [ "$MAIL_USERNAME" = "InternalNoTLSNoAuth" ] ;then echo "using direct smtp port 25 with no auth and no tls" ;sed 's/tls_starttls.\+/tls_starttls off/g;s/^tls on/tls off/g;s/^auth on/auth off/g;s/^port .\+/port 25/g'  /etc/dockermail/msmtprc -i ;fi
        ##Replace legacy /dev/stdout logfiles in msmtprc since /dev/stdout is not writable in docker containers
        test -f /etc/msmtprc && sed 's/logfile \/dev\/stdout/logfile -/g' /etc/msmtprc  -i;
        test -f /etc/msmtprc && grep -q ^logfile /etc/msmtprc || { echo "logfile -" > /etc/msmtprc ; } ;
        test -f /etc/dockermail/msmtprc && sed 's/logfile \/dev\/stdout/logfile -/g' /etc/dockermail/msmtprc  -i
        test -f /etc/dockermail/msmtprc && grep -q ^logfile /etc/dockermail/msmtprc || { echo "logfile -" > /etc/dockermail/msmtprc ; } ;
    fi

    if [ -f /etc/dockermail/msmtprc ]; then
        ln -sf /etc/dockermail/msmtprc /etc/msmtprc
    fi
fi

## php mail setup
if [ -f /etc/dockermail/php-mail.conf ]; then
    chmod ugo+rx /etc/dockermail/ /etc/dockermail/php-mail.conf
    chown www-data  /etc/dockermail/php-mail.conf
    test -d /usr/local/etc/php/conf.d/ && ln -sf /etc/dockermail/php-mail.conf /usr/local/etc/php/conf.d/mail.ini
    #test -d /etc/php/7.2/apache2/conf.d/ && ln -sf /etc/dockermail/php-mail.conf /etc/php/7.2/apache2/conf.d/30-php-mail.ini


    #test -d /etc/php/8.0/cli/conf.d/ && ln -sf /etc/dockermail/php-mail.conf /etc/php/8.0/cli/conf.d/30-php-mail.ini

    for clidir in $(find /etc/php/ -type d -name cli);do
           echo setting up phpmail for  ${clidir}/conf.d;
           test -d ${clidir}/conf.d && ln -sf /etc/dockermail/php-mail.conf ${clidir}/conf.d/30-php-mail.ini ;
    done

    for apadir in $(find /etc/php*/ -type d -name apache2);do
           echo setting up phpmail for  ${apadir}/conf.d;
           test -d ${apadir}/conf.d && ln -sf /etc/dockermail/php-mail.conf ${apadir}/conf.d/30-php-mail.ini ;
    done

    for fpmdir in $(find /etc/php/ -type d -name fpm);do
           echo setting up phpmail for  ${clidir}/conf.d;
           test -d ${clidir}/conf.d && ln -sf /etc/dockermail/php-mail.conf ${clidir}/conf.d/30-php-mail.ini ;
    done

fi



##MAIL_DRIVER IS USED BY OTHER APPS LIKE OCTOBER
if [ "$MAIL_DRIVER" = "msmtp" ] ; then
    MAIL_DRIVER=smtp;
    export MAIL_DRIVER=smtp;
fi

##MAIL_ENCRYPTION IS USED BY OTHER APPS LIKE OCTOBER
if [ "$MAIL_ENCRYPTION" = "starttls" ] ; then
    MAIL_ENCRYPTION=tls;
    export MAIL_ENCRYPTION=tls;

fi
