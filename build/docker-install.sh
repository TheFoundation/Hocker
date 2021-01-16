#!/bin/bash


#apt-key update 2>&1 |grep -v deprecated |grep -v "not changed"

_apt_install() {
DEBIAN_FRONTEND=noninteractive	apt-get -y install --no-install-recommends $@  2>&1 |grep -v -e ^$ -e "debconf: unable to initialize frontend: Dialog" -e "debconf: (No usable dialog-like program is installed, so the dialog based frontend cannot be used" -e ^Building -e ^Reading
echo ; } ;

_apt_update() {
DEBIAN_FRONTEND=noninteractive apt-get -y update 2>&1 |grep -v -e "Get" -e Hit -e OK: -e Holen: -e ^Building -e ^Reading
echo ; } ;

_oneline() { tr -d '\n' ; } ;

_install_php_ppa() {

  export  LC_ALL=C.UTF-8
    ( _apt_update  &&   apt-get dist-upgrade -y || true &&
    _apt_install  --no-install-recommends  dirmngr software-properties-common || true ) 2>&1 |tr -d '\n'
    grep ondrej/apache2 $(find /etc/apt/sources.list.d/ /etc/apt/sources.list -type f) || LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/apache2
    grep ondrej/php/ubuntu $(find /etc/apt/sources.list.d/ /etc/apt/sources.list -type f) || LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php
    if [ "$(cat /etc/lsb-release|grep DISTRIB_ID=Ubuntu | cat /etc/lsb-release |grep RELEASE=[0-9]|cut -d= -f2|cut -d. -f1)" -eq 18 ];then LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/pkg-gearman ;fi
    #apt-get -y purge  software-properties-common && apt-get autoremove -y --force-yes || true &&
    _do_cleanup_quick
echo ; } ;

_fix_ldconfig_gpg() { # https://askubuntu.com/questions/1065373/apt-update-fails-after-upgrade-to-18-04
  rm /usr/local/lib/{libgcrypt,libassuan,libgp}*
  ldconfig /usr/bin/gpg
echo ; } ;

_remove_unwanted_php_deb() {
    PHPLONGVersion=$(php -r'echo PHP_VERSION;')
    PHPVersion=$(echo $PHPLONGVersion|sed 's/^\([0-9]\+.[0-9]\+\).\+/\1/g');
    echo "removing unwanted php versions"
    removeselector=$(dpkg --get-selections|grep ^php[0-9]|grep -v deinstall|cut -f1|grep -v ^php${PHPVersion})
    [[ -z "${removeselector}" ]] || { echo "removing pkgs:${removeselector}"; apt-get -y remove ${removeselector} ; } ;
    removeselector=$(find /etc/php -mindepth 1 -maxdepth 1 -type d |grep -v ${PHPVersion}$)
    find  $removeselector -delete
echo ; } ;

_build_pecl() {
PACKAGE="$1"
if [ -z "$PACKAGE" ]
then
      echo "PACKAGENAME is empty"
else
    test -d /tmp/pear || mkdir /tmp/pear
    cd /tmp/pear
    find /tmp/pear/ -name "${PACKAGE}*tgz" -print -delete
    pecl download ${PACKAGE}
    tar xvzf $(find /tmp/pear/ -name "${PACKAGE}*tgz")
    find /tmp/pear -type d -name "${PACKAGE}*" && cd $(find /tmp/pear -type d -name "${PACKAGE}*"|tail -n1) && phpize && ./configure && make -j$(nproc) && make install
    for filename in $(find /tmp/pear/${EXTENSION}*/modules/ -name "*.so")  $(find /tmp/pear/ -name "${EXTENSION}.so") $(find /tmp/pear/ -name "${EXTENSION}.la") ;do
       for destination in $(find /usr/lib/php/ -mindepth 1 -type d);do cp -v ${filename} ${destination};done;done
fi
echo ; } ;

_fix_apt_keys() {
	chown root:root /tmp;chmod 1777 /tmp
	apt-get clean; find /var/lib/apt/lists -type f -delete
	( _apt_update 2>&1 ||true) |grep NO_PUBKEY | sed -ne 's/.*NO_PUBKEY //p' | while read key; do
    echo 'Processing key:' "$key"
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys "$key"  2>&1 ; done | tr -d '\n'
    ## _apt_update 2>&1 | sed 's/$/|/g'|tr -d '\n'
    ( apt-get clean &&  find /var/lib/apt/lists -type f -delete ) | sed 's/$/|/g'|tr -d '\n'
    rm /var/cache/ldconfig/aux-cache 2>/dev/null|| true ;/sbin/ldconfig ; ## possible partial fix when buildx fails with error 139 segfault at libc-upgrads ,
    #grep "options single-request timeout:2 attempts:2 ndots:2" /etc/resolv.conf || (echo "options single-request timeout:2 attempts:2 ndots:2" >> /etc/resolv.conf )
    ## resolv.conf unchangeable in docker
    #apt-get -y --reinstall install libc-bin
    #apt-mark hold libc-bin

 echo -n ; } ;
##
_do_cleanup_quick() {
        removeselector=$( dpkg --get-selections|grep -v deinstall$|cut -f1|cut -d" " -f1|grep -e python-software-properties -e software-properties-common -e gcc -e make -e build-essential -e \-dev: -e \-dev$ -e ^texlive-base -e  ^doxygen  -e  ^libllvm   -e ^gcc -e ^g++ -e ^build-essential -e \-dev: -e \-dev$ )
        [[ -z "${removeselector}" ]] || apt-get purge -y ${removeselector} 2>&1 | sed 's/$/|/g'|tr -d '\n'         which apt-get &>/dev/null && apt-get autoremove -y --force-yes 2>&1 | sed 's/$/|/g'|tr -d '\n'
        ( find /tmp/ -mindepth 1 -type f 2>/dev/null |grep -v ^$|xargs rm || true ) &
        ( find /usr/share/doc -type f -delete 2>/dev/null || true &  find  /usr/share/man -type f -delete 2>/dev/null || true  ) &
        wait
        ( apt-get clean &&  find /var/lib/apt/lists -type f -delete ) | sed 's/$/|/g'|tr -d '\n'

echo ; } ;

##########################################


_do_cleanup() {
    ##### remove all packages named *-dev* or *-dev:* (e.g. mylib-dev:amd64 )
    removeselector=$( dpkg --get-selections|grep -v deinstall$|cut -f1|cut -d" " -f1|grep -e python-software-properties -e software-properties-common -e gcc -e make -e build-essential -e \-dev: -e \-dev$ -e ^texlive-base -e  ^doxygen  -e  ^libllvm  -e ^gcc -e ^g++ -e ^build-essential -e \-dev: -e \-dev$ )
    [[ -z "${removeselector}" ]] || apt-get purge -y ${removeselector} 2>&1 | sed 's/$/|/g'|tr -d '\n'
    ##remove ssh host keys
    for keyz in /etc/dropbear/dropbear_dss_host_key /etc/dropbear/dropbear_rsa_host_key /etc/dropbear/dropbear_ecdsa_host_key ;do test -f $keyz && rm $keyz;done

    ##remove package manager caches
    (which apt-get 2>/dev/null && apt-get autoremove -y --force-yes &&  apt-get clean && find -name "/var/lib/apt/lists/*_*" -delete )| sed 's/$/|/g'|tr -d '\n'

    ## remove all the rest
    for deleteme in     /var/cache/man     /usr/share/texmf/ /usr/local/share/doc /usr/share/doc /usr/share/man  ;do
        ( find ${deleteme} -type f -delete 2>/dev/null || true ; find ${deleteme} -mindepth 1 -delete 2>/dev/null || true  ) &
    done
    ( find /tmp/ -mindepth 1 -type f 2>/dev/null |wc -l |grep -v ^0$ && find /tmp/ -mindepth 1 -type d 2>/dev/null |xargs rm  -rf || true  ) &
    wait
echo ; } ;

#################################
apt-install-depends() {
    local pkg="$1"
    apt-get install -s "$pkg" \
      | sed -n \
        -e "/^Inst $pkg /d" \
        -e 's/^Inst \([^ ]\+\) .*$/\1/p' \
      | xargs apt-get install
echo ; } ;
##################################


_install_dropbear() {
    echo -n "::DROBEAR INSTALL:APT:"
    ## check if the already installed dropbear has "disable-weak-ciphers" support
    dropbear --help 2>&1 |grep -q ed255 ||  ( echo "re-installing dropbear from git "
    _apt_update && _apt_install build-essential git zlib1g-dev gcc make autoconf libc-dev pkg-config || exit 111
        cd /tmp/ &&  git clone https://github.com/mkj/dropbear.git && cd dropbear && autoconf  &&  autoheader  && ./configure |sed 's/$/ → /g'|tr -d '\n'  &&    make PROGRAMS="dropbear dbclient dropbearkey dropbearconvert " -j$(nproc)  &&  make install || exit 222
        rm -rf /tmp/dropbear 2>/dev/null || true
        apt-get -y purge build-essential zlib1g-dev gcc make autoconf libc-dev pkg-config 2>&1 | sed 's/$/|/g'|tr -d '\n'
    ) | _oneline
  _do_cleanup
 echo ; } ;

_install_imagick() {

## IMAGICK WEBP

    ## since using convert  shall still be possible , we need imagemagick
    which identify &>/dev/null || ( _apt_update  &>/dev/null && apt-get -y --no-install-recommends install imagemagick 2>&1  ) |sed 's/$/|/g'|tr -d '\n'
    build_imagick=false
    # $( apt-cache search imagick  |grep -v deinstall|grep php-imagick |cut -d" " -f1 |cut -f1|grep php-imagick  )
    identify --version|grep webp || build_imagick=true
    echo "build_imagick (webp-cli) is ${build_imagick}"
    if [ "${build_imagick}" = "true" ] ;then
    echo "building imagick"
    ( _apt_update && _apt_install wget libmagickwand-dev libmagickcore-dev ) | sed 's/$/|/g'|tr -d '\n'
    (apt-get -y purge imagemagick 2>&1 ;apt-get -y autoremove)| sed 's/$/|/g'|tr -d '\n'
    ## IMagick with WEBP libwebp
    WEBPARCHIVE=$(wget -O- https://storage.googleapis.com/downloads.webmproject.org/releases/webp/index.html|grep "href"|sed 's/.\+\<a href="\/\///g'|cut -d\" -f1|grep libwebp-[0-9]|grep tar.gz|grep [0-9].tar.gz$|grep -v -e mac -e linux -e rc1 -e rc2 -e rc3 -e rc4 -e rc5 |tail -n1)
    echo ":Building:libwebp: FROM"  "${WEBPARCHIVE}"
    sed -i '/deb-src/s/^# //' /etc/apt/sources.list && apt update && apt-get -y build-dep imagemagick && _apt_install wget build-essential gcc make autoconf libc-dev pkg-config libjpeg-dev libpng-dev && cd /tmp/ && wget -q -c -O- "${WEBPARCHIVE}" | tar xvz || exit 111
    ### IMAGICK
    apt-get -y build-dep imagemagick && cd /tmp/ && wget https://imagemagick.org/download/ImageMagick.tar.gz && tar xvzf ImageMagick.tar.gz|| exit 222
    /bin/bash -c 'cd $(find /tmp/ -type d -name "ImageMagick-*" |head -n1) && ./configure  --with-webp=yes '"|sed 's/$/ → /g'|tr -d '\n' "' && make -j$(nproc) && make install && ldconfig /usr/local/lib &&  ( find /tmp/ -name "ImageMagic*" |xargs rm -rf  )'
    _apt_install  netpbm $(apt-cache search libopenexr|grep ^libopenexr[0-9]|cut -d" " -f1|grep [0-9]$)  $(apt-cache search libfftw|grep ^libfftw[0-9]|cut -d" " -f1|grep bin$)  $(apt-cache search liblqr|grep ^liblqr|cut -d" " -f1|grep -v 'dev')  $(apt-cache search libgomp|grep ^libgomp[0-9]|cut -d" " -f1|grep -v '-') libwmf-bin $(apt-cache search libdjvul|grep ^libdjvulibre[0-9]|cut -d" " -f1) 2>&1 | sed 's/$/|/g'|tr -d '\n'
    ( apt-get -y  purge build-essential gcc make autoconf libc-dev pkg-config || true ) | sed 's/$/|/g'|tr -d '\n'
    _do_cleanup
    fi

    ###to verify if imagick has all shared libs :
    #identify -version || exit 222



###### PHP IMAGICK
    PHPLONGVersion=$(php -r'echo PHP_VERSION;')
    PHPVersion=$(echo $PHPLONGVersion|sed 's/^\([0-9]\+.[0-9]\+\).\+/\1/g');
    if [ "$(cat /etc/lsb-release|grep DISTRIB_ID=Ubuntu |cat /etc/lsb-release |grep RELEASE=[0-9]|cut -d= -f2|cut -d. -f1)" -ge 20 ];then ## ubuntu focal and up have php-imagick webp support
        _apt_update && _apt_install  php${PHPVersion}-imagick;
    fi | _oneline
    php -r 'phpinfo();'|grep  ^ImageMagick|grep WEBP -q || { build_php_imagick=true ; apt-get remove php${PHPVersion}-imagick ; } ;
    echo "build_php_imagick (webp) is ${build_imagick}"
    if [ "${build_php_imagick}" = "true" ] ;then
        ##PHP-imagick
        sed -i '/deb-src/s/^# //' /etc/apt/sources.list
        _apt_update 2>&1 | _oneline
        apt-get purge -y php-imagick  2>&1 | _oneline
        apt-get -y  install build-essential   php${PHPVersion}-dev pkg-config  $(apt-cache search libfreetype dev|cut -f1|cut -d" " -f1 |grep "libfreetype.*dev")
        apt-get -y build-dep imagemagick
        #echo |pecl install imagick
        _build_pecl imagick && echo extension=imagick.so > /etc/php/${PHPVersion}/mods-available/imagick.ini && mkdir /etc/php/${PHPVersion}/imagick.so/conf.d && phpenmod imagick
        #/bin/bash -c 'find /etc/php -type d -name "conf.d"  | while read phpconfdir ;do echo extension=imagick.so > $phpconfdir/20-imagick.ini;done' || true &
        #apt-get -y  purge build-essential gcc make autoconf libmagickwand-dev php${PHPVersion}-dev libjpeg-dev libpng-dev libwebp-dev || true
        apt-get -y  purge build-essential gcc make autoconf php${PHPVersion}-dev libc-dev pkg-config | sed 's/$/|/g'|tr -d '\n' || true
        apt-get -y autoremove 2>&1 | sed 's/$/|/g'|tr -d '\n' || true
#        cd /tmp/ && wget https://pecl.php.net/get/imagick-3.4.3.tgz -O- -q |tar xvz && cd /tmp/imagick-3.4.3/  && phpize && ./configure && make -j $(nproc) && make -j3 install || exit 333
         _apt_install  netpbm $(apt-cache search libopenexr|grep ^libopenexr[0-9]|cut -d" " -f1|grep [0-9]$)  $(apt-cache search libfftw|grep ^libfftw[0-9]|cut -d" " -f1|grep bin$)  $(apt-cache search liblqr|grep ^liblqr|cut -d" " -f1|grep -v 'dev')  $(apt-cache search libgomp|grep ^libgomp[0-9]|cut -d" " -f1|grep -v '-') libwmf-bin $(apt-cache search libdjvul|grep ^libdjvulibre[0-9]|cut -d" " -f1) 2>&1 | sed 's/$/|/g'|tr -d '\n'
    fi

    ## CLEAN build stage
    find /tmp/ -type d -name "lilbwebp*"   |wc -l |grep -v ^0$ && find /tmp/ -type d -name "lilbwebp*"    |xargs rm -rf || true &
    find /tmp/ -type d -name "ImageMagick*"|wc -l |grep -v ^0$ && find /tmp/ -type d -name "ImageMagick*" |xargs rm -rf || true &
    find /tmp/ -type d -name "imagick*"    |wc -l |grep -v ^0$ && find /tmp/ -type d -name "imagick*"     |xargs rm -rf || true &

    echo "TESTING IMAGEMAGICK WEBP";
    php -r 'phpinfo();'|grep  ^ImageMagick|grep WEBP -q || { echo "php imagick webp failed" ; exit 444 ; } ;
    _do_cleanup

        echo ; } ;

_install_php_nofpm() {
        _install_php_basic ;
        PHPLONGVersion=$(php -r'echo PHP_VERSION;')
         PHPVersion=$(echo $PHPLONGVersion|sed 's/^\([0-9]\+.[0-9]\+\).\+/\1/g');
        ( _apt_update && _apt_install  libapache2-mod-php${PHPVersion} ) | sed 's/$/|/g'|tr -d '\n'
    _remove_unwanted_php_deb
    _do_cleanup_quick
    echo ; } ;

_install_php_fpm() {

        PHPLONGVersion=$(php -r'echo PHP_VERSION;')
        PHPVersion=$(echo $PHPLONGVersion|sed 's/^\([0-9]\+.[0-9]\+\).\+/\1/g');
        echo "php-fpm installer detected php "$PHPLONGVersion" and short version "$PHPVersion
        _install_php_basic ;
        echo "+fpm"
        ( apt-get -y --no-install-recommends  install php${PHPVersion}-fpm ) | sed 's/$/|/g'|tr -d '\n'
        uname -m |grep -q aarch64 && cd /tmp && wget https://launchpad.net/~ondrej/+archive/ubuntu/apache2/+build/9629365/+files/libapache2-mod-fastcgi_2.4.7~0910052141-1.2+deb.sury.org~trusty+3_arm64.deb && dpkg -i "libapache2-mod-fastcgi_2.4.7~0910052141-1.2+deb.sury.org~trusty+3_arm64.deb" &&  apt install -f && a2enmod fastcgi && rm "/tmp/libapache2-mod-fastcgi_2.4.7~0910052141-1.2+deb.sury.org~trusty+3_arm64.deb"
        uname -m |grep -q x86_64  && cd /tmp && wget http://mirrors.kernel.org/ubuntu/pool/multiverse/liba/libapache-mod-fastcgi/libapache2-mod-fastcgi_2.4.7~0910052141-1.2_amd64.deb && dpkg -i libapache2-mod-fastcgi_2.4.7~0910052141-1.2_amd64.deb &&  apt install -f && a2enmod fastcgi && rm /tmp/libapache2-mod-fastcgi_2.4.7~0910052141-1.2_amd64.deb
        ## since the libapache2-mod-fastcgi package is available from ppa the next step will upgrade it
        _apt_update && _apt_install fcgiwrap apache2-utils php${PHPVersion}-fpm php${PHPVersion}-common php${PHP_VERSION}-pear php${PHP_VERSION}-intl libapache2-mod-fastcgi
        (mkdir -p /etc/php/${PHPVersion}/cli/conf.d /etc/php/${PHPVersion}/fpm/conf.d /etc/php/${PHPVersion}/apache2/conf.d ;true)
        ln -s /run/php/php${PHPVersion}-fpm.sock /run/php/php-fpm.sock
        echo "fpm mod"
        _modify_apache_fpm
        _remove_unwanted_php_deb
    _do_cleanup_quick

    echo ; } ;


_install_php_basic() {
    _apt_update && _apt_install apt-transport-https lsb-release ca-certificates curl  && curl https://packages.sury.org/php/apt.gpg | apt-key add -
       _do_cleanup_quick
        #get latest composer
        curl -sS https://getcomposer.org/installer -o /tmp/composer.installer.php && php /tmp/composer.installer.php --install-dir=/usr/local/bin --filename=composer && rm /tmp/composer.installer.php
        which composer || { echo no composer binary ; exit 309 ; } ;
        #####following step is preferred in compose file
        #_apt_update  &&  apt-get dist-upgrade -y &&  _apt_install software-properties-common && LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php
        PHPLONGVersion=$(php -r'echo PHP_VERSION;')
        PHPVersion=$(echo $PHPLONGVersion|sed 's/^\([0-9]\+.[0-9]\+\).\+/\1/g');
        echo "php-basics installer detected php "$PHPLONGVersion" and short version "$PHPVersion
        [[ -z "$PHPVersion" ]] && { echo "$PHPVersion empty..quitting ";exit 949 ; } ;
        apt-key update
        (mkdir -p /etc/php/${PHPVersion}/cli/conf.d /etc/php/${PHPVersion}/fpm/conf.d /etc/php/${PHPVersion}/apache2/conf.d ;true)
        ## ATT: php-imagick has no webp (2020-03) , but is installed here since the imagick install step above builds from source and purges it before
        _apt_update && _apt_install --no-install-recommends  php${PHPVersion}-intl php${PHPVersion}-pear \
        $( apt-cache search apcu  |grep -v deinstall|grep -e php${PHPVersion}-apcu -e php-apcu|cut -d" " -f1 |cut -f1|grep -e  php${PHPVersion}-apcu -e php-apcu |sort -r |head -n1 ) \
        $( apt-cache search xdebug  |grep -v deinstall|grep php${PHPVersion}-xdebug |cut -d" " -f1 |cut -f1|grep php${PHPVersion}-xdebug  ) \
        php${PHPVersion}-xmlrpc php-gnupg php${PHPVersion}-opcache php${PHPVersion}-mysql php${PHPVersion}-pgsql php${PHPVersion}-sqlite3 \
        php${PHPVersion}-xml php${PHPVersion}-xsl php${PHPVersion}-zip php${PHPVersion}-soap php${PHPVersion}-curl php${PHPVersion}-bcmath \
        php${PHPVersion}-mbstring php${PHPVersion}-json php${PHPVersion}-gd php${PHPVersion}-ldap php${PHPVersion}-imap php${PHPVersion}-dev || exit 111

#####        $( apt-cache search imagick  |grep -v deinstall|grep php-imagick |cut -d" " -f1 |cut -f1|grep php-imagick  ) \


        #_apt_install --no-install-recommends
        echo "getting build dependencies"
        apt-get -y --no-install-recommends install gcc make autoconf ssl-cert libc-dev pkg-config libc-dev pkg-config zlib1g-dev gcc make autoconf libc-dev php-pear pkg-config libmcrypt-dev php${PHPVersion}-dev
        echo "updating pecl channel"
        pecl channel-update pecl.php.net
        ##php-memcached
        apt-get install libmemcached-dev php${PHPVersion}-dev  libmemcached-tools  $( apt-cache search memcached  |grep -v deinstall|grep libmemcached|cut -d" " -f1 |cut -f1|grep libmemcached|grep -v -e dbg$ -e dev$ -e memcachedutil -e perl$) $( apt-cache search libmcrypt dev  |grep -v deinstall|cut -d" " -f1 |cut -f1|grep libmcrypt-dev)

        ## php modules folder
        test -d /etcecho -n "::pre-installer called with:: "$1 "::"
/php/${PHPVersion}/mods-available || mkdir /etc/php/${PHPVersion}/mods-available  ||true

#######	/bin/bash -c '(sleep 0.5 ; echo "no --disable-memcached-sasl" ;yes  "") | (pecl install -f memcached ;true); find /etc/php -type d -name "conf.d"  | while read phpconfdir ;do echo extension=memcached.so > $phpconfdir/memcached.ini;done'
#        /bin/bash -c ' ( mkdir /tmp/pear ; curl https://pecl.php.net/$(curl https://pecl.php.net/package/memcached|grep tgz|grep memcached|grep get|cut -d/ -f2-|cut -d\" -f1|head -n1) > /tmp/pear/memcached.tgz && ( (sleep 0.2 ; echo "no --disable-memcached-sasl" ;yes  "") | pecl install /tmp/pear/memcached.tgz  &&  ( find /etc/php -type d -name "conf.d"  | while read phpconfdir ;do ls -1 $phpconfdir|grep memcached ||echo extension=memcached.so > $phpconfdir/20-memcached.ini ;done ) ) ; rm /tmp/pear/memcached.tgz  ;true);'
        ## PHP GNUPG
        phpenmod gnupg
        ## PHP MEMCACHED IF MISSING FROM REPO
        #php -r 'phpinfo();'|grep  memcached -q ||  (echo |pecl install memcached ;test -d /etc/php/${PHPVersion}/mods-available || mkdir /etc/php/${PHPVersion}/mods-available && bash -c "echo extension="$(find /usr/lib/php/ -name "memcached.so" |head -n1) |tee /etc/php/${PHPVersion}/mods-available/memcached.ini ;phpenmod memcached  )

        ## memcached/redis is built with specials for php5.6
        if [ "${PHPVersion}" = "5.6"  ] ;then
          _apt_update && apt-get -y --no-install-recommends install gcc make autoconf libc-dev pkg-config zlib1g-dev libmemcached-dev php5.6-dev &&  \
          cd /tmp && wget -c "https://github.com/msgpack/msgpack-php/archive/msgpack-0.5.7.tar.gz" && tar xvzf msgpack-0.5.7.tar.gz && cd msgpack-php-msgpack-0.5.7 && \
          phpize && ./configure --with-php-config=$(which php-config) && make && make install &&  /bin/bash -c '(sleep 2 ; echo "no --disable-memcached-sasl" ;yes  "") | (pecl install -f memcached-2.2.0 && ( bash -c "echo extension=$(find /usr/lib/php/ -name "memcached.so" |head -n1) |tee /etc/php/'${PHPVersion}'/mods-available/memcached.ini ";phpenmod memcached ) );rm -rf /tmp/msgpack-php-msgpack-0.5.7 /tmp/msgpack-0.5.7.tar.gz'
          _apt_update && _apt_install curl php${PHPVersion}-dev && /bin/bash -c 'mkdir /tmp/pear || true && curl https://pecl.php.net/get/redis-4.3.0.tgz > /tmp/pear/redis.tgz && pecl install /tmp/pear/redis.tgz ' && echo extension=redis.so > /etc/php/${PHPVersion}/mods-available/redis.ini && phpenmod redis
        else
          php -r 'phpinfo();' |grep  memcached -q ||  (
                                     _build_pecl memcached && bash -c "echo extension="$(find /usr/lib/php/ -name "memcached.so" |head -n1) |tee /etc/php/${PHPVersion}/mods-available/memcached.ini ;
          grep extension= /etc/php/${PHPVersion}/mods-available/memcached.ini && mkdir /etc/php/${PHPVersion}/memcached.so/conf.d  phpenmod memcached  )  &
          #		_apt_update && _apt_install curl php${PHPVersion}-dev && /bin/bash -c 'echo |pecl install redis' && echo extension=redis.so > /etc/php/${PHPVersion}/mods-available/redis.ini && phpenmod redis
          #_apt_update && _apt_install curl php${PHPVersion}-dev && /bin/bash -c 'mkdir /tmp/pear || true && curl https://pecl.php.net/$(curl https://pecl.php.net/package/redis|grep tgz|grep redis|grep get|cut -d/ -f2-|cut -d\" -f1|head -n1) > /tmp/pear/redis.tgz && pecl install /tmp/pear/redis.tgz ' && echo extension=redis.so > /etc/php/${PHPVersion}/mods-available/redis.ini && phpenmod redis
          #rm /tmp/pear/redis.tgz || true
          _build_pecl redis && echo extension=redis.so > /etc/php/${PHPVersion}/mods-available/redis.ini && mkdir /etc/php/${PHPVersion}/redis.so/conf.d && phpenmod redis
        fi
        ## PHP XDEBUG IF MISSING FROM REPO
        php -r 'phpinfo();' |grep  xdebug -q    || ( _apt_install gcc &&  _build_pecl xdebug && bash -c "echo extension="$(find /usr/lib/php/ -name "xdebug.so" |head -n1) |tee /etc/php/${PHPVersion}/mods-available/xdebug.ini ) & ### do not activate by default ( phpenmod xdebug )
        ##PHP apcu IF MISSING FROM REPO
        php -r 'phpinfo();' |grep    apcu -q    || (_build_pecl apcu && bash -c "echo extension="$(find /usr/lib/php/ -name "apcu.so" |head -n1) |tee /etc/php/${PHPVersion}/mods-available/apcu.ini ; phpenmod apcu || true  ) &
        ##PHP IMAGICK IF MISSING FROM REPO
        php -r 'phpinfo();' |grep  ^ImageMagick -q || _install_imagick
        wait

        ###mcrypt
        ### make the version string an integer for comparations
        if [ "$(echo "$PHPVersion"|awk -F  "." '{printf("%3d%0d",$1,$2*10)}')" -ge $(echo "7.2"|awk -F  "." '{printf("%3d%0d",$1,$2*10)}') ]; then
         echo "PHP Version does not build MCRYPT,deprecated in php7.2"
        else
         echo INSTALL php-mcrypt && pecl channel-update pecl.php.net && pecl install mcrypt-1.0.2
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
        apt-get -y remove gcc make autoconf libc-dev pkg-config libmcrypt-dev php${PHPVersion}-dev

### catch build errors with binary packages
 php -r 'phpinfo();' |grep  memcached -q ||  _apt_install php$($PHPVersion)-memcached ||true
 php -r 'phpinfo();' |grep  redis -q ||  _apt_install php$($PHPVersion)-redis ||true
 phpenmod redis||true
 phpenmod memcached||true


        ( apt-get autoremove -y --force-yes &&  apt-get clean &&   find /var/lib/apt/lists -type f -delete  ) | sed 's/$/|/g'|tr -d '\n'

    _remove_unwanted_php_deb
    _do_cleanup_quick
    echo FINISHED INSTALLER FOR PHP ${PHPVersion}
echo ; } ;

##########################################
_modify_apache_fpm() {
    PHPLONGVersion=$(php -r'echo PHP_VERSION;')
    PHPVersion=$(echecho -n "::pre-installer called with:: "$1 "::"
o $PHPLONGVersion|sed 's/^\([0-9]\+.[0-9]\+\).\+/\1/g');
    _apt_update && apt-get install apache2
    echo -n FPM APACHE ENABLE MODULES:
    a2dismod php${PHPVersion} || true && a2dismod  mpm_prefork mpm_worker && a2enmod headers actions alias setenvif proxy ssl proxy_http remoteip rewrite expires proxy_wstunnel || true
    echo -n WSTUN
    a2enmod proxy_wstunnel || true
    echo -n PROXY_FCGI a2enmod proxy_fcgi || true
    ## SELECT mpm_prefork ## only libapache-mod-php
    a2dismod mpm_event mpm_worker && a2enmod mpm_prefork
    ## SELECT mpm_event ## only FPM
    a2dismod mpm_prefork mpm_worker && a2enmod mpm_event
echo -n ; } ;

_modify_apache() {
    uname -m |grep -q aarch64 && cd /tmp && wget https://launchpad.net/~ondrej/+archive/ubuntu/apache2/+build/9629365/+files/libapache2-mod-fastcgi_2.4.7~0910052141-1.2+deb.sury.org~trusty+3_arm64.deb && dpkg -i "libapache2-mod-fastcgi_2.4.7~0910052141-1.2+deb.sury.org~trusty+3_arm64.deb" &&  apt install -f && a2enmod fastcgi && rm "/tmp/libapache2-mod-fastcgi_2.4.7~0910052141-1.2+deb.sury.org~trusty+3_arm64.deb"
    uname -m |grep -q x86_64  && cd /tmp && wget http://mirrors.kernel.org/ubuntu/pool/multiverse/liba/libapache-mod-fastcgi/libapache2-mod-fastcgi_2.4.7~0910052141-1.2_amd64.deb && dpkg -i libapache2-mod-fastcgi_2.4.7~0910052141-1.2_amd64.deb &&  apt install -f && a2enmod fastcgi && rm /tmp/libapache2-mod-fastcgi_2.4.7~0910052141-1.2_amd64.deb
    apt install -y apache2 libapache2-mod-fastcgi apache2-utils
    dpkg --configure -a || true

    echo "|align docroot to /var/www/html"
    sed 's/DocumentRoot \/var\/www$/DocumentRoot \/var\/www\/html/g' /etc/apache2/sites-enabled/* -i
    ##log other vhosts to access.log
    test -f /etc/apache2/conf-enabled/other-vhosts-access-log.conf && sed 's/other_vhosts_access.log/access.log/g' -i /etc/apache2/conf-enabled/other-vhosts-access-log.conf


    echo -n  '|RECTIFY APACHE CONFIG -> general php-fpm.sock , log remoteip/X-Forwarded-For  ## enable php execution'
    #sed 's/\/VirtualHost/Directory "\/var\/www">\n     Options -Indexes +IncludesNOEXEC +SymLinksIfOwnerMatch\n    AllowOverride All\n    AddType application\/x-httpd-php .htm .html .php5 #.php4\n     AddHandler application\/x-httpd-php .html .htm .php5 #.php4\n<\/Directory>\n<\/VirtualHost/g;s/ErrorLog.\+//g;s/CustomLog.\+/LogFormat "%h %l %u %t \\"%r\\" %>s %b \\"%{Referer}i\\" \\"%{User-Agent}i\\"" combined\n              LogFormat "%{X-Forwarded-For}i %l %u %t \\"%r\\" %>s\\"%{Referer}i\\" \\"%{User-Agent}i\\"" proxy          \n              SetEnvIf X-Forwarded-For "^.*\\..*\\..*\\..*" forwarded\n              ErrorLog ${APACHE_LOG_DIR}\/error.log\n              CustomLog ${APACHE_LOG_DIR}\/access.log combined env=!forwarded \n              CustomLog ${APACHE_LOG_DIR}\/access.log proxy env=forwarded\n/g' -i /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-available/000-default.conf && \
    sed 's/\/VirtualHost/Directory "\/var\/www">\n     Options -Indexes +IncludesNOEXEC +SymLinksIfOwnerMatch\n    AllowOverride All\n    AddType application\/x-httpd-php .htm .html .php5 #.php4\n     AddHandler application\/x-httpd-php .html .htm .php5 #.php4\n<\/Directory>\n     php_admin_value error_log ${APACHE_LOG_DIR}\/php.error.log\n      php_value include_path .:\/var\/www\/\include_local:\/var\/www\/include\n     <\/VirtualHost/g;s/ErrorLog.\+//g;s/CustomLog.\+/LogFormat "%h%u %t \\"%r\\" %>s %b \\"%{Referer}i\\" \\"%{User-Agent}i\\"" combined\n              LogFormat "%{X-Forwarded-For}i %l %u %t \\"%r\\" %>s %b \\"%{Referer}i\\" \\"%{User-Agent}i\\"" proxy          \n              SetEnvIf X-Forwarded-For "^.*\\..*\\..*\\..*" forwarded\n              ErrorLog ${APACHE_LOG_DIR}\/error.log\n              CustomLog ${APACHE_LOG_DIR}\/access.log combined env=!forwarded \n              CustomLog ${APACHE_LOG_DIR}\/access.log proxy env=forwarded\n/gsocket \/var\/run\/php\/php.*fpm.*\.sock/-socket \/var\/run\/php\/php-fpm.sock/g' -i /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-available/000-default.conf
    cp -aurv /etc/apache2/sites-available/ /etc/apache2/sites-available.default ;
    ln -sf /etc/apache2/sites-available/* /etc/apache2/sites-enabled/

    echo -n "|disable catchall document root:"
    sed 's/.\+DocumentRoot.\+//g' -i /etc/apache2/apache2.conf
    ##fixx www-data userid and only enable sftp for them (bind mount /etc/shells and run "usermod -s /bin/bash www-data" for www-data user login )


  ##set max input vars and exec time for fpm/apache2
  [[ -z PHP_MAX_INPUT_VARS ]] && sed "s/^;max_input_vars/max_input_vars/g;s/max_input_vars.\+/max_input_vars = 8192/g"
  [[ -z PHP_MAX_INPUT_VARS ]] || sed "s/^;max_input_vars/max_input_vars/g;s/max_input_vars.\+/max_input_vars = "${PHP_MAX_INPUT_VARS}"/g"
  [[ -z PHP_EXECUTION_TIME ]] && sed "s/max_execution_time.\+/max_execution_time = 1800/g" $(find $(ls -1d /etc/php*) -name php.ini|grep -e apache -e fpm) -i
  [[ -z PHP_EXECUTION_TIME ]] || sed "s/max_execution_time.\+/max_execution_time = "${PHP_EXECUTION_TIME}"/g" $(find $(ls -1d /etc/php*) -name php.ini|grep -e apache -e fpm) -i



    ##ENABLE SITES
    a2ensite default-ssl && a2ensite 000-default && ls -lh /etc/apache2/sites*/*
    _modify_apache_fpm
    _do_cleanup_quick
    echo ; } ;

###########################################
_install_mariadb_ubuntu() {

            ## $2 is MARIADB version $3 ubuntu version as $1 is mariadb passed from main script
            _apt_update && _apt_install gpg-agent dirmngr  $(apt-cache search sofware-properties-common|grep sofware-properties-common|cut -d" " -f1|grep sofware-properties-common)  $(apt-cache search python-software-properties|grep python-software-properties|cut -d" " -f1|grep python-software-properties)
            apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8 || exit 111
            echo "DOING "LC_ALL=C.UTF-8 add-apt-repository 'deb [arch=amd64,arm64,ppc64el] http://mirrors.n-ix.net/mariadb/repo/'$2'/ubuntu '$3' main'
            LC_ALL=C.UTF-8 add-apt-repository 'deb [arch=amd64,arm64,ppc64el] http://mirrors.n-ix.net/mariadb/repo/'$2'/ubuntu '$3' main'
            _apt_update && DEBIAN_FRONTEND=noninteractive	_apt_install mariadb-server mariadb-client
            apt-get purge gnupg dirmngr $(apt-cache search sofware-properties-common|grep sofware-properties-common|cut -d" " -f1|grep sofware-properties-common)  $(apt-cache search python-software-properties|grep python-software-properties|cut -d" " -f1|grep python-software-properties)
            ( which apt-get 2>/dev/null && apt-get autoremove -y --force-yes &&  apt-get clean &&  find /var/lib/apt/lists -type f -delete ) | sed 's/$/|/g'|tr -d '\n'
        _do_cleanup_quick ;
            echo ; } ;

_setup_wwwdata() {
    PHPLONGVersion=$(php -r'echo PHP_VERSION;')
    PHPVersion=$(echo $PHPLONGVersion|sed 's/^\([0-9]\+.[0-9]\+\).\+/\1/g');
      sed 's/^www-data:x:1000/www-data:x:33/g' /etc/passwd -i
      usermod -s /usr/lib/openssh/sftp-server www-data && echo /usr/lib/openssh/sftp-server >> /etc/shells

      ##userdirs
      ln -s /var/www/html /root/ &&  mkdir -p /var/www/.ssh /var/www/include /var/www/include_local && chown www-data /var/www/ -R && mkdir /root/.ssh && touch /root/.ssh/authorized_keys
      touch /var/www/.ssh/authorized_keys && chown root:root /var/www/.ssh /var/www/.ssh/authorized_keys && chmod go-rw  /root/.ssh/authorized_keys /root/.ssh /var/www/.ssh /var/www/.ssh/authorized_keys
        ## CREATE possible php socket folder and insert fpm service into non-supervisord section of init script
        /bin/mkdir -p /var/run/php/ || true && chown www-data:www-data /var/run/php/
        which php-fpm && sed 's/service cron start/service php'${PHPVersion}'-fpm start \&\nservice cron start/g' /usr/local/bin/run.sh -i
        ##copied in dockerfile
        mv /root/www.conf /etc/php/${PHPVersion}/fpm/pool.d/www.conf
        echo ; } ;


_install_util() {
    _apt_update && apt-get -y --no-install-recommends install ssl-cert inotify-tools mariadb-client lftp iputils-ping less byobu net-tools lsof iotop iftop sysstat atop nmon netcat unzip socat
    _do_cleanup_quick
    echo ; } ;


    echo -n "::pre-installer called with:: "$1 "::"

case $1 in
  php-ppa|phppa) _install_php_ppa_ubuntu "$@" ;;
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
  debiansetup) _basic_setup_debian "$@" ;;
esac

exit 0
