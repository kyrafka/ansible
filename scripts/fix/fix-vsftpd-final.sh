#!/bin/bash

echo "════════════════════════════════════════════════════════════════"
echo "🔧 CORREGIR VSFTPD PARA IPv6"
echo "════════════════════════════════════════════════════════════════"
echo ""

if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script debe ejecutarse como root"
    exit 1
fi

echo "Paso 1: Creando estructura correcta de directorios"
echo "────────────────────────────────────────────────────────"

# Crear directorio raíz FTP (no escribible)
mkdir -p /srv/ftp
chmod 755 /srv/ftp
chown root:root /srv/ftp

# Crear subdirectorio público (escribible)
mkdir -p /srv/ftp/publico
chmod 777 /srv/ftp/publico
chown nobody:nogroup /srv/ftp/publico

echo "✓ Directorios creados"

echo ""
echo "Paso 2: Configurando vsftpd"
echo "────────────────────────────────────────────────────────"

cat > /etc/vsftpd.conf << 'EOF'
# Configuración básica
listen=NO
listen_ipv6=YES
anonymous_enable=YES
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES

# Seguridad
chroot_local_user=YES
allow_writeable_chroot=YES
secure_chroot_dir=/var/run/vsftpd/empty
pam_service_name=vsftpd

# FTP pasivo
pasv_enable=YES
pasv_min_port=40000
pasv_max_port=40100

# Anónimo - DIRECTORIO CORRECTO
anon_root=/srv/ftp
no_anon_password=YES
anon_upload_enable=YES
anon_mkdir_write_enable=YES
anon_other_write_enable=YES

# Performance
xferlog_std_format=YES
idle_session_timeout=600
data_connection_timeout=120

# Banner
ftpd_banner=Bienvenido al servidor FTP de GameCenter (IPv6)
EOF

echo "✓ Configuración creada"

echo ""
echo "Paso 3: Reiniciando vsftpd"
echo "────────────────────────────────────────────────────────"

systemctl restart vsftpd
systemctl status vsftpd --no-pager | head -10

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✅ VSFTPD CONFIGURADO PARA IPv6"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "📁 ESTRUCTURA DE DIRECTORIOS:"
echo "  /srv/ftp (755, root:root) - Directorio raíz"
echo "  /srv/ftp/publico (777, nobody:nogroup) - Carpeta pública"
echo ""
echo "🔗 CONECTAR POR IPv6:"
echo ""
echo "  Ubuntu Desktop:"
echo "    ftp 2025:db8:10::2"
echo "    Usuario: anonymous"
echo "    Contraseña: (vacía)"
echo ""
echo "  FileZilla:"
echo "    Servidor: 2025:db8:10::2"
echo "    Puerto: 21"
echo "    Usuario: anonymous"
echo ""
echo "  Nautilus:"
echo "    ftp://[2025:db8:10::2]"
echo ""
echo "  Windows:"
echo "    ftp://[2025:db8:10::2]"
echo ""
echo "════════════════════════════════════════════════════════════════"
