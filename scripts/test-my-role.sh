#!/bin/bash
# Script para que cada usuario pruebe sus permisos

# Auto-permisos
[ ! -x "$0" ] && chmod +x "$0" 2>/dev/null

echo "════════════════════════════════════════════════════════"
echo "🧪 Prueba de Permisos - Usuario: $(whoami)"
echo "════════════════════════════════════════════════════════"
echo ""

USER=$(whoami)

echo "📋 Información del usuario:"
echo "  Usuario: $USER"
echo "  Grupos: $(groups)"
echo "  Home: $HOME"
echo ""

echo "════════════════════════════════════════════════════════"
echo "🔍 Probando permisos..."
echo "════════════════════════════════════════════════════════"
echo ""

# Test 1: Sudo
echo "1️⃣  Probando SUDO..."
if sudo -n true 2>/dev/null; then
    echo "  ✅ Tienes sudo SIN contraseña"
    SUDO_RESULT="✅ Sudo completo"
elif sudo -v 2>/dev/null; then
    echo "  ✅ Tienes sudo CON contraseña"
    SUDO_RESULT="✅ Sudo con contraseña"
else
    echo "  ❌ NO tienes sudo"
    SUDO_RESULT="❌ Sin sudo"
fi

echo ""

# Test 2: SSH al servidor
echo "2️⃣  Probando SSH al servidor..."
if grep -q "^AllowUsers" /etc/ssh/sshd_config 2>/dev/null; then
    if grep "^AllowUsers" /etc/ssh/sshd_config | grep -q "$USER"; then
        echo "  ✅ Puedes hacer SSH al servidor"
        SSH_RESULT="✅ SSH permitido"
    else
        echo "  ❌ NO puedes hacer SSH al servidor"
        SSH_RESULT="❌ SSH bloqueado"
    fi
else
    echo "  ⚠️  SSH sin restricciones"
    SSH_RESULT="⚠️  SSH sin restricciones"
fi

echo ""

# Test 3: Acceso a /srv/admin
echo "3️⃣  Probando acceso a /srv/admin..."
if [ -d "/srv/admin" ]; then
    if touch /srv/admin/test_$USER 2>/dev/null; then
        echo "  ✅ Puedes ESCRIBIR en /srv/admin"
        rm /srv/admin/test_$USER
        ADMIN_RESULT="✅ Escritura"
    elif [ -r /srv/admin ]; then
        echo "  👁️  Solo LECTURA en /srv/admin"
        ADMIN_RESULT="👁️ Solo lectura"
    else
        echo "  ❌ SIN ACCESO a /srv/admin"
        ADMIN_RESULT="❌ Sin acceso"
    fi
else
    echo "  ⚠️  /srv/admin no existe"
    ADMIN_RESULT="⚠️ No existe"
fi

echo ""

# Test 4: Acceso a /srv/audits
echo "4️⃣  Probando acceso a /srv/audits..."
if [ -d "/srv/audits" ]; then
    if touch /srv/audits/test_$USER 2>/dev/null; then
        echo "  ✅ Puedes ESCRIBIR en /srv/audits"
        rm /srv/audits/test_$USER
        AUDITS_RESULT="✅ Escritura"
    elif [ -r /srv/audits ]; then
        echo "  👁️  Solo LECTURA en /srv/audits"
        AUDITS_RESULT="👁️ Solo lectura"
    else
        echo "  ❌ SIN ACCESO a /srv/audits"
        AUDITS_RESULT="❌ Sin acceso"
    fi
else
    echo "  ⚠️  /srv/audits no existe"
    AUDITS_RESULT="⚠️ No existe"
fi

echo ""

# Test 5: Acceso a /srv/games
echo "5️⃣  Probando acceso a /srv/games..."
if [ -d "/srv/games" ]; then
    if touch /srv/games/test_$USER 2>/dev/null; then
        echo "  ✅ Puedes ESCRIBIR en /srv/games"
        rm /srv/games/test_$USER
        GAMES_RESULT="✅ Escritura"
    elif [ -r /srv/games ]; then
        echo "  👁️  Solo LECTURA en /srv/games"
        GAMES_RESULT="👁️ Solo lectura"
    else
        echo "  ❌ SIN ACCESO a /srv/games"
        GAMES_RESULT="❌ Sin acceso"
    fi
else
    echo "  ⚠️  /srv/games no existe"
    GAMES_RESULT="⚠️ No existe"
fi

echo ""

# Test 6: Instalar paquetes
echo "6️⃣  Probando instalación de paquetes..."
if sudo -n apt update &>/dev/null; then
    echo "  ✅ Puedes instalar paquetes"
    INSTALL_RESULT="✅ Puede instalar"
else
    echo "  ❌ NO puedes instalar paquetes"
    INSTALL_RESULT="❌ No puede instalar"
fi

echo ""

# Test 7: Ver logs del sistema
echo "7️⃣  Probando acceso a logs..."
if journalctl -n 1 &>/dev/null; then
    echo "  ✅ Puedes ver logs del sistema"
    LOGS_RESULT="✅ Puede ver logs"
else
    echo "  ❌ NO puedes ver logs del sistema"
    LOGS_RESULT="❌ No puede ver logs"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "📊 RESUMEN DE PERMISOS - $USER"
echo "════════════════════════════════════════════════════════"
echo ""
echo "  Sudo:           $SUDO_RESULT"
echo "  SSH:            $SSH_RESULT"
echo "  /srv/admin:     $ADMIN_RESULT"
echo "  /srv/audits:    $AUDITS_RESULT"
echo "  /srv/games:     $GAMES_RESULT"
echo "  Instalar:       $INSTALL_RESULT"
echo "  Logs:           $LOGS_RESULT"
echo ""

# Mostrar permisos esperados según el usuario
echo "════════════════════════════════════════════════════════"
echo "📋 PERMISOS ESPERADOS PARA: $USER"
echo "════════════════════════════════════════════════════════"
echo ""

case "$USER" in
    "administrador")
        echo "  ROL: Administrador"
        echo ""
        echo "  ✅ Sudo completo (sin contraseña)"
        echo "  ✅ SSH al servidor"
        echo "  ✅ Escritura en /srv/admin"
        echo "  ❌ Sin acceso a /srv/audits"
        echo "  ✅ Escritura en /srv/games"
        echo "  ✅ Instalar paquetes"
        echo "  ✅ Ver logs"
        ;;
    "auditor")
        echo "  ROL: Auditor"
        echo ""
        echo "  ❌ Sin sudo"
        echo "  ❌ Sin SSH al servidor"
        echo "  ❌ Sin acceso a /srv/admin"
        echo "  ✅ Escritura en /srv/audits"
        echo "  👁️  Solo lectura en /srv/games"
        echo "  ❌ No puede instalar paquetes"
        echo "  ✅ Ver logs (solo lectura)"
        ;;
    "gamer01")
        echo "  ROL: Cliente/Gamer"
        echo ""
        echo "  ❌ Sin sudo"
        echo "  ❌ Sin SSH al servidor"
        echo "  ❌ Sin acceso a /srv/admin"
        echo "  ❌ Sin acceso a /srv/audits"
        echo "  👁️  Solo lectura en /srv/games"
        echo "  ❌ No puede instalar paquetes"
        echo "  ❌ No puede ver logs"
        ;;
    *)
        echo "  ⚠️  Usuario no reconocido"
        ;;
esac

echo ""
echo "════════════════════════════════════════════════════════"
