#!/bin/bash
# Script para ejecutar el rol de NFS Server
# Ejecutar desde la raíz del proyecto: bash scripts/run/run-storage.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT"

# Verificar si ansible-playbook está disponible
if ! command -v ansible-playbook &> /dev/null; then
    echo "❌ Error: ansible-playbook no está instalado"
    echo "Instala Ansible con: sudo apt install ansible"
    exit 1
fi

echo "════════════════════════════════════════════════════════"
echo "📁 Configurando NFS Server"
echo "════════════════════════════════════════════════════════"
echo ""

ansible-playbook -i inventory/hosts.ini site.yml --connection=local --become --ask-become-pass --tags nfs
