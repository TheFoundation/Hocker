#!/bin/bash

_fix_apt_keys() {
	chown root:root /tmp;chmod 1777 /tmp
	apt-get clean; find /var/lib/apt/lists -type f -delete
	(apt-get update 2>&1 1>/dev/null||true)  | sed -ne 's/.*NO_PUBKEY //p' | while read key; do
        echo 'Processing key:' "$key"
        apt-key adv --keyserver keyserver.ubuntu.com --recv-keys "$key"; done ;
        ## apt-get update 2>&1 | sed 's/$/|/g'|tr -d '\n'
        apt-get clean &&  find /var/lib/apt/lists -type f -delete
        rm /var/cache/ldconfig/aux-cache 2>/dev/null|| true ;/sbin/ldconfig ; ## possible partial fix when buildx fails with error 139 segfault at libc-upgrads , 
        #grep "options single-request timeout:2 attempts:2 ndots:2" /etc/resolv.conf || (echo "options single-request timeout:2 attempts:2 ndots:2" >> /etc/resolv.conf )
        ## resolv.conf unchangeable in docker
        #apt-get -y --reinstall install libc-bin
        #apt-mark hold libc-bin 
        
         echo -n ; } ;
##
_do_cleanup_quick() {
			which apt-get &>/dev/null && apt-get -y purge texlive-base* man-db doxygen* libllvm* binutils* gcc g++ build-essential gcc make $( dpkg --get-selections|grep -v deinstall$|cut -f1|cut -d" " -f1|grep  -e \-dev: -e \-dev$ ) ||true
			which apt-get &>/dev/null && apt-get -y autoremove 2>&1 | sed 's/$/|/g'|tr -d '\n'
			which apt-get &>/dev/null && apt-get autoremove -y --force-yes 2>&1 | sed 's/$/|/g'|tr -d '\n'
			( find /tmp/ -mindepth 1 -type f 2>/dev/null |grep -v ^$|xargs rm || true  &  find /tmp/ -mindepth 1 -type d 2>/dev/null |grep -v ^$|xargs rm  -rf || true  ) &
			( find /usr/share/doc -type f -delete 2>/dev/null || true &  find  /usr/share/man -type f -delete 2>/dev/null || true  ) &
			wait
			apt-get clean &&  find /var/lib/apt/lists -type f -delete

			echo ; } ;

##########################################
_do_cleanup() {
      PHPLONGVersion=$(php --version|head -n1 |cut -d " " -f2);
      PHPVersion=${PHPLONGVersion:0:3};
      ##### remove all packages named -dev or -dev: (e.g. mylib-dev:amd64 )
      apt-get purge -y build-essential $( dpkg --get-selections|grep -v deinstall$|cut -f1|cut -d" " -f1|grep -e python-software-properties -e software-properties-common) gcc make $( dpkg --get-selections|grep -v deinstall$|cut -f1|cut -d" " -f1|grep  -e \-dev: -e \-dev$ ) 2>&1 | sed 's/$/|/g'|tr -d '\n'
      apt-get -y autoremove 2>&1 | sed 's/$/|/g'|tr -d '\n'
			( find /tmp/ -mindepth 1 -type f |xargs rm || true  ; find /tmp/ -mindepth 1 -type d |xargs rm  -rf || true  ) &
			( find /usr/share/doc -type f -delete || true ; find  /usr/share/man -type f -delete || true  ) &
			wait
			##remove package manager caches
			which apt-get 2>/dev/null && apt-get autoremove -y --force-yes &&  apt-get clean && find -name "/var/lib/apt/lists/*_*" -delete
			##remove ssh host keys
			for keyz in /etc/dropbear/dropbear_dss_host_key /etc/dropbear/dropbear_rsa_host_key /etc/dropbear/dropbear_ecdsa_host_key ;do test -f $keyz && rm $keyz;done

			echo ; } ;

_install_dropbear() {
    echo -n "::DROBEAR INSTALL:APT:"
    apt-get update && apt-get install -y build-essential git zlib1g-dev gcc make autoconf libc-dev pkg-config    || exit 111
    ## check if the already installed dropbear has "disable-weak-ciphers" support 
    dropbear --help 2>&1 |grep -q ed255 ||  ( echo "re-installing dropbear from git "
        cd /tmp/ &&  git clone https://github.com/mkj/dropbear.git && cd dropbear && autoconf  &&  autoheader  && ./configure |sed 's/$/ → /g'|tr -d '\n'  &&    make PROGRAMS="dropbear dbclient dropbearkey dropbearconvert " -j$(nproc)  &&  make install || exit 222
        rm -rf /tmp/dropbear 2>/dev/null || true
        apt-get -y purge build-essential zlib1g-dev gcc make autoconf libc-dev pkg-config 2>&1 | sed 's/$/|/g'|tr -d '\n'
    )
  _do_cleanup_quick
 echo ; } ;

_install_imagick() {
    PHPLONGVersion=$(php --version|head -n1 |cut -d " " -f2);
    PHPVersion=${PHPLONGVersion:0:3};
    php -r 'phpinfo();'|grep  ^ImageMagick|grep WEBP -q || (
    ## IMagick with WEBP
    sed -i '/deb-src/s/^# //' /etc/apt/sources.list && apt update && apt-get -y build-dep imagemagick && apt-get -y install build-essential gcc make autoconf libc-dev pkg-config libmcrypt-dev   php${PHPVersion}-dev libjpeg-dev libpng-dev && cd /tmp/ && wget -q -c -O- http://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-1.1.0.tar.gz | tar xvz || exit 111
    cd $(find /tmp/ -type d -name "libwebp-*" |head -n1) &&  ./configure |sed 's/$/ → /g'|tr -d '\n'  && make -j $(nproc) && make install || exit 111
    ### IMAGICK
    apt-get -y --force-yes build-dep imagemagick && cd /tmp/ && wget https://imagemagick.org/download/ImageMagick.tar.gz && tar xvzf ImageMagick.tar.gz|| exit 222
    /bin/bash -c 'cd $(find /tmp/ -type d -name "ImageMagick-*" |head -n1) && ./configure  --with-webp=yes '"|sed 's/$/ → /g'|tr -d '\n' "' && make -j$(nproc) && make install && ldconfig /usr/local/lib &&  ( find /tmp/ -name "ImageMagic*" |xargs rm -rf  ) && identify -version  ' || exit 222
    ##PHP-imagick
    apt-get -y purge php-imagick 2>&1 | sed 's/$/|/g'|tr -d '\n'
    #pecl install imagick &&
    /bin/bash -c 'find /etc/php -type d -name "conf.d"  | while read phpconfdir ;do echo extension=imagick.so > $phpconfdir/20-imagick.ini;done' || true &
    cd /tmp/ && wget https://pecl.php.net/get/imagick-3.4.3.tgz -O- -q |tar xvz && cd /tmp/imagick-3.4.3/  && phpize && ./configure && make -j $(nproc) && make -j3 install || exit 333
    #apt-get -y  purge build-essential gcc make autoconf libmagickwand-dev php${PHPVersion}-dev libjpeg-dev libpng-dev libwebp-dev || true
    apt-get -y  purge build-essential gcc make autoconf php${PHPVersion}-dev || true
    apt-get -y install  $(apt-cache search libopenexr|grep ^libopenexr[0-9]|cut -d" " -f1|grep [0-9]$)  $(apt-cache search libfftw|grep ^libfftw[0-9]|cut -d" " -f1|grep bin$)  $(apt-cache search liblqr|grep ^liblqr|cut -d" " -f1|grep -v 'dev')  $(apt-cache search libgomp|grep ^libgomp[0-9]|cut -d" " -f1|grep -v '-') libwmf-bin $(apt-cache search libdjvul|grep ^libdjvulibre[0-9]|cut -d" " -f1) 2>&1 | sed 's/$/|/g'|tr -d '\n'
    apt-get -y autoremove 2>&1 | sed 's/$/|/g'|tr -d '\n'

    ## CLEAN build stage
		find /tmp/ -type d -name "lilbwebp*" |xargs rm -rf || true &
		find /tmp/ -type d -name "ImageMagick*" |xargs rm -rf || true &
		find /tmp/ -type d -name "imagick*" |xargs rm -rf || true &
		echo "TESTING IMAGEMAGICK WEBP";
		php -r 'phpinfo();'|grep  ^ImageMagick|grep WEBP -q || exit 444
    )
  _do_cleanup_quick

		echo ; } ;

_install_php_nofpm() {
		_install_php_basic ;
		PHPLONGVersion=$(php --version|head -n1 |cut -d " " -f2);
		PHPVersion=${PHPLONGVersion:0:3};
		apt-get update && apt-get -y install --no-install-recommends  libapache2-mod-php${PHPVersion}
				which apt-get 2>/dev/null && apt-get autoremove -y --force-yes &&  apt-get clean &&   find /var/lib/apt/lists -type f -delete
    _do_cleanup_quick
					echo ; } ;

_install_php_fpm() {
_install_php_basic ;
        PHPLONGVersion=$(php --version|head -n1 |cut -d " " -f2);
        PHPVersion=${PHPLONGVersion:0:3};
        apt-get -y --no-install-recommends  install php${PHPVersion}-fpm
        uname -m |grep -q aarch64 && cd /tmp && wget https://launchpad.net/~ondrej/+archive/ubuntu/apache2/+build/9629365/+files/libapache2-mod-fastcgi_2.4.7~0910052141-1.2+deb.sury.org~trusty+3_arm64.deb && dpkg -i "libapache2-mod-fastcgi_2.4.7~0910052141-1.2+deb.sury.org~trusty+3_arm64.deb" &&  apt install -f && a2enmod fastcgi && rm "/tmp/libapache2-mod-fastcgi_2.4.7~0910052141-1.2+deb.sury.org~trusty+3_arm64.deb"
        uname -m |grep -q x86_64  && cd /tmp && wget http://mirrors.kernel.org/ubuntu/pool/multiverse/liba/libapache-mod-fastcgi/libapache2-mod-fastcgi_2.4.7~0910052141-1.2_amd64.deb && dpkg -i libapache2-mod-fastcgi_2.4.7~0910052141-1.2_amd64.deb &&  apt install -f && a2enmod fastcgi && rm /tmp/libapache2-mod-fastcgi_2.4.7~0910052141-1.2_amd64.deb
        apt-get update && apt-get -y install --no-install-recommends fcgiwrap apache2-utils php${PHPVersion}-fpm  php${PHPVersion}-fpm php${PHPVersion}-common libapache2-mod-fastcgi
        (mkdir -p /etc/php/${PHPVersion}/cli/conf.d /etc/php/${PHPVersion}/fpm/conf.d /etc/php/${PHPVersion}/apache2/conf.d ;true)
        ln -s /run/php/php${PHPVersion}-fpm.sock /run/php/php-fpm.sock
        _modify_apache_fpm

    _do_cleanup_quick

					echo ; } ;

_basic_setup_debian() {
    apt-get update  && apt-get dist-upgrade -y &&  apt-get install -y --no-install-recommends apache2 zip tar openssh-sftp-server supervisor dropbear-run dropbear-bin wget curl ca-certificates rsync nano \
      vim psmisc procps git curl  cron php-pear msmtp msmtp-mta &&  apt-get autoremove -y --force-yes
    echo ; } ;


_install_php_basic() {
    apt-get update && apt-get -y install --no-install-recommends apt-transport-https lsb-release ca-certificates curl  && curl https://packages.sury.org/php/apt.gpg | apt-key add - 
		_basic_setup_debian
       _do_cleanup_quick 
		#get latest composer 
		curl -sS https://getcomposer.org/installer -o /tmp/composer.installer.php && php /tmp/composer.installer.php --install-dir=/usr/local/bin --filename=composer && rm /tmp/composer.installer.php
		
		#####following step is preferred in compose file
		#apt-get update  &&  apt-get dist-upgrade -y &&  apt-get install -y software-properties-common && LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php
		PHPLONGVersion=$(php --version|head -n1 |cut -d " " -f2);
		PHPVersion=${PHPLONGVersion:0:3};
		(mkdir -p /etc/php/${PHPVersion}/cli/conf.d /etc/php/${PHPVersion}/fpm/conf.d /etc/php/${PHPVersion}/apache2/conf.d ;true)
		## ATT: php-imagick has no webp (2020-03) , but is installed here since the imagick install step above builds from source and purges it before
		apt-get update && apt-get install -y --no-install-recommends  php${PHPVersion}-intl \
		$( apt-cache search apcu  |grep -v deinstall|grep php${PHPVersion}-apcu |cut -d" " -f1 |cut -f1|grep php${PHPVersion}-apcu  ) \
		$( apt-cache search imagick  |grep -v deinstall|grep php-imagick |cut -d" " -f1 |cut -f1|grep php-imagick  ) \
		$( apt-cache search xdebug  |grep -v deinstall|grep php${PHPVersion}-xdebug |cut -d" " -f1 |cut -f1|grep php${PHPVersion}-xdebug  ) \
		php${PHPVersion}-xmlrpc php-gnupg php${PHPVersion}-opcache php${PHPVersion}-mysql php${PHPVersion}-pgsql php${PHPVersion}-sqlite3 \
		php${PHPVersion}-xml php${PHPVersion}-xsl php${PHPVersion}-zip php${PHPVersion}-soap php${PHPVersion}-curl php${PHPVersion}-bcmath \
		php${PHPVersion}-mbstring php${PHPVersion}-json php${PHPVersion}-gd php${PHPVersion}-ldap php${PHPVersion}-imap || exit 111
		apt-get install -y --no-install-recommends gcc make autoconf libc-dev pkg-config libmcrypt-dev
		pecl channel-update pecl.php.net
		##php-memcached
		apt-get -y --no-install-recommends install gcc make autoconf libc-dev pkg-config zlib1g-dev libmemcached-dev php${PHPVersion}-dev  libmemcached-tools
		
        
		## PHP GNUPG
		phpenmod gnupg	
		## PHP MEMCACHED IF MISSING FROM REPO
		apt-get update && apt-get install $( apt-cache search memcached  |grep -v deinstall|grep libmemcached|cut -d" " -f1 |cut -f1|grep libmemcached|grep -v -e dbg$ -e dev$ -e memcachedutil -e perl$)
		php -r 'phpinfo();'|grep  memcached -q ||  (echo |pecl install memcached ;test -d /etc/php/${PHPVersion}/mods-available || mkdir /etc/php/${PHPVersion}/mods-available && bash -c "echo extension="$(find /usr/lib/php/ -name "memcached.so" |head -n1) |tee /etc/php/${PHPVersion}/mods-available/memcached.ini ;phpenmod memcached  ) 
		## PHP XDEBUG IF MISSING FROM REPO
		php -r 'phpinfo();'|grep  xdebug -q ||  (echo |pecl install xdebug ;test -d /etc/php/${PHPVersion}/mods-available || mkdir /etc/php/${PHPVersion}/mods-available && bash -c "echo extension="$(find /usr/lib/php/ -name "xdebug.so" |head -n1) |tee /etc/php/${PHPVersion}/mods-available/xdebug.ini ) ### do not activate by default ( phpenmod xdebug )
		##PHP apcu IF MISSING FROM REPO
		php -r 'phpinfo();'|grep  apcu -q || (echo | pecl install apcu ; test -d /etc/php/${PHPVersion}/mods-available || mkdir /etc/php/${PHPVersion}/mods-available && bash -c "echo extension="$(find /usr/lib/php/ -name "apcu.so" |head -n1) |tee /etc/php/${PHPVersion}/mods-available/apcu.ini ; phpenmod apcu || true  )
        ##PHP IMAGICK IF MISSING FROM REPO
        php -r 'phpinfo();'|grep  ^ImageMagick -q || _install_imagick   

#######	/bin/bash -c '(sleep 0.5 ; echo "no --disable-memcached-sasl" ;yes  "") | (pecl install -f memcached ;true); find /etc/php -type d -name "conf.d"  | while read phpconfdir ;do echo extension=memcached.so > $phpconfdir/memcached.ini;done'
		/bin/bash -c '(sleep 0.5 ; echo "no --disable-memcached-sasl" ;yes  "") | ( mkdir /tmp/pear ; curl https://pecl.php.net/$(curl https://pecl.php.net/package/memcached|grep tgz|grep memcached|grep get|cut -d/ -f2-|cut -d\" -f1|head -n1) > /tmp/pear/memcached.tgz && pecl install /tmp/pear/memcached.tgz ; rm /tmp/pear/memcached.tgz  ;true); find /etc/php -type d -name "conf.d"  | while read phpconfdir ;do echo extension=memcached.so > $phpconfdir/memcached.ini;done'


		###mcrypt
		### make the version string an integer for comparations
		if [ "$(echo "$PHPVersion"|awk -F  "." '{printf("%d%0d",$1,$2*10)}')" -ge $(echo "7.2"|awk -F  "." '{printf("%d%0d",$1,$2*10)}') ]; then
			echo "PHP Version does not build MCRYPT,deprecated in php7.2"
		else
			echo INSTALL php-mcrypt && pecl channel-update pecl.php.net && pecl install mcrypt-1.0.2  &

			find /usr/lib/php -name "mcrypt.so"|grep -q mcrypt.so && echo extension=$(find /usr/lib/php -name "mcrypt.so"|head -n1 ) |grep -v "extension=$" | tee /etc/php/${PHPVersion}/*/conf.d/20-mcrypt.ini
			#bash -c "echo extension="$(find /usr/lib/php/ -name "mcrypt.so" |head -n1) |grep -v ^$| tee /etc/php/${PHPVersion}/fpm/conf.d/20-mcrypt.ini /etc/php/${PHPVersion}/cli/conf.d/20-mcrypt.ini
			test -d /etc/php/${PHPVersion}/mods-available || mkdir /etc/php/${PHPVersion}/mods-available && bash -c "echo extension="$(find /usr/lib/php/ -name "mcrypt.so" |head -n1) |tee /etc/php/${PHPVersion}/mods-available/mcrypt.ini
			phpenmod mcrypt
		fi

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
#		apt-get update && apt-get -y install php${PHPVersion}-dev && /bin/bash -c 'echo |pecl install redis' && echo extension=redis.so > /etc/php/${PHPVersion}/mods-available/redis.ini && phpenmod redis
		apt-get update && apt-get -y install php${PHPVersion}-dev && /bin/bash -c 'mkdir /tmp/pear && curl https://pecl.php.net/$(curl https://pecl.php.net/package/redis|grep tgz|grep redis|grep get|cut -d/ -f2-|cut -d\" -f1|head -n1) > /tmp/pear/redis.tgz && pecl install /tmp/pear/redis.tgz ' && echo extension=redis.so > /etc/php/${PHPVersion}/mods-available/redis.ini && phpenmod redis
		rm /tmp/pear/redis.tgz || true 
		apt-get -y remove gcc make autoconf libc-dev pkg-config libmcrypt-dev
		
		apt-get autoremove -y --force-yes &&  apt-get clean &&   find /var/lib/apt/lists -type f -delete
    _do_cleanup_quick
			echo ; } ;

##########################################
_modify_apache_fpm() {
		PHPLONGVersion=$(php --version|head -n1 |cut -d " " -f2);
		PHPVersion=${PHPLONGVersion:0:3};
        echo -n FPM APACHE ENABLE MODULES
        a2dismod php${PHPVersion} || true && a2dismod  mpm_prefork mpm_worker && a2enmod actions alias setenvif proxy ssl proxy_http remoteip rewrite expires 
        echo -n WSTUN
        a2enmod proxy_wstunnel || true
        echo -n PROXY_FCGI a2enmod proxy_fcgi || true
        ## SELECT mpm_prefork ## only libapache-mod-php
        a2dismod mpm_event mpm_worker && a2enmod mpm_prefork
        ## SELECT mpm_event ## only FPM
        a2dismod mpm_prefork mpm_worker && a2enmod mpm_event
    echo -n ; } ;
_modify_apache() {
				##align docroot to /var/www/html
				sed 's/DocumentRoot \/var\/www$/DocumentRoot \/var\/www\/html/g' /etc/apache2/sites-enabled/* -i
				##log other vhosts to access.log
				test -f /etc/apache2/conf-enabled/other-vhosts-access-log.conf && sed 's/other_vhosts_access.log/access.log/g' -i /etc/apache2/conf-enabled/other-vhosts-access-log.conf

                
                echo -n  'RECTIFY APACHE CONFIG -> general php-fpm.sock , log remoteip/X-Forwarded-For  ## enable php execution'
				#sed 's/\/VirtualHost/Directory "\/var\/www">\n     Options -Indexes +IncludesNOEXEC +SymLinksIfOwnerMatch\n    AllowOverride All\n    AddType application\/x-httpd-php .htm .html .php5 #.php4\n     AddHandler application\/x-httpd-php .html .htm .php5 #.php4\n<\/Directory>\n<\/VirtualHost/g;s/ErrorLog.\+//g;s/CustomLog.\+/LogFormat "%h %l %u %t \\"%r\\" %>s %b \\"%{Referer}i\\" \\"%{User-Agent}i\\"" combined\n                LogFormat "%{X-Forwarded-For}i %l %u %t \\"%r\\" %>s %b \\"%{Referer}i\\" \\"%{User-Agent}i\\"" proxy          \n                SetEnvIf X-Forwarded-For "^.*\\..*\\..*\\..*" forwarded\n                ErrorLog ${APACHE_LOG_DIR}\/error.log\n                CustomLog ${APACHE_LOG_DIR}\/access.log combined env=!forwarded \n                CustomLog ${APACHE_LOG_DIR}\/access.log proxy env=forwarded\n/g' -i /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-available/000-default.conf && \
				sed 's/\/VirtualHost/Directory "\/var\/www">\n     Options -Indexes +IncludesNOEXEC +SymLinksIfOwnerMatch\n    AllowOverride All\n    AddType application\/x-httpd-php .htm .html .php5 #.php4\n     AddHandler application\/x-httpd-php .html .htm .php5 #.php4\n<\/Directory>\n     php_admin_value error_log ${APACHE_LOG_DIR}\/php.error.log\n      php_value include_path \/var\/www\/\include_local:\/var\/www\/include\n     <\/VirtualHost/g;s/ErrorLog.\+//g;s/CustomLog.\+/LogFormat "%h %l %u %t \\"%r\\" %>s %b \\"%{Referer}i\\" \\"%{User-Agent}i\\"" combined\n                LogFormat "%{X-Forwarded-For}i %l %u %t \\"%r\\" %>s %b \\"%{Referer}i\\" \\"%{User-Agent}i\\"" proxy          \n                SetEnvIf X-Forwarded-For "^.*\\..*\\..*\\..*" forwarded\n                ErrorLog ${APACHE_LOG_DIR}\/error.log\n                CustomLog ${APACHE_LOG_DIR}\/access.log combined env=!forwarded \n                CustomLog ${APACHE_LOG_DIR}\/access.log proxy env=forwarded\n/g;s/-socket \/var\/run\/php\/php.*fpm.*\.sock/-socket \/var\/run\/php\/php-fpm.sock/g' -i /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-available/000-default.conf 
				cp -aurv /etc/apache2/sites-available/ /etc/apache2/sites-available.default ;
				ln -sf /etc/apache2/sites-available/* /etc/apache2/sites-enabled/

				echo -n "disable catchall document root:"
				sed 's/.\+DocumentRoot.\+//g' -i /etc/apache2/apache2.conf
				##fixx www-data userid and only enable sftp for them (bind mount /etc/shells and run "usermod -s /bin/bash www-data" for www-data user login )

                ##set max input vars and exec time for fpm/apache2
                sed "s/;max_input_vars/max_input_vars/g;s/max_input_vars.\+/max_input_vars = 8192/g;s/max_execution_time.\+/max_execution_time = 1800/g" $(find $(ls -1d /etc/php*) -name php.ini|grep -e apache -e fpm) -i
                ##ENABLE SITES
                a2ensite default-ssl && a2ensite 000-default && ls -lh /etc/apache2/sites*/*
                _do_cleanup_quick
				echo ; } ;

###########################################
_install_mariadb_ubuntu() {

				## $2 is MARIADB version $3 ubuntu version as $1 is mariadb passed from main script
				apt-get update && apt-get install -y gpg-agent dirmngr  $(apt-cache search sofware-properties-common|grep sofware-properties-common|cut -d" " -f1|grep sofware-properties-common)  $(apt-cache search python-software-properties|grep python-software-properties|cut -d" " -f1|grep python-software-properties)
				apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8 || exit 111
				echo "DOING "LC_ALL=C.UTF-8 add-apt-repository 'deb [arch=amd64,arm64,ppc64el] http://mirrors.n-ix.net/mariadb/repo/'$2'/ubuntu '$3' main'
				LC_ALL=C.UTF-8 add-apt-repository 'deb [arch=amd64,arm64,ppc64el] http://mirrors.n-ix.net/mariadb/repo/'$2'/ubuntu '$3' main'
				apt-get update && DEBIAN_FRONTEND=noninteractive	apt-get -y install --no-install-recommends mariadb-server mariadb-client
				apt-get purge gnupg dirmngr $(apt-cache search sofware-properties-common|grep sofware-properties-common|cut -d" " -f1|grep sofware-properties-common)  $(apt-cache search python-software-properties|grep python-software-properties|cut -d" " -f1|grep python-software-properties)
				which apt-get 2>/dev/null && apt-get autoremove -y --force-yes &&  apt-get clean &&  find /var/lib/apt/lists -type f -delete
        _do_cleanup_quick ;
				echo ; } ;

_setup_wwwdata() {
		PHPLONGVersion=$(php --version|head -n1 |cut -d " " -f2);
		PHPVersion=${PHPLONGVersion:0:3};
				sed 's/^www-data:x:1000/www-data:x:33/g' /etc/passwd -i
				usermod -s /usr/lib/openssh/sftp-server www-data && echo /usr/lib/openssh/sftp-server >> /etc/shells

				##userdirs
				ln -s /var/www/html /root/ &&  mkdir -p /var/www/.ssh /var/www/include /var/www/include_local && chown www-data /var/www/ -R && mkdir /root/.ssh && touch /root/.ssh/authorized_keys
				touch /var/www/.ssh/authorized_keys && chown root:root /var/www/.ssh /var/www/.ssh/authorized_keys && chmod go-rw  /root/.ssh/authorized_keys /root/.ssh /var/www/.ssh /var/www/.ssh/authorized_keys
                ## CREATE possible php socket folder and insert fpm service into non-supervisord section of init script
                /bin/mkdir -p /var/run/php/ || true && chown www-data:www-data /var/run/php/
                sed 's/service cron start/service php'${PHPVersion}'-fpm start \&\nservice cron start/g' /usr/local/bin/run.sh -i
                cp -v /root/pool-www.conf /etc/php/${PHPVersion}/fpm/pool.d/www.conf
			echo ; } ;


_install_util() {
			apt-get update && apt-get -y --no-install-recommends install ssl-cert mariadb-client lftp iputils-ping less byobu net-tools lsof iotop iftop sysstat atop nmon netcat unzip socat
			_do_cleanup_quick
			echo ; } ;


echo -n "::installer called with:: "$1

case $1 in
  imagick|imagemagick|ImageMgick) _install_imagick "$@" ;;
  dropbear|ssh-tiny) _install_dropbear "$@" ;;
  php-fpm) _install_php_fpm "$@" ;;
  php|php-nofpm) _install_php_nofpm "$@" ;;
  apache) _modify_apache "$@" ;;
  mariadb-ubuntu|mariabunut) _install_mariadb_ubuntu "$@" ;;
  util|utils) _install_util "$@" ;;
  wwwdata) _setup_wwwdata "$@" ;;
  cleanq|quickclean|qclean) _do_cleanup_quick "$@" ;;
  cleanup|fullclean) _do_cleanup "$@"  ;;
	aptkeys|fixapt|aptupdate) _fix_apt_keys "$@" ;;
esac

exit 0
