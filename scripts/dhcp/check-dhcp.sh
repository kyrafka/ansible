#!/bin/bash
# Script para verificar el estado del servidor DHCP

echo "════════════════════════════════════════════════════════"
echo "🔍 Verificación del Servidor DHCPv6"
echo "════════════════════════════════════════════════════════"
echo ""

# 1. Estado del servicio
echo "📊 Estado del servicio:"
systemctl status isc-dhcp-server6 --no-pager | head -15
echo ""

# 2. Verificar si está escuchando
echo "🎧 Puertos escuchando:"
sudo ss -tulnp | grep dhcpd
echo ""

# 3. Ver últimos logs
echo "📝 Últimos logs:"
journalctl -u isc-dhcp-server6 -n 10 --no-pager
echo ""

# 4. Ver leases activos
echo "📋 Leases activos:"
if [ -f /var/lib/dhcp/dhcpd6.leases ]; then
    sudo cat /var/lib/dhcp/dhcpd6.leases | grep -A 5 "^lease"
else
    echo "No hay archivo de leases"
fi
echo ""

# 5. Ver configuración de red
echo "🌐 Configuración de ens34:"
ip -6 addr show ens34
echo ""

# 6. Verificar forwarding
echo "🔀 IPv6 Forwarding:"
sysctl net.ipv6.conf.all.forwarding
echo ""

# 7. Verificar NAT66
echo "🔄 Reglas NAT66:"
sudo ip6tables -t nat -L -v -n
echo ""

echo "════════════════════════════════════════════════════════"
echo "✅ Verificación completada"
echo "════════════════════════════════════════════════════════"
