#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Script para limpiar leases antiguos de DHCP
# ═══════════════════════════════════════════════════════════════

echo "════════════════════════════════════════════════════════════"
echo "  LIMPIAR LEASES DHCP ANTIGUOS"
echo "════════════════════════════════════════════════════════════"
echo ""

echo "⚠️  ADVERTENCIA: Esto eliminará todos los leases DHCP actuales"
echo "    Los clientes recibirán nuevas IPs cuando se reconecten"
echo ""

read -p "¿Continuar? (s/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "Cancelado."
    exit 0
fi

echo ""
echo "━━━ 1. Mostrando leases actuales ━━━"
if [ -f /var/lib/dhcp/dhcpd6.leases ]; then
    echo "Leases activos:"
    sudo grep "^lease" /var/lib/dhcp/dhcpd6.leases | tail -10
    echo ""
else
    echo "No hay archivo de leases"
fi

echo "━━━ 2. Deteniendo servicio DHCP ━━━"
sudo systemctl stop isc-dhcp-server

echo ""
echo "━━━ 3. Respaldando leases antiguos ━━━"
if [ -f /var/lib/dhcp/dhcpd6.leases ]; then
    sudo cp /var/lib/dhcp/dhcpd6.leases /var/lib/dhcp/dhcpd6.leases.backup-$(date +%Y%m%d-%H%M%S)
    echo "✓ Backup creado"
fi

echo ""
echo "━━━ 4. Limpiando archivo de leases ━━━"
sudo truncate -s 0 /var/lib/dhcp/dhcpd6.leases
echo "✓ Archivo limpiado"

echo ""
echo "━━━ 5. Iniciando servicio DHCP ━━━"
sudo systemctl start isc-dhcp-server

echo ""
echo "━━━ 6. Verificando estado ━━━"
sudo systemctl status isc-dhcp-server --no-pager -l

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  LIMPIEZA COMPLETADA"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Ahora en tus clientes:"
echo "  Windows: Restart-NetAdapter -Name 'Ethernet1'"
echo "  Linux:   sudo dhclient -6 -r && sudo dhclient -6"
echo ""
echo "Las nuevas IPs se asignarán secuencialmente desde ::10"
echo ""
