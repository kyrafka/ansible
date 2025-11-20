#!/bin/bash
# Script para arreglar problema de "Failed to start session" en XFCE
# Ejecutar: bash scripts/fix/fix-xfce-session.sh

echo "════════════════════════════════════════════════════════"
echo "🔧 Arreglando sesión XFCE"
echo "════════════════════════════════════════════════════════"
echo ""

echo "1️⃣  Reinstalando XFCE..."
sudo apt install --reinstall -y xfce4 xfce4-session xfce4-goodies lightdm
echo ""

echo "2️⃣  Configurando sesión por defecto para todos los usuarios..."
for user in ubuntu auditor dev; do
    if id "$user" &>/dev/null; then
        echo "Configurando $user..."
        sudo -u $user bash -c 'echo "xfce4-session" > ~/.xsession'
        sudo -u $user chmod +x /home/$user/.xsession
        sudo chown -R $user:$user /home/$user
        sudo chmod 755 /home/$user
    fi
done
echo ""

echo "3️⃣  Arreglando permisos de /tmp..."
sudo chmod 1777 /tmp
sudo chmod 1777 /var/tmp
echo ""

echo "4️⃣  Limpiando sesiones antiguas..."
sudo rm -rf /tmp/.X11-unix/*
sudo rm -rf /tmp/.ICE-unix/*
echo ""

echo "5️⃣  Configurando LightDM..."
sudo bash -c 'cat > /etc/lightdm/lightdm.conf << EOF
[Seat:*]
greeter-session=lightdm-gtk-greeter
user-session=xfce
allow-guest=false
EOF'
echo ""

echo "6️⃣  Reiniciando LightDM..."
sudo systemctl restart lightdm
echo ""

echo "════════════════════════════════════════════════════════"
echo "✅ Arreglo completado"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Intenta iniciar sesión de nuevo"
echo ""
echo "Si aún falla, ve los logs:"
echo "  sudo cat /var/log/lightdm/lightdm.log"
echo "  cat ~/.xsession-errors"
echo ""
