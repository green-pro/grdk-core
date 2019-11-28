#!/bin/sh

CHECK_FILES=$(ls -la /etc/nginx/conf.d/ | grep -E 'e\_.+\.conf' | wc -l)
if [[ "$CHECK_FILES" -gt 0 ]]; then
	rm /etc/nginx/conf.d/e_*.conf
fi
cp /acme.conf /etc/nginx/conf.d/
file_acme_config=/etc/nginx/conf.d/acme.conf
if [ -f "$file_acme_config" ]; then
	for acme_host in `cat /hosts.conf`; do
		echo "ACME CONF for ${acme_host}"
		cat >> $file_acme_config << EOF
#
# ${acme_host}
#
server {
    listen 80;
    server_name ${acme_host};
    include conf.d/acme-loc.inc;
}
EOF
	echo "O arquivo ${file_acme_config} foi configurado com ${acme_host}"
	done
fi
acme-client.sh
cp /e_*.conf /etc/nginx/conf.d/
nginx -s reload

SERVICE="crond"
if pgrep -x "$SERVICE" > /dev/null; then
	echo "$SERVICE is running"
else
	echo "$SERVICE stopped, starting..."
	crond -b
fi
