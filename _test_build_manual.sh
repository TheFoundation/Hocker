git pull
cd build ;
echo building with APT_HTTP_PROXY_URL=${APT_HTTP_PROXY_URL}
 (
  time docker build . --build-arg APT_HTTP_PROXY_URL -f Dockerfile-php${1}-dropbear-fpm  -t thefoundation/hocker:php${1}-dropbear-fpm 2>&1  && { \
 docker run \
 -e APT_HTTP_PROXY_URL=${APT_HTTP_PROXY_URL} \
 -e MAIL_HOST=localhost \
 -e APP_URL=localtest.lan \
 -e MAIL_USERNAME=testLocalImage \
 -e MAIL_PASSWORD=testLocalPass \
 -e MYSQL_ROOT_PASSWORD=ImageTesterRoot \
 -e MYSQL_USERNAME=ImageTestUser \
 -e MYSQL_PASSWORD=ImageTestPW \
 -e MYSQL_DATABASE=ImageTestDB \
 -e MARIADB_REMOTE_ACCESS=true \
 -v $(pwd)/../thefoundation-imagetester.sh:/_image_tests.sh \
 --rm -t thefoundation/hocker:php${1}-dropbear-fpm /bin/bash /_image_tests.sh 2>&1 ; } ; ) |tee /dev/shm/imagetest.$1.log
 echo "log in /dev/shm/imagetest.$1.log , length "$(wc -l /dev/shm/imagetest.$1.log)" lines"
