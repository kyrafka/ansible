#!/bin/bash
# Script para instalar Squid Proxy para VMs IPv6-only

# Auto-permisos
[ ! -x "$0" ] && chmod +x "$0" 2>/dev/null

echo "════════════════════════════════════════"
echo "🌐 Instalando Squid Proxy"
echo "════════════════════════════════════════"

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script debe ejecutarse como root"
    echo "   Usa: sudo bash $0"
    exit 1
fi

echo "1️⃣  Instalando Squid..."
apt update
apt install squid -y

echo "2️⃣  Configurando Squid..."
cat > /etc/squid/squid.conf << 'EOF'
# Configuración de Squid para VMs IPv6-only

# Puerto de escucha (IPv6)
http_port [::]:3128

# ACL para red local IPv6
acl localnet src 2025:db8:10::/64

# ACL para puertos seguros
acl SSL_ports port 443
acl Safe_ports port 80          # http
acl Safe_ports port 21          # ftp
acl Safe_ports port 443         # https
acl Safe_ports port 70          # gopher
acl Safe_ports port 210         # wais
acl Safe_ports port 1025-65535  # unregistered ports
acl Safe_ports port 280         # http-mgmt
acl Safe_ports port 488         # gss-http
acl Safe_ports port 591         # filemaker
acl Safe_ports port 777         # multiling http
acl CONNECT method CONNECT

# Reglas de acceso
http_access deny !Safe_ports
http_access deny CONNECT !SSL_ports
http_access allow localhost manager
http_access deny manager
http_access allow localnet
http_access allow localhost
http_access deny all

# Cache
cache_dir ufs /var/spool/squid 1000 16 256
coredump_dir /var/spool/squid

# Refresh patterns
refresh_pattern ^ftp:           1440    20%     10080
refresh_pattern ^gopher:        1440    0%      1440
refresh_pattern -i (/cgi-bin/|\?) 0     0%      0
refresh_pattern .               0       20%     4320

# DNS
dns_v4_first off
EOF

echo "3️⃣  Inicializando cache de Squid..."
squid -z 2>/dev/null || true

echo "4️⃣  Reiniciando Squid..."
systemctl restart squid
systemctl enable squid

echo "5️⃣  Configurando firewall..."
ufw allow 3128/tcp comment 'Squid Proxy'

echo "6️⃣  Verificando Squid..."
sleep 2
if systemctl is-active --quiet squid; then
    echo "   ✓ Squid está corriendo"
else
    echo "   ❌ Error al iniciar Squid"
    journalctl -xeu squid
    exit 1
fi

echo ""
echo "════════════════════════════════════════"
echo "✅ Squid Proxy instalado"
echo "════════════════════════════════════════"
echo ""
echo "📋 Configurar en las VMs:"
echo ""
echo "export http_proxy='http://[2025:db8:10::2]:3128'"
echo "export https_proxy='http://[2025:db8:10::2]:3128'"
echo ""
echo "O para apt:"
echo "echo 'Acquire::http::Proxy \"http://[2025:db8:10::2]:3128\";' | sudo tee /etc/apt/apt.conf.d/proxy.conf"
echo ""
echo "════════════════════════════════════════"
