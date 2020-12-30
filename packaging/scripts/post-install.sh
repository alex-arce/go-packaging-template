#!/usr/bin/env bash

OLD_NAME=test-server
NAME=test-server
BIN_DIR=/usr/sbin
SCRIPT_DIR=/etc/systemd/system/test-server.service
LOG_DIR=/var/log/test-server
DAEMON_USER=test
DAEMON_GROUP=test

function install_init {
	cp -f $SCRIPT_DIR/$NAME.init /etc/init.d/$NAME
	chmod +x /etc/init.d/$NAME
	ln -s /etc/init.d/$NAME /etc/init.d/$OLD_NAME
	update-rc.d $NAME defaults
}

function install_systemd {
	cp -f $SCRIPT_DIR/$NAME.service /lib/systemd/system/$NAME.service
	systemctl daemon-reload
	systemctl enable $NAME
}

function restart_service {
	echo "Restarting $NAME"
	which systemctl &>/dev/null
	if [[ $? -eq 0 ]]; then
		systemctl daemon-reload
		systemctl restart $NAME
	else
		/etc/init.d/$NAME restart || true
	fi	
}

function create_log_directory {
	if [[ ! -d $LOG_DIR ]]; then
		mkdir -p $LOG_DIR
		chown -R $DAEMON_USER:$DAEMON_GROUP $LOG_DIR
	fi
}

# User creation
id $DAEMON_USER &>/dev/null
if [[ $? -ne 0 ]]; then
	useradd --system -U -M $DAEMON_USER -s /bin/false -d /etc/$NAME
fi

# Create log directory
create_log_directory


# Set the configuration owner / permissions
if [[ -f /etc/$NAME/$NAME.json ]]; then
	chown -R $DAEMON_USER:$DAEMON_GROUP /etc/$NAME
	chmod 750 /etc/$NAME
	chmod 640 /etc/$NAME/$NAME.json
fi

# Show message on install
if [[ $? -eq 0 ]]; then
	echo -e "\n\n\n"
	echo "---------------------------------------------------------------------------------"
	echo "The configuration file is located at:"
	echo " /etc/$NAME/$NAME.json"
	echo ""
	echo "Some helpful commands for $NAME:"
	echo ""
	which systemctl &>/dev/null
	if [[ $? -eq 0 ]]; then
		echo "Start:"
		echo " $ sudo systemctl start $NAME"
		echo ""
		echo "Restart:"
		echo " $ sudo systemctl restart $NAME"
		echo ""
		echo "Stop:"
		echo " $ sudo systemctl stop $NAME"
		echo ""
		echo "Display logs:"
		echo " $ sudo journalctl -f -n 100 -u $NAME"
	else
		echo "Start:"
		echo " $ sudo /etc/init.d/$NAME start"
		echo ""
		echo "Restart:"
		echo " $ sudo /etc/init.d/$NAME restart"
		echo ""
		echo "Stop:"
		echo " $ sudo /etc/init.d/$NAME stop"
		echo ""
		echo "Display logs:"
		echo " $ sudo tail -f -n 100 $LOG_DIR"
	fi
	echo "---------------------------------------------------------------------------------"
	echo -e "\n\n\n"
fi

# add start script
which systemctl &>/dev/null
if [[ $? -eq 0 ]]; then
	install_systemd
else
	install_init
fi

# restart on upgrade
if [[ -n $2 ]]; then
	restart_service
fi
