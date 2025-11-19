#!/bin/bash
# Verificación en tiempo real del estado de DNS
# Ejecutar: bash scripts/diagnostics/check-dns-now.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

clear
echo ""
echo "════════════════════════════════════════════════════════"
echo "🔍 VERIFICACIÓN EN TIEMPO REAL - DNS"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Fecha: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# ═══════════════════════════════════════════════════════════
# 1. SERVICIO BIND9
# ═══════════════════════════════════════════════════════════
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1️⃣  SERVICIO BIND9"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if systemctl is-active --quiet bind9; then
    echo -e "${GREEN}✅ BIND9 está ACTIVO${NC}"
    UPTIME=$(systemctl show bind9 --property=ActiveEnterTimestamp --value)
    echo "   Iniciado: $UPTIME"
elif systemctl is-active --quiet named; then
    echo -e "${GREEN}✅ named está ACTIVO${NC}"
    UPTIME=$(systemctl show named --property=ActiveEnterTimestamp --value)
    echo "   Iniciado: $UPTIME"
else
    echo -e "${RED}❌ BIND9/named NO está activo${NC}"
    echo ""
    echo "Estado del servicio:"
    systemctl status bind9 --no-pager -l 2>/dev/null || systemctl status named --no-pager -l 2>/dev/null
fi
echo ""

# ═══════════════════════════════════════════════════════════
# 2. PUERTO 53
# ═══════════════════════════════════════════════════════════
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2️⃣  PUERTO 53"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

PORT_CHECK=$(sudo ss -tulpn 2>/dev/null | grep ":53 ")

if [ -n "$PORT_CHECK" ]; then
    if echo "$PORT_CHECK" | grep -q "named"; then
        echo -e "${GREEN}✅ BIND9 está escuchando en puerto 53${NC}"
        echo ""
        echo "Detalles:"
        sudo ss -tulpn 2>/dev/null | grep ":53.*named" | head -5
        echo ""
        SOCKET_COUNT=$(sudo ss -tulpn 2>/dev/null | grep ":53.*named" | wc -l)
        echo "Total de sockets: $SOCKET_COUNT"
    else
        echo -e "${RED}❌ Otro proceso está usando el puerto 53${NC}"
        echo ""
        echo "$PORT_CHECK"
    fi
else
    echo -e "${RED}❌ Nadie está escuchando en puerto 53${NC}"
fi
echo ""

# ═══════════════════════════════════════════════════════════
# 3. ARCHIVOS DE CONFIGURACIÓN
# ═══════════════════════════════════════════════════════════
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3️⃣  ARCHIVOS DE CONFIGURACIÓN"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Detectar dominio
DOMAIN=$(grep -r "domain_name:" group_vars/all.yml 2>/dev/null | grep -v "^#" | awk '{print $2}' | tr -d '"' | head -n1)
if [ -z "$DOMAIN" ]; then
    DOMAIN="gamecenter.lan"
fi
echo "Dominio: $DOMAIN"
echo ""

# Verificar named.conf
echo "→ named.conf:"
if sudo named-checkconf 2>/dev/null; then
    echo -e "  ${GREEN}✅ Sintaxis correcta${NC}"
else
    echo -e "  ${RED}❌ Errores de sintaxis${NC}"
    sudo named-checkconf
fi
echo ""

# Buscar archivo de zona
ZONE_FILE=""
if [ -f "/var/lib/bind/db.$DOMAIN" ]; then
    ZONE_FILE="/var/lib/bind/db.$DOMAIN"
elif [ -f "/etc/bind/zones/db.$DOMAIN" ]; then
    ZONE_FILE="/etc/bind/zones/db.$DOMAIN"
fi

if [ -n "$ZONE_FILE" ]; then
    echo "→ Archivo de zona: $ZONE_FILE"
    if sudo named-checkzone "$DOMAIN" "$ZONE_FILE" &>/dev/null; then
        echo -e "  ${GREEN}✅ Zona válida${NC}"
    else
        echo -e "  ${RED}❌ Zona con errores${NC}"
        sudo named-checkzone "$DOMAIN" "$ZONE_FILE"
    fi
else
    echo -e "${RED}❌ No se encontró archivo de zona para $DOMAIN${NC}"
fi
echo ""

# ═══════════════════════════════════════════════════════════
# 4. PRUEBAS DE RESOLUCIÓN
# ═══════════════════════════════════════════════════════════
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4️⃣  PRUEBAS DE RESOLUCIÓN DNS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Probar dominio principal
echo "→ Probando: $DOMAIN"
RESULT=$(dig @localhost "$DOMAIN" AAAA +short 2>/dev/null | head -1)
if [ -n "$RESULT" ]; then
    echo -e "  ${GREEN}✅ Resuelve: $RESULT${NC}"
else
    echo -e "  ${RED}❌ NO resuelve${NC}"
fi
echo ""

# Probar subdominios
for SUB in dns web www servidor; do
    echo "→ Probando: $SUB.$DOMAIN"
    RESULT=$(dig @localhost "$SUB.$DOMAIN" AAAA +short 2>/dev/null | head -1)
    if [ -n "$RESULT" ]; then
        echo -e "  ${GREEN}✅ Resuelve: $RESULT${NC}"
    else
        echo -e "  ${YELLOW}⚠️  NO resuelve (puede no estar configurado)${NC}"
    fi
done
echo ""

# Probar DNS64
echo "→ Probando DNS64 (google.com):"
RESULT=$(dig @localhost google.com AAAA +short 2>/dev/null | grep "64:ff9b" | head -1)
if [ -n "$RESULT" ]; then
    echo -e "  ${GREEN}✅ DNS64 funciona: $RESULT${NC}"
else
    echo -e "  ${YELLOW}⚠️  DNS64 no funciona${NC}"
fi
echo ""

# ═══════════════════════════════════════════════════════════
# 5. CONTENIDO DE LA ZONA
# ═══════════════════════════════════════════════════════════
if [ -n "$ZONE_FILE" ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "5️⃣  CONTENIDO DE LA ZONA DNS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Archivo: $ZONE_FILE"
    echo ""
    
    # Mostrar registros AAAA
    echo "Registros AAAA (IPv6):"
    sudo grep "IN.*AAAA" "$ZONE_FILE" 2>/dev/null || echo "  (ninguno encontrado)"
    echo ""
    
    # Mostrar registros A (IPv4)
    echo "Registros A (IPv4):"
    sudo grep "IN.*A[^A]" "$ZONE_FILE" 2>/dev/null | grep -v "AAAA" || echo "  (ninguno encontrado)"
    echo ""
fi

# ═══════════════════════════════════════════════════════════
# 6. LOGS RECIENTES
# ═══════════════════════════════════════════════════════════
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "6️⃣  LOGS RECIENTES (últimos 10)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

sudo journalctl -u bind9 -n 10 --no-pager 2>/dev/null || sudo journalctl -u named -n 10 --no-pager 2>/dev/null
echo ""

# ═══════════════════════════════════════════════════════════
# RESUMEN FINAL
# ═══════════════════════════════════════════════════════════
echo "════════════════════════════════════════════════════════"
echo "📊 RESUMEN"
echo "════════════════════════════════════════════════════════"
echo ""

ISSUES=0

if ! systemctl is-active --quiet bind9 && ! systemctl is-active --quiet named; then
    echo -e "${RED}❌ Servicio BIND9 no está activo${NC}"
    ((ISSUES++))
fi

if ! sudo ss -tulpn 2>/dev/null | grep -q ":53.*named"; then
    echo -e "${RED}❌ BIND9 no escucha en puerto 53${NC}"
    ((ISSUES++))
fi

RESULT=$(dig @localhost "$DOMAIN" AAAA +short 2>/dev/null | head -1)
if [ -z "$RESULT" ]; then
    echo -e "${RED}❌ DNS no resuelve $DOMAIN${NC}"
    ((ISSUES++))
fi

RESULT=$(dig @localhost "web.$DOMAIN" AAAA +short 2>/dev/null | head -1)
if [ -z "$RESULT" ]; then
    echo -e "${YELLOW}⚠️  Subdominio web.$DOMAIN no configurado${NC}"
    ((ISSUES++))
fi

if [ $ISSUES -eq 0 ]; then
    echo -e "${GREEN}✅ DNS funcionando correctamente${NC}"
else
    echo ""
    echo -e "${YELLOW}Se detectaron $ISSUES problemas${NC}"
    echo ""
    echo "Soluciones:"
    echo "  → Ejecutar rol completo: bash scripts/run/run-dns.sh"
    echo "  → Agregar subdominio web: sudo bash scripts/fix/add-web-subdomain.sh"
    echo "  → Ver diagnóstico completo: bash scripts/diagnostics/diagnose-dns-complete.sh"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo ""
