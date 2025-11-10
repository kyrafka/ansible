#!/bin/bash
# Script para configurar el servidor Ubuntu con todos los servicios
# Ejecutar DENTRO del servidor Ubuntu

echo "════════════════════════════════════════════════════════"
echo "🚀 Configurando Servidor GameCenter"
echo "════════════════════════════════════════════════════════"
echo ""

# Verificar que estamos en el servidor
if [ ! -d ~/ansible ]; then
    echo "❌ Error: Directorio ~/ansible no encontrado"
    echo "   Ejecuta este script desde el servidor Ubuntu"
    exit 1
fi

cd ~/ansible

# Activar entorno virtual
if [ -f ~/.ansible-venv/bin/activate ]; then
    source ~/.ansible-venv/bin/activate
    echo "✅ Entorno Ansible activado"
else
    echo "❌ Error: Entorno virtual de Ansible no encontrado"
    echo "   Ejecuta primero: source activate-ansible.sh"
    exit 1
fi

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

# Ejecutar playbook completo
ansible-playbook site.yml \
    --connection=local \
    --become \
    --vault-password-file .vault_pass \
    -e "ansible_become_password={{ vault_sudo_password }}"

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
