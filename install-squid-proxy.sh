#!/bin/bash
# Script para instalar Squid Proxy como alternativa

echo "════════════════════════════════════════════════════════"
echo "🌐 Instalando Squid Proxy"
echo "════════════════════════════════════════════════════════"

if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script debe ejecutarse como root"
    exit 1
fi

echo "1️⃣  Instalando Squid..."
apt update
apt install -y squid

echo "2️⃣  Configurando Squid..."
cat > /etc/squid/squid.conf << 'EOF'
# Puerto de escucha
http_port 3128

# Permitir red interna IPv6
acl localnet src 2025:db8:10::/64

# Permitir acceso desde la red local
http_access allow localnet
http_access deny all

# Cache
cache_dir ufs /var/spool/squid 1000 16 256

# DNS
dns_v4_first off

# Logs
access_log /var/log/squid/access.log squid
EOF

echo "3️⃣  Creando directorio de caché..."
squid -z

echo "4️⃣  Iniciando Squid..."
systemctl restart squid
systemctl enable squid

echo "5️⃣  Abriendo puerto en firewall..."
ufw allow 3128/tcp

echo ""
echo "✅ Squid Proxy instalado"
echo ""
echo "📋 Configurar en la VM:"
echo "   export http_proxy=http://[2025:db8:10::2]:3128"
echo "   export https_proxy=http://[2025:db8:10::2]:3128"
echo ""
echo "O configurar en /etc/environment"
echo ""
