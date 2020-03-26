#!/bin/bash

_install_dropbear() {
	apt-get update && apt-get install -y build-essential git zlib1g-dev || exit 111 
	cd /tmp/ &&  git clone https://github.com/mkj/dropbear.git && cd dropbear && autoconf  &&  autoheader  && ./configure &&    make PROGRAMS="dropbear dbclient dropbearkey dropbearconvert " -j 2  &&  make install || exit 222
	rm -rf /tmp/dropbear || true 

 echo ; } ; 

_install_imagick() { 
		PHPLONGVersion=$(php --version|head -n1 |cut -d " " -f2);
		PHPVersion=${PHPLONGVersion:0:3};
		##WEBP
		sed -i '/deb-src/s/^# //' /etc/apt/sources.list && apt update && apt-get -y build-dep imagemagick && apt-get -y install php${PHPVersion}-dev libjpeg-dev libpng-dev && cd /tmp/ && wget -q -c -O- http://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-1.1.0.tar.gz | tar xvz || exit 111
		cd $(find /tmp/ -type d -name "libwebp-*" |head -n1) &&  ./configure && make -j $(nproc) && make install || exit 111
		### IMAGICK
		apt-get -y --force-yes build-dep imagemagick && cd /tmp/ && wget https://imagemagick.org/download/ImageMagick.tar.gz && tar xvzf ImageMagick.tar.gz|| exit 222
		/bin/bash -c 'cd $(find /tmp/ -type d -name "ImageMagick-*" |head -n1) && ./configure --with-webp=yes && make -j$(nproc) && make install && ldconfig /usr/local/lib &&  ( find /tmp/ -name "ImageMagic*" |xargs rm -rf  ) && identify -version  ' || exit 222
		
		##PHP-imagick
		apt-get purge php-imagick	
		#pecl install imagick &&  
		/bin/bash -c 'find /etc/php -type d -name "conf.d"  | while read phpconfdir ;do echo extension=imagick.so > $phpconfdir/20-imagick.ini;done' || true &
		cd /tmp/ && wget https://pecl.php.net/get/imagick-3.4.3.tgz -O- -q |tar xvz && cd /tmp/imagick-3.4.3/  && phpize && ./configure && make -j $(nproc) && make install || exit 333
		apt-get -y purge  libmagickwand-dev php${PHPVersion}-dev libjpeg-dev libpng-dev libwebp-dev || true  &
		find /tmp/ -type d -name "lilbwebp*" |xargs rm -rf || true & 
		find /tmp/ -type d -name "ImageMagick*" |xargs rm -rf || true &
		find /tmp/ -type d -name "imagick*" |xargs rm -rf || true &
		php -r 'phpinfo();'|grep  ^ImageMagick|grep WEBP -q || exit 444
		echo ; } ;

_install_php_nofpm() {
		_install_php_basic ;
		PHPLONGVersion=$(php --version|head -n1 |cut -d " " -f2);
		PHPVersion=${PHPLONGVersion:0:3};
		apt-get -y install libapache2-mod-php${PHPVersion}
					echo ; } ;

_install_php_fpm() {
		_install_php_basic ;
		PHPLONGVersion=$(php --version|head -n1 |cut -d " " -f2);
		PHPVersion=${PHPLONGVersion:0:3};
		apt-get -y install php${PHPVersion}-fpm
					echo ; } ;
		
_install_php_basic() {
		PHPLONGVersion=$(php --version|head -n1 |cut -d " " -f2);
		PHPVersion=${PHPLONGVersion:0:3};
		## ATT: php-imagick has no webp (2020-03) , but is installed here since the imagick install step above builds from source and purges it before
		apt-get update && apt-get install php${PHPVersion}-intl php${PHPVersion}-apcu php${PHPVersion}-opcache php${PHPVersion}-xdebug php${PHPVersion}-mysql php${PHPVersion}-pgsql php${PHPVersion}-sqlite3 php${PHPVersion}-xml php${PHPVersion}-xsl php${PHPVersion}-zip php${PHPVersion}-soap php${PHPVersion}-curl php${PHPVersion}-bcmath php${PHPVersion}-mbstring php${PHPVersion}-json php${PHPVersion}-gd php${PHPVersion}-imagick  php${PHPVersion}-ldap php${PHPVersion}-imap || exit 111
		
			echo ; } ;

_do_cleanup() { 
			find /tmp/ -mindepth 1 -type f |xargs rm || true 
			find /tmp/ -mindepth 1 -type d |xargs rm || true 
			##remove ssh host keys
			which apt-get 2>/dev/null && apt-get autoremove -y --force-yes &&  apt-get clean &&  rm /var/lib/apt/lists/*_*
			##remove ssh host keys
			for keyz in /etc/dropbear/dropbear_dss_host_key /etc/dropbear/dropbear_rsa_host_key /etc/dropbear/dropbear_ecdsa_host_key ;do test -f $keyz && rm $keyz;done 
			
			echo ; } ;


case $1 in 
  imagick|imagemagick|ImageMgick) _install_imagick "$@" ;;
  cleanup ) _do_cleanup "$@"  ;; 
esac

exit 0





