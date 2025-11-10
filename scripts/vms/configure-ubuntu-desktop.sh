#!/bin/bash
# Script para configurar Ubuntu Desktop con su rol
# Ejecutar desde el servidor: bash scripts/vms/configure-ubuntu-desktop.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT"

echo "════════════════════════════════════════════════════════"
echo "🖥️  Configurar Ubuntu Desktop con Rol"
echo "════════════════════════════════════════════════════════"
echo ""

# Verificar ansible-playbook
if ! command -v ansible-playbook &> /dev/null; then
    echo "❌ Error: ansible-playbook no está instalado"
    exit 1
fi

# Verificar que existe el playbook
if [ ! -f "playbooks/configure-ubuntu-role.yml" ]; then
    echo "❌ Error: playbooks/configure-ubuntu-role.yml no existe"
    exit 1
fi

# Listar VMs Ubuntu en el inventario
echo "📋 VMs Ubuntu Desktop en el inventario:"
echo ""
if [ -f "inventory/hosts.ini" ]; then
    grep -A 20 "\[ubuntu_desktops\]" inventory/hosts.ini | grep -v "^#" | grep -v "^\[" | grep -v "^$" | nl -w2 -s') ' || echo "  Ninguna VM configurada"
else
    echo "❌ Error: inventory/hosts.ini no existe"
    exit 1
fi

echo ""
echo "Si no ves tu VM, agrégala primero en inventory/hosts.ini:"
echo "[ubuntu_desktops]"
echo "nombre-vm ansible_host=2025:db8:10::XX vm_role=cliente"
echo ""

# Pedir nombre de la VM
read -p "Nombre de la VM a configurar: " vm_name

if [ -z "$vm_name" ]; then
    echo "❌ El nombre no puede estar vacío"
    exit 1
fi

# Verificar que la VM está en el inventario
if ! grep -q "$vm_name" inventory/hosts.ini; then
    echo "❌ Error: $vm_name no está en inventory/hosts.ini"
    echo ""
    echo "Agrégala primero:"
    echo "[ubuntu_desktops]"
    echo "$vm_name ansible_host=2025:db8:10::XX vm_role=cliente"
    exit 1
fi

# Obtener el rol de la VM
vm_role=$(grep "$vm_name" inventory/hosts.ini | grep -o "vm_role=[^ ]*" | cut -d'=' -f2)

if [ -z "$vm_role" ]; then
    echo "⚠️  Advertencia: No se encontró vm_role para $vm_name"
    echo ""
    read -p "Rol (admin/auditor/cliente): " vm_role
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "Configuración:"
echo "  VM: $vm_name"
echo "  Rol: $vm_role"
echo "════════════════════════════════════════════════════════"
echo ""

read -p "¿Continuar? (s/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "❌ Cancelado"
    exit 0
fi

echo ""
echo "🔧 Configurando $vm_name con rol $vm_role..."
echo ""

# Ejecutar playbook
ansible-playbook playbooks/configure-ubuntu-role.yml --limit "$vm_name"

if [ $? -eq 0 ]; then
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "✅ $vm_name configurado exitosamente"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "Configuración aplicada según rol: $vm_role"
    echo ""
else
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "❌ Error al configurar $vm_name"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "Verifica:"
    echo "  - La VM tiene Ubuntu Desktop instalado"
    echo "  - La VM tiene red IPv6 funcionando"
    echo "  - Puedes hacer ping a la VM"
    echo "  - La IP en inventory/hosts.ini es correcta"
    echo ""
    exit 1
fi
