#!/bin/bash
[[ -z $(pidof apache2 apache2ctl|wc -c|grep ^0 -q && kill -7 $(pidof apache2 apache2ctl 2>/dev/null); ) ]] || grep apache /proc/$(cat /var/run/apache2/apache2.pid)/cmdline -q || rm /var/run/apache2/apache2.pid;
apache2ctl -DFOREGROUND ;sleep 0.2
