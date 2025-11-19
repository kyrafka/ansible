#!/bin/bash
# Script para arreglar contraseñas de login y eliminar usuarios no deseados

echo "════════════════════════════════════════════════════════"
echo "🔧 Arreglando contraseñas y usuarios"
echo "════════════════════════════════════════════════════════"
echo ""

# Verificar si somos root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script debe ejecutarse como root"
    echo "   Usa: sudo bash $0"
    exit 1
fi

echo "📋 Usuarios actuales en el sistema:"
cat /etc/passwd | grep -E "/home/" | cut -d: -f1 | sed 's/^/   /'
echo ""

echo "════════════════════════════════════════════════════════"
echo "🔑 OPCIÓN 1: Resetear contraseña del usuario 'ubuntu'"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Esto te permitirá establecer una nueva contraseña para 'ubuntu'"
read -p "¿Resetear contraseña de ubuntu? (s/n): " reset_ubuntu

if [ "$reset_ubuntu" = "s" ]; then
    echo ""
    echo "Ingresa la nueva contraseña para 'ubuntu':"
    passwd ubuntu
    echo ""
    echo "✅ Contraseña de 'ubuntu' actualizada"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "🗑️  OPCIÓN 2: Eliminar usuario 'gamer01'"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Este usuario fue creado por error y no es necesario"
read -p "¿Eliminar usuario gamer01? (s/n): " delete_gamer

if [ "$delete_gamer" = "s" ]; then
    if id "gamer01" &>/dev/null; then
        echo ""
        echo "Eliminando usuario gamer01..."
        
        # Matar procesos del usuario
        pkill -u gamer01 2>/dev/null || true
        sleep 2
        
        # Eliminar usuario y su home
        userdel -r gamer01 2>/dev/null || userdel gamer01
        
        echo "✅ Usuario gamer01 eliminado"
    else
        echo "ℹ️  Usuario gamer01 no existe"
    fi
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "🗑️  OPCIÓN 3: Eliminar otros usuarios no deseados"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Usuarios actuales (excluyendo sistema):"
cat /etc/passwd | grep -E "/home/" | cut -d: -f1 | sed 's/^/   /'
echo ""
read -p "¿Hay algún otro usuario que quieras eliminar? (nombre o 'n'): " other_user

if [ "$other_user" != "n" ] && [ ! -z "$other_user" ]; then
    if id "$other_user" &>/dev/null; then
        echo ""
        echo "Eliminando usuario $other_user..."
        
        # Matar procesos del usuario
        pkill -u "$other_user" 2>/dev/null || true
        sleep 2
        
        # Eliminar usuario y su home
        userdel -r "$other_user" 2>/dev/null || userdel "$other_user"
        
        echo "✅ Usuario $other_user eliminado"
    else
        echo "❌ Usuario $other_user no existe"
    fi
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ RESUMEN FINAL"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Usuarios finales en el sistema:"
cat /etc/passwd | grep -E "/home/" | cut -d: -f1 | sed 's/^/   /'
echo ""
echo "Para iniciar sesión usa:"
echo "  Usuario: ubuntu"
echo "  Contraseña: (la que acabas de configurar)"
echo ""
echo "════════════════════════════════════════════════════════"
