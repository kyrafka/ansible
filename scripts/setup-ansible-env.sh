#!/bin/bash
# Script para configurar el entorno de Ansible con todas las dependencias

set -e

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     🔧 Configuración de Entorno Ansible + VMware             ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Detectar Python
PYTHON_BIN="/usr/bin/python3"
VENV_DIR="$HOME/.ansible-venv"

if [ ! -f "$PYTHON_BIN" ]; then
    echo "❌ Python3 no encontrado en $PYTHON_BIN"
    exit 1
fi

echo "✓ Python encontrado: $PYTHON_BIN"
echo "  Versión: $($PYTHON_BIN --version)"
echo ""

# Instalar python3-venv si no existe
if ! dpkg -l | grep -q python3-venv; then
    echo "📦 Instalando python3-venv..."
    sudo apt update
    sudo apt install python3-venv -y
fi

# Crear entorno virtual si no existe
if [ ! -d "$VENV_DIR" ]; then
    echo "📦 Creando entorno virtual en $VENV_DIR..."
    $PYTHON_BIN -m venv "$VENV_DIR"
    echo "✓ Entorno virtual creado"
else
    echo "✓ Entorno virtual ya existe"
fi

echo ""

# Activar entorno virtual
source "$VENV_DIR/bin/activate"
echo "✓ Entorno virtual activado"
echo ""

# Actualizar pip
echo "📦 Actualizando pip..."
pip install --upgrade pip setuptools wheel --quiet
echo "✓ pip actualizado"
echo ""

# Instalar dependencias
echo "📦 Instalando dependencias de Ansible y VMware..."
pip install --upgrade \
    ansible \
    pyvmomi \
    requests \
    jinja2 \
    --quiet

echo "✓ Dependencias instaladas"
echo ""

# Verificar instalación
echo "🔍 Verificando instalaciones..."
echo ""

# Verificar Ansible
if command -v ansible &> /dev/null; then
    echo "✓ Ansible: $(ansible --version | head -1)"
else
    echo "❌ Ansible no encontrado en PATH"
fi

# Verificar pyvmomi
if python -c "import pyVim" 2>/dev/null; then
    PYVMOMI_VERSION=$(pip show pyvmomi | grep Version | awk '{print $2}')
    echo "✓ pyvmomi: $PYVMOMI_VERSION"
else
    echo "❌ pyvmomi no se puede importar"
fi

# Verificar requests
if python -c "import requests" 2>/dev/null; then
    REQUESTS_VERSION=$(pip show requests | grep Version | awk '{print $2}')
    echo "✓ requests: $REQUESTS_VERSION"
else
    echo "❌ requests no se puede importar"
fi

echo ""

# Instalar colección de VMware
echo "📦 Instalando colección community.vmware..."
ansible-galaxy collection install community.vmware --force
echo "✓ Colección instalada"
echo ""

# Configurar ansible.cfg
echo "⚙️  Configurando ansible.cfg..."
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
    echo "✓ ansible.cfg creado"
else
    # Actualizar intérprete en ansible.cfg existente
    if grep -q "ansible_python_interpreter" ansible.cfg; then
        sed -i "s|ansible_python_interpreter=.*|ansible_python_interpreter=$VENV_PYTHON|" ansible.cfg
        echo "✓ ansible_python_interpreter actualizado en ansible.cfg"
    else
        sed -i "/\[defaults\]/a ansible_python_interpreter=$VENV_PYTHON" ansible.cfg
        echo "✓ ansible_python_interpreter agregado a ansible.cfg"
    fi
fi

echo ""

# Crear script de activación
cat > activate-ansible.sh << 'EOF'
#!/bin/bash
source ~/.ansible-venv/bin/activate
echo "✓ Entorno Ansible activado"
echo "Ahora puedes ejecutar: ansible-playbook create-vm-gamecenter.yml"
EOF
chmod +x activate-ansible.sh

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    ✅ Configuración Completa                  ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Para usar Ansible, primero activa el entorno virtual:"
echo "  source ~/.ansible-venv/bin/activate"
echo ""
echo "O usa el script de activación:"
echo "  source activate-ansible.sh"
echo ""
echo "Luego ejecuta tus playbooks:"
echo "  ansible-playbook create-vm-gamecenter.yml"
echo ""
echo "Para agregar la activación automática a tu .bashrc:"
echo "  echo 'source ~/.ansible-venv/bin/activate' >> ~/.bashrc"
echo ""
