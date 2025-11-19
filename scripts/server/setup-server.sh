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
echo "⚠️  IMPORTANTE: Este script es SOLO para el SERVIDOR"
echo "    NO ejecutar en máquinas cliente/desktop"
echo ""
echo "Este script configurará:"
echo "  1. Paquetes base del sistema"
echo "  2. Red IPv6 (ens33, ens34) y NAT66"
echo "  3. Servidor DNS (BIND9)"
echo "  4. Servidor DHCPv6"
echo "  5. Firewall (UFW + fail2ban)"
echo "  6. Almacenamiento NFS"
echo ""
echo "NO creará usuarios adicionales (solo servicios de red)"
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

# Verificar si ansible-playbook está disponible
if ! command -v ansible-playbook &> /dev/null; then
    echo "❌ Error: ansible-playbook no está instalado"
    echo "Instala Ansible con: sudo apt install ansible"
    exit 1
fi

# Ejecutar playbook del SERVIDOR (NO el de ubuntu_desktop)
echo "📝 Ejecutando: site.yml (playbook del servidor)"
echo "   Este playbook NO incluye roles de usuario (ubuntu_desktop/seguridad)"
echo ""
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
