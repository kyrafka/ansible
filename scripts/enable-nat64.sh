#!/bin/bash
# Script para habilitar NAT64 en el servidor
# Esto permite que las VMs IPv6 accedan a internet IPv4

# Auto-permisos
[ ! -x "$0" ] && chmod +x "$0" 2>/dev/null

set -e

echo "════════════════════════════════════════"
echo "🌐 Habilitando NAT64 + DNS64"
echo "════════════════════════════════════════"
echo ""

cd "$(dirname "$0")/.."

echo "→ Ejecutando playbook..."
ansible-playbook playbooks/enable-nat64.yml \
    --connection=local \
    --become \
    --ask-become-pass

echo ""
echo "════════════════════════════════════════"
echo "✅ Proceso completado"
echo "════════════════════════════════════════"
