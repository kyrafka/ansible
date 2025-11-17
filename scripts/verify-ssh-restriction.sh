#!/bin/bash
# Script para verificar y forzar restricción SSH

echo "════════════════════════════════════════════════════════"
echo "🔍 Verificando restricción SSH"
echo "════════════════════════════════════════════════════════"
echo ""

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script debe ejecutarse como root"
    echo "   Usa: sudo bash $0"
    exit 1
fi

echo "1️⃣  Verificando configuración actual..."
echo ""

CURRENT_CONFIG=$(grep "^AllowUsers" /etc/ssh/sshd_config 2>/dev/null)

if [ -z "$CURRENT_CONFIG" ]; then
    echo "  ❌ AllowUsers NO está configurado"
    echo "  → Cualquier usuario puede SSH"
else
    echo "  ✓ Configuración encontrada:"
    echo "    $CURRENT_CONFIG"
fi

echo ""
echo "2️⃣  Aplicando configuración correcta..."

# Eliminar todas las líneas AllowUsers
sed -i '/^AllowUsers/d' /etc/ssh/sshd_config
sed -i '/^#AllowUsers/d' /etc/ssh/sshd_config

# Agregar al final del archivo
echo "" >> /etc/ssh/sshd_config
echo "# Restricción de usuarios SSH - Solo administradores" >> /etc/ssh/sshd_config
echo "AllowUsers ubuntu administrador" >> /etc/ssh/sshd_config

echo "  ✓ Configuración aplicada"

echo ""
echo "3️⃣  Verificando sintaxis..."
if sshd -t 2>&1; then
    echo "  ✓ Configuración válida"
else
    echo "  ❌ Error en configuración"
    exit 1
fi

echo ""
echo "4️⃣  Reiniciando SSH..."
systemctl restart sshd
sleep 2

if systemctl is-active --quiet sshd; then
    echo "  ✓ SSH reiniciado correctamente"
else
    echo "  ❌ Error al reiniciar SSH"
    systemctl status sshd
    exit 1
fi

echo ""
echo "5️⃣  Verificación final..."
FINAL_CONFIG=$(grep "^AllowUsers" /etc/ssh/sshd_config)
echo "  Configuración activa:"
echo "    $FINAL_CONFIG"

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ Restricción SSH aplicada"
echo "════════════════════════════════════════════════════════"
echo ""
echo "📋 Usuarios permitidos:"
echo "  ✅ ubuntu"
echo "  ✅ administrador"
echo ""
echo "❌ Usuarios bloqueados:"
echo "  ❌ auditor"
echo "  ❌ gamer01"
echo "  ❌ root"
echo "  ❌ cualquier otro usuario"
echo ""
echo "🧪 Probar desde la VM:"
echo "  ssh ubuntu@2025:db8:10::2        # ✅ Debe funcionar"
echo "  ssh auditor@2025:db8:10::2       # ❌ Debe fallar"
echo ""
echo "════════════════════════════════════════════════════════"
