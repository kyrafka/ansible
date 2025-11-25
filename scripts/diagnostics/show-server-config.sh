#!/bin/bash

# ════════════════════════════════════════════════════════════════
# 📋 MOSTRAR CONFIGURACIONES COMPLETAS DEL SERVIDOR
# ════════════════════════════════════════════════════════════════
# Este script muestra TODAS las configuraciones del servidor
# para la demostración de la rúbrica

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Función para mostrar secciones
show_section() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Función para mostrar subsecciones
show_subsection() {
    echo ""
    echo -e "${YELLOW}🔹 $1${NC}"
    echo ""
}

clear
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}📋 CONFIGURACIONES DEL SERVIDOR ${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Fecha: $(date)"
echo "Servidor: $(hostname)"
echo "Usuario: $(whoami)"
echo ""
echo "Presiona ENTER para continuar..."
read

# ════════════════════════════════════════════════════════════════
# 1️⃣  INFORMACIÓN DEL SISTEMA
# ════════════════════════════════════════════════════════════════
show_section "1️⃣  INFORMACIÓN DEL SISTEMA"

show_subsection "Sistema Operativo"
cat /etc/os-release | grep -E "PRETTY_NAME|VERSION"
echo ""

show_subsection "Kernel"
uname -r
echo ""

show_subsection "Arquitectura"
uname -m
echo ""

show_subsection "Uptime"
uptime -p
echo ""

show_subsection "Recursos del sistema"
echo "CPU:"
lscpu | grep -E "Model name|CPU\(s\):|Thread"
echo ""
echo "Memoria:"
free -h | grep -E "Mem:|Swap:"
echo ""

echo "Presiona ENTER para continuar..."
read

# ════════════════════════════════════════════════════════════════
# 2️⃣  CONFIGURACIÓN DE RED IPv6
# ════════════════════════════════════════════════════════════════
show_section "2️⃣  CONFIGURACIÓN DE RED IPv6"

show_subsection "Interfaces de red"
ip -6 addr show | grep -E "inet6|mtu|state"
echo ""

show_subsection "Rutas IPv6"
ip -6 route show
echo ""

show_subsection "Configuración Netplan"
echo "Archivo: /etc/netplan/99-server-network.yaml"
if [ -f "/etc/netplan/99-server-network.yaml" ]; then
    cat /etc/netplan/99-server-network.yaml
elif [ -f "/etc/netplan/50-cloud-init.yaml" ]; then
    echo "Usando: /etc/netplan/50-cloud-init.yaml"
    cat /etc/netplan/50-cloud-init.yaml
else
    echo "⚠️  Archivo no encontrado"
    echo "Archivos disponibles:"
    ls -la /etc/netplan/
fi
echo ""

show_subsection "IPv6 Forwarding"
echo "IPv6 forwarding: $(cat /proc/sys/net/ipv6/conf/all/forwarding)"
echo ""

echo "Presiona ENTER para continuar..."
read

# ════════════════════════════════════════════════════════════════
# 3️⃣  SERVIDOR DNS (BIND9)
# ════════════════════════════════════════════════════════════════
show_section "3️⃣  SERVIDOR DNS (BIND9)"

show_subsection "Estado del servicio"
sudo systemctl status bind9 --no-pager | head -15
echo ""

show_subsection "Versión de BIND"
named -v
echo ""

show_subsection "Configuración principal"
echo "Archivo: /etc/bind/named.conf.options"
if [ -f "/etc/bind/named.conf.options" ]; then
    sudo cat /etc/bind/named.conf.options | grep -v "^//" | grep -v "^$" | head -30
else
    echo "⚠️  Archivo no encontrado"
fi
echo ""

show_subsection "Zonas configuradas"
echo "Archivo: /etc/bind/named.conf.local"
if [ -f "/etc/bind/named.conf.local" ]; then
    sudo cat /etc/bind/named.conf.local | grep -v "^//" | grep -v "^$"
else
    echo "⚠️  Archivo no encontrado"
fi
echo ""

show_subsection "Zona directa: gamecenter.lan"
if [ -f "/var/lib/bind/db.gamecenter.lan" ]; then
    sudo cat /var/lib/bind/db.gamecenter.lan | head -30
else
    echo "⚠️  Archivo no encontrado"
fi
echo ""

show_subsection "Puerto DNS abierto"
sudo ss -tulnp | grep ":53"
echo ""

echo "Presiona ENTER para continuar..."
read

# ════════════════════════════════════════════════════════════════
# 4️⃣  SERVIDOR DHCP IPv6
# ════════════════════════════════════════════════════════════════
show_section "4️⃣  SERVIDOR DHCP IPv6"

show_subsection "Estado del servicio"
sudo systemctl status isc-dhcp-server6 --no-pager | head -15
echo ""

show_subsection "Configuración DHCPv6"
echo "Archivo: /etc/dhcp/dhcpd6.conf"
if [ -f "/etc/dhcp/dhcpd6.conf" ]; then
    sudo cat /etc/dhcp/dhcpd6.conf | grep -v "^#" | grep -v "^$" | head -40
else
    echo "⚠️  Archivo no encontrado"
fi
echo ""

show_subsection "Leases activos"
if [ -f "/var/lib/dhcp/dhcpd6.leases" ]; then
    echo "Últimos 20 leases:"
    sudo cat /var/lib/dhcp/dhcpd6.leases | tail -20
else
    echo "⚠️  Archivo no encontrado"
fi
echo ""

show_subsection "Puerto DHCP abierto"
sudo ss -tulnp | grep ":547"
echo ""

echo "Presiona ENTER para continuar..."
read

# ════════════════════════════════════════════════════════════════
# 5️⃣  SERVIDOR WEB (NGINX)
# ════════════════════════════════════════════════════════════════
show_section "5️⃣  SERVIDOR WEB (NGINX)"

show_subsection "Estado del servicio"
sudo systemctl status nginx --no-pager | head -15
echo ""

show_subsection "Versión de Nginx"
nginx -v 2>&1
echo ""

show_subsection "Configuración principal"
echo "Archivo: /etc/nginx/nginx.conf"
if [ -f "/etc/nginx/nginx.conf" ]; then
    sudo cat /etc/nginx/nginx.conf | grep -v "^#" | grep -v "^$" | head -30
else
    echo "⚠️  Archivo no encontrado"
fi
echo ""

show_subsection "Sitio configurado"
echo "Archivo: /etc/nginx/sites-available/default"
if [ -f "/etc/nginx/sites-available/default" ]; then
    sudo cat /etc/nginx/sites-available/default | grep -v "^#" | grep -v "^$" | head -30
else
    echo "⚠️  Archivo no encontrado"
fi
echo ""

show_subsection "Puerto HTTP abierto"
sudo ss -tulnp | grep ":80"
echo ""

show_subsection "Contenido de la página web"
if [ -f "/var/www/html/index.html" ]; then
    echo "Primeras 20 líneas de /var/www/html/index.html:"
    sudo cat /var/www/html/index.html | head -20
else
    echo "⚠️  Archivo no encontrado"
fi
echo ""

echo "Presiona ENTER para continuar..."
read

# ════════════════════════════════════════════════════════════════
# 6️⃣  FIREWALL (UFW)
# ════════════════════════════════════════════════════════════════
show_section "6️⃣  FIREWALL (UFW)"

show_subsection "Estado del firewall"
sudo ufw status verbose
echo ""

show_subsection "Reglas numeradas"
sudo ufw status numbered
echo ""

show_subsection "Políticas por defecto"
echo "Incoming: $(sudo ufw status verbose | grep "Default:" | head -1 | awk '{print $2}')"
echo "Outgoing: $(sudo ufw status verbose | grep "Default:" | tail -1 | awk '{print $2}')"
echo ""

show_subsection "Logs del firewall (últimas 10 líneas)"
if [ -f "/var/log/ufw.log" ]; then
    sudo tail -10 /var/log/ufw.log
else
    echo "⚠️  No hay logs disponibles"
fi
echo ""

echo "Presiona ENTER para continuar..."
read

# ════════════════════════════════════════════════════════════════
# 7️⃣  FAIL2BAN
# ════════════════════════════════════════════════════════════════
show_section "7️⃣  FAIL2BAN (PROTECCIÓN CONTRA ATAQUES)"

show_subsection "Estado del servicio"
sudo systemctl status fail2ban --no-pager | head -15
echo ""

show_subsection "Jails activos"
sudo fail2ban-client status
echo ""

show_subsection "Estado de SSH jail"
sudo fail2ban-client status sshd 2>/dev/null || echo "⚠️  SSH jail no configurado"
echo ""

show_subsection "Configuración"
echo "Archivo: /etc/fail2ban/jail.local"
if [ -f "/etc/fail2ban/jail.local" ]; then
    sudo cat /etc/fail2ban/jail.local | grep -v "^#" | grep -v "^$" | head -30
else
    echo "⚠️  Archivo no encontrado"
fi
echo ""

echo "Presiona ENTER para continuar..."
read

# ════════════════════════════════════════════════════════════════
# 8️⃣  SSH
# ════════════════════════════════════════════════════════════════
show_section "8️⃣  SSH (ACCESO REMOTO)"

show_subsection "Estado del servicio"
sudo systemctl status ssh --no-pager | head -15
echo ""

show_subsection "Configuración SSH"
echo "Archivo: /etc/ssh/sshd_config"
echo "Configuraciones importantes:"
sudo cat /etc/ssh/sshd_config | grep -E "^Port|^PermitRootLogin|^PasswordAuthentication|^PubkeyAuthentication|^AllowUsers" | grep -v "^#"
echo ""

show_subsection "Puerto SSH abierto"
sudo ss -tulnp | grep ":22"
echo ""

show_subsection "Usuarios autorizados para SSH"
sudo cat /etc/ssh/sshd_config | grep "^AllowUsers" || echo "⚠️  No hay restricción de usuarios (todos pueden intentar)"
echo ""

echo "Presiona ENTER para continuar..."
read

# ════════════════════════════════════════════════════════════════
# 9️⃣  NFS (ALMACENAMIENTO COMPARTIDO)
# ════════════════════════════════════════════════════════════════
show_section "9️⃣  NFS (ALMACENAMIENTO COMPARTIDO)"

show_subsection "Estado del servicio"
sudo systemctl status nfs-kernel-server --no-pager 2>/dev/null | head -15 || echo "⚠️  NFS no instalado"
echo ""

show_subsection "Exportaciones NFS"
echo "Archivo: /etc/exports"
if [ -f "/etc/exports" ]; then
    sudo cat /etc/exports | grep -v "^#" | grep -v "^$"
else
    echo "⚠️  Archivo no encontrado"
fi
echo ""

show_subsection "Carpetas compartidas"
if [ -d "/srv/games" ]; then
    echo "/srv/games:"
    ls -ld /srv/games
    echo ""
fi
if [ -d "/srv/instaladores" ]; then
    echo "/srv/instaladores:"
    ls -ld /srv/instaladores
    echo ""
fi

echo "Presiona ENTER para continuar..."
read

# ════════════════════════════════════════════════════════════════
# 🔟 USUARIOS DEL SERVIDOR
# ════════════════════════════════════════════════════════════════
show_section "🔟 USUARIOS DEL SERVIDOR"

show_subsection "Usuarios del sistema"
echo "Usuarios importantes:"
cat /etc/passwd | grep -E "ubuntu|auditor|dev" | awk -F: '{print $1 " (UID: " $3 ", Shell: " $7 ")"}'
echo ""

show_subsection "Grupos importantes"
echo "Grupos:"
cat /etc/group | grep -E "sudo|auditors|developers|pcgamers" | awk -F: '{print $1 " (GID: " $3 ")"}'
echo ""

show_subsection "Permisos sudo"
echo "Usuario ubuntu:"
sudo -l -U ubuntu 2>/dev/null | grep -E "may run|NOPASSWD" || echo "Sudo completo"
echo ""

echo "Usuario auditor:"
sudo -l -U auditor 2>/dev/null | grep -E "may run|NOPASSWD" || echo "Sin sudo"
echo ""

echo "Usuario dev:"
sudo -l -U dev 2>/dev/null | grep -E "may run|NOPASSWD" || echo "Sin sudo"
echo ""

show_subsection "Configuración sudoers"
if [ -f "/etc/sudoers.d/auditor" ]; then
    echo "Archivo: /etc/sudoers.d/auditor"
    sudo cat /etc/sudoers.d/auditor
    echo ""
fi

if [ -f "/etc/sudoers.d/dev" ]; then
    echo "Archivo: /etc/sudoers.d/dev"
    sudo cat /etc/sudoers.d/dev
    echo ""
fi

echo "Presiona ENTER para continuar..."
read

# ════════════════════════════════════════════════════════════════
# 1️⃣1️⃣ RESUMEN DE SERVICIOS
# ════════════════════════════════════════════════════════════════
show_section "1️⃣1️⃣ RESUMEN DE SERVICIOS"

show_subsection "Estado de todos los servicios"
echo "| Servicio | Estado | Puerto |"
echo "|----------|--------|--------|"

services=("bind9:53" "isc-dhcp-server6:547" "nginx:80" "ssh:22" "ufw:-" "fail2ban:-" "nfs-kernel-server:2049")

for service_port in "${services[@]}"; do
    service="${service_port%%:*}"
    port="${service_port##*:}"
    
    if sudo systemctl is-active --quiet "$service" 2>/dev/null; then
        status="✅ Activo"
    else
        status="❌ Inactivo"
    fi
    
    printf "| %-20s | %-10s | %-6s |\n" "$service" "$status" "$port"
done
echo ""

show_subsection "Puertos abiertos"
echo "Puertos en escucha:"
sudo ss -tulnp | grep LISTEN | grep -E ":(22|53|80|547|2049)" | awk '{print $5}' | sort -u
echo ""

show_subsection "Conexiones activas"
echo "Conexiones IPv6 activas:"
sudo ss -6 -tn | grep ESTAB | wc -l
echo " conexiones establecidas"
echo ""

echo "Presiona ENTER para continuar..."
read

# ════════════════════════════════════════════════════════════════
# 1️⃣2️⃣ LOGS RECIENTES
# ════════════════════════════════════════════════════════════════
show_section "1️⃣2️⃣ LOGS RECIENTES"

show_subsection "Logs de DNS (últimas 10 líneas)"
sudo journalctl -u bind9 -n 10 --no-pager
echo ""

show_subsection "Logs de DHCP (últimas 10 líneas)"
sudo journalctl -u isc-dhcp-server6 -n 10 --no-pager
echo ""

show_subsection "Logs de Nginx (últimas 10 líneas)"
sudo journalctl -u nginx -n 10 --no-pager
echo ""

show_subsection "Logs de SSH (últimas 10 líneas)"
sudo journalctl -u ssh -n 10 --no-pager
echo ""

echo "Presiona ENTER para finalizar..."
read

# ════════════════════════════════════════════════════════════════
# RESUMEN FINAL
# ════════════════════════════════════════════════════════════════
clear
show_section "✅ RESUMEN DE CONFIGURACIONES"

echo -e "${GREEN}Configuraciones mostradas:${NC}"
echo "  1. ✅ Información del sistema"
echo "  2. ✅ Red IPv6"
echo "  3. ✅ DNS (BIND9)"
echo "  4. ✅ DHCP IPv6"
echo "  5. ✅ Servidor Web (Nginx)"
echo "  6. ✅ Firewall (UFW)"
echo "  7. ✅ fail2ban"
echo "  8. ✅ SSH"
echo "  9. ✅ NFS"
echo " 10. ✅ Usuarios y permisos"
echo " 11. ✅ Resumen de servicios"
echo " 12. ✅ Logs recientes"
echo ""

echo -e "${YELLOW}📸 Para la demostración, toma capturas de:${NC}"
echo "  • Estado de cada servicio (systemctl status)"
echo "  • Configuraciones importantes"
echo "  • Puertos abiertos (ss -tulnp)"
echo "  • Reglas de firewall (ufw status)"
echo "  • Usuarios y permisos"
echo ""

echo -e "${CYAN}📋 Siguiente paso:${NC}"
echo "  Ejecuta las pruebas de funcionamiento con:"
echo "  bash scripts/diagnostics/test-server-functionality.sh"
echo ""

echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ CONFIGURACIONES MOSTRADAS EXITOSAMENTE${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
