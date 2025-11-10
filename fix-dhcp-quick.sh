#!/bin/bash
# Script rápido para arreglar DHCP - Ejecutar con sudo

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script debe ejecutarse como root"
    echo "   Usa: sudo bash $0"
    exit 1
fi

echo "🔧 Arreglando configuración de DHCPv6..."

# 1. Detener servicio
echo "1️⃣  Deteniendo servicio..."
systemctl stop isc-dhcp-server6 || true

# 2. Crear directorio override si no existe
echo "2️⃣  Creando directorio override..."
mkdir -p /etc/systemd/system/isc-dhcp-server6.service.d

# 3. Crear override.conf correcto
echo "3️⃣  Configurando systemd override..."
cat > /etc/systemd/system/isc-dhcp-server6.service.d/override.conf << 'EOF'
[Unit]
After=systemd-tmpfiles-setup.service
Requires=systemd-tmpfiles-setup.service

[Service]
RuntimeDirectory=dhcp-server6
RuntimeDirectoryMode=0755
EOF

echo "   ✅ Override creado"
cat /etc/systemd/system/isc-dhcp-server6.service.d/override.conf

# 4. Configurar AppArmor
echo "4️⃣  Configurando AppArmor..."
mkdir -p /etc/apparmor.d/local
cat > /etc/apparmor.d/local/usr.sbin.dhcpd << 'EOF'
# Permisos adicionales para DHCPv6
/run/dhcp-server6/ rw,
/run/dhcp-server6/** rw,
/run/dhcp-server6/dhcpd6.pid rw,
EOF

if systemctl is-active --quiet apparmor; then
    apparmor_parser -r /etc/apparmor.d/usr.sbin.dhcpd
    echo "   ✅ AppArmor recargado"
fi

# 5. Crear directorio PID
echo "5️⃣  Creando directorio PID..."
mkdir -p /run/dhcp-server6
chown dhcpd:dhcpd /run/dhcp-server6
chmod 0755 /run/dhcp-server6
ls -la /run/dhcp-server6

# 6. Verificar archivo de leases
echo "6️⃣  Verificando archivo de leases..."
if [ ! -f /var/lib/dhcp/dhcpd6.leases ]; then
    touch /var/lib/dhcp/dhcpd6.leases
fi
chown dhcpd:dhcpd /var/lib/dhcp/dhcpd6.leases
chmod 0644 /var/lib/dhcp/dhcpd6.leases
ls -la /var/lib/dhcp/dhcpd6.leases

# 7. Recargar systemd
echo "7️⃣  Recargando systemd..."
systemctl daemon-reload

# 8. Iniciar servicio
echo "8️⃣  Iniciando servicio..."
systemctl enable isc-dhcp-server6
systemctl start isc-dhcp-server6

# 9. Esperar un momento
sleep 2

# 10. Verificar estado
echo ""
echo "🔍 Estado del servicio:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
systemctl status isc-dhcp-server6 --no-pager -l

echo ""
echo "📁 Contenido de /run/dhcp-server6/:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ls -la /run/dhcp-server6/ || echo "Directorio vacío o no existe"

echo ""
echo "📋 Últimos logs:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
journalctl -u isc-dhcp-server6 -n 20 --no-pager

echo ""
if systemctl is-active --quiet isc-dhcp-server6; then
    echo "✅ ¡Servicio DHCPv6 funcionando correctamente!"
else
    echo "❌ El servicio tiene problemas. Revisa los logs arriba."
fi
