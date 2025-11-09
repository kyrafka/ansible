#!/bin/bash
# Script rápido para desplegar todo el entorno

set -e

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   🎮 GameCenter - Despliegue Rápido del Entorno              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Función para mostrar paso
show_step() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Función para confirmar
confirm() {
    read -p "$1 [s/N]: " response
    [[ "$response" =~ ^[sS]$ ]]
}

# Paso 1: Crear servidor Ubuntu
show_step "Paso 1: Crear Servidor Ubuntu"
if confirm "¿Crear servidor Ubuntu?"; then
    ansible-playbook create-vm-gamecenter.yml
    echo -e "${GREEN}✓ Servidor creado${NC}"
    echo -e "${YELLOW}Espera 5 minutos para que cloud-init termine...${NC}"
    
    if confirm "¿Continuar con la configuración del servidor?"; then
        show_step "Configurando servidor..."
        ansible-playbook site.yml
        echo -e "${GREEN}✓ Servidor configurado${NC}"
    fi
else
    echo -e "${YELLOW}Saltando creación del servidor${NC}"
fi

# Paso 2: Crear VMs cliente
show_step "Paso 2: Crear VMs Cliente"
if confirm "¿Crear VMs cliente?"; then
    
    # Ubuntu Desktop
    if confirm "¿Crear Ubuntu Desktop cliente?"; then
        echo ""
        read -p "Nombre de la VM [ubuntu-cliente01]: " ubuntu_name
        ubuntu_name=${ubuntu_name:-ubuntu-cliente01}
        
        ansible-playbook playbooks/create-ubuntu-desktop.yml \
            -e "vm_name=$ubuntu_name" \
            -e "vm_role=cliente"
        
        echo -e "${GREEN}✓ Ubuntu Desktop creado: $ubuntu_name${NC}"
        echo -e "${YELLOW}Recuerda:${NC}"
        echo "1. Instalar Ubuntu Desktop desde la ISO"
        echo "2. Agregar a inventory/hosts.ini"
        echo "3. Ejecutar: ansible-playbook playbooks/configure-ubuntu-role.yml --limit $ubuntu_name"
    fi
    
    # Windows 11
    if confirm "¿Crear Windows 11 cliente?"; then
        echo ""
        read -p "Nombre de la VM [win11-cliente01]: " win_name
        win_name=${win_name:-win11-cliente01}
        
        ansible-playbook playbooks/create-windows11.yml \
            -e "vm_name=$win_name" \
            -e "vm_role=cliente"
        
        echo -e "${GREEN}✓ Windows 11 creado: $win_name${NC}"
        echo -e "${YELLOW}Recuerda:${NC}"
        echo "1. Instalar Windows 11 desde la ISO"
        echo "2. Habilitar WinRM"
        echo "3. Agregar a inventory/hosts.ini"
        echo "4. Ejecutar: ansible-playbook playbooks/configure-windows-role.yml --limit $win_name"
    fi
fi

# Paso 3: Crear VM admin
show_step "Paso 3: Crear VM Administrador"
if confirm "¿Crear VM administrador?"; then
    
    echo "Selecciona SO:"
    echo "1) Ubuntu Desktop"
    echo "2) Windows 11"
    read -p "Opción [1-2]: " so_option
    
    case $so_option in
        1)
            read -p "Nombre de la VM [ubuntu-admin]: " admin_name
            admin_name=${admin_name:-ubuntu-admin}
            
            ansible-playbook playbooks/create-ubuntu-desktop.yml \
                -e "vm_name=$admin_name" \
                -e "vm_role=admin"
            
            echo -e "${GREEN}✓ Ubuntu Admin creado: $admin_name${NC}"
            ;;
        2)
            read -p "Nombre de la VM [win11-admin]: " admin_name
            admin_name=${admin_name:-win11-admin}
            
            ansible-playbook playbooks/create-windows11.yml \
                -e "vm_name=$admin_name" \
                -e "vm_role=admin"
            
            echo -e "${GREEN}✓ Windows Admin creado: $admin_name${NC}"
            ;;
    esac
fi

# Resumen final
show_step "Resumen del Despliegue"
echo -e "${GREEN}✓ Despliegue completado${NC}"
echo ""
echo -e "${YELLOW}VMs creadas en vSphere:${NC}"
./scripts/list-vms.sh 2>/dev/null || echo "Ejecuta: ./scripts/list-vms.sh"
echo ""
echo -e "${YELLOW}Próximos pasos:${NC}"
echo "1. Instalar los sistemas operativos en las VMs"
echo "2. Configurar red IPv6 (DHCP automático)"
echo "3. Agregar VMs a inventory/hosts.ini"
echo "4. Ejecutar playbooks de configuración de roles"
echo "5. Actualizar firewall del servidor: ansible-playbook playbook-firewall.yml"
echo ""
echo -e "${BLUE}Documentación:${NC}"
echo "- Ubuntu Desktop: playbooks/README-ubuntu-desktop.md"
echo "- Windows 11: playbooks/README-windows11.md"
