#!/bin/bash

# ════════════════════════════════════════════════════════════════
# 💾 SCRIPT PARA MOSTRAR PARTICIONES - UBUNTU DESKTOP
# ════════════════════════════════════════════════════════════════

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}💾 INFORMACIÓN DE PARTICIONES Y ALMACENAMIENTO${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo ""

# ════════════════════════════════════════════════════════════════
# 1. VISTA GENERAL DE DISCOS
# ════════════════════════════════════════════════════════════════
echo -e "${YELLOW}1️⃣  DISCOS Y PARTICIONES (lsblk)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT
echo ""

# ════════════════════════════════════════════════════════════════
# 2. USO DE DISCO
# ════════════════════════════════════════════════════════════════
echo -e "${YELLOW}2️⃣  USO DE DISCO (df -h)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
df -h | grep -E "Filesystem|/dev/"
echo ""

# ════════════════════════════════════════════════════════════════
# 3. DETALLES DE PARTICIONES
# ════════════════════════════════════════════════════════════════
echo -e "${YELLOW}3️⃣  DETALLES DE PARTICIONES (fdisk -l)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
sudo fdisk -l | grep -E "Disk /dev|Device|/dev/sd|/dev/nvme"
echo ""

# ════════════════════════════════════════════════════════════════
# 4. UUID DE PARTICIONES
# ════════════════════════════════════════════════════════════════
echo -e "${YELLOW}4️⃣  UUID DE PARTICIONES (blkid)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
sudo blkid | grep -E "/dev/sd|/dev/nvme"
echo ""

# ════════════════════════════════════════════════════════════════
# 5. MONTAJES ACTIVOS
# ════════════════════════════════════════════════════════════════
echo -e "${YELLOW}5️⃣  MONTAJES ACTIVOS (mount)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
mount | grep -E "^/dev/" | column -t
echo ""

# ════════════════════════════════════════════════════════════════
# 6. INFORMACIÓN DE SWAP
# ════════════════════════════════════════════════════════════════
echo -e "${YELLOW}6️⃣  MEMORIA SWAP${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
swapon --show
free -h | grep -E "Mem|Swap"
echo ""

# ════════════════════════════════════════════════════════════════
# 7. RESUMEN
# ════════════════════════════════════════════════════════════════
echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ RESUMEN${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"

# Contar discos
DISK_COUNT=$(lsblk -d -n | grep -c "disk")
echo "  💾 Discos físicos: $DISK_COUNT"

# Contar particiones
PART_COUNT=$(lsblk -n | grep -c "part")
echo "  📁 Particiones: $PART_COUNT"

# Espacio total
TOTAL_SIZE=$(df -h --total | grep "total" | awk '{print $2}')
echo "  📊 Espacio total: $TOTAL_SIZE"

# Espacio usado
USED_SIZE=$(df -h --total | grep "total" | awk '{print $3}')
echo "  📈 Espacio usado: $USED_SIZE"

# Espacio libre
FREE_SIZE=$(df -h --total | grep "total" | awk '{print $4}')
echo "  📉 Espacio libre: $FREE_SIZE"

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
