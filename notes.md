
 #NOTE: specific maria versions
 #RUN if [ "${INSTALL_MARIADB}" = "true"   ]; then apt-get update  && apt-get install -y  --no-install-recommends  dirmngr software-properties-common || true  &&   curl -sL "http://keyserver.ubuntu.com/pks/lookup?op=get&search=0xF1656F24C74CD1D8" | apt-key add && LC_ALL=C.UTF-8 add-apt-repository 'deb [arch=amd64,arm64,ppc64el] http://mirrors.n-ix.net/mariadb/repo/10.3/ubuntu bionic main' && apt-get update && export DEBIAN_FRONTEND=noninteractive &&  apt-get -y install --no-install-recommends mariadb-server mariadb-client &&  /bin/bash /i.sh fullclean  ;else echo "NOT INSTALLING MYSQL(mariadb), set INSTALL_MARIADB=true in .env to install ";echo VALUE IS ;echo "${INSTALL_MARIADB}"; fi && \

 ###libapache2-mod-php5.6  ##php5.6-mcrypt \#      php5.6-apcu php5.6-opcache php5.6-xdebug \#      php5.6-mysql php5.6-pgsql php5.6-sqlite3 \#      php5.6-xml php5.6-xsl \#      php5.6-zip php5.6-soap php5.6-opcache php5.6-curl php5.6-bcmath php5.6-mbstring php5.6-json \#      php5.6-gd \#      php5.6-imagick \#      php5.6-ldap php5.6-imap \


 Header set Content-Security-Policy "form-action 'self'; script-src 'self' https://js.pusher.com https://cdn.onesignal.com https://onesignal.com; connect-src 'self' onesignal.com wss://*.pusher.com wss://*.pusherapp.com  ;"
 Header set Referrer-Policy "strict-origin-when-cross-origin"
 Header set Feature-Policy "geolocation 'self';vibrate 'self'; usermedia *; sync-xhr 'self'; notifications 'self' https://onesignal.com  https://pusher.com  ; payment: 'self'; push: 'self' https://onesignal.com  https://pusher.com   ;fullscreen 'self'; "
 #Header always set X-Content-Type-Options "nosniff"
 #Header always set X-Frame-Options "SAMEORIGIN"
