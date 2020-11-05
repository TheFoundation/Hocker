#!/bin/bash
echo "SNAKEOIL CERT:"

#test -f /etc/ssl/certs/ssl-cert-snakeoil.pem && test -f /etc/ssl/private/ssl-cert-snakeoil.key || openssl req -new -x509 -days 365 -nodes -out /etc/ssl/certs/ssl-cert-snakeoil.pem -keyout /etc/ssl/private/ssl-cert-snakeoil.key &
which  make-ssl-cert && test -f /etc/ssl/certs/ssl-cert-snakeoil.pem && test -f /etc/ssl/private/ssl-cert-snakeoil.key || make-ssl-cert generate-default-snakeoil --force-overwrite &
##if make-ssl-certs is missing..
which  make-ssl-cert >&/dev/null || which openssl &>/dev/null && test -f /etc/ssl/certs/ssl-cert-snakeoil.pem && test -f /etc/ssl/private/ssl-cert-snakeoil.key || openssl req -new -x509 -days 32768 -nodes -out /etc/ssl/certs/ssl-cert-snakeoil.pem -keyout /etc/ssl/private/ssl-cert-snakeoil.key &

