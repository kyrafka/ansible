#!/bin/bash
# Script simple para configurar WireGuard VPN
# Ejecutar: sudo bash scripts/setup/setup-wireguard-simple.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}           🔐 CONFIGURACIÓN SIMPLE DE WIREGUARD VPN             ${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""

# Verificar root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Ejecuta con sudo${NC}"
    exit 1
fi

# 1. Instalar WireGuard
echo -e "${BLUE}[1/8] Instalando WireGuard...${NC}"
apt update > /dev/null 2>&1
apt install -y wireguard wireguard-tools qrencode > /dev/null 2>&1
echo -e "${GREEN}✅ Instalado${NC}"

# 2. Crear directorio
echo -e "${BLUE}[2/8] Creando directorio...${NC}"
mkdir -p /etc/wireguard
chmod 700 /etc/wireguard
echo -e "${GREEN}✅ Directorio listo${NC}"

# 3. Generar claves del servidor
echo -e "${BLUE}[3/8] Generando claves del servidor...${NC}"
cd /etc/wireguard
wg genkey > server_private.key
cat server_private.key | wg pubkey > server_public.key
chmod 600 server_private.key server_public.key
SERVER_PRIVATE=$(cat server_private.key)
SERVER_PUBLIC=$(cat server_public.key)
echo -e "${GREEN}✅ Claves del servidor generadas${NC}"

# 4. Generar claves del cliente
echo -e "${BLUE}[4/8] Generando claves del cliente...${NC}"
wg genkey > client_private.key
cat client_private.key | wg pubkey > client_public.key
chmod 600 client_private.key client_public.key
CLIENT_PRIVATE=$(cat client_private.key)
CLIENT_PUBLIC=$(cat client_public.key)
echo -e "${GREEN}✅ Claves del cliente generadas${NC}"

# 5. Obtener IP del servidor
echo -e "${BLUE}[5/8] Obteniendo IP del servidor...${NC}"
SERVER_IP=$(hostname -I | awk '{print $1}')
echo -e "${GREEN}✅ IP: $SERVER_IP${NC}"

# 6. Crear configuración del servidor
echo -e "${BLUE}[6/8] Creando configuración del servidor...${NC}"
cat > /etc/wireguard/wg0.conf << EOF
[Interface]
Address = 10.8.0.1/24
ListenPort = 51820
PrivateKey = $SERVER_PRIVATE

PostUp = sysctl -w net.ipv4.ip_forward=1
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT
PostUp = iptables -t nat -A POSTROUTING -o ens33 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT
PostDown = iptables -t nat -D POSTROUTING -o ens33 -j MASQUERADE

[Peer]
PublicKey = $CLIENT_PUBLIC
AllowedIPs = 10.8.0.2/32
EOF
chmod 600 /etc/wireguard/wg0.conf
echo -e "${GREEN}✅ Configuración del servidor creada${NC}"

# 7. Crear configuración del cliente
echo -e "${BLUE}[7/8] Creando configuración del cliente...${NC}"
cat > /etc/wireguard/client.conf << EOF
[Interface]
PrivateKey = $CLIENT_PRIVATE
Address = 10.8.0.2/24
DNS = 8.8.8.8

[Peer]
PublicKey = $SERVER_PUBLIC
Endpoint = $SERVER_IP:51820
AllowedIPs = 10.8.0.0/24, 172.17.0.0/16, 2025:db8:10::/64
PersistentKeepalive = 25
EOF
chmod 600 /etc/wireguard/client.conf
echo -e "${GREEN}✅ Configuración del cliente creada${NC}"

# 8. Habilitar IP forwarding
echo -e "${BLUE}[8/8] Habilitando IP forwarding...${NC}"
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p > /dev/null 2>&1
echo -e "${GREEN}✅ IP forwarding habilitado${NC}"

# 9. Abrir firewall
echo -e "${BLUE}[9/9] Configurando firewall...${NC}"
if command -v ufw &> /dev/null; then
    ufw allow 51820/udp > /dev/null 2>&1
    echo -e "${GREEN}✅ Puerto 51820/UDP abierto${NC}"
fi

# 10. Iniciar WireGuard
echo -e "${BLUE}[10/10] Iniciando WireGuard...${NC}"
systemctl enable wg-quick@wg0 > /dev/null 2>&1
systemctl start wg-quick@wg0
sleep 2

# Verificar estado
if systemctl is-active --quiet wg-quick@wg0; then
    echo -e "${GREEN}✅ WireGuard está corriendo${NC}"
else
    echo -e "${RED}❌ WireGuard falló al iniciar${NC}"
    echo "Ver error: sudo journalctl -u wg-quick@wg0 -n 20"
fi

# Resumen
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}              ✅ WIREGUARD CONFIGURADO EXITOSAMENTE             ${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}📋 INFORMACIÓN:${NC}"
echo "  Servidor VPN: $SERVER_IP:51820"
echo "  Red VPN: 10.8.0.0/24"
echo "  IP servidor en VPN: 10.8.0.1"
echo "  IP cliente en VPN: 10.8.0.2"
echo ""
echo -e "${BLUE}📱 CONFIGURACIÓN DEL CLIENTE:${NC}"
echo ""
cat /etc/wireguard/client.conf
echo ""
echo -e "${BLUE}📱 CÓDIGO QR (para móvil):${NC}"
echo ""
qrencode -t ansiutf8 < /etc/wireguard/client.conf
echo ""
echo -e "${YELLOW}💾 Guarda esta configuración en un archivo .conf${NC}"
echo -e "${YELLOW}   y úsala en tu cliente WireGuard${NC}"
echo ""
echo -e "${BLUE}🔧 COMANDOS ÚTILES:${NC}"
echo "  Ver estado: sudo wg show"
echo "  Ver logs: sudo journalctl -u wg-quick@wg0 -f"
echo "  Reiniciar: sudo systemctl restart wg-quick@wg0"
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
