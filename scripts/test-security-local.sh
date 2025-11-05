#!/bin/bash
# Script para probar funciones de seguridad localmente

set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🧪 PRUEBAS LOCALES DE SEGURIDAD${NC}"
echo "==============================="
echo ""

# 1. Probar verificación de servicios
echo -e "${BLUE}1. Probando verificación de servicios...${NC}"
services=("ssh" "cron" "systemd-timesyncd")
for service in "${services[@]}"; do
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        echo -e "  ✅ $service: ${GREEN}ACTIVO${NC}"
    else
        echo -e "  ⚠️  $service: ${YELLOW}INACTIVO O NO INSTALADO${NC}"
    fi
done

echo ""

# 2. Probar verificación de puertos
echo -e "${BLUE}2. Probando verificación de puertos...${NC}"
echo "Puertos abiertos en el sistema:"
ss -tuln | grep LISTEN | head -10 | while read line; do
    echo "  $line"
done

echo ""

# 3. Probar verificación de usuarios
echo -e "${BLUE}3. Probando verificación de usuarios...${NC}"
users_with_shell=$(grep -E "/bin/(bash|sh|zsh)" /etc/passwd 2>/dev/null | wc -l || echo "0")
echo "  Usuarios con shell de login: $users_with_shell"

echo ""

# 4. Probar verificación de espacio en disco
echo -e "${BLUE}4. Probando verificación de espacio...${NC}"
df -h | head -5 | while read line; do
    echo "  $line"
done

echo ""

# 5. Probar verificación de procesos
echo -e "${BLUE}5. Probando top procesos por CPU...${NC}"
ps -eo pid,comm,%cpu --sort=-%cpu | head -6 | while read line; do
    echo "  $line"
done

echo ""

# 6. Probar generación de reporte
echo -e "${BLUE}6. Probando generación de reporte...${NC}"
report_file="/tmp/security-test-$(date +%Y%m%d-%H%M).txt"
{
    echo "REPORTE DE PRUEBA - $(date)"
    echo "=========================="
    echo ""
    echo "Sistema: $(uname -a)"
    echo "Uptime: $(uptime)"
    echo ""
    echo "Servicios activos:"
    systemctl list-units --type=service --state=active | head -10
} > "$report_file"

echo -e "  📄 Reporte generado: ${GREEN}$report_file${NC}"

echo ""
echo -e "${GREEN}✅ Todas las pruebas locales completadas${NC}"
echo ""
echo -e "${YELLOW}💡 Para probar más funciones:${NC}"
echo "  - ansible-playbook test-local.yml"
echo "  - ./scripts/test-network-connectivity.sh"
echo "  - ./scripts/security-hardening.sh --dry-run"