#!/bin/bash
# Script para probar los 3 roles de usuarios

# Auto-permisos
[ ! -x "$0" ] && chmod +x "$0" 2>/dev/null

echo "════════════════════════════════════════════════════════"
echo "🧪 Probando roles de usuarios"
echo "════════════════════════════════════════════════════════"
echo ""

echo "📋 Usuarios configurados:"
echo ""
echo "  1. administrador (original) - Contraseña: 123"
echo "  2. admin (nuevo admin)      - Contraseña: 123456"
echo "  3. auditor                  - Contraseña: 123456"
echo "  4. gamer01                  - Contraseña: 123456"
echo ""

# Función para probar permisos
test_user() {
    local user=$1
    local expected_sudo=$2
    local expected_ssh=$3
    
    echo "════════════════════════════════════════════════════════"
    echo "🔍 Probando usuario: $user"
    echo "════════════════════════════════════════════════════════"
    
    # Verificar que el usuario existe
    if id "$user" &>/dev/null; then
        echo "  ✓ Usuario existe"
    else
        echo "  ❌ Usuario NO existe"
        return
    fi
    
    # Verificar grupos
    echo ""
    echo "  Grupos:"
    groups "$user" | sed 's/^/    /'
    
    # Verificar sudo
    echo ""
    echo "  Permisos sudo:"
    if sudo -l -U "$user" 2>/dev/null | grep -q "NOPASSWD: ALL"; then
        echo "    ✓ Tiene sudo SIN contraseña"
    elif sudo -l -U "$user" 2>/dev/null | grep -q "ALL"; then
        echo "    ✓ Tiene sudo CON contraseña"
    else
        echo "    ❌ NO tiene sudo"
    fi
    
    # Verificar acceso SSH
    echo ""
    echo "  Acceso SSH:"
    if grep -q "^AllowUsers" /etc/ssh/sshd_config; then
        if grep "^AllowUsers" /etc/ssh/sshd_config | grep -q "$user"; then
            echo "    ✓ Puede hacer SSH"
        else
            echo "    ❌ NO puede hacer SSH"
        fi
    else
        echo "    ⚠️  SSH sin restricciones (todos pueden)"
    fi
    
    # Verificar acceso a carpetas
    echo ""
    echo "  Acceso a carpetas:"
    
    # /srv/admin
    if [ -d "/srv/admin" ]; then
        if sudo -u "$user" test -w /srv/admin 2>/dev/null; then
            echo "    ✓ /srv/admin - Escritura"
        elif sudo -u "$user" test -r /srv/admin 2>/dev/null; then
            echo "    👁️  /srv/admin - Solo lectura"
        else
            echo "    ❌ /srv/admin - Sin acceso"
        fi
    fi
    
    # /srv/audits
    if [ -d "/srv/audits" ]; then
        if sudo -u "$user" test -w /srv/audits 2>/dev/null; then
            echo "    ✓ /srv/audits - Escritura"
        elif sudo -u "$user" test -r /srv/audits 2>/dev/null; then
            echo "    👁️  /srv/audits - Solo lectura"
        else
            echo "    ❌ /srv/audits - Sin acceso"
        fi
    fi
    
    # /srv/games
    if [ -d "/srv/games" ]; then
        if sudo -u "$user" test -w /srv/games 2>/dev/null; then
            echo "    ✓ /srv/games - Escritura"
        elif sudo -u "$user" test -r /srv/games 2>/dev/null; then
            echo "    👁️  /srv/games - Solo lectura"
        else
            echo "    ❌ /srv/games - Sin acceso"
        fi
    fi
    
    echo ""
}

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script debe ejecutarse como root"
    echo "   Usa: sudo bash $0"
    exit 1
fi

# Probar cada usuario
test_user "administrador" "yes" "yes"
test_user "admin" "yes" "yes"
test_user "auditor" "no" "no"
test_user "gamer01" "no" "no"

echo "════════════════════════════════════════════════════════"
echo "📊 Resumen de permisos esperados"
echo "════════════════════════════════════════════════════════"
echo ""
echo "┌──────────────┬──────┬─────────┬───────────┬─────────────┬──────────────┐"
echo "│ Usuario      │ Sudo │ SSH     │ /srv/admin│ /srv/audits │ /srv/games   │"
echo "├──────────────┼──────┼─────────┼───────────┼─────────────┼──────────────┤"
echo "│ administrador│  ✓   │    ✓    │     ❌    │      ❌     │      ✓       │"
echo "│ admin        │  ✓   │    ✓    │     ✓     │      ❌     │      ✓       │"
echo "│ auditor      │  ❌  │    ❌   │     ❌    │      ✓      │   👁️ (leer)  │"
echo "│ gamer01      │  ❌  │    ❌   │     ❌    │      ❌     │   👁️ (leer)  │"
echo "└──────────────┴──────┴─────────┴───────────┴─────────────┴──────────────┘"
echo ""
echo "════════════════════════════════════════════════════════"
echo ""
echo "🧪 Pruebas manuales recomendadas:"
echo ""
echo "1. Cerrar sesión actual"
echo "2. Iniciar sesión con cada usuario"
echo "3. Probar:"
echo "   - sudo apt update (debería funcionar solo en admin/administrador)"
echo "   - ssh ubuntu@2025:db8:10::2 (solo admin/administrador)"
echo "   - Crear archivo en /srv/games (solo admin/administrador)"
echo ""
echo "════════════════════════════════════════════════════════"
