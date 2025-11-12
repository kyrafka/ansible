#!/bin/bash
# Script simple para crear VM Ubuntu Desktop (sin roles)

# Auto-permisos
[ ! -x "$0" ] && chmod +x "$0" 2>/dev/null

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        🖥️  Crear VM Ubuntu Desktop (Simple)                  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -f "ansible.cfg" ]; then
    echo -e "${RED}Error: Ejecuta desde el directorio raíz del proyecto${NC}"
    exit 1
fi

echo -e "${YELLOW}📋 Recursos de la VM:${NC}"
echo "  CPU: 2 cores"
echo "  RAM: 4096 MB (4 GB)"
echo "  Disco: 40 GB"
echo "  Red: M_vm's (red interna)"
echo ""

# Ejecutar playbook
echo -e "${BLUE}Creando VM...${NC}"
echo ""

ansible-playbook playbooks/create-vm-simple.yml

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                  ✅ VM Creada Exitosamente                    ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}🔧 Pasos siguientes:${NC}"
    echo "  1. Abre la consola de la VM en ESXi"
    echo "  2. Instala Ubuntu Desktop desde la ISO"
    echo "  3. Durante la instalación:"
    echo "     - Usuario: administrador"
    echo "     - Contraseña: 123456"
    echo "     - Red: IPv6 Automatic (DHCP)"
    echo ""
    echo -e "${YELLOW}🌐 La VM obtendrá IP automáticamente:${NC}"
    echo "  - DHCP le asignará una IP del rango 2025:db8:10::100-200"
    echo "  - DNS la registrará automáticamente (DDNS)"
    echo ""
    echo -e "${YELLOW}🔍 Para ver la IP asignada:${NC}"
    echo "  Desde la VM: ip -6 addr show | grep 2025"
    echo "  Desde el servidor: cat /var/lib/dhcp/dhcpd6.leases"
    echo ""
else
    echo ""
    echo -e "${RED}✗ Error al crear la VM${NC}"
    echo ""
    echo -e "${YELLOW}Posibles causas:${NC}"
    echo "  - Firewall de ESXi bloqueando conexión"
    echo "  - Credenciales incorrectas en group_vars/all.vault.yml"
    echo "  - ESXi no accesible desde esta máquina"
    echo ""
    exit 1
fi
