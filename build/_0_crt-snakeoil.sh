#!/bin/bash
echo "SNAKEOIL CERT:"


CUSTOM_CRT=/etc/ssl/private/ssl-cert-snakeoil.pem
PRIVATE_KEY=/etc/ssl/private/ssl-cert-snakeoil.key
SYSTEM_CERT=/etc/ssl/certs/ssl-cert-snakeoil.pem

## letsencrypt provides privkey.pem and fullchain.pem

# use it like a volume in dockerfile
# - /etc/nginx/certs/${APP_URL}/:/etc/ssl/private_letsencrypt:ro


LE_FULL=/etc/ssl/private_letsencrypt/fullchain.pem
LE_PRIV=/etc/ssl/private_letsencrypt/key.pem


#test -f /etc/ssl/certs/ssl-cert-snakeoil.pem && test -f /etc/ssl/private/ssl-cert-snakeoil.key || openssl req -new -x509 -days 365 -nodes -out /etc/ssl/certs/ssl-cert-snakeoil.pem -keyout /etc/ssl/private/ssl-cert-snakeoil.key &

_is_cert() { grep -q "BEGIN CERTIFICATE--" "$1" && grep -q "END CERTIFICATE--" "$1" ; } ;
_is_key()  {
             grep -q -e "BEGIN PRIVATE KEY--" -e "BEGIN RSA PRIVATE KEY--" "$1" &&  grep -q -e "END RSA PRIVATE KEY--" -e "END PRIVATE KEY--" "$1" ; } ;
_have_snakeoil() {  test -f ${SYSTEM_CERT} && test -f ${PRIVATE_KEY} && _is_key ${PRIVATE_KEY} && _is_cert ${SYSTEM_CERT} ; } ;



test -f ${LE_PRIV} && _is_key ${LE_PRIV} &&  test -f ${LE_PRIV} && _is_cert ${LE_FULL} && {
echo "using letsencrypt certs as softlink"
    ln -sf ${LE_PRIV} ${PRIVATE_KEY}
    ln -sf ${LE_FULL} ${SYSTEM_CERT}


  which inotifywait 2>/dev/null |grep -q inotifywait && {
    echo use:inotifywait Letsencrypt Watcher
    which nginx 2>/dev/null |grep -q nginx && while inotifywait -q -e close_write ${LE_FULL} ${LE_PRIV}; do nginx -t && service nginx reload;sleep 0.3; done &
    which apache2 2>/dev/null |grep -q apache2 && while inotifywait -q -e close_write ${LE_FULL} ${LE_PRIV}; do apache2ctl configtest|grep "Syntax OK"  -q && service apache2 reload;sleep 0.3; done &
  }
  which inotifywait 2>/dev/null |grep -q inotifywait || {
    echo use:sha512sum Letsencrypt Watcher
    sumcr=$(sha512sum  "${LE_PRIV}" )
    sumky=$(sha512sum  "${LE_FULL}" )
    while (true) ;do
      sleep 300
      ## checksum letsencrypt certs
      tmp_sumcr=$(sha512sum  "${LE_PRIV}" )
      tmp_sumky=$(sha512sum  "${LE_FULL}" )
      keys_match=OK
      [[ "${tmp_sumcr}" = "${sumcr}"]] || keys_match=no
      [[ "${tmp_sumky}" = "${sumky}"]] || keys_match=no
      ## reload webserver on ssl cert changes
      [[ "${keys_match}" = "no"]] && {
        which nginx 2>/dev/null |grep -q nginx &&  nginx -t && service nginx reload
        which apache2 2>/dev/null |grep -q apache2 &&  apache2ctl configtest|grep "Syntax OK"  -q && service apache2 reload
      }
     done &
  }

}

_have_snakeoil || {
    echo -n "SSL Certs:FAILED 1" >&2
    rm ${SYSTEM_CERT} ${PRIVATE_KEY}  ; } ;



which  make-ssl-cert >&/dev/null && _have_snakeoil || make-ssl-cert generate-default-snakeoil --force-overwrite &
##if make-ssl-certs is missing..
which  make-ssl-cert >&/dev/null || which openssl &>/dev/null && _have_snakeoil || openssl req -new -x509 -days 32768 -nodes -out ${SYSTEM_CERT} -keyout ${PRIVATE_KEY} &


_have_snakeoil || echo -n "CRITICAL ERROR: SSL Certs:FAILED after regen" >&2
