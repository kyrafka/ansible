#!/bin/bash
# Script para configurar servicios adicionales (Samba, FTP, Monitoreo, GUI)
# Ejecutar: bash scripts/run/run-services.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT"

echo "════════════════════════════════════════════════════════"
echo "🚀 Configurando servicios adicionales"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Se instalará:"
echo "  📁 Samba - Compartir archivos"
echo "  📂 FTP - Transferencia de archivos"
echo "  📊 Netdata - Monitoreo en tiempo real"
echo "  🖥️  Cockpit - Panel web de administración"
echo "  🎨 XFCE - Interfaz gráfica ligera"
echo "  🔌 XRDP - Acceso remoto por RDP"
echo ""
read -p "¿Continuar? (s/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "❌ Cancelado"
    exit 0
fi

ansible-playbook -i inventory/hosts.ini site.yml --connection=local --become --ask-become-pass --tags services
