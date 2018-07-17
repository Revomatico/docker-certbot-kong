#!/bin/bash

# Entrypoint script to run inside the container
# Expects the following env variables:
# - GRACE_DAYS - [optional] number of days before a certificate expires
# - MAIN_DOMAIN - the primary domain (e.g. mydomain.com)
# - KONG_ADMIN - the URL for Kong Admin API (e.g. http://kong-admin.kong:8001)
# - EMAIL - email address to authenticate to LetsEncrypt (e.g. office@mydomain.com)

esc_newline() {
    sed 's,$,\\n,' | tr -d '\n'
}

VARS='MAIN_DOMAIN KONG_ADMIN EMAIL'
for v in $VARS; do
    eval "X=\$$v"
    if [ -z "$X" ]; then
	echo "[ERROR] You need to set $v env variable!"
	exit 1
    fi
done


GRACE_DAYS=${GRACE_DAYS:-10}
BASE_DIR=`readlink -f ${BASH_SOURCE[0]} | grep -o '.*/'`


echo "++ Checking the current certificate expiration in Kong for $MAIN_DOMAIN ++"
JSON=`curl -s $KONG_ADMIN/certificates/$MAIN_DOMAIN`
if [[ $? -ne 0 ]]; then
    echo "[ERROR] Failed to get certificate from $KONG_ADMIN/certificates/$MAIN_DOMAIN, is it alive?"
else
    RENEW=
    SNIS="[\"$MAIN_DOMAIN\"]"
    CERT=`jq -re '.cert' <<< "$JSON"`
    if [[ -z "$CERT" || $? -ne 0 ]]; then
        echo "[ERROR] No certificate found, output json:"
        jq -r '.' <<< "$JSON"
	CERT=
	RENEW=1
    else
	SNIS=`jq -re '.snis' <<< "$JSON"`
	echo $SNIS
        openssl x509 -noout -checkend `expr $GRACE_DAYS \* 24 \* 60 \* 60` <<< "$CERT"
        [[ $? -eq 1 ]] &&  RENEW=1
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
	if [[ $? -eq 0 ]]; then
	    echo "++ Updating the Kong certificate ++"
	    OPERATION='PATCH'
	    DOM=$MAIN_DOMAIN
	    if [[ -z "$CERT" ]]; then
		OPERATION='POST'
		DOM=
	    fi
	    curl -X $OPERATION \
	        -s $KONG_ADMIN/certificates/$DOM \
	        -H 'content-type: application/json' \
	        -d "{\"snis\":$SNIS,\"cert\":\"`esc_newline < /etc/letsencrypt/live/$MAIN_DOMAIN/cert.pem`\",\"key\":\"`esc_newline < /etc/letsencrypt/live/$MAIN_DOMAIN/privkey.pem`\"}"
	else
	     echo "[ERROR] Certificate renewal failed!"
	fi
    fi
fi
