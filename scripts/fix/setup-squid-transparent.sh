#!/bin/bash

echo "════════════════════════════════════════════════════════════════"
echo "🌐 CONFIGURAR SQUID PROXY TRANSPARENTE (MANUAL)"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script debe ejecutarse como root"
    echo "   Usa: sudo bash $0"
    exit 1
fi

# 1. Detener Squid
echo "🛑 Deteniendo Squid..."
systemctl stop squid

# 2. Backup de configuración
echo "📋 Haciendo backup..."
cp /etc/squid/squid.conf /etc/squid/squid.conf.backup-$(date +%Y%m%d-%H%M%S) 2>/dev/null || true

# 3. Crear nueva configuración
echo "📝 Creando configuración transparente..."
cat > /etc/squid/squid.conf << 'EOF'
# Squid Proxy - Configuración transparente para GameCenter

# Puerto normal (para diagnóstico)
http_port 3128

# Puerto transparente para HTTP
http_port 3129 intercept

# HTTPS pasa directo por NAT64 (sin Squid)

# ACLs básicas
acl localnet src 2025:db8:10::/64
acl localnet src 0.0.0.1-0.255.255.255
acl SSL_ports port 443
acl Safe_ports port 80
acl Safe_ports port 443
acl Safe_ports port 21
acl Safe_ports port 1025-65535
acl CONNECT method CONNECT

# Reglas de acceso
http_access deny !Safe_ports
http_access deny CONNECT !SSL_ports
http_access allow localhost manager
http_access deny manager
http_access allow localnet
http_access allow localhost
http_access deny all

# Configuración de cache
cache_dir ufs /var/spool/squid 1000 16 256
maximum_object_size 50 MB
cache_mem 256 MB

# Logs
access_log /var/log/squid/access.log squid
cache_log /var/log/squid/cache.log
cache_store_log none

# DNS
dns_nameservers 127.0.0.1

# Optimizaciones
refresh_pattern ^ftp: 1440 20% 10080
refresh_pattern ^gopher: 1440 0% 1440
refresh_pattern -i (/cgi-bin/|\?) 0 0% 0
refresh_pattern . 0 20% 4320

# Modo transparente
forwarded_for delete
via off
follow_x_forwarded_for allow localnet
EOF

echo "✓ Configuración creada"

# 4. Verificar directorio de cache
echo "📁 Verificando directorio de cache..."
if [ ! -d /var/spool/squid ]; then
    mkdir -p /var/spool/squid
    chown proxy:proxy /var/spool/squid
fi

# 5. Inicializar cache
echo "🔧 Inicializando cache..."
squid -z 2>/dev/null || true
sleep 2

# 6. Iniciar Squid
echo "🚀 Iniciando Squid..."
systemctl start squid
sleep 3

# 7. Verificar que inició
if systemctl is-active --quiet squid; then
    echo "✅ Squid activo"
else
    echo "❌ Squid falló al iniciar"
    journalctl -u squid -n 20
    exit 1
fi

# 8. Limpiar reglas viejas de iptables
echo "🧹 Limpiando reglas viejas..."
iptables -t nat -D PREROUTING -i ens34 -p tcp --dport 80 -j REDIRECT --to-port 3129 2>/dev/null || true

# 9. Agregar reglas de iptables para interceptar tráfico HTTP
echo "🛡️ Configurando iptables..."
iptables -t nat -A PREROUTING -i ens34 -p tcp --dport 80 -j REDIRECT --to-port 3129

# HTTPS (443) pasa directo por NAT64, no por Squid

echo "✓ Reglas de iptables agregadas"

# 10. Guardar reglas
echo "💾 Guardando reglas de iptables..."
iptables-save > /etc/iptables/rules.v4

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✅ SQUID PROXY TRANSPARENTE CONFIGURADO"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "📊 Verificación:"
echo ""

# Mostrar estado
systemctl status squid --no-pager | head -10

echo ""
echo "📋 Reglas de iptables:"
iptables -t nat -L PREROUTING -n -v | grep 3129

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "🧪 PRUEBA DESDE EL CLIENTE:"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "  # Navegar en Firefox"
echo "  firefox http://www.google.com"
echo ""
echo "  # Probar con curl"
echo "  curl -6 http://google.com"
echo ""
echo "  # Ver logs en el servidor"
echo "  sudo tail -f /var/log/squid/access.log"
echo ""
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "✅ Los clientes NO necesitan configurar proxy"
echo "✅ El tráfico HTTP/HTTPS se intercepta automáticamente"
echo "✅ Juegos LAN funcionan directo (no pasan por Squid)"
echo ""
echo "════════════════════════════════════════════════════════════════"
