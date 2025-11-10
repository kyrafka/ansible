#!/bin/bash
# Script para encriptar el archivo de variables sensibles

cd ~/ansible
source ~/.ansible-venv/bin/activate

echo "🔐 Encriptando group_vars/all.vault.yml..."
ansible-vault encrypt group_vars/all.vault.yml --vault-password-file .vault_pass

echo "✅ Archivo encriptado correctamente"
echo "Para editarlo usa: ansible-vault edit group_vars/all.vault.yml --vault-password-file .vault_pass"
