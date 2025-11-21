#!/bin/bash

echo "════════════════════════════════════════════════════════════════"
echo "📁 CONFIGURAR SAMBA Y FTP PARA COMPARTIR ARCHIVOS"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script debe ejecutarse como root"
    echo "   Usa: sudo bash $0"
    exit 1
fi

echo "Paso 1: Instalando Samba y FTP"
echo "────────────────────────────────────────────────────────"

apt update &>/dev/null
apt install -y samba vsftpd &>/dev/null

echo "✓ Samba y vsftpd instalados"

echo ""
echo "Paso 2: Creando carpetas compartidas"
echo "────────────────────────────────────────────────────────"

# Crear carpetas
mkdir -p /srv/compartido
mkdir -p /srv/juegos
mkdir -p /srv/publico

# Permisos
chown -R nobody:nogroup /srv/publico
chmod 777 /srv/publico

chown -R root:pcgamers /srv/juegos
chmod 2775 /srv/juegos

chown -R root:root /srv/compartido
chmod 755 /srv/compartido

echo "✓ Carpetas creadas:"
echo "  - /srv/compartido (solo lectura para todos)"
echo "  - /srv/juegos (lectura/escritura para pcgamers)"
echo "  - /srv/publico (lectura/escritura para todos)"

echo ""
echo "Paso 3: Configurando Samba"
echo "────────────────────────────────────────────────────────"

# Backup de configuración original
cp /etc/samba/smb.conf /etc/samba/smb.conf.backup

# Crear configuración de Samba
cat > /etc/samba/smb.conf << 'EOF'
[global]
   workgroup = GAMECENTER
   server string = Servidor GameCenter
   netbios name = SERVIDOR
   security = user
   map to guest = bad user
   dns proxy = no
   
   # Soporte IPv6
   bind interfaces only = yes
   interfaces = lo ens34
   
   # Logging
   log file = /var/log/samba/log.%m
   max log size = 1000
   
   # Performance
   socket options = TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=131072 SO_SNDBUF=131072
   read raw = yes
   write raw = yes
   max xmit = 65535
   dead time = 15
   getwd cache = yes

# Carpeta pública (sin contraseña)
[Publico]
   comment = Carpeta Publica
   path = /srv/publico
   browseable = yes
   writable = yes
   guest ok = yes
   read only = no
   create mask = 0777
   directory mask = 0777
   force user = nobody

# Carpeta de juegos (solo grupo pcgamers)
[Juegos]
   comment = Juegos Compartidos
   path = /srv/juegos
   browseable = yes
   writable = yes
   valid users = @pcgamers
   create mask = 0775
   directory mask = 0775
   force group = pcgamers

# Carpeta compartida (solo lectura)
[Compartido]
   comment = Archivos Compartidos
   path = /srv/compartido
   browseable = yes
   writable = no
   guest ok = yes
   read only = yes
EOF

echo "✓ Configuración de Samba creada"

# Reiniciar Samba
systemctl restart smbd nmbd
systemctl enable smbd nmbd

echo "✓ Samba reiniciado y habilitado"

echo ""
echo "Paso 4: Configurando FTP (vsftpd)"
echo "────────────────────────────────────────────────────────"

# Backup de configuración original
cp /etc/vsftpd.conf /etc/vsftpd.conf.backup

# Crear configuración de vsftpd
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

# Anónimo
anon_root=/srv/publico
no_anon_password=YES
anon_upload_enable=YES
anon_mkdir_write_enable=YES
anon_other_write_enable=YES

# Performance
xferlog_std_format=YES
idle_session_timeout=600
data_connection_timeout=120

# Banner
ftpd_banner=Bienvenido al servidor FTP de GameCenter
EOF

echo "✓ Configuración de vsftpd creada"

# Reiniciar vsftpd
systemctl restart vsftpd
systemctl enable vsftpd

echo "✓ vsftpd reiniciado y habilitado"

echo ""
echo "Paso 5: Configurando firewall"
echo "────────────────────────────────────────────────────────"

# Samba
ufw allow 139/tcp
ufw allow 445/tcp
ufw allow 137/udp
ufw allow 138/udp

# FTP
ufw allow 20/tcp
ufw allow 21/tcp
ufw allow 40000:40100/tcp

echo "✓ Puertos abiertos en firewall"

echo ""
echo "Paso 6: Creando usuarios de prueba"
echo "────────────────────────────────────────────────────────"

# Crear usuario gamer01 si no existe
if ! id gamer01 &>/dev/null; then
    useradd -m -s /bin/bash -G pcgamers gamer01
    echo "gamer01:Game123!" | chpasswd
    echo "✓ Usuario gamer01 creado"
else
    echo "✓ Usuario gamer01 ya existe"
fi

# Agregar a Samba
(echo "Game123!"; echo "Game123!") | smbpasswd -a gamer01 &>/dev/null
smbpasswd -e gamer01 &>/dev/null

echo "✓ Usuario gamer01 agregado a Samba"

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✅ SAMBA Y FTP CONFIGURADOS"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "📁 CARPETAS COMPARTIDAS:"
echo ""
echo "  1. Público (sin contraseña):"
echo "     Samba: \\\\2025:db8:10::1\\Publico"
echo "     FTP:   ftp://2025:db8:10::1"
echo "     Permisos: Lectura/Escritura para todos"
echo ""
echo "  2. Juegos (requiere usuario):"
echo "     Samba: \\\\2025:db8:10::1\\Juegos"
echo "     Usuario: gamer01"
echo "     Contraseña: Game123!"
echo "     Permisos: Lectura/Escritura para grupo pcgamers"
echo ""
echo "  3. Compartido (solo lectura):"
echo "     Samba: \\\\2025:db8:10::1\\Compartido"
echo "     Permisos: Solo lectura para todos"
echo ""
echo "🪟 CONECTAR DESDE WINDOWS:"
echo ""
echo "  Samba:"
echo "    1. Explorador de archivos"
echo "    2. Barra de dirección: \\\\2025:db8:10::1"
echo "    3. Enter"
echo ""
echo "  FTP:"
echo "    1. Explorador de archivos"
echo "    2. Barra de dirección: ftp://2025:db8:10::1"
echo "    3. Enter"
echo ""
echo "🐧 CONECTAR DESDE UBUNTU:"
echo ""
echo "  Samba:"
echo "    1. Nautilus (Archivos)"
echo "    2. Ctrl+L"
echo "    3. smb://2025:db8:10::1"
echo ""
echo "  FTP:"
echo "    1. Nautilus (Archivos)"
echo "    2. Ctrl+L"
echo "    3. ftp://2025:db8:10::1"
echo ""
echo "🎮 JUEGO LAN RECOMENDADO (ligero):"
echo ""
echo "  OpenArena (Quake 3 open source)"
echo "    sudo apt install openarena"
echo "    Servidor: openarena +set dedicated 1 +set net_port 27960"
echo "    Cliente: openarena +connect 2025:db8:10::1"
echo ""
echo "  Xonotic (FPS ligero)"
echo "    sudo apt install xonotic"
echo "    Muy ligero, gráficos buenos, multijugador LAN"
echo ""
echo "  Teeworlds (2D multiplayer)"
echo "    sudo apt install teeworlds"
echo "    Súper ligero, divertido, fácil de jugar"
echo ""
echo "════════════════════════════════════════════════════════════════"
