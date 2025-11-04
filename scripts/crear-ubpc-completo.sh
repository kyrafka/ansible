#!/bin/bash
# Script para crear y configurar completamente la VM UBPC
# Ejecuta todo el proceso desde el servidor Ubuntu existente

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
VAULT_PASSWORD_FILE="$PROJECT_DIR/.vault_pass"

# Función para logging
log_message() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] ✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ❌ $1${NC}"
}

log_step() {
    echo -e "${PURPLE}[$(date '+%Y-%m-%d %H:%M:%S')] 🚀 $1${NC}"
}

# Función para mostrar banner
show_banner() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    CREACIÓN VM UBPC COMPLETA                 ║"
    echo "║                                                              ║"
    echo "║  Este script automatiza completamente:                       ║"
    echo "║  1. Conexión a ESXi (172.17.25.11)                         ║"
    echo "║  2. Creación de VM Ubuntu 'UBPC'                           ║"
    echo "║  3. Configuración completa de servicios IPv6                ║"
    echo "║                                                              ║"
    echo "║  Servicios que se instalarán:                               ║"
    echo "║  • DNS/BIND9 (puerto 53)                                   ║"
    echo "║  • Apache2 Web (puerto 80)                                 ║"
    echo "║  • DHCPv6 Server (puerto 547)                              ║"
    echo "║  • DHCPv6 Server (puerto 547)                              ║"
    echo "║  • Firewall UFW + fail2ban                                  ║"
    echo "║  • Scripts de monitoreo                                     ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Función para verificar prerrequisitos
check_prerequisites() {
    log_step "Verificando prerrequisitos del sistema..."
    
    # Verificar que estamos en el servidor Ubuntu correcto
    if [ "$(hostname -I | grep -o '192\.168\.100\.125')" != "192.168.100.125" ]; then
        log_warning "No se detectó la IP 192.168.100.125. ¿Estás en el servidor correcto?"
        read -p "¿Continuar de todas formas? (y/N): " confirm
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            log_error "Ejecución cancelada por el usuario"
            exit 1
        fi
    fi
    
    # Verificar Ansible
    if ! command -v ansible-playbook &> /dev/null; then
        log_error "Ansible no está instalado"
        exit 1
    fi
    
    # Verificar colecciones VMware
    if ! ansible-galaxy collection list | grep -q "community.vmware"; then
        log_warning "Colección community.vmware no encontrada. Instalando..."
        ansible-galaxy collection install community.vmware
    fi
    
    # Verificar archivo de vault
    if [ ! -f "$VAULT_PASSWORD_FILE" ]; then
        log_warning "Archivo de contraseña del vault no encontrado"
        read -s -p "Ingresa la contraseña del vault: " vault_pass
        echo ""
        echo "$vault_pass" > "$VAULT_PASSWORD_FILE"
        chmod 600 "$VAULT_PASSWORD_FILE"
        log_success "Archivo de vault creado"
    fi
    
    log_success "Prerrequisitos verificados"
}

# Función para probar conectividad
test_connectivity() {
    log_step "Probando conectividad con ESXi..."
    
    cd "$PROJECT_DIR"
    
    # Probar conexión a ESXi
    if ansible vmware_servers -i inventory/hosts.ini -m ping --vault-password-file "$VAULT_PASSWORD_FILE" -v; then
        log_success "Conectividad con ESXi verificada"
    else
        log_error "No se puede conectar a ESXi (172.17.25.11)"
        log_error "Verifica:"
        log_error "  - Conectividad de red al ESXi"
        log_error "  - Credenciales en el vault"
        log_error "  - Configuración SSH del ESXi"
        exit 1
    fi
}

# Función para crear y configurar VM
create_and_configure_vm() {
    log_step "Iniciando creación y configuración de VM UBPC..."
    
    cd "$PROJECT_DIR"
    
    # Ejecutar playbook completo
    if ansible-playbook -i inventory/hosts.ini playbooks/create_ubpc.yml \
        --vault-password-file "$VAULT_PASSWORD_FILE" \
        -v; then
        log_success "VM UBPC creada y configurada exitosamente"
    else
        log_error "Error durante la creación/configuración de la VM"
        log_error "Revisa los logs anteriores para más detalles"
        exit 1
    fi
}

# Función para verificar servicios
verify_services() {
    log_step "Verificando servicios en la nueva VM..."
    
    # Obtener IP de la VM desde el inventario dinámico o usar IP por defecto
    VM_IP="192.168.100.126"  # IP esperada para la nueva VM
    
    echo ""
    echo -e "${BLUE}🔍 Verificando servicios remotos en $VM_IP:${NC}"
    
    # Verificar puertos abiertos
    services=(
        "22:SSH"
        "53:DNS"
        "80:HTTP"
        ""
        "547:DHCPv6"
    )
    
    for service in "${services[@]}"; do
        port="${service%%:*}"
        name="${service##*:}"
        
        if timeout 5 bash -c "echo >/dev/tcp/$VM_IP/$port" 2>/dev/null; then
            log_success "$name (puerto $port) está disponible"
        else
            log_warning "$name (puerto $port) no responde"
        fi
    done
    
    # Verificar página web
    if curl -s -o /dev/null -w "%{http_code}" "http://$VM_IP" | grep -q "200"; then
        log_success "Servidor web responde correctamente"
    else
        log_warning "Servidor web no responde"
    fi
}

# Función para mostrar información final
show_final_info() {
    VM_IP="192.168.100.126"
    
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    🎉 INSTALACIÓN COMPLETADA 🎉              ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}📍 Información de la VM UBPC:${NC}"
    echo "   • Nombre: UBPC"
    echo "   • IP IPv4: $VM_IP"
    echo "   • IP IPv6: 2001:db8:1::20"
    echo "   • Dominio: ubpc-server.gamecenter.local"
    echo ""
    echo -e "${BLUE}🌐 Servicios disponibles:${NC}"
    echo "   • Web: http://$VM_IP"
    echo "   • DHCPv6: Asignación automática de IPs"
    echo "   • SSH: ssh ubuntu@$VM_IP"
    echo "   • DNS: nslookup gamecenter.local $VM_IP"
    echo ""
    echo -e "${BLUE}🔧 Comandos útiles para administrar la VM:${NC}"
    echo "   • Conectar por SSH: ssh ubuntu@$VM_IP"
    echo "   • Ver servicios: ssh ubuntu@$VM_IP 'systemctl status bind9 apache2 isc-dhcp-server6'"
    echo "   • Ver logs: ssh ubuntu@$VM_IP 'journalctl -f'"
    echo "   • Monitoreo firewall: ssh ubuntu@$VM_IP 'fw-monitor'"
    echo ""
    echo -e "${BLUE}📁 Directorios importantes en la VM:${NC}"
    echo "   • Web: /var/www/html"
    echo "   • DHCP: /etc/dhcp"
    echo "   • DNS: /etc/bind"
    echo "   • Logs: /var/log"
    echo ""
    echo -e "${YELLOW}💡 Para verificar el estado completo:${NC}"
    echo "   ./scripts/verificar-proyecto.sh"
    echo ""
}

# Función principal
main() {
    show_banner
    
    echo ""
    read -p "¿Proceder con la creación de la VM UBPC? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        log_error "Operación cancelada por el usuario"
        exit 0
    fi
    
    echo ""
    log_message "Iniciando proceso de creación de VM UBPC..."
    
    check_prerequisites
    test_connectivity
    create_and_configure_vm
    verify_services
    show_final_info
    
    log_success "¡Proceso completado exitosamente!"
}

# Ejecutar función principal
main "$@"