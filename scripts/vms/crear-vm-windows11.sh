#!/bin/bash
# Script para crear VM Windows 11 con KVM/QEMU

# Auto-permisos
[ ! -x "$0" ] && chmod +x "$0" 2>/dev/null

set -e

echo "════════════════════════════════════════════════════════"
echo "🪟 Crear VM Windows 11"
echo "════════════════════════════════════════════════════════"
echo ""

# Configuración por defecto
VM_NAME="windows11-01"
VM_RAM="4096"        # 4GB RAM
VM_CPUS="2"
VM_DISK_SIZE="60"    # 60GB
ISO_PATH=""
VIRTIO_ISO="/var/lib/libvirt/images/virtio-win.iso"

# Mostrar ayuda
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    echo "Uso: $0 [NOMBRE] [RAM_MB] [CPUs] [DISK_GB] [ISO_PATH]"
    echo ""
    echo "Ejemplos:"
    echo "  $0                                    # Valores por defecto"
    echo "  $0 win11-gaming                       # Solo cambiar nombre"
    echo "  $0 win11-gaming 8192 4 100            # Gaming: 8GB RAM, 4 CPUs, 100GB"
    echo "  $0 win11-office 2048 2 40             # Office: 2GB RAM, 2 CPUs, 40GB"
    echo ""
    echo "Valores por defecto:"
    echo "  Nombre: $VM_NAME"
    echo "  RAM:    $VM_RAM MB (4GB)"
    echo "  CPUs:   $VM_CPUS"
    echo "  Disco:  $VM_DISK_SIZE GB"
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
echo "  Disco:      $VM_DISK_SIZE GB"
echo ""

# Buscar ISO de Windows 11 si no se especificó
if [ -z "$ISO_PATH" ]; then
    echo "🔍 Buscando ISO de Windows 11..."
    
    # Buscar en ubicaciones comunes
    SEARCH_PATHS=(
        "/var/lib/libvirt/images/Win11*.iso"
        "/var/lib/libvirt/images/windows11*.iso"
        "/var/lib/libvirt/images/Windows11*.iso"
        "$HOME/Win11*.iso"
        "$HOME/Downloads/Win11*.iso"
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
        echo "📥 Descarga Windows 11 desde:"
        echo "   https://www.microsoft.com/software-download/windows11"
        echo ""
        echo "💾 Guárdala en:"
        echo "   /var/lib/libvirt/images/Win11.iso"
        echo ""
        echo "Luego ejecuta:"
        echo "   $0 $VM_NAME $VM_RAM $VM_CPUS $VM_DISK_SIZE /var/lib/libvirt/images/Win11.iso"
        echo ""
        exit 1
    fi
fi

echo "  ISO:        $ISO_PATH"
echo ""

# Verificar que existe la ISO
if [ ! -f "$ISO_PATH" ]; then
    echo "❌ No se encuentra el archivo ISO: $ISO_PATH"
    exit 1
fi

# Verificar/descargar drivers VirtIO
if [ ! -f "$VIRTIO_ISO" ]; then
    echo "📥 Descargando drivers VirtIO para Windows..."
    echo "   (Necesarios para red y disco en KVM)"
    echo ""
    
    VIRTIO_URL="https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso"
    
    sudo wget -O "$VIRTIO_ISO" "$VIRTIO_URL" || {
        echo "❌ Error descargando VirtIO drivers"
        echo "   Descarga manual desde: $VIRTIO_URL"
        exit 1
    }
    
    echo "  ✓ Drivers VirtIO descargados"
fi

echo ""
read -p "¿Crear VM '$VM_NAME'? [S/n]: " CONFIRM
if [[ "$CONFIRM" =~ ^[nN]$ ]]; then
    echo "Operación cancelada"
    exit 0
fi

echo ""
echo "1️⃣  Creando disco virtual..."

DISK_PATH="/var/lib/libvirt/images/${VM_NAME}.qcow2"

if [ -f "$DISK_PATH" ]; then
    echo "  ⚠️  El disco ya existe: $DISK_PATH"
    read -p "  ¿Sobrescribir? [s/N]: " OVERWRITE
    if [[ ! "$OVERWRITE" =~ ^[sS]$ ]]; then
        echo "  Usando disco existente"
    else
        sudo rm -f "$DISK_PATH"
        sudo qemu-img create -f qcow2 "$DISK_PATH" "${VM_DISK_SIZE}G"
        echo "  ✓ Disco creado: ${VM_DISK_SIZE}GB"
    fi
else
    sudo qemu-img create -f qcow2 "$DISK_PATH" "${VM_DISK_SIZE}G"
    echo "  ✓ Disco creado: ${VM_DISK_SIZE}GB"
fi

echo ""
echo "2️⃣  Creando VM con virt-install..."
echo ""

# Crear VM con TPM 2.0 y Secure Boot (requeridos por Windows 11)
sudo virt-install \
    --name "$VM_NAME" \
    --ram "$VM_RAM" \
    --vcpus "$VM_CPUS" \
    --disk path="$DISK_PATH",format=qcow2,bus=virtio \
    --cdrom "$ISO_PATH" \
    --disk "$VIRTIO_ISO",device=cdrom \
    --os-variant win11 \
    --network network=default,model=virtio \
    --graphics spice \
    --video qxl \
    --channel spicevmc \
    --boot uefi \
    --tpm backend.type=emulator,backend.version=2.0,model=tpm-crb \
    --features smm.state=on \
    --noautoconsole

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ VM Windows 11 creada"
echo "════════════════════════════════════════════════════════"
echo ""
echo "📋 Información:"
echo ""
echo "  Nombre:     $VM_NAME"
echo "  RAM:        $VM_RAM MB"
echo "  CPUs:       $VM_CPUS"
echo "  Disco:      $VM_DISK_SIZE GB"
echo "  Estado:     Instalando (consola gráfica abierta)"
echo ""
echo "🖥️  Abrir consola gráfica:"
echo "   virt-viewer $VM_NAME"
echo "   # o desde virt-manager (GUI)"
echo ""
echo "📝 PASOS DE INSTALACIÓN:"
echo ""
echo "1. Se abrirá la ventana de instalación de Windows 11"
echo ""
echo "2. Durante la instalación, cuando pida drivers de disco:"
echo "   - Click en 'Cargar controlador'"
echo "   - Buscar en CD 'virtio-win'"
echo "   - Seleccionar: amd64/w11/viostor.inf"
echo "   - Esto permite que Windows vea el disco virtual"
echo ""
echo "3. Después de instalar Windows, instalar drivers de red:"
echo "   - Abrir 'Este equipo' → CD 'virtio-win'"
echo "   - Ejecutar: virtio-win-guest-tools.exe"
echo "   - Esto instala red, gráficos, y otros drivers"
echo ""
echo "4. Configurar red IPv6 (ver guía completa abajo)"
echo ""
echo "════════════════════════════════════════════════════════"
echo ""
echo "📖 Siguiente paso: Ver guía de configuración"
echo "   cat ~/ansible/docs/GUIA-VM-WINDOWS11.md"
echo ""

