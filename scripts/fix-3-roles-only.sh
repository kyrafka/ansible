#!/bin/bash
# Script para dejar solo 3 roles: administrador, auditor, gamer01

# Auto-permisos
[ ! -x "$0" ] && chmod +x "$0" 2>/dev/null

set -e

echo "════════════════════════════════════════════════════════"
echo "🔧 Configurando 3 roles únicos"
echo "════════════════════════════════════════════════════════"
echo ""

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script debe ejecutarse como root"
    echo "   Usa: sudo bash $0"
    exit 1
fi

echo "📋 Configuración final:"
echo ""
echo "  1. administrador - Admin (sudo completo, SSH)"
echo "  2. auditor       - Auditor (solo lectura)"
echo "  3. gamer01       - Cliente/Gamer (sin privilegios)"
echo ""

read -p "¿Continuar? [S/n]: " CONFIRM
if [[ "$CONFIRM" =~ ^[nN]$ ]]; then
    echo "Operación cancelada"
    exit 0
fi

echo ""
echo "1️⃣  Eliminando usuario 'admin' duplicado..."

if id "admin" &>/dev/null; then
    # Matar procesos del usuario
    pkill -u admin 2>/dev/null || true
    
    # Eliminar usuario y su home
    userdel -r admin 2>/dev/null || userdel admin
    
    # Eliminar configuración de sudo
    rm -f /etc/sudoers.d/admin
    
    echo "  ✓ Usuario 'admin' eliminado"
else
    echo "  ✓ Usuario 'admin' no existe"
fi

echo ""
echo "2️⃣  Configurando 'administrador' como admin principal..."

# Asegurar que administrador tiene todos los permisos
usermod -aG sudo,adm,pcgamers administrador 2>/dev/null || true

# Configurar sudo sin contraseña
echo "administrador ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/administrador
chmod 440 /etc/sudoers.d/administrador

echo "  ✓ administrador configurado con sudo completo"

echo ""
echo "3️⃣  Configurando permisos de carpetas..."

# /srv/admin → ahora es de administrador
if [ -d "/srv/admin" ]; then
    chown -R administrador:administrador /srv/admin
    chmod 755 /srv/admin
    echo "  ✓ /srv/admin → administrador"
fi

# /srv/audits → auditor
if [ -d "/srv/audits" ]; then
    chown -R auditor:auditor /srv/audits
    chmod 755 /srv/audits
    echo "  ✓ /srv/audits → auditor"
fi

# /srv/games → compartido (grupo pcgamers)
if [ -d "/srv/games" ]; then
    chown root:pcgamers /srv/games
    chmod 775 /srv/games
    echo "  ✓ /srv/games → compartido (pcgamers)"
fi

echo ""
echo "4️⃣  Configurando SSH..."

# Solo administrador puede SSH
if grep -q "^AllowUsers" /etc/ssh/sshd_config; then
    sed -i 's/^AllowUsers.*/AllowUsers administrador/' /etc/ssh/sshd_config
else
    echo "AllowUsers administrador" >> /etc/ssh/sshd_config
fi

systemctl restart ssh

echo "  ✓ SSH: solo administrador"

echo ""
echo "5️⃣  Verificando usuarios finales..."

echo ""
echo "  Usuarios del sistema:"
cat /etc/passwd | grep -E "administrador|auditor|gamer01" | cut -d: -f1,5 | sed 's/^/    /'

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ Configuración completada"
echo "════════════════════════════════════════════════════════"
echo ""
echo "📊 Roles finales:"
echo ""
echo "┌──────────────┬──────┬─────────┬───────────┬─────────────┬──────────────┐"
echo "│ Usuario      │ Sudo │ SSH     │ /srv/admin│ /srv/audits │ /srv/games   │"
echo "├──────────────┼──────┼─────────┼───────────┼─────────────┼──────────────┤"
echo "│ administrador│  ✓   │    ✓    │     ✓     │      ❌     │      ✓       │"
echo "│ auditor      │  ❌  │    ❌   │     ❌    │      ✓      │   👁️ (leer)  │"
echo "│ gamer01      │  ❌  │    ❌   │     ❌    │      ❌     │   👁️ (leer)  │"
echo "└──────────────┴──────┴─────────┴───────────┴─────────────┴──────────────┘"
echo ""
echo "🔑 Contraseñas:"
echo "  • administrador: 123"
echo "  • auditor: 123456"
echo "  • gamer01: 123456"
echo ""
echo "════════════════════════════════════════════════════════"
echo ""
echo "⚠️  Si estás usando el usuario 'admin', cierra sesión ahora"
echo "   y vuelve a entrar con 'administrador'"
echo ""
echo "════════════════════════════════════════════════════════"
