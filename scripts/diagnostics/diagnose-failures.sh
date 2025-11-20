#!/bin/bash
# Diagnóstico de servicios fallidos
# Ejecutar: bash scripts/diagnostics/diagnose-failures.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

clear
echo ""
echo "════════════════════════════════════════════════════════"
echo "🔍 DIAGNÓSTICO DE SERVICIOS FALLIDOS"
echo "════════════════════════════════════════════════════════"
echo ""

# ═══════════════════════════════════════════════════════════
# 1. BIND9/named
# ═══════════════════════════════════════════════════════════
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1️⃣  BIND9 / named"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if systemctl is-active --quiet bind9 || systemctl is-active --quiet named; then
    echo -e "${GREEN}✅ Servicio activo${NC}"
else
    echo -e "${RED}❌ Servicio INACTIVO${NC}"
    echo ""
    echo "📋 Últimos 30 logs:"
    sudo journalctl -u bind9 -u named -n 30 --no-pager 2>/dev/null
    echo ""
    echo "🔍 Verificando configuración:"
    sudo named-checkconf 2>&1 || echo "Error en named.conf"
    echo ""
    echo "🔍 Verificando zona:"
    DOMAIN=$(grep -r "domain_name:" group_vars/all.yml 2>/dev/null | grep -v "^#" | awk '{print $2}' | tr -d '"' | head -n1)
    if [ -z "$DOMAIN" ]; then
        DOMAIN="gamecenter.lan"
    fi
    
    for ZONE_FILE in "/var/lib/bind/db.$DOMAIN" "/etc/bind/zones/db.$DOMAIN"; do
        if [ -f "$ZONE_FILE" ]; then
            echo "Verificando: $ZONE_FILE"
            sudo named-checkzone "$DOMAIN" "$ZONE_FILE" 2>&1 || echo "Error en zona"
            break
        fi
    done
fi
echo ""

# ═══════════════════════════════════════════════════════════
# 2. TAYGA (NAT64)
# ═══════════════════════════════════════════════════════════
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2️⃣  TAYGA (NAT64)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if systemctl is-active --quiet tayga; then
    echo -e "${GREEN}✅ Servicio activo${NC}"
else
    echo -e "${RED}❌ Servicio INACTIVO${NC}"
    echo ""
    echo "📋 Últimos 30 logs:"
    sudo journalctl -u tayga -n 30 --no-pager 2>/dev/null
    echo ""
    echo "🔍 Verificando configuración:"
    if [ -f "/etc/tayga.conf" ]; then
        echo "Archivo /etc/tayga.conf existe"
        cat /etc/tayga.conf
    else
        echo "❌ /etc/tayga.conf NO existe"
    fi
    echo ""
    echo "🔍 Verificando interfaz nat64:"
    ip link show nat64 2>/dev/null || echo "❌ Interfaz nat64 no existe"
    echo ""
    echo "🔍 Verificando directorio de trabajo:"
    ls -la /var/db/tayga/ 2>/dev/null || echo "❌ /var/db/tayga/ no existe"
fi
echo ""

# ═══════════════════════════════════════════════════════════
# 3. RADVD (Router Advertisement)
# ═══════════════════════════════════════════════════════════
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3️⃣  RADVD (Router Advertisement)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if systemctl is-active --quiet radvd; then
    echo -e "${GREEN}✅ Servicio activo${NC}"
else
    echo -e "${RED}❌ Servicio INACTIVO${NC}"
    echo ""
    echo "📋 Últimos 20 logs:"
    sudo journalctl -u radvd -n 20 --no-pager 2>/dev/null
    echo ""
    echo "🔍 Verificando configuración:"
    if [ -f "/etc/radvd.conf" ]; then
        echo "Archivo /etc/radvd.conf existe"
        cat /etc/radvd.conf
    else
        echo "❌ /etc/radvd.conf NO existe"
    fi
fi
echo ""

# ═══════════════════════════════════════════════════════════
# 4. RED IPv6
# ═══════════════════════════════════════════════════════════
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4️⃣  CONFIGURACIÓN DE RED IPv6"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "→ Forwarding IPv6:"
IPV6_FWD=$(cat /proc/sys/net/ipv6/conf/all/forwarding)
if [ "$IPV6_FWD" == "1" ]; then
    echo -e "  ${GREEN}✅ Habilitado${NC}"
else
    echo -e "  ${RED}❌ Deshabilitado${NC}"
fi

echo ""
echo "→ Interfaces de red:"
ip -6 addr show | grep -E "^[0-9]+:|inet6"
echo ""

echo "→ Rutas IPv6:"
ip -6 route | head -10
echo ""

echo "→ Netplan configuración:"
if [ -d "/etc/netplan" ]; then
    ls -la /etc/netplan/
    echo ""
    for file in /etc/netplan/*.yaml; do
        if [ -f "$file" ]; then
            echo "Contenido de $file:"
            cat "$file"
            echo ""
        fi
    done
else
    echo "❌ /etc/netplan no existe"
fi

# ═══════════════════════════════════════════════════════════
# RESUMEN
# ═══════════════════════════════════════════════════════════
echo "════════════════════════════════════════════════════════"
echo "📊 RESUMEN DE PROBLEMAS"
echo "════════════════════════════════════════════════════════"
echo ""

ISSUES=0

if ! systemctl is-active --quiet bind9 && ! systemctl is-active --quiet named; then
    echo -e "${RED}❌ BIND9 no está activo${NC}"
    echo "   Solución: bash scripts/run/run-dns.sh"
    ((ISSUES++))
fi

if ! systemctl is-active --quiet tayga; then
    echo -e "${RED}❌ TAYGA no está activo${NC}"
    echo "   Solución: bash scripts/run/run-network.sh"
    ((ISSUES++))
fi

if ! systemctl is-active --quiet radvd; then
    echo -e "${RED}❌ RADVD no está activo${NC}"
    echo "   Solución: bash scripts/run/run-network.sh"
    ((ISSUES++))
fi

if [ "$IPV6_FWD" != "1" ]; then
    echo -e "${RED}❌ IPv6 forwarding deshabilitado${NC}"
    echo "   Solución: sudo sysctl -w net.ipv6.conf.all.forwarding=1"
    ((ISSUES++))
fi

if [ $ISSUES -eq 0 ]; then
    echo -e "${GREEN}✅ No se detectaron problemas${NC}"
else
    echo ""
    echo -e "${YELLOW}Total de problemas: $ISSUES${NC}"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo ""
