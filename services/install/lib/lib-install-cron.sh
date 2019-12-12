#!/bin/bash

### HELP

_install_cron_help()
{
	echo "Usage: $prog_name install cron <subcommand> [options]"
	echo "Subcommands:"
	echo "    empty (install main)"
	echo "    start"
	echo "    stop"
	echo "    restart"
	echo "    add (add scripts)"
	echo "    rm (remove scripts)"
	echo ""
	echo "For help with each subcommand run:"
	echo "$prog_name install cron <subcommand> -h | --help"
	echo ""
}

### COMMAND

_install_cron()
{
	case $_subcommand in
		"-h" | "--help")
			_install_cron_help
			;;
		"")
			__install_cron_main
			;;
		*)
			shift 1
			_install_cron_${_subcommand} $@
			if [ $? = 127 ]; then
				echo "Error: '$_subcommand' is not a known subcommand." >&2
				echo "Run '$prog_name cron --help' for a list of known subcommands." >&2
				exit 1
			fi
			;;
	esac
}

### MAIN

__install_cron_main()
{
	# RUN
	_install_cron_rm
	_install_cron_add
	_install_cron_restart
	return 0
}

### SUBCOMMANDS

_install_cron_start()
{
	# RUN
	echo "Start crontab service"
	service cron start
	return 0
}

_install_cron_stop()
{
	# RUN
	echo "Stop crontab service"
	service cron stop
	return 0
}

_install_cron_restart()
{
	# RUN
	echo "Restart crontab service"
	service cron restart
	return 0
}

_install_cron_add()
{
	# RUN
	echo "Create link to cron scripts"
	if [ -d "${DK_INSTALL_PATH}/vendor/grdk-core/scripts" ]; then
		for entry2 in "${DK_INSTALL_PATH}/vendor/grdk-core/scripts"/*; do
			if [ -f "${entry2}" ]; then
				file="${entry2##*/}"
				file_name="${file%.*}"
				file_ext=$([[ "$file" = *.* ]] && echo "${file##*.}" || echo '')
				if [[ $file == grdk-cron-daily-* ]]; then
					cmd="ln -s ${entry2} /etc/cron.daily/${file_name}"
					echo $cmd
					$cmd
				elif [[ $file == grdk-cron-hourly-* ]]; then
					cmd="ln -s ${entry2} /etc/cron.hourly/${file_name}"
					echo $cmd
					$cmd
				fi
			fi
		done
	fi
	for entry in "${DK_INSTALL_PATH}/vendor/grdk-core/services"/*; do
		if [ -d "$entry" ]; then
			if [ -d "$entry/scripts" ]; then
				for entry2 in "${entry}/scripts"/*; do
					if [ -f "${entry2}" ]; then
						file="${entry2##*/}"
						file_name="${file%.*}"
						file_ext=$([[ "$file" = *.* ]] && echo "${file##*.}" || echo '')
						if [[ $file == grdk-cron-daily-* ]]; then
							cmd="ln -s ${entry2} /etc/cron.daily/${file_name}"
							echo $cmd
							$cmd
						elif [[ $file == grdk-cron-hourly-* ]]; then
							cmd="ln -s ${entry2} /etc/cron.hourly/${file_name}"
							echo $cmd
							$cmd
						fi
					fi
				done
			fi
		fi
	done
	for entry in "${DK_INSTALL_PATH}/src/services"/*; do
		if [ -d "$entry" ]; then
			if [ -d "$entry/scripts" ]; then
				for entry2 in "${entry}/scripts"/*; do
					if [ -f "${entry2}" ]; then
						file="${entry2##*/}"
						file_name="${file%.*}"
						file_ext=$([[ "$file" = *.* ]] && echo "${file##*.}" || echo '')
						if [[ $file == grdk-cron-daily-* ]]; then
							cmd="ln -s ${entry2} /etc/cron.daily/${file_name}"
							echo $cmd
							$cmd
						elif [[ $file == grdk-cron-hourly-* ]]; then
							cmd="ln -s ${entry2} /etc/cron.hourly/${file_name}"
							echo $cmd
							$cmd
						fi
					fi
				done
			fi
		fi
	done
	return 0
}

_install_cron_rm()
{
	# RUN
	echo "Remove link to cron scripts"
	CHECK_FILES=$(ls -la /etc/cron.daily/ | grep -E 'grdk-cron-.+' | wc -l)
	if [[ "$CHECK_FILES" -gt 0 ]]; then
		echo "Scripts cron.daily deleted"
		rm /etc/cron.daily/grdk-cron-*
	fi
	CHECK_FILES=$(ls -la /etc/cron.hourly/ | grep -E 'grdk-cron-.+' | wc -l)
	if [[ "$CHECK_FILES" -gt 0 ]]; then
		echo "Scripts cron.hourly deleted"
		rm /etc/cron.hourly/grdk-cron-*
	fi
	return 0
}
