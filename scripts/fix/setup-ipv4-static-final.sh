#!/bin/bash

echo "════════════════════════════════════════════════════════════════"
echo "🔧 CONFIGURACIÓN IPv4 ESTÁTICA PARA SAMBA"
echo "════════════════════════════════════════════════════════════════"
echo ""

if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script debe ejecutarse como root"
    exit 1
fi

echo "Configurando IPv4 estática en ens34..."

# Limpiar IPs existentes de ens34
ip addr flush dev ens34

# Agregar IPv4 estática
ip addr add 10.0.0.1/24 dev ens34

# Agregar IPv6 estática
ip addr add 2025:db8:10::2/64 dev ens34

# Levantar interfaz
ip link set ens34 up

echo "✓ IPs configuradas"

# Hacer permanente con netplan
cat > /etc/netplan/02-lan-static.yaml << 'EOF'
network:
  version: 2
  ethernets:
    ens34:
      addresses:
        - 10.0.0.1/24
        - 2025:db8:10::2/64
EOF

netplan apply

echo "✓ Configuración permanente aplicada"

# Reiniciar Samba
systemctl restart smbd

echo "✓ Samba reiniciado"

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✅ CONFIGURACIÓN COMPLETADA"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "📋 SERVIDOR:"
echo "  IPv4: 10.0.0.1/24"
echo "  IPv6: 2025:db8:10::2/64"
echo ""
echo "🪟 EN WINDOWS (PowerShell Admin):"
echo ""
echo "  # Configurar IP estática"
echo "  New-NetIPAddress -InterfaceAlias Ethernet1 -IPAddress 10.0.0.10 -PrefixLength 24"
echo ""
echo "  # Conectar a Samba"
echo "  net use Z: \\\\10.0.0.1\\Publico /user:jose 123"
echo ""
echo "🐧 EN UBUNTU DESKTOP:"
echo ""
echo "  # Configurar IP estática"
echo "  sudo ip addr add 10.0.0.20/24 dev ens33"
echo ""
echo "  # Conectar a Samba"
echo "  smbclient //10.0.0.1/Publico -U administrador"
echo ""
echo "════════════════════════════════════════════════════════════════"
