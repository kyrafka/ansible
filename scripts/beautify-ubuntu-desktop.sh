#!/bin/bash
# Script para mejorar visualmente Ubuntu Desktop

# Auto-permisos
[ ! -x "$0" ] && chmod +x "$0" 2>/dev/null

echo "════════════════════════════════════════════════════════"
echo "🎨 Mejorando Ubuntu Desktop visualmente"
echo "════════════════════════════════════════════════════════"
echo ""

echo "1️⃣  Instalando herramientas de personalización..."
sudo apt update
sudo apt install -y \
    gnome-tweaks \
    gnome-shell-extensions \
    chrome-gnome-shell \
    dconf-editor \
    papirus-icon-theme \
    fonts-firacode \
    fonts-noto-color-emoji

echo ""
echo "2️⃣  Configurando tema e iconos..."

# Tema oscuro mejorado
gsettings set org.gnome.desktop.interface gtk-theme 'Yaru-dark'
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
gsettings set org.gnome.desktop.interface cursor-theme 'Yaru'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

echo "  ✓ Tema oscuro + iconos Papirus"

echo ""
echo "3️⃣  Configurando fuentes..."

# Fuentes mejoradas
gsettings set org.gnome.desktop.interface font-name 'Ubuntu 11'
gsettings set org.gnome.desktop.interface document-font-name 'Ubuntu 11'
gsettings set org.gnome.desktop.interface monospace-font-name 'Fira Code 10'
gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Ubuntu Bold 11'

# Antialiasing
gsettings set org.gnome.desktop.interface font-antialiasing 'rgba'
gsettings set org.gnome.desktop.interface font-hinting 'slight'

echo "  ✓ Fuentes configuradas (Fira Code para terminal)"

echo ""
echo "4️⃣  Configurando dock..."

# Dock más bonito
gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'
gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 48
gsettings set org.gnome.shell.extensions.dash-to-dock transparency-mode 'DYNAMIC'
gsettings set org.gnome.shell.extensions.dash-to-dock show-trash false
gsettings set org.gnome.shell.extensions.dash-to-dock show-mounts false

echo "  ✓ Dock configurado (abajo, transparente, iconos 48px)"

echo ""
echo "5️⃣  Configurando escritorio..."

# Escritorio limpio
gsettings set org.gnome.desktop.background show-desktop-icons false
gsettings set org.gnome.shell.extensions.ding show-home false
gsettings set org.gnome.shell.extensions.ding show-trash false

# Wallpaper oscuro
gsettings set org.gnome.desktop.background picture-uri 'file:///usr/share/backgrounds/ubuntu-default-greyscale-wallpaper.png'
gsettings set org.gnome.desktop.background picture-uri-dark 'file:///usr/share/backgrounds/ubuntu-default-greyscale-wallpaper.png'

echo "  ✓ Escritorio limpio y minimalista"

echo ""
echo "6️⃣  Configurando ventanas..."

# Botones de ventana a la derecha (estilo Windows)
gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'

# Centrar ventanas nuevas
gsettings set org.gnome.mutter center-new-windows true

echo "  ✓ Botones a la derecha, ventanas centradas"

echo ""
echo "7️⃣  Configurando terminal..."

# Terminal con Fira Code y tema oscuro
PROFILE=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE/ font 'Fira Code 11'
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE/ use-system-font false
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE/ use-theme-colors false
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE/ background-color '#1E1E1E'
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE/ foreground-color '#D4D4D4'
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE/ palette "['#000000', '#CD3131', '#0DBC79', '#E5E510', '#2472C8', '#BC3FBC', '#11A8CD', '#E5E5E5', '#666666', '#F14C4C', '#23D18B', '#F5F543', '#3B8EEA', '#D670D6', '#29B8DB', '#E5E5E5']"

echo "  ✓ Terminal con Fira Code y colores VS Code"

echo ""
echo "8️⃣  Configurando gestos y atajos..."

# Hot corner desactivado (no molesta)
gsettings set org.gnome.desktop.interface enable-hot-corners false

# Atajos útiles
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'Terminal'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'gnome-terminal'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Primary><Alt>t'

echo "  ✓ Ctrl+Alt+T abre terminal"

echo ""
echo "9️⃣  Configurando rendimiento..."

# Desactivar búsqueda de archivos en segundo plano
gsettings set org.gnome.desktop.search-providers disabled "['org.gnome.Nautilus.desktop']"

# Desactivar animaciones (ya lo hicimos pero por si acaso)
gsettings set org.gnome.desktop.interface enable-animations false

echo "  ✓ Optimizaciones de rendimiento aplicadas"

echo ""
echo "🔟 Limpiando y optimizando..."

# Limpiar paquetes innecesarios
sudo apt autoremove -y
sudo apt autoclean -y

echo "  ✓ Sistema limpio"

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ Ubuntu Desktop mejorado"
echo "════════════════════════════════════════════════════════"
echo ""
echo "🎨 Cambios aplicados:"
echo ""
echo "  ✓ Tema: Yaru Dark"
echo "  ✓ Iconos: Papirus Dark"
echo "  ✓ Fuentes: Ubuntu + Fira Code"
echo "  ✓ Dock: Abajo, transparente, 48px"
echo "  ✓ Escritorio: Limpio y minimalista"
echo "  ✓ Terminal: Fira Code + colores VS Code"
echo "  ✓ Atajos: Ctrl+Alt+T para terminal"
echo ""
echo "🔧 Herramientas instaladas:"
echo ""
echo "  • GNOME Tweaks - Personalización avanzada"
echo "  • dconf Editor - Configuración del sistema"
echo "  • Papirus Icons - Iconos modernos"
echo "  • Fira Code - Fuente para programadores"
echo ""
echo "📋 Para más personalización:"
echo ""
echo "  Abre 'Retoques' (GNOME Tweaks):"
echo "    - Apariencia → Más temas e iconos"
echo "    - Extensiones → Activar/desactivar"
echo "    - Fuentes → Ajustar tamaños"
echo ""
echo "════════════════════════════════════════════════════════"
echo ""
echo "⚠️  Reinicia la sesión para ver todos los cambios:"
echo "   Alt+F2 → Escribe 'r' → Enter"
echo "   O cierra sesión y vuelve a entrar"
echo ""
echo "════════════════════════════════════════════════════════"
