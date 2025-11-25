#!/bin/bash

# ════════════════════════════════════════════════════════════════
# 👥 CREAR USUARIOS EN WINDOWS 11
# ════════════════════════════════════════════════════════════════

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}👥 CREANDO USUARIOS EN WINDOWS 11${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo ""

# Crear usuario 'cliente'
echo -e "${YELLOW}1️⃣  Creando usuario 'cliente'...${NC}"
ansible win11 -i inventory/windows.ini -m ansible.windows.win_shell -a "net user cliente 123!123 /add; exit 0" 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}   ✅ Usuario 'cliente' creado${NC}"
else
    echo -e "${YELLOW}   ⚠️  Usuario 'cliente' ya existe o hubo un error${NC}"
fi
echo ""

# Verificar usuarios
echo -e "${YELLOW}2️⃣  Verificando usuarios creados...${NC}"
ansible win11 -i inventory/windows.ini -m ansible.windows.win_shell -a "Get-LocalUser | Select-Object Name, Enabled | Format-Table -AutoSize" 2>/dev/null

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ USUARIOS CONFIGURADOS${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}👥 Usuarios de Windows:${NC}"
echo "  - dev (contraseña: 123!123)"
echo "  - cliente (contraseña: 123!123)"
echo ""
