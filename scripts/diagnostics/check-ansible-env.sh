#!/bin/bash
# Script para verificar que el entorno de Ansible esté correctamente configurado

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     🔍 Verificación de Entorno Ansible                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

VENV_DIR="$HOME/.ansible-venv"
ERRORS=0

# Función para verificar archivo/directorio
check_path() {
    local path=$1
    local type=$2  # "file" o "dir"
    local description=$3
    
    if [ "$type" == "dir" ]; then
        if [ -d "$path" ]; then
            echo -e "${GREEN}✓${NC} $description"
            echo -e "  ${BLUE}→${NC} $path"
            return 0
        else
            echo -e "${RED}✗${NC} $description"
            echo -e "  ${RED}→${NC} $path (NO EXISTE)"
            ((ERRORS++))
            return 1
        fi
    else
        if [ -f "$path" ]; then
            echo -e "${GREEN}✓${NC} $description"
            echo -e "  ${BLUE}→${NC} $path"
            return 0
        else
            echo -e "${RED}✗${NC} $description"
            echo -e "  ${RED}→${NC} $path (NO EXISTE)"
            ((ERRORS++))
            return 1
        fi
    fi
}

# Función para verificar comando
check_command() {
    local cmd=$1
    local description=$2
    
    if command -v "$cmd" &> /dev/null; then
        local version=$($cmd --version 2>&1 | head -1)
        echo -e "${GREEN}✓${NC} $description"
        echo -e "  ${BLUE}→${NC} $version"
        return 0
    else
        echo -e "${RED}✗${NC} $description"
        echo -e "  ${RED}→${NC} Comando no encontrado: $cmd"
        ((ERRORS++))
        return 1
    fi
}

echo -e "${BLUE}┌─ Sistema Base ────────────────────────────────────────────────┐${NC}"
check_command "python3" "Python3"
check_command "pip3" "pip3"
echo -e "${BLUE}└───────────────────────────────────────────────────────────────┘${NC}"
echo ""

echo -e "${BLUE}┌─ Entorno Virtual ─────────────────────────────────────────────┐${NC}"
check_path "$VENV_DIR" "dir" "Directorio del entorno virtual"
check_path "$VENV_DIR/bin" "dir" "Directorio bin/"
check_path "$VENV_DIR/bin/activate" "file" "Script de activación"
check_path "$VENV_DIR/bin/python" "file" "Python del entorno"
check_path "$VENV_DIR/bin/python3" "file" "Python3 del entorno"
check_path "$VENV_DIR/bin/pip" "file" "pip del entorno"
echo -e "${BLUE}└───────────────────────────────────────────────────────────────┘${NC}"
echo ""

echo -e "${BLUE}┌─ Ansible ─────────────────────────────────────────────────────┐${NC}"
check_path "$VENV_DIR/bin/ansible" "file" "Comando ansible"
check_path "$VENV_DIR/bin/ansible-playbook" "file" "Comando ansible-playbook"
check_path "$VENV_DIR/bin/ansible-galaxy" "file" "Comando ansible-galaxy"
echo -e "${BLUE}└───────────────────────────────────────────────────────────────┘${NC}"
echo ""

echo -e "${BLUE}┌─ Librerías Python ────────────────────────────────────────────┐${NC}"
if [ -f "$VENV_DIR/bin/python" ]; then
    echo "Verificando paquetes instalados..."
    
    if "$VENV_DIR/bin/python" -c "import ansible" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} ansible (módulo Python)"
    else
        echo -e "${RED}✗${NC} ansible (módulo Python) - NO INSTALADO"
        ((ERRORS++))
    fi
    
    if "$VENV_DIR/bin/python" -c "import pyVim" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} pyvmomi (VMware SDK)"
    else
        echo -e "${RED}✗${NC} pyvmomi (VMware SDK) - NO INSTALADO"
        ((ERRORS++))
    fi
    
    if "$VENV_DIR/bin/python" -c "import requests" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} requests"
    else
        echo -e "${RED}✗${NC} requests - NO INSTALADO"
        ((ERRORS++))
    fi
    
    if "$VENV_DIR/bin/python" -c "import jinja2" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} jinja2"
    else
        echo -e "${RED}✗${NC} jinja2 - NO INSTALADO"
        ((ERRORS++))
    fi
else
    echo -e "${RED}✗${NC} No se puede verificar (Python no encontrado)"
    ((ERRORS++))
fi
echo -e "${BLUE}└───────────────────────────────────────────────────────────────┘${NC}"
echo ""

echo -e "${BLUE}┌─ Archivos del Proyecto ───────────────────────────────────────┐${NC}"
check_path "activate-ansible.sh" "file" "Script de activación del proyecto"
check_path "ansible.cfg" "file" "Configuración de Ansible"
check_path "inventory/hosts.ini" "file" "Inventario de hosts"
check_path "group_vars/all.yml" "file" "Variables de grupo"
echo -e "${BLUE}└───────────────────────────────────────────────────────────────┘${NC}"
echo ""

# Resumen
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}║  ✅ TODO CORRECTO - Entorno listo para usar                   ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Para activar el entorno:"
    echo -e "  ${YELLOW}source activate-ansible.sh${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}║  ❌ ERRORES ENCONTRADOS: $ERRORS problema(s)                        ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Soluciones:${NC}"
    echo ""
    
    if [ ! -d "$VENV_DIR" ]; then
        echo "1. El entorno virtual no existe. Créalo con:"
        echo -e "   ${YELLOW}python3 -m venv ~/.ansible-venv${NC}"
        echo ""
    fi
    
    if [ ! -f "$VENV_DIR/bin/ansible" ]; then
        echo "2. Ansible no está instalado. Instálalo con:"
        echo -e "   ${YELLOW}source ~/.ansible-venv/bin/activate${NC}"
        echo -e "   ${YELLOW}pip install ansible pyvmomi requests jinja2${NC}"
        echo ""
    fi
    
    echo "O ejecuta el script de instalación completo:"
    echo -e "   ${YELLOW}bash scripts/setup/setup-ansible-env.sh --auto${NC}"
    echo ""
    exit 1
fi
