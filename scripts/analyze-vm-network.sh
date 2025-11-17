#!/bin/bash
# Script para analizar la configuración de red de la VM

echo "════════════════════════════════════════"
echo "🔍 Análisis de Red - VM Ubuntu Desktop"
echo "════════════════════════════════════════"
echo ""

echo "1️⃣  Interfaces de red disponibles:"
ip -o link show | grep -v "lo:" | awk '{print "   ", $2, $9}'
echo ""

echo "2️⃣  Direcciones IPv6:"
ip -6 addr show | grep -E "inet6|scope global"
echo ""

echo "3️⃣  Rutas IPv6:"
ip -6 route
echo ""

echo "4️⃣  DNS configurado:"
cat /etc/resolv.conf
echo ""

echo "5️⃣  Gateway IPv6:"
ip -6 route | grep default
echo ""

echo "6️⃣  Prueba de conectividad al servidor:"
ping6 -c 2 2025:db8:10::2 2>&1 | tail -2
echo ""

echo "7️⃣  Prueba de DNS:"
dig @2025:db8:10::2 google.com AAAA +short 2>&1 | head -3
echo ""

echo "8️⃣  Ruta NAT64:"
ip -6 route | grep 64:ff9b || echo "   ❌ Ruta NAT64 no encontrada"
echo ""

echo "════════════════════════════════════════"
echo "📋 Resumen"
echo "════════════════════════════════════════"
IFACE=$(ip -o link show | grep -v "lo:" | head -1 | awk '{print $2}' | sed 's/://')
IPV6=$(ip -6 addr show $IFACE | grep "2025:db8:10" | grep "scope global" | awk '{print $2}')
GATEWAY=$(ip -6 route | grep default | awk '{print $3}')

echo "Interfaz principal: $IFACE"
echo "IPv6 asignada: $IPV6"
echo "Gateway: $GATEWAY"
echo ""
echo "Para configurar, ejecuta:"
echo "  sudo bash scripts/setup-ubuntu-client.sh"
