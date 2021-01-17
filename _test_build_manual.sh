cd build ;

( time docker build . -f Dockerfile-php${1}-dropbear-fpm  -t thefoundation/hocker:php${1}-dropbear-fpm 2>&1  && {
 docker run -v $(pwd)/../thefoundation-imagetester.sh:/_image_tests.sh --rm -t thefoundation/hocker:php${1}-dropbear-fpm /bin/bash /_image_tests.sh 2>&1  ) |tee /dev/shm/imagetest.$1.log   ; } ;
 echo "log in /dev/shm/imagetest.$1.log , length "$(wc -l /dev/shm/imagetest.$1.log)" lines"
