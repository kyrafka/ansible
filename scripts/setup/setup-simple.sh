#!/bin/bash
# Script SIMPLE para configurar Ansible - SIN COMPLICACIONES

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}🔧 Instalación SIMPLE de Ansible${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo ""

# 1. Instalar paquetes del sistema
echo "1️⃣  Instalando paquetes del sistema..."
sudo apt update > /dev/null 2>&1
sudo apt install -y python3 python3-pip python3-venv git sshpass > /dev/null 2>&1
echo -e "${GREEN}✓ Paquetes del sistema instalados${NC}"

# 2. Instalar Ansible desde apt
echo ""
echo "2️⃣  Instalando Ansible..."
if ! command -v ansible &> /dev/null; then
    sudo apt install -y ansible > /dev/null 2>&1
    echo -e "${GREEN}✓ Ansible instalado desde apt${NC}"
else
    echo -e "${GREEN}✓ Ansible ya está instalado${NC}"
fi

# 3. Instalar dependencias Python
echo ""
echo "3️⃣  Instalando dependencias Python..."
sudo apt install -y python3-pyvmomi python3-requests python3-jinja2 python3-netaddr > /dev/null 2>&1
echo -e "${GREEN}✓ Dependencias Python instaladas${NC}"

# 4. Instalar colecciones Ansible
echo ""
echo "4️⃣  Instalando colecciones Ansible..."

echo "  → community.vmware..."
ansible-galaxy collection install community.vmware --force 2>&1 | grep -q "Installing\|already" && echo -e "    ${GREEN}✓${NC}" || echo -e "    ${YELLOW}⚠${NC}"

echo "  → community.general..."
ansible-galaxy collection install community.general --force 2>&1 | grep -q "Installing\|already" && echo -e "    ${GREEN}✓${NC}" || echo -e "    ${YELLOW}⚠${NC}"

echo "  → ansible.posix..."
ansible-galaxy collection install ansible.posix --force 2>&1 | grep -q "Installing\|already" && echo -e "    ${GREEN}✓${NC}" || echo -e "    ${YELLOW}⚠${NC}"

echo "  → community.windows..."
ansible-galaxy collection install community.windows --force 2>&1 | grep -q "Installing\|already" && echo -e "    ${GREEN}✓${NC}" || echo -e "    ${YELLOW}⚠${NC}"

echo -e "${GREEN}✓ Colecciones instaladas${NC}"

# 5. Verificar instalación
echo ""
echo "5️⃣  Verificando instalación..."
echo -e "${GREEN}✓ Ansible: $(ansible --version | head -1)${NC}"

if python3 -c "import pyVim" 2>/dev/null; then
    echo -e "${GREEN}✓ pyvmomi OK${NC}"
else
    echo -e "${YELLOW}⚠ pyvmomi no disponible (puede funcionar igual)${NC}"
fi

if python3 -c "import requests" 2>/dev/null; then
    echo -e "${GREEN}✓ requests OK${NC}"
else
    echo -e "${YELLOW}⚠ requests no disponible${NC}"
fi

if python3 -c "import jinja2" 2>/dev/null; then
    echo -e "${GREEN}✓ jinja2 OK${NC}"
else
    echo -e "${YELLOW}⚠ jinja2 no disponible${NC}"
fi

# 6. Listar colecciones instaladas
echo ""
echo "6️⃣  Colecciones instaladas:"
ansible-galaxy collection list 2>/dev/null | grep -E "(community|ansible)" | head -10

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Instalación completada${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo ""
echo "Ahora puedes ejecutar:"
echo "  bash scripts/vms/create-server.sh"
echo ""
