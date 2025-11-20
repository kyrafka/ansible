#!/bin/bash
# Script para configurar Ubuntu Desktop con Proxy Squid

echo "════════════════════════════════════════════════════════"
echo "🖥️  Configuración de Ubuntu Desktop con Proxy"
echo "════════════════════════════════════════════════════════"
echo ""

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script debe ejecutarse como root"
    echo "   Usa: sudo bash $0"
    exit 1
fi

PROXY_SERVER="http://[2025:db8:10::2]:3128"

echo "Paso 1: Configurando DNS"
echo "────────────────────────────────────────────────────────"

# Deshabilitar systemd-resolved
systemctl stop systemd-resolved
systemctl disable systemd-resolved

# Configurar DNS
rm -f /etc/resolv.conf
cat > /etc/resolv.conf << EOF
nameserver 2025:db8:10::2
search gamecenter.lan
EOF

chattr +i /etc/resolv.conf
echo "✓ DNS configurado (2025:db8:10::2)"

echo ""
echo "Paso 2: Configurando proxy"
echo "────────────────────────────────────────────────────────"

# Configurar proxy para APT
cat > /etc/apt/apt.conf.d/proxy.conf << EOF
Acquire::http::Proxy "${PROXY_SERVER}";
Acquire::https::Proxy "${PROXY_SERVER}";
EOF
echo "✓ Proxy APT configurado"

# Configurar proxy del sistema
cat >> /etc/environment << EOF

# Proxy configuration
http_proxy="${PROXY_SERVER}"
https_proxy="${PROXY_SERVER}"
HTTP_PROXY="${PROXY_SERVER}"
HTTPS_PROXY="${PROXY_SERVER}"
no_proxy="localhost,127.0.0.1,::1,2025:db8:10::/64"
NO_PROXY="localhost,127.0.0.1,::1,2025:db8:10::/64"
EOF
echo "✓ Variables de entorno configuradas"

# Aplicar proxy ahora
export http_proxy="${PROXY_SERVER}"
export https_proxy="${PROXY_SERVER}"

echo ""
echo "Paso 3: Actualizando sistema"
echo "────────────────────────────────────────────────────────"
apt update
echo "✓ Cache actualizado"

echo ""
echo "Paso 4: Instalando paquetes necesarios"
echo "────────────────────────────────────────────────────────"
apt install -y \
    openssh-server \
    python3 \
    python3-pip \
    git \
    curl \
    wget \
    nfs-common

echo "✓ Paquetes instalados"

echo ""
echo "Paso 5: Configurando SSH"
echo "────────────────────────────────────────────────────────"
systemctl enable ssh
systemctl start ssh
echo "✓ SSH activo"

echo ""
echo "Paso 6: Configurando proxy del sistema (GNOME)"
echo "────────────────────────────────────────────────────────"

# Configurar proxy del sistema (Firefox lo usará automáticamente)
sudo -u administrador DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u administrador)/bus" \
    gsettings set org.gnome.system.proxy mode 'manual' 2>/dev/null || true
sudo -u administrador DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u administrador)/bus" \
    gsettings set org.gnome.system.proxy.http host '2025:db8:10::2' 2>/dev/null || true
sudo -u administrador DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u administrador)/bus" \
    gsettings set org.gnome.system.proxy.http port 3128 2>/dev/null || true
sudo -u administrador DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u administrador)/bus" \
    gsettings set org.gnome.system.proxy.https host '2025:db8:10::2' 2>/dev/null || true
sudo -u administrador DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u administrador)/bus" \
    gsettings set org.gnome.system.proxy.https port 3128 2>/dev/null || true

echo "✓ Proxy del sistema configurado"

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ Configuración completada"
echo "════════════════════════════════════════════════════════"
echo ""
echo "📋 Resumen:"
echo "  ✓ DNS configurado (2025:db8:10::2)"
echo "  ✓ Proxy configurado (http://[2025:db8:10::2]:3128)"
echo "  ✓ APT puede descargar paquetes"
echo "  ✓ SSH activo"
echo ""
echo "🧪 Prueba la conectividad:"
echo ""
echo "  # Probar proxy"
echo "  curl http://google.com"
echo ""
echo "  # Navegar en Firefox"
echo "  firefox http://www.google.com"
echo ""
echo "  # Actualizar paquetes"
echo "  sudo apt update"
echo ""
echo "════════════════════════════════════════════════════════"
