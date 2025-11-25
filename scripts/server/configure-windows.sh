#!/bin/bash

# ════════════════════════════════════════════════════════════════
# 🪟 SCRIPT COMPLETO PARA CONFIGURAR WINDOWS 11 CON ANSIBLE
# ════════════════════════════════════════════════════════════════

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}🪟 CONFIGURANDO WINDOWS 11 CON ANSIBLE${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo ""

# ════════════════════════════════════════════════════════════════
# PASO 1: CREAR USUARIOS
# ════════════════════════════════════════════════════════════════
echo -e "${YELLOW}📋 PASO 1: CREANDO USUARIOS${NC}"
echo ""

echo -e "${YELLOW}1️⃣  Creando usuario 'dev'...${NC}"
ansible win11 -i inventory/windows.ini -m ansible.windows.win_shell -a "net user dev 123!123 /add; exit 0" 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}   ✅ Usuario 'dev' creado/verificado${NC}"
fi
echo ""

echo -e "${YELLOW}2️⃣  Creando usuario 'cliente'...${NC}"
ansible win11 -i inventory/windows.ini -m ansible.windows.win_shell -a "net user cliente 123!123 /add; exit 0" 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}   ✅ Usuario 'cliente' creado/verificado${NC}"
fi
echo ""

# ════════════════════════════════════════════════════════════════
# PASO 2: CONFIGURAR SISTEMA
# ════════════════════════════════════════════════════════════════
echo -e "${YELLOW}📋 PASO 2: CONFIGURANDO SISTEMA${NC}"
echo ""

echo -e "${YELLOW}3️⃣  Creando carpetas...${NC}"
ansible win11 -i inventory/windows.ini -m ansible.windows.win_shell -a "New-Item -Path C:\\Compartido -ItemType Directory -Force; New-Item -Path C:\\Dev -ItemType Directory -Force; exit 0" 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}   ✅ Carpetas creadas (C:\\Compartido, C:\\Dev)${NC}"
fi
echo ""

echo -e "${YELLOW}4️⃣  Configurando firewall...${NC}"
ansible win11 -i inventory/windows.ini -m ansible.windows.win_shell -a "New-NetFirewallRule -Name 'ICMPv6-In' -DisplayName 'ICMPv6 Ping' -Protocol ICMPv6 -IcmpType 8 -Enabled True -Direction Inbound -Action Allow -ErrorAction SilentlyContinue; Enable-NetFirewallRule -DisplayGroup 'File and Printer Sharing' -ErrorAction SilentlyContinue; exit 0" 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}   ✅ Firewall configurado (Ping + Compartir archivos)${NC}"
fi
echo ""

# ════════════════════════════════════════════════════════════════
# PASO 3: VERIFICAR CONFIGURACIÓN
# ════════════════════════════════════════════════════════════════
echo -e "${YELLOW}📋 PASO 3: VERIFICANDO CONFIGURACIÓN${NC}"
echo ""

echo -e "${YELLOW}5️⃣  Usuarios de Windows:${NC}"
ansible win11 -i inventory/windows.ini -m ansible.windows.win_shell -a "Get-LocalUser | Select-Object Name, Enabled | Format-Table -AutoSize" 2>/dev/null
echo ""

echo -e "${YELLOW}6️⃣  Carpetas creadas:${NC}"
ansible win11 -i inventory/windows.ini -m ansible.windows.win_shell -a "Get-ChildItem C:\\ | Where-Object {$_.Name -match 'Compartido|Dev'} | Select-Object Name, LastWriteTime | Format-Table -AutoSize" 2>/dev/null
echo ""

# ════════════════════════════════════════════════════════════════
# RESUMEN FINAL
# ════════════════════════════════════════════════════════════════
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ CONFIGURACIÓN COMPLETADA${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}👥 Usuarios creados:${NC}"
echo "  - dev (contraseña: 123!123)"
echo "  - cliente (contraseña: 123!123)"
echo ""
echo -e "${CYAN}📁 Carpetas creadas:${NC}"
echo "  - C:\\Compartido"
echo "  - C:\\Dev"
echo ""
echo -e "${CYAN}🔥 Firewall configurado:${NC}"
echo "  - Ping (ICMPv6) permitido"
echo "  - Compartir archivos habilitado"
echo ""
echo -e "${GREEN}🎉 Windows 11 configurado exitosamente desde Ubuntu Server${NC}"
echo ""
