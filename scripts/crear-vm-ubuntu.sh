#!/bin/bash
# Script para crear VM Ubuntu en ESXi

set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
VAULT_PASSWORD_FILE="$PROJECT_DIR/.vault_pass"

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

log_step() {
    echo -e "${PURPLE}[PASO]${NC} $1"
}

show_banner() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                CREAR VM UBUNTU EN ESXi                     ║"
    echo "║                                                            ║"
    echo "║  ESXi: 172.17.25.11                                      ║"
    echo "║  VM: UBPC (Ubuntu 24.04)                                 ║"
    echo "║  RAM: 2GB, CPU: 1 core, Disco: 20GB                     ║"
    echo "║  Red: VM Network                                           ║"
    echo "║                                                            ║"
    echo "║  🤖 COMPLETAMENTE AUTOMÁTICO:                             ║"
    echo "║  Crea VM + Instala Ubuntu + Configura servicios           ║"
    echo "║  ¡Todo en un solo comando!                                 ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

check_prerequisites() {
    log_step "Verificando prerrequisitos..."
    
    # Verificar Ansible
    if ! command -v ansible-playbook &> /dev/null; then
        log_error "Ansible no está instalado"
        exit 1
    fi
    
    # Verificar colección VMware
    if ! ansible-galaxy collection list | grep -q "community.vmware"; then
        log_warning "Instalando colección community.vmware..."
        ansible-galaxy collection install community.vmware
    fi
    
    # Verificar vault
    if [ ! -f "$VAULT_PASSWORD_FILE" ]; then
        log_warning "Archivo de vault no encontrado"
        read -s -p "Ingresa la contraseña del vault: " vault_pass
        echo ""
        echo "$vault_pass" > "$VAULT_PASSWORD_FILE"
        chmod 600 "$VAULT_PASSWORD_FILE"
    fi
    
    log_success "Prerrequisitos verificados"
}

test_esxi_connection() {
    log_step "Probando conexión a ESXi..."
    
    cd "$PROJECT_DIR"
    
    if ansible vmware_servers -i inventory/hosts.ini -m ping --vault-password-file "$VAULT_PASSWORD_FILE"; then
        log_success "Conexión a ESXi verificada"
    else
        log_error "No se puede conectar a ESXi (172.17.25.11)"
        log_error "Verifica:"
        log_error "  - Conectividad de red"
        log_error "  - Credenciales en el vault"
        log_error "  - SSH habilitado en ESXi"
        exit 1
    fi
}

create_and_configure_vm() {
    log_step "Creando VM Ubuntu y configurando servicios automáticamente..."
    
    cd "$PROJECT_DIR"
    
    if ansible-playbook -i inventory/hosts.ini site.yml \
        --vault-password-file "$VAULT_PASSWORD_FILE" \
        -v; then
        log_success "VM creada y configurada exitosamente"
    else
        log_error "Error en el proceso"
        exit 1
    fi
}

show_results() {
    echo ""
    log_success "¡Proceso completado exitosamente!"
    echo ""
    echo -e "${BLUE}🎉 Lo que se hizo automáticamente:${NC}"
    echo ""
    echo "1. ✅ Creada VM 'UBPC' en ESXi"
    echo "2. ✅ Instalado Ubuntu 24.04 con particiones LVM"
    echo "3. ✅ Configurada red IPv6 por DHCPv6"
    echo "4. ✅ Habilitado SSH con usuario 'ubuntu'"
    echo "5. ✅ Instalados servicios IPv6:"
    echo "   - DNS/BIND9 (puerto 53)"
    echo "   - DHCPv6 Server (puerto 547)"
    echo "   - Firewall UFW + fail2ban"
    echo "   - Scripts de monitoreo"
    echo ""
    echo -e "${BLUE}🌐 Acceso a la nueva VM:${NC}"
    echo "   - SSH con clave: ssh ubuntu@[IP_asignada]"
    echo "   - SSH con password: ssh ubuntu@[IP_asignada] (password: ubuntu123)"
    echo "   - DNS: nslookup gamecenter.local [IP_asignada]"
    echo "   - Clave SSH: ~/.ssh/id_ed25519"
    echo ""
    echo -e "${BLUE}🔧 Comandos útiles:${NC}"
    echo "   - Ver servicios: systemctl status bind9 isc-dhcp-server6"
    echo "   - Ver IP: ip -6 addr show"
    echo "   - Verificar DHCP: journalctl -u isc-dhcp-server6"
    echo "   - Ver particiones: ./scripts/verificar-particiones.sh"
    echo "   - Monitoreo LVM: sudo vgs && sudo lvs"
    echo ""
    echo -e "${GREEN}🚀 ¡Tu VM Ubuntu está completamente lista y funcionando!${NC}"
}

main() {
    show_banner
    
    read -p "¿Crear VM Ubuntu 'UBPC' en ESXi? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        log_info "Operación cancelada"
        exit 0
    fi
    
    check_prerequisites
    test_esxi_connection
    create_and_configure_vm
    show_results
}

main "$@"