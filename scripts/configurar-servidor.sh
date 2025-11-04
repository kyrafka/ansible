#!/bin/bash
# Script simplificado para configurar servicios IPv6 en el servidor Ubuntu

set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_banner() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║              CONFIGURACIÓN SERVIDOR IPv6                   ║"
    echo "║                                                            ║"
    echo "║  Red: 2025:db8:10::/64                                    ║"
    echo "║  Servidor: 2025:db8:10::2 (tu Ubuntu actual)             ║"
    echo "║  Gateway: 2025:db8:10::1                                  ║"
    echo "║  DHCP: desde 2025:db8:10::10 en adelante                 ║"
    echo "║                                                            ║"
    echo "║  Servicios a instalar:                                     ║"
    echo "║  • DNS/BIND9 (puerto 53)                                  ║"
    echo "║  • Apache2 Web (puerto 80)                                ║"
    echo "║  • DHCPv6 Server (puerto 547)                             ║"
    echo "║  • Firewall UFW + fail2ban                                 ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

check_network() {
    log_info "Verificando configuración de red IPv6..."
    
    # Verificar si tenemos IPv6
    if ! ip -6 addr show | grep -q "2025:db8:10::2"; then
        log_warning "No se detectó la IP 2025:db8:10::2"
        log_info "IPs IPv6 actuales:"
        ip -6 addr show | grep "inet6" | grep -v "::1"
    else
        log_success "IP IPv6 correcta detectada: 2025:db8:10::2"
    fi
}

run_configuration() {
    log_info "Ejecutando configuración de servicios..."
    
    cd "$PROJECT_DIR"
    
    # Ejecutar solo en el servidor local
    if ansible-playbook -i inventory/hosts.ini site.yml \
        --limit servidores_ubuntu \
        --connection=local \
        -v; then
        log_success "Configuración completada"
    else
        log_error "Error en la configuración"
        return 1
    fi
}

verify_services() {
    log_info "Verificando servicios instalados..."
    
    services=("bind9" "apache2" "isc-dhcp-server6" "fail2ban" "ufw")
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            log_success "$service está activo"
        else
            log_warning "$service no está activo"
        fi
    done
}

show_results() {
    echo ""
    log_success "¡Configuración completada!"
    echo ""
    echo -e "${BLUE}📍 Tu servidor ahora tiene:${NC}"
    echo "   • IP: 2025:db8:10::2"
    echo "   • DNS: puerto 53 (resuelve gamecenter.local)"
    echo "   • Web: puerto 80 (http://[2025:db8:10::2])"
    echo "   • DHCPv6: puerto 547 (asigna IPs desde ::10)"
    echo "   • Firewall: activo con fail2ban"
    echo ""
    echo -e "${BLUE}🔧 Comandos útiles:${NC}"
    echo "   • Ver servicios: systemctl status bind9 apache2"
    echo "   • Ver logs: journalctl -f"
    echo "   • Verificar DHCP: systemctl status isc-dhcp-server6"
    echo ""
}

main() {
    show_banner
    
    read -p "¿Configurar servicios IPv6 en este servidor? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        log_info "Operación cancelada"
        exit 0
    fi
    
    check_network
    run_configuration
    verify_services
    show_results
}

main "$@"