#!/bin/bash
# Script de diagnóstico rápido - Muestra estado en tabla
# Ejecutar: bash scripts/diagnostics/quick-status.sh

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

clear

echo ""
echo "════════════════════════════════════════════════════════════════════════════════"
echo "                    🔍 ESTADO RÁPIDO DEL SERVIDOR"
echo "════════════════════════════════════════════════════════════════════════════════"
echo ""
echo "Fecha: $(date '+%Y-%m-%d %H:%M:%S')"
echo "Servidor: $(hostname)"
echo ""

# ════════════════════════════════════════════════════════════════
# TABLA DE SERVICIOS
# ════════════════════════════════════════════════════════════════

echo "┌─────────────────────────┬──────────┬─────────────────────────────────────┐"
echo "│       SERVICIO          │  ESTADO  │            DETALLES                 │"
echo "├─────────────────────────┼──────────┼─────────────────────────────────────┤"

# BIND9 (DNS)
if systemctl is-active --quiet bind9 || systemctl is-active --quiet named; then
    STATUS="${GREEN}✅ ACTIVO${NC}"
    if sudo ss -tulpn 2>/dev/null | grep -q ":53.*named"; then
        DETAILS="Puerto 53 OK"
    else
        DETAILS="${YELLOW}Puerto 53 no escucha${NC}"
    fi
else
    STATUS="${RED}❌ INACTIVO${NC}"
    DETAILS="Servicio detenido"
fi
printf "│ %-23s │ %-8s │ %-35s │\n" "DNS (BIND9)" "$STATUS" "$DETAILS"

# DHCPv6
if systemctl is-active --quiet isc-dhcp-server6; then
    STATUS="${GREEN}✅ ACTIVO${NC}"
    if sudo ss -ulpn 2>/dev/null | grep -q ":547.*dhcpd"; then
        DETAILS="Puerto 547 OK"
    else
        DETAILS="${YELLOW}Puerto 547 no escucha${NC}"
    fi
else
    STATUS="${RED}❌ INACTIVO${NC}"
    DETAILS="Servicio detenido"
fi
printf "│ %-23s │ %-8s │ %-35s │\n" "DHCPv6" "$STATUS" "$DETAILS"

# TAYGA (NAT64)
if systemctl is-active --quiet tayga; then
    STATUS="${GREEN}✅ ACTIVO${NC}"
    if ip link show nat64 &>/dev/null; then
        DETAILS="Interfaz nat64 OK"
    else
        DETAILS="${YELLOW}Interfaz nat64 no existe${NC}"
    fi
else
    STATUS="${RED}❌ INACTIVO${NC}"
    DETAILS="Servicio detenido"
fi
printf "│ %-23s │ %-8s │ %-35s │\n" "NAT64 (TAYGA)" "$STATUS" "$DETAILS"

# RADVD
if systemctl is-active --quiet radvd; then
    STATUS="${GREEN}✅ ACTIVO${NC}"
    DETAILS="Router Advertisement OK"
else
    STATUS="${RED}❌ INACTIVO${NC}"
    DETAILS="Servicio detenido"
fi
printf "│ %-23s │ %-8s │ %-35s │\n" "RADVD" "$STATUS" "$DETAILS"

# UFW (Firewall)
if sudo ufw status 2>/dev/null | grep -q "Status: active"; then
    STATUS="${GREEN}✅ ACTIVO${NC}"
    RULES=$(sudo ufw status numbered 2>/dev/null | grep -c "^\[")
    DETAILS="$RULES reglas configuradas"
else
    STATUS="${RED}❌ INACTIVO${NC}"
    DETAILS="Firewall deshabilitado"
fi
printf "│ %-23s │ %-8s │ %-35s │\n" "Firewall (UFW)" "$STATUS" "$DETAILS"

# NFS
if systemctl is-active --quiet nfs-kernel-server; then
    STATUS="${GREEN}✅ ACTIVO${NC}"
    EXPORTS=$(sudo exportfs 2>/dev/null | wc -l)
    DETAILS="$EXPORTS exports configurados"
else
    STATUS="${RED}❌ INACTIVO${NC}"
    DETAILS="Servicio detenido"
fi
printf "│ %-23s │ %-8s │ %-35s │\n" "NFS Server" "$STATUS" "$DETAILS"

echo "└─────────────────────────┴──────────┴─────────────────────────────────────┘"
echo ""

# ════════════════════════════════════════════════════════════════
# TABLA DE RED
# ════════════════════════════════════════════════════════════════

echo "┌─────────────────────────┬──────────┬─────────────────────────────────────┐"
echo "│      COMPONENTE RED     │  ESTADO  │            DETALLES                 │"
echo "├─────────────────────────┼──────────┼─────────────────────────────────────┤"

# IPv4 Forwarding
if [ "$(cat /proc/sys/net/ipv4/ip_forward)" == "1" ]; then
    STATUS="${GREEN}✅ ACTIVO${NC}"
    DETAILS="Forwarding habilitado"
else
    STATUS="${RED}❌ INACTIVO${NC}"
    DETAILS="Forwarding deshabilitado"
fi
printf "│ %-23s │ %-8s │ %-35s │\n" "IPv4 Forwarding" "$STATUS" "$DETAILS"

# IPv6 Forwarding
if [ "$(cat /proc/sys/net/ipv6/conf/all/forwarding)" == "1" ]; then
    STATUS="${GREEN}✅ ACTIVO${NC}"
    DETAILS="Forwarding habilitado"
else
    STATUS="${RED}❌ INACTIVO${NC}"
    DETAILS="Forwarding deshabilitado"
fi
printf "│ %-23s │ %-8s │ %-35s │\n" "IPv6 Forwarding" "$STATUS" "$DETAILS"

# Interfaz ens33 (WAN)
if ip link show ens33 &>/dev/null; then
    STATUS="${GREEN}✅ ACTIVO${NC}"
    IPV6=$(ip -6 addr show ens33 2>/dev/null | grep "inet6.*global" | awk '{print $2}' | head -1)
    if [ -n "$IPV6" ]; then
        DETAILS="${IPV6:0:20}..."
    else
        DETAILS="${YELLOW}Sin IPv6 global${NC}"
    fi
else
    STATUS="${RED}❌ NO EXISTE${NC}"
    DETAILS="Interfaz no encontrada"
fi
printf "│ %-23s │ %-8s │ %-35s │\n" "Interfaz ens33 (WAN)" "$STATUS" "$DETAILS"

# Interfaz ens34 (LAN)
if ip link show ens34 &>/dev/null; then
    STATUS="${GREEN}✅ ACTIVO${NC}"
    IPV6=$(ip -6 addr show ens34 2>/dev/null | grep "inet6.*2025:db8:10" | awk '{print $2}' | head -1)
    if [ -n "$IPV6" ]; then
        DETAILS="$IPV6"
    else
        DETAILS="${YELLOW}Sin IPv6 configurada${NC}"
    fi
else
    STATUS="${RED}❌ NO EXISTE${NC}"
    DETAILS="Interfaz no encontrada"
fi
printf "│ %-23s │ %-8s │ %-35s │\n" "Interfaz ens34 (LAN)" "$STATUS" "$DETAILS"

# Interfaz nat64
if ip link show nat64 &>/dev/null; then
    STATUS="${GREEN}✅ ACTIVO${NC}"
    STATE=$(ip link show nat64 2>/dev/null | grep -o "state [A-Z]*" | awk '{print $2}')
    DETAILS="Estado: $STATE"
else
    STATUS="${RED}❌ NO EXISTE${NC}"
    DETAILS="Interfaz no creada"
fi
printf "│ %-23s │ %-8s │ %-35s │\n" "Interfaz nat64" "$STATUS" "$DETAILS"

echo "└─────────────────────────┴──────────┴─────────────────────────────────────┘"
echo ""

# ════════════════════════════════════════════════════════════════
# PRUEBAS RÁPIDAS
# ════════════════════════════════════════════════════════════════

echo "┌─────────────────────────┬──────────┬─────────────────────────────────────┐"
echo "│      PRUEBA FUNCIONAL   │  ESTADO  │            RESULTADO                │"
echo "├─────────────────────────┼──────────┼─────────────────────────────────────┤"

# DNS - Resolución local
DOMAIN=$(grep -r "domain_name:" group_vars/all.yml 2>/dev/null | grep -v "^#" | awk '{print $2}' | tr -d '"' | head -n1)
if [ -z "$DOMAIN" ]; then
    DOMAIN="gamecenter.lan"
fi

DNS_RESULT=$(dig @localhost "$DOMAIN" AAAA +short 2>/dev/null | head -1)
if [ -n "$DNS_RESULT" ]; then
    STATUS="${GREEN}✅ OK${NC}"
    DETAILS="${DNS_RESULT:0:30}"
else
    STATUS="${RED}❌ FALLO${NC}"
    DETAILS="No resuelve $DOMAIN"
fi
printf "│ %-23s │ %-8s │ %-35s │\n" "DNS Local ($DOMAIN)" "$STATUS" "$DETAILS"

# DNS64
DNS64_RESULT=$(dig @localhost google.com AAAA +short 2>/dev/null | grep "64:ff9b" | head -1)
if [ -n "$DNS64_RESULT" ]; then
    STATUS="${GREEN}✅ OK${NC}"
    DETAILS="${DNS64_RESULT:0:30}"
else
    STATUS="${YELLOW}⚠️  FALLO${NC}"
    DETAILS="No devuelve 64:ff9b::"
fi
printf "│ %-23s │ %-8s │ %-35s │\n" "DNS64 (google.com)" "$STATUS" "$DETAILS"

# NAT64 - Ping
if ping6 -c 1 -W 2 64:ff9b::8.8.8.8 &>/dev/null; then
    STATUS="${GREEN}✅ OK${NC}"
    DETAILS="Ping exitoso a 8.8.8.8"
else
    STATUS="${YELLOW}⚠️  FALLO${NC}"
    DETAILS="No hay conectividad NAT64"
fi
printf "│ %-23s │ %-8s │ %-35s │\n" "NAT64 Conectividad" "$STATUS" "$DETAILS"

# Conectividad IPv6 pura
if ping6 -c 1 -W 2 2001:4860:4860::8888 &>/dev/null; then
    STATUS="${GREEN}✅ OK${NC}"
    DETAILS="Ping exitoso a Google DNS"
else
    STATUS="${YELLOW}⚠️  FALLO${NC}"
    DETAILS="Sin conectividad IPv6"
fi
printf "│ %-23s │ %-8s │ %-35s │\n" "IPv6 Internet" "$STATUS" "$DETAILS"

echo "└─────────────────────────┴──────────┴─────────────────────────────────────┘"
echo ""

# ════════════════════════════════════════════════════════════════
# RESUMEN Y ACCIONES
# ════════════════════════════════════════════════════════════════

# Contar problemas
PROBLEMS=0

systemctl is-active --quiet bind9 || systemctl is-active --quiet named || ((PROBLEMS++))
systemctl is-active --quiet isc-dhcp-server6 || ((PROBLEMS++))
systemctl is-active --quiet tayga || ((PROBLEMS++))
systemctl is-active --quiet radvd || ((PROBLEMS++))
[ "$(cat /proc/sys/net/ipv4/ip_forward)" == "1" ] || ((PROBLEMS++))
[ "$(cat /proc/sys/net/ipv6/conf/all/forwarding)" == "1" ] || ((PROBLEMS++))

echo "════════════════════════════════════════════════════════════════════════════════"
if [ $PROBLEMS -eq 0 ]; then
    echo -e "                    ${GREEN}✅ SERVIDOR EN BUEN ESTADO${NC}"
    echo "════════════════════════════════════════════════════════════════════════════════"
    echo ""
    echo "🎉 Todos los servicios principales están funcionando"
else
    echo -e "                    ${YELLOW}⚠️  SE DETECTARON $PROBLEMS PROBLEMAS${NC}"
    echo "════════════════════════════════════════════════════════════════════════════════"
    echo ""
    echo "💡 Acciones recomendadas:"
    echo ""
    
    if ! systemctl is-active --quiet bind9 && ! systemctl is-active --quiet named; then
        echo "   🔴 DNS no está activo"
        echo "      → sudo systemctl start bind9"
        echo "      → bash scripts/run/validate-dns.sh"
        echo ""
    fi
    
    if ! systemctl is-active --quiet isc-dhcp-server6; then
        echo "   🔴 DHCPv6 no está activo"
        echo "      → sudo systemctl start isc-dhcp-server6"
        echo "      → bash scripts/run/validate-dhcp.sh"
        echo ""
    fi
    
    if ! systemctl is-active --quiet tayga; then
        echo "   🔴 NAT64 no está activo"
        echo "      → sudo systemctl start tayga"
        echo "      → bash scripts/run/validate-network.sh"
        echo ""
    fi
    
    if [ "$(cat /proc/sys/net/ipv4/ip_forward)" != "1" ] || [ "$(cat /proc/sys/net/ipv6/conf/all/forwarding)" != "1" ]; then
        echo "   🔴 Forwarding deshabilitado"
        echo "      → sudo sysctl -w net.ipv4.ip_forward=1"
        echo "      → sudo sysctl -w net.ipv6.conf.all.forwarding=1"
        echo ""
    fi
fi

echo ""
echo "🔧 Comandos útiles:"
echo "   → Validación completa:  bash scripts/run/validate-all.sh"
echo "   → Diagnóstico DNS:      bash scripts/diagnostics/diagnose-dns-complete.sh"
echo "   → Ver logs:             sudo journalctl -f"
echo "   → Reiniciar servicios:  bash scripts/run/run-all-services.sh"
echo ""
echo "════════════════════════════════════════════════════════════════════════════════"
echo ""
