#!/bin/bash
# Script para ejecutar solo el rol network
# Ejecutar desde la raíz del proyecto: bash scripts/run/run-network.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT"

if [ -f ~/.ansible-venv/bin/activate ]; then
    source ~/.ansible-venv/bin/activate
fi

ansible-playbook -i inventory/hosts.ini site.yml --connection=local --become --ask-become-pass --tags network
