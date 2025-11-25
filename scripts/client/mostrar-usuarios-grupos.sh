#!/bin/bash

# ════════════════════════════════════════════════════════════════
# 👥 SCRIPT PARA MOSTRAR USUARIOS Y GRUPOS - UBUNTU DESKTOP
# ════════════════════════════════════════════════════════════════

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}👥 USUARIOS Y GRUPOS CONFIGURADOS${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo ""

# ════════════════════════════════════════════════════════════════
# 1. USUARIO: ADMINISTRADOR
# ════════════════════════════════════════════════════════════════
echo -e "${YELLOW}1️⃣  USUARIO: administrador${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if id administrador &>/dev/null; then
    echo -e "${GREEN}✅ Usuario existe${NC}"
    echo ""
    echo "Grupos:"
    groups administrador
    echo ""
    echo "Detalles (UID/GID):"
    id administrador
    echo ""
    echo "Permisos sudo:"
    sudo -l -U administrador 2>/dev/null | grep -E "may run|NOPASSWD" || echo "  Sin sudo"
else
    echo -e "${RED}❌ Usuario no existe${NC}"
fi
echo ""

# ════════════════════════════════════════════════════════════════
# 2. USUARIO: AUDITOR
# ════════════════════════════════════════════════════════════════
echo -e "${YELLOW}2️⃣  USUARIO: auditor${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if id auditor &>/dev/null; then
    echo -e "${GREEN}✅ Usuario existe${NC}"
    echo ""
    echo "Grupos:"
    groups auditor
    echo ""
    echo "Detalles (UID/GID):"
    id auditor
    echo ""
    echo "Permisos sudo:"
    sudo -l -U auditor 2>/dev/null | grep -E "may run|NOPASSWD" || echo "  Sin sudo"
else
    echo -e "${RED}❌ Usuario no existe${NC}"
fi
echo ""

# ════════════════════════════════════════════════════════════════
# 3. USUARIO: GAMER01
# ════════════════════════════════════════════════════════════════
echo -e "${YELLOW}3️⃣  USUARIO: gamer01${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if id gamer01 &>/dev/null; then
    echo -e "${GREEN}✅ Usuario existe${NC}"
    echo ""
    echo "Grupos:"
    groups gamer01
    echo ""
    echo "Detalles (UID/GID):"
    id gamer01
    echo ""
    echo "Permisos sudo:"
    sudo -l -U gamer01 2>/dev/null | grep -E "may run|NOPASSWD" || echo "  Sin sudo"
else
    echo -e "${RED}❌ Usuario no existe${NC}"
fi
echo ""

# ════════════════════════════════════════════════════════════════
# 4. TODOS LOS USUARIOS DEL SISTEMA
# ════════════════════════════════════════════════════════════════
echo -e "${YELLOW}4️⃣  TODOS LOS USUARIOS (UID >= 1000)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
awk -F: '$3 >= 1000 && $3 < 65534 {print $1 " (UID: " $3 ")"}' /etc/passwd
echo ""

# ════════════════════════════════════════════════════════════════
# 5. GRUPOS IMPORTANTES
# ════════════════════════════════════════════════════════════════
echo -e "${YELLOW}5️⃣  GRUPOS IMPORTANTES${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "Grupo sudo:"
getent group sudo
echo ""

echo "Grupo adm:"
getent group adm
echo ""

echo "Grupo pcgamers:"
getent group pcgamers 2>/dev/null || echo "  Grupo no existe"
echo ""

# ════════════════════════════════════════════════════════════════
# 6. RESUMEN
# ════════════════════════════════════════════════════════════════
echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ RESUMEN DE CONFIGURACIÓN${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo ""

# Tabla resumen
echo "┌─────────────────┬──────────────────────────┬─────────────┐"
echo "│ Usuario         │ Grupos                   │ Sudo        │"
echo "├─────────────────┼──────────────────────────┼─────────────┤"

# administrador
if id administrador &>/dev/null; then
    ADMIN_GROUPS=$(groups administrador | cut -d: -f2 | xargs)
    ADMIN_SUDO=$(sudo -l -U administrador 2>/dev/null | grep -q "ALL" && echo "✅ Sí" || echo "❌ No")
    printf "│ %-15s │ %-24s │ %-11s │\n" "administrador" "${ADMIN_GROUPS:0:24}" "$ADMIN_SUDO"
fi

# auditor
if id auditor &>/dev/null; then
    AUDITOR_GROUPS=$(groups auditor | cut -d: -f2 | xargs)
    AUDITOR_SUDO=$(sudo -l -U auditor 2>/dev/null | grep -q "may run" && echo "⚠️  Limitado" || echo "❌ No")
    printf "│ %-15s │ %-24s │ %-11s │\n" "auditor" "${AUDITOR_GROUPS:0:24}" "$AUDITOR_SUDO"
fi

# gamer01
if id gamer01 &>/dev/null; then
    GAMER_GROUPS=$(groups gamer01 | cut -d: -f2 | xargs)
    GAMER_SUDO=$(sudo -l -U gamer01 2>/dev/null | grep -q "may run" && echo "✅ Sí" || echo "❌ No")
    printf "│ %-15s │ %-24s │ %-11s │\n" "gamer01" "${GAMER_GROUPS:0:24}" "$GAMER_SUDO"
fi

echo "└─────────────────┴──────────────────────────┴─────────────┘"
echo ""

echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
