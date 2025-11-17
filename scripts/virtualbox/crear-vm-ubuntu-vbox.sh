#!/bin/bash
# ════════════════════════════════════════════════════════════════
# Script para crear VM Ubuntu Desktop en VirtualBox
# Para desarrollo/pruebas en PC local
# ════════════════════════════════════════════════════════════════

set -e

echo "════════════════════════════════════════════════════════"
echo "🖥️  Crear VM Ubuntu Desktop en VirtualBox"
echo "════════════════════════════════════════════════════════"
echo ""

# Verificar que VBoxManage está disponible
if ! command -v VBoxManage &> /dev/null; then
    echo "❌ VirtualBox no está instalado o no está en PATH"
    echo ""
    echo "Descarga VirtualBox desde:"
    echo "https://www.virtualbox.org/wiki/Downloads"
    exit 1
fi

# Configuración por defecto
VM_NAME="ubuntu-desktop-01"
VM_RAM="4096"        # 4GB
VM_CPUS="2"
VM_DISK_SIZE="40960" # 40GB en MB
ISO_PATH=""
NETWORK_MODE="intnet" # Red interna (como KVM)

# Ayuda
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    echo "Uso: $0 [NOMBRE] [RAM_MB] [CPUs] [DISK_MB] [ISO_PATH]"
    echo ""
    echo "Ejemplos:"
    echo "  $0                                    # Valores por defecto"
    echo "  $0 ubuntu-gaming 8192 4 81920         # Gaming: 8GB RAM, 4 CPUs, 80GB"
    echo ""
    echo "Valores por defecto:"
    echo "  Nombre: $VM_NAME"
    echo "  RAM:    $VM_RAM MB (4GB)"
    echo "  CPUs:   $VM_CPUS"
    echo "  Disco:  $VM_DISK_SIZE MB (40GB)"
    echo ""
    exit 0
fi

# Parámetros opcionales
[ -n "$1" ] && VM_NAME="$1"
[ -n "$2" ] && VM_RAM="$2"
[ -n "$3" ] && VM_CPUS="$3"
[ -n "$4" ] && VM_DISK_SIZE="$4"
[ -n "$5" ] && ISO_PATH="$5"

echo "📋 Configuración de la VM:"
echo ""
echo "  Nombre:     $VM_NAME"
echo "  RAM:        $VM_RAM MB"
echo "  CPUs:       $VM_CPUS"
echo "  Disco:      $((VM_DISK_SIZE / 1024)) GB"
echo ""

# Buscar ISO de Ubuntu si no se especificó
if [ -z "$ISO_PATH" ]; then
    echo "🔍 Buscando ISO de Ubuntu..."
    
    # Buscar en ubicaciones comunes de Windows
    SEARCH_PATHS=(
        "$HOME/Desktop/ubuntu-*.iso"
        "$HOME/Downloads/ubuntu-*.iso"
        "/c/Users/$USER/Desktop/ubuntu-*.iso"
        "/c/Users/$USER/Downloads/ubuntu-*.iso"
        "/mnt/c/Users/$USER/Desktop/ubuntu-*.iso"
        "/mnt/c/Users/$USER/Downloads/ubuntu-*.iso"
    )
    
    for pattern in "${SEARCH_PATHS[@]}"; do
        found=$(ls $pattern 2>/dev/null | head -n1)
        if [ -n "$found" ]; then
            ISO_PATH="$found"
            break
        fi
    done
    
    if [ -z "$ISO_PATH" ]; then
        echo ""
        echo "❌ No se encontró ISO de Ubuntu"
        echo ""
        echo "📥 Especifica la ruta de la ISO:"
        echo ""
        echo "   $0 $VM_NAME $VM_RAM $VM_CPUS $VM_DISK_SIZE \"C:/Users/TU_USUARIO/Desktop/ubuntu-24.04-desktop-amd64.iso\""
        echo ""
        echo "   O en formato Git Bash:"
        echo "   $0 $VM_NAME $VM_RAM $VM_CPUS $VM_DISK_SIZE \"/c/Users/TU_USUARIO/Desktop/ubuntu-24.04-desktop-amd64.iso\""
        echo ""
        exit 1
    fi
fi

echo "  ISO:        $ISO_PATH"
echo ""

read -p "¿Crear VM '$VM_NAME'? [S/n]: " CONFIRM
if [[ "$CONFIRM" =~ ^[nN]$ ]]; then
    echo "Operación cancelada"
    exit 0
fi

echo ""
echo "1️⃣  Creando VM..."

# Crear VM
VBoxManage createvm --name "$VM_NAME" --ostype Ubuntu_64 --register

echo "  ✓ VM creada y registrada"

echo ""
echo "2️⃣  Configurando hardware..."

# Configurar RAM y CPUs
VBoxManage modifyvm "$VM_NAME" \
    --memory "$VM_RAM" \
    --cpus "$VM_CPUS" \
    --vram 128 \
    --graphicscontroller vmsvga \
    --accelerate3d on

echo "  ✓ RAM: $VM_RAM MB"
echo "  ✓ CPUs: $VM_CPUS"
echo "  ✓ Video: 128MB con aceleración 3D"

echo ""
echo "3️⃣  Creando disco virtual..."

# Obtener carpeta de VMs
VM_FOLDER=$(VBoxManage showvminfo "$VM_NAME" --machinereadable | grep "CfgFile" | cut -d'"' -f2 | xargs dirname)
DISK_PATH="$VM_FOLDER/${VM_NAME}.vdi"

# Crear disco
VBoxManage createhd --filename "$DISK_PATH" --size "$VM_DISK_SIZE" --format VDI

# Crear controlador SATA
VBoxManage storagectl "$VM_NAME" --name "SATA" --add sata --controller IntelAhci --portcount 2

# Adjuntar disco
VBoxManage storageattach "$VM_NAME" --storagectl "SATA" --port 0 --device 0 --type hdd --medium "$DISK_PATH"

echo "  ✓ Disco creado: $((VM_DISK_SIZE / 1024)) GB"

echo ""
echo "4️⃣  Configurando red..."

# Red interna (como en KVM)
VBoxManage modifyvm "$VM_NAME" \
    --nic1 intnet \
    --intnet1 "gamecenter" \
    --nictype1 82540EM \
    --cableconnected1 on

echo "  ✓ Red interna: gamecenter"
echo "  ℹ️  Nota: Necesitarás configurar un servidor DHCP/Router en VirtualBox"

echo ""
echo "5️⃣  Adjuntando ISO..."

# Crear controlador IDE para CD
VBoxManage storagectl "$VM_NAME" --name "IDE" --add ide

# Adjuntar ISO
VBoxManage storageattach "$VM_NAME" --storagectl "IDE" --port 0 --device 0 --type dvddrive --medium "$ISO_PATH"

echo "  ✓ ISO adjuntada"

echo ""
echo "6️⃣  Configuraciones adicionales..."

# Habilitar EFI, USB, etc.
VBoxManage modifyvm "$VM_NAME" \
    --firmware efi \
    --boot1 dvd \
    --boot2 disk \
    --boot3 none \
    --boot4 none \
    --audio none \
    --usb on \
    --usbehci on \
    --clipboard bidirectional \
    --draganddrop bidirectional

echo "  ✓ UEFI habilitado"
echo "  ✓ USB habilitado"
echo "  ✓ Clipboard bidireccional"

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ VM creada exitosamente"
echo "════════════════════════════════════════════════════════"
echo ""
echo "📋 Información:"
echo ""
echo "  Nombre:     $VM_NAME"
echo "  RAM:        $VM_RAM MB"
echo "  CPUs:       $VM_CPUS"
echo "  Disco:      $((VM_DISK_SIZE / 1024)) GB"
echo "  Red:        Red interna 'gamecenter'"
echo ""
echo "🚀 Iniciar VM:"
echo ""
echo "  # Modo GUI (con ventana)"
echo "  VBoxManage startvm \"$VM_NAME\""
echo ""
echo "  # Modo headless (sin ventana, para servidor)"
echo "  VBoxManage startvm \"$VM_NAME\" --type headless"
echo ""
echo "📝 Próximos pasos:"
echo ""
echo "1. Iniciar la VM e instalar Ubuntu Desktop"
echo "2. Configurar red IPv6 (ver guía)"
echo "3. Ejecutar scripts de configuración"
echo ""
echo "⚠️  IMPORTANTE: Red interna"
echo ""
echo "Esta VM está en red interna 'gamecenter'."
echo "Necesitas:"
echo "  - Otra VM como servidor/router con NAT64"
echo "  - O cambiar a NAT para tener internet directo:"
echo ""
echo "    VBoxManage modifyvm \"$VM_NAME\" --nic1 nat"
echo ""
echo "════════════════════════════════════════════════════════"

