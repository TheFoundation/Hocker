#!/bin/bash
filter_web_log() { grep --line-buffered -v -e 'StatusCabot' -e '"cabot/' -e '"HEAD / HTTP/1.1" 200 - "-" "curl/' -e "UptimeRobot/" -e "docker-health-check/over9000" -e "/favicon.ico" ; } ;

[[ -z $(pidof apache2 apache2ctl)  ]] || { kill $(pidof apache2 apache2ctl) ; } ;
grep apache /proc/$(cat /var/run/apache2/apache2.pid)/cmdline 2>/dev/null -q || rm /var/run/apache2/apache2.pid;
echo apache:starting
#apache2ctl -DFOREGROUND  2>/dev/stderr | filter_web_log >/dev/stdout;sleep 0.2
apache2ctl -DFOREGROUND |while read thing;do echo "$thing"  | filter_web_log ;done
