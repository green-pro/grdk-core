#!/bin/sh

CHECK_FILES=$(ls -la /etc/nginx/conf.d/ | grep -E 'e\_.+\.conf' | wc -l)
if [[ "$CHECK_FILES" -gt 0 ]]; then
	rm /etc/nginx/conf.d/e_*.conf
fi

mkdir -p /var/www/acme/.well-known/acme-challenge
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

### COPY e_*.conf files

for entry in /e_*.conf; do
	if [ -f "${entry}" ]; then
		file="${entry##*/}"
		echo "### File ${file}"
		err=0
		line=$(cat $entry | egrep "^(\s|\t)*ssl_certificate_key\s.+\.pem" | sed -e ""s#[[:space:]]##g"" -e "s#ssl_certificate_key##g" -e "s#;##g")
		if [[ $line ]]; then
			echo "   Certificate is required, searching files..."
			for arq in $line; do
				echo "   ${arq}"
				if [ -f "${arq}" ]; then
					echo "   Certificate found"
				else
					echo "   Certificate not found"
					err=1
				fi
			done
		else
			echo "   Certificate not required, skip check files"
		fi
		if [ "$err" -gt 0 ]; then
			echo "   Copy ${file} skiped"
		else
			echo "   Copying ${file}..."
			cp $entry /etc/nginx/conf.d/
		fi
	fi
done

nginx -s reload
curl http://$DK_MSG_HOST:8002/send.php?profile=1\&text=GrdkProxyReloaded
