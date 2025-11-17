#!/bin/bash
# Script para activar el entorno virtual de Ansible

if [ -d "$HOME/ansible-venv" ]; then
    echo "✅ Activando entorno virtual..."
    source "$HOME/ansible-venv/bin/activate"
    echo "✅ Entorno virtual activado"
    echo ""
    echo "Para desactivar: deactivate"
    echo ""
    # Mantener la shell activa con el venv
    exec bash
else
    echo "❌ No existe el entorno virtual en $HOME/ansible-venv"
    echo ""
    echo "Créalo con:"
    echo "  python3 -m venv ~/ansible-venv"
    echo "  source ~/ansible-venv/bin/activate"
    echo "  pip install ansible pyvmomi requests jinja2"
    exit 1
fi
