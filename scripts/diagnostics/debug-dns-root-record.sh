#!/bin/bash
# Script de diagnóstico avanzado para encontrar por qué el registro @ no funciona
# Ejecutar: bash scripts/diagnostics/debug-dns-root-record.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DOMAIN="gamecenter.lan"
ZONE_FILE="/etc/bind/zones/db.$DOMAIN"
EXPECTED_IP="2025:db8:10::2"

echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}🔍 Diagnóstico Avanzado DNS - Registro Raíz (@)${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""

ERRORS=0

# ============================================
# 1. VERIFICAR QUE EL ARCHIVO DE ZONA EXISTE
# ============================================
echo -e "${YELLOW}📁 1. Verificando archivo de zona...${NC}"
if [ -f "$ZONE_FILE" ]; then
    echo -e "${GREEN}✅ Archivo existe: $ZONE_FILE${NC}"
else
    echo -e "${RED}❌ ERROR: Archivo NO existe: $ZONE_FILE${NC}"
    echo "   💡 Ejecuta: sudo bash scripts/run/run-dns.sh"
    ((ERRORS++))
    exit 1
fi
echo ""

# ============================================
# 2. VERIFICAR PERMISOS DEL ARCHIVO
# ============================================
echo -e "${YELLOW}🔐 2. Verificando permisos...${NC}"
PERMS=$(ls -l "$ZONE_FILE" | awk '{print $1, $3, $4}')
echo "   Permisos: $PERMS"

if sudo -u bind cat "$ZONE_FILE" &>/dev/null; then
    echo -e "${GREEN}✅ Usuario 'bind' puede leer el archivo${NC}"
else
    echo -e "${RED}❌ ERROR: Usuario 'bind' NO puede leer el archivo${NC}"
    echo "   💡 Ejecuta: sudo chown bind:bind $ZONE_FILE"
    ((ERRORS++))
fi
echo ""

# ============================================
# 3. VERIFICAR SINTAXIS DEL ARCHIVO
# ============================================
echo -e "${YELLOW}✔️  3. Verificando sintaxis del archivo...${NC}"
if sudo named-checkzone "$DOMAIN" "$ZONE_FILE" &>/dev/null; then
    echo -e "${GREEN}✅ Sintaxis correcta${NC}"
    ZONE_INFO=$(sudo named-checkzone "$DOMAIN" "$ZONE_FILE" 2>&1)
    echo "   $ZONE_INFO"
else
    echo -e "${RED}❌ ERROR: Sintaxis incorrecta${NC}"
    sudo named-checkzone "$DOMAIN" "$ZONE_FILE"
    ((ERRORS++))
    exit 1
fi
echo ""

# ============================================
# 4. BUSCAR EL REGISTRO @ EN EL ARCHIVO
# ============================================
echo -e "${YELLOW}🔍 4. Buscando registro raíz (@) en el archivo...${NC}"
echo "   Buscando: @ IN AAAA $EXPECTED_IP"
echo ""

# Mostrar las primeras 20 líneas del archivo
echo "   Contenido del archivo (primeras 20 líneas):"
echo "   ─────────────────────────────────────────────"
sudo cat "$ZONE_FILE" | head -20 | nl -w2 -s'│ '
echo "   ─────────────────────────────────────────────"
echo ""

# Buscar el registro @
if sudo grep -q "^@ *IN *AAAA *$EXPECTED_IP" "$ZONE_FILE"; then
    echo -e "${GREEN}✅ Registro @ encontrado en el archivo${NC}"
    FOUND_LINE=$(sudo grep -n "^@ *IN *AAAA *$EXPECTED_IP" "$ZONE_FILE")
    echo "   Línea: $FOUND_LINE"
elif sudo grep -q "^@ *IN *AAAA" "$ZONE_FILE"; then
    echo -e "${YELLOW}⚠️  Registro @ encontrado pero con IP diferente${NC}"
    FOUND_LINE=$(sudo grep -n "^@ *IN *AAAA" "$ZONE_FILE")
    echo "   Línea: $FOUND_LINE"
    echo -e "${RED}   💡 Debería ser: @ IN AAAA $EXPECTED_IP${NC}"
    ((ERRORS++))
else
    echo -e "${RED}❌ ERROR: Registro @ NO encontrado en el archivo${NC}"
    echo "   💡 El archivo debe tener esta línea:"
    echo "      @                       IN      AAAA    $EXPECTED_IP"
    ((ERRORS++))
fi
echo ""

# ============================================
# 5. VERIFICAR QUE BIND9 TIENE LA ZONA CARGADA
# ============================================
echo -e "${YELLOW}📊 5. Verificando que BIND9 tiene la zona cargada...${NC}"
if sudo rndc zonestatus "$DOMAIN" &>/dev/null; then
    echo -e "${GREEN}✅ Zona cargada en BIND9${NC}"
    ZONE_STATUS=$(sudo rndc zonestatus "$DOMAIN" 2>&1)
    echo "$ZONE_STATUS" | grep -E "name:|type:|serial:|nodes:"
else
    echo -e "${RED}❌ ERROR: Zona NO cargada en BIND9${NC}"
    echo "   💡 Ejecuta: sudo rndc reload $DOMAIN"
    ((ERRORS++))
fi
echo ""

# ============================================
# 6. PROBAR RESOLUCIÓN DNS
# ============================================
echo -e "${YELLOW}🧪 6. Probando resolución DNS...${NC}"
echo ""

# Prueba 1: Sin punto final
echo "   a) Probando: dig @127.0.0.1 $DOMAIN AAAA"
RESULT1=$(dig @127.0.0.1 "$DOMAIN" AAAA +short 2>&1)
if echo "$RESULT1" | grep -q "$EXPECTED_IP"; then
    echo -e "${GREEN}   ✅ Resuelve correctamente: $RESULT1${NC}"
else
    echo -e "${RED}   ❌ NO resuelve${NC}"
    echo "      Resultado: ${RESULT1:-Sin respuesta}"
    ((ERRORS++))
fi
echo ""

# Prueba 2: Con punto final (FQDN completo)
echo "   b) Probando: dig @127.0.0.1 $DOMAIN. AAAA (con punto final)"
RESULT2=$(dig @127.0.0.1 "$DOMAIN." AAAA +short 2>&1)
if echo "$RESULT2" | grep -q "$EXPECTED_IP"; then
    echo -e "${GREEN}   ✅ Resuelve correctamente: $RESULT2${NC}"
    if [ -z "$RESULT1" ] || ! echo "$RESULT1" | grep -q "$EXPECTED_IP"; then
        echo -e "${YELLOW}   ⚠️  NOTA: Solo funciona con punto final${NC}"
        echo "      Esto puede indicar un problema de configuración de búsqueda"
    fi
else
    echo -e "${RED}   ❌ NO resuelve ni con punto final${NC}"
    echo "      Resultado: ${RESULT2:-Sin respuesta}"
    ((ERRORS++))
fi
echo ""

# Prueba 3: Consulta completa (sin +short)
echo "   c) Consulta completa (para ver detalles):"
echo "   ─────────────────────────────────────────────"
dig @127.0.0.1 "$DOMAIN" AAAA | grep -A 10 "ANSWER SECTION" || echo "      Sin sección ANSWER"
echo "   ─────────────────────────────────────────────"
echo ""

# ============================================
# 7. VERIFICAR OTROS REGISTROS
# ============================================
echo -e "${YELLOW}🔍 7. Verificando otros registros (para comparar)...${NC}"
echo ""

echo "   a) servidor.$DOMAIN:"
RESULT_SERVIDOR=$(dig @127.0.0.1 "servidor.$DOMAIN" AAAA +short 2>&1)
if [ -n "$RESULT_SERVIDOR" ]; then
    echo -e "${GREEN}   ✅ Resuelve: $RESULT_SERVIDOR${NC}"
else
    echo -e "${RED}   ❌ NO resuelve${NC}"
fi
echo ""

echo "   b) www.$DOMAIN (CNAME):"
RESULT_WWW=$(dig @127.0.0.1 "www.$DOMAIN" AAAA +short 2>&1)
if [ -n "$RESULT_WWW" ]; then
    echo -e "${GREEN}   ✅ Resuelve: $RESULT_WWW${NC}"
else
    echo -e "${RED}   ❌ NO resuelve${NC}"
fi
echo ""

# ============================================
# 8. VERIFICAR CONFIGURACIÓN DE NAMED.CONF.LOCAL
# ============================================
echo -e "${YELLOW}📝 8. Verificando named.conf.local...${NC}"
if grep -q "zone \"$DOMAIN\"" /etc/bind/named.conf.local; then
    echo -e "${GREEN}✅ Zona configurada en named.conf.local${NC}"
    echo "   Configuración:"
    sudo grep -A 5 "zone \"$DOMAIN\"" /etc/bind/named.conf.local | sed 's/^/   /'
else
    echo -e "${RED}❌ ERROR: Zona NO configurada en named.conf.local${NC}"
    ((ERRORS++))
fi
echo ""

# ============================================
# 9. VERIFICAR LOGS DE BIND9
# ============================================
echo -e "${YELLOW}📋 9. Verificando logs recientes de BIND9...${NC}"
echo "   Últimas 10 líneas de logs:"
echo "   ─────────────────────────────────────────────"
sudo journalctl -u bind9 -n 10 --no-pager | sed 's/^/   /'
echo "   ─────────────────────────────────────────────"
echo ""

# ============================================
# RESUMEN Y DIAGNÓSTICO
# ============================================
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ NO SE ENCONTRARON ERRORES${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "El archivo de zona está bien configurado."
    echo ""
    if [ -z "$RESULT1" ] || ! echo "$RESULT1" | grep -q "$EXPECTED_IP"; then
        echo -e "${YELLOW}⚠️  POSIBLE CAUSA:${NC}"
        echo ""
        echo "El registro @ existe pero DNS no lo resuelve sin el punto final."
        echo "Esto puede ser porque:"
        echo ""
        echo "1. El dominio .lan no está en el search domain"
        echo "   Solución: Usar FQDN completo: $DOMAIN."
        echo ""
        echo "2. systemd-resolved está interceptando las consultas"
        echo "   Solución: Configurar /etc/systemd/resolved.conf"
        echo ""
        echo "3. El registro @ necesita un formato específico"
        echo "   Solución: Verificar espaciado en el archivo de zona"
        echo ""
    else
        echo -e "${GREEN}🎉 DNS funciona correctamente!${NC}"
    fi
else
    echo -e "${RED}❌ SE ENCONTRARON $ERRORS ERRORES${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}💡 SOLUCIONES SUGERIDAS:${NC}"
    echo ""
    echo "1. Regenerar el archivo de zona:"
    echo "   sudo bash scripts/run/run-dns.sh"
    echo ""
    echo "2. Verificar el template:"
    echo "   cat roles/dns_bind/templates/db.domain.j2"
    echo ""
    echo "3. Verificar variables:"
    echo "   grep dns_ group_vars/all.yml"
    echo ""
    echo "4. Ver logs completos:"
    echo "   sudo journalctl -u bind9 -n 50"
    echo ""
fi

exit $ERRORS
