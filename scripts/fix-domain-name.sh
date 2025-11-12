#!/bin/bash
# Script para cambiar gamecenter.local a gamecenter.lan en todos los archivos

echo "🔄 Cambiando gamecenter.local → gamecenter.lan"
echo ""

# Archivos a modificar
files=(
    "scripts/run/run-all-services.sh"
    "scripts/run/run-web.sh"
    "scripts/diagnostics/test-dns-records.sh"
    "scripts/diagnostics/diagnose-dns.sh"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "→ Modificando $file"
        sed -i 's/gamecenter\.local/gamecenter.lan/g' "$file"
    else
        echo "⚠️  No encontrado: $file"
    fi
done

echo ""
echo "✅ Cambio completado"
echo ""
echo "Ahora ejecuta:"
echo "  sudo bash scripts/run/run-dns.sh"
