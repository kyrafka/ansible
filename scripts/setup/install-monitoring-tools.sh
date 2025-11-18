#!/bin/bash
# Script para instalar herramientas de monitoreo y gestión
# Ejecutar: bash scripts/setup/install-monitoring-tools.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}     🖥️  INSTALACIÓN DE HERRAMIENTAS DE MONITOREO Y GUI        ${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""

# Verificar que se ejecute como root o con sudo
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Este script debe ejecutarse con sudo${NC}"
    echo "Ejecuta: sudo bash $0"
    exit 1
fi

echo -e "${YELLOW}Se instalarán las siguientes herramientas:${NC}"
echo ""
echo "  📊 Interfaz Web:"
echo "     • Cockpit - Panel de administración web moderno"
echo "     • Cockpit-pcp - Métricas de rendimiento"
echo "     • Cockpit-networkmanager - Gestión de red"
echo ""
echo "  💻 Herramientas de Terminal:"
echo "     • htop - Monitor de procesos interactivo"
echo "     • btop - Monitor de sistema moderno"
echo "     • glances - Monitor todo-en-uno"
echo "     • nmon - Monitor de rendimiento"
echo "     • iotop - Monitor de I/O de disco"
echo "     • nethogs - Monitor de ancho de banda por proceso"
echo "     • ncdu - Analizador de uso de disco"
echo ""
read -p "¿Continuar con la instalación? (s/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo -e "${RED}Instalación cancelada${NC}"
    exit 0
fi

# ============================================================================
# 1. ACTUALIZAR SISTEMA
# ============================================================================
echo ""
echo -e "${BLUE}═══ 1. Actualizando sistema ═══${NC}"
apt update
echo -e "${GREEN}✅ Sistema actualizado${NC}"

# ============================================================================
# 2. INSTALAR COCKPIT (INTERFAZ WEB)
# ============================================================================
echo ""
echo -e "${BLUE}═══ 2. Instalando Cockpit (Interfaz Web) ═══${NC}"

apt install -y cockpit cockpit-pcp cockpit-networkmanager cockpit-storaged cockpit-packagekit

echo -e "${GREEN}✅ Cockpit instalado${NC}"

# Habilitar Cockpit
systemctl enable --now cockpit.socket
echo -e "${GREEN}✅ Cockpit habilitado${NC}"

# ============================================================================
# 3. INSTALAR HERRAMIENTAS DE TERMINAL
# ============================================================================
echo ""
echo -e "${BLUE}═══ 3. Instalando herramientas de terminal ═══${NC}"

# htop - Monitor de procesos
apt install -y htop
echo -e "${GREEN}✅ htop instalado${NC}"

# btop - Monitor moderno
apt install -y btop 2>/dev/null || {
    echo -e "${YELLOW}⚠️  btop no disponible en repositorios, instalando desde snap...${NC}"
    snap install btop 2>/dev/null || echo -e "${YELLOW}⚠️  btop no disponible${NC}"
}

# glances - Monitor todo-en-uno
apt install -y glances
echo -e "${GREEN}✅ glances instalado${NC}"

# nmon - Monitor de rendimiento
apt install -y nmon
echo -e "${GREEN}✅ nmon instalado${NC}"

# iotop - Monitor de I/O
apt install -y iotop
echo -e "${GREEN}✅ iotop instalado${NC}"

# nethogs - Monitor de red por proceso
apt install -y nethogs
echo -e "${GREEN}✅ nethogs instalado${NC}"

# ncdu - Analizador de disco
apt install -y ncdu
echo -e "${GREEN}✅ ncdu instalado${NC}"

# bmon - Monitor de ancho de banda
apt install -y bmon
echo -e "${GREEN}✅ bmon instalado${NC}"

# ============================================================================
# 4. CONFIGURAR FIREWALL
# ============================================================================
echo ""
echo -e "${BLUE}═══ 4. Configurando firewall ═══${NC}"

# Abrir puerto de Cockpit
if command -v ufw &> /dev/null; then
    ufw allow 9090/tcp comment 'Cockpit Web Interface'
    echo -e "${GREEN}✅ Puerto 9090 abierto en UFW${NC}"
else
    echo -e "${YELLOW}⚠️  UFW no instalado, puerto no configurado${NC}"
fi

# ============================================================================
# 5. CREAR SCRIPTS DE ACCESO RÁPIDO
# ============================================================================
echo ""
echo -e "${BLUE}═══ 5. Creando scripts de acceso rápido ═══${NC}"

# Script para htop
cat > /usr/local/bin/monitor << 'EOF'
#!/bin/bash
htop
EOF
chmod +x /usr/local/bin/monitor

# Script para glances
cat > /usr/local/bin/monitor-full << 'EOF'
#!/bin/bash
glances
EOF
chmod +x /usr/local/bin/monitor-full

# Script para btop
cat > /usr/local/bin/monitor-modern << 'EOF'
#!/bin/bash
if command -v btop &> /dev/null; then
    btop
else
    echo "btop no está instalado, usando htop..."
    htop
fi
EOF
chmod +x /usr/local/bin/monitor-modern

# Script para nethogs (requiere sudo)
cat > /usr/local/bin/monitor-network << 'EOF'
#!/bin/bash
if [ "$EUID" -ne 0 ]; then
    echo "Este comando requiere sudo"
    echo "Ejecuta: sudo monitor-network"
    exit 1
fi
nethogs
EOF
chmod +x /usr/local/bin/monitor-network

# Script para iotop (requiere sudo)
cat > /usr/local/bin/monitor-disk << 'EOF'
#!/bin/bash
if [ "$EUID" -ne 0 ]; then
    echo "Este comando requiere sudo"
    echo "Ejecuta: sudo monitor-disk"
    exit 1
fi
iotop
EOF
chmod +x /usr/local/bin/monitor-disk

# Script para ncdu
cat > /usr/local/bin/disk-usage << 'EOF'
#!/bin/bash
ncdu /
EOF
chmod +x /usr/local/bin/disk-usage

echo -e "${GREEN}✅ Scripts de acceso rápido creados${NC}"

# ============================================================================
# 6. OBTENER IP DEL SERVIDOR
# ============================================================================
echo ""
echo -e "${BLUE}═══ 6. Obteniendo información del servidor ═══${NC}"

# Obtener IP
SERVER_IP=$(hostname -I | awk '{print $1}')
echo -e "${GREEN}✅ IP del servidor: $SERVER_IP${NC}"

# ============================================================================
# RESUMEN FINAL
# ============================================================================
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}              ✅ INSTALACIÓN COMPLETADA EXITOSAMENTE            ${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${BLUE}📊 INTERFAZ WEB (Cockpit):${NC}"
echo ""
echo "   Accede desde tu navegador:"
echo -e "   ${YELLOW}https://$SERVER_IP:9090${NC}"
echo ""
echo "   Usuario: $(logname 2>/dev/null || echo "tu_usuario")"
echo "   Contraseña: tu contraseña de sudo"
echo ""

echo -e "${BLUE}💻 COMANDOS DE TERMINAL:${NC}"
echo ""
echo "   Monitoreo básico:"
echo -e "   ${YELLOW}monitor${NC}              - htop (procesos)"
echo -e "   ${YELLOW}monitor-full${NC}         - glances (todo-en-uno)"
echo -e "   ${YELLOW}monitor-modern${NC}       - btop (moderno)"
echo ""
echo "   Monitoreo específico:"
echo -e "   ${YELLOW}sudo monitor-network${NC} - nethogs (red por proceso)"
echo -e "   ${YELLOW}sudo monitor-disk${NC}    - iotop (I/O de disco)"
echo -e "   ${YELLOW}disk-usage${NC}           - ncdu (uso de disco)"
echo -e "   ${YELLOW}nmon${NC}                 - nmon (rendimiento)"
echo -e "   ${YELLOW}bmon${NC}                 - bmon (ancho de banda)"
echo ""

echo -e "${BLUE}🔧 COMANDOS ÚTILES:${NC}"
echo ""
echo "   Ver servicios:"
echo -e "   ${YELLOW}systemctl status cockpit${NC}"
echo ""
echo "   Reiniciar Cockpit:"
echo -e "   ${YELLOW}sudo systemctl restart cockpit${NC}"
echo ""
echo "   Ver logs de Cockpit:"
echo -e "   ${YELLOW}sudo journalctl -u cockpit${NC}"
echo ""

echo -e "${YELLOW}💡 CONSEJO:${NC}"
echo "   Accede a Cockpit desde tu navegador para una experiencia visual completa"
echo "   Usa los comandos de terminal cuando estés conectado por SSH"
echo ""

echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
