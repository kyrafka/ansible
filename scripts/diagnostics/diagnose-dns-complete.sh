#!/bin/bash
# Script de diagnóstico completo para DNS
# Ejecutar: bash scripts/diagnostics/diagnose-dns-complete.sh

set +e  # No salir en errores

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}           🔍 DIAGNÓSTICO COMPLETO DE DNS (BIND9)              ${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""

# ============================================================================
# 1. ESTADO DEL SERVICIO
# ============================================================================
echo -e "${YELLOW}═══ 1. ESTADO DEL SERVICIO BIND9 ═══${NC}"
echo ""

echo "→ Estado del servicio:"
systemctl status bind9 --no-pager -l | head -20
echo ""

echo "→ ¿Está activo?"
if systemctl is-active --quiet bind9; then
    echo -e "${GREEN}✅ SÍ - bind9 está corriendo${NC}"
else
    echo -e "${RED}❌ NO - bind9 NO está corriendo${NC}"
fi
echo ""

echo "→ ¿Está habilitado al inicio?"
if systemctl is-enabled --quiet bind9; then
    echo -e "${GREEN}✅ SÍ - bind9 se inicia automáticamente${NC}"
else
    echo -e "${RED}❌ NO - bind9 NO se inicia automáticamente${NC}"
fi
echo ""

# ============================================================================
# 2. PUERTOS Y PROCESOS
# ============================================================================
echo -e "${YELLOW}═══ 2. PUERTOS Y PROCESOS ═══${NC}"
echo ""

echo "→ Procesos de named corriendo:"
ps aux | grep named | grep -v grep
echo ""

echo "→ Puertos escuchando (todos los :53):"
sudo ss -tulpn | grep :53
echo ""

echo "→ Específicamente named en puerto 53:"
if sudo ss -tulpn | grep -q ":53.*named"; then
    echo -e "${GREEN}✅ named está escuchando en puerto 53${NC}"
    sudo ss -tulpn | grep ":53.*named"
else
    echo -e "${RED}❌ named NO está escuchando en puerto 53${NC}"
    echo ""
    echo "→ ¿Qué está usando el puerto 53?"
    sudo ss -tulpn | grep :53 || echo "Nada está usando el puerto 53"
fi
echo ""

# ============================================================================
# 3. ARCHIVOS DE CONFIGURACIÓN
# ============================================================================
echo -e "${YELLOW}═══ 3. ARCHIVOS DE CONFIGURACIÓN ═══${NC}"
echo ""

echo "→ Verificar sintaxis de named.conf:"
if sudo named-checkconf; then
    echo -e "${GREEN}✅ Configuración válida${NC}"
else
    echo -e "${RED}❌ Errores en la configuración${NC}"
fi
echo ""

echo "→ Archivos de configuración principales:"
for file in /etc/bind/named.conf /etc/bind/named.conf.options /etc/bind/named.conf.local /etc/bind/dhcp-key.key; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅ $file existe${NC}"
        ls -lh "$file"
    else
        echo -e "${RED}❌ $file NO existe${NC}"
    fi
done
echo ""

echo "→ Permisos de dhcp-key.key:"
if [ -f "/etc/bind/dhcp-key.key" ]; then
    ls -la /etc/bind/dhcp-key.key
    OWNER=$(stat -c "%U:%G" /etc/bind/dhcp-key.key)
    PERMS=$(stat -c "%a" /etc/bind/dhcp-key.key)
    
    if [ "$OWNER" == "bind:bind" ]; then
        echo -e "${GREEN}✅ Propietario correcto: $OWNER${NC}"
    else
        echo -e "${RED}❌ Propietario incorrecto: $OWNER (debería ser bind:bind)${NC}"
    fi
    
    if [ "$PERMS" == "640" ]; then
        echo -e "${GREEN}✅ Permisos correctos: $PERMS${NC}"
    else
        echo -e "${YELLOW}⚠️  Permisos: $PERMS (recomendado: 640)${NC}"
    fi
else
    echo -e "${RED}❌ /etc/bind/dhcp-key.key NO existe${NC}"
fi
echo ""

# ============================================================================
# 4. ZONAS DNS
# ============================================================================
echo -e "${YELLOW}═══ 4. ZONAS DNS ═══${NC}"
echo ""

DOMAIN=$(grep -r "domain_name:" group_vars/all.yml 2>/dev/null | grep -v "^#" | awk '{print $2}' | tr -d '"' | head -n1)
if [ -z "$DOMAIN" ]; then
    DOMAIN="gamecenter.lan"
fi

echo "→ Dominio detectado: $DOMAIN"
echo ""

echo "→ Archivos de zona:"
for zone_file in /etc/bind/zones/db.$DOMAIN /var/lib/bind/db.$DOMAIN; do
    if [ -f "$zone_file" ]; then
        echo -e "${GREEN}✅ $zone_file existe${NC}"
        ls -lh "$zone_file"
        
        echo "   Verificando sintaxis:"
        if sudo named-checkzone "$DOMAIN" "$zone_file" 2>&1 | head -5; then
            echo -e "${GREEN}   ✅ Zona válida${NC}"
        else
            echo -e "${RED}   ❌ Zona con errores${NC}"
        fi
    else
        echo -e "${RED}❌ $zone_file NO existe${NC}"
    fi
done
echo ""

echo "→ Contenido de la zona (primeras 20 líneas):"
if [ -f "/var/lib/bind/db.$DOMAIN" ]; then
    sudo head -20 "/var/lib/bind/db.$DOMAIN"
elif [ -f "/etc/bind/zones/db.$DOMAIN" ]; then
    sudo head -20 "/etc/bind/zones/db.$DOMAIN"
else
    echo -e "${RED}No se encontró archivo de zona${NC}"
fi
echo ""

# ============================================================================
# 5. PRUEBAS DE RESOLUCIÓN
# ============================================================================
echo -e "${YELLOW}═══ 5. PRUEBAS DE RESOLUCIÓN DNS ═══${NC}"
echo ""

echo "→ Probando resolución de $DOMAIN:"
dig @localhost "$DOMAIN" AAAA +short
if [ $? -eq 0 ]; then
    RESULT=$(dig @localhost "$DOMAIN" AAAA +short)
    if [ -n "$RESULT" ]; then
        echo -e "${GREEN}✅ Resuelve correctamente: $RESULT${NC}"
    else
        echo -e "${RED}❌ No devuelve resultado${NC}"
    fi
else
    echo -e "${RED}❌ Error al consultar${NC}"
fi
echo ""

echo "→ Probando subdominios:"
for subdomain in www web servidor dns; do
    echo "   → $subdomain.$DOMAIN:"
    RESULT=$(dig @localhost "$subdomain.$DOMAIN" AAAA +short 2>/dev/null)
    if [ -n "$RESULT" ]; then
        echo -e "${GREEN}      ✅ $RESULT${NC}"
    else
        echo -e "${YELLOW}      ⚠️  No configurado${NC}"
    fi
done
echo ""

echo "→ Probando DNS64 (google.com):"
RESULT=$(dig @localhost google.com AAAA +short 2>/dev/null | grep "64:ff9b")
if [ -n "$RESULT" ]; then
    echo -e "${GREEN}✅ DNS64 funciona: $RESULT${NC}"
else
    echo -e "${YELLOW}⚠️  DNS64 no devuelve prefijo 64:ff9b::${NC}"
fi
echo ""

# ============================================================================
# 6. LOGS Y ERRORES
# ============================================================================
echo -e "${YELLOW}═══ 6. LOGS Y ERRORES RECIENTES ═══${NC}"
echo ""

echo "→ Últimos 20 logs de bind9:"
sudo journalctl -u bind9 -n 20 --no-pager
echo ""

echo "→ Errores en los últimos 5 minutos:"
sudo journalctl -u bind9 --since "5 minutes ago" --no-pager | grep -i "error\|failed\|denied" || echo "Sin errores recientes"
echo ""

# ============================================================================
# 7. APPARMOR
# ============================================================================
echo -e "${YELLOW}═══ 7. APPARMOR ═══${NC}"
echo ""

echo "→ Estado de AppArmor para named:"
if command -v aa-status &> /dev/null; then
    sudo aa-status 2>/dev/null | grep named || echo "AppArmor no está restringiendo named"
else
    echo "AppArmor no instalado"
fi
echo ""

echo "→ Perfil de AppArmor:"
if [ -f "/etc/apparmor.d/usr.sbin.named" ]; then
    echo -e "${GREEN}✅ Perfil existe${NC}"
    if [ -f "/etc/apparmor.d/local/usr.sbin.named" ]; then
        echo "   Reglas locales:"
        sudo cat /etc/apparmor.d/local/usr.sbin.named
    fi
else
    echo -e "${YELLOW}⚠️  Perfil no encontrado${NC}"
fi
echo ""

# ============================================================================
# 8. RESUMEN Y RECOMENDACIONES
# ============================================================================
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                    📊 RESUMEN Y RECOMENDACIONES                ${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""

# Arrays para almacenar problemas con detalles
declare -a CRITICAL_ISSUES
declare -a CRITICAL_DETAILS
declare -a WARNINGS
declare -a WARNING_DETAILS
declare -a SOLUTIONS

# Verificar problemas comunes
ISSUES=0
WARNS=0

echo "→ Analizando problemas..."
echo ""

# ============================================================================
# VERIFICACIÓN 1: SERVICIO BIND9
# ============================================================================
echo -n "  [1/15] Verificando servicio bind9... "
if ! systemctl is-active --quiet bind9; then
    echo -e "${RED}FALLO${NC}"
    CRITICAL_ISSUES+=("Servicio bind9 NO está corriendo")
    CRITICAL_DETAILS+=("Estado: $(systemctl is-active bind9)")
    SOLUTIONS+=("sudo systemctl start bind9")
    ((ISSUES++))
else
    echo -e "${GREEN}OK${NC}"
fi

# ============================================================================
# VERIFICACIÓN 2: SERVICIO HABILITADO
# ============================================================================
echo -n "  [2/15] Verificando si bind9 está habilitado... "
if ! systemctl is-enabled --quiet bind9; then
    echo -e "${YELLOW}ADVERTENCIA${NC}"
    WARNINGS+=("bind9 no está habilitado al inicio del sistema")
    WARNING_DETAILS+=("Se debe habilitar para que inicie automáticamente")
    SOLUTIONS+=("sudo systemctl enable bind9")
    ((WARNS++))
else
    echo -e "${GREEN}OK${NC}"
fi

# ============================================================================
# VERIFICACIÓN 3: PUERTO 53 TCP
# ============================================================================
echo -n "  [3/15] Verificando puerto 53/TCP... "
if ! sudo ss -tulpn | grep -q ":53.*named.*tcp"; then
    echo -e "${RED}FALLO${NC}"
    CRITICAL_ISSUES+=("bind9 NO escucha en puerto 53/TCP")
    PORT_USER=$(sudo ss -tulpn | grep ":53.*tcp" | awk '{print $NF}' | head -1)
    if [ -n "$PORT_USER" ]; then
        CRITICAL_DETAILS+=("Puerto 53/TCP ocupado por: $PORT_USER")
    else
        CRITICAL_DETAILS+=("Puerto 53/TCP no está siendo usado por nadie")
    fi
    SOLUTIONS+=("sudo systemctl restart bind9")
    ((ISSUES++))
else
    echo -e "${GREEN}OK${NC}"
fi

# ============================================================================
# VERIFICACIÓN 4: PUERTO 53 UDP
# ============================================================================
echo -n "  [4/15] Verificando puerto 53/UDP... "
if ! sudo ss -tulpn | grep -q ":53.*named.*udp"; then
    echo -e "${RED}FALLO${NC}"
    CRITICAL_ISSUES+=("bind9 NO escucha en puerto 53/UDP")
    PORT_USER=$(sudo ss -tulpn | grep ":53.*udp" | awk '{print $NF}' | head -1)
    if [ -n "$PORT_USER" ]; then
        CRITICAL_DETAILS+=("Puerto 53/UDP ocupado por: $PORT_USER")
    else
        CRITICAL_DETAILS+=("Puerto 53/UDP no está siendo usado por nadie")
    fi
    SOLUTIONS+=("sudo systemctl restart bind9")
    ((ISSUES++))
else
    echo -e "${GREEN}OK${NC}"
fi

# ============================================================================
# VERIFICACIÓN 5: ARCHIVO named.conf
# ============================================================================
echo -n "  [5/15] Verificando named.conf... "
if ! sudo named-checkconf 2>/dev/null; then
    echo -e "${RED}FALLO${NC}"
    CRITICAL_ISSUES+=("Errores de sintaxis en named.conf")
    ERROR_MSG=$(sudo named-checkconf 2>&1)
    CRITICAL_DETAILS+=("Error: $ERROR_MSG")
    SOLUTIONS+=("Revisar: sudo named-checkconf")
    ((ISSUES++))
else
    echo -e "${GREEN}OK${NC}"
fi

# ============================================================================
# VERIFICACIÓN 6: ARCHIVO dhcp-key.key
# ============================================================================
echo -n "  [6/15] Verificando dhcp-key.key... "
if [ ! -f "/etc/bind/dhcp-key.key" ]; then
    echo -e "${RED}FALLO${NC}"
    CRITICAL_ISSUES+=("Archivo /etc/bind/dhcp-key.key NO existe")
    CRITICAL_DETAILS+=("Este archivo es necesario para DDNS")
    SOLUTIONS+=("bash scripts/run/run-dns.sh")
    ((ISSUES++))
else
    OWNER=$(stat -c "%U:%G" /etc/bind/dhcp-key.key)
    PERMS=$(stat -c "%a" /etc/bind/dhcp-key.key)
    
    if [ "$OWNER" != "bind:bind" ] || [ "$PERMS" != "640" ]; then
        echo -e "${YELLOW}ADVERTENCIA${NC}"
        WARNINGS+=("dhcp-key.key tiene permisos incorrectos")
        WARNING_DETAILS+=("Propietario: $OWNER (debe ser bind:bind), Permisos: $PERMS (debe ser 640)")
        SOLUTIONS+=("sudo chown bind:bind /etc/bind/dhcp-key.key && sudo chmod 640 /etc/bind/dhcp-key.key")
        ((WARNS++))
    else
        echo -e "${GREEN}OK${NC}"
    fi
fi

# ============================================================================
# VERIFICACIÓN 7: ARCHIVO DE ZONA
# ============================================================================
echo -n "  [7/15] Verificando archivo de zona... "
ZONE_FILE=""
if [ -f "/var/lib/bind/db.$DOMAIN" ]; then
    ZONE_FILE="/var/lib/bind/db.$DOMAIN"
elif [ -f "/etc/bind/zones/db.$DOMAIN" ]; then
    ZONE_FILE="/etc/bind/zones/db.$DOMAIN"
fi

if [ -z "$ZONE_FILE" ]; then
    echo -e "${RED}FALLO${NC}"
    CRITICAL_ISSUES+=("Archivo de zona para $DOMAIN NO existe")
    CRITICAL_DETAILS+=("Buscado en: /var/lib/bind/db.$DOMAIN y /etc/bind/zones/db.$DOMAIN")
    SOLUTIONS+=("bash scripts/run/run-dns.sh")
    ((ISSUES++))
else
    # Verificar sintaxis de la zona
    if ! sudo named-checkzone "$DOMAIN" "$ZONE_FILE" &>/dev/null; then
        echo -e "${RED}FALLO${NC}"
        CRITICAL_ISSUES+=("Zona $DOMAIN tiene errores de sintaxis")
        ERROR_MSG=$(sudo named-checkzone "$DOMAIN" "$ZONE_FILE" 2>&1 | head -3)
        CRITICAL_DETAILS+=("$ERROR_MSG")
        SOLUTIONS+=("Revisar: sudo named-checkzone $DOMAIN $ZONE_FILE")
        ((ISSUES++))
    else
        echo -e "${GREEN}OK${NC}"
    fi
fi

# ============================================================================
# VERIFICACIÓN 8: RESOLUCIÓN DEL DOMINIO PRINCIPAL
# ============================================================================
echo -n "  [8/15] Probando resolución de $DOMAIN... "
RESULT=$(dig @localhost "$DOMAIN" AAAA +short 2>/dev/null | head -1)
if [ -z "$RESULT" ]; then
    echo -e "${RED}FALLO${NC}"
    CRITICAL_ISSUES+=("DNS NO resuelve $DOMAIN")
    CRITICAL_DETAILS+=("dig @localhost $DOMAIN AAAA no devuelve resultado")
    SOLUTIONS+=("Verificar zona: sudo cat $ZONE_FILE | grep '@'")
    ((ISSUES++))
else
    echo -e "${GREEN}OK${NC} ($RESULT)"
fi

# ============================================================================
# VERIFICACIÓN 9-11: SUBDOMINIOS
# ============================================================================
SUBDOMAINS=("www" "web" "servidor")
for i in "${!SUBDOMAINS[@]}"; do
    subdomain="${SUBDOMAINS[$i]}"
    num=$((9 + i))
    echo -n "  [$num/15] Probando $subdomain.$DOMAIN... "
    RESULT=$(dig @localhost "$subdomain.$DOMAIN" AAAA +short 2>/dev/null | head -1)
    if [ -z "$RESULT" ]; then
        echo -e "${YELLOW}NO CONFIGURADO${NC}"
        WARNINGS+=("$subdomain.$DOMAIN no está configurado")
        WARNING_DETAILS+=("No hay registro AAAA para $subdomain en la zona")
        SOLUTIONS+=("Agregar en $ZONE_FILE: $subdomain IN AAAA <dirección_ipv6>")
        ((WARNS++))
    else
        echo -e "${GREEN}OK${NC} ($RESULT)"
    fi
done

# ============================================================================
# VERIFICACIÓN 12: DNS64
# ============================================================================
echo -n "  [12/15] Probando DNS64 (google.com)... "
RESULT=$(dig @localhost google.com AAAA +short 2>/dev/null | grep "64:ff9b" | head -1)
if [ -z "$RESULT" ]; then
    echo -e "${YELLOW}ADVERTENCIA${NC}"
    WARNINGS+=("DNS64 no funciona correctamente")
    WARNING_DETAILS+=("No devuelve direcciones con prefijo 64:ff9b::")
    SOLUTIONS+=("Verificar /etc/bind/named.conf.options - debe tener 'dns64 64:ff9b::/96'")
    ((WARNS++))
else
    echo -e "${GREEN}OK${NC} ($RESULT)"
fi

# ============================================================================
# VERIFICACIÓN 13: ERRORES EN LOGS
# ============================================================================
echo -n "  [13/15] Verificando errores en logs... "
ERROR_COUNT=$(sudo journalctl -u bind9 --since "5 minutes ago" --no-pager 2>/dev/null | grep -i "error\|failed\|denied" | wc -l)
if [ "$ERROR_COUNT" -gt 0 ]; then
    echo -e "${YELLOW}$ERROR_COUNT errores${NC}"
    WARNINGS+=("$ERROR_COUNT errores en logs de los últimos 5 minutos")
    LAST_ERROR=$(sudo journalctl -u bind9 --since "5 minutes ago" --no-pager 2>/dev/null | grep -i "error\|failed\|denied" | tail -1)
    WARNING_DETAILS+=("Último error: $LAST_ERROR")
    SOLUTIONS+=("Ver logs: sudo journalctl -u bind9 -n 50")
    ((WARNS++))
else
    echo -e "${GREEN}OK${NC}"
fi

# ============================================================================
# VERIFICACIÓN 14: APPARMOR
# ============================================================================
echo -n "  [14/15] Verificando AppArmor... "
if command -v aa-status &> /dev/null; then
    if sudo aa-status 2>/dev/null | grep -q "named.*enforce"; then
        echo -e "${YELLOW}ENFORCE${NC}"
        WARNINGS+=("AppArmor está en modo enforce para named")
        WARNING_DETAILS+=("Puede causar problemas de permisos")
        SOLUTIONS+=("sudo aa-complain /usr/sbin/named")
        ((WARNS++))
    else
        echo -e "${GREEN}OK${NC}"
    fi
else
    echo -e "${GREEN}N/A${NC}"
fi

# ============================================================================
# VERIFICACIÓN 15: PERMISOS DE /var/lib/bind
# ============================================================================
echo -n "  [15/15] Verificando permisos de /var/lib/bind... "
if [ -d "/var/lib/bind" ]; then
    OWNER=$(stat -c "%U:%G" /var/lib/bind)
    PERMS=$(stat -c "%a" /var/lib/bind)
    
    if [ "$OWNER" != "bind:bind" ] || [ "$PERMS" != "775" ]; then
        echo -e "${YELLOW}ADVERTENCIA${NC}"
        WARNINGS+=("/var/lib/bind tiene permisos incorrectos")
        WARNING_DETAILS+=("Propietario: $OWNER (debe ser bind:bind), Permisos: $PERMS (debe ser 775)")
        SOLUTIONS+=("sudo chown -R bind:bind /var/lib/bind && sudo chmod 775 /var/lib/bind")
        ((WARNS++))
    else
        echo -e "${GREEN}OK${NC}"
    fi
else
    echo -e "${RED}FALLO${NC}"
    CRITICAL_ISSUES+=("Directorio /var/lib/bind NO existe")
    CRITICAL_DETAILS+=("Este directorio es necesario para zonas dinámicas")
    SOLUTIONS+=("sudo mkdir -p /var/lib/bind && sudo chown bind:bind /var/lib/bind")
    ((ISSUES++))
fi

echo ""

# ============================================================================
# MOSTRAR LISTA DE PROBLEMAS
# ============================================================================
echo ""
if [ $ISSUES -eq 0 ] && [ $WARNS -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                  ✅ TODO FUNCIONA CORRECTAMENTE                ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
else
    # Mostrar problemas críticos
    if [ $ISSUES -gt 0 ]; then
        echo -e "${RED}╔════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║           ❌ PROBLEMAS CRÍTICOS DETECTADOS: $ISSUES                  ║${NC}"
        echo -e "${RED}╚════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        for i in "${!CRITICAL_ISSUES[@]}"; do
            echo -e "${RED}  $((i+1)). ❌ ${CRITICAL_ISSUES[$i]}${NC}"
            if [ -n "${CRITICAL_DETAILS[$i]}" ]; then
                echo -e "      ${RED}└─ ${CRITICAL_DETAILS[$i]}${NC}"
            fi
        done
        echo ""
    fi
    
    # Mostrar advertencias
    if [ $WARNS -gt 0 ]; then
        echo -e "${YELLOW}╔════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${YELLOW}║              ⚠️  ADVERTENCIAS DETECTADAS: $WARNS                    ║${NC}"
        echo -e "${YELLOW}╚════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        for i in "${!WARNINGS[@]}"; do
            echo -e "${YELLOW}  $((i+1)). ⚠️  ${WARNINGS[$i]}${NC}"
            if [ -n "${WARNING_DETAILS[$i]}" ]; then
                echo -e "      ${YELLOW}└─ ${WARNING_DETAILS[$i]}${NC}"
            fi
        done
        echo ""
    fi
    
    # Mostrar soluciones
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                    💡 SOLUCIONES SUGERIDAS                     ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Eliminar duplicados de soluciones
    UNIQUE_SOLUTIONS=($(printf '%s\n' "${SOLUTIONS[@]}" | sort -u))
    
    for i in "${!UNIQUE_SOLUTIONS[@]}"; do
        echo -e "${BLUE}  $((i+1)). ${UNIQUE_SOLUTIONS[$i]}${NC}"
    done
    echo ""
fi

# ============================================================================
# RESUMEN FINAL
# ============================================================================
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "  📊 Resumen:"
echo -e "     • Problemas críticos: ${RED}$ISSUES${NC}"
echo -e "     • Advertencias: ${YELLOW}$WARNS${NC}"
echo -e "     • Total de issues: $((ISSUES + WARNS))"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Diagnóstico completado: $(date)"
echo ""

# Exit code basado en problemas críticos
if [ $ISSUES -gt 0 ]; then
    exit 1
else
    exit 0
fi
