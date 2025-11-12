#!/bin/bash
# Script para corregir gamecenter.local → gamecenter.lan en documentación

# Auto-permisos
[ ! -x "$0" ] && chmod +x "$0" 2>/dev/null

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   🔧 Corrigiendo gamecenter.local → gamecenter.lan           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

count=0

# Archivos a corregir (solo documentación y scripts de validación)
files=(
    "scripts/run/validate-web.sh"
    "scripts/run/validate-network.sh"
    "scripts/run/run-web.sh"
    "scripts/run/run-all-services.sh"
    "scripts/diagnostics/test-dns-records.sh"
    "scripts/diagnostics/diagnose-dns.sh"
    "docs/QUE-HACE-CADA-PLAYBOOK.md"
    "README.md"
    "ORDEN-DE-USO.md"
    "ORDEN-CORRECTO-SERVIDOR.md"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        if grep -q "gamecenter\.local" "$file"; then
            sed -i 's/gamecenter\.local/gamecenter.lan/g' "$file"
            echo -e "${GREEN}✓${NC} $file"
            ((count++))
        else
            echo -e "${BLUE}→${NC} $file (ya estaba correcto)"
        fi
    else
        echo -e "${YELLOW}⚠${NC} $file (no existe)"
    fi
done

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✅ $count archivos corregidos                                 ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Ahora usa:${NC}"
echo "  dig @localhost gamecenter.lan AAAA"
echo "  sudo cat /var/lib/bind/db.gamecenter.lan"
echo ""
