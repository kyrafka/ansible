#!/bin/bash

# ════════════════════════════════════════════════════════════════
# 🪟 SCRIPT DE DEMOSTRACIÓN - ANSIBLE CON WINDOWS 11
# ════════════════════════════════════════════════════════════════

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}🪟 DEMOSTRACIÓN ANSIBLE → WINDOWS 11${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo ""

# 1. Información del sistema
echo -e "${YELLOW}1️⃣  Información del sistema Windows${NC}"
ansible win11 -i inventory/windows.ini -m win_shell -a "systeminfo | findstr /C:\"Nombre de host\" /C:\"Nombre del sistema\""
echo ""

# 2. Ver usuarios
echo -e "${YELLOW}2️⃣  Usuarios de Windows${NC}"
ansible win11 -i inventory/windows.ini -m win_shell -a "net user"
echo ""

# 3. Ver discos
echo -e "${YELLOW}3️⃣  Discos y particiones${NC}"
ansible win11 -i inventory/windows.ini -m win_shell -a "wmic logicaldisk get name,size,freespace"
echo ""

# 4. Ver IP
echo -e "${YELLOW}4️⃣  Configuración de red${NC}"
ansible win11 -i inventory/windows.ini -m win_shell -a "ipconfig | findstr IPv6"
echo ""

# 5. Crear archivo de prueba
echo -e "${YELLOW}5️⃣  Creando archivo de prueba en el escritorio${NC}"
ansible win11 -i inventory/windows.ini -m win_shell -a "echo 'Gestionado por Ansible desde Ubuntu Server' > C:\\Users\\jose\\Desktop\\ansible-test.txt"
echo ""

# 6. Verificar archivo
echo -e "${YELLOW}6️⃣  Verificando archivo creado${NC}"
ansible win11 -i inventory/windows.ini -m win_shell -a "type C:\\Users\\jose\\Desktop\\ansible-test.txt"
echo ""

# 7. Ver servicios
echo -e "${YELLOW}7️⃣  Servicios de Windows (WinRM)${NC}"
ansible win11 -i inventory/windows.ini -m win_shell -a "sc query WinRM"
echo ""

echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ DEMOSTRACIÓN COMPLETADA${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}📋 Ansible puede gestionar Windows desde Ubuntu Server${NC}"
echo ""
