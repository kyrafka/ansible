#!/bin/bash
# Script para validar la configuración del rol common
# Ejecutar: bash scripts/run/validate-common.sh

echo "════════════════════════════════════════════════════════"
echo "🔍 Validando Paquetes Base (common)"
echo "════════════════════════════════════════════════════════"
echo ""

ERRORS=0

# Verificar paquetes esenciales
PACKAGES=("net-tools" "iputils-ping" "curl" "wget" "vim" "git" "htop")

for pkg in "${PACKAGES[@]}"; do
    if dpkg -l | grep -q "^ii  $pkg"; then
        echo "✅ $pkg instalado"
    else
        echo "❌ $pkg NO instalado"
        ((ERRORS++))
    fi
done

echo ""
if [ $ERRORS -eq 0 ]; then
    echo "✅ Todos los paquetes base están instalados"
    exit 0
else
    echo "❌ Faltan $ERRORS paquetes"
    exit 1
fi
