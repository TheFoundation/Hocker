#!/bin/bash

echo "ENV APT values: ( scrambled)"

env|grep APT|sed 's/[0-9]\+\.//g;s/[0-9]\+\://g'

if [ "${APP_AUTOAPTPROXY}" = "true" ]; then export ENV=debug;echo "auto-apt-proxy ENABLED AT BUILD";else echo "NO APT PROXY (set APP_AUTOAPTPROXY=true in .env to activate)"; fi
if [ "${APP_AUTOAPTPROXY}" = "true" ]; then apt-get update && apt-getinstall auto-apt-proxy apt-get autoremove -y --force-yes &&  /bin/bash /i.sh qclean  ;fi

if [ "x$APT_HTTP_PROXY_URL" = "x" ] ; then
    echo Argument not provided ;
else
    echo using APT_HTTP_PROXY_URL ;
    ( echo 'Acquire::http::Proxy "'${APT_HTTP_PROXY_URL}'/";' ;echo 'PassThroughPattern: ^(.*):443$;';)| tee /etc/apt/apt.conf.d/10-proxy |sed 's/[0-9]\+\.//g;s/[0-9]\+\://g'   ;
fi
