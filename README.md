Hocker
=====
#### Happy Docker scripts and tricks


## Features
* filters some default status monitors and favicon from log ( -e 'StatusCabot'-e '"cabot/' -e '"HEAD / HTTP/1.1" 200 - "-" "curl/' -e UptimeRobot/ -e "docker-health-check/over9000" -e "/favicon.ico" )
* runs apache,supervisord,mysql,redis etc. via **supervisor**
* creates /etc/msmtprc from env and fixes /etc/msmtp.aliases as well
* inserts FROM address with localhost as domain when cronjobs run
* installs php mail extension during startup

## configuration

* a file in `/etc/rc.local` will run IN PARALLEL to startup with /bin/bash
* a file in `/etc/rc.local.foreground` will run IN FOREGROUND before startup with /bin/bash
  `NOTE:` it will  
