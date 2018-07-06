#!/bin/sh

acme-client.sh
rm /etc/nginx/conf.d/e_*.conf
cp /e_*.conf /etc/nginx/conf.d/
nginx -s reload
