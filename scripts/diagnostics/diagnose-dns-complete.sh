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

# Arrays para almacenar problemas
declare -a CRITICAL_ISSUES
declare -a WARNINGS
declare -a SOLUTIONS

# Verificar problemas comunes
ISSUES=0
WARNS=0

# 1. Servicio no corriendo
if ! systemctl is-active --quiet bind9; then
    CRITICAL_ISSUES+=("bind9 no está corriendo")
    SOLUTIONS+=("sudo systemctl start bind9")
    ((ISSUES++))
fi

# 2. Puerto 53 no escuchando
if ! sudo ss -tulpn | grep -q ":53.*named"; then
    CRITICAL_ISSUES+=("bind9 no escucha en puerto 53")
    SOLUTIONS+=("Verificar: sudo journalctl -u bind9 -n 50")
    ((ISSUES++))
fi

# 3. Archivo dhcp-key.key
if [ ! -f "/etc/bind/dhcp-key.key" ]; then
    CRITICAL_ISSUES+=("Falta archivo /etc/bind/dhcp-key.key")
    SOLUTIONS+=("bash scripts/run/run-dns.sh")
    ((ISSUES++))
else
    # Verificar permisos
    OWNER=$(stat -c "%U:%G" /etc/bind/dhcp-key.key)
    if [ "$OWNER" != "bind:bind" ]; then
        WARNINGS+=("dhcp-key.key tiene propietario incorrecto: $OWNER")
        SOLUTIONS+=("sudo chown bind:bind /etc/bind/dhcp-key.key")
        ((WARNS++))
    fi
fi

# 4. Resolución del dominio principal
RESULT=$(dig @localhost "$DOMAIN" AAAA +short 2>/dev/null)
if [ -z "$RESULT" ]; then
    CRITICAL_ISSUES+=("DNS no resuelve $DOMAIN")
    SOLUTIONS+=("Verificar zona: sudo named-checkzone $DOMAIN /var/lib/bind/db.$DOMAIN")
    ((ISSUES++))
fi

# 5. Subdominios importantes
for subdomain in www web servidor; do
    RESULT=$(dig @localhost "$subdomain.$DOMAIN" AAAA +short 2>/dev/null)
    if [ -z "$RESULT" ]; then
        WARNINGS+=("$subdomain.$DOMAIN no está configurado")
        SOLUTIONS+=("Agregar registro en /var/lib/bind/db.$DOMAIN")
        ((WARNS++))
    fi
done

# 6. DNS64
RESULT=$(dig @localhost google.com AAAA +short 2>/dev/null | grep "64:ff9b")
if [ -z "$RESULT" ]; then
    WARNINGS+=("DNS64 no funciona correctamente")
    SOLUTIONS+=("Verificar /etc/bind/named.conf.options")
    ((WARNS++))
fi

# 7. Archivo de zona
if [ ! -f "/var/lib/bind/db.$DOMAIN" ] && [ ! -f "/etc/bind/zones/db.$DOMAIN" ]; then
    CRITICAL_ISSUES+=("Falta archivo de zona para $DOMAIN")
    SOLUTIONS+=("bash scripts/run/run-dns.sh")
    ((ISSUES++))
fi

# 8. Servicio habilitado
if ! systemctl is-enabled --quiet bind9; then
    WARNINGS+=("bind9 no está habilitado al inicio")
    SOLUTIONS+=("sudo systemctl enable bind9")
    ((WARNS++))
fi

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
