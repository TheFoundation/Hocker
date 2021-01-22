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
which a2enmod  2>/dev/null && a2enmod  headers &>/dev/null &
which a2ensite 2>/dev/null && a2ensite 000-default &>/dev/null &
which a2ensite 2>/dev/null && a2ensite default-ssl &>/dev/null &
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
#echo "APA:PRECONF:"
## SPAWN APACHE PRRECONFIG
which apache2ctl && (

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
    sed  's/ErrorLog.\+/ErrorLog   /dev/stderr /g'                                                    -i /etc/apache2/sites-enabled/*.conf  ;
    #sed  's/ErrorLog.\+\.log/ErrorLog   "| \/bin\/bash \/_3_logfilter_apache.sh >> \/dev\/stderr"/g'  -i /etc/apache2/sites-enabled/*.conf  ;
    if [ -z "${MAIL_ADMINISTRATOR}" ];
      then echo "::MAIL_ADMINISTRATOR not set FIX THIS !(apache ServerAdmin)"
    else
      sed 's/ServerAdmin webmaster@localhost/ServerAdmin '${MAIL_ADMINISTRATOR}'/g' -i /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/default-ssl.conf
    fi &
    ) &


(
## fpm and apache fastcgi dislike php_value and php_admin_value in apache config
sed 's/php_admin_value/#php_admin_value/g;s/php_value/#php_value/g' -i  /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-enabled/000-default.conf /etc/apache2/sites-enabled/default-ssl.conf
#grep "^docroot"                           /etc/php/$(php --version|head -n1|cut -d" " -f2|cut -d\. -f 1,2)/fpm/pool.d/www.conf  ||  { (echo;echo "docroot = /var/www/html") >> /etc/php/$(php --version|head -n1|cut -d" " -f2|cut -d\. -f 1,2)/fpm/pool.d/www.conf
grep "^php_admin_value\[open_basedir\] = "  /etc/php/$(php --version|head -n1|cut -d" " -f2|cut -d\. -f 1,2)/fpm/pool.d/www.conf  ||  { (echo;echo "php_admin_value[open_basedir] = /var/www/:/tmp/") >> /etc/php/$(php --version|head -n1|cut -d" " -f2|cut -d\. -f 1,2)/fpm/pool.d/www.conf ; }
grep "^php_value\[session.save_path\] = /var/www/.phpsessions"  /etc/php/$(php --version|head -n1|cut -d" " -f2|cut -d\. -f 1,2)/fpm/pool.d/www.conf  ||  { (echo;echo "php_value[session.save_path] = /var/www/.phpsessions") >> /etc/php/$(php --version|head -n1|cut -d" " -f2|cut -d\. -f 1,2)/fpm/pool.d/www.conf ; } ;

find /etc/php/*/fpm/ -name www.conf |while read fpmpool;do
  grep "^php_admin_flag\\[log_errors\\] = on" ${fpmpool} -q || echo "php_admin_flag[log_errors] = on" |tee -a ${fpmpool};
                                                  done
# FORCE php_admin_value[error_log] = /dev/stderr

find /etc/php/*/fpm/ -name www.conf |while read fpmpool;do
    grep '^php_admin_value\[error_log\] = /dev/stderr' ${fpmpool} |tail -n1 |grep 'php_admin_value\[error_log\] = /dev/stderr' ${fpmpool} || { echo -n " init.php |  $fpmpool" echo 'php_admin_value\[error_log\] = /dev/stderr' | tee -a ${fpmpool} ; } ;
                                                  done

# may the app get data from extenal urls
[ "${DISALLOW_FOPEN}" = "true" ] && {
  grep  ^'php_admin_value.allow_url_fopen.'  /etc/php/$(php --version|head -n1|cut -d" " -f2|cut -d\. -f 1,2)/fpm/pool.d/www.conf |wc -l|grep -q 0$ || {
      (echo;echo "php_admin_value[allow_url_fopen] = 0") >> /etc/php/$(php --version|head -n1|cut -d" " -f2|cut -d\. -f 1,2)/fpm/pool.d/www.conf ; } ;

echo -n ; } ;
) &

(
[  -z "${MAX_UPLOAD_MB}" ]  && MAX_UPLOAD_MB=128
#raise upload limit for default 2M to 128M
if [  -z "${MAX_UPLOAD_MB}" ] ; then
    find /etc/php/*/ -name php.ini |while read php_ini ;do
                                           sed 's/upload_max_filesize.\+/upload_max_filesize = 128M /g;s/post_max_size.\+/post_max_size = 128M/g' -i ${php_ini} &
                                         done
else
    find /etc/php/*/ -name php.ini |while read php_ini ;do
                                           sed 's/upload_max_filesize.\+/upload_max_filesize = '${MAX_UPLOAD_MB}'M /g;s/post_max_size.\+/post_max_size = '${MAX_UPLOAD_MB}'M/g' -i ${php_ini} &
                                         done
fi ; echo " init.php  | MAX_UPLOAD: ${MAX_UPLOAD_MB} MB" ) &

if [ "{$ERRR_LEVEL}" = "default" ]; then
find /etc/php/*/ -name php.ini |while read php_ini ;do
                                      sed 's/^error_reporting.\+//g'; ${php_ini}
                                      echo 'error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT & ~E_NOTICE' | tee -a ${php_ini} >/dev/null
                                done
else
    #[[ -z  "{$ERRR_LEVEL}" ]] && echo ""
    if [ "{$ERRR_LEVEL}" = "verbose" ]; then
      sed 's/^error_reporting.\+//g'; ${php_ini}
      echo 'error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT & ~E_NOTICE' | tee -a ${php_ini} >/dev/null
    done
fi


wait
