#!/bin/bash

REQ="/tmp/${CERTBOT_DOMAIN}.original.request"

# Call the namecheap cheap API and restore the original DNS entries
curl -s "http://api.namecheap.com/xml.response?apiuser=${API_USER}&apikey=${API_KEY}&username=${API_USER}&Command=namecheap.domains.dns.setHosts&ClientIp=`curl -s ipinfo.io/ip`&SLD=${CERTBOT_DOMAIN%%.*}&TLD=${CERTBOT_DOMAIN##*.}"
    -H 'Content-Type: application/x-www-form-urlencoded' \
    -d "`cat $REQ`"

sleep 2

