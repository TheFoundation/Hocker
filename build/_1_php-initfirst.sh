#!/bin/bash
## open_basedir and chroot need a session store path if redis/sql is  not engaged

PHPLONGVersion=$(php --version|head -n1 |cut -d " " -f2);
PHPVersion=${PHPLONGVersion:0:3};


#ls -lh1 /etc/apache2/sites*/*conf
test -f /etc/apache2/sites-available/default-ssl.conf || cp /etc/apache2/sites-available.default/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf
test -f /etc/apache2/sites-available/000-default.conf || cp /etc/apache2/sites-available.default/000-default.conf /etc/apache2/sites-available/000-default.conf

#disable exec time for shell
find /etc/php/*/cli/ -name php.ini |while read php_cli_ini ;do sed 's/max_execution_time.\+/max_execution_time = 0 /g ' -i $php_cli_ini & done


#echo ":MOD:"
## apache modules
which a2enmod  &>/dev/null && a2enmod  headers &>/dev/null &
which a2ensite &>/dev/null && a2ensite 000-default &>/dev/null &
which a2ensite &>/dev/null && a2ensite default-ssl &>/dev/null &
test -e /etc/apache-extra-config  || mkdir /etc/apache-extra-config &

## php fixup

phpenmod redis &>>/dev/shm/init_phpmods &>/dev/null  || true &
phpenmod memcached &>>/dev/shm/init_phpmods &>/dev/null || true &

## sessions folder

test -d /var/www/.phpsessions || mkdir /var/www/.phpsessions &
chown -R www-data:www-data /var/www/.phpsessions &
mkdir -p /run/php &>/dev/null



## if image builder missed it: softlink version-specific php fpm sock
test -f /run/php/php-fpm.sock || ln -s /run/php/php${PHPVersion}-fpm.sock /run/php/php-fpm.sock
#disable php_admin_values since apache does not start with fpm and php_admin_value




echo " sys.info  | :LOG /dev/stderr /dev/stdout"
lgf_ngx=/var/log/nginx/access.log
erl_ngx=/var/log/nginx/error.log
lgf_apa=/var/log/apache2/access.log
erl_apa=/var/log/apache2/error.log
oth_apa=/var/log/apache2/other_vhosts_access.log
sym_apa=/var/log/apache2/symfony.log
for logfile in ${lgf_ngx}  ${lgf_apa} ${oth_apa} ${sym_apa} ;do
    test -d $(basename ${logfile})||mkdir -p $(basename ${logfile});rm ${logfile}   2>/dev/null ;   ln -s /dev/stdout ${logfile}  2>/dev/null
done
for logfile in ${erl_ngx} ${erl_apa} ;do
    test -d $(basename ${logfile})||mkdir -p $(basename ${logfile});rm ${logfile}   2>/dev/null ;   ln -s /dev/stderr ${logfile}  2>/dev/null
done &

###
echo

## SPAWN APACHE PRRECONFIG
which apache2ctl && (
      echo "APA:PRECONF:"
## since fpm will be on the other end, the risk of "growing OOM php process should be very low "
    sed 's/MaxKeepAliveRequests.\+/MaxKeepAliveRequests 256/g' /etc/apache2/apache2.conf -i
    ## waiting 5 sec for keepalive opes/closes all the time for idle sites
    sed 's/KeepAliveTimeout.\+/KeepAliveTimeout 45/g' /etc/apache2/apache2.conf -i


## add mpm config
grep -q MaxClients /etc/apache2/apache2.conf || echo '<IfModule mpm_prefork_module>
 StartServers 2
 MinSpareServers 1
 MaxSpareServers 3
 MaxClients 200 #must be customized
 ServerLimit 200 #must be customized
 MaxRequestsPerChild 250
 </IfModule>' >> /etc/apache2/apache2.conf

## hide server banner
    grep "ServerTokens Prod"   /etc/apache2/apache2.conf || echo "ServerTokens Prod" >> /etc/apache2/apache2.conf
    grep "ServerSignature Off" /etc/apache2/apache2.conf || echo "ServerSignature Off" >> /etc/apache2/apache2.conf
    #hide dirindex not found
    grep "LogLevel autoindex:crit" /etc/apache2/apache2.conf|| { echo "LogLevel autoindex:crit" >>/etc/apache2/apache2.conf ; } ;
    #  apache does not log to a fifo
    # sed 's/CustomLog \/dev\/stdout/CustomLog ${APACHE_LOG_DIR}\/access.log/g' -i /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/default-ssl.conf ;
    #  sed 's/ErrorLog \/dev\/stdout/ErrorLog ${APACHE_LOG_DIR}\/error.log/g'    -i /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/default-ssl.conf ;
    sed 's/AccessLog.\+\.log/AccessLog  "| \/bin\/bash \/_3_logfilter_apache.sh >> \/dev\/stdout"/g'  -i /etc/apache2/sites-enabled/*.conf  ;
    sed 's/CustomLog.\+\.log/CustomLog  "| \/bin\/bash \/_3_logfilter_apache.sh >> \/dev\/stdout"/g'  -i /etc/apache2/sites-enabled/*.conf  ;
    sed  's/ErrorLog.\+\.log/ErrorLog   \/dev\/stderr /g'                                               -i /etc/apache2/sites-enabled/*.conf  ;
    #sed  's/ErrorLog.\+\.log/ErrorLog   "| \/bin\/bash \/_3_logfilter_apache.sh >> \/dev\/stderr"/g'  -i /etc/apache2/sites-enabled/*.conf  ;
    if [ -z "${MAIL_ADMINISTRATOR}" ];
      then echo "::MAIL_ADMINISTRATOR not set FIX THIS !(apache ServerAdmin)"
    else
      sed 's/ServerAdmin webmaster@localhost/ServerAdmin '${MAIL_ADMINISTRATOR}'/g' -i /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/default-ssl.conf
    fi &
    ) &




(
[[  -z "${MAX_UPLOAD_MB}" ]]  &&  echo " init.php  | using default MAX_UPLOAD: 256 MB"
[[  -z "${MAX_UPLOAD_MB}" ]]  && MAX_UPLOAD_MB=256
#raise upload limit for default 2M to 128M
if [  -z "${MAX_UPLOAD_MB}" ] ; then
    find /etc/php/*/ -name php.ini |while read php_ini ;do
                                           sed 's/upload_max_filesize.\+/upload_max_filesize = 256M /g;s/post_max_size.\+/post_max_size = 256M/g' -i ${php_ini}
                                         done
else
    find /etc/php/*/ -name php.ini |while read php_ini ;do
                                           sed 's/upload_max_filesize.\+/upload_max_filesize = '${MAX_UPLOAD_MB}'M /g;s/post_max_size.\+/post_max_size = '${MAX_UPLOAD_MB}'M/g' -i ${php_ini}
                                         done
fi ; echo " init.php  | MAX_UPLOAD: ${MAX_UPLOAD_MB} MB"



[[ -z "${PHP_SHORT_OPEN_TAG}" ]] || PHP_SHORT_OPEN_TAG="false"
if  [ "${PHP_SHORT_OPEN_TAG}" = "true" ]; then
  echo " init.php  | SETTING PHP_SHORT_OPEN_TAG:ON"
  find /etc/php/*/ -name php.ini |while read php_ini ;do
    sed 's/short_open_tag.\+//g' ${php_ini} -i
     echo "short_open_tag = on"  | tee -a "${php_ini}"
  done  | sed 's/$/|/g' |tr -d '\n'
else
  echo " init.php  | SETTING PHP_SHORT_OPEN_TAG:OFF"
  find /etc/php/*/ -name php.ini |while read php_ini ;do  
                                 grep '^short_open_tag = off' "${php_ini}"  ||  {   echo -n "${php_ini} : + " ;
                                                                                 ( echo;echo "short_open_tag = off " ) |tee -a  "${php_ini}" ; } ;done
fi

find /etc/php/*/ -name php.ini |while read php_ini ;do
              sed 's/include_path.\+//g' ${php_ini} -i
              (echo ;echo 'include_path = ./:/var/www/include_local:/var/www/include' )| tee -a "${php_ini}" |while read myline;do echo  "${php_ini} : ${myline}";done
done

) &




[[ -z "${PHP_ERROR_LEVEL}" ]] || PHP_ERROR_LEVEL="default"
if [ "${PHP_ERROR_LEVEL}" = "default" ]; then
    find /etc/php/*/ -name php.ini |while read php_ini ;do
                                      sed 's/^error_reporting.\+//g'; ${php_ini}
                                      echo 'error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT & ~E_NOTICE' | tee -a ${php_ini} >/dev/null
                                    done
else
    #[[ -z  "{$ERRR_LEVEL}" ]] && echo ""
    if [ "${PHP_ERROR_LEVEL}" = "verbose" ]; then
      sed 's/^error_reporting.\+//g'; ${php_ini}
      echo 'error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT & ~E_NOTICE' | tee -a ${php_ini} >/dev/null
    fi
fi


wait
