#!/bin/bash

export B=
export HOST=
export PORT=
export DBNAME=
export USER=

dbdirname="local-${dbtype}"
export DBENV_CONF="${dbdirname}.conf"

usage() {
	cat <<-EOF
		$(basename ${0}) [ARGUMENTS] [ACTION] [[EXTRA ARGUMENTS]]

		ARGUMENTS:
		    -h, --help               This screen
		    -b, --base-dir [PATH]    Path to base directory.  If unspecified, the directory
		                             tree will be searched upward to either the user's home
		                             directory or / looking for the directory '.${dbdirname}/'.
		                             If not found, the default ~/.local/dbenv/${dbdirname}/ is used.
		    -I, --initialize         Shortcut for "--base-dir ./.${dbdirname}"


		ACTION:
		    start         Start the ${dbtype} server and create the default database
		    stop          Stop the resid server
		    shell         Connect to server with psql
		    clean         Stop the server and wipe any remaining files
		    url           Print url to ${dbtype} server
		    base-dir      Print the resolved base-dir

		EXTRA ARGUMENTS are passed when using the 'shell' action and are otherwise ignored.
	EOF
}

err() { echo -e "\e[31m*\e[0m $*"; }
info() { echo -e "\e[32m*\e[0m $*"; }
warn() { echo -e "\e[33m*\e[0m $*"; }

get_port() {
	if server_running; then
		_get_port_from_running_db
	fi

	local host=${1}
	local cmd

	cmd+="import socket;"
	cmd+="s = socket.socket(socket.AF_INET, socket.SOCK_STREAM);"
	cmd+="s.bind(('127.0.0.1', 0));"
	cmd+="print(s.getsockname()[1]);"

	echo ${cmd} | python
}

init() {
	# First find the base directory
	# - If BASE_DIR was already set we're done.
	# - Otherwise search up the directory tree looking for .${dbdirname}
	# - Finally fall back to using ~/.local/dbenv/${dbdirname}
	if [ ! -n "${B}" ]; then
		while [ ! -d ./.${dbdirname} ]; do
			cd ../
			[ $(pwd) == ${HOME} ] && break
			[ $(pwd) == / ] && break
		done

		if [ -d ./.${dbdirname} ]; then
			B=$(pwd)/.${dbdirname}/
		else
			B=${HOME}/.local/dbenv/${dbdirname}
		fi
	fi

	[ ! -d ${B} ] && mkdir -p ${B}

	if [ -s ${B}/${DBENV_CONF} ]; then
		source ${B}/${DBENV_CONF}
	fi

	: ${USER:=${default_user}}
	: ${DBNAME:=${default_dbname}}
	: ${HOST:=127.0.0.1}
	: ${PORT:=$(get_port)}

	if [ ! -s ${B}/${DBENV_CONF} ]; then
		_write_config
	fi
}

server_initialized() {
	_server_initialized
}

server_running() {
	[ -z "${HOST}" ] && return 1
	[ -z "${PORT}" ] && return 1
	_server_running
}

init_server() {
	local r

	server_initialized && return

	_write_server_configs
	if [ $? -ne 0 ]; then
		err "Failed to write server configs"
		return 1
	fi

	mkdir -p ${B}/tmp &>/dev/null
	mkdir -p ${B}/data &>/dev/null
	return 0
}

start_server() {
	local r

	if ! server_initialized; then
		init_server || return 1
	fi

	server_running && return

	_start_server

	for ((i=0; i < 100; ++i)); do
		sleep 0.1
		server_running && break
	done

	server_running
}

stop_server() {
	if ! server_running; then
		err "No server running"
		return 0
	fi

	_stop_server

	if [ $? -ne 0 ]; then
		err "Failed to stop server"
	fi

	return 0
}

shell() {
	if ! server_running; then
		start_server || return 1
	fi

	_shell ${@}
}

action=
declare -a extra

while [ $# -ne 0 ]; do
	case $1 in
		-b|--base-dir)
			shift;
			B=$(realpath -m ${1})
			mkdir -p ${B} &> /dev/null
			;;
		-d|--db)
			shift;
			DBNAME=${1}
			;;
		-I|--initialize)
			B=$(realpath -m $(pwd))/.${dbdirname}
			mkdir -p ${B} &> /dev/null
			;;
		-h)
			usage
			exit 0
			;;
		*)
			if [ -z "${action}" ]; then
				action=${1}
			else
				extra+=(${1})
			fi
			;;
	esac
	shift
done

if [ -z "${action}" ]; then
	err "No action specified"
	exit 1
fi

init

case ${action} in
	init)
		init_server
		;;
	start)
		start_server
		;;
	stop)
		stop_server
		;;
	shell)
		shell ${extra[@]}
		;;
	clean)
		server_running && stop_server
		read -n 1 -r -p "Wipe ${B}? [Y/n] " ans
		echo
		if [ -z "${ans}" ] || [ "${ans}" == "y" ] || [ "${ans}" == "Y" ]; then
			rm -rf ${B}
		fi
		;;
	url)
		_url
		;;
	base-dir)
		echo ${B}
		;;
	*)
		usage
		err "Unknown action"
		exit 1
esac

# vim: noet
