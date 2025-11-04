#!/bin/bash
# Script para verificar conectividad de red desde VirtualBox

set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

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

show_network_info() {
    echo "🌐 INFORMACIÓN DE RED LOCAL"
    echo "=========================="
    echo ""
    
    echo "📍 Tu IP actual:"
    ip addr show | grep "inet " | grep -v "127.0.0.1" | head -3
    echo ""
    
    echo "📍 Tu IPv6 actual:"
    ip -6 addr show | grep "inet6" | grep -v "::1" | head -3
    echo ""
    
    echo "🛣️  Rutas de red:"
    ip route | head -5
    echo ""
}

test_basic_connectivity() {
    log_info "Probando conectividad básica..."
    
    # Test gateway
    gateway=$(ip route | grep default | awk '{print $3}' | head -1)
    if ping -c 2 "$gateway" >/dev/null 2>&1; then
        log_success "Gateway ($gateway): ✅ ACCESIBLE"
    else
        log_error "Gateway ($gateway): ❌ NO ACCESIBLE"
    fi
    
    # Test DNS
    if ping -c 2 8.8.8.8 >/dev/null 2>&1; then
        log_success "DNS externo (8.8.8.8): ✅ ACCESIBLE"
    else
        log_error "DNS externo (8.8.8.8): ❌ NO ACCESIBLE"
    fi
}

test_esxi_connectivity() {
    log_info "Probando conectividad con ESXi..."
    
    esxi_ip="172.17.25.11"
    
    # Test ping
    if ping -c 3 "$esxi_ip" >/dev/null 2>&1; then
        log_success "ESXi ($esxi_ip): ✅ PING OK"
    else
        log_error "ESXi ($esxi_ip): ❌ PING FALLA"
        return 1
    fi
    
    # Test SSH port
    if timeout 5 bash -c "echo >/dev/tcp/$esxi_ip/22" 2>/dev/null; then
        log_success "ESXi SSH (puerto 22): ✅ ABIERTO"
    else
        log_warning "ESXi SSH (puerto 22): ❌ CERRADO O FILTRADO"
    fi
    
    # Test HTTPS port (vSphere)
    if timeout 5 bash -c "echo >/dev/tcp/$esxi_ip/443" 2>/dev/null; then
        log_success "ESXi HTTPS (puerto 443): ✅ ABIERTO"
    else
        log_warning "ESXi HTTPS (puerto 443): ❌ CERRADO O FILTRADO"
    fi
}

test_ubuntu_server_connectivity() {
    log_info "Probando conectividad con servidor Ubuntu..."
    
    # Test IPv6
    ubuntu_ipv6="2025:db8:10::2"
    if ping6 -c 3 "$ubuntu_ipv6" >/dev/null 2>&1; then
        log_success "Servidor Ubuntu IPv6 ($ubuntu_ipv6): ✅ PING OK"
        
        # Test SSH IPv6
        if timeout 5 bash -c "echo >/dev/tcp/$ubuntu_ipv6/22" 2>/dev/null; then
            log_success "Servidor Ubuntu SSH IPv6: ✅ ABIERTO"
        else
            log_warning "Servidor Ubuntu SSH IPv6: ❌ BLOQUEADO (firewall)"
        fi
    else
        log_warning "Servidor Ubuntu IPv6 ($ubuntu_ipv6): ❌ NO ACCESIBLE"
        log_info "Esto es normal si IPv6 no está configurado en VirtualBox"
    fi
    
    # Test IPv4 (si existe)
    ubuntu_ipv4="172.17.25.125"  # IP estimada, ajustar según tu red
    log_info "Probando IP IPv4 estimada: $ubuntu_ipv4"
    if ping -c 3 "$ubuntu_ipv4" >/dev/null 2>&1; then
        log_success "Servidor Ubuntu IPv4 ($ubuntu_ipv4): ✅ PING OK"
    else
        log_warning "Servidor Ubuntu IPv4 ($ubuntu_ipv4): ❌ NO RESPONDE"
        log_info "La IP real puede ser diferente"
    fi
}

test_ansible_tools() {
    log_info "Verificando herramientas de Ansible..."
    
    # Ansible
    if command -v ansible >/dev/null 2>&1; then
        log_success "Ansible: ✅ INSTALADO ($(ansible --version | head -1))"
    else
        log_error "Ansible: ❌ NO INSTALADO"
        log_info "Instalar con: sudo apt install ansible"
    fi
    
    # SSH
    if command -v ssh >/dev/null 2>&1; then
        log_success "SSH: ✅ DISPONIBLE"
    else
        log_error "SSH: ❌ NO DISPONIBLE"
    fi
    
    # Git
    if command -v git >/dev/null 2>&1; then
        log_success "Git: ✅ DISPONIBLE"
    else
        log_warning "Git: ❌ NO DISPONIBLE"
        log_info "Instalar con: sudo apt install git"
    fi
}

show_recommendations() {
    echo ""
    echo "💡 RECOMENDACIONES SEGÚN LOS RESULTADOS:"
    echo "========================================"
    echo ""
    
    echo "✅ Si ESXi es accesible:"
    echo "   - Puedes ejecutar: ./scripts/crear-vm-ubuntu.sh"
    echo "   - El proyecto funcionará correctamente"
    echo ""
    
    echo "⚠️  Si el servidor Ubuntu no es accesible por SSH:"
    echo "   - Es normal debido al firewall"
    echo "   - Ansible creará la nueva VM y se conectará a ella"
    echo "   - La nueva VM SÍ será accesible desde tu red"
    echo ""
    
    echo "❌ Si ESXi no es accesible:"
    echo "   - Verificar que estás en la misma red (172.17.25.x)"
    echo "   - Verificar configuración de VirtualBox (modo bridged)"
    echo "   - Verificar firewall local"
    echo ""
    
    echo "🔧 Comandos útiles:"
    echo "   - Ver tu IP: ip addr show"
    echo "   - Escanear red: nmap -sn 172.17.25.0/24"
    echo "   - Test manual SSH: ssh root@172.17.25.11"
}

main() {
    echo "🔍 VERIFICACIÓN DE CONECTIVIDAD DE RED"
    echo "====================================="
    echo ""
    
    show_network_info
    test_basic_connectivity
    echo ""
    test_esxi_connectivity
    echo ""
    test_ubuntu_server_connectivity
    echo ""
    test_ansible_tools
    show_recommendations
    
    echo ""
    log_success "Verificación completada"
}

main "$@"