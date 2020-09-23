FROM certbot/certbot

MAINTAINER Cristian Chiru <cristian.chiru@revomatico.com>

COPY docker-run.sh certbot-auth-hook.sh certbot-cleanup-hook.sh /

RUN apk add --no-cache \
    bash curl jq xmlstarlet bind-tools

ENTRYPOINT [""]

CMD ["/docker-run.sh"]
