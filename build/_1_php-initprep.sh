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


      grep ^'php_admin_value\[disable_functions\]'  /etc/php/$(php --version|head -n1|cut -d" " -f2|cut -d\. -f 1,2)/fpm/pool.d/www.conf  ||  {

        ## typo3 needs exec     sometimes _> /var/www/typo3_src/
        ## laravel needs pcntl_async_signals with redis/horizon
        #exec,passthru,shell_exec,system,proc_open,popen,curl_exec,curl_multi_exec,parse_ini_file,show_source
        #e.g. php_admin_value[disable_functions] = apache_child_terminate,apache_setenv
        FORBIDDEN_FUNCTIONS_ALL="apache_child_terminate,apache_setenv,define_syslog_variables,escapeshellarg,escapeshellcmd,eval,exec,fp,fput,ftp_connect,ftp_exec,ftp_get,ftp_login,ftp_nb_fput,ftp_put,ftp_raw,ftp_rawlist,highlight_file,ini_alter,ini_get_all,ini_restore,inject_code,mysql_pconnect,openlog,passthru,pcntl_alarm,pcntl_exec,pcntl_fork,pcntl_get_last_error,pcntl_getpriority,pcntl_setpriority,pcntl_signal,pcntl_signal_dispatch,pcntl_sigprocmask,pcntl_sigtimedwait,pcntl_sigwaitinfo,pcntl_strerror,pcntl_wait,pcntl_waitpid,pcntl_wexitstatus,pcntl_wifcontinued,pcntl_wifexited,pcntl_wifsignaled,pcntl_wifstopped,pcntl_wstopsig,pcntl_wtermsig,phpAds_XmlRpc,phpAds_remoteInfo,phpAds_xmlrpcDecode,phpAds_xmlrpcEncode,popen,posix_getpwuid,posix_kill,posix_mkfifo,posix_setpgid,posix_setsid,posix_setuid,posix_uname,proc_close,proc_get_status,proc_nice,proc_open,proc_terminate,shell_exec,syslog,system,xmlrpc_entity_decode"
        FORBIDDEN_FUNCTIONS_HARDENED="exec,passthru,shell_exec,system,proc_open,popen,parse_ini_file,show_source,chroot,escapeshellcmd,escapeshellarg,shell_exec,proc_open,proc_get_status,ini_restore,ftp_connect,ftp_exec,ftp_get,ftp_login,ftp_nb_fput,ftp_put,ftp_raw"
        FORBIDDEN_FUNCTIONS_DEFAULTS="system,passthru,shell_exec,chrootpopen,parse_ini_file,show_source,chroot,shell_exec,ini_restore,apache_child_terminate,apache_setenv,ftp_connect,ftp_exec,ftp_get,ftp_login,ftp_nb_fput,ftp_put,ftp_raw"
        FORBIDDEN_FUNCTIONS_SELECTED=""
        [[ "$PHP_FORBIDDEN_FUNCTIONS" = "NONE" ]] &&  FORBIDDEN_FUNCTIONS_SELECTED=""
        [[ "$PHP_FORBIDDEN_FUNCTIONS" = "HARDENED" ]] &&  FORBIDDEN_FUNCTIONS_SELECTED="${FORBIDDEN_FUNCTIONS_HARDENED}"
        [[ "$PHP_FORBIDDEN_FUNCTIONS" = "ALL" ]] &&  FORBIDDEN_FUNCTIONS_SELECTED="${FORBIDDEN_FUNCTIONS_ALL}"
        [[ -z "$PHP_FORBIDDEN_FUNCTIONS"  ]] &&  FORBIDDEN_FUNCTIONS_SELECTED=${FORBIDDEN_FUNCTIONS_DEFAULTS}

        #if entered directly...
        echo "$PHP_FORBIDDEN_FUNCTIONS" |grep "," && FORBIDDEN_FUNCTIONS_SELECTED=${PHP_FORBIDDEN_FUNCTIONS}
        [[ -z "$FORBIDDEN_FUNCTIONS_SELECTED" ]] &&  [[ "NONE" =  "${PHP_FORBIDDEN_FUNCTIONS}" ]] &&  && echo "ERROR: set PHP_FORBIDDEN_FUNCTIONS to 'NONE' if you want to dangerously enable everything , it is currently: ${PHP_FORBIDDEN_FUNCTIONS}"
        fpmfile=/etc/php/$(php --version|head -n1|cut -d" " -f2|cut -d\. -f 1,2)/fpm/pool.d/www.conf
        grep " ${FORBIDDEN_FUNCTIONS_DEFAULTS}"$ "${fpmfile}" && { echo "OK     php_forbidden_functions_default found in" "${fpmfile}"  ; } ;
        grep " ${FORBIDDEN_FUNCTIONS_DEFAULTS}"$ "${fpmfile}" || { echo "NOT OK php_forbidden_functions enforced "${fpmfile}"  TO= ${FORBIDDEN_FUNCTIONS_DEFAULTS}" ;
                                                                ##remove others
                                                                  sed 's/.\+php_admin_value.disable_functions.\+//g' "${fpmfile}" -i
                                                                ##write
                                                                (echo;echo "php_admin_value[disable_functions] = "${FORBIDDEN_FUNCTIONS_DEFAULTS}) >> ${fpmfile}
                                                              echo -n ; } ;
        echo " sys.info  | PHP_DISABLE_FUNCTIONS:" $(grep )
  echo -n "=fpm"; } ;


      ## config fpm
          echo "apache:php-fpm or nginx fpm";


          ## idle timeout was often not set
          sed 's/sock -pass-header Authorization/sock -idle-timeout 600 -pass-header Authorization/g' /etc/apache2/sites-enabled/default-ssl.conf -i
          grep  "sock -idle-timeout 600 -pass-header Authorization" /etc/apache2/sites-enabled/default-ssl.conf -q  || (
                              echo "fpm config init" ;
                              sed 's/<VirtualHost.\+/\0\n\t\tAddType application\/x-httpd-php    .php .php7 # .phtml #.htm .html # .php5 #.php4\n\t\tAction application\/x-httpd-php \/php-fcgi\n\t\tAction php-fcgi \/php-fcgi\n\t\t\n\t\tFastCgiExternalServer \/usr\/lib\/cgi-bin\/php-fcgi -socket \/var\/run\/php\/php-fpm.sock -idle-timeout 600 -pass-header Authorization\n\t\tAlias \/php-fcgi \/usr\/lib\/cgi-bin\/php-fcgi\n\t\tSetEnv PHP_VALUE "max_execution_time = 600"\n\t\tSetEnv PHP_VALUE "include_path = .\/:\/var\/www\/include_local:\/var\/www\/include"\n\n\t\t<Directory \/usr\/lib\/cgi-bin>\nRequire all granted\n<\/Directory>\n/g'   /etc/apache2/sites-enabled/default-ssl.conf -i
                                ## enable fpm error login
                                #;catch_workers_output = yes
                                #FORCE php_admin_flag[log_errors] = on

                                ##Fix potentially missing .ini files in /etc/php/X.Y/fpm due to delayed installation of FPM in dockerfiles
                                find /etc/php/$(php --version|head -n1|cut -d" " -f2|cut -d\. -f 1,2)/ -name "*.ini"|grep -v /fpm/|grep -v php.ini|grep -v mods-available |while read file;do
                                    test -e /etc/php/$(php --version|head -n1|cut -d" " -f2|cut -d\. -f 1,2)/fpm/conf.d/$(basename $file) || cp $file /etc/php/$(php --version|head -n1|cut -d" " -f2|cut -d\. -f 1,2)/fpm/conf.d/$(basename $file) ;
                                done
                                ## link php.ini
                                ln -sf /etc/php/$(php --version|head -n1|cut -d" " -f2|cut -d\. -f 1,2)/fpm/php.ini /var/www/php.ini
                                )

     fi
