#!/bin/bash

prog_name=$(basename $0)

### HELP

_help()
{
	echo "Usage: $prog_name <service>"
	echo "Services:"
	echo "    proxy"
	echo ""
	echo "For help with each service run:"
	echo "$prog_name <service> -h | --help"
	echo ""
}

### MAIN ROUTE

_service=$1
_command=$2
_subcommand=$3

case $_service in
	"" | "-h" | "--help")
		_help
		;;
	*)
		if [ -f ${DK_INSTALL_PATH}/vendor/grdk-core/services/${_service}/lib/lib-${_service}.sh ]; then
			source ${DK_INSTALL_PATH}/vendor/grdk-core/services/${_service}/lib/lib-${_service}.sh
		fi
		shift 2
		_${_service} $@
		if [ $? = 127 ]; then
			echo "Error: '$_service' is not a known service." >&2
			echo "Run '$prog_name --help' for a list of known services." >&2
			exit 1
		fi
		;;
esac
