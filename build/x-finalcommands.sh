#/bin/bash

## DEBUG PLACE












#apt-get purge -y apache2 apache2-bin
#rm /etc/apache2/conf-enabled/other-vhosts-access-log.conf
#dpkg --configure -a
#mkdir /tmp/apachesave
#rm /etc/apache2/conf-enabled/other-vhosts-access-log.conf

#apt-get -y install apache2  apache2-bin
#dpkg --configure -a
#    uname -m |grep -q aarch64 && cd /tmp && wget https://launchpad.net/~ondrej/+archive/ubuntu/apache2/+build/9629365/+files/libapache2-mod-fastcgi_2.4.7~0910052141-1.2+deb.sury.org~trusty+3_arm64.deb && dpkg -i "libapache2-mod-fastcgi_2.4.7~0910052141-1.2+deb.sury.org~trusty+3_arm64.deb" &&  apt install -f && a2enmod fastcgi && rm "/tmp/libapache2-mod-fastcgi_2.4.7~0910052141-1.2+deb.sury.org~trusty+3_arm64.deb"
#    uname -m |grep -q x86_64  && cd /tmp && wget http://mirrors.kernel.org/ubuntu/pool/multiverse/liba/libapache-mod-fastcgi/libapache2-mod-fastcgi_2.4.7~0910052141-1.2_amd64.deb && dpkg -i libapache2-mod-fastcgi_2.4.7~0910052141-1.2_amd64.deb &&  apt install -f && a2enmod fastcgi && rm /tmp/libapache2-mod-fastcgi_2.4.7~0910052141-1.2_amd64.deb
#dpkg --configure -a
#a2enmod actions fastcgi ssl headers logs a2enmod actions alias setenvif proxy ssl proxy_http remoteip rewrite expires
#a2dismod mpm_event mpm_worker && a2enmod mpm_prefork
exit 0
