#!/bin/bash
## open_basedir and chroot need a session store path if redis/sql is  not engaged

PHPLONGVersion=$(php --version|head -n1 |cut -d " " -f2);
PHPVersion=${PHPLONGVersion:0:3};

## php fixup

phpenmod redis &>>/dev/shm/init_phpmods &>/dev/null  || true
phpenmod memcached &>>/dev/shm/init_phpmods &>/dev/null || true

## sessions folder

test -d /var/www/.phpsessions || mkdir /var/www/.phpsessions
test -d /var/www/.phpsessions && chown www-data:www-data /var/www/.phpsessions
mkdir -p /run/php &>/dev/null

## if image builder missed it: softlink version-specific php fpm sock
test -f /run/php/php-fpm.sock || ln -s /run/php/php${PHPVersion}-fpm.sock /run/php/php-fpm.sock
#disable php_admin_values since apache does not start with fpm and php_admin_value


#ls -lh1 /etc/apache2/sites*/*conf
test -f /etc/apache2/sites-available/default-ssl.conf || cp /etc/apache2/sites-available.default/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf
test -f /etc/apache2/sites-available/000-default.conf || cp /etc/apache2/sites-available.default/000-default.conf /etc/apache2/sites-available/000-default.conf

#disable exec time for shell
find /etc/php/*/cli/ -name php.ini |while read php_cli_ini ;do sed 's/max_execution_time.\+/max_execution_time = 0 /g ' -i $php_cli_ini & done


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
    grep  grep '^php_admin_value\[error_log\] =' ${fpmpool} |tail -n1 |grep 'php_admin_value\[error_log\] = /dev/stderr' ${fpmpool} || { echo -n " init.php |  $fpmpool" echo 'php_admin_value\[error_log\] = /dev/stderr' | tee -a ${fpmpool} ; } ;
                                                  done

# may the app get data from extenal urls
[ "${DISALLOW_FOPEN}" = "true" ] && {
  grep  ^'php_admin_value.allow_url_fopen.'  /etc/php/$(php --version|head -n1|cut -d" " -f2|cut -d\. -f 1,2)/fpm/pool.d/www.conf |wc -l|grep -q 0$ || {
      (echo;echo "php_admin_value[allow_url_fopen] = 0") >> /etc/php/$(php --version|head -n1|cut -d" " -f2|cut -d\. -f 1,2)/fpm/pool.d/www.conf ; } ;

echo -n ; } ;


if [  -z "${MAX_UPLOAD_MB}" ]  && MAX_UPLOAD_MB=128
#raise upload limit for default 2M to 128M
echo " init.php | MAX_UPLOAD: ${MAX_UPLOAD_MB} MB"
if [  -z "${MAX_UPLOAD_MB}" ] ; then
    find /etc/php/*/ -name php.ini |while read php_ini ;do
                                           sed 's/upload_max_filesize.\+/upload_max_filesize = 128M /g;s/post_max_size.\+/post_max_size = 128M/g' -i ${php_ini} & done
else
    find /etc/php/*/ -name php.ini |while read php_ini ;do
                                           sed 's/upload_max_filesize.\+/upload_max_filesize = '${MAX_UPLOAD_MB}'M /g;s/post_max_size.\+/post_max_size = '${MAX_UPLOAD_MB}'M/g' -i ${php_ini} & done
fi
