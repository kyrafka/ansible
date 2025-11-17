#!/bin/bash
# Script para diagnosticar problemas de NAT64

echo "════════════════════════════════════════"
echo "🔍 Diagnóstico de NAT64"
echo "════════════════════════════════════════"
echo ""

echo "1️⃣  Verificando Tayga..."
if ps aux | grep -v grep | grep tayga > /dev/null; then
    echo "✅ Tayga está corriendo"
else
    echo "❌ Tayga NO está corriendo"
fi
echo ""

echo "2️⃣  Verificando interfaz nat64..."
if ip link show nat64 &>/dev/null; then
    echo "✅ Interfaz nat64 existe"
    ip addr show nat64 | grep inet
else
    echo "❌ Interfaz nat64 NO existe"
fi
echo ""

echo "3️⃣  Verificando rutas NAT64..."
echo "Ruta IPv6 (64:ff9b::/96):"
ip -6 route | grep 64:ff9b || echo "❌ No encontrada"
echo ""
echo "Ruta IPv4 (192.168.255.0/24):"
ip -4 route | grep 192.168.255 || echo "❌ No encontrada"
echo ""

echo "4️⃣  Verificando forwarding..."
IPV4_FWD=$(cat /proc/sys/net/ipv4/ip_forward)
IPV6_FWD=$(cat /proc/sys/net/ipv6/conf/all/forwarding)
if [ "$IPV4_FWD" = "1" ]; then
    echo "✅ IPv4 forwarding: habilitado"
else
    echo "❌ IPv4 forwarding: deshabilitado"
fi
if [ "$IPV6_FWD" = "1" ]; then
    echo "✅ IPv6 forwarding: habilitado"
else
    echo "❌ IPv6 forwarding: deshabilitado"
fi
echo ""

echo "5️⃣  Verificando reglas de NAT..."
echo "Reglas MASQUERADE:"
sudo nft list ruleset | grep -A 2 masquerade | grep 192.168.255 || echo "❌ No encontradas"
echo ""

echo "6️⃣  Verificando reglas de FORWARD..."
echo "Reglas de forward para nat64:"
sudo nft list chain ip filter forward 2>/dev/null | grep nat64 || echo "⚠️  No hay reglas específicas para nat64"
echo ""

echo "7️⃣  Verificando conectividad del servidor..."
if ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
    echo "✅ Servidor tiene internet IPv4"
else
    echo "❌ Servidor NO tiene internet IPv4"
fi
echo ""

echo "8️⃣  Prueba de traducción NAT64..."
echo "Capturando 5 segundos en nat64..."
echo "Haz ping desde la VM ahora: ping6 -c 3 64:ff9b::8.8.8.8"
timeout 5 sudo tcpdump -i nat64 -n -c 5 2>/dev/null || echo "❌ No se capturaron paquetes"
echo ""

echo "════════════════════════════════════════"
echo "📋 Resumen"
echo "════════════════════════════════════════"
echo ""
echo "Si Tayga está corriendo y la interfaz existe pero no hay paquetes,"
echo "el problema es el enrutamiento desde la VM."
echo ""
echo "Si hay paquetes en nat64 pero no salen a internet,"
echo "el problema es el forwarding o las reglas de firewall."
echo ""
echo "Ejecuta este script mientras haces ping desde la VM."
