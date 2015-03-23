#!/bin/sh

# Configuration
NETWORK_SERVICE="Thunderbolt Ethernet"
# Or "Wi-Fi", etc
# To list other available services: /usr/sbin/networksetup -listallnetworkservices

SOCKS_HOST="127.0.0.1"
SOCKS_PORT=1080

SSH_HOST="host"
SSH_LOGIN="username"
SSH_PORT=22
SSH_SOCKET="/tmp/HippieSocket"

ROOT_UID=0

# Clearing the terminal
clear

# Checking if run as root
if [ "$UID" -ne "$ROOT_UID" ] ; then

    echo "-----------------------------------------------------------------"
	echo "Hippie must be run as root (or sudo)"
    echo "-----------------------------------------------------------------"

	exit 1
fi

# Cases
case "$1" in
    start)

        echo "-----------------------------------------------------------------"
        
        echo "- Setting up SOCKS Proxy configuration for network service $NETWORK_SERVICE"
        echo ""
        
        echo "SOCKS Host : $SOCKS_HOST"
        echo "SOCKS Port : $SOCKS_PORT"
        /usr/sbin/networksetup -setsocksfirewallproxy "$NETWORK_SERVICE" $SOCKS_HOST $SOCKS_PORT

        echo "-----------------------------------------------------------------"
        
        echo "- Creation of the SSH tunnel"
        ssh -M -S $SSH_SOCKET -qNT -C -f -D $SOCKS_PORT $SSH_LOGIN@$SSH_HOST -p $SSH_PORT

        echo "-----------------------------------------------------------------"
        
        echo "- Starting the SOCKS Proxy"
        /usr/sbin/networksetup -setsocksfirewallproxystate "$NETWORK_SERVICE" on

        echo "-----------------------------------------------------------------"
        ;;

    stop)

        echo "-----------------------------------------------------------------"
        
        echo "- Resetting the SOCKS Proxy configuration for network service $NETWORK_SERVICE"
        /usr/sbin/networksetup -setsocksfirewallproxy "$NETWORK_SERVICE" "" ""

        echo "-----------------------------------------------------------------"

        echo "- Stopping the SOCKS Proxy"
        /usr/sbin/networksetup -setsocksfirewallproxystate "$NETWORK_SERVICE" off

        echo "-----------------------------------------------------------------"

        echo "- Stopping the SSH tunnel"
        sudo ssh -S $SSH_SOCKET -O exit $SSH_LOGIN@$SSH_HOST -p $SSH_PORT

        echo "-----------------------------------------------------------------"
        ;;

    *)

        echo "Usage: $0 start|stop"
        exit 1
esac

osascript -e 'tell application "Terminal" to quit' & exit
exit 0
