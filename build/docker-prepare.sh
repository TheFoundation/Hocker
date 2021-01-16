#!/bin/bash

for need in wget curl apt-transport-https ;do
which apt-get &>/dev/null && which ${need} &>/dev/null || { apt-get update 1>/dev/null && apt-get install -y --no-install-recommends ${need} ; };
done
_oneline() { tr -d '\n' ; } ;

_install_php_ppa() {

export  LC_ALL=C.UTF-8
    apt-get update >/dev/null &&   apt-get dist-upgrade -y || true &&
    apt-get install -y  --no-install-recommends  dirmngr software-properties-common || true
    grep ondrej/apache2 $(find /etc/apt/sources.list.d/ /etc/apt/sources.list -type f) || LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/apache2
    grep ondrej/php/ubuntu $(find /etc/apt/sources.list.d/ /etc/apt/sources.list -type f) || LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php
    bin/bash -c 'if [ "$(cat /etc/lsb-release |grep RELEASE=[0-9]|cut -d= -f2|cut -d. -f1)" -eq 18 ];then LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/pkg-gearman ;fi'|true
    apt-get -y purge  software-properties-common && apt-get autoremove -y --force-yes || true && _do_cleanup
echo ; } ;

_fix_ldconfig_gpg() { # https://askubuntu.com/questions/1065373/apt-update-fails-after-upgrade-to-18-04
  rm /usr/local/lib/{libgcrypt,libassuan,libgp}*
  ldconfig /usr/bin/gpg
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
	(apt-get update 2>&1 1>/dev/null||true)  | sed -ne 's/.*NO_PUBKEY //p' | while read key; do
        echo 'Processing key:' "$key"
        apt-key adv --keyserver keyserver.ubuntu.com --recv-keys "$key"; done ;
        ## apt-get update 2>&1 | sed 's/$/|/g'|tr -d '\n'
        ( apt-get clean &&  find /var/lib/apt/lists -type f -delete ) | sed 's/$/|/g'|tr -d '\n'
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
         ( apt-get clean &&  find /var/lib/apt/lists -type f -delete ) | sed 's/$/|/g'|tr -d '\n'

         echo ; } ;

##########################################


_do_cleanup() {
    ##### remove all packages named *-dev* or *-dev:* (e.g. mylib-dev:amd64 )
    apt-get purge -y build-essential $( dpkg --get-selections|grep -v deinstall$|cut -f1|cut -d" " -f1|grep -e python-software-properties -e software-properties-common) gcc make $( dpkg --get-selections|grep -v deinstall$|cut -f1|cut -d" " -f1|grep  -e \-dev: -e \-dev$ ) 2>&1 | sed 's/$/|/g'|tr -d '\n'
    apt-get -y autoremove 2>&1 | sed 's/$/|/g'|tr -d '\n'

    ##remove ssh host keys
    for keyz in /etc/dropbear/dropbear_dss_host_key /etc/dropbear/dropbear_rsa_host_key /etc/dropbear/dropbear_ecdsa_host_key ;do test -f $keyz && rm $keyz;done

    ##remove package manager caches
    which apt-get 2>/dev/null && apt-get autoremove -y --force-yes &&  apt-get clean && find -name "/var/lib/apt/lists/*_*" -delete

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


_install_util() {
    apt-get update && apt-get -y --no-install-recommends install ssl-cert inotify-tools mariadb-client lftp iputils-ping less byobu net-tools lsof iotop iftop sysstat atop nmon netcat unzip socat
    _do_cleanup_quick
    echo ; } ;

  _install_dropbear() {
        echo -n "::DROBEAR INSTALL:APT:"
        ## check if the already installed dropbear has "disable-weak-ciphers" support
        dropbear --help 2>&1 |grep -q ed255 ||  ( echo "re-installing dropbear from git "
        _apt-update && _apt_install build-essential git zlib1g-dev gcc make autoconf libc-dev pkg-config || exit 111
            cd /tmp/ &&  git clone https://github.com/mkj/dropbear.git && cd dropbear && autoconf  &&  autoheader  && ./configure |sed 's/$/ → /g'|tr -d '\n'  &&    make PROGRAMS="dropbear dbclient dropbearkey dropbearconvert " -j$(nproc)  &&  make install || exit 222
            rm -rf /tmp/dropbear 2>/dev/null || true
            apt-get -y purge build-essential zlib1g-dev gcc make autoconf libc-dev pkg-config 2>&1 | sed 's/$/|/g'|tr -d '\n'
        ) | _oneline
      _do_cleanup
     echo ; } ;

     _basic_setup_debian() {
        echo "basic setup debian"
         _apt_update  && apt-get dist-upgrade -y &&  \
         _apt_install --no-install-recommends apache2-utils \
         zip tar openssh-sftp-server supervisor wget curl ca-certificates rsync nano \
         vim psmisc procps git curl  cron   msmtp msmtp-mta &&  \
         apt-get autoremove -y --force-yes | sed 's/$/|/g'|tr -d '\n'
         #which dropbear |grep -q dropbear || apt-get install dropbear-bin dropbear-run
         which dropbear |grep -q dropbear || _install_dropbear
         dpkg-divert /usr/sbin/sendmail
         _apt_install locales | sed 's/$/|/g'|tr -d '\n'
         locale-gen de_DE.UTF-8 en_US.UTF-8 en_US.UTF-8 es_ES.UTF-8 fr_FR.UTF-8 pt_BR.UTF-8 it_IT.UTF-8 ja_JP.UTF-8  pl_PL.UTF-8 zh_TW.UTF-8 zh_CN.UTF-8 zh_HK.UTF-8 th_TH.UTF-8 vi_VN.UTF-8 uk_UA.UTF-8  nl_NL.UTF-8 nl_BE.UTF-8 pt_PT.UTF-8  ro_RO.UTF-8 et_EE.UTF-8 fi_FI.UTF-8 es_MX.UTF-8 de_AT.UTF-8 da_DK.UTF-8 cs_CZ.UTF-8 ca_ES.UTF-8 bs_BA.UTF-8
         _do_cleanup
         echo ; } ;
echo -n "::pre-installer called with:: "$1 "::"

case $1 in
  php-ppa|phppa) _install_php_ppa "$@" ;;
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
