#!/bin/bash
# Script para validar la red IPv6 completa (forwarding, TAYGA, NAT64, conectividad)
# Ejecutar: bash scripts/run/validate-network.sh

echo "════════════════════════════════════════════════════════"
echo "🔍 Validando Red IPv6 y NAT64"
echo "════════════════════════════════════════════════════════"
echo ""

ERRORS=0

# ═══════════════════════════════════════════════════════════
# 1. IP FORWARDING
# ═══════════════════════════════════════════════════════════
echo "🔧 IP Forwarding:"

IPV4_FWD=$(cat /proc/sys/net/ipv4/ip_forward)
IPV6_FWD=$(cat /proc/sys/net/ipv6/conf/all/forwarding)

if [ "$IPV4_FWD" == "1" ]; then
    echo "✅ IPv4 forwarding habilitado"
else
    echo "❌ IPv4 forwarding DESHABILITADO"
    echo "   💡 Ejecuta: bash scripts/run/run-network.sh"
    ((ERRORS++))
fi

if [ "$IPV6_FWD" == "1" ]; then
    echo "✅ IPv6 forwarding habilitado"
else
    echo "❌ IPv6 forwarding DESHABILITADO"
    echo "   💡 Ejecuta: bash scripts/run/run-network.sh"
    ((ERRORS++))
fi

echo ""

# ═══════════════════════════════════════════════════════════
# 2. INTERFACES DE RED
# ═══════════════════════════════════════════════════════════
echo "🌐 Interfaces de red:"

# Verificar ens33 (WAN)
if ip link show ens33 &>/dev/null; then
    echo "✅ ens33 (WAN) existe"
else
    echo "❌ ens33 (WAN) NO existe"
    ((ERRORS++))
fi

# Verificar ens34 (LAN)
if ip link show ens34 &>/dev/null; then
    echo "✅ ens34 (LAN) existe"
    
    # Verificar IPs en ens34
    if ip -6 addr show ens34 | grep -q "2025:db8:10::1"; then
        echo "✅ ens34 tiene IP gateway (::1)"
    else
        echo "❌ ens34 NO tiene IP gateway (::1)"
        echo "   💡 Ejecuta: sudo netplan apply"
        ((ERRORS++))
    fi
    
    if ip -6 addr show ens34 | grep -q "2025:db8:10::2"; then
        echo "✅ ens34 tiene IP servidor (::2)"
    else
        echo "❌ ens34 NO tiene IP servidor (::2)"
        echo "   💡 Ejecuta: sudo netplan apply"
        ((ERRORS++))
    fi
else
    echo "❌ ens34 (LAN) NO existe"
    ((ERRORS++))
fi

echo ""

# ═══════════════════════════════════════════════════════════
# 3. TAYGA (NAT64)
# ═══════════════════════════════════════════════════════════
echo "🔄 TAYGA (NAT64):"

if systemctl is-active --quiet tayga; then
    echo "✅ TAYGA está activo"
else
    echo "❌ TAYGA NO está activo"
    echo "   💡 Ejecuta: bash scripts/run/run-network.sh"
    ((ERRORS++))
fi

if systemctl is-enabled --quiet tayga; then
    echo "✅ TAYGA habilitado al inicio"
else
    echo "❌ TAYGA NO habilitado al inicio"
    ((ERRORS++))
fi

# Verificar interfaz nat64
if ip link show nat64 &>/dev/null; then
    echo "✅ Interfaz nat64 existe"
    
    STATE=$(ip link show nat64 | grep -o "state [A-Z]*" | awk '{print $2}')
    if [ "$STATE" == "UP" ] || [ "$STATE" == "UNKNOWN" ]; then
        echo "✅ Interfaz nat64 está $STATE"
    else
        echo "❌ Interfaz nat64 está $STATE (debe estar UP)"
        echo "   💡 Ejecuta: sudo ip link set nat64 up"
        ((ERRORS++))
    fi
else
    echo "❌ Interfaz nat64 NO existe"
    echo "   💡 Ejecuta: bash scripts/run/run-network.sh"
    ((ERRORS++))
fi

echo ""

# ═══════════════════════════════════════════════════════════
# 4. RUTAS NAT64
# ═══════════════════════════════════════════════════════════
echo "🔀 Rutas NAT64:"

if ip -6 route | grep -q "64:ff9b::/96 dev nat64"; then
    echo "✅ Ruta IPv6 NAT64 existe"
else
    echo "❌ Ruta IPv6 NAT64 NO existe"
    echo "   💡 Ejecuta: bash scripts/run/run-network.sh"
    ((ERRORS++))
fi

if ip -4 route | grep -q "192.168.255.0/24 dev nat64"; then
    echo "✅ Ruta IPv4 NAT64 existe"
else
    echo "❌ Ruta IPv4 NAT64 NO existe"
    echo "   💡 Ejecuta: bash scripts/run/run-network.sh"
    ((ERRORS++))
fi

echo ""

# ═══════════════════════════════════════════════════════════
# 5. IPTABLES NAT
# ═══════════════════════════════════════════════════════════
echo "🛡️  Reglas NAT:"

if sudo iptables -t nat -L POSTROUTING -n | grep -q "192.168.255.0/24"; then
    echo "✅ Regla NAT para TAYGA existe"
else
    echo "❌ Regla NAT para TAYGA NO existe"
    echo "   💡 Ejecuta: bash scripts/run/run-network.sh"
    ((ERRORS++))
fi

echo ""

# ═══════════════════════════════════════════════════════════
# 6. RADVD
# ═══════════════════════════════════════════════════════════
echo "📡 RADVD (Router Advertisement):"

if systemctl is-active --quiet radvd; then
    echo "✅ RADVD está activo"
else
    echo "❌ RADVD NO está activo"
    echo "   💡 Ejecuta: bash scripts/run/run-network.sh"
    ((ERRORS++))
fi

if systemctl is-enabled --quiet radvd; then
    echo "✅ RADVD habilitado al inicio"
else
    echo "❌ RADVD NO habilitado al inicio"
    ((ERRORS++))
fi

echo ""

# ═══════════════════════════════════════════════════════════
# 7. PRUEBAS DE CONECTIVIDAD
# ═══════════════════════════════════════════════════════════
echo "🧪 Pruebas de conectividad:"

# Ping NAT64
if ping6 -c 2 -W 2 64:ff9b::8.8.8.8 &>/dev/null; then
    echo "✅ NAT64 funciona (ping a 8.8.8.8)"
else
    echo "❌ NAT64 NO funciona"
    echo "   💡 Ejecuta: bash scripts/diagnostics/diagnose-connectivity.sh"
    ((ERRORS++))
fi

# Ping IPv4 del servidor
if ping -c 2 -W 2 8.8.8.8 &>/dev/null; then
    echo "✅ Servidor tiene conectividad IPv4"
else
    echo "⚠️  Servidor NO tiene conectividad IPv4"
    echo "   (Esto puede ser normal si no tienes internet IPv4)"
fi

echo ""

# ═══════════════════════════════════════════════════════════
# RESUMEN
# ═══════════════════════════════════════════════════════════
if [ $ERRORS -eq 0 ]; then
    echo "✅ RED IPv6 Y NAT64 CONFIGURADOS CORRECTAMENTE"
    exit 0
else
    echo "❌ Hay $ERRORS problemas de configuración"
    echo ""
    echo "💡 Solución:"
    echo "   bash scripts/run/run-network.sh"
    echo ""
    echo "🔍 Diagnóstico detallado:"
    echo "   bash scripts/diagnostics/diagnose-connectivity.sh"
    exit 1
fi
