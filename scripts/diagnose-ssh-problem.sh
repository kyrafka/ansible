#!/bin/bash
# Script para diagnosticar por qué auditor puede SSH

echo "════════════════════════════════════════════════════════"
echo "🔍 Diagnóstico SSH - ¿Por qué auditor puede conectarse?"
echo "════════════════════════════════════════════════════════"
echo ""

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script debe ejecutarse como root"
    echo "   Usa: sudo bash $0"
    exit 1
fi

echo "1️⃣  Verificando configuración de SSH..."
echo ""

# Buscar AllowUsers en el archivo principal
echo "📄 Archivo: /etc/ssh/sshd_config"
if grep -q "^AllowUsers" /etc/ssh/sshd_config; then
    echo "  ✓ AllowUsers encontrado:"
    grep "^AllowUsers" /etc/ssh/sshd_config | sed 's/^/    /'
else
    echo "  ❌ AllowUsers NO encontrado"
    echo "  → Esto permite que CUALQUIER usuario se conecte"
fi

echo ""

# Buscar en archivos de configuración adicionales
echo "📁 Archivos en /etc/ssh/sshd_config.d/"
if [ -d "/etc/ssh/sshd_config.d" ]; then
    if ls /etc/ssh/sshd_config.d/*.conf 2>/dev/null; then
        for file in /etc/ssh/sshd_config.d/*.conf; do
            echo "  Archivo: $file"
            if grep -q "AllowUsers" "$file"; then
                grep "AllowUsers" "$file" | sed 's/^/    /'
            fi
        done
    else
        echo "  (vacío)"
    fi
fi

echo ""
echo "2️⃣  Verificando estado del servicio SSH..."
echo ""

if systemctl is-active --quiet sshd; then
    echo "  ✓ SSH está corriendo"
elif systemctl is-active --quiet ssh; then
    echo "  ✓ SSH está corriendo (servicio 'ssh')"
else
    echo "  ❌ SSH NO está corriendo"
fi

echo ""
echo "3️⃣  Verificando sintaxis de configuración..."
echo ""

if sshd -t 2>&1; then
    echo "  ✓ Configuración válida"
else
    echo "  ❌ Error en configuración:"
    sshd -t 2>&1 | sed 's/^/    /'
fi

echo ""
echo "4️⃣  Verificando usuarios del sistema..."
echo ""

echo "  Usuarios que existen:"
for user in ubuntu administrador auditor gamer01; do
    if id "$user" &>/dev/null; then
        echo "    ✓ $user"
    else
        echo "    ❌ $user (no existe)"
    fi
done

echo ""
echo "5️⃣  Verificando configuración efectiva de SSH..."
echo ""

echo "  Configuración que SSH está usando:"
sshd -T | grep -i allowusers | sed 's/^/    /'

echo ""
echo "════════════════════════════════════════════════════════"
echo "📊 DIAGNÓSTICO"
echo "════════════════════════════════════════════════════════"
echo ""

# Determinar el problema
ALLOW_USERS=$(grep "^AllowUsers" /etc/ssh/sshd_config 2>/dev/null)
EFFECTIVE_CONFIG=$(sshd -T | grep -i allowusers)

if [ -z "$ALLOW_USERS" ]; then
    echo "❌ PROBLEMA ENCONTRADO:"
    echo "   AllowUsers NO está configurado en /etc/ssh/sshd_config"
    echo ""
    echo "💡 SOLUCIÓN:"
    echo "   Ejecutar: sudo bash scripts/verify-ssh-restriction.sh"
elif [[ "$ALLOW_USERS" != *"ubuntu"* ]] || [[ "$ALLOW_USERS" != *"administrador"* ]]; then
    echo "❌ PROBLEMA ENCONTRADO:"
    echo "   AllowUsers está mal configurado"
    echo "   Actual: $ALLOW_USERS"
    echo "   Esperado: AllowUsers ubuntu administrador"
    echo ""
    echo "💡 SOLUCIÓN:"
    echo "   Ejecutar: sudo bash scripts/verify-ssh-restriction.sh"
elif [ -z "$EFFECTIVE_CONFIG" ]; then
    echo "⚠️  ADVERTENCIA:"
    echo "   SSH no está aplicando la restricción AllowUsers"
    echo "   Esto puede ser por un archivo en /etc/ssh/sshd_config.d/"
    echo ""
    echo "💡 SOLUCIÓN:"
    echo "   1. Revisar archivos en /etc/ssh/sshd_config.d/"
    echo "   2. Ejecutar: sudo bash scripts/verify-ssh-restriction.sh"
else
    echo "✅ Configuración correcta"
    echo "   $ALLOW_USERS"
    echo ""
    echo "⚠️  Si auditor aún puede conectarse:"
    echo "   1. Reiniciar SSH: sudo systemctl restart sshd"
    echo "   2. Verificar desde la VM: ssh auditor@2025:db8:10::2"
fi

echo ""
echo "════════════════════════════════════════════════════════"
