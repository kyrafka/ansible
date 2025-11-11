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
echo "📋 Verificando archivo de zona:"
if sudo grep -q "@ *IN *AAAA *2025:db8:10::2" /etc/bind/zones/db.gamecenter.local; then
    echo "✅ Registro raíz (@) configurado correctamente"
else
    echo "❌ Falta registro raíz (@) en la zona"
    echo "   Debería tener: @  IN  AAAA  2025:db8:10::2"
    ((ERRORS++))
fi

echo ""
echo "🧪 Prueba de resolución:"
echo "→ Probando gamecenter.local..."
RESULT=$(dig @localhost gamecenter.local AAAA +short)
if echo "$RESULT" | grep -q "2025:db8:10::2"; then
    echo "✅ DNS resuelve gamecenter.local → $RESULT"
else
    echo "❌ DNS NO resuelve gamecenter.local"
    echo "   Resultado: $RESULT"
    ((ERRORS++))
fi

echo "→ Probando servidor.gamecenter.local..."
RESULT=$(dig @localhost servidor.gamecenter.local AAAA +short)
if echo "$RESULT" | grep -q "2025:db8:10::2"; then
    echo "✅ DNS resuelve servidor.gamecenter.local → $RESULT"
else
    echo "❌ DNS NO resuelve servidor.gamecenter.local"
    ((ERRORS++))
fi

echo "→ Probando www.gamecenter.local..."
RESULT=$(dig @localhost www.gamecenter.local AAAA +short)
if echo "$RESULT" | grep -q "2025:db8:10::2"; then
    echo "✅ DNS resuelve www.gamecenter.local → $RESULT"
else
    echo "❌ DNS NO resuelve www.gamecenter.local"
    ((ERRORS++))
fi

echo ""
if [ $ERRORS -eq 0 ]; then
    echo "════════════════════════════════════════════════════════"
    echo "✅ DNS configurado correctamente"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "📊 Dominios disponibles:"
    echo "   → gamecenter.local"
    echo "   → servidor.gamecenter.local"
    echo "   → www.gamecenter.local"
    echo "   → web.gamecenter.local"
    echo ""
    exit 0
else
    echo "════════════════════════════════════════════════════════"
    echo "❌ Hay $ERRORS problemas de configuración"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "💡 Para corregir, ejecuta:"
    echo "   bash scripts/run/run-dns.sh"
    echo ""
    exit 1
fi
