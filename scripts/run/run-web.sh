#!/bin/bash
# Script para configurar el servidor web Nginx

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   🌐 CONFIGURACIÓN DE SERVIDOR WEB (NGINX)${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""

# Cargar funciones comunes
source "$SCRIPT_DIR/run-common.sh"

# Verificar que estamos en WSL
check_wsl

# Cambiar al directorio del proyecto
cd "$PROJECT_ROOT"

echo -e "${YELLOW}📋 Información:${NC}"
echo "   → Instalará Nginx"
echo "   → Configurará sitio web"
echo "   → Abrirá puerto 80 en firewall"
echo "   → Creará página de bienvenida"
echo ""

# Preguntar confirmación
read -p "¿Continuar con la instalación? (s/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo -e "${RED}❌ Instalación cancelada${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}🚀 Ejecutando playbook de Nginx...${NC}"
echo ""

# Ejecutar playbook con tag web
if ansible-playbook site.yml --tags web; then
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}   ✅ NGINX INSTALADO CORRECTAMENTE${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}📊 Acceso al servidor web:${NC}"
    echo "   → http://gamecenter.local"
    echo "   → http://www.gamecenter.local"
    echo "   → http://web.gamecenter.local"
    echo "   → http://servidor.gamecenter.local"
    echo ""
    echo -e "${YELLOW}🔍 Validar instalación:${NC}"
    echo "   bash scripts/run/validate-web.sh"
    echo ""
else
    echo ""
    echo -e "${RED}════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}   ❌ ERROR EN LA INSTALACIÓN DE NGINX${NC}"
    echo -e "${RED}════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}💡 Posibles soluciones:${NC}"
    echo "   1. Verificar que el servidor esté accesible"
    echo "   2. Revisar logs: journalctl -u nginx -n 50"
    echo "   3. Ejecutar validación: bash scripts/run/validate-web.sh"
    echo ""
    exit 1
fi
