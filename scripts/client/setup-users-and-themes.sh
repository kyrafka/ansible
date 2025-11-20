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
echo "Paso 4: Instalando temas"
echo "────────────────────────────────────────────────────────"

apt install -y \
    papirus-icon-theme \
    arc-theme \
    fonts-firacode \
    gnome-tweaks \
    dconf-cli &>/dev/null

echo "✓ Temas instalados"

echo ""
echo "Paso 5: Configurando tema para GAMER01 (oscuro gaming)"
echo "────────────────────────────────────────────────────────"

# Configurar tema oscuro para gamer01
sudo -u gamer01 dbus-launch gsettings set org.gnome.desktop.interface gtk-theme 'Arc-Dark' 2>/dev/null || true
sudo -u gamer01 dbus-launch gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' 2>/dev/null || true
sudo -u gamer01 dbus-launch gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
sudo -u gamer01 dbus-launch gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close' 2>/dev/null || true

# Wallpaper oscuro
sudo -u gamer01 dbus-launch gsettings set org.gnome.desktop.background picture-uri 'file:///usr/share/backgrounds/warty-final-ubuntu.png' 2>/dev/null || true

echo "✓ Tema gaming aplicado a gamer01"

echo ""
echo "Paso 6: Configurando tema para AUDITOR (claro profesional)"
echo "────────────────────────────────────────────────────────"

# Configurar tema claro para auditor
sudo -u auditor dbus-launch gsettings set org.gnome.desktop.interface gtk-theme 'Yaru' 2>/dev/null || true
sudo -u auditor dbus-launch gsettings set org.gnome.desktop.interface icon-theme 'Papirus' 2>/dev/null || true
sudo -u auditor dbus-launch gsettings set org.gnome.desktop.interface color-scheme 'prefer-light' 2>/dev/null || true

echo "✓ Tema claro aplicado a auditor"

echo ""
echo "Paso 7: Configurando tema para ADMINISTRADOR (oscuro profesional)"
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
echo "🎨 Temas aplicados:"
echo "  - administrador: Yaru-dark + Papirus-Dark"
echo "  - gamer01: Arc-Dark + Papirus-Dark"
echo "  - auditor: Yaru + Papirus"
echo ""
echo "🔄 Cierra sesión y entra con otro usuario para ver los cambios"
echo "════════════════════════════════════════════════════════════════"
