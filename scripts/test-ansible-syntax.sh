#!/bin/bash
# Script para probar sintaxis de Ansible sin ejecutar

set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🧪 PRUEBAS DE SINTAXIS DE ANSIBLE${NC}"
echo "================================="
echo ""

# 1. Verificar sintaxis del playbook principal
echo -e "${BLUE}1. Verificando sintaxis de site.yml...${NC}"
if ansible-playbook --syntax-check site.yml >/dev/null 2>&1; then
    echo -e "  ✅ site.yml: ${GREEN}SINTAXIS CORRECTA${NC}"
else
    echo -e "  ❌ site.yml: ${RED}ERROR DE SINTAXIS${NC}"
    ansible-playbook --syntax-check site.yml
fi

# 2. Verificar sintaxis del playbook de pruebas
echo -e "${BLUE}2. Verificando sintaxis de test-local.yml...${NC}"
if ansible-playbook --syntax-check test-local.yml >/dev/null 2>&1; then
    echo -e "  ✅ test-local.yml: ${GREEN}SINTAXIS CORRECTA${NC}"
else
    echo -e "  ❌ test-local.yml: ${RED}ERROR DE SINTAXIS${NC}"
fi

# 3. Verificar inventario
echo -e "${BLUE}3. Verificando inventario...${NC}"
if ansible-inventory -i inventory/hosts.ini --list >/dev/null 2>&1; then
    echo -e "  ✅ inventory/hosts.ini: ${GREEN}VÁLIDO${NC}"
    echo "  Grupos encontrados:"
    ansible-inventory -i inventory/hosts.ini --list | grep -E '"[a-zA-Z_]+":' | head -5 | sed 's/^/    /'
else
    echo -e "  ❌ inventory/hosts.ini: ${RED}ERROR${NC}"
fi

# 4. Verificar roles
echo -e "${BLUE}4. Verificando roles...${NC}"
for role_dir in roles/*/; do
    role_name=$(basename "$role_dir")
    if [ -f "$role_dir/tasks/main.yml" ]; then
        if ansible-playbook --syntax-check -e "test_mode=true" <(echo "- hosts: localhost; roles: [{ role: $role_name }]") >/dev/null 2>&1; then
            echo -e "  ✅ rol $role_name: ${GREEN}SINTAXIS CORRECTA${NC}"
        else
            echo -e "  ⚠️  rol $role_name: ${YELLOW}REVISAR SINTAXIS${NC}"
        fi
    fi
done

# 5. Verificar variables
echo -e "${BLUE}5. Verificando variables...${NC}"
if [ -f "group_vars/all.yml" ]; then
    if python3 -c "import yaml; yaml.safe_load(open('group_vars/all.yml'))" 2>/dev/null; then
        echo -e "  ✅ group_vars/all.yml: ${GREEN}YAML VÁLIDO${NC}"
    else
        echo -e "  ❌ group_vars/all.yml: ${RED}YAML INVÁLIDO${NC}"
    fi
fi

# 6. Modo dry-run (simulación)
echo -e "${BLUE}6. Probando ejecución en modo dry-run...${NC}"
if ansible-playbook test-local.yml --check --diff >/dev/null 2>&1; then
    echo -e "  ✅ Dry-run: ${GREEN}EXITOSO${NC}"
else
    echo -e "  ⚠️  Dry-run: ${YELLOW}CON ADVERTENCIAS${NC}"
fi

echo ""
echo -e "${GREEN}✅ Verificación de sintaxis completada${NC}"
echo ""
echo -e "${YELLOW}💡 Para ejecutar pruebas reales:${NC}"
echo "  ansible-playbook test-local.yml --check --diff"
echo "  ansible-playbook test-local.yml --tags test_procesos"