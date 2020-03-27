#!/bin/bash


##
_do_cleanup_quick() { 
			which apt-get 2>/dev/null && apt-get autoremove -y --force-yes &&  apt-get clean &&  rm /var/lib/apt/lists/*_*
			
			echo ; } ;
			
##########################################
_do_cleanup() { 
      PHPLONGVersion=$(php --version|head -n1 |cut -d " " -f2);
      PHPVersion=${PHPLONGVersion:0:3};
      ##### remove all packages named -dev or -dev: (e.g. mylib-dev:amd64 )
      apt-get purge -y build-essential gcc make $( dpkg --get-selections|grep -v deinstall$|cut -f1|cut -d" " -f1|grep  -e \-dev: -e \-dev$ )
      apt-get -y autoremove
			find /tmp/ -mindepth 1 -type f |xargs rm || true 
			find /tmp/ -mindepth 1 -type d |xargs rm || true 
			##remove package managers
			which apt-get 2>/dev/null && apt-get autoremove -y --force-yes &&  apt-get clean && find -name "/var/lib/apt/lists/*_*" -delete
			##remove ssh host keys
			for keyz in /etc/dropbear/dropbear_dss_host_key /etc/dropbear/dropbear_rsa_host_key /etc/dropbear/dropbear_ecdsa_host_key ;do test -f $keyz && rm $keyz;done 
			
			echo ; } ;




_install_dropbear() {
	apt-get update && apt-get install -y build-essential git zlib1g-dev || exit 111 
	cd /tmp/ &&  git clone https://github.com/mkj/dropbear.git && cd dropbear && autoconf  &&  autoheader  && ./configure &&    make PROGRAMS="dropbear dbclient dropbearkey dropbearconvert " -j$(nproc)  &&  make install || exit 222
	rm -rf /tmp/dropbear || true 
  apt-get -y purge zlib1g-dev
  _do_cleanup_quick
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
  _do_cleanup_quick

		echo ; } ;

_install_php_nofpm() {
		_install_php_basic ;
		PHPLONGVersion=$(php --version|head -n1 |cut -d " " -f2);
		PHPVersion=${PHPLONGVersion:0:3};
		apt-get update && apt-get -y install --no-install-recommends  libapache2-mod-php${PHPVersion}
				which apt-get 2>/dev/null && apt-get autoremove -y --force-yes &&  apt-get clean &&  rm /var/lib/apt/lists/*_*
    _do_cleanup_quick
					echo ; } ;

_install_php_fpm() {
		_install_php_basic ;
		PHPLONGVersion=$(php --version|head -n1 |cut -d " " -f2);
		PHPVersion=${PHPLONGVersion:0:3};
		apt-get -y --no-install-recommends  install php${PHPVersion}-fpm
		cd /tmp && wget http://mirrors.kernel.org/ubuntu/pool/multiverse/liba/libapache-mod-fastcgi/libapache2-mod-fastcgi_2.4.7~0910052141-1.2_amd64.deb && dpkg -i libapache2-mod-fastcgi_2.4.7~0910052141-1.2_amd64.deb &&  apt install -f && rm /tmp/libapache2-mod-fastcgi_2.4.7~0910052141-1.2_amd64.deb
		apt-get update && apt-get -y install --no-install-recommends fcgiwrap apache2-utils php${PHPVersion}-fpm  php${PHPVersion}-fpm php${PHPVersion}-common libapache2-mod-fastcgi
		(mkdir -p /etc/php/${PHPVersion}/cli/conf.d /etc/php/${PHPVersion}/fpm/conf.d /etc/php/${PHPVersion}/apache2/conf.d ;true)
    _do_cleanup_quick

					echo ; } ;
		
_install_php_basic() {
		
		PHPLONGVersion=$(php --version|head -n1 |cut -d " " -f2);
		PHPVersion=${PHPLONGVersion:0:3};
		(mkdir -p /etc/php/${PHPVersion}/cli/conf.d /etc/php/${PHPVersion}/fpm/conf.d /etc/php/${PHPVersion}/apache2/conf.d ;true) 
		## ATT: php-imagick has no webp (2020-03) , but is installed here since the imagick install step above builds from source and purges it before
		apt-get update && apt-get install -y --no-install-recommends  php${PHPVersion}-intl php${PHPVersion}-apcu php${PHPVersion}-opcache php${PHPVersion}-xdebug php${PHPVersion}-mysql php${PHPVersion}-pgsql php${PHPVersion}-sqlite3 php${PHPVersion}-xml php${PHPVersion}-xsl php${PHPVersion}-zip php${PHPVersion}-soap php${PHPVersion}-curl php${PHPVersion}-bcmath php${PHPVersion}-mbstring php${PHPVersion}-json php${PHPVersion}-gd php${PHPVersion}-imagick  php${PHPVersion}-ldap php${PHPVersion}-imap || exit 111

		##php-memcached
		apt-get -y --no-install-recommends install gcc make autoconf libc-dev pkg-config zlib1g-dev libmemcached-dev php${PHPVersion}-dev 
		/bin/bash -c '(sleep 2 ; echo "no --disable-memcached-sasl" ;yes  "") | (pecl install -f memcached ;true); find /etc/php -type d -name "conf.d"  | while read phpconfdir ;do echo extension=memcached.so > $phpconfdir/memcached.ini;done'
		###mcrypt
		echo INSTALL php-mcrypt && pecl channel-update pecl.php.net && pecl install mcrypt-1.0.2  & 

		#echo extension=$(find /usr/lib/php -name "mcrypt.so")  |tee /etc/php/${PHPVersion}/fpm/conf.d/20-mcrypt.ini /etc/php/${PHPVersion}/cli/conf.d/20-mcrypt.ini
		
		
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
		which apt-get 2>/dev/null && apt-get autoremove -y --force-yes &&  apt-get clean &&  rm /var/lib/apt/lists/*_*
    _do_cleanup_quick
			echo ; } ;
			
##########################################
_modify_apache() { 
				##align docroot to /var/www/html
				sed 's/DocumentRoot \/var\/www$/DocumentRoot \/var\/www\/html/g' /etc/apache2/sites-enabled/* -i
				##log other vhosts to access.log
				test -f /etc/apache2/conf-enabled/other-vhosts-access-log.conf && sed 's/other_vhosts_access.log/access.log/g' -i /etc/apache2/conf-enabled/other-vhosts-access-log.conf
				
				sed 's/\/VirtualHost/Directory "\/var\/www">\n     Options -Indexes +IncludesNOEXEC +SymLinksIfOwnerMatch\n    AllowOverride All\n    AddType application\/x-httpd-php .htm .html .php5 #.php4\n     AddHandler application\/x-httpd-php .html .htm .php5 #.php4\n<\/Directory>\n<\/VirtualHost/g;s/ErrorLog.\+//g;s/CustomLog.\+/LogFormat "%h %l %u %t \\"%r\\" %>s %b \\"%{Referer}i\\" \\"%{User-Agent}i\\"" combined\n                LogFormat "%{X-Forwarded-For}i %l %u %t \\"%r\\" %>s %b \\"%{Referer}i\\" \\"%{User-Agent}i\\"" proxy          \n                SetEnvIf X-Forwarded-For "^.*\\..*\\..*\\..*" forwarded\n                ErrorLog ${APACHE_LOG_DIR}\/error.log\n                CustomLog ${APACHE_LOG_DIR}\/access.log combined env=!forwarded \n                CustomLog ${APACHE_LOG_DIR}\/access.log proxy env=forwarded\n/g' -i /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-available/000-default.conf && \
						cp -aurv /etc/apache2/sites-available/ /etc/apache2/sites-available.default ;ln -sf /etc/apache2/sites-available/* /etc/apache2/sites-enabled/
				
				#disable catchall document root
				sed 's/.\+DocumentRoot.\+//g' -i /etc/apache2/apache2.conf
				##fixx www-data userid and only enable sftp for them (bind mount /etc/shells and run "usermod -s /bin/bash www-data" for www-data user login )

				echo ; } ;
				
###########################################
_install_mariadb_ubuntu() {
				## $2 is MARIADB version $3 ubuntu version as $1 is mariadb passed from main script
				apt-get update && apt-get install -y gpg-agent dirmngr
				apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8 || exit 111 
				echo "DOING "add-apt-repository 'deb [arch=amd64,arm64,ppc64el] http://mirrors.n-ix.net/mariadb/repo/'$2'/ubuntu '$3' main' 
				add-apt-repository 'deb [arch=amd64,arm64,ppc64el] http://mirrors.n-ix.net/mariadb/repo/'$2'/ubuntu '$3' main' 
				apt-get update && DEBIAN_FRONTEND=noninteractive	apt-get -y install --no-install-recommends mariadb-server mariadb-client
				which apt-get 2>/dev/null && apt-get autoremove -y --force-yes &&  apt-get clean &&  rm /var/lib/apt/lists/*_*
        _do_cleanup_quick ;
				echo ; } ;

_setup_wwwdata() {
				sed 's/^www-data:x:1000/www-data:x:33/g' /etc/passwd -i
				usermod -s /usr/lib/openssh/sftp-server www-data && echo /usr/lib/openssh/sftp-server >> /etc/shells

				##userdirs
				ln -s /var/www/html /root/ &&  mkdir -p /var/www/.ssh /var/www/include /var/www/include_local && chown www-data /var/www/ -R && mkdir /root/.ssh && touch /root/.ssh/authorized_keys 
				touch /var/www/.ssh/authorized_keys && chown root:root /var/www/.ssh /var/www/.ssh/authorized_keys && chmod go-rw  /root/.ssh/authorized_keys /root/.ssh /var/www/.ssh /var/www/.ssh/authorized_keys

			echo ; } ;


_install_util() {
			apt-get update && apt-get -y --no-install-recommends install ssl-cert mariadb-client lftp iputils-ping less byobu net-tools lsof iotop iftop sysstat atop nmon netcat unzip socat
			_do_cleanup_quick
			echo ; } ;


case $1 in 
  imagick|imagemagick|ImageMgick) _install_imagick "$@" ;;
  dropbear) _install_dropbear "$@" ;;
  php-fpm) _install_php_fpm "$@" ;;
  php|php-nofpm) _install_php_nofpm "$@" ;;
  apache) _modify_apache "$@" ;;
  mariadb-ubuntu|mariabunut) _install_mariadb_ubuntu "$@" ;;
  util|utils) _install_util "$@" ;;
  wwwdata) _setup_wwwdata "$@" ;;
  cleanq|quickclean|qclean) _do_cleanup_quick "$@" ;;
  cleanup|fullclean) _do_cleanup "$@"  ;; 
  
esac

exit 0





