#!/bin/bash

# ════════════════════════════════════════════════════════════════
# 📋 MOSTRAR CONFIGURACIÓN DE WINDOWS 11 DESDE UBUNTU
# ════════════════════════════════════════════════════════════════

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}📋 CONFIGURACIÓN DE WINDOWS 11${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo ""

# 1. Usuarios
echo -e "${YELLOW}1️⃣  USUARIOS DEL SISTEMA${NC}"
echo "────────────────────────────────────────────────────────────────"
ansible win11 -i inventory/windows.ini -m ansible.windows.win_shell -a "Get-LocalUser | Select-Object Name, Enabled | Format-Table -AutoSize" 2>/dev/null
echo ""

# 2. Carpetas creadas
echo -e "${YELLOW}2️⃣  CARPETAS CREADAS POR ANSIBLE${NC}"
echo "────────────────────────────────────────────────────────────────"
ansible win11 -i inventory/windows.ini -m ansible.windows.win_shell -a "Get-ChildItem C:\\ | Where-Object {\$_.Name -match 'Compartido|Dev'} | Select-Object Name, LastWriteTime | Format-Table -AutoSize" 2>/dev/null
echo ""

# 3. Configuración de red
echo -e "${YELLOW}3️⃣  CONFIGURACIÓN DE RED (IPv6)${NC}"
echo "────────────────────────────────────────────────────────────────"
ansible win11 -i inventory/windows.ini -m ansible.windows.win_shell -a "ipconfig | findstr IPv6" 2>/dev/null
echo ""

# 4. Firewall
echo -e "${YELLOW}4️⃣  REGLAS DE FIREWALL CONFIGURADAS${NC}"
echo "────────────────────────────────────────────────────────────────"
ansible win11 -i inventory/windows.ini -m ansible.windows.win_shell -a "Get-NetFirewallRule | Where-Object {\$_.DisplayName -match 'WinRM|ICMPv6'} | Select-Object DisplayName, Enabled | Format-Table -AutoSize" 2>/dev/null
echo ""

# 5. Servicio WinRM
echo -e "${YELLOW}5️⃣  SERVICIO WINRM${NC}"
echo "────────────────────────────────────────────────────────────────"
ansible win11 -i inventory/windows.ini -m ansible.windows.win_shell -a "Get-Service WinRM | Select-Object Name, Status, StartType | Format-Table -AutoSize" 2>/dev/null
echo ""

# 6. Información del sistema
echo -e "${YELLOW}6️⃣  INFORMACIÓN DEL SISTEMA${NC}"
echo "────────────────────────────────────────────────────────────────"
ansible win11 -i inventory/windows.ini -m ansible.windows.win_shell -a "Write-Host \"Hostname: \$env:COMPUTERNAME\"; Write-Host \"Usuario: \$env:USERNAME\"; Write-Host \"OS: \$((Get-WmiObject Win32_OperatingSystem).Caption)\"" 2>/dev/null
echo ""

# 7. Archivo creado por Ansible
echo -e "${YELLOW}7️⃣  ARCHIVO CREADO POR ANSIBLE${NC}"
echo "────────────────────────────────────────────────────────────────"
ansible win11 -i inventory/windows.ini -m ansible.windows.win_shell -a "if (Test-Path 'C:\\Users\\jose\\Desktop\\ansible-test.txt') { Write-Host '✅ Archivo encontrado'; Get-Content 'C:\\Users\\jose\\Desktop\\ansible-test.txt' } else { Write-Host '⚠️ Archivo no encontrado' }" 2>/dev/null
echo ""

echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ CONFIGURACIÓN MOSTRADA${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo ""
