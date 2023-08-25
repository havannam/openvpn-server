#!/bin/bash

# Fast way for adding lots of users to an openvpn-install setup
# See the main openvpn-install project here: https://github.com/Nyr/openvpn-install
# openvpn-useradd-bulk is NOT supported or maintained and could become obsolete or broken in the future
# Created to satisfy the requirements here: https://github.com/Nyr/openvpn-install/issues/435

if readlink /proc/$$/exe | grep -qs "dash"; then
	echo "This script needs to be run with bash, not sh"
	exit 1
fi

if [[ "$EUID" -ne 0 ]]; then
	echo "Sorry, you need to run this as root"
	exit 2
fi

newclient () {
	# Generates the custom client.ovpn
	cp /etc/openvpn/server/client-common.txt ~/$1.ovpn
	echo "<ca>" >> ~/$1.ovpn
	cat /etc/openvpn/server/ca.crt >> ~/$1.ovpn
	echo "</ca>" >> ~/$1.ovpn
	echo "<cert>" >> ~/$1.ovpn
	cat /etc/openvpn/server/easy-rsa/pki/issued/$1.crt >> ~/$1.ovpn
	echo "</cert>" >> ~/$1.ovpn
	echo "<key>" >> ~/$1.ovpn
	cat /etc/openvpn/server/easy-rsa/pki/private/$1.key >> ~/$1.ovpn
	echo "</key>" >> ~/$1.ovpn
	echo "<tls-crypt>" >> ~/$1.ovpn
	cat /etc/openvpn/server/tc.key >> ~/$1.ovpn
	echo "</tls-crypt>" >> ~/$1.ovpn
}

if [ "$1" = "" ]; then
	echo "This tool will let you add new user certificates in bulk to your openvpn-install"
	echo ""
	echo "Run this script specifying a file which contains a list of one username per line"
	echo ""
	echo "Eg: openvpn-useradd-bulk.sh users.txt"
	exit
fi

while read line; do
	cd /etc/openvpn/server/easy-rsa/
	echo yes | ./easyrsa build-client-full $line nopass
	newclient "$line"
	echo ""
	echo "Client $line added, configuration is available at" ~/"$line.ovpn"
	echo ""
done < $1
