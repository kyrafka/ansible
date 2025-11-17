#!/bin/bash
# Script para arreglar Tayga NAT64

echo "🛑 Deteniendo Tayga..."
sudo systemctl stop tayga 2>/dev/null || true
sudo killall -9 tayga 2>/dev/null || true

echo "🧹 Limpiando configuración problemática..."
sudo rm -f /etc/systemd/system/tayga.service
sudo rm -f /var/run/tayga.pid
sudo rm -f /run/tayga.pid
sudo ip link delete nat64 2>/dev/null || true

echo "🔄 Recargando systemd..."
sudo systemctl daemon-reload

echo "🔧 Creando interfaz nat64..."
sudo tayga --mktun
sudo ip link set nat64 up

echo "🌐 Agregando rutas NAT64..."
sudo ip -6 route add 64:ff9b::/96 dev nat64 2>/dev/null || true
sudo ip -4 route add 192.168.255.0/24 dev nat64 2>/dev/null || true

echo "🔍 Verificando rutas..."
ip -6 route | grep 64:ff9b

echo "🚀 Iniciando Tayga en background..."
sudo tayga -d &

sleep 2

echo "✅ Verificando que Tayga está corriendo..."
if ps aux | grep -v grep | grep tayga > /dev/null; then
    echo "✅ Tayga está corriendo correctamente"
    echo ""
    echo "🧪 Prueba desde la VM cliente:"
    echo "   ping6 -c 3 64:ff9b::8.8.8.8"
else
    echo "❌ Tayga no está corriendo"
    echo "Ver logs: sudo journalctl -xeu tayga"
fi
