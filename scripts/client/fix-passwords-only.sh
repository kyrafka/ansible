#!/bin/bash

echo "════════════════════════════════════════════════════════════════"
echo "🔑 ARREGLAR CONTRASEÑAS DE USUARIOS EXISTENTES"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "⚠️  Este script SOLO cambia contraseñas, NO toca datos ni archivos"
echo ""

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script debe ejecutarse como root"
    echo "   Usa: sudo bash $0"
    exit 1
fi

echo "Cambiando contraseñas..."
echo ""

# Cambiar contraseña de auditor (si existe)
if id auditor &>/dev/null; then
    echo "auditor:Audit123!" | chpasswd
    echo "✓ Contraseña de auditor cambiada: Audit123!"
else
    echo "⚠️  Usuario auditor no existe"
fi

# Cambiar contraseña de gamer01 (si existe)
if id gamer01 &>/dev/null; then
    echo "gamer01:Game123!" | chpasswd
    echo "✓ Contraseña de gamer01 cambiada: Game123!"
else
    echo "⚠️  Usuario gamer01 no existe"
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✅ CONTRASEÑAS ACTUALIZADAS"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "🔑 Nuevas contraseñas:"
echo "  - auditor: Audit123!"
echo "  - gamer01: Game123!"
echo ""
echo "⚠️  NO se tocaron archivos ni datos de los usuarios"
echo "════════════════════════════════════════════════════════════════"
