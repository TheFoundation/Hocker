#!/bin/bash
##fixing legacy composer version from ubuntu / debian  
cd /tmp/
    EXPECTED_SIGNATURE="$(wget -q -O - https://composer.github.io/installer.sig)"
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    ACTUAL_SIGNATURE="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

    if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]
    then
        >&2 echo 'ERROR: Invalid installer signature'   ; rm composer-setup.php   ; ##exit 1
    fi

    php composer-setup.php --quiet
    RESULT=$?
    rm composer-setup.php

    test -f composer.phar || (echo "NO COMPOSER DOWNLOADED" > /dev/stderr)
    test -f composer.phar && (
        newest=$( (./composer.phar --version 2>/dev/null;composer --version 2>/dev/null)|sed 's/Composer version/Composer/g'|cut -d" " -f2-3|sed 's/ /-/g'|sort -n |tail -n1)
        upgrade=$(./composer.phar --version 2>/dev/null |sed 's/Composer version/Composer/g'|cut -d" " -f2-3|sed 's/ /-/g' )
        sysver=$(composer --version 2>/dev/null |sed 's/Composer version/Composer/g'|cut -d" " -f2-3|sed 's/ /-/g' )
        if [ "$sysver" != "$newest" ] ;then
            echo UPGRADING COMPOSER ;which composer >/dev/null && ( mv composer.phar $(which composer) ) || ( mv composer.phar /usr/bin/composer)  ;fi
        test -f /tmp/composer.phar && rm /tmp/composer.phar 
    ) | tr -d '\n' &
    

