#!/bin/bash
# Script para configurar tema profesional/sereno para usuario auditor

echo "════════════════════════════════════════"
echo "📊 Configurando tema AUDITOR para auditor"
echo "════════════════════════════════════════"
echo ""

# Verificar que el usuario existe
if ! id "auditor" &>/dev/null; then
    echo "❌ Usuario auditor no existe. Ejecuta primero: sudo bash scripts/create-users.sh"
    exit 1
fi

echo "1️⃣  Instalando temas profesionales..."
sudo apt install -y \
    arc-theme \
    papirus-icon-theme \
    gnome-tweaks \
    gnome-shell-extensions

echo ""
echo "2️⃣  Descargando wallpaper profesional..."
sudo mkdir -p /usr/share/backgrounds/professional
sudo wget -q -O /usr/share/backgrounds/professional/minimal-blue.jpg \
    "https://images.unsplash.com/photo-1557683316-973673baf926?w=1920" 2>/dev/null || \
sudo wget -q -O /usr/share/backgrounds/professional/minimal-blue.jpg \
    "https://picsum.photos/1920/1080" 2>/dev/null

echo ""
echo "3️⃣  Configurando tema para auditor..."

# Tema claro y profesional
sudo -u auditor dbus-launch gsettings set org.gnome.desktop.interface gtk-theme 'Arc' 2>/dev/null || true
sudo -u auditor dbus-launch gsettings set org.gnome.desktop.interface icon-theme 'Papirus' 2>/dev/null || true
sudo -u auditor dbus-launch gsettings set org.gnome.desktop.wm.preferences theme 'Arc' 2>/dev/null || true

echo ""
echo "4️⃣  Configurando wallpaper profesional..."
sudo -u auditor dbus-launch gsettings set org.gnome.desktop.background picture-uri \
    'file:///usr/share/backgrounds/professional/minimal-blue.jpg' 2>/dev/null || true
sudo -u auditor dbus-launch gsettings set org.gnome.desktop.background picture-uri-dark \
    'file:///usr/share/backgrounds/professional/minimal-blue.jpg' 2>/dev/null || true

echo ""
echo "5️⃣  Configurando colores serenos..."
# Tema claro
sudo -u auditor dbus-launch gsettings set org.gnome.desktop.interface color-scheme 'prefer-light' 2>/dev/null || true

# Accent color azul (profesional)
sudo -u auditor dbus-launch gsettings set org.gnome.desktop.interface accent-color 'blue' 2>/dev/null || true

echo ""
echo "6️⃣  Configurando dock minimalista..."
# Dock lateral izquierdo
sudo -u auditor dbus-launch gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'LEFT' 2>/dev/null || true

# Iconos medianos
sudo -u auditor dbus-launch gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 48 2>/dev/null || true

# Ocultar automáticamente
sudo -u auditor dbus-launch gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed 'false' 2>/dev/null || true
sudo -u auditor dbus-launch gsettings set org.gnome.shell.extensions.dash-to-dock autohide 'true' 2>/dev/null || true

echo ""
echo "7️⃣  Instalando fuentes profesionales..."
sudo apt install -y fonts-roboto fonts-noto

echo ""
echo "8️⃣  Creando accesos directos para auditoría..."
sudo mkdir -p /home/auditor/Desktop
sudo mkdir -p /home/auditor/Documentos/Auditorias
sudo mkdir -p /home/auditor/Documentos/Reportes

# Acceso directo a logs del sistema
cat << 'EOF' | sudo tee /home/auditor/Desktop/Logs.desktop > /dev/null
[Desktop Entry]
Version=1.0
Type=Link
Name=Logs del Sistema
Icon=utilities-system-monitor
URL=/var/log
EOF

# Acceso directo a auditorías
cat << 'EOF' | sudo tee /home/auditor/Desktop/Auditorias.desktop > /dev/null
[Desktop Entry]
Version=1.0
Type=Link
Name=Auditorías
Icon=folder-documents
URL=/home/auditor/Documentos/Auditorias
EOF

sudo chown -R auditor:auditor /home/auditor/Desktop
sudo chown -R auditor:auditor /home/auditor/Documentos
sudo chmod +x /home/auditor/Desktop/*.desktop

echo ""
echo "9️⃣  Instalando herramientas de auditoría..."
sudo apt install -y \
    gnome-system-monitor \
    baobab \
    gnome-logs

echo ""
echo "════════════════════════════════════════"
echo "✅ Tema AUDITOR configurado"
echo "════════════════════════════════════════"
echo ""
echo "📊 Configuración aplicada:"
echo "   - Tema: Arc (claro, profesional)"
echo "   - Iconos: Papirus (claro)"
echo "   - Wallpaper: Minimalista azul"
echo "   - Dock: Lateral izquierdo, auto-ocultar"
echo "   - Fuentes: Roboto, Noto (profesionales)"
echo ""
echo "📁 Carpetas creadas:"
echo "   - ~/Documentos/Auditorias"
echo "   - ~/Documentos/Reportes"
echo "   - Acceso directo a /var/log"
echo ""
echo "🔧 Herramientas instaladas:"
echo "   - Monitor del sistema"
echo "   - Analizador de uso de disco"
echo "   - Visor de logs"
echo ""
echo "🔄 Para ver los cambios:"
echo "   1. Cierra sesión de auditor"
echo "   2. Inicia sesión de nuevo"
echo ""
echo "════════════════════════════════════════"
