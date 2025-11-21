#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Script de Diagnóstico - UBUNTU DESKTOP
# ═══════════════════════════════════════════════════════════════

echo "════════════════════════════════════════════════════════════"
echo "  DIAGNÓSTICO UBUNTU DESKTOP - $(date)"
echo "════════════════════════════════════════════════════════════"
echo ""

# ═══════════════════════════════════════════════════════════════
# 1. INFORMACIÓN DEL SISTEMA
# ═══════════════════════════════════════════════════════════════
echo "━━━ 1. INFORMACIÓN DEL SISTEMA ━━━"
echo "Hostname: $(hostname)"
echo "Sistema Operativo: $(lsb_release -d | cut -f2)"
echo "Kernel: $(uname -r)"
echo "Uptime: $(uptime -p)"
echo "Usuario actual: $(whoami)"
echo ""
sleep 5

# ═══════════════════════════════════════════════════════════════
# 2. CONFIGURACIÓN DE RED
# ═══════════════════════════════════════════════════════════════
echo "━━━ 2. CONFIGURACIÓN DE RED ━━━"
echo ""
echo "--- Interfaces de red ---"
ip -6 addr show | grep -E "inet6|^[0-9]"
echo ""

echo "--- Mi dirección IPv6 ---"
MY_IPV6=$(ip -6 addr show | grep "inet6 2025" | awk '{print $2}' | head -1)
echo "IPv6: $MY_IPV6"
echo ""

echo "--- Gateway predeterminado ---"
ip -6 route show default
echo ""

echo "--- Servidores DNS ---"
if command -v resolvectl &> /dev/null; then
    resolvectl status | grep "DNS Servers" | head -3
else
    cat /etc/resolv.conf | grep nameserver
fi
echo ""
sleep 5

# ═══════════════════════════════════════════════════════════════
# 3. CONECTIVIDAD - PING AL SERVIDOR
# ═══════════════════════════════════════════════════════════════
echo "━━━ 3. CONECTIVIDAD CON EL SERVIDOR ━━━"
echo ""

SERVER_IP="2025:db8:10::2"
echo "--- Ping al servidor ($SERVER_IP) ---"
if ping6 -c 4 $SERVER_IP > /dev/null 2>&1; then
    echo "✓ Servidor: ACCESIBLE"
    ping6 -c 4 $SERVER_IP | tail -2
else
    echo "✗ Servidor: NO ACCESIBLE"
fi
echo ""
sleep 5

# ═══════════════════════════════════════════════════════════════
# 4. CONECTIVIDAD - PING A WINDOWS
# ═══════════════════════════════════════════════════════════════
echo "━━━ 4. CONECTIVIDAD CON WINDOWS ━━━"
echo ""


# Windows 11-Gaming
WIN_GAMING_IP="2025:db8:10::13f"
echo "--- Ping a Windows 11-Gaming ($WIN_GAMING_IP) ---"
if ping6 -c 3 $WIN_GAMING_IP > /dev/null 2>&1; then
    echo "✓ Windows 11-Gaming: ACCESIBLE"
    ping6 -c 3 $WIN_GAMING_IP | tail -2
else
    echo "✗ Windows 11-Gaming: NO ACCESIBLE"
fi
echo ""


# ═══════════════════════════════════════════════════════════════
# 5. CONECTIVIDAD EXTERNA
# ═══════════════════════════════════════════════════════════════
echo "━━━ 5. CONECTIVIDAD EXTERNA ━━━"
echo ""
echo "--- Ping a Google DNS IPv6 ---"
if ping6 -c 3 2001:4860:4860::8888 > /dev/null 2>&1; then
    echo "✓ Internet IPv6: ACCESIBLE"
    ping6 -c 3 2001:4860:4860::8888 | tail -2
else
    echo "✗ Internet IPv6: NO ACCESIBLE"
fi
echo ""
sleep 5

# ═══════════════════════════════════════════════════════════════
# 6. DNS
# ═══════════════════════════════════════════════════════════════
echo "━━━ 6. PRUEBAS DNS ━━━"
echo ""
echo "--- Resolución del servidor ---"
nslookup servidor.gamecenter.lan
echo ""

echo "--- Resolución externa ---"
nslookup google.com
echo ""
sleep 5

# ═══════════════════════════════════════════════════════════════
# 7. MONTAJES NFS
# ═══════════════════════════════════════════════════════════════
echo "━━━ 7. MONTAJES NFS ━━━"
echo ""
if mount | grep -q nfs; then
    echo "Montajes NFS activos:"
    mount | grep nfs
else
    echo "No hay montajes NFS activos"
fi
echo ""
sleep 5

# ═══════════════════════════════════════════════════════════════
# 8. SERVICIOS SSH
# ═══════════════════════════════════════════════════════════════
echo "━━━ 8. SERVICIO SSH ━━━"
if systemctl is-active --quiet ssh; then
    echo "✓ SSH: ACTIVO"
    echo "Puerto SSH:"
    sudo ss -tulpn | grep ssh | awk '{print $5}'
else
    echo "✗ SSH: INACTIVO"
fi
echo ""
sleep 5

# ═══════════════════════════════════════════════════════════════
# 9. RECURSOS DEL SISTEMA
# ═══════════════════════════════════════════════════════════════
echo "━━━ 9. RECURSOS DEL SISTEMA ━━━"
echo ""
echo "--- Uso de CPU ---"
top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print "CPU en uso: " 100 - $1"%"}'
echo ""

echo "--- Uso de Memoria ---"
free -h | grep -E "Mem|Swap"
echo ""
sleep 3

echo "--- Uso de Disco ---"
df -h | grep -E "Filesystem|/dev/"
echo ""
sleep 5

# ═══════════════════════════════════════════════════════════════
# 10. USUARIOS Y ROLES DEL SISTEMA
# ═══════════════════════════════════════════════════════════════
echo "━━━ 10. USUARIOS Y ROLES DEL SISTEMA ━━━"
echo ""

echo "--- Usuarios del sistema ---"
echo "Usuario actual: $(whoami)"
echo ""

echo "Todos los usuarios con shell de login:"
echo "Usuario          UID    GID    Shell                Home"
echo "────────────────────────────────────────────────────────────"
grep -E "/bin/bash|/bin/sh" /etc/passwd | while IFS=: read -r user pass uid gid gecos home shell; do
    printf "%-15s  %-5s  %-5s  %-20s %s\n" "$user" "$uid" "$gid" "$shell" "$home"
done
echo ""

echo "--- Roles y privilegios ---"
echo ""

# Verificar usuarios con sudo
echo "Usuarios con privilegios SUDO:"
if [ -f /etc/sudoers.d/ansible-users ] || grep -q "^%sudo" /etc/sudoers 2>/dev/null; then
    getent group sudo | cut -d: -f4 | tr ',' '\n' | while read user; do
        [ -n "$user" ] && echo "  ✓ $user (grupo sudo)"
    done
    getent group admin 2>/dev/null | cut -d: -f4 | tr ',' '\n' | while read user; do
        [ -n "$user" ] && echo "  ✓ $user (grupo admin)"
    done
else
    echo "  No hay usuarios en grupo sudo"
fi
echo ""

# Grupos importantes
echo "--- Grupos importantes del proyecto ---"
for grupo in pcgamers servicios administrador auditor; do
    if getent group "$grupo" >/dev/null 2>&1; then
        echo "Grupo: $grupo (GID: $(getent group "$grupo" | cut -d: -f3))"
        miembros=$(getent group "$grupo" | cut -d: -f4)
        if [ -n "$miembros" ]; then
            echo "  Miembros: $miembros"
        else
            echo "  Miembros: (ninguno)"
        fi
    fi
done
echo ""

echo "--- Todos los grupos del usuario actual ---"
groups
echo ""
sleep 5

# ═══════════════════════════════════════════════════════════════
# 11. ENTORNO DE ESCRITORIO
# ═══════════════════════════════════════════════════════════════
echo "━━━ 11. ENTORNO DE ESCRITORIO ━━━"
echo ""

# Detectar entorno de escritorio
if [ -n "$XDG_CURRENT_DESKTOP" ]; then
    echo "Entorno de escritorio: $XDG_CURRENT_DESKTOP"
elif [ -n "$DESKTOP_SESSION" ]; then
    echo "Sesión de escritorio: $DESKTOP_SESSION"
else
    echo "Entorno de escritorio: No detectado (posible servidor sin GUI)"
fi
echo ""

# Detectar gestor de ventanas
if [ -n "$XDG_SESSION_TYPE" ]; then
    echo "Tipo de sesión: $XDG_SESSION_TYPE"
fi
echo ""

# Tema GTK
if command -v gsettings &> /dev/null && [ -n "$DISPLAY" ]; then
    echo "--- Temas y apariencia ---"
    echo "Tema GTK: $(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || echo 'No disponible')"
    echo "Tema de iconos: $(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null || echo 'No disponible')"
    echo "Tema de cursor: $(gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null || echo 'No disponible')"
    echo ""
fi

# Resolución de pantalla
if command -v xrandr &> /dev/null && [ -n "$DISPLAY" ]; then
    echo "--- Resolución de pantalla ---"
    xrandr 2>/dev/null | grep -E "connected|Screen" | head -5
    echo ""
fi
sleep 5

# ═══════════════════════════════════════════════════════════════
# 12. SOFTWARE INSTALADO
# ═══════════════════════════════════════════════════════════════
echo "━━━ 12. SOFTWARE INSTALADO ━━━"
echo ""

echo "--- Aplicaciones principales ---"
apps=("firefox" "chromium-browser" "google-chrome" "steam" "discord" "code" "vlc" "gimp" "libreoffice")
for app in "${apps[@]}"; do
    if command -v "$app" &> /dev/null; then
        version=$(dpkg -l | grep "^ii.*$app" | awk '{print $3}' | head -1)
        echo "  ✓ $app ${version:+(versión: $version)}"
    fi
done
echo ""

echo "--- Herramientas de desarrollo ---"
dev_tools=("git" "python3" "node" "npm" "docker" "ansible")
for tool in "${dev_tools[@]}"; do
    if command -v "$tool" &> /dev/null; then
        version=$($tool --version 2>/dev/null | head -1)
        echo "  ✓ $tool: $version"
    fi
done
echo ""
sleep 5

# ═══════════════════════════════════════════════════════════════
# 13. PERMISOS Y ACCESOS
# ═══════════════════════════════════════════════════════════════
echo "━━━ 13. PERMISOS Y ACCESOS ━━━"
echo ""

echo "--- Permisos del usuario actual ---"
echo "Usuario: $(whoami)"
echo "UID: $(id -u)"
echo "GID: $(id -g)"
echo "Grupos: $(id -Gn)"
echo ""

echo "--- Capacidades especiales ---"
# Verificar si puede usar sudo
if sudo -n true 2>/dev/null; then
    echo "  ✓ Puede ejecutar sudo SIN contraseña"
elif sudo -l &>/dev/null; then
    echo "  ✓ Puede ejecutar sudo CON contraseña"
else
    echo "  ✗ NO tiene privilegios sudo"
fi
echo ""

echo "--- Directorios importantes ---"
dirs_check=(
    "$HOME"
    "/mnt/games"
    "/mnt/steam_epic"
    "/tmp"
)

for dir in "${dirs_check[@]}"; do
    if [ -d "$dir" ]; then
        perms=$(stat -c "%a %U:%G" "$dir" 2>/dev/null)
        echo "  $dir"
        echo "    Permisos: $perms"
    fi
done
echo ""
sleep 5

# ═══════════════════════════════════════════════════════════════
# 14. SESIONES Y LOGINS
# ═══════════════════════════════════════════════════════════════
echo "━━━ 14. SESIONES Y LOGINS ━━━"
echo ""

echo "--- Usuarios conectados actualmente ---"
who
echo ""

echo "--- Últimos logins ---"
last -n 10 | head -15
echo ""

echo "--- Intentos de login fallidos (últimos 10) ---"
if [ -f /var/log/auth.log ]; then
    sudo grep "Failed password" /var/log/auth.log 2>/dev/null | tail -10 || echo "  No hay intentos fallidos recientes"
else
    echo "  Log no disponible"
fi
echo ""
sleep 5

echo "════════════════════════════════════════════════════════════"
echo "  FIN DEL DIAGNÓSTICO"
echo "════════════════════════════════════════════════════════════"
