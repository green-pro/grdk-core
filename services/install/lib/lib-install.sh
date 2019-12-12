#!/bin/bash

### HELP

_install_help()
{
	echo "Usage: $prog_name install <command> [options]"
	echo "Commands:"
	echo "    cron"
	echo ""
	echo "For help with each command run:"
	echo "$prog_name install <command> -h | --help"
	echo ""
}

### SERVICES

_install()
{
	case $_command in
		"" | "-h" | "--help")
			_install_help
			;;
		*)
			if [ -f ${DK_INSTALL_PATH}/vendor/grdk-core/services/${_service}/lib/lib-${_service}-${_command}.sh ]; then
				source ${DK_INSTALL_PATH}/vendor/grdk-core/services/${_service}/lib/lib-${_service}-${_command}.sh
			fi
			shift 3
			_install_${_command} $@
			if [ $? = 127 ]; then
				echo "Error: '$_command' is not a known command." >&2
				echo "Run '$prog_name install --help' for a list of known commands." >&2
				exit 1
			fi
			;;
	esac
}
