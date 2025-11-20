#!/bin/bash
# Diagnóstico de conectividad IPv6 e internet
# Ejecutar en el SERVIDOR: bash scripts/diagnostics/diagnose-connectivity.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

clear
echo ""
echo "════════════════════════════════════════════════════════"
echo "🔍 DIAGNÓSTICO DE CONECTIVIDAD"
echo "════════════════════════════════════════════════════════"
echo ""

PROBLEMS=0

# ═══════════════════════════════════════════════════════════
# 1. FORWARDING
# ═══════════════════════════════════════════════════════════
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1️⃣  IP FORWARDING"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

IPV4_FWD=$(cat /proc/sys/net/ipv4/ip_forward)
IPV6_FWD=$(cat /proc/sys/net/ipv6/conf/all/forwarding)

if [ "$IPV4_FWD" == "1" ]; then
    echo -e "${GREEN}✅ IPv4 forwarding: HABILITADO${NC}"
else
    echo -e "${RED}❌ IPv4 forwarding: DESHABILITADO${NC}"
    echo "   Solución: sudo sysctl -w net.ipv4.ip_forward=1"
    ((PROBLEMS++))
fi

if [ "$IPV6_FWD" == "1" ]; then
    echo -e "${GREEN}✅ IPv6 forwarding: HABILITADO${NC}"
else
    echo -e "${RED}❌ IPv6 forwarding: DESHABILITADO${NC}"
    echo "   Solución: sudo sysctl -w net.ipv6.conf.all.forwarding=1"
    ((PROBLEMS++))
fi
echo ""

# ═══════════════════════════════════════════════════════════
# 2. TAYGA (NAT64)
# ═══════════════════════════════════════════════════════════
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2️⃣  TAYGA (NAT64)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if systemctl is-active --quiet tayga; then
    echo -e "${GREEN}✅ TAYGA: ACTIVO${NC}"
    
    if ip link show nat64 &>/dev/null; then
        echo -e "${GREEN}✅ Interfaz nat64: EXISTE${NC}"
        STATE=$(ip link show nat64 | grep -o "state [A-Z]*" | awk '{print $2}')
        if [ "$STATE" == "UP" ] || [ "$STATE" == "UNKNOWN" ]; then
            echo -e "${GREEN}✅ Interfaz nat64: $STATE${NC}"
        else
            echo -e "${RED}❌ Interfaz nat64: $STATE (debe estar UP)${NC}"
            echo "   Solución: sudo ip link set nat64 up"
            ((PROBLEMS++))
        fi
    else
        echo -e "${RED}❌ Interfaz nat64: NO EXISTE${NC}"
        echo "   Solución: bash scripts/fix/fix-tayga-pidfile.sh"
        ((PROBLEMS++))
    fi
else
    echo -e "${RED}❌ TAYGA: INACTIVO${NC}"
    echo "   Solución: sudo systemctl start tayga"
    ((PROBLEMS++))
fi
echo ""

# ═══════════════════════════════════════════════════════════
# 3. RUTAS NAT64
# ═══════════════════════════════════════════════════════════
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3️⃣  RUTAS NAT64"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if ip -6 route | grep -q "64:ff9b::/96"; then
    echo -e "${GREEN}✅ Ruta IPv6 NAT64: EXISTE${NC}"
    ip -6 route | grep "64:ff9b::/96"
else
    echo -e "${RED}❌ Ruta IPv6 NAT64: NO EXISTE${NC}"
    echo "   Solución: sudo ip -6 route add 64:ff9b::/96 dev nat64"
    ((PROBLEMS++))
fi

if ip -4 route | grep -q "192.168.255.0/24"; then
    echo -e "${GREEN}✅ Ruta IPv4 NAT64: EXISTE${NC}"
    ip -4 route | grep "192.168.255.0/24"
else
    echo -e "${RED}❌ Ruta IPv4 NAT64: NO EXISTE${NC}"
    echo "   Solución: sudo ip -4 route add 192.168.255.0/24 dev nat64"
    ((PROBLEMS++))
fi
echo ""

# ═══════════════════════════════════════════════════════════
# 4. IPTABLES NAT
# ═══════════════════════════════════════════════════════════
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4️⃣  IPTABLES NAT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

WAN_IF=$(ip route | grep default | awk '{print $5}' | head -1)
echo "Interfaz WAN detectada: $WAN_IF"
echo ""

if sudo iptables -t nat -L POSTROUTING -n | grep -q "192.168.255.0/24"; then
    echo -e "${GREEN}✅ Regla NAT para TAYGA: EXISTE${NC}"
    sudo iptables -t nat -L POSTROUTING -n -v | grep "192.168.255"
else
    echo -e "${RED}❌ Regla NAT para TAYGA: NO EXISTE${NC}"
    echo "   Solución: sudo iptables -t nat -A POSTROUTING -s 192.168.255.0/24 -o $WAN_IF -j MASQUERADE"
    ((PROBLEMS++))
fi
echo ""

# ═══════════════════════════════════════════════════════════
# 5. PRUEBAS DE CONECTIVIDAD
# ═══════════════════════════════════════════════════════════
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5️⃣  PRUEBAS DE CONECTIVIDAD"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "→ Ping IPv6 puro (Google DNS):"
if ping6 -c 2 -W 2 2001:4860:4860::8888 &>/dev/null; then
    echo -e "${GREEN}✅ Conectividad IPv6 pura: FUNCIONA${NC}"
else
    echo -e "${YELLOW}⚠️  Conectividad IPv6 pura: NO FUNCIONA${NC}"
    echo "   (Normal si no tienes IPv6 nativo)"
fi

echo ""
echo "→ Ping NAT64 (8.8.8.8 vía 64:ff9b::):"
if ping6 -c 2 -W 2 64:ff9b::8.8.8.8 &>/dev/null; then
    echo -e "${GREEN}✅ NAT64: FUNCIONA${NC}"
else
    echo -e "${RED}❌ NAT64: NO FUNCIONA${NC}"
    echo "   Este es el problema principal"
    ((PROBLEMS++))
fi

echo ""
echo "→ Ping IPv4 desde el servidor:"
if ping -c 2 -W 2 8.8.8.8 &>/dev/null; then
    echo -e "${GREEN}✅ Conectividad IPv4 del servidor: FUNCIONA${NC}"
else
    echo -e "${RED}❌ Conectividad IPv4 del servidor: NO FUNCIONA${NC}"
    echo "   El servidor no tiene internet IPv4"
    ((PROBLEMS++))
fi
echo ""

# ═══════════════════════════════════════════════════════════
# RESUMEN Y SOLUCIONES
# ═══════════════════════════════════════════════════════════
echo "════════════════════════════════════════════════════════"
echo "📊 RESUMEN"
echo "════════════════════════════════════════════════════════"
echo ""

if [ $PROBLEMS -eq 0 ]; then
    echo -e "${GREEN}✅ TODO FUNCIONA CORRECTAMENTE${NC}"
    echo ""
    echo "Si los clientes aún no tienen internet, reinícialos."
else
    echo -e "${RED}❌ SE ENCONTRARON $PROBLEMS PROBLEMAS${NC}"
    echo ""
    echo "🔧 SOLUCIÓN RÁPIDA:"
    echo ""
    echo "Ejecuta este comando para arreglar todo:"
    echo ""
    echo -e "${BLUE}bash scripts/run/run-network.sh${NC}"
    echo ""
    echo "O manualmente:"
    echo ""
    
    if [ "$IPV4_FWD" != "1" ]; then
        echo "sudo sysctl -w net.ipv4.ip_forward=1"
    fi
    
    if [ "$IPV6_FWD" != "1" ]; then
        echo "sudo sysctl -w net.ipv6.conf.all.forwarding=1"
    fi
    
    if ! systemctl is-active --quiet tayga; then
        echo "sudo systemctl start tayga"
    fi
    
    if ! ip link show nat64 &>/dev/null; then
        echo "sudo ip link set nat64 up"
    fi
    
    if ! ip -6 route | grep -q "64:ff9b::/96"; then
        echo "sudo ip -6 route add 64:ff9b::/96 dev nat64"
    fi
    
    if ! ip -4 route | grep -q "192.168.255.0/24"; then
        echo "sudo ip -4 route add 192.168.255.0/24 dev nat64"
    fi
    
    if ! sudo iptables -t nat -L POSTROUTING -n | grep -q "192.168.255.0/24"; then
        echo "sudo iptables -t nat -A POSTROUTING -s 192.168.255.0/24 -o $WAN_IF -j MASQUERADE"
    fi
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo ""
