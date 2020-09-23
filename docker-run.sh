#!/bin/bash

# Entrypoint script to run inside the container
# Expects the following env variables:
# - GRACE_DAYS - [optional] number of days before a certificate expires, default 10
# - MAIN_DOMAIN - the primary domain (e.g. mydomain.com)
# - EMAIL - email address to authenticate to LetsEncrypt (e.g. office@mydomain.com)

set -o pipefail -o noclobber -o nounset

esc_newline() {
    sed 's,$,\\n,' | tr -d '\n'
}

VARS='MAIN_DOMAIN EMAIL'
for v in $VARS; do
  eval "X=\$$v"
  if [ -z "$X" ]; then
    echo "[ERROR] You need to set $v env variable!"
    exit 1
  fi
done


GRACE_DAYS=${GRACE_DAYS:-10}
BASE_DIR=`readlink -f ${BASH_SOURCE[0]} | grep -o '.*/'`


RENEW=
CERT=`cat /etc/letsencrypt/live/$MAIN_DOMAIN/cert.pem`
if [[ -z "$CERT" || $? -ne 0 ]]; then
    echo "[ERROR] No certificate found, creating a new one"
    CERT=
    RENEW=1
else
  openssl x509 -noout -checkend `expr $GRACE_DAYS \* 24 \* 60 \* 60` <<< "$CERT"
  RET=$?
  [[ $RET -eq 1 ]] && RENEW=1
fi

if [[ -n "$RENEW" ]]; then
  echo "++ Renewing... ++"
  certbot \
    certonly \
    --manual \
    --preferred-challenges dns \
    --manual-auth-hook ${BASE_DIR}certbot-auth-hook.sh \
    --manual-cleanup-hook ${BASE_DIR}certbot-cleanup-hook.sh \
    --server https://acme-v02.api.letsencrypt.org/directory \
    -n \
    --agree-tos \
    --manual-public-ip-logging-ok \
    -d "*.$MAIN_DOMAIN" \
    -m $EMAIL
  if [[ $? -ne 0 ]]; then
    echo "[ERROR] Certificate renewal failed!"
    exit 1
  fi
fi
