#!/bin/bash
filter_web_log() { grep --line-buffered -v -e 'StatusCabot' -e '"cabot/' -e '"HEAD / HTTP/1.1" 200 - "-" "curl/' -e "UptimeRobot/" -e "docker-health-check/over9000" -e "/favicon.ico" ; } ;

[[ -z $(pidof apache2 apache2ctl)  ]] || { kill $(pidof apache2 apache2ctl) ; } ;
grep apache /proc/$(cat /var/run/apache2/apache2.pid)/cmdline -q || rm /var/run/apache2/apache2.pid;
apache2ctl -DFOREGROUND  2>/dev/stderr | filter_web_log >/dev/stdout;sleep 0.2
