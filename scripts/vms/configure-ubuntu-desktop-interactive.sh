#!/bin/bash
# Script interactivo para configurar Ubuntu Desktop

# Auto-permisos
[ ! -x "$0" ] && chmod +x "$0" 2>/dev/null

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

clear

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                                ║${NC}"
echo -e "${BLUE}║   🖥️  ${CYAN}Configurador Interactivo de Ubuntu Desktop${BLUE}          ║${NC}"
echo -e "${BLUE}║                                                                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -f "ansible.cfg" ]; then
    echo -e "${RED}❌ Error: Ejecuta este script desde el directorio raíz del proyecto${NC}"
    exit 1
fi

# Verificar que existe el inventario
if [ ! -f "inventory/hosts.ini" ]; then
    echo -e "${RED}❌ Error: No se encuentra inventory/hosts.ini${NC}"
    exit 1
fi

echo -e "${CYAN}📋 VMs disponibles en el inventario:${NC}"
echo ""

# Leer VMs del inventario
VMS=()
IN_UBUNTU_DESKTOPS=0

while IFS= read -r line; do
    # Detectar sección [ubuntu_desktops]
    if [[ "$line" == "[ubuntu_desktops]" ]]; then
        IN_UBUNTU_DESKTOPS=1
        continue
    fi
    
    # Si encontramos otra sección, salir
    if [[ "$line" =~ ^\[.*\]$ ]] && [[ "$IN_UBUNTU_DESKTOPS" -eq 1 ]]; then
        break
    fi
    
    # Si estamos en la sección correcta y la línea no está vacía
    if [[ "$IN_UBUNTU_DESKTOPS" -eq 1 ]] && [[ ! -z "$line" ]] && [[ ! "$line" =~ ^# ]]; then
        # Extraer nombre de la VM (primera palabra)
        VM_NAME=$(echo "$line" | awk '{print $1}')
        if [[ ! -z "$VM_NAME" ]]; then
            VMS+=("$VM_NAME")
        fi
    fi
done < "inventory/hosts.ini"

# Mostrar VMs disponibles
if [ ${#VMS[@]} -eq 0 ]; then
    echo -e "${RED}❌ No se encontraron VMs en [ubuntu_desktops]${NC}"
    echo ""
    echo -e "${YELLOW}Agrega una VM al inventario:${NC}"
    echo ""
    echo "[ubuntu_desktops]"
    echo "ubuntu123 ansible_host=2025:db8:10::dce9 ansible_user=administrador ansible_password=123 ansible_become_password=123"
    echo ""
    exit 1
fi

for i in "${!VMS[@]}"; do
    NUM=$((i+1))
    VM="${VMS[$i]}"
    
    # Obtener IP de la VM
    IP=$(grep "^$VM " inventory/hosts.ini | grep -oP 'ansible_host=\K[^ ]+' || echo "N/A")
    
    echo -e "${GREEN}  [$NUM]${NC} ${CYAN}$VM${NC} ${YELLOW}($IP)${NC}"
done

echo ""
echo -e "${MAGENTA}  [0] ❌ Cancelar${NC}"
echo ""

# Pedir selección
while true; do
    read -p "$(echo -e ${YELLOW}Selecciona una VM [0-${#VMS[@]}]: ${NC})" SELECTION
    
    if [[ "$SELECTION" == "0" ]]; then
        echo -e "${YELLOW}Operación cancelada${NC}"
        exit 0
    fi
    
    if [[ "$SELECTION" =~ ^[0-9]+$ ]] && [ "$SELECTION" -ge 1 ] && [ "$SELECTION" -le "${#VMS[@]}" ]; then
        break
    else
        echo -e "${RED}❌ Selección inválida. Intenta de nuevo.${NC}"
    fi
done

SELECTED_VM="${VMS[$((SELECTION-1))]}"

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ VM seleccionada: ${CYAN}$SELECTED_VM${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""

# Probar conexión
echo -e "${YELLOW}🔍 Probando conexión con $SELECTED_VM...${NC}"
echo ""

if ansible $SELECTED_VM -i inventory/hosts.ini -m ping > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Conexión exitosa${NC}"
else
    echo -e "${RED}✗ No se puede conectar a la VM${NC}"
    echo ""
    echo -e "${YELLOW}Verifica:${NC}"
    echo "  1. La VM está encendida"
    echo "  2. SSH está instalado: sudo apt install openssh-server"
    echo "  3. La IP en inventory/hosts.ini es correcta"
    echo "  4. El usuario y contraseña son correctos"
    echo ""
    read -p "$(echo -e ${YELLOW}¿Continuar de todas formas? [s/N]: ${NC})" CONTINUE
    if [[ ! "$CONTINUE" =~ ^[sS]$ ]]; then
        echo -e "${YELLOW}Operación cancelada${NC}"
        exit 1
    fi
fi

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}📦 Configuración que se aplicará:${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}👥 Usuarios:${NC}"
echo "  • admin      - Administrador (sudo completo)"
echo "  • auditor    - Auditor (solo lectura)"
echo "  • gamer01    - Cliente/Gamer (sin privilegios)"
echo ""
echo -e "${GREEN}📁 Directorios:${NC}"
echo "  • /srv/admin        - Privado (admin)"
echo "  • /srv/audits       - Privado (auditor)"
echo "  • /srv/games        - Compartido (todos)"
echo "  • /srv/instaladores - Compartido (todos)"
echo ""
echo -e "${GREEN}🔧 Servicios:${NC}"
echo "  • SSH configurado (solo admin)"
echo "  • Firewall habilitado"
echo "  • NFS montado"
echo "  • Paquetes actualizados"
echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""

read -p "$(echo -e ${YELLOW}¿Continuar con la configuración? [S/n]: ${NC})" CONFIRM

if [[ "$CONFIRM" =~ ^[nN]$ ]]; then
    echo -e "${YELLOW}Operación cancelada${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}🚀 Iniciando configuración...${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""

# Ejecutar playbook
ansible-playbook playbooks/configure-vm-simple.yml \
    -i inventory/hosts.ini \
    --limit "$SELECTED_VM" \
    -v

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                                ║${NC}"
    echo -e "${GREEN}║                  ✅ ${CYAN}Configuración Completada${GREEN}                  ║${NC}"
    echo -e "${GREEN}║                                                                ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}📋 Resumen:${NC}"
    echo ""
    echo -e "${GREEN}VM configurada:${NC} ${CYAN}$SELECTED_VM${NC}"
    echo ""
    echo -e "${YELLOW}👥 Usuarios creados (contraseña: 123456):${NC}"
    echo ""
    echo -e "${GREEN}  🔑 admin${NC}"
    echo "     • Sudo completo (sin contraseña)"
    echo "     • Acceso SSH al servidor"
    echo "     • Escritura en /srv/games"
    echo ""
    echo -e "${BLUE}  👁️  auditor${NC}"
    echo "     • Solo lectura de logs"
    echo "     • NO puede SSH al servidor"
    echo "     • Solo lectura en /srv/games"
    echo ""
    echo -e "${YELLOW}  🎮 gamer01${NC}"
    echo "     • Sin sudo"
    echo "     • NO puede SSH al servidor"
    echo "     • Solo lectura en /srv/games"
    echo ""
    echo -e "${CYAN}🔗 Conectarse:${NC}"
    echo "  ssh admin@$SELECTED_VM"
    echo ""
    echo -e "${CYAN}📝 Siguiente paso:${NC}"
    echo "  • Cierra sesión en la VM"
    echo "  • Inicia con uno de los usuarios creados"
    echo "  • Lee el archivo ~/LEEME.txt"
    echo ""
else
    echo ""
    echo -e "${RED}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                                                                ║${NC}"
    echo -e "${RED}║                    ❌ Error en la configuración                ║${NC}"
    echo -e "${RED}║                                                                ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Revisa los errores arriba y vuelve a intentar${NC}"
    echo ""
    exit 1
fi
