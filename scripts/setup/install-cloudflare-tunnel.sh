#!/bin/bash
# Script para instalar Cloudflare Tunnel
# Permite acceder a Cockpit desde cualquier lugar sin VPN
# Ejecutar: sudo bash scripts/setup/install-cloudflare-tunnel.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}         🌐 INSTALACIÓN DE CLOUDFLARE TUNNEL                    ${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""

# Verificar root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Ejecuta con sudo${NC}"
    exit 1
fi

# 1. Descargar cloudflared
echo -e "${BLUE}[1/3] Descargando Cloudflare Tunnel...${NC}"
wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
echo -e "${GREEN}✅ Descargado${NC}"

# 2. Instalar
echo -e "${BLUE}[2/3] Instalando...${NC}"
dpkg -i cloudflared-linux-amd64.deb
rm cloudflared-linux-amd64.deb
echo -e "${GREEN}✅ Instalado${NC}"

# 3. Crear túnel rápido
echo -e "${BLUE}[3/3] Creando túnel...${NC}"
echo ""
echo -e "${YELLOW}════════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}IMPORTANTE: Copia la URL que aparecerá abajo${NC}"
echo -e "${YELLOW}════════════════════════════════════════════════════════════════${NC}"
echo ""

# Iniciar túnel a Cockpit
cloudflared tunnel --url http://localhost:9090

