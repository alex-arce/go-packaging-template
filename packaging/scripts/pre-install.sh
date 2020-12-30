#!/usr/bin/env bash

OLD_NAME=test-old-server
NAME=test-server

# migrate config to new location
if [[ -f /etc/$OLD_NAME/$OLD_NAME.json ]] && [[ ! -h /etc/$OLD_NAME/$OLD_NAME.json ]] && [[ ! -f /etc/$NAME/$NAME.json ]]; then
	echo "Migrating /etc/$OLD_NAME/$OLD_NAME.json to /etc/$NAME/$NAME.json"

	mkdir -p /etc/$NAME
	mv /etc/$OLD_NAME/$OLD_NAME.json /etc/$NAME/$NAME.json

	echo "Creating symlink /etc/$OLD_NAME/$OLD_NAME.toml for backwards compatibility"
	ln -s /etc/$NAME/$NAME.json /etc/$OLD_NAME/$OLD_NAME.json
fi

function stop_init() {
	if [[ -f /etc/init.d/$OLD_NAME ]]; then
		echo "Stopping $OLD_NAME"
		/etc/init.d/$OLD_NAME stop
	fi
}

function stop_systemd() {
	if [[ -f /lib/systemd/system/$OLD_NAME.service ]]; then
		echo "Stopping $OLD_NAME"
		systemctl stop $OLD_NAME
	fi
}

# stop old service
which systemctl &>/dev/null
if [[ $? -eq 0 ]]; then
	stop_systemd
else
	stop_init
fi
