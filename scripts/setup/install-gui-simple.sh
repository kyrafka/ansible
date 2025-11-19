#!/bin/bash
# Script para instalar interfaz gráfica en Ubuntu Server
# Ejecutar: sudo bash scripts/setup/install-gui-simple.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}         🖥️  INSTALACIÓN DE INTERFAZ GRÁFICA (XFCE)            ${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""

# Verificar root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Ejecuta con sudo${NC}"
    exit 1
fi

echo -e "${YELLOW}Se instalará XFCE (interfaz ligera)${NC}"
echo -e "${YELLOW}Esto tomará unos 10-15 minutos${NC}"
echo ""
read -p "¿Continuar? (s/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo -e "${RED}Cancelado${NC}"
    exit 0
fi

# 1. Actualizar sistema
echo -e "${BLUE}[1/4] Actualizando sistema...${NC}"
apt update > /dev/null 2>&1
echo -e "${GREEN}✅ Sistema actualizado${NC}"

# 2. Instalar XFCE
echo -e "${BLUE}[2/4] Instalando XFCE (esto toma tiempo)...${NC}"
DEBIAN_FRONTEND=noninteractive apt install -y xfce4 xfce4-goodies lightdm > /dev/null 2>&1
echo -e "${GREEN}✅ XFCE instalado${NC}"

# 3. Configurar LightDM
echo -e "${BLUE}[3/4] Configurando gestor de login...${NC}"
systemctl enable lightdm > /dev/null 2>&1
echo -e "${GREEN}✅ LightDM configurado${NC}"

# 4. Instalar herramientas útiles
echo -e "${BLUE}[4/4] Instalando herramientas adicionales...${NC}"
apt install -y firefox htop > /dev/null 2>&1
echo -e "${GREEN}✅ Herramientas instaladas${NC}"

# Resumen
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}         ✅ INTERFAZ GRÁFICA INSTALADA EXITOSAMENTE             ${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}📋 SIGUIENTE PASO:${NC}"
echo ""
echo "1. Reinicia el servidor:"
echo -e "   ${YELLOW}sudo reboot${NC}"
echo ""
echo "2. Después del reinicio verás una pantalla de login gráfica"
echo ""
echo "3. Login:"
echo "   Usuario: ubuntu"
echo "   Contraseña: 123"
echo ""
echo -e "${BLUE}🖥️  ACCESO:${NC}"
echo "   Accede desde la consola de ESXi"
echo "   Tendrás escritorio completo con Firefox y herramientas"
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
