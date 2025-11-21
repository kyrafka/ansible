#!/bin/bash

echo "════════════════════════════════════════════════════════════════"
echo "🔧 CONFIGURACIÓN FINAL DE SAMBA PARA WINDOWS + UBUNTU"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script debe ejecutarse como root"
    echo "   Usa: sudo bash $0"
    exit 1
fi

echo "Paso 1: Creando carpetas compartidas"
echo "────────────────────────────────────────────────────────"

mkdir -p /srv/publico
mkdir -p /srv/juegos
mkdir -p /srv/compartido

chmod -R 777 /srv/publico
chown -R nobody:nogroup /srv/publico

chmod -R 2775 /srv/juegos
chown -R root:pcgamers /srv/juegos

chmod -R 755 /srv/compartido
chown -R root:root /srv/compartido

echo "✓ Carpetas creadas y permisos configurados"

echo ""
echo "Paso 2: Configurando Samba con compatibilidad Windows"
echo "────────────────────────────────────────────────────────"

# Backup
cp /etc/samba/smb.conf /etc/samba/smb.conf.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null

# Crear configuración optimizada
cat > /etc/samba/smb.conf << 'EOF'
[global]
workgroup = WORKGROUP
server string = Servidor GameCenter
netbios name = servidor
security = user
map to guest = Bad User

# Permitir descubrimiento de Windows
server min protocol = SMB2
client min protocol = SMB2

# Para compatibilidad con Windows 10/11
ntlm auth = yes
lanman auth = no

# Importante: permitir IPv4 + IPv6
interfaces = lo ens33 ens34
bind interfaces only = no

# Logs
log file = /var/log/samba/log.%m
max log size = 50

# Performance
socket options = TCP_NODELAY SO_RCVBUF=131072 SO_SNDBUF=131072

# Carpeta pública (sin contraseña)
[Publico]
path = /srv/publico
browseable = yes
writable = yes
guest ok = yes
read only = no
create mask = 0777
directory mask = 0777

# Carpeta privada (con usuarios)
[Juegos]
path = /srv/juegos
browseable = yes
writable = yes
valid users = @pcgamers
force group = pcgamers
create mask = 0775
directory mask = 0775

# Carpeta solo lectura para invitados
[Compartido]
path = /srv/compartido
browseable = yes
guest ok = yes
read only = yes
EOF

echo "✓ Configuración de Samba creada"

echo ""
echo "Paso 3: Configurando firewall"
echo "────────────────────────────────────────────────────────"

# Samba
ufw allow 139/tcp comment "Samba NetBIOS"
ufw allow 445/tcp comment "Samba SMB"
ufw allow 137/udp comment "Samba NetBIOS Name"
ufw allow 138/udp comment "Samba NetBIOS Datagram"

# FTP
ufw allow 20/tcp comment "FTP Data"
ufw allow 21/tcp comment "FTP Control"
ufw allow 40000:40100/tcp comment "FTP Passive"

echo "✓ Reglas de firewall agregadas"

echo ""
echo "Paso 4: Reiniciando servicios"
echo "────────────────────────────────────────────────────────"

# Reiniciar Samba
systemctl restart smbd nmbd
systemctl enable smbd nmbd

# Reiniciar FTP
systemctl restart vsftpd
systemctl enable vsftpd

echo "✓ Servicios reiniciados"

sleep 2

echo ""
echo "Paso 5: Verificando servicios"
echo "────────────────────────────────────────────────────────"

echo "Estado de smbd:"
systemctl is-active smbd && echo "  ✓ smbd activo" || echo "  ❌ smbd inactivo"

echo "Estado de nmbd:"
systemctl is-active nmbd && echo "  ✓ nmbd activo" || echo "  ❌ nmbd inactivo"

echo "Estado de vsftpd:"
systemctl is-active vsftpd && echo "  ✓ vsftpd activo" || echo "  ❌ vsftpd inactivo"

echo ""
echo "Puertos escuchando:"
netstat -tlnp | grep -E "smbd|nmbd|vsftpd" | head -15

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✅ SAMBA Y FTP CONFIGURADOS"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "📁 CARPETAS COMPARTIDAS:"
echo "  /srv/publico  → Lectura/Escritura para todos"
echo "  /srv/juegos   → Lectura/Escritura para grupo pcgamers"
echo "  /srv/compartido → Solo lectura para todos"
echo ""
echo "🪟 CONECTAR DESDE WINDOWS:"
echo ""
echo "  Opción 1 - Samba por IPv6:"
echo "    \\\\2025:db8:10::1"
echo "    (En Explorador de archivos)"
echo ""
echo "  Opción 2 - FTP por IPv6:"
echo "    ftp://2025:db8:10::1"
echo "    (En Explorador de archivos)"
echo ""
echo "  Opción 3 - FileZilla:"
echo "    Host: 2025:db8:10::1"
echo "    Puerto: 21"
echo "    Usuario: anonymous"
echo ""
echo "🐧 CONECTAR DESDE UBUNTU:"
echo ""
echo "  Samba:"
echo "    smb://2025:db8:10::1"
echo "    (En Nautilus, presiona Ctrl+L)"
echo ""
echo "  FTP:"
echo "    ftp://2025:db8:10::1"
echo "    (En Nautilus, presiona Ctrl+L)"
echo ""
echo "🧪 PROBAR CONEXIÓN:"
echo ""
echo "  Desde Ubuntu:"
echo "    smbclient -L 2025:db8:10::1 -N"
echo ""
echo "  Desde Windows PowerShell:"
echo "    Test-NetConnection -ComputerName 2025:db8:10::1 -Port 445"
echo ""
echo "════════════════════════════════════════════════════════════════"
