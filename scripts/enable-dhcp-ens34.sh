#!/bin/bash
# Script para habilitar DHCP en ens34

echo "🔧 Configurando DHCP en ens34..."

sudo bash -c 'cat > /etc/netplan/99-ens34-dhcp.yaml << EOF
network:
  version: 2
  ethernets:
    ens34:
      dhcp4: false
      dhcp6: true
      accept-ra: true
      nameservers:
        addresses:
          - 2025:db8:10::2
        search:
          - gamecenter.lan
EOF'

echo "✅ Configuración creada"
echo "🔄 Aplicando netplan..."

sudo netplan apply

echo "⏸️  Esperando 5 segundos..."
sleep 5

echo ""
echo "📋 Estado de ens34:"
ip -6 addr show ens34

echo ""
echo "📋 Rutas:"
ip -6 route

echo ""
if ip -6 addr show ens34 | grep "2025:db8:10" > /dev/null; then
    echo "✅ IP asignada correctamente"
else
    echo "❌ No se asignó IP - Verifica que el servidor DHCP esté corriendo"
    echo "   En el servidor ejecuta: sudo systemctl status isc-dhcp-server6"
fi
