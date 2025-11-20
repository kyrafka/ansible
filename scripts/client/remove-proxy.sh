#!/bin/bash

echo "════════════════════════════════════════════════════════════════"
echo "🧹 ELIMINAR CONFIGURACIÓN DE PROXY"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Este script eliminará toda la configuración de proxy del sistema."
echo "Ahora usarás NAT64 directamente (sin proxy)."
echo ""
echo "⚠️  IMPORTANTE: Ejecuta esto DESDE EL CLIENTE, no desde el servidor"
echo ""
read -p "¿Continuar? (s/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "❌ Cancelado"
    exit 1
fi

echo ""
echo "🔧 Eliminando configuración de proxy..."
echo ""

# 1. Eliminar proxy de APT
echo "1️⃣  Eliminando proxy de APT..."
sudo rm -f /etc/apt/apt.conf.d/proxy.conf
echo "   ✓ Proxy APT eliminado"
echo ""

# 2. Eliminar proxy de /etc/environment
echo "2️⃣  Eliminando proxy de /etc/environment..."
sudo sed -i '/^http_proxy=/d' /etc/environment
sudo sed -i '/^https_proxy=/d' /etc/environment
sudo sed -i '/^HTTP_PROXY=/d' /etc/environment
sudo sed -i '/^HTTPS_PROXY=/d' /etc/environment
sudo sed -i '/^no_proxy=/d' /etc/environment
sudo sed -i '/^NO_PROXY=/d' /etc/environment
sudo sed -i '/^# Proxy configuration/d' /etc/environment
echo "   ✓ Variables de entorno eliminadas"
echo ""

# 3. Eliminar proxy de ~/.bashrc
echo "3️⃣  Eliminando proxy de ~/.bashrc..."
sed -i '/^export http_proxy=/d' ~/.bashrc
sed -i '/^export https_proxy=/d' ~/.bashrc
sed -i '/^export HTTP_PROXY=/d' ~/.bashrc
sed -i '/^export HTTPS_PROXY=/d' ~/.bashrc
sed -i '/^export no_proxy=/d' ~/.bashrc
sed -i '/^export NO_PROXY=/d' ~/.bashrc
echo "   ✓ Proxy de usuario eliminado"
echo ""

# 4. Desactivar proxy del sistema (GNOME)
echo "4️⃣  Desactivando proxy del sistema (GNOME)..."
gsettings set org.gnome.system.proxy mode 'none' 2>/dev/null || echo "   ⚠️  No se pudo cambiar (puede que no uses GNOME)"
echo "   ✓ Proxy del sistema desactivado"
echo ""

# 5. Limpiar variables de entorno actuales
echo "5️⃣  Limpiando variables de entorno de la sesión actual..."
unset http_proxy
unset https_proxy
unset HTTP_PROXY
unset HTTPS_PROXY
unset no_proxy
unset NO_PROXY
echo "   ✓ Variables limpiadas"
echo ""

# 6. Verificar
echo "6️⃣  Verificando..."
if grep -q "proxy" /etc/environment 2>/dev/null; then
    echo "   ⚠️  Aún hay referencias a proxy en /etc/environment"
else
    echo "   ✅ /etc/environment limpio"
fi

if [ -f /etc/apt/apt.conf.d/proxy.conf ]; then
    echo "   ⚠️  Archivo de proxy APT aún existe"
else
    echo "   ✅ Proxy APT eliminado"
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✅ PROXY ELIMINADO"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "🔄 Para aplicar los cambios completamente:"
echo ""
echo "  1. Cierra esta terminal y abre una nueva"
echo "  2. O ejecuta: source ~/.bashrc"
echo "  3. O reinicia la sesión (logout/login)"
echo ""
echo "🧪 Prueba la conectividad:"
echo ""
echo "  # Verificar que no hay proxy"
echo "  env | grep -i proxy"
echo ""
echo "  # Probar curl sin proxy"
echo "  curl -6 http://google.com"
echo ""
echo "  # Probar apt"
echo "  sudo apt update"
echo ""
echo "  # Navegar en Firefox"
echo "  firefox http://www.google.com"
echo ""
echo "════════════════════════════════════════════════════════════════"
