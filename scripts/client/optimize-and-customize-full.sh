#!/bin/bash

echo "════════════════════════════════════════════════════════════════"
echo "🚀 OPTIMIZACIÓN Y PERSONALIZACIÓN COMPLETA DEL CLIENTE"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script debe ejecutarse como root"
    echo "   Usa: sudo bash $0"
    exit 1
fi

echo "Paso 1: Optimizando sistema base"
echo "────────────────────────────────────────────────────────"

# Desactivar servicios innecesarios
systemctl disable bluetooth.service 2>/dev/null
systemctl stop bluetooth.service 2>/dev/null
systemctl disable cups.service 2>/dev/null
systemctl disable cups-browsed.service 2>/dev/null
systemctl disable ModemManager.service 2>/dev/null
systemctl disable avahi-daemon.service 2>/dev/null

echo "✓ Servicios innecesarios desactivados"

# Optimizar swappiness
echo "vm.swappiness=10" > /etc/sysctl.d/99-swappiness.conf
sysctl -p /etc/sysctl.d/99-swappiness.conf &>/dev/null

echo "✓ Swappiness optimizado (10)"

# Limpiar sistema
apt autoremove -y &>/dev/null
apt autoclean -y &>/dev/null

echo "✓ Sistema limpiado"

echo ""
echo "Paso 2: Instalando herramientas de personalización"
echo "────────────────────────────────────────────────────────"

apt update &>/dev/null

apt install -y \
    gnome-shell-extensions \
    gnome-shell-extension-manager \
    chrome-gnome-shell \
    gnome-tweaks \
    dconf-editor \
    papirus-icon-theme \
    arc-theme \
    fonts-firacode \
    fonts-noto-color-emoji \
    git \
    curl \
    neofetch \
    htop \
    preload &>/dev/null

echo "✓ Herramientas instaladas"

# Habilitar preload para mejor rendimiento
systemctl enable preload &>/dev/null
systemctl start preload &>/dev/null

echo "✓ Preload habilitado (precarga apps frecuentes)"

echo ""
echo "Paso 3: Instalando temas premium"
echo "────────────────────────────────────────────────────────"

# Instalar tema Orchis
if [ ! -d "/usr/share/themes/Orchis-Dark" ]; then
    cd /tmp
    git clone https://github.com/vinceliuice/Orchis-theme.git --depth=1 &>/dev/null
    cd Orchis-theme
    ./install.sh -t all --tweaks compact &>/dev/null
    cd /tmp
    rm -rf Orchis-theme
    echo "✓ Tema Orchis instalado"
else
    echo "✓ Tema Orchis ya instalado"
fi

# Instalar iconos Tela
if [ ! -d "/usr/share/icons/Tela" ]; then
    cd /tmp
    git clone https://github.com/vinceliuice/Tela-icon-theme.git --depth=1 &>/dev/null
    cd Tela-icon-theme
    ./install.sh -a &>/dev/null
    cd /tmp
    rm -rf Tela-icon-theme
    echo "✓ Iconos Tela instalados"
else
    echo "✓ Iconos Tela ya instalados"
fi

# Instalar cursor Bibata
if [ ! -d "/usr/share/icons/Bibata-Modern-Classic" ]; then
    cd /tmp
    wget -q https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.6/Bibata-Modern-Classic.tar.xz
    tar -xf Bibata-Modern-Classic.tar.xz
    mv Bibata-Modern-Classic /usr/share/icons/
    rm Bibata-Modern-Classic.tar.xz
    echo "✓ Cursor Bibata instalado"
else
    echo "✓ Cursor Bibata ya instalado"
fi

echo ""
echo "Paso 4: Configurando ADMINISTRADOR (UI profesional oscura)"
echo "────────────────────────────────────────────────────────"

cat > /home/administrador/.apply-full-theme.sh << 'EOFADMIN'
#!/bin/bash
# UI Profesional Oscura para Administrador

# Tema y apariencia
gsettings set org.gnome.desktop.interface gtk-theme 'Orchis-Dark-Compact'
gsettings set org.gnome.desktop.interface icon-theme 'Tela-dark'
gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Classic'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

# Fuentes
gsettings set org.gnome.desktop.interface font-name 'Ubuntu 10'
gsettings set org.gnome.desktop.interface document-font-name 'Ubuntu 11'
gsettings set org.gnome.desktop.interface monospace-font-name 'Fira Code 10'
gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Ubuntu Bold 10'

# Dock/Panel
gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'
gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 40
gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false
gsettings set org.gnome.shell.extensions.dash-to-dock autohide true
gsettings set org.gnome.shell.extensions.dash-to-dock intellihide true

# Ventanas
gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'
gsettings set org.gnome.mutter center-new-windows true

# Rendimiento
gsettings set org.gnome.desktop.interface enable-animations true
gsettings set org.gnome.desktop.interface enable-hot-corners false

# Wallpaper oscuro
gsettings set org.gnome.desktop.background picture-uri 'file:///usr/share/backgrounds/warty-final-ubuntu.png'
gsettings set org.gnome.desktop.background picture-uri-dark 'file:///usr/share/backgrounds/warty-final-ubuntu.png'

# Favoritos en dock
gsettings set org.gnome.shell favorite-apps "['org.gnome.Nautilus.desktop', 'firefox.desktop', 'org.gnome.Terminal.desktop', 'org.gnome.gedit.desktop', 'org.gnome.SystemMonitor.desktop']"

notify-send "⚙️ Tema Admin" "UI profesional aplicada" -i preferences-desktop-theme
EOFADMIN

chmod +x /home/administrador/.apply-full-theme.sh
chown administrador:administrador /home/administrador/.apply-full-theme.sh

echo "✓ Script creado: /home/administrador/.apply-full-theme.sh"

echo ""
echo "Paso 5: Configurando GAMER01 (UI gaming oscura)"
echo "────────────────────────────────────────────────────────"

cat > /home/gamer01/.apply-full-theme.sh << 'EOFGAMER'
#!/bin/bash
# UI Gaming Oscura para Gamer01

# Tema gaming
gsettings set org.gnome.desktop.interface gtk-theme 'Orchis-Dark'
gsettings set org.gnome.desktop.interface icon-theme 'Tela-dark'
gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Classic'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

# Fuentes más grandes para gaming
gsettings set org.gnome.desktop.interface font-name 'Ubuntu 11'
gsettings set org.gnome.desktop.interface document-font-name 'Ubuntu 12'
gsettings set org.gnome.desktop.interface monospace-font-name 'Fira Code 11'

# Dock grande y visible
gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'LEFT'
gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 48
gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed true
gsettings set org.gnome.shell.extensions.dash-to-dock autohide false
gsettings set org.gnome.shell.extensions.dash-to-dock transparency-mode 'FIXED'
gsettings set org.gnome.shell.extensions.dash-to-dock background-opacity 0.7

# Ventanas
gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'
gsettings set org.gnome.mutter center-new-windows true

# Animaciones suaves
gsettings set org.gnome.desktop.interface enable-animations true
gsettings set org.gnome.desktop.interface enable-hot-corners true

# Wallpaper gaming
gsettings set org.gnome.desktop.background picture-uri 'file:///usr/share/backgrounds/warty-final-ubuntu.png'

# Apps favoritas gaming
gsettings set org.gnome.shell favorite-apps "['org.gnome.Nautilus.desktop', 'firefox.desktop', 'org.gnome.Software.desktop', 'org.gnome.SystemMonitor.desktop']"

notify-send "🎮 Tema Gaming" "UI gaming aplicada" -i preferences-desktop-theme
EOFGAMER

chmod +x /home/gamer01/.apply-full-theme.sh
chown gamer01:gamer01 /home/gamer01/.apply-full-theme.sh

echo "✓ Script creado: /home/gamer01/.apply-full-theme.sh"

echo ""
echo "Paso 6: Configurando AUDITOR (UI claro profesional)"
echo "────────────────────────────────────────────────────────"

cat > /home/auditor/.apply-full-theme.sh << 'EOFAUDITOR'
#!/bin/bash
# UI Claro Profesional para Auditor

# Tema claro
gsettings set org.gnome.desktop.interface gtk-theme 'Orchis-Light-Compact'
gsettings set org.gnome.desktop.interface icon-theme 'Tela'
gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Classic'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'

# Fuentes profesionales
gsettings set org.gnome.desktop.interface font-name 'Ubuntu 10'
gsettings set org.gnome.desktop.interface document-font-name 'Ubuntu 11'
gsettings set org.gnome.desktop.interface monospace-font-name 'Fira Code 10'

# Dock minimalista
gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'
gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 36
gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false
gsettings set org.gnome.shell.extensions.dash-to-dock autohide true
gsettings set org.gnome.shell.extensions.dash-to-dock intellihide true

# Ventanas
gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'
gsettings set org.gnome.mutter center-new-windows true

# Rendimiento (menos animaciones)
gsettings set org.gnome.desktop.interface enable-animations false
gsettings set org.gnome.desktop.interface enable-hot-corners false

# Wallpaper claro
gsettings set org.gnome.desktop.background picture-uri 'file:///usr/share/backgrounds/ubuntu-default-greyscale-wallpaper.png'

# Apps favoritas auditor
gsettings set org.gnome.shell favorite-apps "['org.gnome.Nautilus.desktop', 'firefox.desktop', 'org.gnome.gedit.desktop', 'org.gnome.Calculator.desktop', 'org.gnome.Terminal.desktop']"

notify-send "📊 Tema Auditor" "UI profesional clara aplicada" -i preferences-desktop-theme
EOFAUDITOR

chmod +x /home/auditor/.apply-full-theme.sh
chown auditor:auditor /home/auditor/.apply-full-theme.sh

echo "✓ Script creado: /home/auditor/.apply-full-theme.sh"

echo ""
echo "Paso 7: Creando script de optimización de rendimiento"
echo "────────────────────────────────────────────────────────"

cat > /usr/local/bin/optimize-performance << 'EOFOPT'
#!/bin/bash
# Script de optimización rápida

echo "🚀 Optimizando rendimiento..."

# Limpiar caché
sync; echo 3 > /proc/sys/vm/drop_caches

# Limpiar journald
journalctl --vacuum-time=3d &>/dev/null

# Limpiar apt
apt autoremove -y &>/dev/null
apt autoclean -y &>/dev/null

# Limpiar thumbnails viejos
find ~/.cache/thumbnails -type f -atime +7 -delete 2>/dev/null

echo "✓ Sistema optimizado"
EOFOPT

chmod +x /usr/local/bin/optimize-performance

echo "✓ Script de optimización creado: optimize-performance"

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✅ OPTIMIZACIÓN Y PERSONALIZACIÓN COMPLETADA"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "🎨 CADA USUARIO DEBE EJECUTAR SU SCRIPT:"
echo ""
echo "  👤 administrador:"
echo "     ~/.apply-full-theme.sh"
echo "     → UI profesional oscura, dock abajo, minimalista"
echo ""
echo "  🎮 gamer01:"
echo "     ~/.apply-full-theme.sh"
echo "     → UI gaming oscura, dock izquierda, grande"
echo ""
echo "  📊 auditor:"
echo "     ~/.apply-full-theme.sh"
echo "     → UI claro profesional, dock abajo, sin animaciones"
echo ""
echo "🚀 OPTIMIZACIONES APLICADAS:"
echo "  ✓ Servicios innecesarios desactivados"
echo "  ✓ Swappiness optimizado (10)"
echo "  ✓ Preload habilitado"
echo "  ✓ Sistema limpiado"
echo ""
echo "⚡ COMANDO DE OPTIMIZACIÓN:"
echo "  sudo optimize-performance"
echo "  (Ejecutar cuando el sistema esté lento)"
echo ""
echo "🔄 REINICIA LA SESIÓN para aplicar todos los cambios"
echo "════════════════════════════════════════════════════════════════"
