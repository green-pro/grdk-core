#!/bin/sh

for host in `cat /hosts.conf`; do
	echo "SSL for ${host}"
	acme-client -a https://letsencrypt.org/documents/LE-SA-v1.2-November-15-2017.pdf -Nnmv $host && renew=1
done

#[ "$renew" = 1 ] && rc-service nginx reload
