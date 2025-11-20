#!/bin/bash
# Script para limpiar y reiniciar BIND9 correctamente
# Ejecutar: sudo bash scripts/fix/restart-bind9-clean.sh

if [ "$EUID" -ne 0 ]; then 
    echo "❌ Ejecuta como root: sudo bash $0"
    exit 1
fi

echo "════════════════════════════════════════════════════════"
echo "🔧 Limpiando y reiniciando BIND9"
echo "════════════════════════════════════════════════════════"
echo ""

echo "1️⃣  Deteniendo BIND9..."
systemctl stop bind9
systemctl stop named
sleep 2
echo "✅ Detenido"
echo ""

echo "2️⃣  Limpiando archivos de bloqueo y journals..."
rm -f /var/run/named/named.pid
rm -f /var/lib/bind/*.jnl
rm -f /var/cache/bind/*
echo "✅ Limpiado"
echo ""

echo "3️⃣  Verificando configuración..."
if named-checkconf; then
    echo "✅ Configuración válida"
else
    echo "❌ Error en configuración:"
    named-checkconf
    exit 1
fi
echo ""

echo "4️⃣  Verificando permisos..."
chown -R bind:bind /var/lib/bind
chown -R bind:bind /var/cache/bind
chmod 775 /var/lib/bind
echo "✅ Permisos corregidos"
echo ""

echo "5️⃣  Iniciando BIND9..."
systemctl start bind9
sleep 3

if systemctl is-active --quiet bind9; then
    echo "✅ BIND9 iniciado correctamente"
else
    echo "❌ BIND9 falló al iniciar"
    echo ""
    echo "📋 Logs de error:"
    journalctl -u bind9 -n 30 --no-pager
    exit 1
fi
echo ""

echo "6️⃣  Verificando puerto 53..."
sleep 2
if ss -tulpn | grep -q ":53.*named"; then
    echo "✅ BIND9 escuchando en puerto 53"
else
    echo "❌ BIND9 NO escucha en puerto 53"
    exit 1
fi
echo ""

echo "7️⃣  Probando resolución DNS..."
DOMAIN=$(grep -r "domain_name:" group_vars/all.yml 2>/dev/null | grep -v "^#" | awk '{print $2}' | tr -d '"' | head -n1)
if [ -z "$DOMAIN" ]; then
    DOMAIN="gamecenter.lan"
fi

RESULT=$(dig @localhost "$DOMAIN" AAAA +short 2>/dev/null | head -1)
if [ -n "$RESULT" ]; then
    echo "✅ DNS resuelve $DOMAIN → $RESULT"
else
    echo "⚠️  DNS no resuelve $DOMAIN aún"
    echo "   Recargando zonas..."
    rndc reload
    sleep 2
    RESULT=$(dig @localhost "$DOMAIN" AAAA +short 2>/dev/null | head -1)
    if [ -n "$RESULT" ]; then
        echo "✅ Ahora sí resuelve: $RESULT"
    else
        echo "❌ Aún no resuelve"
    fi
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ Proceso completado"
echo "════════════════════════════════════════════════════════"
echo ""
echo "📊 Estado:"
systemctl status bind9 --no-pager -l | head -15
echo ""
