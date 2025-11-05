#!/bin/bash
# ✅ Script ÚNICO: valida ESXi, carga GOVC desde vault y crea la VM automáticamente

set -euo pipefail

VAULT_FILE="group_vars/all.vault.yml"
DATASTORE="datastore1"
NETWORK_NAME="VM Network"
SEED_ISO="seed.iso"

VM_NAME="ubuntu-auto"
VM_CPU=2
VM_RAM_MB=2048
VM_DISK_GB=20


echo "🚀 SCRIPT MAESTRO — VALIDACIÓN + CREACIÓN DE VM"
echo "=================================================="
echo ""


# ----------------------------------------------------
# 1. Cargar credenciales desde vault
# ----------------------------------------------------
echo "🔐 Cargando credenciales desde Vault..."

if head -1 "$VAULT_FILE" | grep -q "^\$ANSIBLE_VAULT"; then
    read -s -p "🔑 Ingresa la contraseña del vault: " VAULT_PASS
    echo ""
    VAULT_CONTENT=$(echo "$VAULT_PASS" | ansible-vault view "$VAULT_FILE" --vault-password-file=/dev/stdin)
else
    VAULT_CONTENT=$(cat "$VAULT_FILE")
fi

get_vault_value() {
    local key="$1"
    echo "$VAULT_CONTENT" | grep "^$key:" | head -1 | sed 's/^[^:]*:[[:space:]]*//' | sed 's/"//g'
}

ESXI_HOST=$(get_vault_value "vault_vcenter_hostname")
ESXI_PORT=$(get_vault_value "vault_vcenter_port")
ESXI_USER=$(get_vault_value "vault_vcenter_username")
ESXI_PASS=$(get_vault_value "vault_vcenter_password")

export GOVC_URL="https://$ESXI_USER:${ESXI_PASS}@$ESXI_HOST:$ESXI_PORT"
export GOVC_INSECURE=1

echo "✅ GOVC cargado:"
echo "  URL: $GOVC_URL"
echo "  User: $ESXI_USER"
echo ""


# ----------------------------------------------------
# 2. Verificar govc (instalar si falta)
# ----------------------------------------------------
if ! command -v govc >/dev/null 2>&1; then
    echo "📦 Instalando govc automáticamente..."
    mkdir -p "$HOME/bin"
    curl -L -o /tmp/govc.tar.gz "https://github.com/vmware/govmomi/releases/latest/download/govc_$(uname -s)_$(uname -m).tar.gz"
    tar -C "$HOME/bin" -xzf /tmp/govc.tar.gz govc
    chmod +x "$HOME/bin/govc"
fi
export PATH="$HOME/bin:$PATH"

echo "✅ govc disponible"
echo ""


# ----------------------------------------------------
# 3. Validaciones antes de crear la VM
# ----------------------------------------------------
echo "🔍 Validando conexión con ESXi..."
govc about >/dev/null
echo "✅ ESXi responde"#!/bin/bash
# SCRIPT MAESTRO — VALIDACIÓN + CREACIÓN DE VM (Versión Corregida)

set -e

echo "🚀 SCRIPT MAESTRO — VALIDACIÓN + CREACIÓN DE VM"
echo "=================================================="
echo ""

##############################################
# 1) Cargar credenciales GOVC desde Vault
##############################################
echo "🔐 Cargando credenciales desde Vault..."
ansible-vault view vault/govc_credentials.yml >/tmp/govc_creds.yml

export GOVC_URL=$(yq '.govc.url' /tmp/govc_creds.yml)
export GOVC_USERNAME=$(yq '.govc.username' /tmp/govc_creds.yml)
export GOVC_PASSWORD=$(yq '.govc.password' /tmp/govc_creds.yml)
export GOVC_INSECURE=1

echo "✅ GOVC cargado:"
echo "  URL: $GOVC_URL"
echo "  User: $GOVC_USERNAME"
echo ""

##############################################
# 2) Validar govc
##############################################
if ! command -v govc &>/dev/null; then
    echo "❌ govc no instalado"
    exit 1
fi
echo "✅ govc disponible"
echo ""

##############################################
# 3) Validaciones ESXi
##############################################

echo "🔍 Validando conexión con ESXi..."
govc about >/dev/null
echo "✅ ESXi responde"

echo "🔍 Validando datastore..."
DATASTORE="datastore1"
govc datastore.info "$DATASTORE" >/dev/null
echo "✅ Datastore OK"

##############################################
# 4) Listar ISOs del datastore y seleccionar
##############################################

echo "🔍 Buscando ISOs disponibles..."
ISO_LIST=$(govc datastore.ls "$DATASTORE" | grep -E '\.iso$' || true)

if [[ -z "$ISO_LIST" ]]; then
    echo "❌ No hay ISOs en el datastore. Sube uno."
    exit 1
fi

echo ""
echo "📀 ISOs disponibles:"
echo "----------------------------"

i=1
declare -A ISO_MAP

while read -r iso; do
    echo "  $i) $iso"
    ISO_MAP[$i]="$iso"
    ((i++))
done <<< "$ISO_LIST"

echo ""
read -p "👉 Selecciona el número del ISO que deseas usar: " ISO_CHOICE

ISO_PATH="${ISO_MAP[$ISO_CHOICE]}"

if [[ -z "$ISO_PATH" ]]; then
    echo "❌ Selección inválida"
    exit 1
fi

echo ""
echo "✅ ISO seleccionada: $ISO_PATH"
echo ""

##############################################
# 5) Validar PortGroup
##############################################

PORTGROUP="VM Network"

echo "🔍 Validando PortGroup..."
if ! govc find / -type n -name "$PORTGROUP" >/dev/null; then
    echo "❌ PortGroup no encontrado"
    exit 1
fi
echo "✅ PortGroup OK"
echo ""

##############################################
# 6) Validar si la VM existe (MÉTODO CORREGIDO)
##############################################

VM_NAME="ubuntu-auto"

echo "🔍 Verificando si la VM ya existe..."

VM_EXISTS=$(govc vm.info -json "$VM_NAME" 2>/dev/null | jq -r '.VirtualMachines | length')

if [[ "$VM_EXISTS" == "1" ]]; then
    echo "⚠️  VM existente encontrada. Eliminando..."
    govc vm.destroy "$VM_NAME"
else
    echo "✅ No existe una VM previa con ese nombre."
fi
echo ""

##############################################
# 7) Crear VM nueva
##############################################

echo "🧱 Creando VM nueva..."
govc vm.create \
    -m=4096 \
    -c=2 \
    -disk=20GB \
    -on=false \
    -g=ubuntu64Guest \
    -net="$PORTGROUP" \
    -iso="$ISO_PATH" \
    "$VM_NAME"

echo "✅ VM creada"
echo ""

##############################################
# 8) Adjuntar seed.iso si existe
##############################################

if govc datastore.ls "$DATASTORE/seed.iso" >/dev/null 2>&1; then
    echo "📎 Adjuntando seed.iso..."
    govc device.cdrom.insert -vm "$VM_NAME" "$DATASTORE/seed.iso"
fi

##############################################
# 9) Encender VM
##############################################

echo "⚡ Encendiendo VM..."
govc vm.power -on "$VM_NAME"

echo ""
echo "🎉 VM lista y arrancando con autoinstall"

a
echo "🔍 Validando datastore..."
govc datastore.info "$DATASTORE" >/dev/null
echo "✅ Datastore OK"

echo "🔍 Buscando ISOs disponibles..."
ISO_LIST=$(govc datastore.ls -ds="$DATASTORE" | grep -iE '\.iso$' || true)

if [ -z "$ISO_LIST" ]; then
    echo "❌ No hay ISOs en el datastore. Sube uno."
    exit 1
fi

echo ""
echo "📀 ISOs disponibles:"
echo "----------------------------"

i=1
declare -A ISO_MAP

while read -r iso; do
    ISO_MAP[$i]="$iso"
    echo "  $i) $iso"
    ((i++))
done <<< "$ISO_LIST"

echo ""
read -p "👉 Selecciona el número del ISO que deseas usar: " ISO_CHOICE

if [[ -z "${ISO_MAP[$ISO_CHOICE]}" ]]; then
    echo "❌ Opción inválida."
    exit 1
fi

SELECTED_ISO="${ISO_MAP[$ISO_CHOICE]}"
INSTALL_ISO_PATH="/vmfs/volumes/$DATASTORE/$SELECTED_ISO"

echo ""
echo "✅ ISO seleccionada: $SELECTED_ISO"
echo ""


echo "🔍 Validando PortGroup..."
govc host.portgroup.info | grep -q "$NETWORK_NAME"
echo "✅ PortGroup OK"
echo ""


# ----------------------------------------------------
# 4. Borrar VM previa si existe
# ----------------------------------------------------
if govc vm.info "$VM_NAME" >/dev/null 2>&1; then
    echo "⚠️  VM existente encontrada. Eliminando..."
    govc vm.destroy "$VM_NAME"
    echo "✅ VM eliminada"
fi


# ----------------------------------------------------
# 5. Crear VM
# ----------------------------------------------------
echo "📦 Creando VM base..."
govc vm.create \
    -on=false \
    -m="$VM_RAM_MB" \
    -c="$VM_CPU" \
    -ds="$DATASTORE" \
    -g="ubuntu64Guest" \
    -net="$NETWORK_NAME" \
    -net.adapter="e1000" \
    "$VM_NAME"

echo "✅ VM creada"


# ----------------------------------------------------
# 6. Crear disco
# ----------------------------------------------------
echo "💽 Agregando disco ${VM_DISK_GB}GB..."
govc vm.disk.create \
    -vm="$VM_NAME" \
    -size="${VM_DISK_GB}G"
echo "✅ Disco añadido"


# ----------------------------------------------------
# 7. Montar ISO y seed.iso
# ----------------------------------------------------
echo "📀 Montando ISO seleccionada..."
govc device.cdrom.insert -vm="$VM_NAME" "$INSTALL_ISO_PATH"
echo "✅ ISO montada"

echo "☁️ Montando seed.iso..."
govc device.cdrom.insert -vm="$VM_NAME" "/vmfs/volumes/$DATASTORE/$SEED_ISO"
echo "✅ seed.iso montado"


# ----------------------------------------------------
# 8. ENCENDER VM
# ----------------------------------------------------
echo "⚡ Encendiendo VM..."
govc vm.power -on "$VM_NAME"

echo ""
echo "✅✅✅ VM CREADA Y ENCENDIDA CON ÉXITO ✅✅✅"
echo ""
