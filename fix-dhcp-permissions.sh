#!/bin/bash
# Script para corregir permisos de DHCPv6 y AppArmor

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script debe ejecutarse como root"
    echo "   Usa: sudo bash $0"
    exit 1
fi

set -e

echo "🔧 Corrigiendo permisos de DHCPv6..."

# 1. Verificar y crear usuario/grupo dhcpd
echo "1️⃣  Verificando usuario dhcpd..."
if ! id dhcpd &>/dev/null; then
    echo "   Creando usuario dhcpd..."
    useradd -r -s /usr/sbin/nologin -d /nonexistent dhcpd
else
    echo "   ✅ Usuario dhcpd existe"
fi

# 2. Detener servicio
echo "2️⃣  Deteniendo servicio..."
systemctl stop isc-dhcp-server6 || true

# 3. Crear y configurar directorio PID
echo "3️⃣  Configurando directorio PID..."
mkdir -p /run/dhcp-server6
chown -v dhcpd:dhcpd /run/dhcp-server6 || {
    echo "   ⚠️  No se pudo cambiar owner del directorio"
    chmod 777 /run/dhcp-server6
}
chmod -v 0755 /run/dhcp-server6
ls -la /run/ | grep dhcp-server6
echo "   ✅ Directorio /run/dhcp-server6 creado"

# 4. Configurar permisos de leases
echo "4️⃣  Configurando archivo de leases..."
if [ ! -f /var/lib/dhcp/dhcpd6.leases ]; then
    touch /var/lib/dhcp/dhcpd6.leases
fi
chown -v dhcpd:dhcpd /var/lib/dhcp/dhcpd6.leases || {
    echo "   ⚠️  No se pudo cambiar owner, intentando con permisos alternativos..."
    chmod 666 /var/lib/dhcp/dhcpd6.leases
}
chmod -v 0644 /var/lib/dhcp/dhcpd6.leases
ls -la /var/lib/dhcp/dhcpd6.leases
echo "   ✅ Archivo de leases configurado"

# 5. Configurar AppArmor
echo "5️⃣  Configurando AppArmor..."
mkdir -p /etc/apparmor.d/local

cat > /etc/apparmor.d/local/usr.sbin.dhcpd << 'EOF'
# Permisos adicionales para DHCPv6
/run/dhcp-server6/ rw,
/run/dhcp-server6/** rw,
/run/dhcp-server6/dhcpd6.pid rw,
EOF

echo "   ✅ Configuración de AppArmor creada"

# 6. Recargar AppArmor
echo "6️⃣  Recargando AppArmor..."
if systemctl is-active --quiet apparmor; then
    apparmor_parser -r /etc/apparmor.d/usr.sbin.dhcpd
    echo "   ✅ AppArmor recargado"
else
    echo "   ⚠️  AppArmor no está activo"
fi

# 7. Configurar tmpfiles.d
echo "7️⃣  Configurando tmpfiles.d..."
cat > /etc/tmpfiles.d/dhcp-server6.conf << 'EOF'
d /run/dhcp-server6 0755 dhcpd dhcpd -
EOF
systemd-tmpfiles --create
echo "   ✅ tmpfiles.d configurado"

# 8. Configurar systemd override
echo "8️⃣  Configurando systemd override..."
mkdir -p /etc/systemd/system/isc-dhcp-server6.service.d

cat > /etc/systemd/system/isc-dhcp-server6.service.d/override.conf << 'EOF'
[Unit]
After=systemd-tmpfiles-setup.service
Requires=systemd-tmpfiles-setup.service

[Service]
RuntimeDirectory=dhcp-server6
RuntimeDirectoryMode=0755
EOF

systemctl daemon-reload
echo "   ✅ systemd configurado"

# 9. Iniciar servicio
echo "9️⃣  Iniciando servicio..."
systemctl enable isc-dhcp-server6
systemctl start isc-dhcp-server6

# 10. Verificar estado
echo "🔍 Verificando estado..."
sleep 2
systemctl status isc-dhcp-server6 --no-pager -l

echo ""
echo "✅ ¡Corrección completada!"
echo ""
echo "📋 Verificar logs:"
echo "   journalctl -u isc-dhcp-server6 -n 50 --no-pager"
echo ""
echo "📋 Verificar PID:"
echo "   ls -la /run/dhcp-server6/"
