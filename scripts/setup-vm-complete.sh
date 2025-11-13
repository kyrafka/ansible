#!/bin/bash
# Script completo para configurar VM Ubuntu Desktop

# Auto-permisos
[ ! -x "$0" ] && chmod +x "$0" 2>/dev/null

set -e

echo "════════════════════════════════════════"
echo "🚀 Configuración completa de VM"
echo "════════════════════════════════════════"
echo ""

cd "$(dirname "$0")/.."

echo "Paso 1: Instalar Squid Proxy en el servidor"
echo "────────────────────────────────────────"
sudo bash scripts/install-squid-proxy.sh

echo ""
echo "Paso 2: Configurar proxy en la VM"
echo "────────────────────────────────────────"
echo ""
echo "⚠️  IMPORTANTE: Primero debes configurar SSH manualmente en la VM"
echo ""
echo "En la VM (ubuntu123), ejecuta:"
echo "  1. sudo apt install openssh-server -y"
echo "     (Si falla, usa el proxy manualmente primero)"
echo ""
echo "  2. Configura el proxy temporalmente:"
echo "     echo 'Acquire::http::Proxy \"http://[2025:db8:10::2]:3128\";' | sudo tee /etc/apt/apt.conf.d/proxy.conf"
echo "     sudo apt update"
echo "     sudo apt install openssh-server -y"
echo ""
echo "  3. Verifica que SSH esté corriendo:"
echo "     sudo systemctl status ssh"
echo ""
read -p "¿SSH está instalado y corriendo en la VM? (s/n): " respuesta

if [[ "$respuesta" != "s" && "$respuesta" != "S" ]]; then
    echo "❌ Configura SSH primero y vuelve a ejecutar este script"
    exit 1
fi

echo ""
echo "Paso 3: Probar conexión SSH"
echo "────────────────────────────────────────"
ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 administrador@2025:db8:10::dce9 "echo 'Conexión exitosa'" || {
    echo "❌ No se pudo conectar por SSH"
    echo "   Verifica que SSH esté corriendo en la VM"
    exit 1
}

echo "✓ Conexión SSH exitosa"
echo ""

echo "Paso 4: Ejecutar playbook de configuración"
echo "────────────────────────────────────────"
ansible-playbook -i inventory.yml playbooks/configure-vm-proxy.yml

echo ""
echo "════════════════════════════════════════"
echo "✅ Configuración completada"
echo "════════════════════════════════════════"
echo ""
echo "Tu VM ahora tiene:"
echo "  ✓ Proxy configurado"
echo "  ✓ APT funcionando"
echo "  ✓ SSH activo"
echo "  ✓ Internet completo"
echo ""
echo "Puedes conectarte con:"
echo "  ssh administrador@2025:db8:10::dce9"
echo ""
echo "════════════════════════════════════════"
