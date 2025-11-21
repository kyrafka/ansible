#!/bin/bash

echo "════════════════════════════════════════════════════════════════"
echo "🔧 CONFIGURAR SAMBA PARA IPv6 EN WINDOWS"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script debe ejecutarse como root"
    echo "   Usa: sudo bash $0"
    exit 1
fi

echo "Paso 1: Corrigiendo configuración de Samba para IPv6"
echo "────────────────────────────────────────────────────────"

# Crear configuración optimizada para IPv6
cat > /etc/samba/smb.conf << 'EOF'
[global]
   workgroup = WORKGROUP
   server string = Servidor GameCenter
   netbios name = servidor
   security = user
   map to guest = bad user
   
   # IPv6 ONLY
   bind interfaces only = no
   
   # Logging
   log file = /var/log/samba/log.%m
   max log size = 50
   
   # Performance
   socket options = TCP_NODELAY SO_RCVBUF=131072 SO_SNDBUF=131072
   
   # SMB2/SMB3 (mejor para IPv6)
   server min protocol = SMB2
   client min protocol = SMB2

# Carpeta pública (sin contraseña)
[Publico]
   path = /srv/publico
   browseable = yes
   writable = yes
   guest ok = yes
   read only = no
   create mask = 0777
   directory mask = 0777
   force user = nobody
   
[Juegos]
   path = /srv/juegos
   browseable = yes
   writable = yes
   valid users = @pcgamers
   create mask = 0775
   directory mask = 0775
   force group = pcgamers

[Compartido]
   path = /srv/compartido
   browseable = yes
   writable = no
   guest ok = yes
   read only = yes
EOF

echo "✓ Configuración de Samba actualizada"

# Reiniciar solo smbd (sin nmbd que no soporta IPv6)
systemctl stop nmbd
systemctl disable nmbd
systemctl restart smbd
systemctl enable smbd

echo "✓ Samba reiniciado (solo smbd, sin nmbd)"

echo ""
echo "Paso 2: Verificando que Samba escucha en IPv6"
echo "────────────────────────────────────────────────────────"

netstat -tlnp | grep smbd | grep ":::"

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✅ SAMBA CONFIGURADO PARA IPv6"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "🪟 CONECTAR DESDE WINDOWS 11:"
echo ""
echo "  Método 1 - PowerShell (RECOMENDADO):"
echo "    net use Z: \\\\2025-db8-10--1.ipv6-literal.net\\Publico"
echo ""
echo "  Método 2 - Mapear unidad con cmdkey:"
echo "    cmdkey /add:2025-db8-10--1.ipv6-literal.net /user:guest /pass:"
echo "    net use Z: \\\\2025-db8-10--1.ipv6-literal.net\\Publico"
echo ""
echo "  Método 3 - Explorador (formato especial):"
echo "    \\\\2025-db8-10--1.ipv6-literal.net\\Publico"
echo ""
echo "  Nota: Windows convierte IPv6 a formato DNS:"
echo "    2025:db8:10::1 → 2025-db8-10--1.ipv6-literal.net"
echo ""
echo "🐧 CONECTAR DESDE UBUNTU:"
echo ""
echo "  Nautilus (Archivos):"
echo "    smb://2025:db8:10::1"
echo ""
echo "  Montar manualmente:"
echo "    sudo mount -t cifs //2025:db8:10::1/Publico /mnt/publico -o guest,vers=3.0"
echo ""
echo "════════════════════════════════════════════════════════════════"
