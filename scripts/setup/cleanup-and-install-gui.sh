#!/bin/bash
# Script para limpiar WireGuard/Cockpit y luego instalar GUI
# Ejecutar: sudo bash scripts/setup/cleanup-and-install-gui.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}         🧹 LIMPIEZA Y INSTALACIÓN DE GUI                       ${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""

# Verificar root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Ejecuta con sudo${NC}"
    exit 1
fi

# ============================================================================
# PARTE 1: LIMPIEZA
# ============================================================================
echo -e "${BLUE}═══ PARTE 1: LIMPIANDO INSTALACIONES ANTERIORES ═══${NC}"
echo ""

# 1. Desinstalar WireGuard
echo -e "${BLUE}[1/5] Desinstalando WireGuard...${NC}"
systemctl stop wg-quick@wg0 2>/dev/null || true
systemctl disable wg-quick@wg0 2>/dev/null || true
apt remove --purge -y wireguard wireguard-tools qrencode 2>/dev/null || true
rm -rf /etc/wireguard
echo -e "${GREEN}✅ WireGuard eliminado${NC}"

# 2. Desinstalar Cockpit
echo -e "${BLUE}[2/5] Desinstalando Cockpit...${NC}"
systemctl stop cockpit 2>/dev/null || true
systemctl disable cockpit.socket 2>/dev/null || true
apt remove --purge -y cockpit cockpit-* 2>/dev/null || true
echo -e "${GREEN}✅ Cockpit eliminado${NC}"

# 3. Desinstalar Cloudflared
echo -e "${BLUE}[3/5] Desinstalando Cloudflare Tunnel...${NC}"
pkill cloudflared 2>/dev/null || true
apt remove --purge -y cloudflared 2>/dev/null || true
rm -f /usr/local/bin/cloudflared
echo -e "${GREEN}✅ Cloudflare Tunnel eliminado${NC}"

# 4. Limpiar paquetes rotos
echo -e "${BLUE}[4/5] Limpiando paquetes rotos...${NC}"
apt --fix-broken install -y 2>/dev/null || true
apt autoremove -y 2>/dev/null || true
apt autoclean 2>/dev/null || true
echo -e "${GREEN}✅ Sistema limpio${NC}"

# 5. Cerrar puertos en firewall
echo -e "${BLUE}[5/5] Limpiando reglas de firewall...${NC}"
if command -v ufw &> /dev/null; then
    ufw delete allow 51820/udp 2>/dev/null || true
    ufw delete allow 9090/tcp 2>/dev/null || true
fi
echo -e "${GREEN}✅ Firewall limpio${NC}"

echo ""
echo -e "${GREEN}✅ LIMPIEZA COMPLETADA${NC}"
echo ""

# ============================================================================
# PARTE 2: INSTALACIÓN DE GUI
# ============================================================================
echo -e "${BLUE}═══ PARTE 2: INSTALANDO INTERFAZ GRÁFICA ═══${NC}"
echo ""

echo -e "${YELLOW}Se instalará XFCE (interfaz ligera)${NC}"
echo -e "${YELLOW}Esto tomará unos 10-15 minutos${NC}"
echo ""
read -p "¿Continuar con la instalación de GUI? (s/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo -e "${YELLOW}Instalación de GUI cancelada${NC}"
    echo -e "${GREEN}Limpieza completada exitosamente${NC}"
    exit 0
fi

# 1. Actualizar sistema
echo -e "${BLUE}[1/4] Actualizando sistema...${NC}"
apt update > /dev/null 2>&1
echo -e "${GREEN}✅ Sistema actualizado${NC}"

# 2. Instalar XFCE
echo -e "${BLUE}[2/4] Instalando XFCE (esto toma tiempo, espera...)${NC}"
DEBIAN_FRONTEND=noninteractive apt install -y xfce4 xfce4-goodies lightdm 2>&1 | grep -v "pcp\|pmlogger" || true
echo -e "${GREEN}✅ XFCE instalado${NC}"

# 3. Configurar LightDM
echo -e "${BLUE}[3/4] Configurando gestor de login...${NC}"
systemctl enable lightdm > /dev/null 2>&1
echo -e "${GREEN}✅ LightDM configurado${NC}"

# 4. Instalar herramientas útiles
echo -e "${BLUE}[4/4] Instalando herramientas adicionales...${NC}"
apt install -y firefox htop 2>&1 | grep -v "pcp\|pmlogger" || true
echo -e "${GREEN}✅ Herramientas instaladas${NC}"

# ============================================================================
# RESUMEN FINAL
# ============================================================================
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}         ✅ INSTALACIÓN COMPLETADA EXITOSAMENTE                 ${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${BLUE}📋 LO QUE SE ELIMINÓ:${NC}"
echo "  ❌ WireGuard VPN"
echo "  ❌ Cockpit"
echo "  ❌ Cloudflare Tunnel"
echo "  ❌ Paquetes rotos (pcp, cockpit-pcp)"
echo ""

echo -e "${BLUE}📋 LO QUE SE INSTALÓ:${NC}"
echo "  ✅ XFCE Desktop (interfaz gráfica ligera)"
echo "  ✅ LightDM (gestor de login)"
echo "  ✅ Firefox (navegador)"
echo "  ✅ htop (monitor de sistema)"
echo ""

echo -e "${BLUE}🚀 SIGUIENTE PASO:${NC}"
echo ""
echo "1. Reinicia el servidor:"
echo -e "   ${YELLOW}sudo reboot${NC}"
echo ""
echo "2. Después del reinicio verás una pantalla de login gráfica"
echo ""
echo "3. Login desde la consola de ESXi:"
echo "   Usuario: ubuntu"
echo "   Contraseña: 123"
echo ""
echo "4. Tendrás escritorio completo con:"
echo "   • Firefox para navegar"
echo "   • Terminal"
echo "   • Gestor de archivos"
echo "   • Todas las herramientas de monitoreo"
echo ""

echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
