#!/bin/bash
# Script para validar el firewall (UFW + fail2ban)
# Ejecutar: bash scripts/run/validate-firewall.sh

echo "════════════════════════════════════════════════════════"
echo "🔍 Validando Firewall (UFW + fail2ban)"
echo "════════════════════════════════════════════════════════"
echo ""

ERRORS=0

# Verificar UFW
echo "🔥 UFW:"
if systemctl is-active --quiet ufw; then
    echo "✅ UFW está activo"
else
    echo "❌ UFW NO está activo"
    ((ERRORS++))
fi

if sudo ufw status | grep -q "Status: active"; then
    echo "✅ UFW habilitado"
else
    echo "❌ UFW deshabilitado"
    ((ERRORS++))
fi

echo ""
echo "📋 Reglas UFW importantes:"
if sudo ufw status | grep -q "22/tcp"; then
    echo "✅ SSH (22) permitido"
else
    echo "❌ SSH (22) NO permitido"
    ((ERRORS++))
fi

if sudo ufw status | grep -q "53"; then
    echo "✅ DNS (53) permitido"
else
    echo "⚠️  DNS (53) no configurado"
fi

if sudo ufw status | grep -q "547"; then
    echo "✅ DHCPv6 (547) permitido"
else
    echo "⚠️  DHCPv6 (547) no configurado"
fi

echo ""
echo "🛡️  fail2ban:"
if systemctl is-active --quiet fail2ban; then
    echo "✅ fail2ban está activo"
else
    echo "❌ fail2ban NO está activo"
    ((ERRORS++))
fi

if systemctl is-enabled --quiet fail2ban; then
    echo "✅ fail2ban habilitado al inicio"
else
    echo "❌ fail2ban NO habilitado al inicio"
    ((ERRORS++))
fi

echo ""
if [ $ERRORS -eq 0 ]; then
    echo "✅ Firewall configurado correctamente"
    exit 0
else
    echo "❌ Hay $ERRORS problemas de configuración"
    exit 1
fi
