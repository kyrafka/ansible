#!/bin/bash
# Script para gestionar VMs (encender, apagar, reiniciar)

set -e

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Verificar govc
if ! command -v govc &> /dev/null; then
    echo -e "${RED}Error: govc no está instalado${NC}"
    echo ""
    echo "Instalar en WSL:"
    echo "  curl -L https://github.com/vmware/govmomi/releases/latest/download/govc_Linux_x86_64.tar.gz | tar -xz"
    echo "  sudo mv govc /usr/local/bin/"
    exit 1
fi

# Cargar variables de vCenter
VCENTER_HOST=$(grep 'vault_vcenter_hostname:' group_vars/all.vault.yml | awk -F': ' '{print $2}' | tr -d '"' | tr -d "'")
VCENTER_PORT=$(grep 'vault_vcenter_port:' group_vars/all.vault.yml | awk -F': ' '{print $2}' | tr -d '"' | tr -d "'")
VCENTER_USER=$(grep 'vault_vcenter_username:' group_vars/all.vault.yml | awk -F': ' '{print $2}' | tr -d '"' | tr -d "'")
VCENTER_PASS=$(grep 'vault_vcenter_password:' group_vars/all.vault.yml | awk -F': ' '{print $2}' | tr -d '"' | tr -d "'")

if [ -z "$VCENTER_PORT" ]; then
    VCENTER_PORT="443"
fi

export GOVC_URL="https://${VCENTER_HOST}:${VCENTER_PORT}"
export GOVC_USERNAME="${VCENTER_USER}"
export GOVC_PASSWORD="${VCENTER_PASS}"
export GOVC_INSECURE=1

# Función para mostrar menú
show_menu() {
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   🎮 GameCenter - Gestión de VMs     ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo "1) Listar VMs"
    echo "2) Encender VM"
    echo "3) Apagar VM"
    echo "4) Reiniciar VM"
    echo "5) Ver estado de VM"
    echo "6) Salir"
    echo ""
}

# Función para listar VMs
list_vms() {
    echo -e "${YELLOW}VMs disponibles:${NC}"
    govc ls /ha-datacenter/vm | nl -w2 -s') '
}

# Función para seleccionar VM
select_vm() {
    list_vms
    echo ""
    read -p "Selecciona el número de la VM: " vm_num
    
    VM_PATH=$(govc ls /ha-datacenter/vm | sed -n "${vm_num}p")
    
    if [ -z "$VM_PATH" ]; then
        echo -e "${RED}VM no válida${NC}"
        return 1
    fi
    
    VM_NAME=$(basename "$VM_PATH")
    echo -e "${GREEN}Seleccionada: $VM_NAME${NC}"
    return 0
}

# Función para encender VM
power_on() {
    if select_vm; then
        echo -e "${YELLOW}Encendiendo $VM_NAME...${NC}"
        govc vm.power -on "$VM_PATH"
        echo -e "${GREEN}✓ VM encendida${NC}"
    fi
}

# Función para apagar VM
power_off() {
    if select_vm; then
        echo -e "${YELLOW}Apagando $VM_NAME...${NC}"
        govc vm.power -off "$VM_PATH"
        echo -e "${GREEN}✓ VM apagada${NC}"
    fi
}

# Función para reiniciar VM
restart() {
    if select_vm; then
        echo -e "${YELLOW}Reiniciando $VM_NAME...${NC}"
        govc vm.power -reset "$VM_PATH"
        echo -e "${GREEN}✓ VM reiniciada${NC}"
    fi
}

# Función para ver estado
show_status() {
    if select_vm; then
        echo ""
        echo -e "${BLUE}Estado de $VM_NAME:${NC}"
        govc vm.info "$VM_PATH"
    fi
}

# Menú principal
while true; do
    show_menu
    read -p "Opción: " option
    echo ""
    
    case $option in
        1)
            list_vms
            ;;
        2)
            power_on
            ;;
        3)
            power_off
            ;;
        4)
            restart
            ;;
        5)
            show_status
            ;;
        6)
            echo -e "${GREEN}Saliendo...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Opción inválida${NC}"
            ;;
    esac
    
    echo ""
    read -p "Presiona Enter para continuar..."
    clear
done
