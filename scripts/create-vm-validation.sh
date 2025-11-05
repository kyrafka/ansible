#!/bin/bash
# ✅ Script de COMPROBACIÓN para ESXi
# Si TODO está correcto → ejecuta el script creador de VM

set -euo pipefail


VAULT_FILE="group_vars/all.vault.yml"
DATASTORE_REQUERIDO="datastore1"
ISO_REQUERIDO="ubuntu-24.04.3-live-server-amd64.iso"
NETWORK_REQUERIDO="VM Network"

echo "🔍 INICIANDO VERIFICACIÓN COMPLETA DE ESXi"
echo "==========================================="
echo ""



# ------------------------------------------------
# 2. Verificar Vault
# ------------------------------------------------
if [ ! -f "$VAULT_FILE" ]; then
    echo "❌ No se encontró $VAULT_FILE"
    exit 1
fi

echo "🔐 Verificando Vault..."
if head -1 "$VAULT_FILE" | grep -q "^\$ANSIBLE_VAULT"; then
    echo "🔒 Vault cifrado detectado"
    read -s -p "🔑 Ingresa la contraseña del vault: " VAULT_PASSWORD
    echo ""
    VAULT_CONTENT=$(echo "$VAULT_PASSWORD" | ansible-vault view "$VAULT_FILE" --vault-password-file=/dev/stdin)
else
    echo "🔓 Vault sin cifrar"
    VAULT_CONTENT=$(cat "$VAULT_FILE")
fi

get_vault_value() {
    local key="$1"
    echo "$VAULT_CONTENT" | grep "^$key:" | head -1 | sed 's/^[^:]*:[[:space:]]*//' | sed 's/^"//' | sed 's/"$//'
}

ESXI_HOST=$(get_vault_value "vault_vcenter_hostname")
ESXI_WEB_PORT=$(get_vault_value "vault_vcenter_port")
ESXI_USER=$(get_vault_value "vault_vcenter_username")
ESXI_PASS=$(get_vault_value "vault_vcenter_password")

if [ -z "$ESXI_HOST" ] || [ -z "$ESXI_USER" ] || [ -z "$ESXI_PASS" ]; then
    echo "❌ Error cargando credenciales del vault"
    exit 1
fi

echo "✅ Credenciales cargadas correctamente"

export GOVC_URL="https://$ESXI_USER:${ESXI_PASS}@$ESXI_HOST:$ESXI_WEB_PORT"
export GOVC_INSECURE=1

# ------------------------------------------------
# 3. Verificar govc instalado
# ------------------------------------------------
if ! command -v govc >/dev/null 2>&1; then
    echo "📦 Instalando govc automáticamente..."
    mkdir -p "$HOME/bin"
    curl -L -o /tmp/govc.tar.gz "https://github.com/vmware/govmomi/releases/latest/download/govc_$(uname -s)_$(uname -m).tar.gz"
    tar -C "$HOME/bin" -xzf /tmp/govc.tar.gz govc
    chmod +x "$HOME/bin/govc"
    rm /tmp/govc.tar.gz
fi
GOVC_CMD="$HOME/bin/govc"
export PATH="$HOME/bin:$PATH"

echo "✅ govc disponible"

# ------------------------------------------------
# 4. Verificar conexión con ESXi
# ------------------------------------------------
echo "🔍 Verificando conexión con ESXi..."
echo "🔗 URL: https://$ESXI_HOST:$ESXI_WEB_PORT"
if ! $GOVC_CMD about >/dev/null 2>&1; then
    echo "❌ No se puede conectar a ESXi"
    echo "💡 Verifica:"
    echo "   - IP/hostname: $ESXI_HOST"
    echo "   - Puerto: $ESXI_WEB_PORT"
    echo "   - Usuario: $ESXI_USER"
    echo "   - Contraseña contiene caracteres especiales"
    exit 1
fi
echo "✅ Conectado a ESXi"

# ------------------------------------------------
# 5. Verificar datastore
# ------------------------------------------------
echo "🔍 Verificando datastore '$DATASTORE_REQUERIDO'..."
if ! $GOVC_CMD datastore.info "$DATASTORE_REQUERIDO" >/dev/null 2>&1; then
    echo "❌ Datastore no encontrado"
    exit 1
fi
echo "✅ Datastore encontrado"

# ------------------------------------------------
# 6. Verificar ISO
# ------------------------------------------------
echo "🔍 Verificando ISO '$ISO_REQUERIDO'..."
if ! $GOVC_CMD datastore.ls -ds="$DATASTORE_REQUERIDO" | grep -q "$ISO_REQUERIDO"; then
    echo "❌ La ISO no existe en el datastore"
    exit 1
fi
echo "✅ ISO encontrada"

# ------------------------------------------------
# 7. Verificar red (PortGroup)
# ------------------------------------------------
echo "🔍 Verificando red '$NETWORK_REQUERIDO'..."
if ! $GOVC_CMD host.portgroup.info | grep -q "$NETWORK_REQUERIDO"; then
    echo "❌ No existe el PortGroup '$NETWORK_REQUERIDO'"
    exit 1
fi
echo "✅ PortGroup encontrado"

# ------------------------------------------------
# 8. Verificar que ESXi NO esté en mantenimiento
# ------------------------------------------------
echo "🔍 Verificando modo de mantenimiento..."
if $GOVC_CMD host.service | grep -q "maintenance.*on"; then
    echo "❌ ESXi está en modo mantenimiento"
    exit 1
fi
echo "✅ ESXi no está en mantenimiento"

# ------------------------------------------------
# ✅ TODAS LAS VALIDACIONES OK
# ------------------------------------------------
echo ""
echo "✅✅✅ TODO CORRECTO — INICIANDO CREACIÓN DE VM ✅✅✅"
echo ""
