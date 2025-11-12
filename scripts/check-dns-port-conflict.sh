#!/bin/bash
# Script para diagnosticar conflictos de puerto 53 entre BIND9 y systemd-resolved

echo "🔍 Diagnóstico de conflicto de puerto DNS (53)"
echo "=============================================="
echo ""

echo "1️⃣  Servicios escuchando en puerto 53:"
echo "----------------------------------------"
sudo netstat -tulpn | grep :53 | grep -E "(LISTEN|udp)"
echo ""

echo "2️⃣  Estado de systemd-resolved:"
echo "----------------------------------------"
systemctl status systemd-resolved --no-pager | head -n 5
echo ""

echo "3️⃣  Configuración de systemd-resolved:"
echo "----------------------------------------"
if [ -f /etc/systemd/resolved.conf ]; then
    grep -E "^(DNS|DNSStubListener|Domains)=" /etc/systemd/resolved.conf || echo "Sin configuración personalizada"
else
    echo "Archivo no existe"
fi
echo ""

echo "4️⃣  Estado de BIND9:"
echo "----------------------------------------"
systemctl status bind9 --no-pager | head -n 5
echo ""

echo "5️⃣  Contenido de /etc/resolv.conf:"
echo "----------------------------------------"
cat /etc/resolv.conf
echo ""

echo "6️⃣  Prueba de resolución DNS local:"
echo "----------------------------------------"
dig @127.0.0.1 gamecenter.lan AAAA +short
echo ""

echo "✅ Diagnóstico completado"
echo ""
echo "💡 Solución recomendada:"
echo "   - Si ves 'systemd-resolved' en puerto 53: Configurar DNSStubListener=no"
echo "   - Si ves solo 'named': Todo está correcto"
