#!/bin/bash
# Script interactivo para crear VMs con roles

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   🎮 GameCenter - Crear VM con Rol   ║${NC}"
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo ""

# Seleccionar SO
echo -e "${YELLOW}Selecciona el Sistema Operativo:${NC}"
echo "1) Ubuntu Desktop 24.04"
echo "2) Windows 11"
read -p "Opción [1-2]: " so_option

case $so_option in
    1)
        SO="ubuntu"
        PLAYBOOK="playbooks/create-ubuntu-desktop.yml"
        ;;
    2)
        SO="windows"
        PLAYBOOK="playbooks/create-windows11.yml"
        ;;
    *)
        echo -e "${RED}Opción inválida${NC}"
        exit 1
        ;;
esac

# Nombre de la VM
echo ""
echo -e "${YELLOW}Nombre de la VM:${NC}"
read -p "Ejemplo: ${SO}-cliente01: " vm_name

if [ -z "$vm_name" ]; then
    echo -e "${RED}El nombre no puede estar vacío${NC}"
    exit 1
fi

# Seleccionar rol
echo ""
echo -e "${YELLOW}Selecciona el Rol:${NC}"
echo "1) Admin    - Acceso total, puede SSH al servidor"
echo "2) Auditor  - Solo lectura de logs, NO puede SSH"
echo "3) Cliente  - Solo juegos, NO puede SSH"
read -p "Opción [1-3]: " rol_option

case $rol_option in
    1)
        ROL="admin"
        CPU=2
        RAM=4096
        DISK=40
        ;;
    2)
        ROL="auditor"
        CPU=2
        RAM=3072
        DISK=35
        ;;
    3)
        ROL="cliente"
        CPU=2
        RAM=4096
        DISK=40
        ;;
    *)
        echo -e "${RED}Opción inválida${NC}"
        exit 1
        ;;
esac

# Mostrar resumen
echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           Resumen de la VM            ║${NC}"
echo -e "${GREEN}╠════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║${NC} Nombre:  ${BLUE}$vm_name${NC}"
echo -e "${GREEN}║${NC} SO:      ${BLUE}$SO${NC}"
echo -e "${GREEN}║${NC} Rol:     ${BLUE}$ROL${NC}"
echo -e "${GREEN}║${NC} CPU:     ${BLUE}$CPU cores${NC}"
echo -e "${GREEN}║${NC} RAM:     ${BLUE}$RAM MB${NC}"
echo -e "${GREEN}║${NC} Disco:   ${BLUE}$DISK GB${NC}"
echo -e "${GREEN}║${NC} Red:     ${BLUE}M_vm's${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""

# Confirmar
read -p "¿Crear esta VM? [s/N]: " confirm
if [[ ! "$confirm" =~ ^[sS]$ ]]; then
    echo -e "${YELLOW}Cancelado${NC}"
    exit 0
fi

# Crear VM
echo ""
echo -e "${BLUE}Creando VM...${NC}"
ansible-playbook "$PLAYBOOK" \
    -e "vm_name=$vm_name" \
    -e "vm_role=$ROL"

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ VM creada exitosamente!${NC}"
    echo ""
    echo -e "${YELLOW}Siguientes pasos:${NC}"
    echo "1. Instalar $SO desde la ISO"
    
    if [ "$SO" == "windows" ]; then
        echo "2. Habilitar WinRM (ver playbooks/README-windows11.md)"
        echo "3. Agregar a inventory/hosts.ini en [windows_desktops]:"
        echo "   ${vm_name} ansible_host=2025:db8:10::XX vm_role=${ROL}"
        echo "4. Configurar: ansible-playbook playbooks/configure-windows-role.yml --limit ${vm_name}"
    else
        echo "2. Habilitar SSH: sudo apt install openssh-server"
        echo "3. Agregar a inventory/hosts.ini en [ubuntu_desktops]:"
        echo "   ${vm_name} ansible_host=2025:db8:10::XX vm_role=${ROL}"
        echo "4. Configurar: ansible-playbook playbooks/configure-ubuntu-role.yml --limit ${vm_name}"
    fi
    
    echo "5. Actualizar firewall: ansible-playbook playbook-firewall.yml"
else
    echo -e "${RED}✗ Error al crear la VM${NC}"
    exit 1
fi
