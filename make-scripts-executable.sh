#!/bin/bash
# Script para dar permisos de ejecución a todos los scripts

echo "🔧 Dando permisos de ejecución a todos los scripts..."
echo ""

# Dar permisos a scripts en raíz de scripts/
chmod +x scripts/*.sh 2>/dev/null

# Dar permisos a scripts en subcarpetas
find scripts/ -type f -name "*.sh" -exec chmod +x {} \;

# Contar scripts
TOTAL=$(find scripts/ -type f -name "*.sh" | wc -l)

echo "✅ Permisos aplicados a $TOTAL scripts"
echo ""
echo "Scripts por carpeta:"
echo "  📁 scripts/nat64/: $(find scripts/nat64/ -type f -name "*.sh" 2>/dev/null | wc -l) scripts"
echo "  📁 scripts/dhcp/: $(find scripts/dhcp/ -type f -name "*.sh" 2>/dev/null | wc -l) scripts"
echo "  📁 scripts/diagnostics/: $(find scripts/diagnostics/ -type f -name "*.sh" 2>/dev/null | wc -l) scripts"
echo "  📁 scripts/run/: $(find scripts/run/ -type f -name "*.sh" 2>/dev/null | wc -l) scripts"
echo "  📁 scripts/server/: $(find scripts/server/ -type f -name "*.sh" 2>/dev/null | wc -l) scripts"
echo "  📁 scripts/quick-deploy/: $(find scripts/quick-deploy/ -type f -name "*.sh" 2>/dev/null | wc -l) scripts"
echo "  📁 scripts/vms/: $(find scripts/vms/ -type f -name "*.sh" 2>/dev/null | wc -l) scripts"
echo "  📁 scripts/setup/: $(find scripts/setup/ -type f -name "*.sh" 2>/dev/null | wc -l) scripts"
echo "  📁 scripts/ (raíz): $(find scripts/ -maxdepth 1 -type f -name "*.sh" 2>/dev/null | wc -l) scripts"
echo ""
echo "✅ Todos los scripts son ahora ejecutables"
