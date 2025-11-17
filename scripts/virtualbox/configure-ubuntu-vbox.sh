#!/bin/bash
# ════════════════════════════════════════════════════════════════
# Script para configurar VM Ubuntu Desktop en VirtualBox con Ansible
# ════════════════════════════════════════════════════════════════

set -e

echo "════════════════════════════════════════════════════════"
echo "🔧 Configurar Ubuntu Desktop en VirtualBox"
echo "════════════════════════════════════════════════════════"
echo ""

# Verificar que Ansible está instalado
if ! command -v ansible-playbook &> /dev/null; then
    echo "❌ Ansible no está instalado"
    echo ""
    echo "Instala con:"
    echo "  sudo apt install ansible -y"
    exit 1
fi

echo "✅ Ansible encontrado"
echo ""

echo "📋 Configuración:"
echo "  VM: ubuntu-desktop-local"
echo "  SSH: localhost:2222"
echo "  Usuario: admin"
echo "  Contraseña: 123"
echo ""

echo "Se configurará:"
echo "  - 3 usuarios (admin, auditor, gamer01)"
echo "  - SSH restringido a admin"
echo "  - Firewall (UFW)"
echo "  - Directorios compartidos"
echo ""

read -p "¿Continuar? [S/n]: " confirm
if [[ "$confirm" =~ ^[nN]$ ]]; then
    echo "Operación cancelada"
    exit 0
fi

echo ""
echo "🚀 Ejecutando playbook de Ansible..."
echo ""

# Ejecutar playbook
ansible-playbook -i inventory/virtualbox.ini playbooks/configure-virtualbox-ubuntu.yml

if [ $? -eq 0 ]; then
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "✅ Configuración completada"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "Conectar por SSH:"
    echo "  ssh -p 2222 admin@localhost"
    echo ""
else
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "❌ Error en la configuración"
    echo "════════════════════════════════════════════════════════"
    echo ""
    exit 1
fi
