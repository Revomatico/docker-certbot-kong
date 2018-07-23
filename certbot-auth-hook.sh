#!/bin/bash

## Reference: https://www.namecheap.com/support/api/methods/domains-dns/set-hosts.aspx

REQ="/tmp/${CERTBOT_DOMAIN}.original.request"

# Get the current DNS entries, process them and add them again, because the sad api from namecheap will overwrite everything
curl -s "http://api.namecheap.com/xml.response?apiuser=${API_USER}&apikey=1${API_KEY}&username=${API_USER}&Command=namecheap.domains.dns.getHosts&ClientIp=`curl -s ipinfo.io/ip`&SLD=${CERTBOT_DOMAIN%%.*}&TLD=${CERTBOT_DOMAIN##*.}" > ${REQ}.xml
if [[ $? -ne 0 ]]; then
    echo "[ERROR] curl namecheap api failed!" > `tty`
    exit 1
fi

# Parse the incoming XML and prepare the parameters
XPATH='//ApiResponse/CommandResponse/DomainDNSGetHostsResult/host'
POST_DATA=`sed -E 's/(xmlns|xsi:.*)=\".*\"//g' < ${REQ}.xml | \
    xmlstarlet sel -T -t -m "$XPATH" -v '
	    concat("HostName",position()+1,"=",@Name,"&",
		    "RecordType",position()+1,"=",@Type,"&",
		    "Address",position()+1,"=",@Address,"&",
		    "MXPref",position()+1,"=",@MXPref,"&",
		    "TTL",position()+1,"=",@TTL,"&"
	    )' -`

# Save current parameters to a temp file, to be called by the cleanup hook script
echo "$POST_DATA" > $REQ

if [[ -z "$POST_DATA" ]]; then
    echo "[ERROR] emtpy response from namecheap API, perhaps failed?!" > `tty`
    echo "Response: `cat ${REQ}.xml`" > `tty`
    exit 2
fi

# Add the new parameters
POST_DATA="HostName1=@&RecordType1=TXT&Address1=_acme-challenge=${CERTBOT_VALIDATION}&TTL1=60&${POST_DATA}"
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

# Sleep to allow DNS propagation
sleep ${CHALLENGE_TIMEOUT:-60}
