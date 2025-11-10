#!/bin/bash
# Script maestro para ejecutar roles de Ansible
# Uso: ./run.sh [rol] o ./run.sh (para ejecutar todo)

cd ~/ansible
source ~/.ansible-venv/bin/activate

if [ -z "$1" ]; then
    echo "🚀 Ejecutando playbook completo..."
    ansible-playbook site.yml --connection=local --become --vault-password-file .vault_pass -e "ansible_become_password={{ vault_sudo_password }}"
else
    echo "🚀 Ejecutando rol: $1"
    ansible-playbook site.yml --connection=local --become --vault-password-file .vault_pass -e "ansible_become_password={{ vault_sudo_password }}" --tags "$1"
fi
