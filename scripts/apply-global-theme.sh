#!/bin/bash
# Script para aplicar tema oscuro globalmente a todos los usuarios

# Auto-permisos
[ ! -x "$0" ] && chmod +x "$0" 2>/dev/null

set -e

echo "════════════════════════════════════════════════════════"
echo "🎨 Aplicando tema global para todos los usuarios"
echo "════════════════════════════════════════════════════════"
echo ""

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script debe ejecutarse como root"
    echo "   Usa: sudo bash $0"
    exit 1
fi

echo "1️⃣  Instalando paquetes necesarios..."
apt update
apt install -y \
    papirus-icon-theme \
    fonts-firacode \
    dconf-cli

echo ""
echo "2️⃣  Configurando tema global en dconf..."

# Crear configuración global de dconf
mkdir -p /etc/dconf/db/local.d
mkdir -p /etc/dconf/profile

# Perfil de usuario
cat > /etc/dconf/profile/user << 'EOF'
user-db:user
system-db:local
EOF

# Configuración global
cat > /etc/dconf/db/local.d/01-global-theme << 'EOF'
# Tema e iconos
[org/gnome/desktop/interface]
gtk-theme='Yaru-dark'
icon-theme='Papirus-Dark'
cursor-theme='Yaru'
color-scheme='prefer-dark'

# Fuentes
font-name='Ubuntu 11'
document-font-name='Ubuntu 11'
monospace-font-name='Fira Code 10'
font-antialiasing='rgba'
font-hinting='slight'

# Optimizaciones
enable-animations=false
enable-hot-corners=false

# Dock
[org/gnome/shell/extensions/dash-to-dock]
dock-position='BOTTOM'
dash-max-icon-size=48
transparency-mode='DYNAMIC'
show-trash=false
show-mounts=false

# Ventanas
[org/gnome/desktop/wm/preferences]
button-layout=':minimize,maximize,close'
titlebar-font='Ubuntu Bold 11'

# Mutter
[org/gnome/mutter]
center-new-windows=true
dynamic-workspaces=false

# Shell
[org/gnome/shell/overrides]
workspaces-only-on-primary=true

# Escritorio
[org/gnome/desktop/background]
show-desktop-icons=false
picture-uri='file:///usr/share/backgrounds/ubuntu-default-greyscale-wallpaper.png'
picture-uri-dark='file:///usr/share/backgrounds/ubuntu-default-greyscale-wallpaper.png'

# Red (quitar icono de "sin internet")
[org/gnome/nm-applet]
disable-connected-notifications=true
disable-disconnected-notifications=true
EOF

# Actualizar base de datos dconf
dconf update

echo "  ✓ Configuración global creada"

echo ""
echo "3️⃣  Aplicando configuración a usuarios existentes..."

# Aplicar a cada usuario
for USER_HOME in /home/*; do
    if [ -d "$USER_HOME" ]; then
        USERNAME=$(basename "$USER_HOME")
        
        # Saltar si es un directorio del sistema
        if [ "$USERNAME" = "lost+found" ]; then
            continue
        fi
        
        echo "  → Configurando $USERNAME..."
        
        # Aplicar configuraciones como el usuario
        sudo -u "$USERNAME" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u $USERNAME)/bus" \
            dconf load / < /etc/dconf/db/local.d/01-global-theme 2>/dev/null || true
        
        # Terminal con Fira Code
        PROFILE=$(sudo -u "$USERNAME" gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null | tr -d "'" || echo "")
        if [ ! -z "$PROFILE" ]; then
            sudo -u "$USERNAME" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u $USERNAME)/bus" \
                gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE/ font 'Fira Code 11' 2>/dev/null || true
            sudo -u "$USERNAME" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u $USERNAME)/bus" \
                gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE/ use-system-font false 2>/dev/null || true
        fi
    fi
done

echo ""
echo "4️⃣  Configurando tema de login (GDM)..."

# Tema oscuro para la pantalla de login
cat > /etc/gdm3/greeter.dconf-defaults << 'EOF'
[org/gnome/desktop/interface]
gtk-theme='Yaru-dark'
icon-theme='Papirus-Dark'
cursor-theme='Yaru'

[org/gnome/desktop/background]
picture-uri='file:///usr/share/backgrounds/ubuntu-default-greyscale-wallpaper.png'
EOF

# Recargar GDM
dpkg-reconfigure gdm3 2>/dev/null || true

echo "  ✓ Tema de login configurado"

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ Tema global aplicado"
echo "════════════════════════════════════════════════════════"
echo ""
echo "🎨 Configuración aplicada:"
echo ""
echo "  ✓ Tema: Yaru Dark (global)"
echo "  ✓ Iconos: Papirus Dark (global)"
echo "  ✓ Fuentes: Ubuntu + Fira Code (global)"
echo "  ✓ Optimizaciones de rendimiento (global)"
echo "  ✓ Pantalla de login: Tema oscuro"
echo ""
echo "👥 Usuarios configurados:"
for USER_HOME in /home/*; do
    if [ -d "$USER_HOME" ]; then
        USERNAME=$(basename "$USER_HOME")
        if [ "$USERNAME" != "lost+found" ]; then
            echo "  • $USERNAME"
        fi
    fi
done
echo ""
echo "════════════════════════════════════════════════════════"
echo ""
echo "⚠️  Para ver los cambios:"
echo "   • Cierra sesión y vuelve a entrar"
echo "   • O reinicia la VM"
echo ""
echo "════════════════════════════════════════════════════════"
