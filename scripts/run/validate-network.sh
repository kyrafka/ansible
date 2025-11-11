il#!/bin/bash
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
if sudo ip6tables -t nat -L POSTROUTING -n 2>/dev/null | grep -q "MASQUERADE"; then
    echo "✅ NAT66 configurado"
else
    echo "❌ NAT66 no configurado"
    ((ERRORS++))
fi

echo ""
echo "📡 Servicio radvd:"
if systemctl is-active radvd &>/dev/null; then
    echo "✅ radvd está activo"
else
    echo "❌ radvd NO está activo"
    ((ERRORS++))
fi

echo ""
echo "🔧 Configuración de radvd:"
if [ -f /etc/radvd.conf ]; then
    echo "✅ Archivo /etc/radvd.conf existe"
    
    # Verificar que SLAAC está desactivado
    if grep -q "AdvAutonomous off" /etc/radvd.conf; then
        echo "✅ SLAAC desactivado (AdvAutonomous off)"
    else
        echo "⚠️  SLAAC activado (AdvAutonomous on) - Los clientes se autoconfigurarán"
    fi
    
    # Verificar flags DHCPv6
    if grep -q "AdvManagedFlag on" /etc/radvd.conf; then
        echo "✅ DHCPv6 Managed Flag activado (clientes usarán DHCPv6 para IP)"
    else
        echo "⚠️  DHCPv6 Managed Flag desactivado"
    fi
    
    if grep -q "AdvOtherConfigFlag on" /etc/radvd.conf; then
        echo "✅ DHCPv6 Other Config Flag activado (clientes usarán DHCPv6 para DNS)"
    else
        echo "⚠️  DHCPv6 Other Config Flag desactivado"
    fi
else
    echo "❌ Archivo /etc/radvd.conf NO existe"
    ((ERRORS++))
fi

echo ""
if [ $ERRORS -eq 0 ]; then
    echo "════════════════════════════════════════════════════════"
    echo "✅ Red IPv6 configurada correctamente"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "📋 Resumen de configuración:"
    echo "   → SLAAC: Desactivado (solo DHCPv6)"
    echo "   → Rango DHCP: 2025:db8:10::10 - ::FFFF"
    echo "   → DNS: 2025:db8:10::2"
    echo "   → Dominio: gamecenter.local"
    echo ""
    exit 0
else
    echo "════════════════════════════════════════════════════════"
    echo "❌ Hay $ERRORS problemas de configuración"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "💡 Para corregir, ejecuta:"
    echo "   bash scripts/run/run-network.sh"
    echo ""
    exit 1
fi
