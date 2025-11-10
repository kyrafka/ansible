#!/bin/bash
# Script para probar conectividad SSH con la VM UBPC

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

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar si existe la clave SSH
if [ ! -f ~/.ssh/id_ed25519 ]; then
    log_error "Clave SSH no encontrada en ~/.ssh/id_ed25519"
    log_info "Ejecuta primero: ./scripts/crear-vm-ubuntu.sh"
    exit 1
fi

# Pedir IP de la VM
read -p "Ingresa la IP de la VM UBPC: " vm_ip

if [ -z "$vm_ip" ]; then
    log_error "IP no puede estar vacía"
    exit 1
fi

log_info "Probando conectividad SSH con $vm_ip..."

# Probar SSH con clave
if ssh -i ~/.ssh/id_ed25519 -o ConnectTimeout=10 -o StrictHostKeyChecking=no ubuntu@$vm_ip "echo 'SSH con clave funciona'"; then
    log_success "SSH con clave privada: ✅ FUNCIONA"
else
    log_error "SSH con clave privada: ❌ FALLA"
    
    # Probar SSH con contraseña
    log_info "Probando SSH con contraseña..."
    # Obtener contraseña del vault
    vault_pass=$(ansible-vault view group_vars/all.vault.yml --vault-password-file .vault_pass | grep vault_ubuntu_password | cut -d'"' -f2)
    if sshpass -p "$vault_pass" ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ubuntu@$vm_ip "echo 'SSH con password funciona'"; then
        log_success "SSH con contraseña: ✅ FUNCIONA"
    else
        log_error "SSH con contraseña: ❌ FALLA"
        log_error "La VM puede no estar lista aún"
        exit 1
    fi
fi

# Probar comandos básicos
log_info "Probando comandos básicos en la VM..."

ssh -i ~/.ssh/id_ed25519 -o StrictHostKeyChecking=no ubuntu@$vm_ip << 'EOF'
echo "🔍 Información del sistema:"
echo "Hostname: $(hostname)"
echo "Usuario: $(whoami)"
echo "SO: $(lsb_release -d | cut -f2)"
echo "Uptime: $(uptime -p)"

echo ""
echo "🌐 Configuración de red:"
ip -6 addr show | grep inet6 | head -3

echo ""
echo "🔧 Servicios SSH:"
systemctl is-active ssh || echo "SSH no activo"

echo ""
echo "🐍 Python disponible:"
python3 --version || echo "Python3 no encontrado"
EOF

log_success "¡Conectividad SSH verificada exitosamente!"
echo ""
echo -e "${BLUE}💡 Para conectar manualmente:${NC}"
echo "ssh -i ~/.ssh/id_ed25519 ubuntu@$vm_ip"
echo ""
echo -e "${BLUE}🚀 Para configurar servicios:${NC}"
echo "ansible-playbook site.yml --limit nueva_vm_ubpc"