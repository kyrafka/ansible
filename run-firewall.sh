#!/bin/bash
# Script para ejecutar solo el rol de firewall

cd ~/ansible
source ~/.ansible-venv/bin/activate
ansible-playbook site.yml --connection=local --become --vault-password-file .vault_pass -e "ansible_become_password={{ vault_sudo_password }}" --tags firewall
