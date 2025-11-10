#!/bin/bash
# Script para crear la VM del servidor Ubuntu desde WSL
# Ejecutar: bash scripts/vms/create-server.sh

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        🖥️  Crear VM del Servidor Ubuntu GameCenter           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar que estamos en la raíz del proyecto
if [ ! -f "playbooks/create_ubpc.yml" ]; then
    echo -e "${RED}Error: Ejecuta este script desde la raíz del proyecto${NC}"
    exit 1
fi

# Verificar Ansible
if ! command -v ansible-playbook &> /dev/null; then
    echo -e "${RED}Error: Ansible no está instalado${NC}"
    echo ""
    echo "Instalar con:"
    echo "  sudo apt update"
    echo "  sudo apt install ansible python3-pip -y"
    echo "  pip3 install pyvmomi"
    exit 1
fi

echo -e "${YELLOW}Configuración de la VM:${NC}"
echo "  Nombre: ubuntu-server"
echo "  CPU: 2 cores"
echo "  RAM: 4096 MB"
echo "  Disco: 80 GB"
echo "  Red: M_vm's (IPv6)"
echo "  ISO: Ubuntu Server 24.04"
echo ""

read -p "¿Crear la VM del servidor? [s/N]: " confirm
if [[ ! "$confirm" =~ ^[sS]$ ]]; then
    echo -e "${YELLOW}Cancelado${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}Creando VM del servidor...${NC}"
echo ""

# Ejecutar playbook solo para crear la VM (sin configuración)
ansible-playbook playbooks/create_ubpc.yml --tags create_vm

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              ✅ VM del servidor creada exitosamente           ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Siguientes pasos:${NC}"
    echo ""
    echo "1. Conectarte a la consola de la VM en vCenter/ESXi"
    echo ""
    echo "2. Instalar Ubuntu Server 24.04 desde la ISO"
    echo "   - Usuario: ubuntu (o el que prefieras)"
    echo "   - Configurar red IPv6"
    echo ""
    echo "3. Desde el servidor Ubuntu, ejecutar:"
    echo "   ${BLUE}bash scripts/server/setup-server.sh${NC}"
    echo ""
    echo "4. Esto configurará:"
    echo "   - Paquetes base"
    echo "   - Red IPv6 (ens33, ens34) y NAT66"
    echo "   - DNS (BIND9)"
    echo "   - DHCPv6"
    echo "   - Firewall (UFW + fail2ban)"
    echo "   - Almacenamiento NFS"
    echo ""
else
    echo ""
    echo -e "${RED}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                  ❌ Error al crear la VM                      ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Verifica:"
    echo "  - Credenciales de vCenter en group_vars/all.vault.yml"
    echo "  - Conectividad con vCenter"
    echo "  - Que la ISO de Ubuntu esté en el datastore"
    echo ""
    exit 1
fi
