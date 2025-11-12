#!/bin/bash
# Script para crear VM Ubuntu Desktop

# Auto-permisos
[ ! -x "$0" ] && chmod +x "$0" 2>/dev/null

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           🖥️  Crear VM Ubuntu Desktop                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar directorio
if [ ! -f "ansible.cfg" ]; then
    echo -e "${RED}Error: Ejecuta desde el directorio raíz del proyecto${NC}"
    exit 1
fi

echo -e "${YELLOW}📋 Recursos de la VM:${NC}"
echo "  • CPU: 2 cores"
echo "  • RAM: 4 GB"
echo "  • Disco: 40 GB"
echo "  • Red: M_vm's (red interna)"
echo "  • ISO: Ubuntu Desktop 24.04"
echo ""

# Ejecutar playbook
ansible-playbook playbooks/create-ubuntu-desktop.yml

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                  ✅ VM Creada Exitosamente                    ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
else
    echo ""
    echo -e "${RED}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                     ✗ Error al crear VM                       ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Posibles causas:${NC}"
    echo "  • Firewall de ESXi bloqueando conexión"
    echo "  • Credenciales incorrectas"
    echo "  • ESXi no accesible"
    echo ""
    exit 1
fi
