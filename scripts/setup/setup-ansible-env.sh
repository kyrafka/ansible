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

# Verificar que NO se ejecute como root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  ⚠️  ERROR: No ejecutes este script como root                 ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "El entorno virtual debe crearse para tu usuario normal, no para root."
    echo ""
    echo "Ejecuta como usuario normal:"
    echo -e "  ${YELLOW}bash scripts/setup/setup-ansible-env.sh --auto${NC}"
    echo ""
    echo "Si necesitas permisos sudo, el script te los pedirá cuando sea necesario."
    echo ""
    exit 1
fi

# Variables globales
PYTHON_BIN="/usr/bin/python3"
VENV_DIR="$HOME/.ansible-venv"

echo -e "${GREEN}✓${NC} Ejecutando como usuario: ${YELLOW}$USER${NC}"
echo -e "${GREEN}✓${NC} Entorno se creará en: ${YELLOW}$VENV_DIR${NC}"
echo ""

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
        echo -e "  ${YELLOW}→ Ejecuta opción 3 para instalar${NC}"
        return 1
    fi
}

# Función para verificar paquete Python
check_python_package() {
    local package=$1
    local import_name=$2
    
    if [ -f "$VENV_DIR/bin/python" ]; then
        if "$VENV_DIR/bin/python" -c "import $import_name" 2>/dev/null; then
            VERSION=$("$VENV_DIR/bin/pip" show $package 2>/dev/null | grep Version | awk '{print $2}')
            echo -e "${GREEN}✓${NC} $package instalado: $VERSION"
            return 0
        fi
    fi
    echo -e "${RED}✗${NC} $package no instalado"
    echo -e "  ${YELLOW}→ Ejecuta opción 3 para instalar${NC}"
    return 1
}

# Función para verificar pyvmomi
check_pyvmomi() {
    check_python_package "pyvmomi" "pyVim"
}

# Función para verificar requests
check_requests() {
    check_python_package "requests" "requests"
}

# Función para verificar jinja2
check_jinja2() {
    check_python_package "jinja2" "jinja2"
}

# Función para verificar colección
check_collection() {
    local collection=$1
    local required=$2  # "required" o "optional"
    
    if [ ! -f "$VENV_DIR/bin/ansible-galaxy" ]; then
        echo -e "${RED}✗${NC} $collection - Ansible no instalado"
        echo -e "  ${YELLOW}→ Ejecuta opción 3 primero${NC}"
        return 1
    fi
    
    if "$VENV_DIR/bin/ansible-galaxy" collection list 2>/dev/null | grep -q "$collection"; then
        VERSION=$("$VENV_DIR/bin/ansible-galaxy" collection list 2>/dev/null | grep "$collection" | awk '{print $2}')
        echo -e "${GREEN}✓${NC} $collection: $VERSION"
        return 0
    else
        if [ "$required" == "optional" ]; then
            echo -e "${YELLOW}⚠${NC} $collection no instalado (opcional)"
        else
            echo -e "${RED}✗${NC} $collection no instalado"
            echo -e "  ${YELLOW}→ Ejecuta opción 4 para instalar${NC}"
        fi
        return 1
    fi
}

# Función para verificar ansible.cfg
check_ansible_cfg() {
    if [ -f "ansible.cfg" ]; then
        if grep -q "ansible_python_interpreter.*ansible-venv" ansible.cfg 2>/dev/null; then
            echo -e "${GREEN}✓${NC} ansible.cfg configurado correctamente"
            return 0
        else
            echo -e "${YELLOW}⚠${NC} ansible.cfg existe pero puede necesitar actualización"
            echo -e "  ${YELLOW}→ Ejecuta opción 5 para actualizar${NC}"
            return 1
        fi
    else
        echo -e "${RED}✗${NC} ansible.cfg no existe"
        echo -e "  ${YELLOW}→ Ejecuta opción 5 para crear${NC}"
        return 1
    fi
}

# Función para verificar activate script
check_activate_script() {
    if [ -f "activate-ansible.sh" ]; then
        echo -e "${GREEN}✓${NC} activate-ansible.sh existe"
        return 0
    else
        echo -e "${RED}✗${NC} activate-ansible.sh no existe"
        echo -e "  ${YELLOW}→ Ejecuta opción 5 para crear${NC}"
        return 1
    fi
}

# Función para mostrar tabla de estado
show_status() {
    local total=0
    local installed=0
    
    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║              📊 Estado de Dependencias                        ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${BLUE}┌─ Sistema Base ────────────────────────────────────────────────┐${NC}"
    check_python && ((installed++)); ((total++))
    check_venv && ((installed++)); ((total++))
    echo -e "${BLUE}└───────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    echo -e "${BLUE}┌─ Paquetes Python ─────────────────────────────────────────────┐${NC}"
    check_ansible && ((installed++)); ((total++))
    check_pyvmomi && ((installed++)); ((total++))
    check_requests && ((installed++)); ((total++))
    check_jinja2 && ((installed++)); ((total++))
    echo -e "${BLUE}└───────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    echo -e "${BLUE}┌─ Colecciones Ansible (Requeridas) ────────────────────────────┐${NC}"
    check_collection "community.vmware" "required" && ((installed++)); ((total++))
    check_collection "community.general" "required" && ((installed++)); ((total++))
    check_collection "ansible.posix" "required" && ((installed++)); ((total++))
    check_collection "community.windows" "required" && ((installed++)); ((total++))
    echo -e "${BLUE}└───────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    echo -e "${BLUE}┌─ Colecciones Opcionales ──────────────────────────────────────┐${NC}"
    check_collection "vmware.vmware" "optional"
    echo -e "${BLUE}└───────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    echo -e "${BLUE}┌─ Configuración ───────────────────────────────────────────────┐${NC}"
    check_ansible_cfg && ((installed++)); ((total++))
    check_activate_script && ((installed++)); ((total++))
    echo -e "${BLUE}└───────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    # Resumen
    local percentage=$((installed * 100 / total))
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    if [ $installed -eq $total ]; then
        echo -e "${GREEN}║  ✅ TODO INSTALADO: $installed/$total componentes ($percentage%)${NC}"
        echo -e "${GREEN}║  Listo para usar Ansible!${NC}"
    elif [ $installed -gt 0 ]; then
        echo -e "${YELLOW}║  ⚠ PARCIALMENTE INSTALADO: $installed/$total ($percentage%)${NC}"
        echo -e "${YELLOW}║  Faltan $((total - installed)) componentes${NC}"
    else
        echo -e "${RED}║  ✗ NADA INSTALADO: $installed/$total ($percentage%)${NC}"
        echo -e "${RED}║  Ejecuta opción 6 para instalar todo${NC}"
    fi
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
}

# Función para instalar paquetes del sistema
install_system_packages() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}📦 Instalando paquetes del sistema...${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    
    echo "→ Actualizando lista de paquetes..."
    if sudo apt update 2>&1 | grep -q "Err:"; then
        echo -e "${YELLOW}⚠ Algunos repositorios fallaron, continuando...${NC}"
    else
        echo -e "${GREEN}✓ Lista de paquetes actualizada${NC}"
    fi
    
    local packages=(
        "python3"
        "python3-pip"
        "python3-venv"
        "python3-dev"
        "build-essential"
        "libssl-dev"
        "libffi-dev"
        "sshpass"
        "git"
        "apparmor-utils"
    )
    
    echo "→ Instalando paquetes necesarios..."
    for pkg in "${packages[@]}"; do
        if dpkg -l 2>/dev/null | grep -q "^ii  $pkg "; then
            echo -e "  ${GREEN}✓ $pkg ya instalado${NC}"
        else
            echo "  → Instalando $pkg..."
            if sudo DEBIAN_FRONTEND=noninteractive apt install -y "$pkg" 2>&1 | tee /tmp/apt-install-$pkg.log | grep -q "Setting up"; then
                echo -e "    ${GREEN}✓ $pkg instalado${NC}"
            else
                if dpkg -l 2>/dev/null | grep -q "^ii  $pkg "; then
                    echo -e "    ${GREEN}✓ $pkg ya estaba instalado${NC}"
                else
                    echo -e "    ${YELLOW}⚠ $pkg - revisar /tmp/apt-install-$pkg.log${NC}"
                fi
            fi
        fi
    done
    
    echo -e "${GREEN}✅ Paquetes del sistema instalados${NC}"
}

# Función para instalar venv
install_venv() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}📦 Creando entorno virtual...${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    
    if [ ! -d "$VENV_DIR" ]; then
        echo "→ Creando entorno virtual en $VENV_DIR..."
        if $PYTHON_BIN -m venv "$VENV_DIR"; then
            echo -e "${GREEN}✓ Entorno virtual creado exitosamente${NC}"
        else
            echo -e "${RED}✗ Error al crear entorno virtual${NC}"
            return 1
        fi
    else
        echo -e "${GREEN}✓ Entorno virtual ya existe${NC}"
    fi
    
    echo -e "${GREEN}✅ Entorno virtual listo${NC}"
}

# Función para instalar Ansible
install_ansible() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}📦 Instalando Ansible y dependencias Python...${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    
    if [ ! -d "$VENV_DIR" ]; then
        echo -e "${RED}✗ Error: Primero debes crear el entorno virtual (opción 2)${NC}"
        return 1
    fi
    
    source "$VENV_DIR/bin/activate"
    
    echo "→ Actualizando pip, setuptools, wheel..."
    if pip install --upgrade pip setuptools wheel 2>&1 | tee /tmp/pip-upgrade.log | grep -qE "(Successfully installed|Requirement already satisfied)"; then
        echo -e "${GREEN}✓ pip actualizado${NC}"
    else
        echo -e "${YELLOW}⚠ Revisar /tmp/pip-upgrade.log si hay problemas${NC}"
    fi
    
    echo "→ Instalando Ansible..."
    pip install --upgrade ansible 2>&1 | tee /tmp/pip-ansible.log
    if command -v ansible &> /dev/null; then
        VERSION=$(ansible --version 2>/dev/null | head -1 | awk '{print $2}')
        echo -e "${GREEN}✓ Ansible $VERSION instalado${NC}"
    else
        echo -e "${RED}✗ Error al instalar Ansible - revisar /tmp/pip-ansible.log${NC}"
        return 1
    fi
    
    echo "→ Instalando pyvmomi (VMware SDK)..."
    pip install --upgrade pyvmomi 2>&1 | tee /tmp/pip-pyvmomi.log
    if python -c "import pyVim" 2>/dev/null; then
        echo -e "${GREEN}✓ pyvmomi instalado${NC}"
    else
        echo -e "${YELLOW}⚠ pyvmomi - revisar /tmp/pip-pyvmomi.log${NC}"
    fi
    
    echo "→ Instalando requests y jinja2..."
    pip install --upgrade requests jinja2 2>&1 | tee /tmp/pip-deps.log
    if python -c "import requests, jinja2" 2>/dev/null; then
        echo -e "${GREEN}✓ requests y jinja2 instalados${NC}"
    else
        echo -e "${YELLOW}⚠ requests/jinja2 - revisar /tmp/pip-deps.log${NC}"
    fi
    
    echo -e "${GREEN}✅ Todos los paquetes Python instalados correctamente${NC}"
}

# Función para instalar colecciones
install_collections() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}📦 Instalando colecciones Ansible...${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    
    if [ ! -f "$VENV_DIR/bin/ansible-galaxy" ]; then
        echo -e "${RED}✗ Error: Primero debes instalar Ansible (opción 3)${NC}"
        return 1
    fi
    
    source "$VENV_DIR/bin/activate"
    
    local failed=0
    
    if [ -f "collections/requirements.yml" ]; then
        echo "→ Instalando desde collections/requirements.yml..."
        if ansible-galaxy collection install -r collections/requirements.yml --force; then
            echo -e "${GREEN}✓ Colecciones desde requirements.yml instaladas${NC}"
        else
            echo -e "${RED}✗ Error al instalar desde requirements.yml${NC}"
            failed=1
        fi
    else
        echo -e "${YELLOW}⚠ collections/requirements.yml no encontrado${NC}"
        echo "→ Instalando colecciones individualmente..."
        
        echo "  → community.vmware..."
        ansible-galaxy collection install community.vmware --force && echo -e "    ${GREEN}✓${NC}" || { echo -e "    ${RED}✗${NC}"; failed=1; }
        
        echo "  → community.general..."
        ansible-galaxy collection install community.general --force && echo -e "    ${GREEN}✓${NC}" || { echo -e "    ${RED}✗${NC}"; failed=1; }
        
        echo "  → ansible.posix..."
        ansible-galaxy collection install ansible.posix --force && echo -e "    ${GREEN}✓${NC}" || { echo -e "    ${RED}✗${NC}"; failed=1; }
        
        echo "  → community.windows..."
        ansible-galaxy collection install community.windows --force && echo -e "    ${GREEN}✓${NC}" || { echo -e "    ${RED}✗${NC}"; failed=1; }
    fi
    
    echo "→ Instalando vmware.vmware (opcional)..."
    if ansible-galaxy collection install vmware.vmware --force 2>/dev/null; then
        echo -e "${GREEN}✓ vmware.vmware instalado${NC}"
    else
        echo -e "${YELLOW}⚠ vmware.vmware no disponible (opcional, no es crítico)${NC}"
    fi
    
    if [ $failed -eq 0 ]; then
        echo -e "${GREEN}✅ Todas las colecciones instaladas correctamente${NC}"
        return 0
    else
        echo -e "${RED}✗ Algunas colecciones fallaron${NC}"
        return 1
    fi
}

# Función para configurar ansible.cfg
configure_ansible_cfg() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}⚙️  Configurando ansible.cfg...${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    
    VENV_PYTHON="$VENV_DIR/bin/python3"
    
    if [ ! -f "ansible.cfg" ]; then
        echo "→ Creando ansible.cfg..."
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
        echo "→ ansible.cfg ya existe, actualizando..."
        if grep -q "ansible_python_interpreter" ansible.cfg; then
            sed -i "s|ansible_python_interpreter=.*|ansible_python_interpreter=$VENV_PYTHON|" ansible.cfg
            echo -e "${GREEN}✓ ansible_python_interpreter actualizado${NC}"
        else
            sed -i "/\[defaults\]/a ansible_python_interpreter=$VENV_PYTHON" ansible.cfg
            echo -e "${GREEN}✓ ansible_python_interpreter agregado${NC}"
        fi
    fi
    
    # Crear script de activación
    echo "→ Creando activate-ansible.sh..."
    cat > activate-ansible.sh << 'EOF'
#!/bin/bash
source ~/.ansible-venv/bin/activate
echo "✓ Entorno Ansible activado"
echo "Ahora puedes ejecutar: ansible-playbook create-vm-gamecenter.yml"
EOF
    chmod +x activate-ansible.sh
    echo -e "${GREEN}✓ activate-ansible.sh creado${NC}"
    
    echo -e "${GREEN}✅ Configuración completada${NC}"
}

# Función para instalar todo
install_all() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}Instalando TODO...${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    
    install_system_packages
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
    echo "2) Instalar paquetes del sistema (python3, pip, etc)"
    echo "3) Instalar entorno virtual (venv)"
    echo "4) Instalar Ansible y paquetes Python"
    echo "5) Instalar colecciones Ansible"
    echo "6) Configurar ansible.cfg"
    echo "7) Instalar TODO (opción rápida)"
    echo "8) Salir"
    echo ""
    read -p "Selecciona una opción [1-8]: " option
    
    case $option in
        1) show_status; show_menu ;;
        2) install_system_packages; show_menu ;;
        3) install_venv; show_menu ;;
        4) install_ansible; show_menu ;;
        5) install_collections; show_menu ;;
        6) configure_ansible_cfg; show_menu ;;
        7) install_all ;;
        8) echo "Saliendo..."; exit 0 ;;
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


