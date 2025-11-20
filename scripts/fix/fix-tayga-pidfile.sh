#!/bin/bash
# Script para arreglar el problema del PID file de TAYGA
# Ejecutar: sudo bash scripts/fix/fix-tayga-pidfile.sh

if [ "$EUID" -ne 0 ]; then 
    echo "❌ Ejecuta como root: sudo bash $0"
    exit 1
fi

echo "════════════════════════════════════════════════════════"
echo "🔧 Arreglando problema de PID file de TAYGA"
echo "════════════════════════════════════════════════════════"
echo ""

echo "1️⃣  Deteniendo TAYGA..."
systemctl stop tayga
sleep 2
echo "✅ Detenido"
echo ""

echo "2️⃣  Creando override de systemd para TAYGA..."
mkdir -p /etc/systemd/system/tayga.service.d/

cat > /etc/systemd/system/tayga.service.d/override.conf << 'EOF'
[Service]
# Arreglar problema de PID file
PIDFile=/run/tayga.pid
# Aumentar timeout
TimeoutStartSec=30s
# No fallar si el PID file no existe inmediatamente
RemainAfterExit=no
Type=forking
EOF

echo "✅ Override creado"
echo ""

echo "3️⃣  Recargando configuración de systemd..."
systemctl daemon-reload
echo "✅ Recargado"
echo ""

echo "4️⃣  Limpiando archivos viejos..."
rm -f /var/run/tayga.pid
rm -f /run/tayga.pid
ip link delete nat64 2>/dev/null || true
echo "✅ Limpiado"
echo ""

echo "5️⃣  Verificando configuración de TAYGA..."
if [ ! -f "/etc/tayga.conf" ]; then
    echo "⚠️  /etc/tayga.conf no existe, creando..."
    cat > /etc/tayga.conf << 'EOFCONF'
tun-device nat64
ipv4-addr 192.168.255.1
prefix 64:ff9b::/96
dynamic-pool 192.168.255.0/24
data-dir /var/db/tayga
EOFCONF
    echo "✅ Configuración creada"
else
    echo "✅ /etc/tayga.conf existe"
fi
echo ""

echo "6️⃣  Asegurando directorio de datos..."
mkdir -p /var/db/tayga
chmod 755 /var/db/tayga
echo "✅ Directorio listo"
echo ""

echo "7️⃣  Iniciando TAYGA..."
systemctl start tayga
sleep 5

if systemctl is-active --quiet tayga; then
    echo "✅ TAYGA iniciado correctamente"
else
    echo "❌ TAYGA falló al iniciar"
    echo ""
    echo "📋 Logs:"
    journalctl -u tayga -n 20 --no-pager
    exit 1
fi
echo ""

echo "8️⃣  Verificando interfaz nat64..."
if ip link show nat64 &>/dev/null; then
    echo "✅ Interfaz nat64 existe"
    
    # Levantar interfaz si está down
    ip link set nat64 up 2>/dev/null
    
    # Configurar rutas
    ip -6 route add 64:ff9b::/96 dev nat64 2>/dev/null || echo "   (ruta IPv6 ya existe)"
    ip -4 route add 192.168.255.0/24 dev nat64 2>/dev/null || echo "   (ruta IPv4 ya existe)"
    
    echo ""
    echo "Estado de nat64:"
    ip addr show nat64
else
    echo "❌ Interfaz nat64 NO existe"
    exit 1
fi
echo ""

echo "9️⃣  Habilitando TAYGA al inicio..."
systemctl enable tayga
echo "✅ Habilitado"
echo ""

echo "════════════════════════════════════════════════════════"
echo "✅ TAYGA arreglado"
echo "════════════════════════════════════════════════════════"
echo ""
echo "📊 Estado final:"
systemctl status tayga --no-pager -l | head -15
echo ""
echo "🌐 Rutas NAT64:"
ip -6 route | grep 64:ff9b
ip -4 route | grep 192.168.255
echo ""
