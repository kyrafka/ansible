#!/bin/bash
# Script para validar el servidor DNS (BIND9)
# Ejecutar: bash scripts/run/validate-dns.sh

echo "════════════════════════════════════════════════════════"
echo "🔍 Validando Servidor DNS (BIND9)"
echo "════════════════════════════════════════════════════════"
echo ""

ERRORS=0

# Verificar servicio
echo "🔧 Servicio BIND9:"
if systemctl is-active --quiet named; then
    echo "✅ named está activo"
else
    echo "❌ named NO está activo"
    ((ERRORS++))
fi

if systemctl is-enabled --quiet named; then
    echo "✅ named habilitado al inicio"
else
    echo "❌ named NO habilitado al inicio"
    ((ERRORS++))
fi

echo ""
echo "🌐 Puerto DNS:"
if ss -tulpn | grep -q ":53.*named"; then
    echo "✅ BIND9 escuchando en puerto 53"
else
    echo "❌ BIND9 NO escuchando en puerto 53"
    ((ERRORS++))
fi

echo ""
echo "📝 Archivos de configuración:"
if [ -f "/etc/bind/named.conf.local" ]; then
    echo "✅ named.conf.local existe"
else
    echo "❌ named.conf.local NO existe"
    ((ERRORS++))
fi

if [ -f "/etc/bind/zones/db.gamecenter.local" ]; then
    echo "✅ Zona gamecenter.local existe"
else
    echo "❌ Zona gamecenter.local NO existe"
    ((ERRORS++))
fi

echo ""
echo "🧪 Prueba de resolución:"
if dig @localhost gamecenter.local +short | grep -q "2025:db8"; then
    echo "✅ DNS resuelve gamecenter.local"
else
    echo "❌ DNS NO resuelve gamecenter.local"
    ((ERRORS++))
fi

echo ""
if [ $ERRORS -eq 0 ]; then
    echo "✅ DNS configurado correctamente"
    exit 0
else
    echo "❌ Hay $ERRORS problemas de configuración"
    exit 1
fi
