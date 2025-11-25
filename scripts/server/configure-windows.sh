#!/bin/bash

# ════════════════════════════════════════════════════════════════
# 🪟 SCRIPT PARA CONFIGURAR WINDOWS 11 CON ANSIBLE
# ════════════════════════════════════════════════════════════════

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}🪟 CONFIGURANDO WINDOWS 11 CON ANSIBLE${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo ""

# Ejecutar playbook
ansible-playbook -i inventory/windows.ini playbooks/configure-windows.yml

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ CONFIGURACIÓN COMPLETADA${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo ""

# Verificar usuarios
echo -e "${YELLOW}📋 Verificando usuarios creados...${NC}"
ansible win11 -i inventory/windows.ini -m ansible.windows.win_shell -a "net user"

echo ""
echo -e "${CYAN}🎯 Usuarios configurados:${NC}"
echo "  - dev (contraseña: 123!123)"
echo "  - cliente (contraseña: 123!123)"
echo ""
