#!/bin/bash
# Script para ejecutar solo el rol dhcpv6
# Ejecutar desde la raíz del proyecto: bash scripts/run/run-dhcp.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT"

# Verificar si ansible-playbook está disponible
if ! command -v ansible-playbook &> /dev/null; then
    echo "❌ Error: ansible-playbook no está instalado"
    echo "Instala Ansible con: sudo apt install ansible"
    exit 1
fi

ansible-playbook -i inventory/hosts.ini site.yml --connection=local --become --ask-become-pass --vault-password-file .vault_pass --tags dhcp
