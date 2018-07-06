location /.well-known/acme-challenge {
    allow all;
    alias /var/www/acme;
}
location / {
    return 301 https://$host$request_uri;
}
