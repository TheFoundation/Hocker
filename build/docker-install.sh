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
		cd /tmp && wget http://mirrors.kernel.org/ubuntu/pool/multiverse/liba/libapache-mod-fastcgi/libapache2-mod-fastcgi_2.4.7~0910052141-1.2_amd64.deb && dpkg -i libapache2-mod-fastcgi_2.4.7~0910052141-1.2_amd64.deb &&  apt install -f && rm /tmp/libapache2-mod-fastcgi_2.4.7~0910052141-1.2_amd64.deb
		apt-get -y install --no-install-recommends fcgiwrap apache2-utils php${PHPVersion}-fpm  php${PHPVersion}-fpm php${PHPVersion}-common libapache2-mod-fastcgi
		(mkdir -p /etc/php/${PHPVersion}/cli/conf.d /etc/php/${PHPVersion}/fpm/conf.d /etc/php/${PHPVersion}/apache2/conf.d ;true)

					echo ; } ;
		
_install_php_basic() {
		PHPLONGVersion=$(php --version|head -n1 |cut -d " " -f2);
		PHPVersion=${PHPLONGVersion:0:3};
		## ATT: php-imagick has no webp (2020-03) , but is installed here since the imagick install step above builds from source and purges it before
		apt-get update && apt-get install php${PHPVersion}-intl php${PHPVersion}-apcu php${PHPVersion}-opcache php${PHPVersion}-xdebug php${PHPVersion}-mysql php${PHPVersion}-pgsql php${PHPVersion}-sqlite3 php${PHPVersion}-xml php${PHPVersion}-xsl php${PHPVersion}-zip php${PHPVersion}-soap php${PHPVersion}-curl php${PHPVersion}-bcmath php${PHPVersion}-mbstring php${PHPVersion}-json php${PHPVersion}-gd php${PHPVersion}-imagick  php${PHPVersion}-ldap php${PHPVersion}-imap || exit 111

		##php-memcached
		apt-get -y --no-install-recommends install gcc make autoconf libc-dev pkg-config zlib1g-dev libmemcached-dev php${PHPVersion}-dev 
		/bin/bash -c '(sleep 2 ; echo "no --disable-memcached-sasl" ;yes  "") | (pecl install -f memcached ;true); find /etc/php -type d -name "conf.d"  | while read phpconfdir ;do echo extension=memcached.so > $phpconfdir/memcached.ini;done'
		###mcrypt
		echo INSTALL php-mcrypt && pecl channel-update pecl.php.net && pecl install mcrypt-1.0.2 

		#echo extension=$(find /usr/lib/php -name "mcrypt.so")  |tee /etc/php/${PHPVersion}/fpm/conf.d/20-mcrypt.ini /etc/php/${PHPVersion}/cli/conf.d/20-mcrypt.ini
		(mkdir -p /etc/php/${PHPVersion}/cli/conf.d /etc/php/${PHPVersion}/fpm/conf.d /etc/php/${PHPVersion}/apache2/conf.d ;true)
		
		bash -c "echo extension="$(find /usr/lib/php/ -name "mcrypt.so" |head -n1) | tee /etc/php/${PHPVersion}/fpm/conf.d/20-mcrypt.ini /etc/php/${PHPVersion}/cli/conf.d/20-mcrypt.ini
		test -d /etc/php/${PHPVersion}/mods-available || mkdir /etc/php/${PHPVersion}/mods-available && bash -c "echo extension="$(find /usr/lib/php/ -name "mcrypt.so" |head -n1) |tee /etc/php/${PHPVersion}/mods-available/mcrypt.ini
		phpenmod mcrypt 

		##OPCACHE
		{ \
		                echo 'opcache.memory_consumption=128'; \
		                echo 'opcache.interned_strings_buffer=8'; \
		                echo 'opcache.max_accelerated_files=4000'; \
		                echo 'opcache.revalidate_freq=60'; \
		                echo 'opcache.fast_shutdown=1'; \
		                echo 'opcache.enable_cli=1'; \
		        } | tee  -a /etc/php/${PHPVersion}/fpm/conf.d/opcache.ini /etc/php/${PHPVersion}/apache2/conf.d/opcache.ini /etc/php/${PHPVersion}/cli/conf.d/opcache.ini /etc/php/${PHPVersion}/mods-available/opcache.ini > /dev/null
				##MCRYPT ## was in php until 7.1
		apt-get update && apt-get -y install php${PHPVersion}-dev && /bin/bash -c 'echo |pecl install redis' && echo extension=redis.so > /etc/php/${PHPVersion}/mods-available/redis.ini && phpenmod redis
		
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





