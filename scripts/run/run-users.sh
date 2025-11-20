#!/bin/bash
# Script para crear usuarios del servidor
# Ejecutar: bash scripts/run/run-users.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT"

echo "════════════════════════════════════════════════════════"
echo "👥 Configurando usuarios del servidor"
echo "════════════════════════════════════════════════════════"
echo ""

ansible-playbook -i inventory/hosts.ini site.yml --connection=local --become --ask-become-pass --tags users
