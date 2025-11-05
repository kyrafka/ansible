#!/bin/bash

VAULT_FILE="group_vars/all.vault.yml"

echo "🔐 Cargando credenciales GOVC desde Ansible Vault..."

# --- Detectar si está cifrado ---
if head -1 "$VAULT_FILE" | grep -q "^\$ANSIBLE_VAULT"; then
    echo "🔑 Ingresa la contraseña del vault:"
    read -s VAULT_PASS
    VAULT_CONTENT=$(echo "$VAULT_PASS" | ansible-vault view "$VAULT_FILE" --vault-password-file=/dev/stdin)
else
    VAULT_CONTENT=$(cat "$VAULT_FILE")
fi

get_vault_value() {
    local key="$1"
    echo "$VAULT_CONTENT" | grep "^$key:" | head -1 | awk -F': ' '{print $2}' | tr -d '"'
}

export GOVC_URL=$(get_vault_value "vault_govc_url")
export GOVC_USERNAME=$(get_vault_value "vault_govc_username")
export GOVC_PASSWORD=$(get_vault_value "vault_govc_password")
export GOVC_INSECURE=$(get_vault_value "vault_govc_insecure")

echo "✅ GOVC cargado:"
echo "URL: $GOVC_URL"
echo "User: $GOVC_USERNAME"
