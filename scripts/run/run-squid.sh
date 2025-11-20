#!/bin/bash

echo "════════════════════════════════════════════════════════════════"
echo "🌐 CONFIGURAR SQUID PROXY TRANSPARENTE"
echo "════════════════════════════════════════════════════════════════"
echo ""

cd "$(dirname "$0")/../.." || exit 1

ansible-playbook -i inventory.yml playbooks/setup-squid.yml

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✅ SQUID CONFIGURADO"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "🧪 Prueba desde el cliente:"
echo ""
echo "  # Navegar en Firefox"
echo "  firefox http://www.google.com"
echo ""
echo "  # Verificar que pasa por Squid (desde el servidor)"
echo "  sudo tail -f /var/log/squid/access.log"
echo ""
echo "════════════════════════════════════════════════════════════════"
