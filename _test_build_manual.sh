git pull
cd build ;

 (
  time docker build . -f Dockerfile-php${1}-dropbear-fpm  -t thefoundation/hocker:php${1}-dropbear-fpm 2>&1  && { \
 docker run \
 -e APT_HTTP_PROXY_URL=${APT_HTTP_PROXY_URL} \
 -e MAIL_HOST=${MAIL_HOST} \
 -e APP_URL=${APP_URL} \
 -e MAIL_USERNAME=${MAIL_USERNAME} \
 -e MAIL_PASSWORD=${MAIL_PASSWORD} \
 -e MYSQL_ROOT_PASSWORD=ImageTesterRoot \
 -e MYSQL_USERNAME=ImageTestUser \
 -e MYSQL_PASSWORD=ImageTestPW \
 -e MYSQL_DATABASE=ImageTestDB 

 -v $(pwd)/../thefoundation-imagetester.sh:/_image_tests.sh \
 --rm -t thefoundation/hocker:php${1}-dropbear-fpm /bin/bash /_image_tests.sh 2>&1 ; } ; ) |tee /dev/shm/imagetest.$1.log
 echo "log in /dev/shm/imagetest.$1.log , length "$(wc -l /dev/shm/imagetest.$1.log)" lines"
