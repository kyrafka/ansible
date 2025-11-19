#!/bin/bash
# Script para validar TODA la configuración del servidor
# Ejecutar: bash scripts/run/validate-all.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "════════════════════════════════════════════════════════"
echo "🔍 Validación Completa del Servidor GameCenter"
echo "════════════════════════════════════════════════════════"
echo ""

TOTAL=0
PASSED=0

# Arrays para almacenar resultados detallados
declare -a COMPONENT_NAMES
declare -a COMPONENT_STATUS
declare -a COMPONENT_DETAILS
declare -a COMPONENT_ERRORS

# Función para validar componente
validate_component() {
    local name="$1"
    local script="$2"
    local number="$3"
    
    echo "${number}  Validando ${name}..."
    
    # Capturar salida y código de error
    OUTPUT=$(bash "$SCRIPT_DIR/$script" 2>&1)
    EXIT_CODE=$?
    
    COMPONENT_NAMES+=("$name")
    
    if [ $EXIT_CODE -eq 0 ]; then
        COMPONENT_STATUS+=("✅ OK")
        COMPONENT_DETAILS+=("Funcionando correctamente")
        COMPONENT_ERRORS+=("")
        echo -e "${GREEN}   ✅ OK${NC}"
        ((PASSED++))
    else
        COMPONENT_STATUS+=("❌ FALLO")
        
        # Extraer detalles del error
        ERROR_SUMMARY=$(echo "$OUTPUT" | grep -E "❌|ERROR|FALLO" | head -3 | tr '\n' ' ')
        if [ -z "$ERROR_SUMMARY" ]; then
            ERROR_SUMMARY="Error desconocido - revisar manualmente"
        fi
        
        COMPONENT_DETAILS+=("$ERROR_SUMMARY")
        COMPONENT_ERRORS+=("bash scripts/run/$script")
        echo -e "${RED}   ❌ FALLO${NC}"
    fi
    
    ((TOTAL++))
    echo ""
}

# Ejecutar cada validación
validate_component "Paquetes Base" "validate-common.sh" "1️⃣"
validate_component "Red IPv6" "validate-network.sh" "2️⃣"
validate_component "DNS (BIND9)" "validate-dns.sh" "3️⃣"
validate_component "DHCPv6" "validate-dhcp.sh" "4️⃣"
validate_component "Firewall" "validate-firewall.sh" "5️⃣"
validate_component "NFS Storage" "validate-storage.sh" "6️⃣"

# Resumen final
echo "════════════════════════════════════════════════════════"
echo "📊 Resumen de Validación"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Componentes validados: $PASSED/$TOTAL"
echo ""

if [ $PASSED -eq $TOTAL ]; then
    echo "✅ ¡Servidor completamente configurado y funcional!"
    echo ""
    echo "Servicios activos:"
    echo "  🌐 Red IPv6: 2025:db8:10::/64"
    echo "  🔍 DNS: puerto 53"
    echo "  📡 DHCPv6: puerto 547"
    echo "  🔥 Firewall: UFW + fail2ban"
    echo "  📂 NFS: /srv/nfs/games, /srv/nfs/shared"
    exit 0
else
    FAILED=$((TOTAL - PASSED))
    echo "❌ Hay $FAILED componentes con problemas"
    echo ""
    echo "Ejecuta los scripts individuales para más detalles:"
    echo "  bash scripts/run/validate-common.sh"
    echo "  bash scripts/run/validate-network.sh"
    echo "  bash scripts/run/validate-dns.sh"
    echo "  bash scripts/run/validate-dhcp.sh"
    echo "  bash scripts/run/validate-firewall.sh"
    echo "  bash scripts/run/validate-storage.sh"
    exit 1
fi
