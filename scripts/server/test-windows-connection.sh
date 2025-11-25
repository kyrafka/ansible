#!/bin/bash

# ════════════════════════════════════════════════════════════════
# 🪟 SCRIPT PARA PROBAR CONEXIÓN A WINDOWS 11 VIA WINRM
# ════════════════════════════════════════════════════════════════

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# Variables
WINDOWS_IP="2025:db8:10::4f"
WINDOWS_USER="jose"
WINDOWS_PASS="123"

clear
echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}🪟 PROBANDO CONEXIÓN A WINDOWS 11${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo ""

# ════════════════════════════════════════════════════════════════
# 1. PING A WINDOWS (OPCIONAL)
# ════════════════════════════════════════════════════════════════
echo -e "${YELLOW}1️⃣  Probando conectividad (ping)...${NC}"
if ping6 -c 2 $WINDOWS_IP > /dev/null 2>&1; then
    echo -e "${GREEN}   ✅ Windows responde al ping${NC}"
else
    echo -e "${YELLOW}   ⚠️  Ping no responde (puede estar bloqueado por firewall)${NC}"
    echo -e "${YELLOW}   Continuando con WinRM...${NC}"
fi
echo ""

# ════════════════════════════════════════════════════════════════
# 2. VERIFICAR PUERTO WINRM
# ════════════════════════════════════════════════════════════════
echo -e "${YELLOW}2️⃣  Verificando puerto WinRM (5985)...${NC}"
if nc -zv $WINDOWS_IP 5985 2>&1 | grep -q "succeeded"; then
    echo -e "${GREEN}   ✅ Puerto 5985 abierto${NC}"
else
    echo -e "${RED}   ❌ Puerto 5985 cerrado${NC}"
    echo -e "${YELLOW}   Verifica que WinRM esté configurado en Windows${NC}"
    exit 1
fi
echo ""

# ════════════════════════════════════════════════════════════════
# 3. INSTALAR PYWINRM
# ════════════════════════════════════════════════════════════════
echo -e "${YELLOW}3️⃣  Instalando pywinrm...${NC}"
if ! pip3 list | grep -q pywinrm; then
    pip3 install pywinrm --quiet
    echo -e "${GREEN}   ✅ pywinrm instalado${NC}"
else
    echo -e "${GREEN}   ✅ pywinrm ya está instalado${NC}"
fi
echo ""

# ════════════════════════════════════════════════════════════════
# 4. CREAR INVENTARIO DE ANSIBLE
# ════════════════════════════════════════════════════════════════
echo -e "${YELLOW}4️⃣  Creando inventario de Ansible...${NC}"

cat > /tmp/windows.ini << EOF
[windows]
win11 ansible_host=$WINDOWS_IP

[windows:vars]
ansible_connection=winrm
ansible_user=$WINDOWS_USER
ansible_password=$WINDOWS_PASS
ansible_winrm_transport=basic
ansible_winrm_server_cert_validation=ignore
ansible_port=5985
EOF

echo -e "${GREEN}   ✅ Inventario creado en /tmp/windows.ini${NC}"
echo ""

# ════════════════════════════════════════════════════════════════
# 5. PROBAR CONEXIÓN CON ANSIBLE
# ════════════════════════════════════════════════════════════════
echo -e "${YELLOW}5️⃣  Probando conexión con Ansible (win_ping)...${NC}"
echo ""

ansible win11 -i /tmp/windows.ini -m win_ping

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}   ✅ Conexión exitosa con Ansible${NC}"
else
    echo ""
    echo -e "${RED}   ❌ Error al conectar con Ansible${NC}"
    exit 1
fi
echo ""

# ════════════════════════════════════════════════════════════════
# 6. EJECUTAR COMANDO DE PRUEBA
# ════════════════════════════════════════════════════════════════
echo -e "${YELLOW}6️⃣  Ejecutando comando de prueba (ipconfig)...${NC}"
echo ""

ansible win11 -i /tmp/windows.ini -m win_shell -a "ipconfig | findstr IPv6"

echo ""

# ════════════════════════════════════════════════════════════════
# 7. OBTENER INFORMACIÓN DEL SISTEMA
# ════════════════════════════════════════════════════════════════
echo -e "${YELLOW}7️⃣  Obteniendo información del sistema...${NC}"
echo ""

ansible win11 -i /tmp/windows.ini -m win_shell -a "systeminfo | findstr /C:\"Nombre de host\" /C:\"Nombre del sistema operativo\""

echo ""

# ════════════════════════════════════════════════════════════════
# RESUMEN
# ════════════════════════════════════════════════════════════════
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ PRUEBAS COMPLETADAS${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}📋 Información de conexión:${NC}"
echo -e "   IP: ${WINDOWS_IP}"
echo -e "   Usuario: ${WINDOWS_USER}"
echo -e "   Puerto: 5985"
echo -e "   Protocolo: WinRM (HTTP)"
echo ""
echo -e "${CYAN}📁 Inventario guardado en:${NC}"
echo -e "   /tmp/windows.ini"
echo ""
echo -e "${YELLOW}🚀 Comandos útiles:${NC}"
echo -e "   # Probar conexión:"
echo -e "   ansible win11 -i /tmp/windows.ini -m win_ping"
echo ""
echo -e "   # Ejecutar comando:"
echo -e "   ansible win11 -i /tmp/windows.ini -m win_shell -a \"COMANDO\""
echo ""
echo -e "   # Ver usuarios:"
echo -e "   ansible win11 -i /tmp/windows.ini -m win_shell -a \"net user\""
echo ""
