#!/bin/bash

echo "════════════════════════════════════════════════════════════════"
echo "👥 CONFIGURAR USUARIOS Y TEMAS EN CLIENTE"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script debe ejecutarse como root"
    echo "   Usa: sudo bash $0"
    exit 1
fi

echo "Paso 1: Creando usuarios"
echo "────────────────────────────────────────────────────────"

# Crear grupo pcgamers si no existe
if ! getent group pcgamers > /dev/null; then
    groupadd -g 3000 pcgamers
    echo "✓ Grupo pcgamers creado"
else
    echo "✓ Grupo pcgamers ya existe"
fi

# Crear usuario gamer
if ! id gamer &>/dev/null; then
    useradd -m -s /bin/bash -G pcgamers,audio,video gamer
    echo "gamer:123" | chpasswd
    echo "✓ Usuario gamer creado (contraseña: 123)"
else
    echo "✓ Usuario gamer ya existe"
fi

# Crear usuario invitado
if ! id invitado &>/dev/null; then
    useradd -m -s /bin/bash invitado
    echo "invitado:123" | chpasswd
    echo "✓ Usuario invitado creado (contraseña: 123)"
else
    echo "✓ Usuario invitado ya existe"
fi

# Agregar administrador al grupo pcgamers
usermod -aG pcgamers administrador
echo "✓ Administrador agregado a pcgamers"

echo ""
echo "Paso 2: Configurando carpetas"
echo "────────────────────────────────────────────────────────"

# Crear punto de montaje NFS
mkdir -p /mnt/games
chown root:pcgamers /mnt/games
chmod 2775 /mnt/games
echo "✓ /mnt/games creado"

# Crear carpetas personales
mkdir -p /home/gamer/{Descargas,Documentos,Juegos}
chown -R gamer:gamer /home/gamer
echo "✓ Carpetas de gamer creadas"

mkdir -p /home/invitado/{Descargas,Documentos}
chown -R invitado:invitado /home/invitado
echo "✓ Carpetas de invitado creadas"

echo ""
echo "Paso 3: Instalando temas"
echo "────────────────────────────────────────────────────────"

apt install -y \
    papirus-icon-theme \
    arc-theme \
    fonts-firacode \
    gnome-tweaks \
    dconf-cli &>/dev/null

echo "✓ Temas instalados"

echo ""
echo "Paso 4: Configurando tema para GAMER (oscuro gaming)"
echo "────────────────────────────────────────────────────────"

# Configurar tema oscuro para gamer
sudo -u gamer dbus-launch gsettings set org.gnome.desktop.interface gtk-theme 'Arc-Dark' 2>/dev/null || true
sudo -u gamer dbus-launch gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' 2>/dev/null || true
sudo -u gamer dbus-launch gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
sudo -u gamer dbus-launch gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close' 2>/dev/null || true

# Wallpaper oscuro
sudo -u gamer dbus-launch gsettings set org.gnome.desktop.background picture-uri 'file:///usr/share/backgrounds/warty-final-ubuntu.png' 2>/dev/null || true

echo "✓ Tema gaming aplicado a gamer"

echo ""
echo "Paso 5: Configurando tema para INVITADO (claro simple)"
echo "────────────────────────────────────────────────────────"

# Configurar tema claro para invitado
sudo -u invitado dbus-launch gsettings set org.gnome.desktop.interface gtk-theme 'Yaru' 2>/dev/null || true
sudo -u invitado dbus-launch gsettings set org.gnome.desktop.interface icon-theme 'Papirus' 2>/dev/null || true
sudo -u invitado dbus-launch gsettings set org.gnome.desktop.interface color-scheme 'prefer-light' 2>/dev/null || true

echo "✓ Tema claro aplicado a invitado"

echo ""
echo "Paso 6: Configurando tema para ADMINISTRADOR (oscuro profesional)"
echo "────────────────────────────────────────────────────────"

# Configurar tema oscuro para administrador
sudo -u administrador dbus-launch gsettings set org.gnome.desktop.interface gtk-theme 'Yaru-dark' 2>/dev/null || true
sudo -u administrador dbus-launch gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' 2>/dev/null || true
sudo -u administrador dbus-launch gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true

echo "✓ Tema oscuro aplicado a administrador"

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✅ CONFIGURACIÓN COMPLETADA"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "👥 Usuarios creados:"
echo "  1. administrador (ya existía) - Tema oscuro profesional"
echo "  2. gamer (nuevo) - Tema oscuro gaming"
echo "  3. invitado (nuevo) - Tema claro simple"
echo ""
echo "🔑 Contraseñas:"
echo "  - gamer: 123"
echo "  - invitado: 123"
echo ""
echo "📁 Carpetas:"
echo "  - /mnt/games (compartida para pcgamers)"
echo "  - /home/gamer/Juegos"
echo ""
echo "🎨 Temas aplicados:"
echo "  - administrador: Yaru-dark + Papirus-Dark"
echo "  - gamer: Arc-Dark + Papirus-Dark"
echo "  - invitado: Yaru + Papirus"
echo ""
echo "🔄 Cierra sesión y entra con otro usuario para ver los cambios"
echo "════════════════════════════════════════════════════════════════"
