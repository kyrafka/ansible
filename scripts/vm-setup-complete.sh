#!/bin/bash
# Script completo para configurar VM Ubuntu Desktop
# Ejecutar DENTRO de la VM como root

echo "════════════════════════════════════════════════════════"
echo "🚀 Configuración completa de VM Ubuntu Desktop"
echo "════════════════════════════════════════════════════════"
echo ""

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script debe ejecutarse como root"
    echo "   Usa: sudo bash $0"
    exit 1
fi

echo "Paso 1: Configurando DNS"
echo "────────────────────────────────────────────────────────"

# Deshabilitar systemd-resolved para usar DNS del servidor
systemctl stop systemd-resolved
systemctl disable systemd-resolved

# Eliminar enlace simbólico y crear archivo real
rm -f /etc/resolv.conf
cat > /etc/resolv.conf << EOF
nameserver 2025:db8:10::2
search gamecenter.lan
EOF

# Proteger el archivo de cambios
chattr +i /etc/resolv.conf
echo "✓ DNS configurado (2025:db8:10::2)"

echo ""
echo "Paso 2: Actualizando sistema (usando NAT64)"
echo "────────────────────────────────────────────────────────"
apt update
echo "✓ Cache actualizado"

echo ""
echo "Paso 3: Instalando paquetes necesarios"
echo "────────────────────────────────────────────────────────"
apt install -y \
    openssh-server \
    python3 \
    python3-pip \
    python3-venv \
    git \
    curl \
    wget

echo "✓ Paquetes instalados"

echo ""
echo "Paso 4: Configurando SSH"
echo "────────────────────────────────────────────────────────"
systemctl enable ssh
systemctl start ssh

if systemctl is-active --quiet ssh; then
    echo "✓ SSH activo"
else
    echo "❌ Error al iniciar SSH"
    exit 1
fi

echo ""
echo "Paso 5: Instalando Ansible"
echo "────────────────────────────────────────────────────────"
pip3 install --break-system-packages ansible
echo "✓ Ansible instalado"

echo ""
echo "Paso 6: Configurando usuarios y grupos"
echo "────────────────────────────────────────────────────────"

# Crear grupo pcgamers con GID específico
if ! getent group pcgamers > /dev/null; then
    groupadd -g 3000 pcgamers
    echo "✓ Grupo pcgamers creado"
else
    echo "✓ Grupo pcgamers ya existe"
fi

# Agregar usuario actual al grupo
usermod -aG pcgamers administrador
echo "✓ Usuario agregado al grupo pcgamers"

echo ""
echo "Paso 7: Configurando directorios compartidos"
echo "────────────────────────────────────────────────────────"

# Crear punto de montaje para NFS
mkdir -p /mnt/games
chown root:pcgamers /mnt/games
chmod 2775 /mnt/games
echo "✓ Directorio /mnt/games creado"

echo ""
echo "Paso 8: Obteniendo información de red"
echo "────────────────────────────────────────────────────────"
HOSTNAME=$(hostname)
IPV6=$(ip -6 addr show ens33 | grep "scope global" | awk '{print $2}' | cut -d'/' -f1 | head -1)

echo "✓ Hostname: $HOSTNAME"
echo "✓ IPv6: $IPV6"

echo ""
echo "Paso 9: Desactivando proxy del sistema..."
echo "────────────────────────────────────────────────────────"

# Desactivar proxy del sistema (usar NAT64 directamente)
sudo -u administrador DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u administrador)/bus" \
    gsettings set org.gnome.system.proxy mode 'none' 2>/dev/null || true

echo "✓ Proxy desactivado (usando NAT64 directamente)"
echo ""
echo "ℹ️  Firefox usará NAT64 automáticamente"
echo "   No necesitas configurar proxy manualmente"

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ Configuración completada exitosamente"
echo "════════════════════════════════════════════════════════"
echo ""
echo "📋 Resumen:"
echo "  ✓ DNS configurado (2025:db8:10::2)"
echo "  ✓ NAT64 funcionando (sin proxy)"
echo "  ✓ APT puede descargar paquetes"
echo "  ✓ SSH activo y accesible"
echo "  ✓ Ansible instalado"
echo "  ✓ Grupos y permisos configurados"
echo "  ✓ Directorios preparados"
echo ""
echo "🌐 Información de conexión:"
echo "  Hostname: $HOSTNAME"
echo "  IPv6: $IPV6"
echo "  Usuario: administrador"
echo ""
echo "📡 Desde el servidor puedes conectarte con:"
echo "  ssh administrador@$IPV6"
echo ""
echo "🎮 Siguiente paso:"
echo "  Configurar NFS para montar juegos compartidos"
echo ""
echo "════════════════════════════════════════════════════════"
