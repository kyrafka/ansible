#!/bin/bash
# Script para configurar Ubuntu Desktop con su rol
# Ejecutar desde el servidor: bash scripts/vms/configure-ubuntu-desktop.sh

set -euo pipefail  # Salir si hay error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT"

echo "════════════════════════════════════════════════════════"
echo "🖥️  Configurar Ubuntu Desktop con Rol"
echo "════════════════════════════════════════════════════════"
echo ""

# ============================================
# VALIDACIONES PREVIAS
# ============================================

echo "🔍 Validando requisitos previos..."
echo ""

# 1. Verificar ansible-playbook
if ! command -v ansible-playbook &> /dev/null; then
    echo "❌ Error: ansible-playbook no está instalado"
    echo "   Instala con: bash scripts/setup/setup-ansible-env.sh --auto"
    exit 1
fi
echo "✅ Ansible instalado"

# 2. Verificar que existe el playbook
if [ ! -f "playbooks/configure-ubuntu-role.yml" ]; then
    echo "❌ Error: playbooks/configure-ubuntu-role.yml no existe"
    exit 1
fi
echo "✅ Playbook encontrado"

# 3. Verificar que existe el rol
if [ ! -d "roles/ubuntu_desktop" ]; then
    echo "❌ Error: roles/ubuntu_desktop no existe"
    exit 1
fi
echo "✅ Rol ubuntu_desktop encontrado"

# 4. Verificar inventario
if [ ! -f "inventory/hosts.ini" ]; then
    echo "❌ Error: inventory/hosts.ini no existe"
    exit 1
fi
echo "✅ Inventario encontrado"

# 5. Verificar variables de grupo
if [ ! -f "group_vars/all.yml" ]; then
    echo "❌ Error: group_vars/all.yml no existe"
    exit 1
fi
echo "✅ Variables de grupo encontradas"

# 6. Verificar que existen las contraseñas en vault
if ! grep -q "ubuntu_desktop_users:" group_vars/all.yml; then
    echo "❌ Error: No se encontraron ubuntu_desktop_users en group_vars/all.yml"
    exit 1
fi
echo "✅ Usuarios Ubuntu Desktop configurados"

# 7. Verificar que existe el vault (si está encriptado)
if [ -f "group_vars/all.vault.yml" ]; then
    if [ ! -f ".vault_pass" ]; then
        echo "⚠️  Advertencia: Existe all.vault.yml pero no .vault_pass"
        echo "   Si las contraseñas están encriptadas, necesitas .vault_pass"
    else
        echo "✅ Vault password encontrado"
    fi
fi

echo ""
echo "════════════════════════════════════════════════════════"

# Listar VMs en ESXi
echo "📋 Listando VMs en ESXi..."
echo ""

# Obtener credenciales de ESXi
ESXI_HOST=$(grep "vcenter_hostname:" group_vars/ubpc.yml | awk '{print $2}' | tr -d '"')
ESXI_USER=$(grep "vcenter_username:" group_vars/ubpc.yml | awk '{print $2}' | tr -d '"' | sed 's/{{.*vault_vcenter_username.*}}/root/')
ESXI_PASS=$(grep "vault_vcenter_password:" group_vars/all.vault.yml | awk '{print $2}' | tr -d '"')

if [ -z "$ESXI_HOST" ] || [ -z "$ESXI_USER" ] || [ -z "$ESXI_PASS" ]; then
    echo "❌ Error: No se pudieron obtener credenciales de ESXi"
    exit 1
fi

echo "🔍 Conectando a ESXi: $ESXI_HOST"
echo ""

# Listar VMs usando govc o ansible
if command -v govc &> /dev/null; then
    export GOVC_URL="https://$ESXI_HOST"
    export GOVC_USERNAME="$ESXI_USER"
    export GOVC_PASSWORD="$ESXI_PASS"
    export GOVC_INSECURE=1
    
    VM_LIST=$(govc ls /ha-datacenter/vm 2>/dev/null | grep -v "Discovered" | sed 's|/ha-datacenter/vm/||')
else
    # Usar ansible para listar VMs
    VM_LIST=$(ansible localhost -m community.vmware.vmware_vm_info -a "hostname=$ESXI_HOST username=$ESXI_USER password=$ESXI_PASS validate_certs=no" 2>/dev/null | grep -o '"guest_name": "[^"]*"' | cut -d'"' -f4)
fi

if [ -z "$VM_LIST" ]; then
    echo "❌ Error: No se pudieron listar las VMs"
    echo ""
    echo "VMs en el inventario:"
    grep -A 20 "\[ubuntu_desktops\]" inventory/hosts.ini | grep -v "^#" | grep -v "^\[" | grep -v "^$" | nl -w2 -s') ' || echo "  Ninguna VM configurada"
    echo ""
    read -p "Nombre de la VM a configurar: " vm_name
else
    echo "VMs disponibles en ESXi:"
    echo ""
    echo "$VM_LIST" | nl -w2 -s') '
    echo ""
    read -p "Selecciona el número de la VM: " vm_number
    
    if [ -z "$vm_number" ]; then
        echo "❌ Debes seleccionar una VM"
        exit 1
    fi
    
    vm_name=$(echo "$VM_LIST" | sed -n "${vm_number}p")
    
    if [ -z "$vm_name" ]; then
        echo "❌ Número inválido"
        exit 1
    fi
    
    echo ""
    echo "✅ VM seleccionada: $vm_name"
    echo ""
    
    # Verificar estado de la VM
    echo "🔍 Verificando estado de la VM..."
    
    if command -v govc &> /dev/null; then
        VM_STATE=$(govc vm.info "$vm_name" 2>/dev/null | grep "Power state:" | awk '{print $3}')
    else
        VM_STATE=$(ansible localhost -m community.vmware.vmware_vm_info -a "hostname=$ESXI_HOST username=$ESXI_USER password=$ESXI_PASS validate_certs=no name=$vm_name" 2>/dev/null | grep -o '"power_state": "[^"]*"' | cut -d'"' -f4)
    fi
    
    echo "Estado actual: $VM_STATE"
    echo ""
    
    if [ "$VM_STATE" == "poweredOff" ] || [ "$VM_STATE" == "off" ]; then
        echo "⚠️  La VM está apagada"
        read -p "¿Encender la VM? (s/n): " -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Ss]$ ]]; then
            echo "🔌 Encendiendo VM..."
            
            if command -v govc &> /dev/null; then
                govc vm.power -on "$vm_name"
            else
                ansible localhost -m community.vmware.vmware_guest_powerstate -a "hostname=$ESXI_HOST username=$ESXI_USER password=$ESXI_PASS validate_certs=no name=$vm_name state=powered-on" &> /dev/null
            fi
            
            echo "✅ VM encendida"
            echo "⏳ Esperando 30 segundos para que arranque..."
            sleep 30
        else
            echo "❌ No se puede configurar una VM apagada"
            exit 1
        fi
    elif [ "$VM_STATE" == "poweredOn" ] || [ "$VM_STATE" == "on" ]; then
        echo "✅ La VM está encendida"
    else
        echo "❌ Estado desconocido: $VM_STATE"
        exit 1
    fi
fi

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
echo "✅ VM encontrada en inventario"

# Obtener el rol de la VM
vm_role=$(grep "$vm_name" inventory/hosts.ini | grep -o "vm_role=[^ ]*" | cut -d'=' -f2)

if [ -z "$vm_role" ]; then
    echo "⚠️  Advertencia: No se encontró vm_role para $vm_name"
    echo ""
    read -p "Rol (admin/auditor/cliente): " vm_role
fi

# Validar que el rol es válido
if [[ ! "$vm_role" =~ ^(admin|auditor|cliente)$ ]]; then
    echo "❌ Error: Rol inválido '$vm_role'"
    echo "   Debe ser: admin, auditor o cliente"
    exit 1
fi
echo "✅ Rol válido: $vm_role"

# Obtener la IP de la VM
vm_ip=$(grep "$vm_name" inventory/hosts.ini | grep -o "ansible_host=[^ ]*" | cut -d'=' -f2)

if [ -z "$vm_ip" ]; then
    echo "❌ Error: No se encontró ansible_host para $vm_name"
    exit 1
fi
echo "✅ IP encontrada: $vm_ip"

# ============================================
# VALIDAR CONECTIVIDAD
# ============================================

echo ""
echo "🔍 Validando conectividad con $vm_name ($vm_ip)..."
echo ""

# Verificar ping IPv6
if ! ping6 -c 2 -W 3 "$vm_ip" &> /dev/null; then
    echo "❌ Error: No se puede hacer ping a $vm_ip"
    echo ""
    echo "Verifica:"
    echo "  - La VM está encendida"
    echo "  - La VM tiene red IPv6 configurada"
    echo "  - La IP en inventory/hosts.ini es correcta"
    echo ""
    exit 1
fi
echo "✅ Ping exitoso"

# Verificar SSH
echo "🔍 Verificando acceso SSH..."
if ! ansible "$vm_name" -m ping &> /dev/null; then
    echo "❌ Error: No se puede conectar por SSH a $vm_name"
    echo ""
    echo "Verifica:"
    echo "  - SSH está habilitado en la VM"
    echo "  - Las credenciales en inventory/hosts.ini son correctas"
    echo "  - El firewall permite SSH"
    echo ""
    echo "Intenta manualmente:"
    echo "  ssh usuario@$vm_ip"
    echo ""
    exit 1
fi
echo "✅ SSH funcionando"

# Verificar que es Ubuntu
echo "🔍 Verificando sistema operativo..."
os_check=$(ansible "$vm_name" -m shell -a "lsb_release -si" 2>/dev/null | grep -i ubuntu || echo "")
if [ -z "$os_check" ]; then
    echo "❌ Error: La VM no parece ser Ubuntu"
    echo "   Este script solo funciona con Ubuntu Desktop"
    exit 1
fi
echo "✅ Sistema operativo: Ubuntu"

# Verificar privilegios sudo
echo "🔍 Verificando privilegios sudo..."
if ! ansible "$vm_name" -m shell -a "sudo -n true" -b &> /dev/null; then
    echo "⚠️  Advertencia: No se pudo verificar sudo sin contraseña"
    echo "   Puede que necesites ingresar la contraseña durante la ejecución"
fi
echo "✅ Privilegios verificados"

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
echo "════════════════════════════════════════════════════════"
echo "🔧 Ejecutando configuración..."
echo "════════════════════════════════════════════════════════"
echo ""

# Crear backup de configuración actual (si existe)
echo "📦 Creando backup de configuración..."
timestamp=$(date +%Y%m%d_%H%M%S)
backup_dir="backups/ubuntu-desktop-$vm_name-$timestamp"
mkdir -p "$backup_dir"

# Guardar configuración actual
ansible "$vm_name" -m shell -a "cat /etc/ssh/sshd_config" > "$backup_dir/sshd_config.bak" 2>/dev/null || true
ansible "$vm_name" -m shell -a "sudo ufw status verbose" -b > "$backup_dir/ufw_status.bak" 2>/dev/null || true
echo "✅ Backup creado en $backup_dir"

echo ""
echo "🔧 Configurando $vm_name con rol $vm_role..."
echo ""

# Ejecutar playbook con validación
if ansible-playbook playbooks/configure-ubuntu-role.yml --limit "$vm_name" --check; then
    echo ""
    echo "✅ Validación en modo dry-run exitosa"
    echo ""
    read -p "¿Aplicar cambios reales? (s/n): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        echo "❌ Cancelado por el usuario"
        exit 0
    fi
    
    # Ejecutar playbook real
    if ansible-playbook playbooks/configure-ubuntu-role.yml --limit "$vm_name"; then
        echo ""
        echo "════════════════════════════════════════════════════════"
        echo "✅ $vm_name configurado exitosamente"
        echo "════════════════════════════════════════════════════════"
        echo ""
        echo "Configuración aplicada:"
        echo "  VM: $vm_name"
        echo "  IP: $vm_ip"
        echo "  Rol: $vm_role"
        echo ""
        echo "Usuarios creados:"
        echo "  - admin (sudo, acceso total)"
        echo "  - auditor (solo lectura)"
        echo "  - gamer01 (sin privilegios)"
        echo ""
        echo "Carpetas creadas:"
        echo "  - /srv/admin"
        echo "  - /srv/audits"
        echo "  - /srv/games"
        echo "  - /srv/instaladores"
        echo ""
        echo "Backup guardado en: $backup_dir"
        echo ""
        
        # Verificar que la configuración se aplicó correctamente
        echo "🔍 Verificando configuración aplicada..."
        if ansible "$vm_name" -m shell -a "id admin && id auditor && id gamer01" &> /dev/null; then
            echo "✅ Usuarios creados correctamente"
        else
            echo "⚠️  Advertencia: No se pudieron verificar todos los usuarios"
        fi
        
        if ansible "$vm_name" -m shell -a "ls -la /srv/games /srv/admin /srv/audits /srv/instaladores" -b &> /dev/null; then
            echo "✅ Carpetas creadas correctamente"
        else
            echo "⚠️  Advertencia: No se pudieron verificar todas las carpetas"
        fi
        
        echo ""
        echo "✅ Configuración completada y verificada"
        echo ""
    else
        echo ""
        echo "════════════════════════════════════════════════════════"
        echo "❌ Error al configurar $vm_name"
        echo "════════════════════════════════════════════════════════"
        echo ""
        echo "Para restaurar el backup:"
        echo "  ansible $vm_name -m copy -a \"src=$backup_dir/sshd_config.bak dest=/etc/ssh/sshd_config\" -b"
        echo ""
        exit 1
    fi
else
    echo ""
    echo "❌ Error en validación dry-run"
    echo "   Revisa los errores antes de continuar"
    exit 1
fi
