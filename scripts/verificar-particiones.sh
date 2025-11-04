#!/bin/bash
# Script para verificar el esquema de particiones de la VM UBPC

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

# Pedir IP de la VM
read -p "Ingresa la IP de la VM UBPC: " vm_ip

if [ -z "$vm_ip" ]; then
    echo -e "${RED}Error: IP no puede estar vacía${NC}"
    exit 1
fi

log_info "Verificando particiones en VM $vm_ip..."

# Ejecutar comandos de verificación en la VM
ssh -i ~/.ssh/id_ed25519 -o StrictHostKeyChecking=no ubuntu@$vm_ip << 'EOF'
echo "🔍 VERIFICACIÓN DE PARTICIONES Y ALMACENAMIENTO"
echo "=============================================="
echo ""

echo "📊 Resumen de particiones:"
lsblk -f

echo ""
echo "💾 Uso de disco por partición:"
df -h

echo ""
echo "🔧 Información de LVM:"
echo "Grupos de volúmenes:"
sudo vgs 2>/dev/null || echo "LVM no configurado"

echo ""
echo "Volúmenes lógicos:"
sudo lvs 2>/dev/null || echo "No hay volúmenes lógicos"

echo ""
echo "📁 Puntos de montaje críticos:"
echo "/ (root):"
df -h / | tail -1

echo "/var:"
df -h /var 2>/dev/null | tail -1 || echo "/var no tiene partición separada"

echo "/var/log:"
df -h /var/log 2>/dev/null | tail -1 || echo "/var/log no tiene partición separada"

echo "/tmp:"
df -h /tmp 2>/dev/null | tail -1 || echo "/tmp no tiene partición separada"

echo "/home:"
df -h /home 2>/dev/null | tail -1 || echo "/home no tiene partición separada"

echo ""
echo "🔒 Opciones de montaje de /tmp:"
mount | grep "/tmp" || echo "/tmp no montado por separado"

echo ""
echo "💿 Información del disco:"
sudo fdisk -l /dev/sda 2>/dev/null | head -20 || echo "No se puede acceder a información del disco"

echo ""
echo "🎯 Espacio disponible total:"
echo "Usado: $(df -h --total | tail -1 | awk '{print $3}')"
echo "Disponible: $(df -h --total | tail -1 | awk '{print $4}')"
echo "Total: $(df -h --total | tail -1 | awk '{print $2}')"
EOF

log_success "Verificación de particiones completada"

echo ""
echo -e "${BLUE}📋 Esquema de particiones configurado:${NC}"
echo "├── /boot/efi (512MB) - Partición EFI"
echo "├── /boot (1GB) - Kernel y archivos de arranque"
echo "└── LVM vg0 (resto del disco)"
echo "    ├── / (8GB) - Sistema raíz"
echo "    ├── /var (4GB) - Datos variables"
echo "    ├── /var/log (2GB) - Logs del sistema"
echo "    ├── /tmp (1GB) - Archivos temporales (noexec)"
echo "    └── /home (resto) - Directorios de usuarios"
echo ""
echo -e "${YELLOW}💡 Ventajas de este esquema:${NC}"
echo "• Separación de logs para evitar llenar el sistema"
echo "• /tmp con opciones de seguridad (noexec, nosuid)"
echo "• LVM para flexibilidad en redimensionamiento"
echo "• Particiones separadas para mejor organización"