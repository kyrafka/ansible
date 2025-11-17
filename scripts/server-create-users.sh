#!/bin/bash
# Script para configurar usuarios en el servidor Ubuntu Server
# - ubuntu (ya existe): Configurar permisos de admin
# - auditor (crear): Solo lectura de logs
# - dev (crear): Gestión de servicios

# Auto-permisos
[ ! -x "$0" ] && chmod +x "$0" 2>/dev/null

set -e

echo "════════════════════════════════════════════════════════"
echo "👥 Configurando usuarios en el servidor"
echo "════════════════════════════════════════════════════════"
echo ""

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script debe ejecutarse como root"
    echo "   Usa: sudo bash $0"
    exit 1
fi

echo "📋 Configuración de usuarios:"
echo ""
echo "  1. ubuntu     - Administrador (YA EXISTE - solo configurar)"
echo "  2. auditor    - Auditor (CREAR NUEVO - solo lectura)"
echo "  3. dev        - Desarrollador (CREAR NUEVO - gestión servicios)"
echo ""
echo "ℹ️  El usuario 'ubuntu' viene por defecto en Ubuntu Server"
echo "   Solo se crearán 2 usuarios nuevos: auditor y dev"
echo ""

read -p "¿Continuar? [S/n]: " CONFIRM
if [[ "$CONFIRM" =~ ^[nN]$ ]]; then
    echo "Operación cancelada"
    exit 0
fi

echo ""
echo "1️⃣  Creando grupo 'servicios'..."

if ! getent group servicios > /dev/null; then
    groupadd servicios
    echo "  ✓ Grupo 'servicios' creado"
else
    echo "  ✓ Grupo 'servicios' ya existe"
fi

echo ""
echo "2️⃣  Configurando usuario 'ubuntu' (administrador)..."

if id "ubuntu" &>/dev/null; then
    # Asegurar que ubuntu tiene todos los permisos
    usermod -aG sudo,adm ubuntu 2>/dev/null || true
    
    # Sudo sin contraseña
    echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ubuntu
    chmod 440 /etc/sudoers.d/ubuntu
    
    echo "  ✓ Usuario 'ubuntu' configurado"
    echo "    Contraseña: 123 (ya existente)"
    echo "    Grupos: sudo, adm"
    echo "    Sudo: SIN contraseña"
else
    echo "  ❌ Usuario 'ubuntu' no existe (esto no debería pasar)"
fi

echo ""
echo "3️⃣  Creando usuario 'auditor'..."

if ! id "auditor" &>/dev/null; then
    # Crear usuario auditor
    useradd -m -s /bin/bash -G adm auditor
    echo "auditor:123" | chpasswd
    
    echo "  ✓ Usuario 'auditor' creado"
    echo "    Contraseña: 123"
    echo "    Grupos: adm"
    echo "    Permisos: Solo lectura de logs"
else
    echo "  ✓ Usuario 'auditor' ya existe"
    # Actualizar contraseña si ya existe
    echo "auditor:123" | chpasswd
    echo "    Contraseña actualizada: 123"
fi

echo ""
echo "4️⃣  Creando usuario 'dev' (desarrollador)..."

if ! id "dev" &>/dev/null; then
    # Crear usuario dev
    useradd -m -s /bin/bash -G servicios dev
    echo "dev:123" | chpasswd
    
    # Sudo limitado (solo servicios y logs)
    cat > /etc/sudoers.d/dev << 'EOF'
# Dev puede gestionar servicios y ver logs
dev ALL=(ALL) NOPASSWD: /bin/systemctl start *
dev ALL=(ALL) NOPASSWD: /bin/systemctl stop *
dev ALL=(ALL) NOPASSWD: /bin/systemctl restart *
dev ALL=(ALL) NOPASSWD: /bin/systemctl status *
dev ALL=(ALL) NOPASSWD: /bin/journalctl *
dev ALL=(ALL) NOPASSWD: /usr/bin/tail *
dev ALL=(ALL) NOPASSWD: /usr/bin/cat /var/log/*
EOF
    chmod 440 /etc/sudoers.d/dev
    
    echo "  ✓ Usuario 'dev' creado"
    echo "    Contraseña: 123"
    echo "    Grupos: servicios"
    echo "    Sudo: Servicios y logs (systemctl, journalctl)"
else
    echo "  ✓ Usuario 'dev' ya existe"
    # Actualizar contraseña si ya existe
    echo "dev:123" | chpasswd
    echo "    Contraseña actualizada: 123"
fi

echo ""
echo "5️⃣  Creando directorios de trabajo..."

# Directorio para ubuntu (admin)
if [ ! -d "/srv/admin" ]; then
    mkdir -p /srv/admin
    chown ubuntu:ubuntu /srv/admin
    chmod 755 /srv/admin
    echo "  ✓ /srv/admin creado (ubuntu)"
fi

# Directorio para auditor
if [ ! -d "/srv/audits" ]; then
    mkdir -p /srv/audits
    chown auditor:auditor /srv/audits
    chmod 755 /srv/audits
    echo "  ✓ /srv/audits creado (auditor)"
fi

# Directorio para dev
if [ ! -d "/srv/dev" ]; then
    mkdir -p /srv/dev
    chown dev:servicios /srv/dev
    chmod 775 /srv/dev
    echo "  ✓ /srv/dev creado (dev)"
fi

echo ""
echo "6️⃣  Configurando acceso SSH..."

# Actualizar AllowUsers para incluir solo ubuntu
sed -i '/^AllowUsers/d' /etc/ssh/sshd_config
echo "" >> /etc/ssh/sshd_config
echo "# Usuarios autorizados para SSH" >> /etc/ssh/sshd_config
echo "AllowUsers ubuntu" >> /etc/ssh/sshd_config

systemctl restart sshd

echo "  ✓ SSH configurado"
echo "    Permitido: ubuntu"
echo "    Bloqueados: auditor, dev"

echo ""
echo "7️⃣  Creando archivo de bienvenida para cada usuario..."

# Ubuntu (admin)
cat > /home/ubuntu/README.txt << 'EOF'
════════════════════════════════════════════════════════════════
Bienvenido al servidor GameCenter
════════════════════════════════════════════════════════════════

Usuario: ubuntu
Rol: Administrador del servidor

PERMISOS:
✅ Sudo completo (sin contraseña)
✅ Acceso SSH
✅ Gestión de todos los servicios
✅ Acceso a todos los logs
✅ Configuración del sistema

COMANDOS ÚTILES:

Ver servicios:
  sudo systemctl status named              # DNS
  sudo systemctl status isc-dhcp-server6   # DHCP
  sudo systemctl status tayga              # NAT64
  sudo systemctl status squid              # Proxy

Ver logs:
  sudo journalctl -fu named
  sudo journalctl -fu isc-dhcp-server6

Gestionar red:
  ip -6 addr show
  ip -6 route
  sudo ip6tables -t nat -L -v -n

Tu directorio: /srv/admin
════════════════════════════════════════════════════════════════
EOF
chown ubuntu:ubuntu /home/ubuntu/README.txt

# Auditor
cat > /home/auditor/README.txt << 'EOF'
════════════════════════════════════════════════════════════════
Bienvenido al servidor GameCenter
════════════════════════════════════════════════════════════════

Usuario: auditor
Rol: Auditor del sistema

PERMISOS:
✅ Ver logs del sistema
✅ Ver estado de servicios
❌ NO puede modificar configuraciones
❌ NO tiene sudo
❌ NO puede SSH (solo acceso local)

COMANDOS ÚTILES:

Ver logs:
  journalctl -n 50                    # Últimos 50 logs
  journalctl -u named -n 20           # Logs de DNS
  journalctl -u isc-dhcp-server6      # Logs de DHCP
  journalctl --since "1 hour ago"     # Última hora

Ver estado:
  systemctl status named
  systemctl status isc-dhcp-server6

Tu directorio: /srv/audits
════════════════════════════════════════════════════════════════
EOF
chown auditor:auditor /home/auditor/README.txt

# Dev
cat > /home/dev/README.txt << 'EOF'
════════════════════════════════════════════════════════════════
Bienvenido al servidor GameCenter
════════════════════════════════════════════════════════════════

Usuario: dev
Rol: Desarrollador / Operador de servicios

PERMISOS:
✅ Iniciar/detener/reiniciar servicios
✅ Ver logs de servicios
✅ Ver estado del sistema
❌ NO puede modificar configuraciones
❌ NO puede SSH (solo acceso local)

COMANDOS ÚTILES:

Gestionar servicios:
  sudo systemctl restart named
  sudo systemctl restart isc-dhcp-server6
  sudo systemctl restart tayga
  sudo systemctl status named

Ver logs:
  sudo journalctl -fu named
  sudo journalctl -fu isc-dhcp-server6

Tu directorio: /srv/dev
════════════════════════════════════════════════════════════════
EOF
chown dev:dev /home/dev/README.txt

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ Usuarios configurados exitosamente"
echo "════════════════════════════════════════════════════════"
echo ""
echo "📋 Resumen:"
echo ""
echo "┌────────────┬──────────────┬──────┬─────────┬──────────────────┬──────────┐"
echo "│ Usuario    │ Contraseña   │ Sudo │ SSH     │ Función          │ Estado   │"
echo "├────────────┼──────────────┼──────┼─────────┼──────────────────┼──────────┤"
echo "│ ubuntu     │ 123          │  ✅  │   ✅    │ Administrador    │ Configurado│"
echo "│ auditor    │ 123          │  ❌  │   ❌    │ Auditoría        │ Creado   │"
echo "│ dev        │ 123          │  ⚡  │   ❌    │ Desarrollador    │ Creado   │"
echo "└────────────┴──────────────┴──────┴─────────┴──────────────────┴──────────┘"
echo ""
echo "⚡ = Sudo limitado (solo servicios y logs)"
echo ""
echo "📁 Directorios:"
echo "  /srv/admin   → ubuntu"
echo "  /srv/audits  → auditor"
echo "  /srv/dev     → dev"
echo ""
echo "📝 Cada usuario tiene un README.txt en su home"
echo ""
echo "ℹ️  Usuarios creados: 2 (auditor, dev)"
echo "   Usuario configurado: 1 (ubuntu - ya existía)"
echo ""
echo "🔐 Cambiar contraseñas:"
echo "  sudo passwd ubuntu"
echo "  sudo passwd auditor"
echo "  sudo passwd dev"
echo ""
echo "════════════════════════════════════════════════════════"
