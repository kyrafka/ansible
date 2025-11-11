#!/bin/bash
# Script para ejecutar solo el rol network
# Ejecutar desde la raíz del proyecto: bash scripts/run/run-network.sh

set -e  # Salir si hay errores

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT"

echo "════════════════════════════════════════════════════════════"
echo "🌐 Configurando Red (Network Role)"
echo "════════════════════════════════════════════════════════════"
echo ""

# Verificar si estamos en el entorno virtual
if [ -n "$VIRTUAL_ENV" ]; then
    echo "✓ Entorno virtual activo: $VIRTUAL_ENV"
elif [ -f "$HOME/.ansible-venv/bin/activate" ]; then
    echo "→ Activando entorno virtual..."
    source "$HOME/.ansible-venv/bin/activate"
    echo "✓ Entorno virtual activado"
else
    echo "⚠ Entorno virtual no encontrado, usando Ansible del sistema"
fi

# Verificar si ansible-playbook está disponible
if ! command -v ansible-playbook &> /dev/null; then
    echo "❌ Error: ansible-playbook no está instalado"
    echo ""
    echo "Opciones:"
    echo "  1. Instalar con el script: bash scripts/setup/setup-ansible-env.sh --auto"
    echo "  2. Instalar manualmente: sudo apt install ansible"
    exit 1
fi

ANSIBLE_VERSION=$(ansible --version 2>/dev/null | head -1 | awk '{print $2}')
echo "✓ Ansible $ANSIBLE_VERSION encontrado"
echo ""

echo "→ Ejecutando playbook con tag 'network'..."
echo ""

ansible-playbook -i inventory/hosts.ini site.yml \
    --connection=local \
    --become \
    --ask-become-pass \
    --tags network \
    -v

echo ""
echo "════════════════════════════════════════════════════════════"
echo "✅ Configuración de red completada"
echo "════════════════════════════════════════════════════════════"
