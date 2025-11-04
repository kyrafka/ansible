#!/bin/bash
# Script para configurar VM de control Ansible en VirtualBox

set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
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

log_step() {
    echo -e "${PURPLE}[PASO]${NC} $1"
}

show_banner() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║            CONFIGURAR VM ANSIBLE EN VIRTUALBOX             ║"
    echo "║                                                            ║"
    echo "║  Esta VM será tu controlador Ansible local                 ║"
    echo "║  Desde aquí ejecutarás los playbooks hacia ESXi           ║"
    echo "║                                                            ║"
    echo "║  Red: Bridged (misma red que ESXi)                        ║"
    echo "║  Acceso: SSH a ESXi (172.17.25.11)                       ║"
    echo "║  Acceso: SSH a servidor Ubuntu (2025:db8:10::2)          ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

check_virtualbox() {
    log_step "Verificando VirtualBox..."
    
    if ! command -v VBoxManage &> /dev/null; then
        log_error "VirtualBox no está instalado"
        log_info "Instala VirtualBox desde: https://www.virtualbox.org/"
        exit 1
    fi
    
    log_success "VirtualBox encontrado: $(VBoxManage --version)"
}

check_iso() {
    log_step "Verificando ISO de Ubuntu..."
    
    iso_path="ubuntu-24.04.3-desktop-amd64.iso"
    
    if [ ! -f "$iso_path" ]; then
        log_warning "ISO no encontrada: $iso_path"
        log_info "Descarga Ubuntu 24.04.3 desde: https://ubuntu.com/download/desktop"
        log_info "O especifica la ruta: export ISO_PATH=/ruta/a/tu/ubuntu.iso"
        
        if [ -n "$ISO_PATH" ] && [ -f "$ISO_PATH" ]; then
            iso_path="$ISO_PATH"
            log_success "Usando ISO: $iso_path"
        else
            exit 1
        fi
    else
        log_success "ISO encontrada: $iso_path"
    fi
}

create_vm() {
    log_step "Creando VM ansible-controller..."
    
    vm_name="ansible-controller"
    
    # Verificar si la VM ya existe
    if VBoxManage list vms | grep -q "$vm_name"; then
        log_warning "VM '$vm_name' ya existe"
        read -p "¿Eliminar y recrear? (y/N): " confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            VBoxManage unregistervm "$vm_name" --delete 2>/dev/null || true
        else
            log_info "Usando VM existente"
            return 0
        fi
    fi
    
    # Crear VM
    VBoxManage createvm --name "$vm_name" --ostype "Ubuntu_64" --register
    
    # Configurar hardware
    VBoxManage modifyvm "$vm_name" \
        --memory 2048 \
        --cpus 2 \
        --vram 128 \
        --graphicscontroller vmsvga \
        --audio none \
        --usb on \
        --usbehci on
    
    # Crear disco
    VBoxManage createhd --filename "$HOME/VirtualBox VMs/$vm_name/$vm_name.vdi" --size 20480
    
    # Configurar almacenamiento
    VBoxManage storagectl "$vm_name" --name "SATA Controller" --add sata --controller IntelAhci
    VBoxManage storageattach "$vm_name" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$HOME/VirtualBox VMs/$vm_name/$vm_name.vdi"
    
    # Configurar CD/DVD
    VBoxManage storagectl "$vm_name" --name "IDE Controller" --add ide
    VBoxManage storageattach "$vm_name" --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium "$iso_path"
    
    log_success "VM creada exitosamente"
}

configure_network() {
    log_step "Configurando red bridged..."
    
    vm_name="ansible-controller"
    
    # Listar adaptadores disponibles
    log_info "Adaptadores de red disponibles:"
    VBoxManage list bridgedifs | grep "^Name:" | head -5
    
    # Configurar red bridged (ajustar según tu adaptador)
    VBoxManage modifyvm "$vm_name" \
        --nic1 bridged \
        --bridgeadapter1 "$(VBoxManage list bridgedifs | grep "^Name:" | head -1 | cut -d' ' -f2-)"
    
    log_success "Red configurada en modo bridged"
    log_info "La VM obtendrá IP de tu red física (172.17.25.x)"
}

start_vm() {
    log_step "Iniciando VM..."
    
    vm_name="ansible-controller"
    
    VBoxManage startvm "$vm_name" --type gui
    
    log_success "VM iniciada"
}

show_next_steps() {
    echo ""
    log_success "¡VM ansible-controller creada y iniciada!"
    echo ""
    echo -e "${BLUE}📋 Próximos pasos MANUALES en la VM:${NC}"
    echo ""
    echo "1. 💿 Instalar Ubuntu 24.04:"
    echo "   - Seguir instalación normal"
    echo "   - Crear usuario (ej: ansible)"
    echo "   - Configurar red automática (DHCP)"
    echo ""
    echo "2. 🔧 Instalar herramientas necesarias:"
    echo "   sudo apt update"
    echo "   sudo apt install -y ansible git openssh-client sshpass"
    echo ""
    echo "3. 📁 Clonar el proyecto:"
    echo "   git clone <tu-repositorio> ansible-gestion-despliegue"
    echo "   cd ansible-gestion-despliegue"
    echo ""
    echo "4. 🔑 Configurar SSH:"
    echo "   ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519"
    echo "   # Copiar clave pública al servidor si es necesario"
    echo ""
    echo "5. 🌐 Verificar conectividad:"
    echo "   ping 172.17.25.11  # ESXi"
    echo "   ping 2025:db8:10::2  # Servidor Ubuntu (si IPv6 funciona)"
    echo ""
    echo "6. 🚀 Ejecutar proyecto:"
    echo "   ./scripts/crear-vm-ubuntu.sh"
    echo ""
    echo -e "${YELLOW}💡 La VM debería obtener IP en rango 172.17.25.x${NC}"
    echo -e "${YELLOW}💡 Desde ahí podrás acceder a ESXi sin problemas de firewall${NC}"
}

main() {
    show_banner
    
    read -p "¿Crear VM ansible-controller en VirtualBox? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        log_info "Operación cancelada"
        exit 0
    fi
    
    check_virtualbox
    check_iso
    create_vm
    configure_network
    start_vm
    show_next_steps
}

main "$@"