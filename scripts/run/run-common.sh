#!/bin/bash
# Script para ejecutar solo el rol common
# Ejecutar desde la raíz del proyecto: bash scripts/run/run-common.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT"

if [ -f ~/.ansible-venv/bin/activate ]; then
    source ~/.ansible-venv/bin/activate
fi

ansible-playbook site.yml --connection=local --become --ask-become-pass --tags common
