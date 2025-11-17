#!/bin/bash
# Script para configurar tema gaming para usuario gamer01

echo "════════════════════════════════════════"
echo "🎮 Configurando tema GAMER para gamer01"
echo "════════════════════════════════════════"
echo ""

# Verificar que el usuario existe
if ! id "gamer01" &>/dev/null; then
    echo "❌ Usuario gamer01 no existe. Ejecuta primero: sudo bash scripts/create-users.sh"
    exit 1
fi

echo "1️⃣  Instalando temas gaming..."
sudo apt install -y \
    arc-theme \
    papirus-icon-theme \
    gnome-tweaks \
    gnome-shell-extensions

echo ""
echo "2️⃣  Descargando wallpaper gaming..."
sudo mkdir -p /usr/share/backgrounds/gaming
sudo wget -q -O /usr/share/backgrounds/gaming/gaming-setup.jpg \
    "https://images.unsplash.com/photo-1593305841991-05c297ba4575?w=1920" 2>/dev/null || \
sudo wget -q -O /usr/share/backgrounds/gaming/gaming-setup.jpg \
    "https://picsum.photos/1920/1080" 2>/dev/null

echo ""
echo "3️⃣  Configurando tema para gamer01..."

# Configurar como usuario gamer01
sudo -u gamer01 dbus-launch gsettings set org.gnome.desktop.interface gtk-theme 'Arc-Dark' 2>/dev/null || true
sudo -u gamer01 dbus-launch gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' 2>/dev/null || true
sudo -u gamer01 dbus-launch gsettings set org.gnome.desktop.wm.preferences theme 'Arc-Dark' 2>/dev/null || true

echo ""
echo "4️⃣  Configurando wallpaper gaming..."
sudo -u gamer01 dbus-launch gsettings set org.gnome.desktop.background picture-uri \
    'file:///usr/share/backgrounds/gaming/gaming-setup.jpg' 2>/dev/null || true
sudo -u gamer01 dbus-launch gsettings set org.gnome.desktop.background picture-uri-dark \
    'file:///usr/share/backgrounds/gaming/gaming-setup.jpg' 2>/dev/null || true

echo ""
echo "5️⃣  Configurando colores gaming (RGB style)..."
# Tema oscuro
sudo -u gamer01 dbus-launch gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true

# Accent color (si está disponible en Ubuntu 22.04+)
sudo -u gamer01 dbus-launch gsettings set org.gnome.desktop.interface accent-color 'red' 2>/dev/null || true

echo ""
echo "6️⃣  Configurando dock gaming..."
# Dock en la parte inferior
sudo -u gamer01 dbus-launch gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM' 2>/dev/null || true

# Iconos más grandes
sudo -u gamer01 dbus-launch gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 64 2>/dev/null || true

# Transparencia
sudo -u gamer01 dbus-launch gsettings set org.gnome.shell.extensions.dash-to-dock transparency-mode 'DYNAMIC' 2>/dev/null || true

echo ""
echo "7️⃣  Instalando fuentes gaming..."
sudo apt install -y fonts-firacode fonts-roboto

echo ""
echo "8️⃣  Creando accesos directos gaming..."
sudo mkdir -p /home/gamer01/Desktop
sudo mkdir -p /home/gamer01/Juegos

# Crear acceso directo a carpeta de juegos
cat << 'EOF' | sudo tee /home/gamer01/Desktop/Juegos.desktop > /dev/null
[Desktop Entry]
Version=1.0
Type=Link
Name=Juegos
Icon=folder-games
URL=/home/gamer01/Juegos
EOF

sudo chown -R gamer01:gamer01 /home/gamer01/Desktop
sudo chown -R gamer01:gamer01 /home/gamer01/Juegos
sudo chmod +x /home/gamer01/Desktop/Juegos.desktop

echo ""
echo "════════════════════════════════════════"
echo "✅ Tema GAMER configurado"
echo "════════════════════════════════════════"
echo ""
echo "🎮 Configuración aplicada:"
echo "   - Tema: Arc-Dark (oscuro)"
echo "   - Iconos: Papirus-Dark"
echo "   - Wallpaper: Gaming setup"
echo "   - Dock: Inferior, iconos grandes"
echo "   - Fuentes: FiraCode, Roboto"
echo ""
echo "📁 Carpetas creadas:"
echo "   - ~/Juegos (para instalar juegos)"
echo "   - ~/Desktop/Juegos (acceso directo)"
echo ""
echo "🔄 Para ver los cambios:"
echo "   1. Cierra sesión de gamer01"
echo "   2. Inicia sesión de nuevo"
echo ""
echo "🎨 Para personalizar más:"
echo "   - Abre 'Tweaks' desde el menú"
echo "   - Cambia colores, fuentes, etc."
echo ""
echo "════════════════════════════════════════"
