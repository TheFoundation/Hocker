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

## disabled functions for php-fpm by default:
system,exec,passthru,system,proc_open,popen,parse_ini_file,show_source,chroot,escapeshellcmd,escapeshellarg,shell_exec,proc_open,proc_get_status,ini_restore,ftp_connect,ftp_exec,ftp_get,ftp_login,ftp_nb_fput,ftp_put,ftp_raw

## configuration

### .env Variables

* MARIADB_REMOTE_ACCESS
* MAIL_ADMINISTRATOR
* MAX_UPLOAD_MB
* PHP_SESSION_STORAGE

* APP_TIMEZONE ( e.g. `Europe/Berlin` ) might be set
### APACHE:

*  mount a volume that contains `/etc/apache-extra-config-var-www/*.conf` that will bee applied in `<Directory> /var/www`

* letsencrypt cert dir for a domain goes to /etc/ssl/private_letsencrypt

  **Attention**: the files need to be directly in the folder e.g. /etc/ssl/private_letsencrypt/fullchain.pem

* a file in `/etc/rc.local` will run IN PARALLEL to startup with /bin/bash
* a file in `/etc/rc.local.foreground` will run IN FOREGROUND before startup with /bin/bash
  `NOTE:` it will  


## in-depth notes:
* php fpm socket under `/run/php/php-fpm.sock` is soft linked like this:

  `ln -s /run/php/php${PHPVersion}-fpm.sock /run/php/php-fpm.sock`
