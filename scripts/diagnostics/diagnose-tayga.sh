#!/bin/bash

echo "════════════════════════════════════════"
echo "🔍 DIAGNÓSTICO COMPLETO DE TAYGA"
echo "════════════════════════════════════════"
echo ""

echo "📋 1. Estado del servicio tayga:"
sudo systemctl status tayga --no-pager
echo ""

echo "📋 2. Logs recientes de tayga:"
sudo journalctl -u tayga -n 30 --no-pager
echo ""

echo "📋 3. Verificar archivo de configuración:"
if [ -f /etc/tayga.conf ]; then
    echo "✅ /etc/tayga.conf existe"
    cat /etc/tayga.conf
else
    echo "❌ /etc/tayga.conf NO existe"
fi
echo ""

echo "📋 4. Verificar directorio de datos:"
if [ -d /var/db/tayga ]; then
    echo "✅ /var/db/tayga existe"
    ls -la /var/db/tayga
else
    echo "❌ /var/db/tayga NO existe"
fi
echo ""

echo "📋 5. Verificar interfaz nat64:"
if ip link show nat64 &>/dev/null; then
    echo "✅ Interfaz nat64 existe"
    ip link show nat64
    ip addr show nat64
else
    echo "❌ Interfaz nat64 NO existe"
fi
echo ""

echo "📋 6. Intentar crear interfaz manualmente:"
sudo tayga --mktun 2>&1
echo ""

echo "📋 7. Verificar si tayga puede ejecutarse:"
timeout 5 sudo tayga --nodetach 2>&1 &
TAYGA_PID=$!
sleep 3
if ps -p $TAYGA_PID > /dev/null; then
    echo "✅ Tayga se está ejecutando"
    sudo kill $TAYGA_PID 2>/dev/null
else
    echo "❌ Tayga no se pudo ejecutar"
fi
echo ""

echo "📋 8. Verificar permisos:"
ls -la /usr/sbin/tayga
echo ""

echo "📋 9. Verificar archivo de servicio systemd:"
if [ -f /etc/systemd/system/tayga.service ]; then
    echo "✅ /etc/systemd/system/tayga.service existe"
    cat /etc/systemd/system/tayga.service
else
    echo "❌ /etc/systemd/system/tayga.service NO existe"
fi
echo ""

echo "📋 10. Verificar IP forwarding:"
echo "IPv4 forwarding: $(cat /proc/sys/net/ipv4/ip_forward)"
echo "IPv6 forwarding: $(cat /proc/sys/net/ipv6/conf/all/forwarding)"
echo ""

echo "════════════════════════════════════════"
echo "🔍 FIN DEL DIAGNÓSTICO"
echo "════════════════════════════════════════"
