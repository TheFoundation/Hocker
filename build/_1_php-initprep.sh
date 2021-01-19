#!/bin/bash

echo "APACHE:"
#ls -lh1 /etc/apache2/sites*/*conf
test -f /etc/apache2/sites-available/default-ssl.conf || cp /etc/apache2/sites-available.default/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf
test -f /etc/apache2/sites-available/000-default.conf || cp /etc/apache2/sites-available.default/000-default.conf /etc/apache2/sites-available/000-default.conf

#disable exec time for shell
find /etc/php/*/cli/ -name php.ini |while read php_cli_ini ;do sed 's/max_execution_time.\+/max_execution_time = 0 /g ' -i $php_cli_ini & done

## since fpm is installed later , imagick might be missing
test -e /etc/php/$(php --version|head -n1|cut -d" " -f2|cut -d\. -f 1,2)/fpm/conf.d/20-imagick.ini || test -e /etc/php/$(php --version|head -n1|cut -d" " -f2|cut -d\. -f 1,2)/mods-available/20-imagick.ini  && ln -s /etc/php/$(php --version|head -n1|cut -d" " -f2|cut -d\. -f 1,2)/mods-available/imagick.ini /etc/php/$(php --version|head -n1|cut -d" " -f2|cut -d\. -f 1,2)/fpm/conf.d/20-imagick.ini 2>/dev/null

#raise upload limit for default 2M to 128M
echo "UPL:"
if [  -z "${MAX_UPLOAD_MB}" ] ; then
    find /etc/php/*/ -name php.ini |while read php_ini ;do
                                           sed 's/upload_max_filesize.\+/upload_max_filesize = 128M /g;s/post_max_size.\+/post_max_size = 128M/g' -i ${php_ini} & done
else
    find /etc/php/*/ -name php.ini |while read php_ini ;do
                                           sed 's/upload_max_filesize.\+/upload_max_filesize = '${MAX_UPLOAD_MB}'M /g;s/post_max_size.\+/post_max_size = '${MAX_UPLOAD_MB}'M/g' -i ${php_ini} & done
fi



echo "FPM:"
if [ "$(ls -1 /usr/sbin/php-fpm* 2>/dev/null|wc -l)" -eq 0 ];then
    echo "apache:mod-php  , no fpm executable"
    grep  "php_admin_value error_log" /etc/apache2/sites-available/000-default.conf || sed -i 's/AllowOverride All/AllowOverride All\nphp_admin_value error_log /dev/stderr/g' /etc/apache2/sites-available/000-default.conf
    grep  "php_admin_value error_log" /etc/apache2/sites-available/default-ssl.conf || sed -i 's/AllowOverride All/AllowOverride All\nphp_admin_value error_log /dev/stderr/g' /etc/apache2/sites-available/default-ssl.conf
    ln -sf /etc/php/$(php --version|head -n1|cut -d" " -f2|cut -d\. -f 1,2)/apache2/php.ini /var/www/php.ini


    else  ### FPM DETECTED
        PHPLONGVersion=$(php --version|head -n1 |cut -d " " -f2);
        PHPVersion=${PHPLONGVersion:0:3};
        ## open_basedir and chroot need a session store path if redis/sql is  not engaged
        test -d /var/www/.phpsessions || mkdir /var/www/.phpsessions
        test -d /var/www/.phpsessions && chown www-data:www-data /var/www/.phpsessions
        mkdir -p /run/php &>/dev/null

        ## if image builder missed it: softlink version-specific php fpm sock
        test -e /run/php/php-fpm.sock || ln -s /run/php/php${PHPVersion}-fpm.sock /run/php/php-fpm.sock
        #disable php_admin_values since apache does not start with fpm and php_admin_value

        sed 's/php_admin_value/#php_admin_value/g;s/php_value/#php_value/g' -i  /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-enabled/000-default.conf /etc/apache2/sites-enabled/default-ssl.conf
        #grep "^docroot"                           /etc/php/$(php --version|head -n1|cut -d" " -f2|cut -d\. -f 1,2)/fpm/pool.d/www.conf  ||  { (echo;echo "docroot = /var/www/html") >> /etc/php/$(php --version|head -n1|cut -d" " -f2|cut -d\. -f 1,2)/fpm/pool.d/www.conf
        grep "^php_admin_value\[open_basedir\] = "  /etc/php/$(php --version|head -n1|cut -d" " -f2|cut -d\. -f 1,2)/fpm/pool.d/www.conf  ||  { (echo;echo "php_admin_value[open_basedir] = /var/www/:/tmp/") >> /etc/php/$(php --version|head -n1|cut -d" " -f2|cut -d\. -f 1,2)/fpm/pool.d/www.conf ; }
        grep "^php_value\[session.save_path\] = /var/www/.phpsessions"  /etc/php/$(php --version|head -n1|cut -d" " -f2|cut -d\. -f 1,2)/fpm/pool.d/www.conf  ||  { (echo;echo "php_value[session.save_path] = /var/www/.phpsessions") >> /etc/php/$(php --version|head -n1|cut -d" " -f2|cut -d\. -f 1,2)/fpm/pool.d/www.conf ; } ;

        find /etc/php/*/fpm/ -name www.conf |while read fpmpool;do grep "^php_admin_flag\\[log_errors\\] = on" $fpmpool -q || echo "php_admin_flag[log_errors] = on" |tee -a $fpmpool;done
        # FORCE php_admin_value[error_log] = /dev/stderr

        find /etc/php/*/fpm/ -name www.conf |while read fpmpool;do grep "^php_admin_value\\[error_log\\] = /dev/stderr" $fpmpool  || echo "php_admin_value[error_log] = /dev/stderr" |tee -a $fpmpool;done

        # may the app get data from extenal urls
        [ "${DISALLOW_FOPEN}" = "true" ] && {
    		grep  ^'php_admin_value.allow_url_fopen.'  /etc/php/$(php --version|head -n1|cut -d" " -f2|cut -d\. -f 1,2)/fpm/pool.d/www.conf |wc -l|grep -q 0$ || { (echo;echo "php_admin_value[allow_url_fopen] = 0") >> /etc/php/$(php --version|head -n1|cut -d" " -f2|cut -d\. -f 1,2)/fpm/pool.d/www.conf ; } ;

    	echo -n ; } ;
