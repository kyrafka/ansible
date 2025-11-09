#!/bin/bash
# Script para ejecutar un rol específico
# Uso: ./run-role.sh common
# Uso: ./run-role.sh network
# Uso: ./run-role.sh firewall

if [ -z "$1" ]; then
    echo "❌ Debes especificar un rol"
    echo "Uso: $0 <rol>"
    echo "Roles disponibles: common, network, dns_bind, dhcpv6, firewall, storage"
    exit 1
fi

ROL=$1

cd ~/ansible
source ~/.ansible-venv/bin/activate

# Crear playbook temporal
cat > /tmp/run-single-role.yml <<EOF
---
- name: Ejecutar rol $ROL
  hosts: localhost
  connection: local
  become: true
  
  roles:
    - role: $ROL
EOF

echo "🚀 Ejecutando rol: $ROL"
ansible-playbook /tmp/run-single-role.yml --connection=local --become --ask-become-pass

# Limpiar
rm /tmp/run-single-role.yml
