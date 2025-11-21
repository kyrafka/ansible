#!/bin/bash

echo "════════════════════════════════════════════════════════════════"
echo "🔍 DIAGNÓSTICO Y CORRECCIÓN EXHAUSTIVA DE SAMBA"
echo "════════════════════════════════════════════════════════════════"
echo ""

if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script debe ejecutarse como root"
    exit 1
fi

echo "Paso 1: Deteniendo servicios conflictivos"
echo "────────────────────────────────────────────────────────"

systemctl stop smbd nmbd avahi-daemon
killall -9 smbd nmbd 2>/dev/null

echo "✓ Servicios detenidos"

echo ""
echo "Paso 2: Limpiando configuraciones antiguas"
echo "────────────────────────────────────────────────────────"

rm -f /var/cache/samba/*.tdb
rm -f /var/lib/samba/*.tdb
rm -f /run/samba/*.pid

echo "✓ Caché limpiado"

echo ""
echo "Paso 3: Configurando Samba SOLO para IPv6"
echo "────────────────────────────────────────────────────────"

cat > /etc/samba/smb.conf << 'EOF'
[global]
# Identificación
workgroup = WORKGROUP
netbios name = GAMESERVER
server string = Servidor GameCenter

# Seguridad
security = user
map to guest = Bad User
guest account = nobody

# Protocolo
server min protocol = SMB2
client min protocol = SMB2
server max protocol = SMB3

# Autenticación
ntlm auth = yes
lanman auth = no

# RED - CRÍTICO PARA IPv6
# NO usar bind interfaces only con IPv6
bind interfaces only = no
# Dejar que Samba detecte automáticamente
# interfaces = 

# Desactivar NetBIOS (no funciona con IPv6)
disable netbios = yes
smb ports = 445

# Logs detallados
log level = 3
log file = /var/log/samba/log.%m
max log size = 1000

# Performance
socket options = TCP_NODELAY IPTOS_LOWDELAY
read raw = yes
write raw = yes

# Resolución de nombres
dns proxy = no
wins support = no

[Publico]
path = /srv/publico
comment = Carpeta Publica
browseable = yes
writable = yes
guest ok = yes
read only = no
create mask = 0777
directory mask = 0777
force user = nobody
force group = nogroup

[Juegos]
path = /srv/juegos
comment = Juegos Compartidos
browseable = yes
writable = yes
valid users = jose, administrador, @pcgamers
force group = pcgamers
create mask = 0775
directory mask = 0775

[Compartido]
path = /srv/compartido
comment = Archivos Compartidos
browseable = yes
guest ok = yes
read only = yes
EOF

echo "✓ Configuración creada (NetBIOS desactivado, solo SMB directo)"

echo ""
echo "Paso 4: Verificando sintaxis de configuración"
echo "────────────────────────────────────────────────────────"

testparm -s 2>&1 | head -20

echo ""
echo "Paso 5: Configurando permisos de carpetas"
echo "────────────────────────────────────────────────────────"

chmod 777 /srv/publico
chown nobody:nogroup /srv/publico

chmod 2775 /srv/juegos
chown root:pcgamers /srv/juegos

chmod 755 /srv/compartido
chown root:root /srv/compartido

echo "✓ Permisos configurados"

echo ""
echo "Paso 6: Iniciando SOLO smbd (sin nmbd)"
echo "────────────────────────────────────────────────────────"

# Desactivar nmbd permanentemente (no soporta IPv6)
systemctl disable nmbd
systemctl mask nmbd

# Iniciar solo smbd
systemctl enable smbd
systemctl start smbd

sleep 3

echo ""
echo "Paso 7: Verificando que smbd escucha en IPv6"
echo "────────────────────────────────────────────────────────"

echo "Puertos escuchando:"
ss -tlnp | grep smbd

echo ""
echo "Verificando puerto 445 en IPv6:"
ss -tlnp | grep ":445"

echo ""
echo "Paso 8: Verificando firewall"
echo "────────────────────────────────────────────────────────"

ufw allow 445/tcp comment "SMB Direct"
ufw status | grep 445

echo ""
echo "Paso 9: Probando conexión local"
echo "────────────────────────────────────────────────────────"

echo "Listando recursos compartidos:"
smbclient -L localhost -N 2>&1 | grep -E "Sharename|Publico|Juegos|Compartido"

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✅ CONFIGURACIÓN EXHAUSTIVA COMPLETADA"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "🔍 CAMBIOS REALIZADOS:"
echo ""
echo "  ✓ NetBIOS DESACTIVADO (no funciona con IPv6)"
echo "  ✓ Solo SMB directo en puerto 445"
echo "  ✓ nmbd DESACTIVADO permanentemente"
echo "  ✓ Solo smbd activo"
echo "  ✓ Configuración optimizada para IPv6"
echo ""
echo "🪟 CONECTAR DESDE WINDOWS:"
echo ""
echo "  PowerShell como Administrador:"
echo "    net use Z: \\\\[2025:db8:10::1]\\Publico /user:jose 123"
echo ""
echo "  O en Explorador (puede no funcionar):"
echo "    \\\\2025:db8:10::1"
echo ""
echo "🐧 CONECTAR DESDE UBUNTU:"
echo ""
echo "  Nautilus:"
echo "    smb://2025:db8:10::1"
echo "    Usuario: administrador"
echo "    Contraseña: 123"
echo ""
echo "  Terminal:"
echo "    smbclient //2025:db8:10::1/Publico -U administrador"
echo ""
echo "📋 VERIFICAR LOGS:"
echo "    sudo tail -f /var/log/samba/log.smbd"
echo ""
echo "════════════════════════════════════════════════════════════════"
