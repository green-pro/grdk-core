#!/bin/bash

source $DK_INSTALL_PATH/vendor/grdk-core/lib/include-functions.sh

grdk_logger_send "[GrdkProxyCertbot] Started"

### CHECK REQUIREMENTS

grdk_containers_checkup grdk-proxy 3 1 exact
if [ $? != 1 ]; then
	grdk_logger_send "[GrdkProxyCertbot] GRDK-PROXY - Not Found"
	exit 1
fi

cert_lock_file=/mnt/storage-local/grdk-proxy/certboot/lib/.certbot.lock
if [ -f "$cert_lock_file" ]; then
	grdk_logger_send "[GrdkProxyCertbot] Certbot is locked"
	exit 1
fi

### CERTBOT RENEW

docker run -it --rm --name grdk-proxy_certbot \
 -v "/mnt/storage-local/grdk-proxy/certboot/etc:/etc/letsencrypt" \
 -v "/mnt/storage-local/grdk-proxy/certboot/lib:/var/lib/letsencrypt" \
 -v "/mnt/storage-local/grdk-proxy/certboot/www:/var/www/acme" \
 certbot/certbot:v0.40.1 renew --webroot --webroot-path /var/www/acme \
 --pre-hook 'echo > /etc/letsencrypt/deploy_hook_renewed.txt' \
 --deploy-hook 'echo $RENEWED_DOMAINS >> /etc/letsencrypt/deploy_hook_renewed.txt'

### READ DEPLOY HOOK OUTPUT FILE

sleep 3s
rd=0
deploy_hook_renewed=/mnt/storage-local/grdk-proxy/certboot/etc/deploy_hook_renewed.txt
if [ -f "$deploy_hook_renewed" ]; then
	for host_renewed in `cat $deploy_hook_renewed`; do
		grdk_logger_send "[GrdkProxyCertbot] ${host_renewed} renewed"
		(( rd++ ))
	done
	# Delete file (optional)
fi
if [[ "$rd" -gt 0 ]]; then
	docker exec -it grdk-proxy start-servers.sh
	grdk_logger_send "[GrdkProxyCertbot] NGINX reloaded"
else
	grdk_logger_send "[GrdkProxyCertbot] NGINX skip reload"
fi

## END

grdk_logger_send "[GrdkProxyCertbot] Completed"
