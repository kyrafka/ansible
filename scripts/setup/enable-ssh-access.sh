#!/bin/bash
# Script para habilitar y configurar SSH en el servidor
# Ejecutar: sudo bash scripts/setup/enable-ssh-access.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}              🔐 CONFIGURACIÓN DE SSH                           ${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""

# Verificar que se ejecute como root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Este script debe ejecutarse con sudo${NC}"
    echo "Ejecuta: sudo bash $0"
    exit 1
fi

# ============================================================================
# 1. VERIFICAR ESTADO ACTUAL DE SSH
# ============================================================================
echo -e "${BLUE}═══ 1. Verificando estado actual de SSH ═══${NC}"
echo ""

if systemctl is-active --quiet ssh; then
    echo -e "${GREEN}✅ SSH ya está corriendo${NC}"
    SSH_RUNNING=true
else
    echo -e "${YELLOW}⚠️  SSH no está corriendo${NC}"
    SSH_RUNNING=false
fi

if systemctl is-enabled --quiet ssh; then
    echo -e "${GREEN}✅ SSH está habilitado al inicio${NC}"
else
    echo -e "${YELLOW}⚠️  SSH no está habilitado al inicio${NC}"
fi

echo ""

# ============================================================================
# 2. INSTALAR OPENSSH SERVER
# ============================================================================
echo -e "${BLUE}═══ 2. Instalando OpenSSH Server ═══${NC}"
echo ""

apt update
apt install -y openssh-server

echo -e "${GREEN}✅ OpenSSH Server instalado${NC}"
echo ""

# ============================================================================
# 3. CONFIGURAR SSH
# ============================================================================
echo -e "${BLUE}═══ 3. Configurando SSH ═══${NC}"
echo ""

# Backup de configuración original
if [ ! -f /etc/ssh/sshd_config.backup ]; then
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
    echo -e "${GREEN}✅ Backup de configuración creado${NC}"
fi

# Configurar SSH para permitir acceso con contraseña
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Permitir login de root (opcional, descomenta si lo necesitas)
# sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# Configurar puerto SSH (por defecto 22)
sed -i 's/#Port 22/Port 22/' /etc/ssh/sshd_config

echo -e "${GREEN}✅ SSH configurado${NC}"
echo ""

# ============================================================================
# 4. HABILITAR Y INICIAR SSH
# ============================================================================
echo -e "${BLUE}═══ 4. Habilitando SSH ═══${NC}"
echo ""

systemctl enable ssh
systemctl restart ssh

echo -e "${GREEN}✅ SSH habilitado e iniciado${NC}"
echo ""

# ============================================================================
# 5. CONFIGURAR FIREWALL
# ============================================================================
echo -e "${BLUE}═══ 5. Configurando firewall ═══${NC}"
echo ""

if command -v ufw &> /dev/null; then
    # Verificar si UFW está activo
    if ufw status | grep -q "Status: active"; then
        ufw allow 22/tcp comment 'SSH'
        echo -e "${GREEN}✅ Puerto 22 abierto en UFW${NC}"
    else
        echo -e "${YELLOW}⚠️  UFW no está activo${NC}"
        echo "   Para activarlo: sudo ufw enable"
    fi
else
    echo -e "${YELLOW}⚠️  UFW no está instalado${NC}"
fi

echo ""

# ============================================================================
# 6. OBTENER INFORMACIÓN DE CONEXIÓN
# ============================================================================
echo -e "${BLUE}═══ 6. Información de conexión ═══${NC}"
echo ""

# Obtener IPs
echo "Direcciones IP del servidor:"
ip -4 addr show | grep inet | grep -v 127.0.0.1 | awk '{print "  IPv4: " $2}'
ip -6 addr show | grep inet6 | grep -v "::1" | grep -v "fe80" | awk '{print "  IPv6: " $2}'

echo ""

# Obtener usuario actual
CURRENT_USER=$(logname 2>/dev/null || echo "ubuntu")
echo "Usuario: $CURRENT_USER"

echo ""

# ============================================================================
# 7. PROBAR SSH LOCALMENTE
# ============================================================================
echo -e "${BLUE}═══ 7. Probando SSH localmente ═══${NC}"
echo ""

if ss -tulpn | grep -q ":22.*sshd"; then
    echo -e "${GREEN}✅ SSH está escuchando en puerto 22${NC}"
else
    echo -e "${RED}❌ SSH NO está escuchando en puerto 22${NC}"
fi

echo ""

# ============================================================================
# RESUMEN FINAL
# ============================================================================
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}              ✅ SSH CONFIGURADO EXITOSAMENTE                   ${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${BLUE}📋 INFORMACIÓN DE CONEXIÓN:${NC}"
echo ""

# Obtener primera IP IPv4
SERVER_IP=$(hostname -I | awk '{print $1}')

echo "Desde tu PC, conéctate con:"
echo ""
echo -e "${YELLOW}  ssh $CURRENT_USER@$SERVER_IP${NC}"
echo ""
echo "Contraseña: (tu contraseña de usuario)"
echo ""

echo -e "${BLUE}🔐 TÚNEL SSH PARA COCKPIT:${NC}"
echo ""
echo "Para acceder a Cockpit desde tu PC:"
echo ""
echo -e "${YELLOW}  ssh -L 9090:localhost:9090 $CURRENT_USER@$SERVER_IP${NC}"
echo ""
echo "Luego abre tu navegador en:"
echo -e "${YELLOW}  http://localhost:9090${NC}"
echo ""

echo -e "${BLUE}🧪 PROBAR CONEXIÓN:${NC}"
echo ""
echo "Desde tu PC, ejecuta:"
echo -e "${YELLOW}  ping $SERVER_IP${NC}"
echo ""
echo "Si responde, intenta conectar por SSH"
echo ""

echo -e "${BLUE}🔧 COMANDOS ÚTILES:${NC}"
echo ""
echo "Ver estado de SSH:"
echo -e "${YELLOW}  sudo systemctl status ssh${NC}"
echo ""
echo "Ver logs de SSH:"
echo -e "${YELLOW}  sudo journalctl -u ssh -n 50${NC}"
echo ""
echo "Ver intentos de conexión:"
echo -e "${YELLOW}  sudo tail -f /var/log/auth.log${NC}"
echo ""

echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
