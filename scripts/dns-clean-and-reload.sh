#!/bin/bash
# Script para limpiar zona DNS y regenerarla sin registros estáticos de VMs

# Auto-permisos
[ ! -x "$0" ] && chmod +x "$0" 2>/dev/null

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   🧹 Limpiar y Regenerar Zona DNS (sin registros estáticos)  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -f "ansible.cfg" ]; then
    echo -e "${RED}Error: Ejecuta desde el directorio raíz del proyecto${NC}"
    exit 1
fi

echo -e "${YELLOW}📋 Zona DNS actual:${NC}"
echo ""
sudo cat /var/lib/bind/db.gamecenter.lan | grep "AAAA" | grep -v "^;"
echo ""

read -p "¿Regenerar zona DNS sin registros estáticos de VMs? [s/N]: " confirm
if [[ ! "$confirm" =~ ^[sS]$ ]]; then
    echo -e "${YELLOW}Cancelado${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}1️⃣  Eliminando zona dinámica antigua...${NC}"
sudo rm -f /var/lib/bind/db.gamecenter.lan
sudo rm -f /var/lib/bind/db.gamecenter.lan.jnl
echo -e "${GREEN}✓ Zona antigua eliminada${NC}"

echo ""
echo -e "${BLUE}2️⃣  Regenerando zona DNS...${NC}"
ansible-playbook playbooks/infrastructure/playbook-dns.yml --tags dns -v

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ Zona DNS regenerada${NC}"
else
    echo ""
    echo -e "${RED}✗ Error al regenerar zona DNS${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}3️⃣  Verificando nueva zona DNS...${NC}"
echo ""
sudo cat /var/lib/bind/db.gamecenter.lan | grep "AAAA" | grep -v "^;"
echo ""

echo -e "${BLUE}4️⃣  Recargando BIND9...${NC}"
sudo rndc reload
echo -e "${GREEN}✓ BIND9 recargado${NC}"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                  ✅ Zona DNS Limpia                           ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}📊 Registros estáticos (servidor):${NC}"
sudo grep "AAAA" /var/lib/bind/db.gamecenter.lan | grep -v "^;" | grep -E "(servidor|ns1|dns|dhcp|router)"
echo ""
echo -e "${YELLOW}🔄 Los clientes se registrarán automáticamente por DDNS${NC}"
echo ""
echo -e "${YELLOW}Para probar DDNS:${NC}"
echo "  1. Desde tu cliente: sudo dhclient -6 -r && sudo dhclient -6 -v"
echo "  2. Desde el servidor: sudo journalctl -u isc-dhcp-server -f"
echo "  3. Ver zona: sudo cat /var/lib/bind/db.gamecenter.lan"
echo ""
