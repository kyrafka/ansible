#!/bin/bash
# Script de verificación del Proyecto SO
# Verifica que todos los servicios estén funcionando correctamente

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para verificar un servicio
verificar_servicio() {
    local servicio=$1
    local puerto=$2
    local host=${3:-localhost}
    
    echo -n "🔹 $servicio ($puerto): "
    
    if systemctl is-active --quiet "$servicio" 2>/dev/null; then
        echo -e "${GREEN}✅ ACTIVO${NC}"
        
        # Verificar puerto si se especifica
        if [ -n "$puerto" ]; then
            if netstat -tuln 2>/dev/null | grep -q ":$puerto "; then
                echo "   Puerto $puerto: ${GREEN}✅ ABIERTO${NC}"
            else
                echo "   Puerto $puerto: ${RED}❌ CERRADO${NC}"
            fi
        fi
    else
        echo -e "${RED}❌ INACTIVO${NC}"
    fi
}

# Función para verificar conectividad de red
verificar_red() {
    echo -e "${BLUE}🌐 VERIFICACIÓN DE RED${NC}"
    echo "===================="
    
    # Verificar interfaces IPv6
    echo "📡 Interfaces IPv6:"
    ip -6 addr show | grep -E "(inet6|UP)" | head -10
    echo ""
    
    # Verificar rutas IPv6
    echo "🛣️  Rutas IPv6:"
    ip -6 route | head -5
    echo ""
    
    # Verificar DNS
    echo "🔍 Resolución DNS:"
    if nslookup localhost >/dev/null 2>&1; then
        echo -e "   DNS local: ${GREEN}✅ FUNCIONANDO${NC}"
    else
        echo -e "   DNS local: ${RED}❌ ERROR${NC}"
    fi
    echo ""
}

# Función para verificar servicios web
verificar_web() {
    echo -e "${BLUE}🌍 VERIFICACIÓN WEB${NC}"
    echo "=================="
    
    # Verificar Apache
    if curl -s -o /dev/null -w "%{http_code}" http://localhost | grep -q "200"; then
        echo -e "   HTTP (puerto 80): ${GREEN}✅ RESPONDIENDO${NC}"
    else
        echo -e "   HTTP (puerto 80): ${RED}❌ NO RESPONDE${NC}"
    fi
    
    # Verificar archivos web
    if [ -f "/var/www/html/index.html" ]; then
        echo -e "   Página principal: ${GREEN}✅ EXISTE${NC}"
    else
        echo -e "   Página principal: ${RED}❌ NO EXISTE${NC}"
    fi
    echo ""
}

# Función para verificar DHCPv6
verificar_dhcp() {
    echo -e "${BLUE}🔧 VERIFICACIÓN DHCPv6${NC}"
    echo "===================="
    
    verificar_servicio "isc-dhcp-server6" "547"
    
    # Verificar configuración
    if [ -f "/etc/dhcp/dhcpd6.conf" ]; then
        echo -e "   Configuración DHCPv6: ${GREEN}✅ EXISTE${NC}"
    else
        echo -e "   Configuración DHCPv6: ${RED}❌ NO EXISTE${NC}"
    fi
    echo ""
}

# Función para verificar DNS
verificar_dns() {
    echo -e "${BLUE}🔍 VERIFICACIÓN DNS${NC}"
    echo "=================="
    
    verificar_servicio "bind9" "53"
    
    # Verificar configuración
    if named-checkconf >/dev/null 2>&1; then
        echo -e "   Configuración BIND: ${GREEN}✅ VÁLIDA${NC}"
    else
        echo -e "   Configuración BIND: ${RED}❌ ERROR${NC}"
    fi
    
    # Verificar zonas
    if [ -d "/etc/bind/zones" ]; then
        echo -e "   Directorio de zonas: ${GREEN}✅ EXISTE${NC}"
        echo "   Zonas configuradas:"
        ls -1 /etc/bind/zones/ 2>/dev/null | sed 's/^/     - /' || echo "     Ninguna"
    fi
    echo ""
}

# Función para verificar seguridad
verificar_seguridad() {
    echo -e "${BLUE}🛡️  VERIFICACIÓN DE SEGURIDAD${NC}"
    echo "=========================="
    
    verificar_servicio "ufw" ""
    verificar_servicio "fail2ban" ""
    
    # Verificar estado del firewall
    echo "🔥 Estado del firewall:"
    ufw status | head -10
    echo ""
    
    # Verificar fail2ban
    if systemctl is-active --quiet fail2ban; then
        echo "🚫 Jails de fail2ban activas:"
        fail2ban-client status 2>/dev/null | grep "Jail list" || echo "   No hay jails activas"
    fi
    echo ""
}

# Función para verificar logs
verificar_logs() {
    echo -e "${BLUE}📋 VERIFICACIÓN DE LOGS${NC}"
    echo "====================="
    
    # Verificar logs importantes
    logs=("/var/log/apache2/error.log" "/var/log/named/query.log" "/var/log/fail2ban.log" "/var/log/dhcpd6.log")
    
    for log in "${logs[@]}"; do
        if [ -f "$log" ]; then
            size=$(du -h "$log" 2>/dev/null | cut -f1)
            echo -e "   $(basename "$log"): ${GREEN}✅ EXISTE${NC} ($size)"
        else
            echo -e "   $(basename "$log"): ${YELLOW}⚠️  NO EXISTE${NC}"
        fi
    done
    echo ""
    
    # Mostrar errores recientes
    echo "🚨 Errores recientes en logs del sistema:"
    journalctl --since "1 hour ago" --priority=err --no-pager -n 5 2>/dev/null || echo "   No hay errores recientes"
    echo ""
}

# Función para generar reporte
generar_reporte() {
    local archivo_reporte="/tmp/verificacion-proyecto-$(date +%Y%m%d-%H%M).txt"
    
    {
        echo "REPORTE DE VERIFICACIÓN DEL PROYECTO SO"
        echo "======================================="
        echo "Fecha: $(date)"
        echo "Servidor: $(hostname)"
        echo ""
        
        verificar_red
        verificar_web
        verificar_ftp
        verificar_dns
        verificar_seguridad
        verificar_logs
        
    } > "$archivo_reporte"
    
    echo -e "${GREEN}📄 Reporte generado: $archivo_reporte${NC}"
}

# Función principal
main() {
    echo "🔍 VERIFICACIÓN DEL PROYECTO SO"
    echo "==============================="
    echo ""
    
    echo -e "${BLUE}🔧 SERVICIOS PRINCIPALES${NC}"
    echo "======================="
    verificar_servicio "ssh" "22"
    verificar_servicio "bind9" "53"
    verificar_servicio "apache2" "80"
    verificar_servicio "isc-dhcp-server6" "547"
    verificar_servicio "isc-dhcp-server6" "547"
    verificar_servicio "fail2ban" ""
    verificar_servicio "ufw" ""
    echo ""
    
    case "${1:-all}" in
        "red")
            verificar_red
            ;;
        "web")
            verificar_web
            ;;
        "dhcp")
            verificar_dhcp
            ;;
        "dns")
            verificar_dns
            ;;
        "seguridad")
            verificar_seguridad
            ;;
        "logs")
            verificar_logs
            ;;
        "reporte")
            generar_reporte
            ;;
        "all"|*)
            verificar_red
            verificar_web
            verificar_dhcp
            verificar_dns
            verificar_seguridad
            verificar_logs
            ;;
    esac
    
    echo -e "${GREEN}✅ Verificación completada${NC}"
    echo ""
    echo "💡 Comandos disponibles:"
    echo "   $0 red       - Solo verificación de red"
    echo "   $0 web       - Solo verificación web"
    echo "   $0 dhcp      - Solo verificación DHCPv6"
    echo "   $0 dns       - Solo verificación DNS"
    echo "   $0 seguridad - Solo verificación de seguridad"
    echo "   $0 logs      - Solo verificación de logs"
    echo "   $0 reporte   - Generar reporte completo"
}

# Ejecutar función principal
main "$@"