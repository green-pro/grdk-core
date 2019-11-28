location /.well-known/acme-challenge {
    allow all;
    alias /var/www/acme/.well-known/acme-challenge;
}
location / {
    return 301 https://$host$request_uri;
}
