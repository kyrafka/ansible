#!/bin/bash

echo "════════════════════════════════════════════════════════════════"
echo "🔐 VERIFICACIÓN DE PERMISOS Y RESTRICCIONES DE USUARIOS"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script debe ejecutarse como root"
    echo "   Usa: sudo bash $0"
    exit 1
fi

echo "═══════════════════════════════════════════════════════════════"
echo "👤 USUARIO: ADMINISTRADOR"
echo "═══════════════════════════════════════════════════════════════"

if id administrador &>/dev/null; then
    echo "✓ Usuario existe"
    echo ""
    
    echo "📋 Grupos:"
    groups administrador
    echo ""
    
    echo "🔑 Permisos sudo:"
    if sudo -l -U administrador 2>/dev/null | grep -q "(ALL)"; then
        echo "  ✓ Tiene permisos sudo COMPLETOS"
    else
        echo "  ⚠️  No tiene permisos sudo"
    fi
    echo ""
    
    echo "📁 Carpeta home:"
    ls -ld /home/administrador
    echo ""
    
    echo "📂 Acceso a carpetas importantes:"
    echo -n "  /mnt/games: "
    if sudo -u administrador test -r /mnt/games 2>/dev/null; then
        echo "✓ Lectura OK"
    else
        echo "❌ Sin acceso"
    fi
    
    echo -n "  /home/gamer01: "
    if sudo -u administrador test -r /home/gamer01 2>/dev/null; then
        echo "✓ Lectura OK (es admin)"
    else
        echo "❌ Sin acceso"
    fi
else
    echo "❌ Usuario NO existe"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "🎮 USUARIO: GAMER01"
echo "═══════════════════════════════════════════════════════════════"

if id gamer01 &>/dev/null; then
    echo "✓ Usuario existe"
    echo ""
    
    echo "📋 Grupos:"
    groups gamer01
    echo ""
    
    echo "🔑 Permisos sudo:"
    if sudo -l -U gamer01 2>/dev/null | grep -q "(ALL)"; then
        echo "  ⚠️  TIENE permisos sudo (NO DEBERÍA)"
    else
        echo "  ✓ NO tiene permisos sudo (correcto)"
    fi
    echo ""
    
    echo "📁 Carpeta home:"
    ls -ld /home/gamer01
    echo ""
    
    echo "📂 Contenido de home:"
    ls -la /home/gamer01 | head -15
    echo ""
    
    echo "📂 Acceso a carpetas:"
    echo -n "  /mnt/games: "
    if sudo -u gamer01 test -r /mnt/games 2>/dev/null; then
        echo -n "✓ Lectura "
        if sudo -u gamer01 test -w /mnt/games 2>/dev/null; then
            echo "✓ Escritura"
        else
            echo "❌ Sin escritura"
        fi
    else
        echo "❌ Sin acceso"
    fi
    
    echo -n "  /home/auditor: "
    if sudo -u gamer01 test -r /home/auditor 2>/dev/null; then
        echo "⚠️  Tiene acceso (NO DEBERÍA)"
    else
        echo "✓ Sin acceso (correcto)"
    fi
    
    echo -n "  /home/administrador: "
    if sudo -u gamer01 test -r /home/administrador 2>/dev/null; then
        echo "⚠️  Tiene acceso (NO DEBERÍA)"
    else
        echo "✓ Sin acceso (correcto)"
    fi
    
    echo ""
    echo "🎮 Permisos en /mnt/games:"
    ls -ld /mnt/games 2>/dev/null || echo "  ❌ Carpeta no existe"
    
else
    echo "❌ Usuario NO existe"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "📊 USUARIO: AUDITOR"
echo "═══════════════════════════════════════════════════════════════"

if id auditor &>/dev/null; then
    echo "✓ Usuario existe"
    echo ""
    
    echo "📋 Grupos:"
    groups auditor
    echo ""
    
    echo "🔑 Permisos sudo:"
    if sudo -l -U auditor 2>/dev/null | grep -q "(ALL)"; then
        echo "  ⚠️  TIENE permisos sudo (NO DEBERÍA)"
    else
        echo "  ✓ NO tiene permisos sudo (correcto)"
    fi
    echo ""
    
    echo "📁 Carpeta home:"
    ls -ld /home/auditor
    echo ""
    
    echo "📂 Contenido de home:"
    ls -la /home/auditor | head -15
    echo ""
    
    echo "📂 Acceso a carpetas:"
    echo -n "  /var/log: "
    if sudo -u auditor test -r /var/log 2>/dev/null; then
        echo "✓ Lectura OK"
    else
        echo "❌ Sin acceso"
    fi
    
    echo -n "  /home/gamer01: "
    if sudo -u auditor test -r /home/gamer01 2>/dev/null; then
        echo "⚠️  Tiene acceso (NO DEBERÍA)"
    else
        echo "✓ Sin acceso (correcto)"
    fi
    
    echo -n "  /home/administrador: "
    if sudo -u auditor test -r /home/administrador 2>/dev/null; then
        echo "⚠️  Tiene acceso (NO DEBERÍA)"
    else
        echo "✓ Sin acceso (correcto)"
    fi
    
    echo -n "  /mnt/games: "
    if sudo -u auditor test -r /mnt/games 2>/dev/null; then
        echo "⚠️  Tiene acceso (puede ser correcto si es auditor)"
    else
        echo "✓ Sin acceso"
    fi
    
else
    echo "❌ Usuario NO existe"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "🔒 VERIFICACIÓN DE SEGURIDAD"
echo "═══════════════════════════════════════════════════════════════"

echo ""
echo "📋 Usuarios con sudo:"
grep -Po '^sudo.+:\K.*$' /etc/group

echo ""
echo "📋 Archivo sudoers:"
if grep -E "gamer01|auditor" /etc/sudoers /etc/sudoers.d/* 2>/dev/null; then
    echo "  ⚠️  gamer01 o auditor tienen entradas en sudoers"
else
    echo "  ✓ gamer01 y auditor NO están en sudoers"
fi

echo ""
echo "📁 Permisos de carpetas compartidas:"
if [ -d "/mnt/games" ]; then
    ls -ld /mnt/games
    echo ""
    echo "  Contenido:"
    ls -la /mnt/games 2>/dev/null | head -10
else
    echo "  ❌ /mnt/games no existe"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "📊 RESUMEN DE SEGURIDAD"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Verificar configuración correcta
ISSUES=0

# Verificar sudo
if sudo -l -U gamer01 2>/dev/null | grep -q "(ALL)"; then
    echo "❌ gamer01 tiene sudo (PROBLEMA)"
    ISSUES=$((ISSUES+1))
else
    echo "✓ gamer01 sin sudo"
fi

if sudo -l -U auditor 2>/dev/null | grep -q "(ALL)"; then
    echo "❌ auditor tiene sudo (PROBLEMA)"
    ISSUES=$((ISSUES+1))
else
    echo "✓ auditor sin sudo"
fi

# Verificar permisos de home
if sudo -u gamer01 test -r /home/auditor 2>/dev/null; then
    echo "❌ gamer01 puede leer /home/auditor (PROBLEMA)"
    ISSUES=$((ISSUES+1))
else
    echo "✓ gamer01 no puede leer /home/auditor"
fi

if sudo -u auditor test -r /home/gamer01 2>/dev/null; then
    echo "❌ auditor puede leer /home/gamer01 (PROBLEMA)"
    ISSUES=$((ISSUES+1))
else
    echo "✓ auditor no puede leer /home/gamer01"
fi

echo ""
if [ $ISSUES -eq 0 ]; then
    echo "✅ CONFIGURACIÓN DE SEGURIDAD CORRECTA"
else
    echo "⚠️  SE ENCONTRARON $ISSUES PROBLEMAS DE SEGURIDAD"
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
