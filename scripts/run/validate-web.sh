#!/bin/bash
# Script para validar la instalación y configuración de Nginx

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
echo -e "${BLUE}   🔍 VALIDACIÓN DE SERVIDOR WEB (NGINX)${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""

# Cargar funciones comunes
source "$SCRIPT_DIR/validate-common.sh"

ERRORS=0

# 1. Verificar que Nginx está instalado
echo -e "${YELLOW}📦 Verificando instalación de Nginx...${NC}"
if ssh ubuntu@servidor "which nginx" &>/dev/null; then
    echo -e "${GREEN}✅ Nginx está instalado${NC}"
    NGINX_VERSION=$(ssh ubuntu@servidor "nginx -v 2>&1 | cut -d'/' -f2")
    echo "   → Versión: $NGINX_VERSION"
else
    echo -e "${RED}❌ Nginx NO está instalado${NC}"
    ((ERRORS++))
fi

# 2. Verificar que el servicio está activo
echo ""
echo -e "${YELLOW}🔄 Verificando servicio Nginx...${NC}"
if ssh ubuntu@servidor "systemctl is-active nginx" &>/dev/null; then
    echo -e "${GREEN}✅ Servicio Nginx está activo${NC}"
else
    echo -e "${RED}❌ Servicio Nginx NO está activo${NC}"
    ((ERRORS++))
fi

if ssh ubuntu@servidor "systemctl is-enabled nginx" &>/dev/null; then
    echo -e "${GREEN}✅ Servicio Nginx está habilitado${NC}"
else
    echo -e "${RED}❌ Servicio Nginx NO está habilitado${NC}"
    ((ERRORS++))
fi

# 3. Verificar puerto 80
echo ""
echo -e "${YELLOW}🔌 Verificando puerto 80...${NC}"
if ssh ubuntu@servidor "ss -tlnp | grep ':80'" &>/dev/null; then
    echo -e "${GREEN}✅ Nginx escuchando en puerto 80${NC}"
else
    echo -e "${RED}❌ Nginx NO está escuchando en puerto 80${NC}"
    ((ERRORS++))
fi

# 4. Verificar archivos de configuración
echo ""
echo -e "${YELLOW}📁 Verificando archivos de configuración...${NC}"
if ssh ubuntu@servidor "test -f /etc/nginx/nginx.conf"; then
    echo -e "${GREEN}✅ Archivo nginx.conf existe${NC}"
else
    echo -e "${RED}❌ Archivo nginx.conf NO existe${NC}"
    ((ERRORS++))
fi

if ssh ubuntu@servidor "test -f /etc/nginx/sites-available/default"; then
    echo -e "${GREEN}✅ Configuración del sitio existe${NC}"
else
    echo -e "${RED}❌ Configuración del sitio NO existe${NC}"
    ((ERRORS++))
fi

if ssh ubuntu@servidor "test -f /var/www/html/index.html"; then
    echo -e "${GREEN}✅ Página index.html existe${NC}"
else
    echo -e "${RED}❌ Página index.html NO existe${NC}"
    ((ERRORS++))
fi

# 5. Verificar sintaxis de configuración
echo ""
echo -e "${YELLOW}✔️  Verificando sintaxis de configuración...${NC}"
if ssh ubuntu@servidor "sudo nginx -t" &>/dev/null; then
    echo -e "${GREEN}✅ Configuración de Nginx es válida${NC}"
else
    echo -e "${RED}❌ Configuración de Nginx tiene errores${NC}"
    ((ERRORS++))
fi

# 6. Verificar firewall
echo ""
echo -e "${YELLOW}🔥 Verificando reglas de firewall...${NC}"
if ssh ubuntu@servidor "sudo ufw status | grep '80/tcp'" &>/dev/null; then
    echo -e "${GREEN}✅ Puerto 80 permitido en firewall${NC}"
else
    echo -e "${RED}❌ Puerto 80 NO está permitido en firewall${NC}"
    ((ERRORS++))
fi

# 7. Probar acceso HTTP local
echo ""
echo -e "${YELLOW}🌐 Probando acceso HTTP local...${NC}"
if ssh ubuntu@servidor "curl -s -o /dev/null -w '%{http_code}' http://localhost" | grep -q "200"; then
    echo -e "${GREEN}✅ Servidor responde correctamente (HTTP 200)${NC}"
else
    echo -e "${RED}❌ Servidor NO responde correctamente${NC}"
    ((ERRORS++))
fi

# 8. Verificar logs
echo ""
echo -e "${YELLOW}📋 Verificando logs...${NC}"
if ssh ubuntu@servidor "test -f /var/log/nginx/access.log"; then
    echo -e "${GREEN}✅ Log de accesos existe${NC}"
    ACCESS_LINES=$(ssh ubuntu@servidor "wc -l < /var/log/nginx/access.log")
    echo "   → Líneas en access.log: $ACCESS_LINES"
else
    echo -e "${RED}❌ Log de accesos NO existe${NC}"
    ((ERRORS++))
fi

if ssh ubuntu@servidor "test -f /var/log/nginx/error.log"; then
    echo -e "${GREEN}✅ Log de errores existe${NC}"
    ERROR_LINES=$(ssh ubuntu@servidor "wc -l < /var/log/nginx/error.log")
    echo "   → Líneas en error.log: $ERROR_LINES"
else
    echo -e "${RED}❌ Log de errores NO existe${NC}"
    ((ERRORS++))
fi

# 9. Verificar resolución DNS
echo ""
echo -e "${YELLOW}🔍 Verificando resolución DNS...${NC}"
if ssh ubuntu@servidor "nslookup gamecenter.local localhost" &>/dev/null; then
    echo -e "${GREEN}✅ DNS resuelve gamecenter.local${NC}"
else
    echo -e "${YELLOW}⚠️  DNS no resuelve gamecenter.local (puede ser normal si DNS no está configurado)${NC}"
fi

# Resumen final
echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}   ✅ VALIDACIÓN EXITOSA - NGINX FUNCIONANDO${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}📊 Acceso al servidor web:${NC}"
    echo "   → http://gamecenter.local"
    echo "   → http://www.gamecenter.local"
    echo "   → http://web.gamecenter.local"
    echo "   → http://servidor.gamecenter.local"
    echo ""
    echo -e "${YELLOW}🔧 Comandos útiles:${NC}"
    echo "   → Ver logs: ssh ubuntu@servidor 'sudo tail -f /var/log/nginx/access.log'"
    echo "   → Reiniciar: ssh ubuntu@servidor 'sudo systemctl restart nginx'"
    echo "   → Estado: ssh ubuntu@servidor 'sudo systemctl status nginx'"
    echo ""
    exit 0
else
    echo -e "${RED}   ❌ VALIDACIÓN FALLIDA - $ERRORS ERROR(ES) ENCONTRADO(S)${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}💡 Soluciones sugeridas:${NC}"
    echo "   1. Reinstalar Nginx: bash scripts/run/run-web.sh"
    echo "   2. Ver logs de Nginx: ssh ubuntu@servidor 'sudo journalctl -u nginx -n 50'"
    echo "   3. Verificar firewall: ssh ubuntu@servidor 'sudo ufw status'"
    echo "   4. Probar configuración: ssh ubuntu@servidor 'sudo nginx -t'"
    echo ""
    exit 1
fi
