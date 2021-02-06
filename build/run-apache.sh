#!/bin/bash


[[ -z $(pidof apache2 apache2ctl)  ]] || { kill $(pidof apache2 apache2ctl) ; } ;
sleep 1;
grep apache /proc/$(cat /var/run/apache2/apache2.pid 2>/dev/null)/cmdline 2>/dev/null -q || rm /var/run/apache2/apache2.pid 2>/dev/null;
echo apache:starting
#apache2ctl -DFOREGROUND  2>/dev/stderr | filter_web_log >/dev/stdout;sleep 0.2

/usr/bin/stdbuf  -oL apache2ctl -DFOREGROUND ## apache fifo logging needs the following entry: ____Log "|/usr/bin/logformatter arg1 arge2 >> /dev/null/some/where"
