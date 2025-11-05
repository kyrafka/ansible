#!/bin/bash
set -euo pipefail

VM_NAME="ubuntu-template-$(date +%s)"
DATASTORE="datastore1"
ISO_PATH="ubuntu-24.04.3-live-server-amd64.iso"
RAM_GB=4
CPUS=2
DISK_GB=40
NETWORK="VM Network"

VAULT_FILE="group_vars/all.vault.yml"
VAULT_CONTENT=$(cat "$VAULT_FILE")

get_vault_value() {
    echo "$VAULT_CONTENT" | grep "^$1:" | head -1 | sed 's/^[^:]*:[[:space:]]*//' | sed 's/^"//' | sed 's/"$//'
}

ESXI_HOST=$(get_vault_value "vault_vcenter_hostname")
ESXI_WEB_PORT=$(get_vault_value "vault_vcenter_port")
ESXI_USER=$(get_vault_value "vault_vcenter_username")
ESXI_PASS=$(get_vault_value "vault_vcenter_password")

export GOVC_URL="https://$ESXI_USER:$ESXI_PASS@$ESXI_HOST:$ESXI_WEB_PORT"
export GOVC_INSECURE=1
GOVC_CMD="$HOME/bin/govc"
export PATH="$HOME/bin:$PATH"

genisoimage -output autoinstall.iso -volid cidata -joliet -rock cloud-init/user-data cloud-init/meta-data
$GOVC_CMD datastore.upload -ds="$DATASTORE" autoinstall.iso autoinstall-$VM_NAME.iso

$GOVC_CMD vm.create \
    -m=$((RAM_GB*1024)) \
    -c=$CPUS \
    -disk=${DISK_GB}GB \
    -net="$NETWORK" \
    -g=ubuntu64Guest \
    -on=false \
    "$VM_NAME"

$GOVC_CMD device.cdrom.add -vm="$VM_NAME"
$GOVC_CMD device.cdrom.insert -vm="$VM_NAME" -device=ide-200 "[$DATASTORE] $ISO_PATH"
$GOVC_CMD device.cdrom.insert -vm="$VM_NAME" -device=ide-201 "[$DATASTORE] autoinstall-$VM_NAME.iso"

$GOVC_CMD vm.change -vm="$VM_NAME" -e="boot.order=cdrom,hdd"

$GOVC_CMD vm.power -on "$VM_NAME"

while [ "$($GOVC_CMD vm.info "$VM_NAME" | grep "Power state:" | awk '{print $3}')" = "poweredOn" ]; do
    sleep 30
done

$GOVC_CMD device.cdrom.eject -vm="$VM_NAME" -device=ide-200
$GOVC_CMD device.cdrom.eject -vm="$VM_NAME" -device=ide-201
$GOVC_CMD datastore.rm -ds="$DATASTORE" autoinstall-$VM_NAME.iso
rm autoinstall.iso

$GOVC_CMD vm.markastemplate "$VM_NAME"

echo "Template creado: $VM_NAME"