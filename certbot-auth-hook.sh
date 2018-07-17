#!/bin/bash

# TODO: replace with namecheap.com API to automatically create a TXT record in the domain

CREATE_DOMAIN="_acme-challenge.$CERTBOT_DOMAIN"

echo "Add a TXT record containing:" > `tty`
echo "_acme-challenge=$CERTBOT_VALIDATION" > `tty`
echo "$CREATE_DOMAIN=$CERTBOT_VALIDATION" > `tty`

sleep ${CHALLENGE_TIMEOUT:-80}
