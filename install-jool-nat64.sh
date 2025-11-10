#!/bin/bash
# Script para instalar Jool NAT64 (alternativa a Tayga)

echo "════════════════════════════════════════════════════════"
echo "🔧 Instalando Jool NAT64"
echo "════════════════════════════════════════════════════════"

if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script debe ejecutarse como root"
    exit 1
fi

echo "1️⃣  Deteniendo Tayga..."
systemctl stop tayga-nat64 2>/dev/null || true
killall tayga 2>/dev/null || true

echo "2️⃣  Instalando dependencias..."
apt update
apt install -y linux-headers-$(uname -r) build-essential dkms pkg-config \
    libnl-genl-3-dev libxtables-dev git autoconf automake libtool

echo "3️⃣  Descargando Jool..."
cd /tmp
wget https://github.com/NICMx/Jool/releases/download/v4.1.10/jool-4.1.10.tar.gz
tar -xzf jool-4.1.10.tar.gz
cd jool-4.1.10

echo "4️⃣  Compilando Jool..."
./configure
make
make install

echo "5️⃣  Cargando módulo de Jool..."
modprobe jool_siit

echo "6️⃣  Configurando Jool NAT64..."
# Crear instancia NAT64
jool_siit instance add "default" --netfilter --pool6 64:ff9b::/96

# Obtener IP del servidor
SERVER_IP=$(ip -4 addr show ens33 | grep inet | awk '{print $2}' | cut -d/ -f1)

echo "7️⃣  Configurando pool de IPs..."
# Agregar pool de IPs
jool_siit -i "default" eamt add 64:ff9b::$SERVER_IP $SERVER_IP

echo "8️⃣  Configurando iptables..."
iptables -t nat -A POSTROUTING -s 64:ff9b::/96 -o ens33 -j MASQUERADE
iptables -A FORWARD -s 64:ff9b::/96 -j ACCEPT
iptables -A FORWARD -d 64:ff9b::/96 -m state --state RELATED,ESTABLISHED -j ACCEPT

echo "9️⃣  Guardando configuración..."
iptables-save > /etc/iptables/rules.v4

echo ""
echo "✅ Jool NAT64 instalado"
echo ""
echo "📋 Probar desde la VM:"
echo "   ping6 64:ff9b::808:808"
echo "   curl -6 http://google.com"
echo ""
