#!/bin/bash
# Script de bootstrap para VMs Ubuntu Desktop
# Ejecutar DENTRO de la VM para configurar proxy y SSH

echo "════════════════════════════════════════"
echo "🚀 Configuración inicial de VM"
echo "════════════════════════════════════════"

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script debe ejecutarse como root"
    echo "   Usa: sudo bash $0"
    exit 1
fi

PROXY_SERVER="http://[2025:db8:10::2]:3128"

echo "1️⃣  Configurando proxy para APT..."
cat > /etc/apt/apt.conf.d/proxy.conf << EOF
Acquire::http::Proxy "${PROXY_SERVER}";
Acquire::https::Proxy "${PROXY_SERVER}";
EOF

echo "   ✓ Proxy APT configurado"

echo ""
echo "2️⃣  Configurando proxy del sistema..."
cat >> /etc/environment << EOF

# Proxy configuration
http_proxy="${PROXY_SERVER}"
https_proxy="${PROXY_SERVER}"
HTTP_PROXY="${PROXY_SERVER}"
HTTPS_PROXY="${PROXY_SERVER}"
no_proxy="localhost,127.0.0.1,::1,2025:db8:10::/64"
NO_PROXY="localhost,127.0.0.1,::1,2025:db8:10::/64"
EOF

echo "   ✓ Variables de entorno configuradas"

echo ""
echo "3️⃣  Actualizando cache de APT..."
export http_proxy="${PROXY_SERVER}"
export https_proxy="${PROXY_SERVER}"
apt update

echo ""
echo "4️⃣  Instalando OpenSSH Server..."
apt install -y openssh-server

echo ""
echo "5️⃣  Habilitando SSH..."
systemctl enable ssh
systemctl start ssh

echo ""
echo "6️⃣  Verificando SSH..."
if systemctl is-active --quiet ssh; then
    echo "   ✓ SSH está corriendo"
else
    echo "   ❌ Error al iniciar SSH"
    exit 1
fi

echo ""
echo "════════════════════════════════════════"
echo "✅ Configuración completada"
echo "════════════════════════════════════════"
echo ""
echo "La VM ahora tiene:"
echo "  ✓ Proxy configurado"
echo "  ✓ APT funcionando"
echo "  ✓ SSH activo"
echo ""
echo "Desde el servidor puedes conectarte con:"
echo "  ssh administrador@$(hostname -I | awk '{print $2}')"
echo ""
echo "════════════════════════════════════════"
