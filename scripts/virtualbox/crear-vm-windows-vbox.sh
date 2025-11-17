#!/bin/bash
# ════════════════════════════════════════════════════════════════
# Script para crear VM Windows 11 en VirtualBox
# Para desarrollo/pruebas en PC local
# ════════════════════════════════════════════════════════════════

set -e

echo "════════════════════════════════════════════════════════"
echo "🪟 Crear VM Windows 11 en VirtualBox"
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
VM_NAME="windows11-01"
VM_RAM="4096"        # 4GB
VM_CPUS="2"
VM_DISK_SIZE="61440" # 60GB en MB
ISO_PATH=""

# Ayuda
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    echo "Uso: $0 [NOMBRE] [RAM_MB] [CPUs] [DISK_MB] [ISO_PATH]"
    echo ""
    echo "Ejemplos:"
    echo "  $0                                    # Valores por defecto"
    echo "  $0 win11-gaming 8192 4 102400         # Gaming: 8GB RAM, 4 CPUs, 100GB"
    echo ""
    echo "Valores por defecto:"
    echo "  Nombre: $VM_NAME"
    echo "  RAM:    $VM_RAM MB (4GB)"
    echo "  CPUs:   $VM_CPUS"
    echo "  Disco:  $VM_DISK_SIZE MB (60GB)"
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

# Buscar ISO de Windows 11 si no se especificó
if [ -z "$ISO_PATH" ]; then
    echo "🔍 Buscando ISO de Windows 11..."
    
    # Buscar en ubicaciones comunes
    SEARCH_PATHS=(
        "$HOME/Desktop/Win11*.iso"
        "$HOME/Downloads/Win11*.iso"
        "/c/Users/$USER/Desktop/Win11*.iso"
        "/c/Users/$USER/Downloads/Win11*.iso"
        "/mnt/c/Users/$USER/Desktop/Win11*.iso"
        "/mnt/c/Users/$USER/Downloads/Win11*.iso"
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
        echo "❌ No se encontró ISO de Windows 11"
        echo ""
        echo "📥 Especifica la ruta de la ISO:"
        echo ""
        echo "   $0 $VM_NAME $VM_RAM $VM_CPUS $VM_DISK_SIZE \"C:/Users/TU_USUARIO/Desktop/Win11.iso\""
        echo ""
        echo "   O en formato Git Bash:"
        echo "   $0 $VM_NAME $VM_RAM $VM_CPUS $VM_DISK_SIZE \"/c/Users/TU_USUARIO/Desktop/Win11.iso\""
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

# Crear VM con Windows 11
VBoxManage createvm --name "$VM_NAME" --ostype Windows11_64 --register

echo "  ✓ VM creada y registrada"

echo ""
echo "2️⃣  Configurando hardware..."

# Configurar RAM, CPUs y video
VBoxManage modifyvm "$VM_NAME" \
    --memory "$VM_RAM" \
    --cpus "$VM_CPUS" \
    --vram 128 \
    --graphicscontroller vboxsvga \
    --accelerate3d on

echo "  ✓ RAM: $VM_RAM MB"
echo "  ✓ CPUs: $VM_CPUS"
echo "  ✓ Video: 128MB con aceleración 3D"

echo ""
echo "3️⃣  Habilitando TPM 2.0 y Secure Boot..."

# Windows 11 requiere TPM 2.0 y Secure Boot
VBoxManage modifyvm "$VM_NAME" \
    --firmware efi \
    --tpm-type 2.0 \
    --secure-boot on

echo "  ✓ UEFI habilitado"
echo "  ✓ TPM 2.0 habilitado"
echo "  ✓ Secure Boot habilitado"

echo ""
echo "4️⃣  Creando disco virtual..."

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
echo "5️⃣  Configurando red..."

# Red interna (como en KVM)
VBoxManage modifyvm "$VM_NAME" \
    --nic1 intnet \
    --intnet1 "gamecenter" \
    --nictype1 82540EM \
    --cableconnected1 on

echo "  ✓ Red interna: gamecenter"

echo ""
echo "6️⃣  Adjuntando ISO de Windows 11..."

# Crear controlador IDE para CD
VBoxManage storagectl "$VM_NAME" --name "IDE" --add ide

# Adjuntar ISO
VBoxManage storageattach "$VM_NAME" --storagectl "IDE" --port 0 --device 0 --type dvddrive --medium "$ISO_PATH"

echo "  ✓ ISO de Windows 11 adjuntada"

echo ""
echo "7️⃣  Configuraciones adicionales..."

# Configuraciones de Windows
VBoxManage modifyvm "$VM_NAME" \
    --boot1 dvd \
    --boot2 disk \
    --boot3 none \
    --boot4 none \
    --audio none \
    --usb on \
    --usbehci on \
    --clipboard bidirectional \
    --draganddrop bidirectional \
    --mouse usbtablet

echo "  ✓ USB habilitado"
echo "  ✓ Clipboard bidireccional"
echo "  ✓ Mouse tablet (mejor integración)"

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ VM Windows 11 creada exitosamente"
echo "════════════════════════════════════════════════════════"
echo ""
echo "📋 Información:"
echo ""
echo "  Nombre:     $VM_NAME"
echo "  RAM:        $VM_RAM MB"
echo "  CPUs:       $VM_CPUS"
echo "  Disco:      $((VM_DISK_SIZE / 1024)) GB"
echo "  TPM:        2.0 ✅"
echo "  Secure Boot: ✅"
echo "  Red:        Red interna 'gamecenter'"
echo ""
echo "🚀 Iniciar VM:"
echo ""
echo "  VBoxManage startvm \"$VM_NAME\""
echo ""
echo "📝 Próximos pasos:"
echo ""
echo "1. Iniciar la VM e instalar Windows 11"
echo "2. Configurar red IPv6 (ver guía)"
echo "3. Habilitar SSH (ejecutar setup-ssh-windows.ps1)"
echo ""
echo "⚠️  IMPORTANTE: Red"
echo ""
echo "Esta VM está en red interna 'gamecenter'."
echo ""
echo "Opciones:"
echo "  A) Usar con servidor Ubuntu (NAT64/DNS64)"
echo "  B) Cambiar a NAT para internet directo:"
echo ""
echo "     VBoxManage modifyvm \"$VM_NAME\" --nic1 nat"
echo ""
echo "════════════════════════════════════════════════════════"

