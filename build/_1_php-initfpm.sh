#!/bin/bash 

PHPLONGVersion=$(php --version|head -n1 |cut -d " " -f2);
PHPVersion=${PHPLONGVersion:0:3};




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
        [[ "yes" = "${setup_memcached}" ]]  && echo " sys.info | SETTING UP PHP_SESSION_STORAGE ${PHP_SESSION_STORAGE} WITH ${PHP_SESSION_MEMCACHED_HOST}" >&2

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
