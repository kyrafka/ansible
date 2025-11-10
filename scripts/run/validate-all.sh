#!/bin/bash
# Script para validar TODA la configuración del servidor
# Ejecutar: bash scripts/run/validate-all.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "════════════════════════════════════════════════════════"
echo "🔍 Validación Completa del Servidor GameCenter"
echo "════════════════════════════════════════════════════════"
echo ""

TOTAL=0
PASSED=0

# Ejecutar cada validación
echo "1️⃣  Validando Paquetes Base..."
if bash "$SCRIPT_DIR/validate-common.sh"; then
    ((PASSED++))
fi
((TOTAL++))
echo ""

echo "2️⃣  Validando Red IPv6..."
if bash "$SCRIPT_DIR/validate-network.sh"; then
    ((PASSED++))
fi
((TOTAL++))
echo ""

echo "3️⃣  Validando DNS..."
if bash "$SCRIPT_DIR/validate-dns.sh"; then
    ((PASSED++))
fi
((TOTAL++))
echo ""

echo "4️⃣  Validando DHCPv6..."
if bash "$SCRIPT_DIR/validate-dhcp.sh"; then
    ((PASSED++))
fi
((TOTAL++))
echo ""

echo "5️⃣  Validando Firewall..."
if bash "$SCRIPT_DIR/validate-firewall.sh"; then
    ((PASSED++))
fi
((TOTAL++))
echo ""

echo "6️⃣  Validando NFS..."
if bash "$SCRIPT_DIR/validate-storage.sh"; then
    ((PASSED++))
fi
((TOTAL++))
echo ""

# Resumen final
echo "════════════════════════════════════════════════════════"
echo "📊 Resumen de Validación"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Componentes validados: $PASSED/$TOTAL"
echo ""

if [ $PASSED -eq $TOTAL ]; then
    echo "✅ ¡Servidor completamente configurado y funcional!"
    echo ""
    echo "Servicios activos:"
    echo "  🌐 Red IPv6: 2025:db8:10::/64"
    echo "  🔍 DNS: puerto 53"
    echo "  📡 DHCPv6: puerto 547"
    echo "  🔥 Firewall: UFW + fail2ban"
    echo "  📂 NFS: /srv/nfs/games, /srv/nfs/shared"
    exit 0
else
    FAILED=$((TOTAL - PASSED))
    echo "❌ Hay $FAILED componentes con problemas"
    echo ""
    echo "Ejecuta los scripts individuales para más detalles:"
    echo "  bash scripts/run/validate-common.sh"
    echo "  bash scripts/run/validate-network.sh"
    echo "  bash scripts/run/validate-dns.sh"
    echo "  bash scripts/run/validate-dhcp.sh"
    echo "  bash scripts/run/validate-firewall.sh"
    echo "  bash scripts/run/validate-storage.sh"
    exit 1
fi
