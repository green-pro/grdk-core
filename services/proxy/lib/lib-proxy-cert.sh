#!/bin/bash

### HELP

_proxy_cert_help()
{
	echo "Usage: $prog_name cert <subcommand> [options]"
	echo "Subcommands:"
	echo "    list"
	echo "    add"
	echo "    renew"
	echo ""
	echo "For help with each subcommand run:"
	echo "$prog_name cert <subcommand> -h | --help"
	echo ""
}

### COMMAND

_proxy_cert()
{
	case $_subcommand in
		"" | "-h" | "--help")
			_proxy_cert_help
			;;
		*)
			shift 1
			_proxy_cert_${_subcommand} $@
			if [ $? = 127 ]; then
				echo "Error: '$_subcommand' is not a known subcommand." >&2
				echo "Run '$prog_name cert --help' for a list of known subcommands." >&2
				exit 1
			fi
			;;
	esac
}

### SUBCOMMANDS

_proxy_cert_list()
{
	# RUN
	echo "List all certificates"
	docker run -it --rm --name grdk-proxy_certbot \
		-v "/mnt/storage-local/grdk-proxy/certboot/etc:/etc/letsencrypt" \
		-v "/mnt/storage-local/grdk-proxy/certboot/lib:/var/lib/letsencrypt" \
		-v "/mnt/storage-local/grdk-proxy/certboot/www:/var/www/acme" \
		${DK_REPO_DI_HOST}:5000/certbot/certbot:v0.40.1 certificates
	return 0
}

_proxy_cert_add()
{
	# PARAMS
	PAR_DOMAIN=$1
	# RUN
	echo "Add certificate for domain ${PAR_DOMAIN}"
	docker run -it --rm --name grdk-proxy_certbot \
		-v "/mnt/storage-local/grdk-proxy/certboot/etc:/etc/letsencrypt" \
		-v "/mnt/storage-local/grdk-proxy/certboot/lib:/var/lib/letsencrypt" \
		-v "/mnt/storage-local/grdk-proxy/certboot/www:/var/www/acme" \
		${DK_REPO_DI_HOST}:5000/certbot/certbot:v0.40.1 certonly --webroot --webroot-path /var/www/acme -d $PAR_DOMAIN
	return 0
}

_proxy_cert_renew()
{
	# RUN
	echo "Renew all certificates"
	docker run -it --rm --name grdk-proxy_certbot \
		-v "/mnt/storage-local/grdk-proxy/certboot/etc:/etc/letsencrypt" \
		-v "/mnt/storage-local/grdk-proxy/certboot/lib:/var/lib/letsencrypt" \
		-v "/mnt/storage-local/grdk-proxy/certboot/www:/var/www/acme" \
		${DK_REPO_DI_HOST}:5000/certbot/certbot:v0.40.1 renew --webroot --webroot-path /var/www/acme \
		--pre-hook 'echo > /etc/letsencrypt/deploy_hook_renewed.txt' \
		--deploy-hook 'echo $RENEWED_DOMAINS >> /etc/letsencrypt/deploy_hook_renewed.txt'
	return 0
}
