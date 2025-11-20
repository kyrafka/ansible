#!/bin/bash
# Script para verificar servicios instalados
# Ejecutar: bash scripts/diagnostics/check-services.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

clear
echo ""
echo "════════════════════════════════════════════════════════"
echo "🔍 VERIFICACIÓN DE SERVICIOS"
echo "════════════════════════════════════════════════════════"
echo ""

# Usuarios
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "👥 USUARIOS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
for user in ubuntu auditor dev; do
    if id "$user" &>/dev/null; then
        echo -e "${GREEN}✅ $user${NC} - $(id $user)"
    else
        echo -e "${RED}❌ $user no existe${NC}"
    fi
done
echo ""

# Servicios
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 SERVICIOS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

services=("ssh:SSH" "smbd:Samba" "vsftpd:FTP" "netdata:Netdata" "cockpit:Cockpit")

for service_info in "${services[@]}"; do
    IFS=':' read -r service name <<< "$service_info"
    if systemctl is-active --quiet "$service"; then
        echo -e "${GREEN}✅ $name${NC} - activo"
    else
        echo -e "${RED}❌ $name${NC} - inactivo"
    fi
done
echo ""

# Puertos
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔌 PUERTOS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ports=("22:SSH" "445:Samba" "21:FTP" "19999:Netdata" "9090:Cockpit")

for port_info in "${ports[@]}"; do
    IFS=':' read -r port name <<< "$port_info"
    if sudo ss -tulpn | grep -q ":$port "; then
        echo -e "${GREEN}✅ $name${NC} - puerto $port abierto"
    else
        echo -e "${RED}❌ $name${NC} - puerto $port cerrado"
    fi
done
echo ""

# Directorios
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📁 DIRECTORIOS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

dirs=("/srv/samba:Samba" "/srv/ftp:FTP" "/srv/nfs:NFS")

for dir_info in "${dirs[@]}"; do
    IFS=':' read -r dir name <<< "$dir_info"
    if [ -d "$dir" ]; then
        echo -e "${GREEN}✅ $name${NC} - $dir existe"
        ls -la "$dir" 2>/dev/null | head -5 | sed 's/^/   /'
    else
        echo -e "${RED}❌ $name${NC} - $dir no existe"
    fi
done
echo ""

# Acceso web
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌐 ACCESO WEB"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

IP=$(ip -6 addr show ens34 2>/dev/null | grep "inet6.*2025:db8:10" | awk '{print $2}' | cut -d'/' -f1 | head -1)
if [ -z "$IP" ]; then
    IP="[IP-del-servidor]"
fi

echo "Netdata:  http://$IP:19999"
echo "Cockpit:  https://$IP:9090"
echo ""

# SSH
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔐 SSH"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if systemctl is-active --quiet ssh; then
    PORT=$(sudo grep "^Port" /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}')
    if [ -z "$PORT" ]; then
        PORT="22"
    fi
    echo -e "${GREEN}✅ SSH activo${NC}"
    echo "   Puerto: $PORT"
    echo "   Conectar: ssh ubuntu@$IP"
else
    echo -e "${RED}❌ SSH inactivo${NC}"
fi
echo ""

# Resumen
echo "════════════════════════════════════════════════════════"
echo "📊 RESUMEN"
echo "════════════════════════════════════════════════════════"

TOTAL=0
OK=0

for service in ssh smbd vsftpd; do
    ((TOTAL++))
    systemctl is-active --quiet "$service" && ((OK++))
done

echo "Servicios funcionando: $OK/$TOTAL"
echo ""

if [ $OK -eq $TOTAL ]; then
    echo -e "${GREEN}✅ Todo funcionando correctamente${NC}"
else
    echo -e "${YELLOW}⚠️  Algunos servicios no están activos${NC}"
    echo ""
    echo "Para iniciar servicios:"
    echo "  sudo systemctl start smbd"
    echo "  sudo systemctl start vsftpd"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo ""
