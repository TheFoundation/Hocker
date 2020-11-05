#!/bin/bash
echo "PREP:USER"



###CRON
grep -q crontabs /etc/group && adduser www-data crontabs 2>/dev/null

test -e /var/spool/cron/crontabs/ || mkdir -p /var/spool/cron/crontabs/
test -e /var/spool/cron/crontabs/www-data || ( touch /var/spool/cron/crontabs/www-data ;chown www-data /var/spool/cron/crontabs/www-data ; chgrp crontabs /var/spool/cron/crontabs/www-data)



########### WEBROOT / DROPBEAR / PERMISSION HUSSLE
test -d /var/www/.ssh || ( mkdir /var/www/.ssh ;chown www-data:www-data /var/www/.ssh;touch /var/www/.ssh/authorized_keys;chmod 0600 /var/www/.ssh/authorized_keys /var/www/.ssh )
test -f /var/www/.ssh/authorized_keys && chown www-data:www-data /var/www/.ssh/authorized_keys
test -f /var/www/.ssh/authorized_keys && ( chmod 600 /var/www/.ssh/authorized_keys ;chmod ugo-w /var/www/.ssh/authorized_keys)
test -d /var/www/.ssh && (chown www-data:www-data /var/www/.ssh ;chmod u+x /var/www/.ssh) &
test -d /root/.ssh || ( mkdir /root/.ssh;touch /root/.ssh/authorized_keys ; chmod 0600 /root/.ssh /root/.ssh/authorized_keys ) &

## USER DIR PREPARATION #######
## ssh reads .bash_profile and misses path from standard config
test -f /var/www/.bashrc ||  cp /root/.bashrc /var/www/
test -e /var/www/.bash_profile || ( ln -s /var/www/.bashrc /var/www/.bash_profile )
grep -q PATH /var/www/.bashrc || ( echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" >> /var/www/.bashrc ) &

test -d /var/www/html || ( mkdir /var/www/html;chown www-data:www-data /var/www/ /var/www/html) && (chown www-data:www-data /var/www/ /var/www/html) &
########################################################################################################


###enable ssh for www-data , put keys in /var/www/.ssh/authorized keys , deploy keys also under /var/www/.ssh/id-rsa{.pub}
if [ "$ENABLE_WWW_SHELL" = "true"  ]; then
    usermod -s /bin/bash www-data
else
    usermod -s /usr/lib/sftp-server www-data
fi


## end subshell spawn
