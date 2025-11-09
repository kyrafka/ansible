#!/bin/bash
# Script para listar todas las VMs y su estado

set -e

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           🎮 GameCenter - Estado de VMs                       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar govc primero
if ! command -v govc &> /dev/null; then
    echo -e "${RED}Error: govc no está instalado${NC}"
    echo ""
    echo "Instalar en WSL:"
    echo "  curl -L https://github.com/vmware/govmomi/releases/latest/download/govc_Linux_x86_64.tar.gz | tar -xz"
    echo "  sudo mv govc /usr/local/bin/"
    echo ""
    exit 1
fi

# Verificar jq
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}Instalando jq...${NC}"
    sudo apt install jq -y
fi

# Cargar variables de vCenter
echo -e "${YELLOW}Cargando credenciales...${NC}"

VCENTER_HOST=$(grep 'vault_vcenter_hostname:' group_vars/all.vault.yml | awk -F': ' '{print $2}' | tr -d '"' | tr -d "'")
VCENTER_PORT=$(grep 'vault_vcenter_port:' group_vars/all.vault.yml | awk -F': ' '{print $2}' | tr -d '"' | tr -d "'")
VCENTER_USER=$(grep 'vault_vcenter_username:' group_vars/all.vault.yml | awk -F': ' '{print $2}' | tr -d '"' | tr -d "'")
VCENTER_PASS=$(grep 'vault_vcenter_password:' group_vars/all.vault.yml | awk -F': ' '{print $2}' | tr -d '"' | tr -d "'")

# Si no hay puerto, usar 443 por defecto
if [ -z "$VCENTER_PORT" ]; then
    VCENTER_PORT="443"
fi

if [ -z "$VCENTER_HOST" ] || [ -z "$VCENTER_USER" ] || [ -z "$VCENTER_PASS" ]; then
    echo -e "${RED}Error: No se pudieron cargar las credenciales${NC}"
    echo "Verifica group_vars/all.vault.yml"
    exit 1
fi

export GOVC_URL="https://${VCENTER_HOST}:${VCENTER_PORT}"
export GOVC_USERNAME="${VCENTER_USER}"
export GOVC_PASSWORD="${VCENTER_PASS}"
export GOVC_INSECURE=1

echo -e "${GREEN}✓ Credenciales cargadas${NC}"
echo -e "${YELLOW}Conectando a vCenter: ${VCENTER_HOST}:${VCENTER_PORT}${NC}"
echo ""

# Probar conexión
if ! timeout 10 govc about &> /dev/null; then
    echo -e "${RED}Error: No se puede conectar a vCenter${NC}"
    echo ""
    echo "Verifica:"
    echo "  - Host: ${VCENTER_HOST}"
    echo "  - Usuario: ${VCENTER_USER}"
    echo "  - Red/Firewall"
    echo ""
    exit 1
fi

echo -e "${GREEN}✓ Conectado a vCenter${NC}"
echo ""

VMS=$(govc ls /ha-datacenter/vm 2>/dev/null | grep -v "^$" || true)

if [ -z "$VMS" ]; then
    echo -e "${YELLOW}No hay VMs en el datacenter${NC}"
    exit 0
fi

echo -e "${GREEN}VMs encontradas:${NC}"
echo ""
printf "%-25s %-15s %-10s %-15s %-20s\n" "NOMBRE" "ESTADO" "CPU" "RAM (MB)" "IP"
echo "────────────────────────────────────────────────────────────────────────────"

for vm_path in $VMS; do
    vm_name=$(basename "$vm_path")
    
    # Obtener info de la VM sin JSON (más confiable)
    vm_info=$(govc vm.info "$vm_path" 2>/dev/null)
    
    # Extraer estado
    power_state=$(echo "$vm_info" | grep "Power state:" | awk '{print $3}')
    
    # Extraer CPU y RAM
    cpu=$(echo "$vm_info" | grep "CPU:" | awk '{print $2}')
    ram=$(echo "$vm_info" | grep "Memory:" | awk '{print $2}' | sed 's/MB//')
    
    # Si no se pudo obtener, poner valores por defecto
    [ -z "$cpu" ] && cpu="?"
    [ -z "$ram" ] && ram="?"
    
    # Obtener IP con timeout para no colgarse
    if [ "$power_state" == "poweredOff" ]; then
        ip="N/A"
        estado="Apagada"
        state_color="${RED}"
    else
        ip=$(timeout 3 govc vm.ip "$vm_path" 2>/dev/null || echo "")
        if [ -z "$ip" ]; then
            ip="Sin Tools/IP"
        fi
        estado="Encendida"
        state_color="${GREEN}"
    fi
    
    printf "%-25s ${state_color}%-15s${NC} %-10s %-15s %-20s\n" \
        "$vm_name" "$estado" "$cpu" "$ram" "$ip"
done

echo ""
echo -e "${BLUE}Total de VMs: $(echo "$VMS" | wc -l)${NC}"
echo ""

# Mostrar VMs en inventario
echo -e "${YELLOW}VMs en inventario Ansible:${NC}"
echo ""

if [ -f "inventory/hosts.ini" ]; then
    echo -e "${GREEN}Ubuntu Desktops:${NC}"
    grep -A 10 "\[ubuntu_desktops\]" inventory/hosts.ini | grep -v "^#" | grep -v "^\[" | grep -v "^$" || echo "  Ninguna"
    echo ""
    
    echo -e "${GREEN}Windows Desktops:${NC}"
    grep -A 10 "\[windows_desktops\]" inventory/hosts.ini | grep -v "^#" | grep -v "^\[" | grep -v "^$" || echo "  Ninguna"
    echo ""
fi
