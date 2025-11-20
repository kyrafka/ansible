#!/bin/bash

echo "════════════════════════════════════════════════════════════════"
echo "💾 CREAR PARTICIONES PARA WINDOWS 11"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script debe ejecutarse como root"
    echo "   Usa: sudo bash $0"
    exit 1
fi

echo "⚠️  ADVERTENCIA: Este script modificará las particiones del disco"
echo "   Asegúrate de tener respaldo de datos importantes"
echo ""
read -p "¿Continuar? (escribe SI en mayúsculas): " confirm

if [ "$confirm" != "SI" ]; then
    echo "❌ Operación cancelada"
    exit 1
fi

echo ""
echo "Paso 1: Verificando discos disponibles"
echo "────────────────────────────────────────────────────────"

lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT

echo ""
echo "Discos detectados:"
fdisk -l | grep "Disk /dev/sd" | grep -v "loop"

echo ""
read -p "¿En qué disco quieres crear la partición? (ejemplo: sda, sdb, vda): " DISK

if [ ! -b "/dev/$DISK" ]; then
    echo "❌ El disco /dev/$DISK no existe"
    exit 1
fi

echo ""
echo "Información del disco /dev/$DISK:"
fdisk -l /dev/$DISK

echo ""
read -p "¿Cuántos GB quieres para Windows 11? (mínimo 45 GB): " SIZE_GB

if [ "$SIZE_GB" -lt 45 ]; then
    echo "❌ Windows 11 necesita mínimo 45 GB"
    exit 1
fi

echo ""
echo "Paso 2: Verificando espacio disponible"
echo "────────────────────────────────────────────────────────"

# Verificar espacio libre
FREE_SPACE=$(parted /dev/$DISK unit GB print free | grep "Free Space" | tail -1 | awk '{print $3}' | sed 's/GB//')

if [ -z "$FREE_SPACE" ]; then
    echo "❌ No se pudo determinar el espacio libre"
    exit 1
fi

echo "Espacio libre: ${FREE_SPACE}GB"
echo "Espacio solicitado: ${SIZE_GB}GB"

if (( $(echo "$FREE_SPACE < $SIZE_GB" | bc -l) )); then
    echo "❌ No hay suficiente espacio libre"
    exit 1
fi

echo "✓ Hay suficiente espacio"

echo ""
echo "Paso 3: Creando partición para Windows 11"
echo "────────────────────────────────────────────────────────"

# Obtener el número de la siguiente partición
NEXT_PART=$(parted /dev/$DISK print | grep "^ " | tail -1 | awk '{print $1}')
NEXT_PART=$((NEXT_PART + 1))

echo "Se creará la partición /dev/${DISK}${NEXT_PART}"
echo ""

# Crear partición con parted
parted /dev/$DISK --script mkpart primary ntfs 0% ${SIZE_GB}GB

if [ $? -ne 0 ]; then
    echo "❌ Error al crear la partición"
    exit 1
fi

echo "✓ Partición creada"

# Esperar a que el kernel reconozca la partición
sleep 2
partprobe /dev/$DISK
sleep 2

echo ""
echo "Paso 4: Formateando partición como NTFS"
echo "────────────────────────────────────────────────────────"

# Instalar ntfs-3g si no está
if ! command -v mkfs.ntfs &>/dev/null; then
    echo "Instalando ntfs-3g..."
    apt update &>/dev/null
    apt install -y ntfs-3g &>/dev/null
fi

# Formatear como NTFS
mkfs.ntfs -f -L "Windows11" /dev/${DISK}${NEXT_PART}

if [ $? -ne 0 ]; then
    echo "❌ Error al formatear la partición"
    exit 1
fi

echo "✓ Partición formateada como NTFS"

echo ""
echo "Paso 5: Verificando partición creada"
echo "────────────────────────────────────────────────────────"

lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINT | grep -A 10 "$DISK"

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✅ PARTICIÓN PARA WINDOWS 11 CREADA EXITOSAMENTE"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "📋 Información:"
echo "  Disco: /dev/$DISK"
echo "  Partición: /dev/${DISK}${NEXT_PART}"
echo "  Tamaño: ${SIZE_GB}GB"
echo "  Sistema de archivos: NTFS"
echo "  Etiqueta: Windows11"
echo ""
echo "🔄 Ahora puedes:"
echo "  1. Reiniciar desde el USB de Windows 11"
echo "  2. En el instalador, seleccionar la partición 'Windows11'"
echo "  3. Instalar Windows 11 normalmente"
echo ""
echo "⚠️  IMPORTANTE:"
echo "  - NO formatees otras particiones en el instalador"
echo "  - Selecciona SOLO la partición 'Windows11'"
echo "  - Después de instalar, configura el dual boot con GRUB"
echo ""
echo "════════════════════════════════════════════════════════════════"
