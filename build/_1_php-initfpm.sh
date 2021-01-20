#!/bin/bash

PHPLONGVersion=$(php --version|head -n1 |cut -d " " -f2);
PHPVersion=${PHPLONGVersion:0:3};

##Fix potentially missing .ini files in /etc/php/X.Y/fpm due to delayed installation of FPM in dockerfiles
find /etc/php/$(php --version|head -n1|cut -d" " -f2|cut -d\. -f 1,2)/ -name "*.ini"|grep -v /fpm/|grep -v php.ini|grep -v mods-available |while read file;do
    test -e /etc/php/$(php --version|head -n1|cut -d" " -f2|cut -d\. -f 1,2)/fpm/conf.d/$(basename $file) || cp $file /etc/php/$(php --version|head -n1|cut -d" " -f2|cut -d\. -f 1,2)/fpm/conf.d/$(basename $file) ;
done

## check disablef funtions
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

  #if entered directly...
  echo "$PHP_FORBIDDEN_FUNCTIONS" |grep -q  "," && FORBIDDEN_FUNCTIONS_SELECTED=${PHP_FORBIDDEN_FUNCTIONS}
  [[ -z "$FORBIDDEN_FUNCTIONS_SELECTED" ]] &&  [[ "NONE" =  "${PHP_FORBIDDEN_FUNCTIONS}" ]] ||  echo "ERROR: set PHP_FORBIDDEN_FUNCTIONS to 'NONE' if you want to dangerously enable everything , it is currently: "${PHP_FORBIDDEN_FUNCTIONS}
  [[ -z "$PHP_FORBIDDEN_FUNCTIONS"  ]]     &&  [[ "NONE" =  "${PHP_FORBIDDEN_FUNCTIONS}" ]] ||  FORBIDDEN_FUNCTIONS_SELECTED=${FORBIDDEN_FUNCTIONS_DEFAULTS}
  fpmfile=/etc/php/${PHPVersion}/fpm/pool.d/www.conf
  grep " ${FORBIDDEN_FUNCTIONS_SELECTED}" "${fpmfile}" && { echo " sys.info  | PHP_FPM OK     php_forbidden_functions_default found in" "${fpmfile}"  ; } ;
  grep " ${FORBIDDEN_FUNCTIONS_SELECTED}" "${fpmfile}" || { echo " sys.info  | PHP_FPM FALLBACK php_forbidden_functions enforced ${fpmfile}  TO= ${FORBIDDEN_FUNCTIONS_SELECTED}" ;
                                                          ##remove others
                                                          sed 's/.\+php_admin_value.disable_functions.\+//g' "${fpmfile}" -i
                                                          ##write
                                                          (echo;echo "php_admin_value[disable_functions] = "${FORBIDDEN_FUNCTIONS_SELECTED}) >> ${fpmfile}
                                                        echo -n ; } ;
  echo " sys.info  | PHP_DISABLE_FUNCTIONS:" $(grep )
echo -n "=fpm" ; } ;


    echo " sys.info  | PHP_FPM::SESSIONS:"
    (
    ### DEFAULT SESSION STORAGE IS MEMCACHED if FOUND


        ##php sess redis

        setup_memcached=no

        ## set auto localhost if executable found
        [[ -z "${PHP_SESSION_MEMCACHED_HOST}" ]]  && which memcached &>/dev/null && echo " sys.info  | USING DEFAULT REDIS LOCALHOST: 127.0.0.1:11211"
        [[ -z "${PHP_SESSION_MEMCACHED_HOST}" ]]  && which memcached &>/dev/null && PHP_SESSION_MEMCACHED_HOST=127.0.0.1:11211
        [[ -z "${PHP_SESSION_STORAGE}" ]]         && which memcached &>/dev/null && setup_memcached=yes
        #  set up memcached if forced by env ( will fall back when PHP_SESSION_MEMCACHED_HOST empty )
        [[    "${PHP_SESSION_STORAGE}" = "memcached" ]] && setup_memcached=yes

        [[ -z "${PHP_SESSION_MEMCACHED_HOST}" ]]  && [[ "yes" = "${setup_memcached}" ]]   && echo " sys.err  | SOFTFAIL:NO MEMCACHED HOST SET but detected .. DEGRADED" >&2
        [[ -z "${PHP_SESSION_MEMCACHED_HOST}" ]]  && [[ "yes" = "${setup_memcached}" ]]   && setup_memcached=no

        [[ "yes" = "${setup_memcached}" ]]  && PHP_SESSION_STORAGE=memcached # so the following tests will not get it empty
        [[ "yes" = "${setup_memcached}" ]]  && echo " sys.info  | SETTING UP PHP_SESSION_STORAGE ${PHP_SESSION_STORAGE} WITH ${PHP_SESSION_MEMCACHED_HOST}" >&2

        [[ "yes" = "${setup_memcached}" ]] && {
            for phpconf in $(find $(find /etc/ -maxdepth 1 -name "php*") -name php.ini |grep -e apache -e fpm);do
              ##remove entries
                sed 's/.\+session.save_\(handler\|path\).\+//g' ${phpconf} -i
                ( echo '[Session]';echo "session.save_handler = memcached" ; echo 'session.save_path = "'${PHP_SESSION_MEMCACHED_HOST}'"' ) > ${phpconf} ;
            done
         echo ; } ;

        ##php sess redis
        setup_redis=no
        #  set up redis if forced by env ( will fall back when PHP_SESSION_REDIS_HOST empty )
        [[    "${PHP_SESSION_STORAGE}" = "redis" ]] && setup_redis=yes
        [[ -z "${PHP_SESSION_REDIS_HOST}"        ]]  && [[ "yes" = "${setup_redis}" ]]   && echo " sys.err  | SOFTFAIL:NO REDIS HOST SET but detected .. DEGRADED" >&2

        ## add php session hander redis for PHP 5
        #&& { php --version 2>&1 | head -n1 |grep -q "^PHP 5" ; }

        [[ "yes" = "${setup_redis}"              ]]  && {
          echo "setting up redis sessionstorage";
          [[ -z "PHP_SESSION_REDIS_HOST" ]] && echo " sys.info  | USING DEFAULT REDIS LOCALHOST "
          [[ -z "PHP_SESSION_REDIS_HOST" ]] && PHP_SESSION_REDIS_HOST=tcp://127.0.0.1:6379

          [[ "yes" = "${setup_redis}"              ]]  && PHP_SESSION_STORAGE=redis # so the following tests will not get it empty
          [[ "yes" = "${setup_redis}"              ]]  && echo " sys.info | SETTING UP PHP_SESSION_STORAGE ${PHP_SESSION_STORAGE} WITH ${PHP_SESSION_MEMCACHED_HOST}" >&2

          for phpconf in $(find $(find /etc/ -maxdepth 1 -name "php*") -name php.ini |grep -e apache -e fpm);do
            sed 's/.\+session.save_\(handler\|path\).\+//g' ${phpconf} -i
            ( echo '[Session]';echo "session.save_handler = redis" ; echo 'session.save_path = "'${PHP_SESSION_REDIS_HOST}'"' ) > ${phpconf} ;
          done
        #end setup redis
        echo -n ; } ;


        [[ "${PHP_SESSION_STORAGE}" = "files" ]] && {
          echo " sys.info  | forcing session save path to /var/www/.phpsessions"
          for phpconf in $(find $(find /etc/ -maxdepth 1 -name "php*") -name php.ini |grep -e apache -e fpm);do
              sed 's/.\+session.save_\(handler\|path\).\+//g' ${phpconf} -i
              echo "session.save_handler = files" ; echo 'session.save_path = "/var/www/.phpsessions'
            done
          echo -n; } ;

         #which memcached &> /dev/null || which redis &>/dev/null

        echo " sys.info  | PHP_FPM::SESSIONS:RESULT:"$(grep -i ^session $(find $(find /etc/ -maxdepth 1 -name "php*") -name php.ini |grep -e apache -e fpm) )


    ) &
