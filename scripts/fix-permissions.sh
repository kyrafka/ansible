#!/bin/bash
# Script para otorgar permisos de ejecución a todos los scripts del proyecto

# Auto-otorgar permisos a sí mismo primero
chmod +x "$0" 2>/dev/null || true

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   🔧 Otorgando permisos de ejecución a todos los scripts     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Contador
count=0

# Buscar y dar permisos a todos los .sh
echo -e "${YELLOW}Buscando scripts...${NC}"
echo ""

while IFS= read -r -d '' script; do
    if [ ! -x "$script" ]; then
        chmod +x "$script"
        echo -e "${GREEN}✓${NC} $script"
        ((count++))
    else
        echo -e "${BLUE}→${NC} $script (ya tenía permisos)"
    fi
done < <(find scripts -name "*.sh" -type f -print0 2>/dev/null)

# También dar permisos a activate-ansible.sh si existe
if [ -f "activate-ansible.sh" ]; then
    if [ ! -x "activate-ansible.sh" ]; then
        chmod +x "activate-ansible.sh"
        echo -e "${GREEN}✓${NC} activate-ansible.sh"
        ((count++))
    fi
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✅ Permisos otorgados a $count scripts                        ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Ahora puedes ejecutar cualquier script con:${NC}"
echo "  bash scripts/nombre-del-script.sh"
echo ""
