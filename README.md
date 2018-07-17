# docker-certbot-kong
> Builds a Docker image from base certbot/certbot

- Tested with Kong v0.13
- The container will:
    - Check for a certificate in Kong ($KONG_ADMIN), based on SNI = $MAIN_DOMAIN
    - Verify the validity of the certificate
    - Request a new certificate for $MAIN_DOMAIN using $MAIL
    - Use $KONG_ADMIN/certificates to create the certificate object in Kong
- `certbot-auth-hook.sh` automates the creation of a TXT record in namecheap.com, for others see:
    - https://github.com/Neilpang/acme.sh/tree/master/dnsapi
- `certbot-cleanup-hook.sh` automates the deletion of the TXT record created above
- Validation hooks: https://certbot.eff.org/docs/using.html#pre-and-post-validation-hooks


# Release notes
- 2018-07-15 [0.1]:
    - Initial release
