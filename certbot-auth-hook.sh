#!/bin/bash

## Reference: https://www.namecheap.com/support/api/methods/domains-dns/set-hosts.aspx
## Inspiration: https://github.com/seansch/letsencrypt_namecheap_dns_api_hook/blob/master/namecheap_dns_api_hook.sh

DNS_TIMEOUT=${DNS_TIMEOUT:-150}

REQ="/tmp/${CERTBOT_DOMAIN}.original.request"

# Get the current DNS entries, process them and add them again, because the sad api from namecheap will overwrite everything
curl -s "http://api.namecheap.com/xml.response?apiuser=${API_USER}&apikey=${API_KEY}&username=${API_USER}&Command=namecheap.domains.dns.getHosts&ClientIp=`curl -s ipinfo.io/ip`&SLD=${CERTBOT_DOMAIN%%.*}&TLD=${CERTBOT_DOMAIN##*.}" > ${REQ}.xml
if [[ $? -ne 0 ]]; then
    echo "[ERROR] curl namecheap api failed!" > `tty`
    exit 1
fi

# Parse the incoming XML and prepare the parameters
XPATH='//ApiResponse/CommandResponse/DomainDNSGetHostsResult/host'
INCR=5
POST_DATA=`sed -E 's/(xmlns|xsi:.*)=\".*\"//g' < ${REQ}.xml | \
    xmlstarlet sel -T -t -m "$XPATH" -v '
	    concat("HostName",position()+'$INCR',"=",@Name,"&",
		    "RecordType",position()+'$INCR',"=",@Type,"&",
		    "Address",position()+'$INCR',"=",@Address,"&",
		    "MXPref",position()+'$INCR',"=",@MXPref,"&",
		    "TTL",position()+'$INCR',"=",@TTL,"&"
	    )' -`

# Save current parameters to a temp file, to be called by the cleanup hook script
echo "$POST_DATA" > $REQ

if [[ -z "$POST_DATA" ]]; then
    echo "[ERROR] emtpy response from namecheap API, perhaps failed?!" > `tty`
    echo "Response: `cat ${REQ}.xml`" > `tty`
    exit 2
fi

# Add the new parameters in front, not sure which one of them work... what the heck are you doing, namecheap?
# TODO remove the useless entries, leave only relevant, but for now it just works like that, cannot afford to make all permutations test, maybe someone?
INCR=1
POST_DATA="HostName$INCR=@&RecordType$INCR=TXT&Address$INCR=_acme-challenge.${CERTBOT_DOMAIN}=${CERTBOT_VALIDATION}&TTL$INCR=60&${POST_DATA}"
INCR=2
POST_DATA="HostName$INCR=@&RecordType$INCR=TXT&Address$INCR=_acme-challenge=${CERTBOT_VALIDATION}&TTL$INCR=60&${POST_DATA}"
INCR=3
POST_DATA="HostName$INCR=_acme-challenge.${CERTBOT_DOMAIN}&RecordType$INCR=TXT&Address$INCR=${CERTBOT_VALIDATION}&TTL$INCR=60&${POST_DATA}"
INCR=4
POST_DATA="HostName$INCR=_acme-challenge&RecordType$INCR=TXT&Address$INCR=${CERTBOT_VALIDATION}&TTL$INCR=60&${POST_DATA}"
echo "Request data: [$POST_DATA]" > `tty`

# Call the namecheap cheap API
curl -s "http://api.namecheap.com/xml.response?apiuser=${API_USER}&apikey=${API_KEY}&username=${API_USER}&Command=namecheap.domains.dns.setHosts&ClientIp=`curl -s ipinfo.io/ip`&SLD=${CERTBOT_DOMAIN%%.*}&TLD=${CERTBOT_DOMAIN##*.}" \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    -d "$POST_DATA"
if [[ $? -ne 0 ]]; then
    echo "[ERROR] curl namecheap api failed!" > `tty`
    exit 3
fi

# No need to check for the XML output from namecheap, since the overall validation will fail if there is an error returned

# Wait for DNS updates to be provisioned (check at $WAITING second intervals)
timer=0
WAITING=15
until dig @8.8.8.8 txt ${CERTBOT_DOMAIN} | grep "${CERTBOT_VALIDATION}" 2>&1 > /dev/null; do
    if [[ $timer -ge $DNS_TIMEOUT ]]; then
        break
    else
        echo " + DNS not propagated. Waiting ${WAITING}s for record creation and replication... Total time elapsed has been $timer out of $DNS_TIMEOUT seconds." > `tty`
        ((timer+=$WAITING))
        sleep $WAITING
    fi
done

# Sleep to allow DNS propagation
#sleep ${DNS_TIMEOUT}
