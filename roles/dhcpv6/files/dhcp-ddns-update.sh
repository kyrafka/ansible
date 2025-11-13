#!/bin/bash
# Script para actualizar DNS cuando DHCP asigna una IP

ACTION=$1
HOSTNAME=$2
IP=$3

DOMAIN="gamecenter.lan"
KEYFILE="/etc/dhcp/dhcp-key.key"

if [ "$ACTION" == "add" ]; then
    # Agregar registro AAAA en DNS
    nsupdate -k "$KEYFILE" <<EOF
server 127.0.0.1
zone $DOMAIN
update delete ${HOSTNAME}.${DOMAIN} AAAA
update add ${HOSTNAME}.${DOMAIN} 600 AAAA $IP
send
EOF
    
    logger "DDNS: Added $HOSTNAME.$DOMAIN -> $IP"
fi
