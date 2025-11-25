#!/bin/bash

# ════════════════════════════════════════════════════════════════
# 💾 SCRIPT PARA CONFIGURAR PARTICIONES - UBUNTU DESKTOP
# ════════════════════════════════════════════════════════════════
# ESQUEMA RECOMENDADO:
#   sda1: 1G    - /boot/efi  (ya existe)
#   sda2: 18G   - /          (sistema + aplicaciones)
#   sda3: 11G   - /home      (usuarios: administrador, auditor, gamer01)
# ════════════════════════════════════════════════════════════════

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ Este script debe ejecutarse como root${NC}"
    echo "Usa: sudo bash $0"
    exit 1
fi

clear
echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}💾 CONFIGURACIÓN DE PARTICIONES - UBUNTU DESKTOP${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}⚠️  ADVERTENCIA: Este proceso modificará las particiones${NC}"
echo -e "${YELLOW}   Asegúrate de tener un respaldo de tus datos importantes${NC}"
echo ""

# Mostrar estado actual
echo -e "${CYAN}📊 Estado actual de particiones:${NC}"
echo ""
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT | grep -E "NAME|sda"
echo ""

# Mostrar esquema propuesto
echo -e "${CYAN}📋 Esquema propuesto:${NC}"
echo ""
echo "  sda1:  1G   - /boot/efi  (EFI - ya existe)"
echo "  sda2: 18G   - /          (Sistema raíz)"
echo "  sda3: 11G   - /home      (Datos de usuarios)"
echo ""

# Confirmar
read -p "¿Deseas continuar? (escribe 'SI' para confirmar): " CONFIRM
if [ "$CONFIRM" != "SI" ]; then
    echo -e "${YELLOW}❌ Operación cancelada${NC}"
    exit 0
fi

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}🚀 INICIANDO CONFIGURACIÓN...${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo ""

# ════════════════════════════════════════════════════════════════
# PASO 1: CREAR NUEVA PARTICIÓN /home
# ════════════════════════════════════════════════════════════════
echo -e "${YELLOW}1️⃣  Creando partición /home (sda3)...${NC}"

# Redimensionar sda2 y crear sda3
parted /dev/sda --script \
    resizepart 2 18GB \
    mkpart primary ext4 18GB 100%

if [ $? -eq 0 ]; then
    echo -e "${GREEN}   ✅ Partición sda3 creada${NC}"
else
    echo -e "${RED}   ❌ Error al crear partición${NC}"
    exit 1
fi
echo ""

# ════════════════════════════════════════════════════════════════
# PASO 2: FORMATEAR NUEVA PARTICIÓN
# ════════════════════════════════════════════════════════════════
echo -e "${YELLOW}2️⃣  Formateando /dev/sda3 como ext4...${NC}"

mkfs.ext4 -F /dev/sda3

if [ $? -eq 0 ]; then
    echo -e "${GREEN}   ✅ Partición formateada${NC}"
else
    echo -e "${RED}   ❌ Error al formatear${NC}"
    exit 1
fi
echo ""

# ════════════════════════════════════════════════════════════════
# PASO 3: COPIAR DATOS DE /home ACTUAL
# ════════════════════════════════════════════════════════════════
echo -e "${YELLOW}3️⃣  Copiando datos de /home actual...${NC}"

# Crear punto de montaje temporal
mkdir -p /mnt/newhome

# Montar nueva partición
mount /dev/sda3 /mnt/newhome

# Copiar datos
rsync -avxHAX /home/ /mnt/newhome/

if [ $? -eq 0 ]; then
    echo -e "${GREEN}   ✅ Datos copiados${NC}"
else
    echo -e "${RED}   ❌ Error al copiar datos${NC}"
    exit 1
fi
echo ""

# ════════════════════════════════════════════════════════════════
# PASO 4: ACTUALIZAR /etc/fstab
# ════════════════════════════════════════════════════════════════
echo -e "${YELLOW}4️⃣  Actualizando /etc/fstab...${NC}"

# Obtener UUID de la nueva partición
NEW_HOME_UUID=$(blkid -s UUID -o value /dev/sda3)

# Hacer backup de fstab
cp /etc/fstab /etc/fstab.backup

# Agregar entrada para /home
echo "UUID=$NEW_HOME_UUID  /home  ext4  defaults  0  2" >> /etc/fstab

echo -e "${GREEN}   ✅ /etc/fstab actualizado${NC}"
echo -e "${CYAN}   UUID: $NEW_HOME_UUID${NC}"
echo ""

# ════════════════════════════════════════════════════════════════
# PASO 5: VERIFICAR CONFIGURACIÓN
# ════════════════════════════════════════════════════════════════
echo -e "${YELLOW}5️⃣  Verificando configuración...${NC}"

# Desmontar temporal
umount /mnt/newhome

# Montar /home desde fstab
mount -a

if [ $? -eq 0 ]; then
    echo -e "${GREEN}   ✅ Montaje exitoso${NC}"
else
    echo -e "${RED}   ❌ Error al montar${NC}"
    exit 1
fi
echo ""

# ════════════════════════════════════════════════════════════════
# RESUMEN FINAL
# ════════════════════════════════════════════════════════════════
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ CONFIGURACIÓN COMPLETADA${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${CYAN}📊 Nuevas particiones:${NC}"
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT | grep -E "NAME|sda"
echo ""

echo -e "${CYAN}💾 Uso de disco:${NC}"
df -h | grep -E "Filesystem|/dev/sda"
echo ""

echo -e "${CYAN}📝 Archivo /etc/fstab:${NC}"
cat /etc/fstab | grep -v "^#" | grep -v "^$"
echo ""

echo -e "${YELLOW}⚠️  IMPORTANTE:${NC}"
echo "  1. Reinicia el sistema para aplicar todos los cambios"
echo "  2. Verifica que /home se monte correctamente después del reinicio"
echo "  3. Si todo funciona, puedes eliminar el backup: /etc/fstab.backup"
echo ""

echo -e "${GREEN}🎉 ¡Particiones configuradas exitosamente!${NC}"
echo ""
