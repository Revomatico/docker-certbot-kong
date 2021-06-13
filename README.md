# docker-revo-certbot
> Builds a Docker image from base certbot/certbot

# Purpose
- The container will:
    1. Verify the validity of the certificate
    2. Using [certbot](https://certbot.eff.org/docs/using.html#manual), request a new **wildcard** certificate for $MAIN_DOMAIN using $EMAIL:
        - **manual** method
        - **dns** challenge
    3. Automatically add a TXT record to the DN registrar for certbot challenge, using $API_KEY and $API_USER env vars
    4. Wait for $CHALLENGE_TIMEOUT seconds for the DNS changes to propagate
    5. If validation is successfull, restore the original DNS records
- `certbot-auth-hook.sh` automates the creation of a TXT record. Currently works for **namecheap.com**, for others get inspiration from:
    - https://github.com/Neilpang/acme.sh/tree/master/dnsapi
- `certbot-cleanup-hook.sh` automates the deletion of the TXT record created above
- Used:
    - Certbot validation hooks: https://certbot.eff.org/docs/using.html#pre-and-post-validation-hooks
    - [jq](https://stedolan.github.io/jq/) to manipulate JSON
    - [xmlstarlet](http://xmlstar.sourceforge.net/) to manipulate XML

# Usage
- `./build.sh` - build the image
- `./run.sh` - test run the image using bash, bypassing the entrypoint script

> This can be run in Kubernetes, as a Job

# Release notes
- 2021-06-14 [0.6]:
    - Docker pull on latest certbot image
- 2020-09-23 [0.4]:
    - Removed Kong certificate push, since now Kong is mainly stateless
- 2018-07-24 [0.2]:
    - Added automatic adding and removal of TXT record for validation using [namecheap.com APIs](https://www.namecheap.com/support/api/methods/domains-dns/set-hosts.aspx)
- 2018-07-17 [0.1]:
    - Initial release
