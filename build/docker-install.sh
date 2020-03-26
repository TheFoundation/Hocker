#!/bin/bash

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
		apt-get -y purge  libmagickwand-dev php7.4-dev libjpeg-dev libpng-dev libwebp-dev || true  &
		find /tmp/ -type d -name "lilbwebp*" |xargs rm -rf || true & 
		find /tmp/ -type d -name "ImageMagick*" |xargs rm -rf || true &
		find /tmp/ -type d -name "imagick*" |xargs rm -rf || true &
		php -r 'phpinfo();'|grep  ^ImageMagick|grep WEBP -q || exit 444
		echo -n ; } ;




case $1 in 
  imagick|imagemagick|ImageMgick) _install_imagick "$@"
esac

exit 0





