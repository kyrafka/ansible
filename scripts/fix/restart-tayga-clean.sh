#!/bin/bash
# Script para limpiar y reiniciar TAYGA correctamente
# Ejecutar: sudo bash scripts/fix/restart-tayga-clean.sh

if [ "$EUID" -ne 0 ]; then 
    echo "❌ Ejecuta como root: sudo bash $0"
    exit 1
fi

echo "════════════════════════════════════════════════════════"
echo "🔧 Limpiando y reiniciando TAYGA (NAT64)"
echo "════════════════════════════════════════════════════════"
echo ""

echo "1️⃣  Deteniendo TAYGA..."
systemctl stop tayga
sleep 2
echo "✅ Detenido"
echo ""

echo "2️⃣  Eliminando interfaz nat64 antigua..."
ip link delete nat64 2>/dev/null || echo "   (no existía)"
sleep 1
echo "✅ Limpiado"
echo ""

echo "3️⃣  Limpiando directorio de trabajo..."
rm -rf /var/db/tayga/*
mkdir -p /var/db/tayga
echo "✅ Directorio limpio"
echo ""

echo "4️⃣  Verificando configuración..."
if [ -f "/etc/tayga.conf" ]; then
    echo "✅ /etc/tayga.conf existe"
    echo ""
    echo "Contenido:"
    cat /etc/tayga.conf
else
    echo "❌ /etc/tayga.conf NO existe"
    echo ""
    echo "Creando configuración básica..."
    cat > /etc/tayga.conf << 'EOF'
tun-device nat64
ipv4-addr 192.168.255.1
prefix 64:ff9b::/96
dynamic-pool 192.168.255.0/24
data-dir /var/db/tayga
EOF
    echo "✅ Configuración creada"
fi
echo ""

echo "5️⃣  Iniciando TAYGA..."
systemctl start tayga
sleep 3

if systemctl is-active --quiet tayga; then
    echo "✅ TAYGA iniciado correctamente"
else
    echo "❌ TAYGA falló al iniciar"
    echo ""
    echo "📋 Logs de error:"
    journalctl -u tayga -n 30 --no-pager
    exit 1
fi
echo ""

echo "6️⃣  Verificando interfaz nat64..."
sleep 2
if ip link show nat64 &>/dev/null; then
    echo "✅ Interfaz nat64 existe"
    ip link show nat64
    echo ""
    echo "Estado:"
    ip addr show nat64
else
    echo "❌ Interfaz nat64 NO existe"
    echo ""
    echo "Intentando levantar manualmente..."
    ip link set nat64 up 2>/dev/null
    sleep 1
    if ip link show nat64 &>/dev/null; then
        echo "✅ Ahora sí existe"
    else
        echo "❌ No se pudo crear"
        exit 1
    fi
fi
echo ""

echo "7️⃣  Configurando rutas NAT64..."
ip -6 route add 64:ff9b::/96 dev nat64 2>/dev/null || echo "   (ruta ya existe)"
ip -4 route add 192.168.255.0/24 dev nat64 2>/dev/null || echo "   (ruta ya existe)"
echo "✅ Rutas configuradas"
echo ""

echo "8️⃣  Probando conectividad NAT64..."
if ping6 -c 2 -W 2 64:ff9b::8.8.8.8 &>/dev/null; then
    echo "✅ Ping a 8.8.8.8 vía NAT64 funciona"
else
    echo "⚠️  Ping a 8.8.8.8 vía NAT64 no funciona"
    echo "   (Puede ser normal si no hay conectividad IPv4)"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ Proceso completado"
echo "════════════════════════════════════════════════════════"
echo ""
echo "📊 Estado:"
systemctl status tayga --no-pager -l | head -15
echo ""
echo "🌐 Rutas NAT64:"
ip -6 route | grep 64:ff9b
ip -4 route | grep 192.168.255
echo ""
