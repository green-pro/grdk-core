#!/bin/bash

### HELP

_proxy_help()
{
	echo "Usage: $prog_name proxy <command> [options]"
	echo "Commands:"
	echo "    start"
	echo "    stop"
	echo "    cert"
	echo ""
	echo "For help with each command run:"
	echo "$prog_name proxy <command> -h | --help"
	echo ""
}

### SERVICES

_proxy()
{
	case $_command in
		"" | "-h" | "--help")
			_proxy_help
			;;
		"start")
			echo "Start Service"
			;;
		"stop")
			echo "Stop service"
			;;
		*)
			if [ -f ${DK_INSTALL_PATH}/vendor/grdk-core/services/${_service}/lib/lib-${_service}-${_command}.sh ]; then
				source ${DK_INSTALL_PATH}/vendor/grdk-core/services/${_service}/lib/lib-${_service}-${_command}.sh
			fi
			shift 3
			_proxy_${_command} $@
			if [ $? = 127 ]; then
				echo "Error: '$_command' is not a known command." >&2
				echo "Run '$prog_name proxy --help' for a list of known commands." >&2
				exit 1
			fi
			;;
	esac
}
