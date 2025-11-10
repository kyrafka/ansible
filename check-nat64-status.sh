#!/bin/bash
# Script para verificar el estado de NAT64 con Tayga

echo "════════════════════════════════════════════════════════"
echo "🔍 Verificando estado de NAT64 (Tayga)"
echo "════════════════════════════════════════════════════════"
echo ""

echo "1️⃣  Proceso de Tayga:"
echo "────────────────────────────────────────────────────────"
ps aux | grep tayga | grep -v grep || echo "   ❌ Tayga NO está corriendo"
echo ""

echo "2️⃣  Servicio systemd:"
echo "────────────────────────────────────────────────────────"
systemctl status tayga 2>/dev/null || echo "   ⚠️  No hay servicio systemd configurado"
echo ""

echo "3️⃣  Interfaz nat64:"
echo "────────────────────────────────────────────────────────"
ip addr show nat64 2>/dev/null || echo "   ❌ Interfaz nat64 NO existe"
echo ""

echo "4️⃣  Rutas IPv6:"
echo "────────────────────────────────────────────────────────"
ip -6 route show | grep -E "(64:ff9b|2025:db8:10)" || echo "   ⚠️  No hay rutas IPv6 configuradas"
echo ""

echo "5️⃣  Rutas de NAT64:"
echo "────────────────────────────────────────────────────────"
ip route | grep -E "(64:ff9b|192.168.255)" || echo "   ⚠️  No hay rutas de NAT64"
echo ""

echo "6️⃣  Configuración de Tayga:"
echo "────────────────────────────────────────────────────────"
if [ -f /etc/tayga.conf ]; then
    cat /etc/tayga.conf
else
    echo "   ❌ /etc/tayga.conf NO existe"
fi
echo ""

echo "7️⃣  Estadísticas de interfaz nat64:"
echo "────────────────────────────────────────────────────────"
ip -s link show nat64 2>/dev/null || echo "   ❌ No se puede obtener estadísticas"
echo ""

echo "8️⃣  Logs recientes de Tayga:"
echo "────────────────────────────────────────────────────────"
journalctl -u tayga -n 10 --no-pager 2>/dev/null || dmesg | grep -i tayga | tail -10 || echo "   ⚠️  No hay logs disponibles"
echo ""

echo "9️⃣  Reglas de iptables para NAT64:"
echo "────────────────────────────────────────────────────────"
echo "NAT IPv4:"
iptables -t nat -L POSTROUTING -v -n | grep 192.168.255 || echo "   ⚠️  No hay reglas NAT para Tayga"
echo ""
echo "FORWARD:"
iptables -L FORWARD -v -n | grep nat64 || echo "   ⚠️  No hay reglas FORWARD para nat64"
echo ""

echo "🔟  Test de conectividad desde el servidor:"
echo "────────────────────────────────────────────────────────"
echo "Ping a 8.8.8.8 (IPv4):"
ping -c 2 8.8.8.8 2>/dev/null && echo "   ✅ Conectividad IPv4 OK" || echo "   ❌ Sin conectividad IPv4"
echo ""

echo "════════════════════════════════════════════════════════"
echo "📋 Resumen:"
echo "════════════════════════════════════════════════════════"

if ps aux | grep -v grep | grep tayga > /dev/null; then
    echo "✅ Tayga está corriendo"
else
    echo "❌ Tayga NO está corriendo"
fi

if ip addr show nat64 > /dev/null 2>&1; then
    echo "✅ Interfaz nat64 existe"
else
    echo "❌ Interfaz nat64 NO existe"
fi

if ip route | grep 64:ff9b > /dev/null 2>&1; then
    echo "✅ Rutas NAT64 configuradas"
else
    echo "❌ Rutas NAT64 NO configuradas"
fi

echo ""
echo "═════════════════════════════════════════���══════════════"
