#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Script para aplicar configuración DHCP secuencial
# ═══════════════════════════════════════════════════════════════

echo "════════════════════════════════════════════════════════════"
echo "  APLICAR CONFIGURACIÓN DHCP SECUENCIAL"
echo "════════════════════════════════════════════════════════════"
echo ""

echo "Este script cambiará el rango DHCP a:"
echo "  Inicio: 2025:db8:10::10"
echo "  Fin:    2025:db8:10::50"
echo ""
echo "Las IPs se asignarán secuencialmente: ::10, ::11, ::12, ::13, etc."
echo ""

read -p "¿Continuar? (s/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "Cancelado."
    exit 0
fi

echo ""
echo "━━━ 1. Ejecutando playbook de DHCPv6 ━━━"
ansible-playbook -i inventory/hosts.ini playbooks/dhcpv6.yml --ask-become-pass

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Configuración aplicada correctamente"
    echo ""
    echo "━━━ 2. Verificando configuración ━━━"
    echo ""
    
    echo "Rango DHCP configurado:"
    sudo grep "range6" /etc/dhcp/dhcpd6.conf
    echo ""
    
    echo "━━━ 3. Reiniciando servicios ━━━"
    sudo systemctl restart isc-dhcp-server
    sudo systemctl restart radvd
    
    echo ""
    echo "━━━ 4. Estado de servicios ━━━"
    sudo systemctl status isc-dhcp-server --no-pager -l
    echo ""
    sudo systemctl status radvd --no-pager -l
    
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "  CONFIGURACIÓN COMPLETADA"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    echo "Ahora en tus clientes Windows/Ubuntu:"
    echo "  1. Reinicia el adaptador de red"
    echo "  2. Espera 10-30 segundos"
    echo "  3. Verifica la IP asignada"
    echo ""
    echo "Las IPs se asignarán en orden:"
    echo "  - Primer cliente:  2025:db8:10::10"
    echo "  - Segundo cliente: 2025:db8:10::11"
    echo "  - Tercer cliente:  2025:db8:10::12"
    echo "  - etc..."
    echo ""
else
    echo ""
    echo "✗ Error al aplicar la configuración"
    exit 1
fi
