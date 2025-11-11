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

ERRORS=0

# 1. Verificar que Nginx está instalado
echo -e "${YELLOW}📦 Verificando instalación de Nginx...${NC}"
if ansible servidor -m shell -a "which nginx" &>/dev/null; then
    echo -e "${GREEN}✅ Nginx está instalado${NC}"
    NGINX_VERSION=$(ansible servidor -m shell -a "nginx -v 2>&1" 2>/dev/null | grep -oP 'nginx/\K[0-9.]+' | head -1)
    echo "   → Versión: $NGINX_VERSION"
else
    echo -e "${RED}❌ Nginx NO está instalado${NC}"
    ((ERRORS++))
fi

# 2. Verificar que el servicio está activo
echo ""
echo -e "${YELLOW}🔄 Verificando servicio Nginx...${NC}"
if ansible servidor -m shell -a "systemctl is-active nginx" &>/dev/null; then
    echo -e "${GREEN}✅ Servicio Nginx está activo${NC}"
else
    echo -e "${RED}❌ Servicio Nginx NO está activo${NC}"
    ((ERRORS++))
fi

if ansible servidor -m shell -a "systemctl is-enabled nginx" &>/dev/null; then
    echo -e "${GREEN}✅ Servicio Nginx está habilitado${NC}"
else
    echo -e "${RED}❌ Servicio Nginx NO está habilitado${NC}"
    ((ERRORS++))
fi

# 3. Verificar puerto 80
echo ""
echo -e "${YELLOW}🔌 Verificando puerto 80...${NC}"
if ansible servidor -m shell -a "ss -tlnp | grep ':80'" &>/dev/null; then
    echo -e "${GREEN}✅ Nginx escuchando en puerto 80${NC}"
else
    echo -e "${RED}❌ Nginx NO está escuchando en puerto 80${NC}"
    ((ERRORS++))
fi

# 4. Verificar archivos de configuración
echo ""
echo -e "${YELLOW}📁 Verificando archivos de configuración...${NC}"
if ansible servidor -m shell -a "test -f /etc/nginx/nginx.conf" &>/dev/null; then
    echo -e "${GREEN}✅ Archivo nginx.conf existe${NC}"
else
    echo -e "${RED}❌ Archivo nginx.conf NO existe${NC}"
    ((ERRORS++))
fi

if ansible servidor -m shell -a "test -f /etc/nginx/sites-available/default" &>/dev/null; then
    echo -e "${GREEN}✅ Configuración del sitio existe${NC}"
else
    echo -e "${RED}❌ Configuración del sitio NO existe${NC}"
    ((ERRORS++))
fi

if ansible servidor -m shell -a "test -f /var/www/html/index.html" &>/dev/null; then
    echo -e "${GREEN}✅ Página index.html existe${NC}"
else
    echo -e "${RED}❌ Página index.html NO existe${NC}"
    ((ERRORS++))
fi

# 5. Verificar sintaxis de configuración
echo ""
echo -e "${YELLOW}✔️  Verificando sintaxis de configuración...${NC}"
if ansible servidor -m shell -a "nginx -t" --become &>/dev/null; then
    echo -e "${GREEN}✅ Configuración de Nginx es válida${NC}"
else
    echo -e "${RED}❌ Configuración de Nginx tiene errores${NC}"
    ((ERRORS++))
fi

# 6. Verificar firewall
echo ""
echo -e "${YELLOW}🔥 Verificando reglas de firewall...${NC}"
if ansible servidor -m shell -a "ufw status | grep '80/tcp'" --become &>/dev/null; then
    echo -e "${GREEN}✅ Puerto 80 permitido en firewall${NC}"
else
    echo -e "${RED}❌ Puerto 80 NO está permitido en firewall${NC}"
    ((ERRORS++))
fi

# 7. Probar acceso HTTP local
echo ""
echo -e "${YELLOW}🌐 Probando acceso HTTP local...${NC}"
HTTP_CODE=$(ansible servidor -m shell -a "curl -s -o /dev/null -w '%{http_code}' http://localhost" 2>/dev/null | grep -oP '\d{3}' | tail -1)
if [ "$HTTP_CODE" == "200" ]; then
    echo -e "${GREEN}✅ Servidor responde correctamente (HTTP 200)${NC}"
else
    echo -e "${RED}❌ Servidor NO responde correctamente (HTTP $HTTP_CODE)${NC}"
    ((ERRORS++))
fi

# 8. Verificar logs
echo ""
echo -e "${YELLOW}📋 Verificando logs...${NC}"
if ansible servidor -m shell -a "test -f /var/log/nginx/access.log" &>/dev/null; then
    echo -e "${GREEN}✅ Log de accesos existe${NC}"
    ACCESS_LINES=$(ansible servidor -m shell -a "wc -l < /var/log/nginx/access.log" 2>/dev/null | grep -oP '\d+' | tail -1)
    echo "   → Líneas en access.log: $ACCESS_LINES"
else
    echo -e "${RED}❌ Log de accesos NO existe${NC}"
    ((ERRORS++))
fi

if ansible servidor -m shell -a "test -f /var/log/nginx/error.log" &>/dev/null; then
    echo -e "${GREEN}✅ Log de errores existe${NC}"
    ERROR_LINES=$(ansible servidor -m shell -a "wc -l < /var/log/nginx/error.log" 2>/dev/null | grep -oP '\d+' | tail -1)
    echo "   → Líneas en error.log: $ERROR_LINES"
else
    echo -e "${RED}❌ Log de errores NO existe${NC}"
    ((ERRORS++))
fi

# 9. Verificar resolución DNS
echo ""
echo -e "${YELLOW}🔍 Verificando resolución DNS...${NC}"
if ansible servidor -m shell -a "nslookup gamecenter.local localhost" &>/dev/null; then
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
    echo "   → Ver logs: ansible servidor -m shell -a 'tail -f /var/log/nginx/access.log' --become"
    echo "   → Reiniciar: ansible servidor -m systemd -a 'name=nginx state=restarted' --become"
    echo "   → Estado: ansible servidor -m systemd -a 'name=nginx' --become"
    echo ""
    exit 0
else
    echo -e "${RED}   ❌ VALIDACIÓN FALLIDA - $ERRORS ERROR(ES) ENCONTRADO(S)${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}💡 Soluciones sugeridas:${NC}"
    echo "   1. Reinstalar Nginx: bash scripts/run/run-web.sh"
    echo "   2. Ver logs de Nginx: ansible servidor -m shell -a 'journalctl -u nginx -n 50' --become"
    echo "   3. Verificar firewall: ansible servidor -m shell -a 'ufw status' --become"
    echo "   4. Probar configuración: ansible servidor -m shell -a 'nginx -t' --become"
    echo ""
    exit 1
fi
