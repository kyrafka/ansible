#!/bin/bash
# Script para activar el entorno virtual de Ansible

if [ -f "$HOME/.ansible-venv/bin/activate" ]; then
    source "$HOME/.ansible-venv/bin/activate"
    echo "✓ Entorno Ansible activado"
    echo ""
    echo "Comandos disponibles:"
    echo "  • ansible-playbook site.yml --tags network    # Configurar red"
    echo "  • bash scripts/run/run-network.sh             # Atajo para red"
    echo "  • ansible-playbook site.yml                   # Ejecutar todo"
    echo ""
    ANSIBLE_VERSION=$(ansible --version 2>/dev/null | head -1 | awk '{print $2}')
    echo "Ansible $ANSIBLE_VERSION listo para usar"
else
    echo "❌ Error: Entorno virtual no encontrado en ~/.ansible-venv"
    echo ""
    echo "Instala primero con:"
    echo "  bash scripts/setup/setup-ansible-env.sh --auto"
    exit 1
fi
