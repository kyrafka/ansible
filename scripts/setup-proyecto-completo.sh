#!/bin/bash
# Script de instalación completa del Proyecto SO
# Configura todos los servicios en el servidor Ubuntu

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Función para verificar prerrequisitos
check_prerequisites() {
    log_message "Verificando prerrequisitos..."
    
    # Verificar que estamos en Ubuntu
    if ! grep -q "Ubuntu" /etc/os-release; then
        log_error "Este script está diseñado para Ubuntu"
        exit 1
    fi
    
    # Verificar Ansible
    if ! command -v ansible-playbook &> /dev/null; then
        log_warning "Ansible no está instalado. Instalando..."
        sudo apt update
        sudo apt install -y ansible
    fi
    
    # Verificar archivo de vault
    if [ ! -f "$VAULT_PASSWORD_FILE" ]; then
        log_warning "Archivo de contraseña del vault no encontrado"
        echo "Por favor, crea el archivo .vault_pass con la contraseña del vault"
        read -s -p "Ingresa la contraseña del vault: " vault_pass
        echo "$vault_pass" > "$VAULT_PASSWORD_FILE"
        chmod 600 "$VAULT_PASSWORD_FILE"
    fi
    
    log_success "Prerrequisitos verificados"
}

# Función para instalar colecciones de Ansible
install_collections() {
    log_message "Instalando colecciones de Ansible..."
    
    if [ -f "$PROJECT_DIR/collections/requirements.yml" ]; then
        ansible-galaxy collection install -r "$PROJECT_DIR/collections/requirements.yml"
        log_success "Colecciones instaladas"
    else
        log_warning "Archivo de requirements no encontrado"
    fi
}

# Función para verificar conectividad
test_connectivity() {
    log_message "Probando conectividad con los hosts..."
    
    cd "$PROJECT_DIR"
    if ansible all -i inventory/hosts.ini -m ping --vault-password-file "$VAULT_PASSWORD_FILE"; then
        log_success "Conectividad verificada"
    else
        log_error "Error de conectividad. Verifica el inventario y credenciales"
        exit 1
    fi
}

# Función para ejecutar el playbook principal
run_main_playbook() {
    log_message "Ejecutando configuración completa del proyecto..."
    
    cd "$PROJECT_DIR"
    
    # Ejecutar con verbose para ver el progreso
    if ansible-playbook -i inventory/hosts.ini site.yml \
        --vault-password-file "$VAULT_PASSWORD_FILE" \
        -v; then
        log_success "Configuración completada exitosamente"
    else
        log_error "Error durante la configuración"
        exit 1
    fi
}

# Función para verificar servicios
verify_services() {
    log_message "Verificando servicios instalados..."
    
    services=("ssh" "bind9" "apache2" "isc-dhcp-server6" "fail2ban" "ufw")
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            log_success "$service está activo"
        else
            log_warning "$service no está activo"
        fi
    done
}

# Función para mostrar información final
show_final_info() {
    log_message "Configuración completada. Información del servidor:"
    
    echo ""
    echo "🌐 Servicios disponibles:"
    echo "  - Web: http://$(hostname)"
    echo "  - DNS: $(hostname).gamecenter.local"
    echo ""
    echo "🔧 Comandos útiles:"
    echo "  - Monitoreo de firewall: fw-monitor"
    echo "  - Estado de servicios: systemctl status <servicio>"
    echo "  - Logs: journalctl -u <servicio>"
    echo ""
    echo "📁 Directorios importantes:"
    echo "  - Web: /var/www/html"
    echo "  - DNS: /etc/bind"
    echo "  - Logs: /var/log"
    echo ""
}

# Función principal
main() {
    echo "🚀 INSTALACIÓN COMPLETA DEL PROYECTO SO"
    echo "======================================"
    echo ""
    
    check_prerequisites
    install_collections
    test_connectivity
    run_main_playbook
    verify_services
    show_final_info
    
    log_success "¡Instalación completada exitosamente!"
}

# Ejecutar función principal
main "$@"