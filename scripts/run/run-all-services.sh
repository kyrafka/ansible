#!/bin/bash
# Script para ejecutar todos los servicios en orden

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   🚀 CONFIGURACIÓN COMPLETA DE SERVICIOS${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}Se ejecutarán los siguientes servicios en orden:${NC}"
echo "   1. Red (Network)"
echo "   2. DHCP"
echo "   3. DNS"
echo "   4. Servidor Web (Nginx)"
echo "   5. Firewall + Fail2ban"
echo ""

read -p "¿Continuar? (s/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo -e "${RED}❌ Cancelado${NC}"
    exit 1
fi

# 1. Red
if [ -f "$SCRIPT_DIR/run-network.sh" ]; then
    echo ""
    echo -e "${BLUE}═══ 1/5: Configurando Red ═══${NC}"
    bash "$SCRIPT_DIR/run-network.sh" || { echo -e "${RED}❌ Error en red${NC}"; exit 1; }
else
    echo -e "${YELLOW}⚠️  Script run-network.sh no encontrado, saltando...${NC}"
fi

# 2. DHCP
if [ -f "$SCRIPT_DIR/run-dhcp.sh" ]; then
    echo ""
    echo -e "${BLUE}═══ 2/5: Configurando DHCP ═══${NC}"
    bash "$SCRIPT_DIR/run-dhcp.sh" || { echo -e "${RED}❌ Error en DHCP${NC}"; exit 1; }
else
    echo -e "${YELLOW}⚠️  Script run-dhcp.sh no encontrado, saltando...${NC}"
fi

# 3. DNS
if [ -f "$SCRIPT_DIR/run-dns.sh" ]; then
    echo ""
    echo -e "${BLUE}═══ 3/5: Configurando DNS ═══${NC}"
    bash "$SCRIPT_DIR/run-dns.sh" || { echo -e "${RED}❌ Error en DNS${NC}"; exit 1; }
else
    echo -e "${YELLOW}⚠️  Script run-dns.sh no encontrado, saltando...${NC}"
fi

# 4. Web
if [ -f "$SCRIPT_DIR/run-web.sh" ]; then
    echo ""
    echo -e "${BLUE}═══ 4/5: Configurando Servidor Web ═══${NC}"
    bash "$SCRIPT_DIR/run-web.sh" || { echo -e "${RED}❌ Error en Web${NC}"; exit 1; }
else
    echo -e "${YELLOW}⚠️  Script run-web.sh no encontrado, saltando...${NC}"
fi

# 5. Firewall
if [ -f "$SCRIPT_DIR/run-firewall.sh" ]; then
    echo ""
    echo -e "${BLUE}═══ 5/5: Configurando Firewall ═══${NC}"
    bash "$SCRIPT_DIR/run-firewall.sh" || { echo -e "${RED}❌ Error en Firewall${NC}"; exit 1; }
else
    echo -e "${YELLOW}⚠️  Script run-firewall.sh no encontrado, saltando...${NC}"
fi

# Resumen final
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}   ✅ TODOS LOS SERVICIOS CONFIGURADOS${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}🔍 Validar servicios:${NC}"
echo "   bash scripts/run/validate-network.sh"
echo "   bash scripts/run/validate-dhcp.sh"
echo "   bash scripts/run/validate-dns.sh"
echo "   bash scripts/run/validate-web.sh"
echo "   bash scripts/run/validate-firewall.sh"
echo ""
echo -e "${YELLOW}🌐 Acceso web:${NC}"
echo "   http://gamecenter.local"
echo "   http://www.gamecenter.local"
echo ""
