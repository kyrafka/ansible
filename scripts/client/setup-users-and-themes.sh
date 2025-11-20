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

# Crear/actualizar usuario auditor
if ! id auditor &>/dev/null; then
    useradd -m -s /bin/bash auditor
    echo "✓ Usuario auditor creado"
else
    echo "✓ Usuario auditor ya existe"
fi
echo "auditor:Audit123!" | chpasswd
echo "✓ Contraseña de auditor configurada: Audit123!"

# Crear/actualizar usuario gamer01
if ! id gamer01 &>/dev/null; then
    useradd -m -s /bin/bash -G pcgamers,audio,video gamer01
    echo "✓ Usuario gamer01 creado"
else
    echo "✓ Usuario gamer01 ya existe"
    usermod -aG pcgamers,audio,video gamer01
fi
echo "gamer01:Game123!" | chpasswd
echo "✓ Contraseña de gamer01 configurada: Game123!"

# Agregar administrador al grupo pcgamers
usermod -aG pcgamers administrador
echo "✓ Administrador agregado a pcgamers"

echo ""
echo "Paso 2: Instalando SSH (si no está)"
echo "────────────────────────────────────────────────────────"

if ! command -v sshd &>/dev/null; then
    apt install -y openssh-server
    systemctl enable ssh
    systemctl start ssh
    echo "✓ SSH instalado y habilitado"
else
    echo "✓ SSH ya está instalado"
fi

echo ""
echo "Paso 3: Configurando carpetas"
echo "────────────────────────────────────────────────────────"

# Crear punto de montaje NFS
mkdir -p /mnt/games
chown root:pcgamers /mnt/games
chmod 2775 /mnt/games
echo "✓ /mnt/games creado"

# Crear carpetas personales
mkdir -p /home/gamer01/{Descargas,Documentos,Juegos}
chown -R gamer01:gamer01 /home/gamer01
echo "✓ Carpetas de gamer01 verificadas"

mkdir -p /home/auditor/{Descargas,Documentos,Reportes}
chown -R auditor:auditor /home/auditor
echo "✓ Carpetas de auditor verificadas"

echo ""
echo "Paso 4: Instalando temas y herramientas"
echo "────────────────────────────────────────────────────────"

apt install -y \
    papirus-icon-theme \
    arc-theme \
    fonts-firacode \
    gnome-tweaks \
    dconf-cli \
    git &>/dev/null

echo "✓ Paquetes base instalados"

# Instalar tema Orchis (Beautiful theme)
if [ ! -d "/usr/share/themes/Orchis-Dark" ]; then
    echo "📦 Descargando tema Orchis..."
    cd /tmp
    git clone https://github.com/vinceliuice/Orchis-theme.git --depth=1 &>/dev/null
    cd Orchis-theme
    ./install.sh -t all &>/dev/null
    cd /tmp
    rm -rf Orchis-theme
    echo "✓ Tema Orchis instalado"
else
    echo "✓ Tema Orchis ya instalado"
fi

# Instalar iconos Tela
if [ ! -d "/usr/share/icons/Tela" ]; then
    echo "📦 Descargando iconos Tela..."
    cd /tmp
    git clone https://github.com/vinceliuice/Tela-icon-theme.git --depth=1 &>/dev/null
    cd Tela-icon-theme
    ./install.sh &>/dev/null
    cd /tmp
    rm -rf Tela-icon-theme
    echo "✓ Iconos Tela instalados"
else
    echo "✓ Iconos Tela ya instalados"
fi

echo "✓ Todos los temas instalados"

echo ""
echo "Paso 5: Creando scripts de tema para GAMER01 (oscuro gaming)"
echo "────────────────────────────────────────────────────────"

# Crear script de tema para gamer01
cat > /home/gamer01/.apply-theme.sh << 'EOF'
#!/bin/bash
# Tema Gaming Oscuro para gamer01
gsettings set org.gnome.desktop.interface gtk-theme 'Orchis-Dark'
gsettings set org.gnome.desktop.interface icon-theme 'Tela-dark'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'
gsettings set org.gnome.desktop.background picture-uri 'file:///usr/share/backgrounds/warty-final-ubuntu.png'
gsettings set org.gnome.desktop.interface font-name 'Ubuntu 11'
gsettings set org.gnome.desktop.interface monospace-font-name 'Fira Code 10'
notify-send "🎮 Tema Gaming" "Tema oscuro aplicado correctamente" -i preferences-desktop-theme
EOF

chmod +x /home/gamer01/.apply-theme.sh
chown gamer01:gamer01 /home/gamer01/.apply-theme.sh

# Aplicar tema ahora si el usuario tiene sesión
sudo -u gamer01 DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u gamer01)/bus" /home/gamer01/.apply-theme.sh 2>/dev/null || true

echo "✓ Script de tema creado para gamer01"
echo "  → El usuario puede ejecutar: ~/.apply-theme.sh"

echo ""
echo "Paso 6: Creando scripts de tema para AUDITOR (claro profesional)"
echo "────────────────────────────────────────────────────────"

# Crear script de tema para auditor
cat > /home/auditor/.apply-theme.sh << 'EOF'
#!/bin/bash
# Tema Claro Profesional para auditor
gsettings set org.gnome.desktop.interface gtk-theme 'Orchis-Light'
gsettings set org.gnome.desktop.interface icon-theme 'Tela'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'
gsettings set org.gnome.desktop.background picture-uri 'file:///usr/share/backgrounds/ubuntu-default-greyscale-wallpaper.png'
gsettings set org.gnome.desktop.interface font-name 'Ubuntu 11'
gsettings set org.gnome.desktop.interface monospace-font-name 'Fira Code 10'
notify-send "📊 Tema Auditor" "Tema claro aplicado correctamente" -i preferences-desktop-theme
EOF

chmod +x /home/auditor/.apply-theme.sh
chown auditor:auditor /home/auditor/.apply-theme.sh

# Aplicar tema ahora si el usuario tiene sesión
sudo -u auditor DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u auditor)/bus" /home/auditor/.apply-theme.sh 2>/dev/null || true

echo "✓ Script de tema creado para auditor"
echo "  → El usuario puede ejecutar: ~/.apply-theme.sh"

echo ""
echo "Paso 7: Creando scripts de tema para ADMINISTRADOR (oscuro profesional)"
echo "────────────────────────────────────────────────────────"

# Crear script de tema para administrador
cat > /home/administrador/.apply-theme.sh << 'EOF'
#!/bin/bash
# Tema Oscuro Profesional para administrador
gsettings set org.gnome.desktop.interface gtk-theme 'Orchis-Dark-Compact'
gsettings set org.gnome.desktop.interface icon-theme 'Tela-dark'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'
gsettings set org.gnome.desktop.background picture-uri 'file:///usr/share/backgrounds/warty-final-ubuntu.png'
gsettings set org.gnome.desktop.interface font-name 'Ubuntu 11'
gsettings set org.gnome.desktop.interface monospace-font-name 'Fira Code 10'
notify-send "⚙️ Tema Admin" "Tema oscuro profesional aplicado" -i preferences-desktop-theme
EOF

chmod +x /home/administrador/.apply-theme.sh
chown administrador:administrador /home/administrador/.apply-theme.sh

# Aplicar tema ahora si el usuario tiene sesión
sudo -u administrador DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u administrador)/bus" /home/administrador/.apply-theme.sh 2>/dev/null || true

echo "✓ Script de tema creado para administrador"
echo "  → El usuario puede ejecutar: ~/.apply-theme.sh"

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✅ CONFIGURACIÓN COMPLETADA"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "👥 Usuarios configurados:"
echo "  1. administrador - Tema oscuro profesional"
echo "  2. gamer01 - Tema oscuro gaming"
echo "  3. auditor - Tema claro profesional"
echo ""
echo "🔑 Contraseñas:"
echo "  - gamer01: Game123!"
echo "  - auditor: Audit123!"
echo ""
echo "📁 Carpetas:"
echo "  - /mnt/games (compartida para pcgamers)"
echo "  - /home/gamer01/Juegos"
echo ""
echo "🎨 Temas configurados:"
echo "  - administrador: Orchis-Dark-Compact + Tela-dark (profesional)"
echo "  - gamer01: Orchis-Dark + Tela-dark (gaming)"
echo "  - auditor: Orchis-Light + Tela (claro)"
echo ""
echo "� Cadra usuario tiene un script ~/.apply-theme.sh"
echo "   Si el tema no se aplicó automáticamente, ejecuta:"
echo "   ~/.apply-theme.sh"
echo ""
echo "🔄 Cierra sesión y entra con otro usuario para ver los cambios"
echo "════════════════════════════════════════════════════════════════"
