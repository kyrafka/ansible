#!/bin/bash
# Script para configurar Ubuntu Desktop con los 3 roles

# Auto-otorgar permisos de ejecución si no los tiene
if [ ! -x "$0" ]; then
    chmod +x "$0"
    echo "✓ Permisos de ejecución otorgados"
fi

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   🖥️  Configurar Ubuntu Desktop con 3 Roles                  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -f "ansible.cfg" ]; then
    echo -e "${RED}Error: Ejecuta este script desde el directorio raíz del proyecto${NC}"
    exit 1
fi

# Pedir nombre de la VM
echo -e "${YELLOW}Nombre de la VM en inventory/hosts.ini:${NC}"
read -p "Ejemplo: ubuntu-gaming: " vm_name

if [ -z "$vm_name" ]; then
    echo -e "${RED}El nombre no puede estar vacío${NC}"
    exit 1
fi

# Verificar que la VM existe en el inventario
if ! grep -q "^$vm_name" inventory/hosts.ini 2>/dev/null; then
    echo -e "${RED}Error: La VM '$vm_name' no existe en inventory/hosts.ini${NC}"
    echo ""
    echo -e "${YELLOW}Agrega la VM al inventario primero:${NC}"
    echo ""
    echo "[ubuntu_desktops]"
    echo "$vm_name ansible_host=2025:db8:10::XXX ansible_user=administrador ansible_password=123456"
    echo ""
    exit 1
fi

# Probar conexión
echo ""
echo -e "${BLUE}Probando conexión con $vm_name...${NC}"
if ansible $vm_name -m ping; then
    echo -e "${GREEN}✓ Conexión exitosa${NC}"
else
    echo -e "${RED}✗ No se puede conectar a la VM${NC}"
    echo ""
    echo -e "${YELLOW}Verifica:${NC}"
    echo "1. La VM está encendida"
    echo "2. SSH está instalado: sudo apt install openssh-server"
    echo "3. La IP en inventory/hosts.ini es correcta"
    echo "4. El usuario y contraseña son correctos"
    exit 1
fi

# Ejecutar playbook
echo ""
echo -e "${BLUE}Configurando Ubuntu Desktop...${NC}"
echo -e "${YELLOW}Esto creará 3 usuarios:${NC}"
echo "  - administrador (admin)"
echo "  - auditor (auditor)"
echo "  - gamer01 (cliente)"
echo ""

ansible-playbook playbooks/configure-ubuntu-role.yml \
    --limit "$vm_name" \
    -v

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                  ✅ Configuración Completada                  ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}👥 Usuarios creados:${NC}"
    echo ""
    echo -e "${GREEN}  🔑 administrador / 123456${NC}"
    echo "     - Sudo completo"
    echo "     - Puede SSH al servidor"
    echo "     - Escritura en /srv/games"
    echo ""
    echo -e "${BLUE}  👁️  auditor / 123456${NC}"
    echo "     - Solo lectura de logs"
    echo "     - NO puede SSH al servidor"
    echo "     - Solo lectura en /srv/games"
    echo ""
    echo -e "${YELLOW}  🎮 gamer01 / 123456${NC}"
    echo "     - Sin sudo"
    echo "     - NO puede SSH al servidor"
    echo "     - Solo lectura en /srv/games"
    echo ""
    echo -e "${YELLOW}📁 Carpetas creadas:${NC}"
    echo "  - /srv/admin (privada admin)"
    echo "  - /srv/audits (privada auditor)"
    echo "  - /srv/games (compartida)"
    echo "  - /srv/instaladores (compartida)"
    echo ""
    echo -e "${YELLOW}🔥 Firewall configurado y activo${NC}"
    echo ""
else
    echo -e "${RED}✗ Error en la configuración${NC}"
    exit 1
fi
