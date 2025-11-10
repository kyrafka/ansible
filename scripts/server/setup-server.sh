#!/bin/bash
# Script para configurar el servidor Ubuntu con todos los servicios
# Ejecutar desde la raíz del proyecto: bash scripts/server/setup-server.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "════════════════════════════════════════════════════════"
echo "🚀 Configurando Servidor GameCenter"
echo "════════════════════════════════════════════════════════"
echo ""

echo ""
echo "Este script configurará:"
echo "  1. Paquetes base del sistema"
echo "  2. Red IPv6 (ens33, ens34) y NAT66"
echo "  3. Servidor DNS (BIND9)"
echo "  4. Servidor DHCPv6"
echo "  5. Firewall (UFW + fail2ban)"
echo "  6. Almacenamiento NFS"
echo ""
read -p "¿Continuar? (s/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "❌ Cancelado por el usuario"
    exit 0
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "🔧 Ejecutando configuración completa..."
echo "════════════════════════════════════════════════════════"
echo ""

cd "$PROJECT_ROOT"

if [ -f ~/.ansible-venv/bin/activate ]; then
    source ~/.ansible-venv/bin/activate
fi

# Ejecutar playbook completo (localmente)
ansible-playbook -i inventory/hosts.ini site.yml --connection=local --become --ask-become-pass
# Verificar resultado
if [ $? -eq 0 ]; then
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "✅ Servidor configurado exitosamente"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "Servicios configurados:"
    echo "  ✅ Red IPv6: 2025:db8:10::2/64"
    echo "  ✅ DNS: puerto 53"
    echo "  ✅ DHCP: puerto 547"
    echo "  ✅ Firewall: activo"
    echo "  ✅ NFS: /srv/nfs/games, /srv/nfs/shared"
    echo ""
    echo "Verificar servicios:"
    echo "  systemctl status named"
    echo "  systemctl status isc-dhcp-server6"
    echo "  sudo ufw status"
    echo "  showmount -e localhost"
    echo ""
else
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "❌ Error en la configuración"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "Revisa los errores arriba y vuelve a intentar"
    echo ""
    exit 1
fi
