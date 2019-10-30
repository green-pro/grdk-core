#!/bin/sh

for host in `cat /hosts.conf`; do
	echo "SSL for ${host}"
	acme-client -a https://letsencrypt.org/documents/LE-SA-v1.2-November-15-2017.pdf -Nnmv $host && renew=1
done

if [ "$renew" = 1 ]; then
	echo "GRDK-PROXY - RELOAD"
	nginx -s reload
	curl http://$DK_MSG_HOST:8002/send.php?profile=1\&text=GrdkProxyReloaded
else
	echo "GRDK-PROXY - RELOAD skiped"
	curl http://$DK_MSG_HOST:8002/send.php?profile=1\&text=GrdkProxyReloadSkiped
fi

#[ "$renew" = 1 ] && rc-service nginx reload
