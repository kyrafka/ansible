#!/bin/bash

echo "════════════════════════════════════════════════════════════════"
echo "🔍 VERIFICACIÓN COMPLETA DEL SERVIDOR"
echo "════════════════════════════════════════════════════════════════"
echo ""

ERRORS=0

echo "1️⃣  DNS (BIND9):"
if systemctl is-active --quiet bind9; then
    echo "   ✅ Servicio activo"
    if dig @localhost google.com AAAA +short | head -1 | grep -q ":"; then
        echo "   ✅ Responde consultas"
    else
        echo "   ❌ No responde consultas"
        ((ERRORS++))
    fi
else
    echo "   ❌ Servicio inactivo"
    ((ERRORS++))
fi

echo ""
echo "2️⃣  DHCPv6:"
if systemctl is-active --quiet isc-dhcp-server6; then
    echo "   ✅ Servicio activo"
else
    echo "   ❌ Servicio inactivo"
    ((ERRORS++))
fi

echo ""
echo "3️⃣  RADVD:"
if systemctl is-active --quiet radvd; then
    echo "   ✅ Servicio activo"
else
    echo "   ❌ Servicio inactivo"
    ((ERRORS++))
fi

echo ""
echo "4️⃣  TAYGA (NAT64):"
if systemctl is-active --quiet tayga; then
    echo "   ✅ Servicio activo"
    if ip link show nat64 &>/dev/null; then
        echo "   ✅ Interfaz nat64 existe"
        if ping6 -c 1 -W 2 64:ff9b::8.8.8.8 &>/dev/null; then
            echo "   ✅ NAT64 funciona"
        else
            echo "   ❌ NAT64 no funciona"
            ((ERRORS++))
        fi
    else
        echo "   ❌ Interfaz nat64 no existe"
        ((ERRORS++))
    fi
else
    echo "   ❌ Servicio inactivo"
    ((ERRORS++))
fi

echo ""
echo "5️⃣  SQUID PROXY:"
if systemctl is-active --quiet squid; then
    echo "   ✅ Servicio activo"
    if netstat -tln | grep -q ":3128"; then
        echo "   ✅ Puerto 3128 abierto"
        if curl -x http://localhost:3128 -s -m 5 http://google.com &>/dev/null; then
            echo "   ✅ Proxy funciona"
        else
            echo "   ⚠️  Proxy no responde (puede ser normal)"
        fi
    else
        echo "   ❌ Puerto 3128 no abierto"
        ((ERRORS++))
    fi
else
    echo "   ❌ Servicio inactivo"
    ((ERRORS++))
fi

echo ""
echo "6️⃣  IP FORWARDING:"
IPV4_FWD=$(cat /proc/sys/net/ipv4/ip_forward)
IPV6_FWD=$(cat /proc/sys/net/ipv6/conf/all/forwarding)

if [ "$IPV4_FWD" = "1" ]; then
    echo "   ✅ IPv4 forwarding habilitado"
else
    echo "   ❌ IPv4 forwarding deshabilitado"
    ((ERRORS++))
fi

if [ "$IPV6_FWD" = "1" ]; then
    echo "   ✅ IPv6 forwarding habilitado"
else
    echo "   ❌ IPv6 forwarding deshabilitado"
    ((ERRORS++))
fi

echo ""
echo "7️⃣  RED:"
if ip -6 addr show ens34 | grep -q "2025:db8:10::2"; then
    echo "   ✅ ens34 tiene IPv6 (2025:db8:10::2)"
else
    echo "   ❌ ens34 sin IPv6"
    ((ERRORS++))
fi

if ip -4 addr show ens33 | grep -q "inet "; then
    echo "   ✅ ens33 tiene IPv4"
else
    echo "   ❌ ens33 sin IPv4"
    ((ERRORS++))
fi

echo ""
echo "8️⃣  FIREWALL:"
if sudo ufw status | grep -q "Status: active"; then
    echo "   ✅ UFW activo"
    if sudo ufw status | grep -q "53"; then
        echo "   ✅ Puerto 53 (DNS) abierto"
    else
        echo "   ⚠️  Puerto 53 no visible en UFW"
    fi
else
    echo "   ⚠️  UFW inactivo"
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
if [ $ERRORS -eq 0 ]; then
    echo "✅ SERVIDOR LISTO - Todo funciona correctamente"
    echo ""
    echo "Puedes configurar clientes ahora:"
    echo "  bash scripts/client/setup-client-with-proxy.sh"
else
    echo "❌ ERRORES ENCONTRADOS: $ERRORS"
    echo ""
    echo "Arregla los errores antes de configurar clientes"
fi
echo "════════════════════════════════════════════════════════════════"
