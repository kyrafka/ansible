#!/bin/bash
# Script para restringir acceso SSH en el servidor

# Auto-permisos
[ ! -x "$0" ] && chmod +x "$0" 2>/dev/null

set -e

echo "════════════════════════════════════════════════════════"
echo "🔒 Restringiendo acceso SSH"
echo "════════════════════════════════════════════════════════"
echo ""

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script debe ejecutarse como root"
    echo "   Usa: sudo bash $0"
    exit 1
fi

echo "1️⃣  Configurando SSH para permitir solo usuarios autorizados..."

# Backup de configuración actual
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)

# Eliminar AllowUsers existente si hay
sed -i '/^AllowUsers/d' /etc/ssh/sshd_config

# Agregar AllowUsers al final
echo "" >> /etc/ssh/sshd_config
echo "# Usuarios autorizados para SSH" >> /etc/ssh/sshd_config
echo "AllowUsers ubuntu administrador" >> /etc/ssh/sshd_config

echo "  ✓ Configuración actualizada"

echo ""
echo "2️⃣  Verificando configuración..."
if sshd -t; then
    echo "  ✓ Configuración válida"
else
    echo "  ❌ Error en configuración, restaurando backup..."
    cp /etc/ssh/sshd_config.backup.* /etc/ssh/sshd_config
    exit 1
fi

echo ""
echo "3️⃣  Reiniciando servicio SSH..."
systemctl restart ssh

if systemctl is-active --quiet ssh; then
    echo "  ✓ SSH reiniciado correctamente"
else
    echo "  ❌ Error al reiniciar SSH"
    exit 1
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ Acceso SSH restringido"
echo "════════════════════════════════════════════════════════"
echo ""
echo "📋 Usuarios autorizados para SSH:"
echo "  • ubuntu (servidor)"
echo "  • administrador (desde VMs)"
echo ""
echo "❌ Usuarios bloqueados:"
echo "  • auditor"
echo "  • gamer01"
echo "  • root"
echo ""
echo "🧪 Probar desde la VM:"
echo "  ssh ubuntu@2025:db8:10::2        # ✅ Debe funcionar (administrador)"
echo "  ssh auditor@2025:db8:10::2       # ❌ Debe fallar (auditor)"
echo ""
echo "════════════════════════════════════════════════════════"
