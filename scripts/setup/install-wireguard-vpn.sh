#!/bin/bash
# Script para instalar y configurar WireGuard VPN
# Ejecutar: sudo bash scripts/setup/install-wireguard-vpn.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}           🔐 INSTALACIÓN DE WIREGUARD VPN                      ${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""

# Verificar que se ejecute como root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Este script debe ejecutarse con sudo${NC}"
    echo "Ejecuta: sudo bash $0"
    exit 1
fi

# ============================================================================
# 1. INSTALAR WIREGUARD
# ============================================================================
echo -e "${BLUE}═══ 1. Instalando WireGuard ═══${NC}"
echo ""

apt update
apt install -y wireguard wireguard-tools qrencode

echo -e "${GREEN}✅ WireGuard instalado${NC}"
echo ""

# ============================================================================
# 2. GENERAR CLAVES DEL SERVIDOR
# ============================================================================
echo -e "${BLUE}═══ 2. Generando claves del servidor ═══${NC}"
echo ""

# Verificar que el directorio existe
if [ ! -d "/etc/wireguard" ]; then
    echo -e "${YELLOW}Creando directorio /etc/wireguard...${NC}"
    mkdir -p /etc/wireguard
    chmod 700 /etc/wireguard
fi

cd /etc/wireguard

# Verificar que tenemos permisos
if [ ! -w "/etc/wireguard" ]; then
    echo -e "${RED}❌ No hay permisos de escritura en /etc/wireguard${NC}"
    exit 1
fi

# Generar clave privada del servidor
echo "Generando clave privada del servidor..."
wg genkey | tee server_private.key | wg pubkey | tee server_public.key > /dev/null

# Permisos seguros
chmod 600 server_private.key server_public.key

# Verificar que se crearon
if [ ! -f "server_private.key" ] || [ ! -f "server_public.key" ]; then
    echo -e "${RED}❌ Error al generar claves del servidor${NC}"
    exit 1
fi

SERVER_PRIVATE_KEY=$(cat server_private.key)
SERVER_PUBLIC_KEY=$(cat server_public.key)

echo -e "${GREEN}✅ Claves del servidor generadas${NC}"
echo "   Clave pública: $SERVER_PUBLIC_KEY"
echo ""

# ============================================================================
# 3. GENERAR CLAVES DEL CLIENTE
# ============================================================================
echo -e "${BLUE}═══ 3. Generando claves del cliente ═══${NC}"
echo ""

# Generar clave privada del cliente
wg genkey | tee client_private.key | wg pubkey > client_public.key

CLIENT_PRIVATE_KEY=$(cat client_private.key)
CLIENT_PUBLIC_KEY=$(cat client_public.key)

echo -e "${GREEN}✅ Claves del cliente generadas${NC}"
echo ""

# ============================================================================
# 4. OBTENER IP DEL SERVIDOR
# ============================================================================
echo -e "${BLUE}═══ 4. Obteniendo IP del servidor ═══${NC}"
echo ""

SERVER_IP=$(hostname -I | awk '{print $1}')
echo "IP del servidor: $SERVER_IP"
echo ""

# ============================================================================
# 5. CONFIGURAR SERVIDOR WIREGUARD
# ============================================================================
echo -e "${BLUE}═══ 5. Configurando servidor WireGuard ═══${NC}"
echo ""

cat > /etc/wireguard/wg0.conf << EOF
[Interface]
Address = 10.8.0.1/24
ListenPort = 51820
PrivateKey = $SERVER_PRIVATE_KEY

# Habilitar IP forwarding
PostUp = sysctl -w net.ipv4.ip_forward=1
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT
PostUp = iptables -t nat -A POSTROUTING -o ens33 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT
PostDown = iptables -t nat -D POSTROUTING -o ens33 -j MASQUERADE

# Cliente
[Peer]
PublicKey = $CLIENT_PUBLIC_KEY
AllowedIPs = 10.8.0.2/32
EOF

chmod 600 /etc/wireguard/wg0.conf

echo -e "${GREEN}✅ Servidor WireGuard configurado${NC}"
echo ""

# ============================================================================
# 6. HABILITAR IP FORWARDING
# ============================================================================
echo -e "${BLUE}═══ 6. Habilitando IP forwarding ═══${NC}"
echo ""

# Habilitar permanentemente
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

echo -e "${GREEN}✅ IP forwarding habilitado${NC}"
echo ""

# ============================================================================
# 7. CONFIGURAR FIREWALL
# ============================================================================
echo -e "${BLUE}═══ 7. Configurando firewall ═══${NC}"
echo ""

if command -v ufw &> /dev/null; then
    ufw allow 51820/udp comment 'WireGuard VPN'
    echo -e "${GREEN}✅ Puerto 51820/UDP abierto en UFW${NC}"
else
    echo -e "${YELLOW}⚠️  UFW no instalado${NC}"
fi

echo ""

# ============================================================================
# 8. INICIAR WIREGUARD
# ============================================================================
echo -e "${BLUE}═══ 8. Iniciando WireGuard ═══${NC}"
echo ""

systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0

echo -e "${GREEN}✅ WireGuard iniciado${NC}"
echo ""

# ============================================================================
# 9. CREAR CONFIGURACIÓN DEL CLIENTE
# ============================================================================
echo -e "${BLUE}═══ 9. Creando configuración del cliente ═══${NC}"
echo ""

cat > /etc/wireguard/client.conf << EOF
[Interface]
PrivateKey = $CLIENT_PRIVATE_KEY
Address = 10.8.0.2/24
DNS = 8.8.8.8

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = $SERVER_IP:51820
AllowedIPs = 10.8.0.0/24, 172.17.0.0/16, 2025:db8:10::/64
PersistentKeepalive = 25
EOF

echo -e "${GREEN}✅ Configuración del cliente creada${NC}"
echo ""

# ============================================================================
# 10. GENERAR QR CODE
# ============================================================================
echo -e "${BLUE}═══ 10. Generando código QR para móvil ═══${NC}"
echo ""

qrencode -t ansiutf8 < /etc/wireguard/client.conf

echo ""
echo -e "${GREEN}✅ Código QR generado (escanea con la app de WireGuard)${NC}"
echo ""

# ============================================================================
# RESUMEN FINAL
# ============================================================================
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}           ✅ WIREGUARD VPN INSTALADO EXITOSAMENTE              ${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${BLUE}📋 INFORMACIÓN DE LA VPN:${NC}"
echo ""
echo "  Servidor VPN: $SERVER_IP:51820"
echo "  Red VPN: 10.8.0.0/24"
echo "  IP del servidor en VPN: 10.8.0.1"
echo "  IP del cliente en VPN: 10.8.0.2"
echo ""

echo -e "${BLUE}📱 CONFIGURAR CLIENTE EN TU PC:${NC}"
echo ""
echo "1. Descargar WireGuard:"
echo "   Windows: https://www.wireguard.com/install/"
echo "   macOS: https://apps.apple.com/app/wireguard/id1451685025"
echo "   Linux: sudo apt install wireguard"
echo ""

echo "2. Copiar configuración del cliente:"
echo -e "${YELLOW}   cat /etc/wireguard/client.conf${NC}"
echo ""

echo "3. En tu PC, crear un túnel con esa configuración"
echo ""

echo -e "${BLUE}📱 PARA MÓVIL:${NC}"
echo ""
echo "1. Instalar app WireGuard desde Play Store o App Store"
echo "2. Escanear el código QR mostrado arriba"
echo ""

echo -e "${BLUE}🔧 COMANDOS ÚTILES:${NC}"
echo ""
echo "Ver estado de WireGuard:"
echo -e "${YELLOW}  sudo wg show${NC}"
echo ""
echo "Ver configuración del cliente:"
echo -e "${YELLOW}  cat /etc/wireguard/client.conf${NC}"
echo ""
echo "Reiniciar WireGuard:"
echo -e "${YELLOW}  sudo systemctl restart wg-quick@wg0${NC}"
echo ""
echo "Ver logs:"
echo -e "${YELLOW}  sudo journalctl -u wg-quick@wg0 -f${NC}"
echo ""

echo -e "${BLUE}🌐 DESPUÉS DE CONECTAR LA VPN:${NC}"
echo ""
echo "Podrás acceder a:"
echo "  • SSH: ssh ubuntu@10.8.0.1"
echo "  • Cockpit: http://10.8.0.1:9090"
echo "  • Servidor: ping 10.8.0.1"
echo ""

echo -e "${YELLOW}💡 SIGUIENTE PASO:${NC}"
echo ""
echo "Ejecuta este comando para ver la configuración del cliente:"
echo -e "${YELLOW}  sudo cat /etc/wireguard/client.conf${NC}"
echo ""
echo "Copia esa configuración y úsala en tu cliente WireGuard"
echo ""

echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
