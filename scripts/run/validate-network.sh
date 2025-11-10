#!/bin/bash
# Script para validar la configuración de red IPv6
# Ejecutar: bash scripts/run/validate-network.sh

echo "════════════════════════════════════════════════════════"
echo "🔍 Validando Configuración de Red IPv6"
echo "════════════════════════════════════════════════════════"
echo ""

ERRORS=0

# Verificar interfaces
echo "📡 Interfaces de red:"
if ip -6 addr show ens33 | grep -q "inet6"; then
    IP=$(ip -6 addr show ens33 | grep "inet6" | grep -v "fe80" | awk '{print $2}')
    echo "✅ ens33 configurada: $IP"
else
    echo "❌ ens33 sin IPv6"
    ((ERRORS++))
fi

if ip -6 addr show ens34 | grep -q "inet6"; then
    IP=$(ip -6 addr show ens34 | grep "inet6" | grep -v "fe80" | awk '{print $2}')
    echo "✅ ens34 configurada: $IP"
else
    echo "❌ ens34 sin IPv6"
    ((ERRORS++))
fi

echo ""
echo "🔀 IPv6 Forwarding:"
if [ "$(cat /proc/sys/net/ipv6/conf/all/forwarding)" == "1" ]; then
    echo "✅ IPv6 forwarding habilitado"
else
    echo "❌ IPv6 forwarding deshabilitado"
    ((ERRORS++))
fi

echo ""
echo "🌐 NAT66:"
if ip6tables -t nat -L POSTROUTING -n | grep -q "MASQUERADE"; then
    echo "✅ NAT66 configurado"
else
    echo "❌ NAT66 no configurado"
    ((ERRORS++))
fi

echo ""
if [ $ERRORS -eq 0 ]; then
    echo "✅ Red IPv6 configurada correctamente"
    exit 0
else
    echo "❌ Hay $ERRORS problemas de configuración"
    exit 1
fi
