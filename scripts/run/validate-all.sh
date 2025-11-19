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

# ════════════════════════════════════════════════════════════════
# REPORTE FINAL EN TABLA
# ════════════════════════════════════════════════════════════════

clear  # Limpiar pantalla para mostrar solo el reporte final

echo ""
echo "════════════════════════════════════════════════════════════════════════════════"
echo "                    📊 REPORTE FINAL DE VALIDACIÓN"
echo "════════════════════════════════════════════════════════════════════════════════"
echo ""
echo "Fecha: $(date '+%Y-%m-%d %H:%M:%S')"
echo "Servidor: $(hostname)"
echo ""

# Calcular estadísticas
FAILED=$((TOTAL - PASSED))
PERCENTAGE=$((PASSED * 100 / TOTAL))

# Mostrar estadísticas generales
echo "┌────────────────────────────────────────────────────────────────────────────┐"
echo "│                           ESTADÍSTICAS GENERALES                           │"
echo "├────────────────────────────────────────────────────────────────────────────┤"
printf "│  Total de componentes:     %-48s│\n" "$TOTAL"
printf "│  Componentes OK:           %-48s│\n" "$(echo -e "${GREEN}$PASSED${NC}")"
printf "│  Componentes con fallos:   %-48s│\n" "$(echo -e "${RED}$FAILED${NC}")"
printf "│  Porcentaje de éxito:      %-48s│\n" "$PERCENTAGE%"
echo "└────────────────────────────────────────────────────────────────────────────┘"
echo ""

# Tabla de resultados
echo "┌──────────────────────┬──────────┬──────────────────────────────────────────┐"
echo "│     COMPONENTE       │  ESTADO  │              DETALLES                    │"
echo "├──────────────────────┼──────────┼──────────────────────────────────────────┤"

for i in "${!COMPONENT_NAMES[@]}"; do
    NAME="${COMPONENT_NAMES[$i]}"
    STATUS="${COMPONENT_STATUS[$i]}"
    DETAILS="${COMPONENT_DETAILS[$i]}"
    
    # Truncar detalles si son muy largos
    if [ ${#DETAILS} -gt 40 ]; then
        DETAILS="${DETAILS:0:37}..."
    fi
    
    printf "│ %-20s │ %-8s │ %-40s │\n" "$NAME" "$STATUS" "$DETAILS"
done

echo "└──────────────────────┴──────────┴──────────────────────────────────────────┘"
echo ""

# Mostrar errores detallados si los hay
if [ $FAILED -gt 0 ]; then
    echo "════════════════════════════════════════════════════════════════════════════════"
    echo "                         ❌ COMPONENTES CON ERRORES"
    echo "════════════════════════════════════════════════════════════════════════════════"
    echo ""
    
    ERROR_NUM=1
    for i in "${!COMPONENT_NAMES[@]}"; do
        if [[ "${COMPONENT_STATUS[$i]}" == *"❌"* ]]; then
            echo -e "${RED}${ERROR_NUM}. ${COMPONENT_NAMES[$i]}${NC}"
            echo "   Problema: ${COMPONENT_DETAILS[$i]}"
            echo "   Comando para revisar: ${COMPONENT_ERRORS[$i]}"
            echo ""
            ((ERROR_NUM++))
        fi
    done
    
    echo "════════════════════════════════════════════════════════════════════════════════"
    echo "                              💡 SOLUCIONES RÁPIDAS"
    echo "════════════════════════════════════════════════════════════════════════════════"
    echo ""
    
    # Sugerencias específicas por componente
    for i in "${!COMPONENT_NAMES[@]}"; do
        if [[ "${COMPONENT_STATUS[$i]}" == *"❌"* ]]; then
            NAME="${COMPONENT_NAMES[$i]}"
            
            case "$NAME" in
                "Paquetes Base")
                    echo "🔧 Paquetes Base:"
                    echo "   → bash scripts/run/run-common.sh"
                    echo ""
                    ;;
                "Red IPv6")
                    echo "🔧 Red IPv6:"
                    echo "   → bash scripts/run/run-network.sh"
                    echo "   → sudo netplan apply"
                    echo "   → ip -6 addr show"
                    echo ""
                    ;;
                "DNS (BIND9)")
                    echo "🔧 DNS (BIND9):"
                    echo "   → bash scripts/run/run-dns.sh"
                    echo "   → bash scripts/diagnostics/diagnose-dns-complete.sh"
                    echo "   → sudo systemctl restart bind9"
                    echo ""
                    ;;
                "DHCPv6")
                    echo "🔧 DHCPv6:"
                    echo "   → bash scripts/run/run-dhcp.sh"
                    echo "   → sudo systemctl restart isc-dhcp-server6"
                    echo ""
                    ;;
                "Firewall")
                    echo "🔧 Firewall:"
                    echo "   → bash scripts/run/run-firewall.sh"
                    echo "   → sudo ufw status verbose"
                    echo ""
                    ;;
                "NFS Storage")
                    echo "🔧 NFS Storage:"
                    echo "   → bash scripts/run/run-storage.sh"
                    echo "   → sudo exportfs -ra"
                    echo ""
                    ;;
            esac
        fi
    done
    
    echo "════════════════════════════════════════════════════════════════════════════════"
    echo ""
    echo -e "${YELLOW}⚠️  RECOMENDACIÓN: Corrige los errores y vuelve a ejecutar este script${NC}"
    echo ""
    echo "   bash scripts/run/validate-all.sh"
    echo ""
    
    # Guardar reporte en archivo
    REPORT_FILE="/tmp/server-validation-report-$(date +%Y%m%d-%H%M%S).txt"
    {
        echo "REPORTE DE VALIDACIÓN DEL SERVIDOR"
        echo "Fecha: $(date)"
        echo ""
        echo "COMPONENTES CON ERRORES:"
        for i in "${!COMPONENT_NAMES[@]}"; do
            if [[ "${COMPONENT_STATUS[$i]}" == *"❌"* ]]; then
                echo "- ${COMPONENT_NAMES[$i]}: ${COMPONENT_DETAILS[$i]}"
            fi
        done
    } > "$REPORT_FILE"
    
    echo "📄 Reporte guardado en: $REPORT_FILE"
    echo ""
    
    exit 1
else
    echo "════════════════════════════════════════════════════════════════════════════════"
    echo -e "                    ${GREEN}✅ ¡SERVIDOR COMPLETAMENTE FUNCIONAL!${NC}"
    echo "════════════════════════════════════════════════════════════════════════════════"
    echo ""
    echo "🎉 Todos los componentes están funcionando correctamente"
    echo ""
    echo "📋 Servicios activos:"
    echo "   🌐 Red IPv6:     2025:db8:10::/64"
    echo "   🔍 DNS:          puerto 53 (BIND9)"
    echo "   📡 DHCPv6:       puerto 547"
    echo "   🔥 Firewall:     UFW + fail2ban"
    echo "   📂 NFS:          /srv/nfs/games, /srv/nfs/shared"
    echo ""
    echo "🔧 Comandos útiles:"
    echo "   → Ver logs DNS:    sudo journalctl -u bind9 -n 50"
    echo "   → Ver logs DHCP:   sudo journalctl -u isc-dhcp-server6 -n 50"
    echo "   → Probar DNS:      dig @localhost gamecenter.lan AAAA"
    echo "   → Ver firewall:    sudo ufw status verbose"
    echo "   → Ver NFS:         showmount -e localhost"
    echo ""
    echo "════════════════════════════════════════════════════════════════════════════════"
    echo ""
    
    exit 0
fi
