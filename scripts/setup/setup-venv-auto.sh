#!/bin/bash
# Script para configurar entorno virtual automáticamente

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}🔧 Configuración automática del entorno virtual${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo ""

VENV_DIR="$HOME/ansible-venv"

# 1. Crear venv si no existe
if [ ! -d "$VENV_DIR" ]; then
    echo "→ Creando entorno virtual..."
    python3 -m venv "$VENV_DIR"
    echo -e "${GREEN}✓ Entorno virtual creado${NC}"
else
    echo -e "${GREEN}✓ Entorno virtual ya existe${NC}"
fi

# 2. Activar venv
echo "→ Activando entorno virtual..."
source "$VENV_DIR/bin/activate"
echo -e "${GREEN}✓ Entorno virtual activado${NC}"

# 3. Actualizar pip
echo "→ Actualizando pip..."
pip install --upgrade pip > /dev/null 2>&1
echo -e "${GREEN}✓ pip actualizado${NC}"

# 4. Instalar paquetes Python
echo "→ Instalando paquetes Python..."
pip install ansible pyvmomi requests jinja2 netaddr > /dev/null 2>&1
echo -e "${GREEN}✓ Paquetes Python instalados${NC}"

# 5. Instalar colecciones Ansible
echo "→ Instalando colecciones Ansible..."
ansible-galaxy collection install community.vmware --force > /dev/null 2>&1
ansible-galaxy collection install community.general --force > /dev/null 2>&1
ansible-galaxy collection install ansible.posix --force > /dev/null 2>&1
ansible-galaxy collection install community.windows --force > /dev/null 2>&1
echo -e "${GREEN}✓ Colecciones Ansible instaladas${NC}"

# 6. Verificar instalación
echo ""
echo "→ Verificando instalación..."
echo -e "${GREEN}✓ Ansible: $(ansible --version | head -1)${NC}"
python -c "import pyvmomi; print('✓ pyvmomi OK')" 2>/dev/null || echo -e "${RED}✗ pyvmomi FALLO${NC}"
python -c "import requests; print('✓ requests OK')" 2>/dev/null || echo -e "${RED}✗ requests FALLO${NC}"
python -c "import jinja2; print('✓ jinja2 OK')" 2>/dev/null || echo -e "${RED}✗ jinja2 FALLO${NC}"

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Entorno virtual configurado exitosamente${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo ""
echo "Para usar Ansible:"
echo "  1. Activar venv: source ~/ansible-venv/bin/activate"
echo "  2. Ejecutar: bash scripts/vms/create-server.sh"
echo ""
echo "O ejecuta directamente (el venv ya está activo):"
echo "  bash scripts/vms/create-server.sh"
echo ""

# Mantener el venv activo
exec bash
