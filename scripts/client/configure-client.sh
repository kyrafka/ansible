#!/bin/bash

echo "════════════════════════════════════════════════════════════════"
echo "🖥️  CONFIGURACIÓN DE CLIENTE UBUNTU DESKTOP"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Este script configurará tu Ubuntu Desktop para usar:"
echo "  • DNS del servidor (2025:db8:10::2)"
echo "  • IPv6 únicamente"
echo "  • NAT64 para acceso a internet"
echo ""
echo "⚠️  IMPORTANTE: Ejecuta esto DESDE EL CLIENTE, no desde el servidor"
echo ""
read -p "¿Continuar? (s/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "❌ Cancelado"
    exit 1
fi

echo ""
echo "🔧 Ejecutando playbook de configuración..."
echo ""

cd "$(dirname "$0")/../.." || exit 1

ansible-playbook playbooks/configure-local-ubuntu.yml

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✅ CONFIGURACIÓN COMPLETADA"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "🧪 Prueba la conectividad:"
echo ""
echo "  # Ping al servidor"
echo "  ping6 2025:db8:10::2"
echo ""
echo "  # Ping a internet (NAT64)"
echo "  ping6 64:ff9b::8.8.8.8"
echo ""
echo "  # Resolver nombre"
echo "  ping6 google.com"
echo ""
echo "  # Navegar en Firefox"
echo "  firefox http://www.google.com"
echo ""
echo "════════════════════════════════════════════════════════════════"
