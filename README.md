Hocker
=====
#### Happy Docker images

## Features
* restricted basedir (/var/www /tmp) for www-data user
* filters some default status monitors and favicon from log ( -e 'StatusCabot'-e '"cabot/' -e '"HEAD / HTTP/1.1" 200 - "-" "curl/' -e UptimeRobot/ -e "docker-health-check/over9000" -e "/favicon.ico" )
* runs apache,supervisord,mysql,redis etc. via **supervisor**
* creates /etc/msmtprc from env and fixes /etc/msmtp.aliases as well
* inserts FROM address with localhost as domain when cronjobs run
* installs php mail extension during startup
* detects php:artisan queue and websockets under /var/www/* , inserts them into **supervisor**

## configuration

### .env Variables

* MARIADB_REMOTE_ACCESS
* MAIL_ADMINISTRATOR
* 

* APP_TIMEZONE ( e.g. `Europe/Berlin` ) might be set

* letsencrypt cert dir for a domain goes to /etc/ssl/private_letsencrypt

  **Attention**: the files need to be directly in the folder e.g. /etc/ssl/private_letsencrypt/fullchain.pem

* a file in `/etc/rc.local` will run IN PARALLEL to startup with /bin/bash
* a file in `/etc/rc.local.foreground` will run IN FOREGROUND before startup with /bin/bash
  `NOTE:` it will  
