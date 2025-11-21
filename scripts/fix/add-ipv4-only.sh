#!/bin/bash

echo "════════════════════════════════════════════════════════════════"
echo "➕ AGREGAR IPv4 A ens34 SIN TOCAR IPv6"
echo "════════════════════════════════════════════════════════════════"
echo ""

if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script debe ejecutarse como root"
    exit 1
fi

# SOLO agregar IPv4, NO borrar nada
ip addr add 10.0.0.1/24 dev ens34 2>/dev/null || echo "IPv4 ya existe"

echo "✓ IPv4 10.0.0.1/24 agregada a ens34"

# Verificar
echo ""
echo "IPs en ens34:"
ip addr show ens34 | grep "inet"

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✅ IPv4 AGREGADA (IPv6 intacta)"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "🪟 EN WINDOWS:"
echo "  New-NetIPAddress -InterfaceAlias Ethernet1 -IPAddress 10.0.0.10 -PrefixLength 24"
echo "  net use Z: \\\\10.0.0.1\\Publico /user:jose 123"
echo ""
echo "════════════════════════════════════════════════════════════════"
