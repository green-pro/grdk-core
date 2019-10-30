FROM nginx:1.13.5-alpine

COPY nginx.conf /etc/nginx/
COPY acme.conf /etc/nginx/conf.d/
COPY acme-loc.inc /etc/nginx/conf.d/
COPY proxy-params.inc /etc/nginx/conf.d/
COPY hosts.conf /
COPY e_* /

RUN rm /etc/nginx/conf.d/default.conf

RUN apk add --update curl acme-client libressl && rm -rf /var/cache/apk/*

COPY acme-client.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/acme-client.sh
RUN ln -s /usr/local/bin/acme-client.sh /etc/periodic/weekly/acme-client

COPY start-servers.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/start-servers.sh
