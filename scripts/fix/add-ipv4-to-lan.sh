#!/bin/bash

echo "════════════════════════════════════════════════════════════════"
echo "🔧 AGREGAR IPv4 A LA INTERFAZ LAN PARA SAMBA"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script debe ejecutarse como root"
    echo "   Usa: sudo bash $0"
    exit 1
fi

echo "Paso 1: Verificando configuración actual"
echo "────────────────────────────────────────────────────────"

echo "Interfaces actuales:"
ip addr show | grep -E "^[0-9]+:|inet "

echo ""
echo "Paso 2: Agregando IPv4 a ens34 (LAN)"
echo "────────────────────────────────────────────────────────"

# Agregar IPv4 a ens34
ip addr add 192.168.100.1/24 dev ens34

echo "✓ IPv4 192.168.100.1/24 agregada a ens34"

echo ""
echo "Paso 3: Haciendo la configuración permanente"
echo "────────────────────────────────────────────────────────"

# Crear configuración de netplan para IPv4
cat > /etc/netplan/99-lan-ipv4.yaml << 'EOF'
network:
  version: 2
  ethernets:
    ens34:
      addresses:
        - 192.168.100.1/24
EOF

echo "✓ Configuración de netplan creada"

# Aplicar netplan
netplan apply

echo "✓ Netplan aplicado"

echo ""
echo "Paso 4: Corrigiendo configuración de Samba"
echo "────────────────────────────────────────────────────────"

# Modificar smb.conf para escuchar en todas las interfaces
sed -i 's/^   bind interfaces only = yes/   bind interfaces only = no/' /etc/samba/smb.conf
sed -i 's/^   interfaces = lo ens34/#   interfaces = lo ens34/' /etc/samba/smb.conf

echo "✓ Configuración de Samba modificada"

echo ""
echo "Paso 5: Reiniciando servicios"
echo "────────────────────────────────────────────────────────"

systemctl restart smbd nmbd

echo "✓ Samba reiniciado"

sleep 2

echo ""
echo "Paso 6: Verificando servicios"
echo "────────────────────────────────────────────────────────"

echo "Estado de smbd:"
systemctl status smbd --no-pager | head -5

echo ""
echo "Estado de nmbd:"
systemctl status nmbd --no-pager | head -5

echo ""
echo "Puertos escuchando:"
netstat -tlnp | grep -E "smbd|nmbd" | head -10

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✅ IPv4 AGREGADA Y SAMBA CONFIGURADO"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "📋 Configuración de red:"
echo "  IPv6 LAN: 2025:db8:10::1/64"
echo "  IPv4 LAN: 192.168.100.1/24"
echo ""
echo "🪟 CONECTAR DESDE WINDOWS:"
echo ""
echo "  Opción 1 - IPv4:"
echo "    \\\\192.168.100.1\\Publico"
echo ""
echo "  Opción 2 - Nombre NetBIOS:"
echo "    \\\\SERVIDOR\\Publico"
echo ""
echo "  Opción 3 - IPv6 (puede no funcionar en Windows):"
echo "    \\\\2025:db8:10::1\\Publico"
echo ""
echo "🐧 CONECTAR DESDE UBUNTU:"
echo ""
echo "  IPv6:"
echo "    smb://2025:db8:10::1"
echo ""
echo "  IPv4:"
echo "    smb://192.168.100.1"
echo ""
echo "⚠️  IMPORTANTE:"
echo "  Los clientes necesitan tener IP en la red 192.168.100.0/24"
echo "  para acceder por IPv4."
echo ""
echo "  Configura en los clientes:"
echo "    Windows: IP estática 192.168.100.X/24"
echo "    Ubuntu: IP estática 192.168.100.X/24"
echo ""
echo "════════════════════════════════════════════════════════════════"
