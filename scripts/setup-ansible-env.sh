#!/bin/bash
# Script interactivo para configurar el entorno de Ansible con todas las dependencias

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     🔧 Configuración de Entorno Ansible + VMware             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Variables globales
PYTHON_BIN="/usr/bin/python3"
VENV_DIR="$HOME/.ansible-venv"

# Función para verificar Python
check_python() {
    if [ -f "$PYTHON_BIN" ]; then
        echo -e "${GREEN}✓${NC} Python encontrado: $PYTHON_BIN"
        echo "  Versión: $($PYTHON_BIN --version)"
        return 0
    else
        echo -e "${RED}✗${NC} Python3 no encontrado en $PYTHON_BIN"
        return 1
    fi
}

# Función para verificar venv
check_venv() {
    if [ -d "$VENV_DIR" ]; then
        echo -e "${GREEN}✓${NC} Entorno virtual existe en $VENV_DIR"
        return 0
    else
        echo -e "${RED}✗${NC} Entorno virtual no existe"
        return 1
    fi
}

# Función para verificar Ansible
check_ansible() {
    if [ -f "$VENV_DIR/bin/ansible" ]; then
        VERSION=$("$VENV_DIR/bin/ansible" --version 2>/dev/null | head -1 | awk '{print $2}')
        echo -e "${GREEN}✓${NC} Ansible instalado: $VERSION"
        return 0
    else
        echo -e "${RED}✗${NC} Ansible no instalado"
        return 1
    fi
}

# Función para verificar pyvmomi
check_pyvmomi() {
    if [ -f "$VENV_DIR/bin/python" ]; then
        if "$VENV_DIR/bin/python" -c "import pyVim" 2>/dev/null; then
            VERSION=$("$VENV_DIR/bin/pip" show pyvmomi 2>/dev/null | grep Version | awk '{print $2}')
            echo -e "${GREEN}✓${NC} pyvmomi instalado: $VERSION"
            return 0
        fi
    fi
    echo -e "${RED}✗${NC} pyvmomi no instalado"
    return 1
}

# Función para verificar colección
check_collection() {
    local collection=$1
    if [ -f "$VENV_DIR/bin/ansible-galaxy" ]; then
        if "$VENV_DIR/bin/ansible-galaxy" collection list 2>/dev/null | grep -q "$collection"; then
            VERSION=$("$VENV_DIR/bin/ansible-galaxy" collection list 2>/dev/null | grep "$collection" | awk '{print $2}')
            echo -e "${GREEN}✓${NC} $collection instalado: $VERSION"
            return 0
        fi
    fi
    echo -e "${RED}✗${NC} $collection no instalado"
    return 1
}

# Función para mostrar tabla de estado
show_status() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}Estado de Dependencias${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    echo "Sistema Base:"
    check_python
    check_venv
    echo ""
    
    echo "Paquetes Python:"
    check_ansible
    check_pyvmomi
    echo ""
    
    echo "Colecciones Ansible:"
    check_collection "community.vmware"
    check_collection "community.general"
    check_collection "ansible.posix"
    check_collection "community.windows"
    check_collection "vmware.vmware"
    echo ""
    
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
}

# Función para instalar venv
install_venv() {
    echo ""
    echo -e "${YELLOW}Instalando entorno virtual...${NC}"
    
    if ! dpkg -l | grep -q python3-venv; then
        echo "📦 Instalando python3-venv..."
        sudo apt update
        sudo apt install python3-venv -y
    fi
    
    if [ ! -d "$VENV_DIR" ]; then
        echo "📦 Creando entorno virtual en $VENV_DIR..."
        $PYTHON_BIN -m venv "$VENV_DIR"
        echo -e "${GREEN}✓ Entorno virtual creado${NC}"
    else
        echo -e "${GREEN}✓ Entorno virtual ya existe${NC}"
    fi
}

# Función para instalar Ansible
install_ansible() {
    echo ""
    echo -e "${YELLOW}Instalando Ansible y dependencias Python...${NC}"
    
    if [ ! -d "$VENV_DIR" ]; then
        echo -e "${RED}Error: Primero debes crear el entorno virtual${NC}"
        return 1
    fi
    
    source "$VENV_DIR/bin/activate"
    
    echo "📦 Actualizando pip..."
    pip install --upgrade pip setuptools wheel --quiet
    
    echo "📦 Instalando Ansible, pyvmomi, requests, jinja2..."
    pip install --upgrade ansible pyvmomi requests jinja2 --quiet
    
    echo -e "${GREEN}✓ Paquetes Python instalados${NC}"
}

# Función para instalar colecciones
install_collections() {
    echo ""
    echo -e "${YELLOW}Instalando colecciones Ansible...${NC}"
    
    if [ ! -f "$VENV_DIR/bin/ansible-galaxy" ]; then
        echo -e "${RED}Error: Primero debes instalar Ansible${NC}"
        return 1
    fi
    
    source "$VENV_DIR/bin/activate"
    
    if [ -f "collections/requirements.yml" ]; then
        echo "📦 Instalando desde collections/requirements.yml..."
        ansible-galaxy collection install -r collections/requirements.yml --force
    else
        echo "📦 Instalando colecciones individualmente..."
        ansible-galaxy collection install community.vmware --force
        ansible-galaxy collection install community.general --force
        ansible-galaxy collection install ansible.posix --force
        ansible-galaxy collection install community.windows --force
    fi
    
    echo "📦 Instalando vmware.vmware..."
    ansible-galaxy collection install vmware.vmware --force 2>/dev/null || echo -e "${YELLOW}⚠ vmware.vmware no disponible (opcional)${NC}"
    
    echo -e "${GREEN}✓ Colecciones instaladas${NC}"
}

# Función para configurar ansible.cfg
configure_ansible_cfg() {
    echo ""
    echo -e "${YELLOW}Configurando ansible.cfg...${NC}"
    
    VENV_PYTHON="$VENV_DIR/bin/python3"
    
    if [ ! -f "ansible.cfg" ]; then
        cat > ansible.cfg << EOF
[defaults]
ansible_python_interpreter=$VENV_PYTHON
host_key_checking = False
inventory = inventory/hosts.ini
roles_path = roles
collections_paths = ~/.ansible/collections:/usr/share/ansible/collections
retry_files_enabled = False
stdout_callback = yaml
bin_ansible_callbacks = True

[inventory]
enable_plugins = host_list, script, auto, yaml, ini, toml

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False
EOF
        echo -e "${GREEN}✓ ansible.cfg creado${NC}"
    else
        if grep -q "ansible_python_interpreter" ansible.cfg; then
            sed -i "s|ansible_python_interpreter=.*|ansible_python_interpreter=$VENV_PYTHON|" ansible.cfg
            echo -e "${GREEN}✓ ansible_python_interpreter actualizado${NC}"
        else
            sed -i "/\[defaults\]/a ansible_python_interpreter=$VENV_PYTHON" ansible.cfg
            echo -e "${GREEN}✓ ansible_python_interpreter agregado${NC}"
        fi
    fi
    
    # Crear script de activación
    cat > activate-ansible.sh << 'EOF'
#!/bin/bash
source ~/.ansible-venv/bin/activate
echo "✓ Entorno Ansible activado"
echo "Ahora puedes ejecutar: ansible-playbook create-vm-gamecenter.yml"
EOF
    chmod +x activate-ansible.sh
    echo -e "${GREEN}✓ activate-ansible.sh creado${NC}"
}

# Función para instalar todo
install_all() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}Instalando TODO...${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    
    check_python || exit 1
    
    install_venv
    install_ansible
    install_collections
    configure_ansible_cfg
    
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    ✅ Instalación Completa                    ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Para usar Ansible:"
    echo "  source activate-ansible.sh"
    echo ""
}

# Menú principal
show_menu() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}Menú de Instalación${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "1) Ver estado de dependencias"
    echo "2) Instalar entorno virtual (venv)"
    echo "3) Instalar Ansible y paquetes Python"
    echo "4) Instalar colecciones Ansible"
    echo "5) Configurar ansible.cfg"
    echo "6) Instalar TODO (opción rápida)"
    echo "7) Salir"
    echo ""
    read -p "Selecciona una opción [1-7]: " option
    
    case $option in
        1) show_status; show_menu ;;
        2) install_venv; show_menu ;;
        3) install_ansible; show_menu ;;
        4) install_collections; show_menu ;;
        5) configure_ansible_cfg; show_menu ;;
        6) install_all ;;
        7) echo "Saliendo..."; exit 0 ;;
        *) echo -e "${RED}Opción inválida${NC}"; show_menu ;;
    esac
}

# Verificar si se ejecuta con argumentos
if [ "$1" == "--auto" ] || [ "$1" == "-a" ]; then
    install_all
else
    check_python || exit 1
    show_menu
fi


