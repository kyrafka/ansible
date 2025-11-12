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
    echo -e "${YELLOW}📦 Verificando paquetes del sistema...${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    
    echo "→ Actualizando lista de paquetes..."
    if sudo apt update 2>&1 | grep -q "Err:"; then
        echo -e "${YELLOW}⚠ Algunos repositorios fallaron, continuando...${NC}"
    else
        echo -e "${GREEN}✓ Lista de paquetes actualizada${NC}"
    fi
    
    # Verificar cuántos paquetes tienen actualizaciones
    local upgradable_count=$(apt list --upgradable 2>/dev/null | grep -c "upgradable")
    if [ "$upgradable_count" -gt 0 ]; then
        echo -e "${YELLOW}⚠ Hay $upgradable_count paquetes del sistema con actualizaciones disponibles${NC}"
        
        if [ "$AUTO_MODE" = true ]; then
            echo "→ Modo automático: actualizando todos los paquetes del sistema..."
            sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y
            echo -e "${GREEN}✓ Sistema actualizado${NC}"
        else
            read -p "¿Deseas actualizar TODOS los paquetes del sistema? (s/n): " upgrade_all
            if [ "$upgrade_all" == "s" ] || [ "$upgrade_all" == "S" ]; then
                sudo apt upgrade -y
                echo -e "${GREEN}✓ Sistema actualizado${NC}"
            else
                echo -e "${YELLOW}→ Actualización del sistema omitida${NC}"
            fi
        fi
    else
        echo -e "${GREEN}✓ Sistema completamente actualizado${NC}"
    fi
    
    # Paquetes críticos (deben instalarse)
    local critical_packages=(
        "python3"
        "python3-pip"
        "python3-venv"
        "python3-dev"
        "sshpass"
        "git"
        "apparmor-utils"
    )
    
    # Paquetes opcionales (útiles pero no críticos)
    local optional_packages=(
        "build-essential"
        "libssl-dev"
        "libffi-dev"
    )
    
    local packages=("${critical_packages[@]}" "${optional_packages[@]}")
    
    local to_install=()
    local to_upgrade=()
    
    echo "→ Verificando paquetes..."
    for pkg in "${packages[@]}"; do
        # Verificar si está instalado (ii = installed)
        if dpkg -l 2>/dev/null | grep -q "^ii  $pkg "; then
            echo -e "  ${GREEN}✓ $pkg ya instalado${NC}"
            # Verificar si hay actualizaciones
            if apt list --upgradable 2>/dev/null | grep -q "^$pkg/"; then
                to_upgrade+=("$pkg")
                echo -e "    ${YELLOW}→ Actualización disponible${NC}"
            fi
        # Verificar si está en estado "rc" (removed but config remains) o similar
        elif dpkg -l 2>/dev/null | grep -q "^rc  $pkg "; then
            to_install+=("$pkg")
            echo -e "  ${YELLOW}→ $pkg necesita reinstalarse${NC}"
        # Verificar si el paquete existe en los repositorios
        elif apt-cache show "$pkg" &>/dev/null; then
            to_install+=("$pkg")
            echo -e "  ${YELLOW}→ $pkg necesita instalarse${NC}"
        else
            echo -e "  ${YELLOW}⚠ $pkg no encontrado en repositorios (omitiendo)${NC}"
        fi
    done
    
    # Instalar paquetes faltantes
    if [ ${#to_install[@]} -gt 0 ]; then
        echo ""
        echo "→ Instalando ${#to_install[@]} paquetes faltantes..."
        
        # Intentar instalar todos juntos primero
        if sudo DEBIAN_FRONTEND=noninteractive apt install -y "${to_install[@]}" 2>&1 | tee /tmp/apt-install.log | grep -q "no se pudo instalar"; then
            echo -e "${YELLOW}→ Algunos paquetes fallaron, intentando uno por uno...${NC}"
            
            # Intentar instalar uno por uno
            for pkg in "${to_install[@]}"; do
                if sudo DEBIAN_FRONTEND=noninteractive apt install -y "$pkg" 2>/dev/null; then
                    echo -e "  ${GREEN}✓ $pkg instalado${NC}"
                else
                    echo -e "  ${YELLOW}⚠ $pkg no disponible (omitiendo)${NC}"
                fi
            done
        fi
        
        # Verificar si realmente se instalaron
        local install_failed=0
        for pkg in "${to_install[@]}"; do
            if ! dpkg -l 2>/dev/null | grep -q "^ii  $pkg "; then
                echo -e "    ${YELLOW}⚠ $pkg no se pudo instalar (puede no estar disponible)${NC}"
                install_failed=$((install_failed + 1))
            fi
        done
        
        if [ $install_failed -eq 0 ]; then
            echo -e "${GREEN}✓ Todos los paquetes instalados correctamente${NC}"
        else
            # Verificar si los paquetes críticos están instalados
            local critical_missing=0
            for pkg in "${critical_packages[@]}"; do
                if ! dpkg -l 2>/dev/null | grep -q "^ii  $pkg "; then
                    critical_missing=$((critical_missing + 1))
                fi
            done
            
            if [ $critical_missing -eq 0 ]; then
                echo -e "${GREEN}✓ Paquetes críticos instalados (algunos opcionales fallaron, pero no son necesarios)${NC}"
            else
                echo -e "${YELLOW}⚠ $install_failed paquetes no se instalaron, incluyendo $critical_missing críticos${NC}"
            fi
        fi
    fi
    
    # Actualizar paquetes si hay disponibles
    if [ ${#to_upgrade[@]} -gt 0 ]; then
        echo ""
        echo -e "${YELLOW}Hay ${#to_upgrade[@]} paquetes con actualizaciones disponibles:${NC}"
        for pkg in "${to_upgrade[@]}"; do
            echo "  - $pkg"
        done
        
        if [ "$AUTO_MODE" = true ]; then
            echo "→ Modo automático: actualizando paquetes..."
            sudo apt upgrade -y "${to_upgrade[@]}"
            echo -e "${GREEN}✓ Paquetes actualizados${NC}"
        else
            read -p "¿Deseas actualizar estos paquetes? (s/n): " upgrade_choice
            if [ "$upgrade_choice" == "s" ] || [ "$upgrade_choice" == "S" ]; then
                sudo apt upgrade -y "${to_upgrade[@]}"
                echo -e "${GREEN}✓ Paquetes actualizados${NC}"
            else
                echo -e "${YELLOW}→ Actualizaciones omitidas${NC}"
            fi
        fi
    fi
    
    echo -e "${GREEN}✅ Verificación de paquetes completada${NC}"
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
    echo -e "${YELLOW}📦 Instalando Ansible...${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    
    # Verificar si Ansible ya está instalado
    if command -v ansible &> /dev/null; then
        VERSION=$(ansible --version 2>/dev/null | head -1)
        echo -e "${GREEN}✓ Ansible ya está instalado: $VERSION${NC}"
        
        # Verificar si hay actualizaciones disponibles
        echo "→ Verificando actualizaciones..."
        if sudo apt list --upgradable 2>/dev/null | grep -q "ansible"; then
            echo -e "${YELLOW}⚠ Hay actualizaciones disponibles para Ansible${NC}"
            
            if [ "$AUTO_MODE" = true ]; then
                echo "→ Modo automático: actualizando Ansible..."
                sudo apt update
                sudo apt upgrade -y ansible
                echo -e "${GREEN}✓ Ansible actualizado${NC}"
            else
                read -p "¿Deseas actualizar Ansible? (s/n): " update_choice
                if [ "$update_choice" == "s" ] || [ "$update_choice" == "S" ]; then
                    sudo apt update
                    sudo apt upgrade -y ansible
                    echo -e "${GREEN}✓ Ansible actualizado${NC}"
                else
                    echo -e "${YELLOW}→ Actualización omitida${NC}"
                fi
            fi
        else
            echo -e "${GREEN}✓ Ansible está actualizado${NC}"
        fi
    else
        # Instalar Ansible desde repositorios oficiales
        echo "→ Agregando repositorio oficial de Ansible..."
        if ! grep -q "ansible/ansible" /etc/apt/sources.list.d/* 2>/dev/null; then
            sudo apt-add-repository --yes --update ppa:ansible/ansible 2>&1 | tee /tmp/ansible-repo.log
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✓ Repositorio agregado${NC}"
            else
                echo -e "${YELLOW}⚠ No se pudo agregar repositorio PPA, usando repositorios por defecto${NC}"
            fi
        else
            echo -e "${GREEN}✓ Repositorio ya existe${NC}"
        fi
        
        echo "→ Instalando Ansible desde apt..."
        sudo apt update
        sudo apt install -y ansible 2>&1 | tee /tmp/ansible-install.log
        
        if command -v ansible &> /dev/null; then
            VERSION=$(ansible --version 2>/dev/null | head -1)
            echo -e "${GREEN}✓ Ansible instalado: $VERSION${NC}"
        else
            echo -e "${RED}✗ Error al instalar Ansible - revisar /tmp/ansible-install.log${NC}"
            return 1
        fi
    fi
    
    # Verificar dependencias Python (sin instalar con pip del sistema)
    echo "→ Verificando dependencias Python..."
    
    local missing_deps=()
    
    if ! python3 -c "import pyVim" 2>/dev/null; then
        missing_deps+=("python3-pyvmomi")
    fi
    
    if ! python3 -c "import requests" 2>/dev/null; then
        missing_deps+=("python3-requests")
    fi
    
    if ! python3 -c "import jinja2" 2>/dev/null; then
        missing_deps+=("python3-jinja2")
    fi
    
    if ! python3 -c "import netaddr" 2>/dev/null; then
        missing_deps+=("python3-netaddr")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${YELLOW}→ Instalando dependencias faltantes con apt...${NC}"
        for dep in "${missing_deps[@]}"; do
            echo "  → Instalando $dep..."
            sudo apt install -y "$dep" 2>&1 | tee /tmp/apt-install-$dep.log
        done
    else
        echo -e "${GREEN}✓ Todas las dependencias Python ya están instaladas${NC}"
    fi
    
    # Verificar nuevamente
    if python3 -c "import pyVim, requests, jinja2" 2>/dev/null; then
        echo -e "${GREEN}✓ Dependencias Python verificadas${NC}"
    else
        echo -e "${YELLOW}⚠ Algunas dependencias pueden faltar, pero Ansible debería funcionar${NC}"
    fi
    
    echo -e "${GREEN}✅ Ansible y dependencias listos${NC}"
}

# Función para instalar colecciones
install_collections() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}📦 Instalando colecciones Ansible...${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    
    if ! command -v ansible-galaxy &> /dev/null; then
        echo -e "${RED}✗ Error: Primero debes instalar Ansible (opción 4)${NC}"
        return 1
    fi
    
    local failed=0
    
    if [ -f "collections/requirements.yml" ]; then
        echo "→ Instalando desde collections/requirements.yml..."
        if ansible-galaxy collection install -r collections/requirements.yml --force 2>&1 | tee /tmp/ansible-collections.log; then
            echo -e "${GREEN}✓ Colecciones desde requirements.yml instaladas${NC}"
        else
            echo -e "${YELLOW}⚠ Algunos errores al instalar desde requirements.yml${NC}"
            echo -e "${YELLOW}→ Continuando con instalación individual...${NC}"
            failed=1
        fi
    else
        echo -e "${YELLOW}⚠ collections/requirements.yml no encontrado${NC}"
    fi
    
    echo "→ Instalando colecciones individualmente..."
    
    echo "  → community.vmware..."
    if ansible-galaxy collection install community.vmware --force 2>&1 | grep -q "successfully"; then
        echo -e "    ${GREEN}✓ Instalado${NC}"
    else
        echo -e "    ${YELLOW}⚠ Error o ya instalado${NC}"
    fi
    
    echo "  → community.general..."
    if ansible-galaxy collection install community.general --force 2>&1 | grep -q "successfully"; then
        echo -e "    ${GREEN}✓ Instalado${NC}"
    else
        echo -e "    ${YELLOW}⚠ Error o ya instalado${NC}"
    fi
    
    echo "  → ansible.posix..."
    if ansible-galaxy collection install ansible.posix --force 2>&1 | grep -q "successfully"; then
        echo -e "    ${GREEN}✓ Instalado${NC}"
    else
        echo -e "    ${YELLOW}⚠ Error o ya instalado${NC}"
    fi
    
    echo "  → community.windows..."
    if ansible-galaxy collection install community.windows --force 2>&1 | grep -q "successfully"; then
        echo -e "    ${GREEN}✓ Instalado${NC}"
    else
        echo -e "    ${YELLOW}⚠ Error o ya instalado${NC}"
    fi
    
    echo "→ Instalando vmware.vmware (opcional)..."
    if ansible-galaxy collection install vmware.vmware --force 2>/dev/null; then
        echo -e "${GREEN}✓ vmware.vmware instalado${NC}"
    else
        echo -e "${YELLOW}⚠ vmware.vmware no disponible (opcional, no es crítico)${NC}"
    fi
    
    echo ""
    echo "→ Verificando colecciones instaladas..."
    ansible-galaxy collection list 2>/dev/null | grep -E "(community|ansible|vmware)" || echo "No se pudieron listar colecciones"
    
    echo -e "${GREEN}✅ Proceso de instalación de colecciones completado${NC}"
    return 0
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
    
    # Crear script de activación (ya no necesario con instalación de sistema)
    echo "→ Creando activate-ansible.sh..."
    cat > activate-ansible.sh << 'EOF'
#!/bin/bash
# Ansible está instalado a nivel de sistema, no necesita activación
if command -v ansible &> /dev/null; then
    echo "✓ Ansible está disponible en el sistema"
    ansible --version | head -1
    echo ""
    echo "Puedes ejecutar directamente:"
    echo "  ansible-playbook playbooks/create-ubuntu-desktop.yml"
else
    echo "✗ Error: Ansible no está instalado"
    echo "Ejecuta: bash scripts/setup/setup-ansible-env.sh --auto"
fi
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
    echo "2) Instalar paquetes del sistema (python3, pip, apparmor-utils, etc)"
    echo "3) Instalar entorno virtual (venv) - OPCIONAL"
    echo "4) Instalar Ansible (desde apt o pip)"
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

# Variable global para modo automático
AUTO_MODE=false

# Verificar si se ejecuta con argumentos
if [ "$1" == "--auto" ] || [ "$1" == "-a" ]; then
    AUTO_MODE=true
    install_all
else
    check_python || exit 1
    show_menu
fi


