#!/bin/bash
# Script para forzar reinicio limpio de BIND9

set -e

echo "🛑 Deteniendo BIND9..."
systemctl stop bind9 2>/dev/null || true

echo "🧹 Limpiando procesos y PIDs..."
killall -9 named 2>/dev/null || true
rm -f /var/run/named/named.pid 2>/dev/null || true
rm -f /run/named/named.pid 2>/dev/null || true

echo "🔍 Verificando configuración..."
if ! named-checkconf; then
    echo "❌ Error en configuración de BIND9"
    echo "📋 Mostrando últimas líneas de named.conf.local:"
    tail -20 /etc/bind/named.conf.local
    exit 1
fi

echo "✅ Configuración válida"

echo "🔄 Iniciando BIND9..."
systemctl start bind9

echo "⏸️  Esperando 3 segundos..."
sleep 3

echo "🔍 Verificando estado..."
if systemctl is-active --quiet bind9; then
    echo "✅ BIND9 está corriendo"
    
    echo "🧪 Probando resolución DNS..."
    dig @localhost gamecenter.local AAAA +short
    
    echo ""
    echo "✅ DNS reiniciado exitosamente"
else
    echo "❌ BIND9 falló al iniciar"
    echo "📋 Logs de error:"
    journalctl -xeu bind9 --no-pager -n 30
    exit 1
fi
