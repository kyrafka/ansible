#!/bin/bash

echo "════════════════════════════════════════════════════════════════"
echo "🎮 OPTIMIZAR UBUNTU DESKTOP PARA GAMING"
echo "════════════════════════════════════════════════════════════════"
echo ""

if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script debe ejecutarse como root"
    echo "   Usa: sudo bash $0"
    exit 1
fi

echo "Paso 1: Instalando herramientas de VM"
echo "────────────────────────────────────────────────────────"

# Detectar si es VMware o VirtualBox
if lspci | grep -i vmware &>/dev/null; then
    echo "Detectado: VMware"
    apt install -y open-vm-tools open-vm-tools-desktop
    echo "✓ VMware Tools instalado"
elif lspci | grep -i virtualbox &>/dev/null; then
    echo "Detectado: VirtualBox"
    apt install -y virtualbox-guest-utils virtualbox-guest-x11 virtualbox-guest-dkms
    echo "✓ VirtualBox Guest Additions instalado"
else
    echo "⚠️  No se detectó VMware ni VirtualBox"
fi

echo ""
echo "Paso 2: Optimizando rendimiento gráfico"
echo "────────────────────────────────────────────────────────"

# Instalar drivers y aceleración
apt install -y mesa-utils libgl1-mesa-dri libgl1-mesa-glx

# Habilitar aceleración 3D
echo "✓ Drivers gráficos instalados"

echo ""
echo "Paso 3: Optimizando sistema para gaming"
echo "────────────────────────────────────────────────────────"

# Desactivar efectos visuales pesados
sudo -u administrador dbus-launch gsettings set org.gnome.desktop.interface enable-animations false 2>/dev/null || true

# Optimizar swappiness
echo "vm.swappiness=10" > /etc/sysctl.d/99-gaming.conf
sysctl -p /etc/sysctl.d/99-gaming.conf &>/dev/null

# Prioridad de CPU para juegos
echo "✓ Swappiness optimizado"

echo ""
echo "Paso 4: Configurando mouse para gaming"
echo "────────────────────────────────────────────────────────"

# Crear configuración de mouse
cat > /etc/X11/xorg.conf.d/50-mouse.conf << 'EOF'
Section "InputClass"
    Identifier "Mouse"
    MatchIsPointer "yes"
    Driver "libinput"
    Option "AccelProfile" "flat"
    Option "AccelSpeed" "0"
EndSection
EOF

echo "✓ Configuración de mouse creada"

echo ""
echo "Paso 5: Instalando herramientas de gaming"
echo "────────────────────────────────────────────────────────"

# Instalar gamemode (optimiza CPU/GPU para juegos)
apt install -y gamemode

# Instalar herramientas de rendimiento
apt install -y htop iotop

echo "✓ Herramientas instaladas"

echo ""
echo "Paso 6: Configurando Teeworlds"
echo "────────────────────────────────────────────────────────"

# Crear configuración optimizada de Teeworlds
mkdir -p /home/administrador/.teeworlds
cat > /home/administrador/.teeworlds/settings.cfg << 'EOF'
gfx_vsync 0
gfx_refresh_rate 60
gfx_screen_width 1280
gfx_screen_height 720
gfx_fullscreen 0
inp_mousesens 100
cl_mouse_deadzone 0
cl_mouse_followfactor 0
cl_mouse_max_distance 400
EOF

chown -R administrador:administrador /home/administrador/.teeworlds

echo "✓ Configuración de Teeworlds creada"

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✅ OPTIMIZACIÓN COMPLETADA"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "🎮 MEJORAS APLICADAS:"
echo "  ✓ Herramientas de VM instaladas"
echo "  ✓ Drivers gráficos optimizados"
echo "  ✓ Swappiness reducido (10)"
echo "  ✓ Animaciones desactivadas"
echo "  ✓ Mouse configurado para gaming"
echo "  ✓ Gamemode instalado"
echo "  ✓ Teeworlds configurado"
echo ""
echo "⚠️  IMPORTANTE: REINICIA LA VM"
echo "   sudo reboot"
echo ""
echo "🎮 DESPUÉS DEL REINICIO:"
echo "  1. El mouse debería funcionar mejor"
echo "  2. Inicia Teeworlds: teeworlds"
echo "  3. Si el mouse sigue sin funcionar, verifica:"
echo "     - Que VMware Tools esté instalado"
echo "     - Que la aceleración 3D esté habilitada en VMware"
echo ""
echo "🚀 PARA MEJOR RENDIMIENTO:"
echo "  - Aumenta RAM de la VM (mínimo 2GB)"
echo "  - Habilita aceleración 3D en VMware"
echo "  - Aumenta memoria de video (128MB+)"
echo ""
echo "════════════════════════════════════════════════════════════════"
