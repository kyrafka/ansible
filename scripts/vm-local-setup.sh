#!/bin/bash
# Script para ejecutar DENTRO de la VM Ubuntu Desktop
# Configura cosas que requieren sesión gráfica

# Auto-permisos
[ ! -x "$0" ] && chmod +x "$0" 2>/dev/null

echo "════════════════════════════════════════════════════════"
echo "🖥️  Configuración local de Ubuntu Desktop"
echo "════════════════════════════════════════════════════════"
echo ""

# Verificar que estamos en una sesión gráfica
if [ -z "$DISPLAY" ]; then
    echo "⚠️  Advertencia: No hay sesión gráfica activa"
    echo "   Algunas configuraciones de GNOME no funcionarán"
    echo ""
fi

echo "1️⃣  Optimizando GNOME..."

# Tema oscuro
gsettings set org.gnome.desktop.interface gtk-theme 'Yaru-dark' 2>/dev/null && echo "  ✓ Tema oscuro activado" || echo "  ⚠️  No se pudo cambiar tema"
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null

# Desactivar animaciones (mejor rendimiento)
gsettings set org.gnome.desktop.interface enable-animations false 2>/dev/null && echo "  ✓ Animaciones desactivadas"
gsettings set org.gnome.desktop.interface gtk-enable-animations false 2>/dev/null

# Optimizar workspaces
gsettings set org.gnome.mutter dynamic-workspaces false 2>/dev/null && echo "  ✓ Workspaces optimizados"
gsettings set org.gnome.shell.overrides workspaces-only-on-primary true 2>/dev/null

echo ""
echo "2️⃣  Verificando conectividad..."

# Verificar internet
if ping6 -c 1 google.com > /dev/null 2>&1; then
    echo "  ✓ Internet funcionando"
else
    echo "  ❌ Sin internet - Verifica NAT64/DNS64"
fi

# Verificar DNS
if dig ubuntu123.gamecenter.lan AAAA +short > /dev/null 2>&1; then
    echo "  ✓ DNS funcionando"
else
    echo "  ⚠️  DNS no responde"
fi

echo ""
echo "3️⃣  Verificando montajes NFS..."

if mountpoint -q /mnt/games; then
    echo "  ✓ NFS montado en /mnt/games"
else
    echo "  ⚠️  NFS no montado"
    echo ""
    echo "  Para montar NFS, ejecuta en el SERVIDOR:"
    echo "    sudo mkdir -p /srv/nfs/games"
    echo "    sudo chmod 777 /srv/nfs/games"
    echo "    echo '/srv/nfs/games 2025:db8:10::/64(rw,sync,no_subtree_check)' | sudo tee -a /etc/exports"
    echo "    sudo exportfs -ra"
    echo ""
    echo "  Luego en la VM:"
    echo "    sudo mount -t nfs [2025:db8:10::2]:/srv/nfs/games /mnt/games"
fi

echo ""
echo "4️⃣  Creando enlaces útiles..."

# Crear enlace a juegos compartidos en el escritorio
if [ -d "/mnt/games" ]; then
    ln -sf /mnt/games ~/Escritorio/JuegosCompartidos 2>/dev/null && echo "  ✓ Enlace a juegos en escritorio"
    ln -sf /mnt/games ~/Desktop/SharedGames 2>/dev/null
fi

echo ""
echo "5️⃣  Información del sistema..."

echo ""
echo "  Usuario actual: $(whoami)"
echo "  Hostname: $(hostname)"
echo "  IPv6: $(ip -6 addr show ens33 | grep 'scope global' | awk '{print $2}' | cut -d'/' -f1 | head -1)"
echo "  Grupos: $(groups)"

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ Configuración completada"
echo "════════════════════════════════════════════════════════"
echo ""
echo "📋 Comandos útiles:"
echo ""
echo "  Ver IP:"
echo "    ip -6 addr show ens33 | grep 'scope global'"
echo ""
echo "  Probar internet:"
echo "    ping6 google.com"
echo ""
echo "  Probar DNS:"
echo "    dig ubuntu123.gamecenter.lan AAAA"
echo ""
echo "  SSH al servidor:"
echo "    ssh ubuntu@2025:db8:10::2"
echo ""
echo "  Ver juegos compartidos:"
echo "    ls /mnt/games"
echo ""
echo "════════════════════════════════════════════════════════"
echo ""
echo "🎮 Para instalar software de gaming:"
echo ""
echo "  Steam:"
echo "    sudo apt install steam-installer -y"
echo ""
echo "  Lutris:"
echo "    sudo add-apt-repository ppa:lutris-team/lutris -y"
echo "    sudo apt update && sudo apt install lutris -y"
echo ""
echo "  Wine:"
echo "    sudo apt install wine winetricks -y"
echo ""
echo "════════════════════════════════════════════════════════"
