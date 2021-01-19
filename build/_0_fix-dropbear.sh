#!/bin/bash

echo "DROPBEAR_INIT:"
CONF_DIR="/etc/dropbear"
SSH_KEY_DSS="${CONF_DIR}/dropbear_dss_host_key"      ; SSH_KEY_RSA="${CONF_DIR}/dropbear_rsa_host_key" ; SSH_KEY_ECDSA="${CONF_DIR}/dropbear_ecdsa_host_key" ;SSH_KEY_ED25519="${CONF_DIR}/dropbear_ed25519_host_key"

# Check if conf dir exists
if [ ! -d ${CONF_DIR} ]; then
    mkdir -p ${CONF_DIR} ;fi

chown root:root ${CONF_DIR} ; chmod 755 ${CONF_DIR}

# Check if keys exists , if not generate -- except DSS KEY (just purged)


## OpenSSH 7.0 and greater similarly disables the ssh-dss (DSA) public key algorithm. It too is weak and we recommend against its use.
rm ${SSH_KEY_DSS} 2>/dev/null || true &
## Check if keys exists
#if [ ! -f ${SSH_KEY_DSS} ]; then
#    dropbearkey  -t dss -f   ${SSH_KEY_DSS} 2>&1 | sed 's/$/ |/g' |tr -d '\n' ;echo ;    chown root:root          ${SSH_KEY_DSS};    chmod 600                ${SSH_KEY_DSS}
#fi &

if [ ! -f ${SSH_KEY_ED25519} ]; then
    dropbearkey  -t ed25519 -f ${SSH_KEY_ED25519}     2>&1 | sed 's/$/ |/g' |tr -d '\n' ;echo ;    chown root:root          ${SSH_KEY_ED25519};    chmod 600                ${SSH_KEY_ED25519}
fi &

if [ ! -f ${SSH_KEY_ECDSA} ]; then
    dropbearkey  -t ecdsa -f ${SSH_KEY_ECDSA} -s 521  2>&1 | sed 's/$/ |/g' |tr -d '\n' ;echo ;    chown root:root          ${SSH_KEY_ECDSA}  ;    chmod 600                ${SSH_KEY_ECDSA}
fi &

if [ ! -f ${SSH_KEY_RSA} ]; then
    dropbearkey  -t rsa -f ${SSH_KEY_RSA} -s 8192     2>&1 | sed 's/$/ |/g' |tr -d '\n' ;echo ;    chown root:root          ${SSH_KEY_RSA}    ;    chmod 600                ${SSH_KEY_RSA}
fi &
## dropbear wants a "missing" sftp-server executable if not compiled  differently

test -f /usr/libexec/sftp-server || (test-f /usr/lib/sftp-server && mkdir -p /usr/libexec/ && ln -s /usr/lib/sftp-server /usr/libexec/sftp-server)
