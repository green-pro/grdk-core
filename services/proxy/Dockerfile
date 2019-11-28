FROM nginx:1.13.5-alpine

COPY nginx.conf /etc/nginx/
COPY acme-loc.inc /etc/nginx/conf.d/
COPY proxy-params.inc /etc/nginx/conf.d/

COPY hosts.conf /
COPY acme.conf /
COPY e_* /

COPY start-servers.sh /usr/local/bin/

RUN rm /etc/nginx/conf.d/default.conf \
    && apk add --update curl \
    && rm -rf /var/cache/apk/* \
    && chmod +x /usr/local/bin/start-servers.sh

EXPOSE 80 443 8080
