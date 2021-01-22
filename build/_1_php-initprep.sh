#!/bin/bash

echo " init.php | PHP APACHE/NGINX:"





PHPLONGVersion=$(php --version|head -n1 |cut -d " " -f2);
PHPVersion=${PHPLONGVersion:0:3};

## since fpm is installed later , imagick might be missing
test -e /etc/php/${PHPVersion}/fpm/conf.d/20-imagick.ini || test -e /etc/php/$(php --version|head -n1|cut -d" " -f2|cut -d\. -f 1,2)/mods-available/20-imagick.ini  && ln -s /etc/php/$(php --version|head -n1|cut -d" " -f2|cut -d\. -f 1,2)/mods-available/imagick.ini /etc/php/$(php --version|head -n1|cut -d" " -f2|cut -d\. -f 1,2)/fpm/conf.d/20-imagick.ini 2>/dev/null

##pecl/manual installation might have messed up the .ini softlinks ( having imagick.ini and 20-imagick.ini )
for dir in apache2 fpm cli;do
  test -e /etc/php/${PHPVersion}/${dir}/conf.d/20-imagick.ini && test -e /etc/php/${PHPVersion}/${dir}/conf.d/imagick.ini && rm /etc/php/${PHPVersion}/${dir}/conf.d/imagick.ini
done


bash /_1_php-initfirst.sh

if [ "$(( which php${PHPVersion}-bin ;ls -1 /usr/sbin/php-fpm* 2>/dev/null)|wc -l)" -eq 0 ];then
  echo " init.php | apache:mod-php  , no fpm executable"
    test -f /etc/apache2/sites-available/000-default.conf && grep  "php_admin_value error_log" /etc/apache2/sites-available/000-default.conf || sed -i 's/AllowOverride All/AllowOverride All\nphp_admin_value error_log /dev/stderr/g' /etc/apache2/sites-available/000-default.conf
    test -f /etc/apache2/sites-available/default-ssl.conf && grep  "php_admin_value error_log" /etc/apache2/sites-available/default-ssl.conf || sed -i 's/AllowOverride All/AllowOverride All\nphp_admin_value error_log /dev/stderr/g' /etc/apache2/sites-available/default-ssl.conf
    ln -sf /etc/php/$(php --version|head -n1|cut -d" " -f2|cut -d\. -f 1,2)/apache2/php.ini /var/www/php.ini


else  ### FPM DETECTED
  echo -n " init.php | FPM:"
  ## config fpm
  echo "apache:php-fpm or nginx fpm";
  bash /_1_php-initfpm.sh



## idle timeout was often not set
sed 's/sock -pass-header Authorization/sock -idle-timeout 600 -pass-header Authorization/g' /etc/apache2/sites-enabled/default-ssl.conf -i
grep  "sock -idle-timeout 600 -pass-header Authorization" /etc/apache2/sites-enabled/default-ssl.conf -q  || (
                    echo "fpm config init" ;
                    sed 's/<VirtualHost.\+/\0\n\t\tAddType application\/x-httpd-php    .php .php7 # .phtml #.htm .html # .php5 #.php4\n\t\tAction application\/x-httpd-php \/php-fcgi\n\t\tAction php-fcgi \/php-fcgi\n\t\t\n\t\tFastCgiExternalServer \/usr\/lib\/cgi-bin\/php-fcgi -socket \/var\/run\/php\/php-fpm.sock -idle-timeout 600 -pass-header Authorization\n\t\tAlias \/php-fcgi \/usr\/lib\/cgi-bin\/php-fcgi\n\t\tSetEnv PHP_VALUE "max_execution_time = 600"\n\t\tSetEnv PHP_VALUE "include_path = .\/:\/var\/www\/include_local:\/var\/www\/include"\n\n\t\t<Directory \/usr\/lib\/cgi-bin>\nRequire all granted\n<\/Directory>\n/g'   /etc/apache2/sites-enabled/default-ssl.conf -i
                                ## enable fpm error login
                                #;catch_workers_output = yes
                                #FORCE php_admin_flag[log_errors] = on

     ## link php.ini
     ln -sf /etc/php/$(php --version|head -n1|cut -d" " -f2|cut -d\. -f 1,2)/fpm/php.ini /var/www/php.ini
     )

    fi





wait $waittime


echo "FPM INIT:DONE"
exit 0
