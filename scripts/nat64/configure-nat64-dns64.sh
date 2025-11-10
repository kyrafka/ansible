#!/bin/bash
# Script para configurar NAT64 y DNS64 en el servidor
# Permite que VMs con IPv6-only salgan a internet IPv4

echo "════════════════════════════════════════════════════════"
echo "🌐 Configurando NAT64 + DNS64"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Esto configurará:"
echo "  ✓ NAT64: Traducción de paquetes IPv6 → IPv4"
echo "  ✓ DNS64: Traducción de nombres DNS"
echo "  ✓ Las VMs podrán acceder a internet con solo IPv6"
echo ""
echo "════════════════════════════════════════════════════════"
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -f "run-network.sh" ]; then
    echo "❌ Error: No se encuentra run-network.sh"
    echo "   Ejecuta este script desde el directorio de Ansible"
    exit 1
fi

# Verificar que el entorno virtual está activado
if [ -z "$VIRTUAL_ENV" ]; then
    echo "🔄 Activando entorno virtual de Ansible..."
    if [ -f ".ansible-venv/bin/activate" ]; then
        source .ansible-venv/bin/activate
    else
        echo "❌ Error: No se encuentra el entorno virtual"
        echo "   Crea el entorno con: python3 -m venv .ansible-venv"
        exit 1
    fi
fi

echo "🚀 Ejecutando playbook de Ansible..."
echo ""

# Ejecutar los playbooks
echo "1️⃣  Configurando red (NAT64)..."
ansible-playbook -i inventory/hosts.yml playbook-network.yml -K

echo ""
echo "2️⃣  Configurando DNS (DNS64)..."
ansible-playbook -i inventory/hosts.yml playbook-dns.yml -K

# Verificar el resultado
if [ $? -eq 0 ]; then
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "✅ Configuración completada exitosamente"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "📋 Verificar en el servidor:"
    echo "   sudo iptables -t nat -L -v -n"
    echo "   sudo systemctl status bind9"
    echo ""
    echo "📋 Probar en la VM:"
    echo "   nslookup google.com 2025:db8:10::2"
    echo "   ping6 google.com"
    echo ""
    echo "════════════════════════════════════════════════════════"
else
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "❌ Error en la configuración"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "Revisa los errores arriba y vuelve a intentar"
    echo ""
    exit 1
fi
