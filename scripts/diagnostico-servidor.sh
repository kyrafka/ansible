#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Script de Diagnóstico - SERVIDOR
# ═══════════════════════════════════════════════════════════════

echo "════════════════════════════════════════════════════════════"
echo "  DIAGNÓSTICO DEL SERVIDOR - $(date)"
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
echo ""

# ═══════════════════════════════════════════════════════════════
# 2. CONFIGURACIÓN DE RED
# ═══════════════════════════════════════════════════════════════
echo "━━━ 2. CONFIGURACIÓN DE RED ━━━"
echo ""
echo "--- Interfaces de red ---"
ip -6 addr show | grep -E "inet6|^[0-9]"
echo ""

echo "--- Rutas IPv6 ---"
ip -6 route show
echo ""

echo "--- IPs configuradas ---"
echo "IPv6 del servidor:"
ip -6 addr show | grep "inet6 2025" | awk '{print $2}'
echo ""

# ═══════════════════════════════════════════════════════════════
# 3. SERVICIOS CRÍTICOS
# ═══════════════════════════════════════════════════════════════
echo "━━━ 3. ESTADO DE SERVICIOS CRÍTICOS ━━━"
servicios=("ssh" "bind9" "isc-dhcp-server" "radvd" "nfs-kernel-server" "ufw")

for servicio in "${servicios[@]}"; do
    if systemctl is-active --quiet "$servicio"; then
        echo "✓ $servicio: ACTIVO"
    else
        echo "✗ $servicio: INACTIVO"
    fi
done
echo ""

# ═══════════════════════════════════════════════════════════════
# 4. FIREWALL
# ═══════════════════════════════════════════════════════════════
echo "━━━ 4. ESTADO DEL FIREWALL ━━━"
sudo ufw status numbered
echo ""

# ═══════════════════════════════════════════════════════════════
# 5. CONECTIVIDAD - PING A CLIENTES
# ═══════════════════════════════════════════════════════════════
echo "━━━ 5. CONECTIVIDAD CON CLIENTES ━━━"
echo ""

# Ubuntu Desktop
echo "--- Ping a Ubuntu Desktop (2025:db8:10::dce9) ---"
if ping6 -c 3 2025:db8:10::200 > /dev/null 2>&1; then
    echo "✓ Ubuntu Desktop: ACCESIBLE"
    ping6 -c 3 2025:db8:10::200 | tail -2
else
    echo "✗ Ubuntu Desktop: NO ACCESIBLE"
fi
echo ""

# Windows 11 - VM 1
echo "--- Ping a Windows 11-01 (2025:db8:10::11) ---"
if ping6 -c 3 2025:db8:10::11 > /dev/null 2>&1; then
    echo "✓ Windows 11-01: ACCESIBLE"
    ping6 -c 3 2025:db8:10::11 | tail -2
else
    echo "✗ Windows 11-01: NO ACCESIBLE"
fi
echo ""

# Windows 11 - Gaming
echo "--- Ping a Windows 11-Gaming (2025:db8:10::56) ---"
if ping6 -c 3 2025:db8:10::56 > /dev/null 2>&1; then
    echo "✓ Windows 11-Gaming: ACCESIBLE"
    ping6 -c 3 2025:db8:10::56 | tail -2
else
    echo "✗ Windows 11-Gaming: NO ACCESIBLE"
fi
echo ""

# Windows 11 - Office
echo "--- Ping a Windows 11-Office (2025:db8:10::72) ---"
if ping6 -c 3 2025:db8:10::72 > /dev/null 2>&1; then
    echo "✓ Windows 11-Office: ACCESIBLE"
    ping6 -c 3 2025:db8:10::72 | tail -2
else
    echo "✗ Windows 11-Office: NO ACCESIBLE"
fi
echo ""

# ═══════════════════════════════════════════════════════════════
# 6. DNS
# ═══════════════════════════════════════════════════════════════
echo "━━━ 6. PRUEBAS DNS ━━━"
echo ""
echo "--- Resolución DNS local ---"
nslookup servidor.gamecenter.lan localhost
echo ""

# ═══════════════════════════════════════════════════════════════
# 7. DHCP
# ═══════════════════════════════════════════════════════════════
echo "━━━ 7. LEASES DHCP ACTIVOS ━━━"
if [ -f /var/lib/dhcp/dhcpd6.leases ]; then
    echo "Últimos leases DHCPv6:"
    sudo grep "^lease" /var/lib/dhcp/dhcpd6.leases | tail -5
else
    echo "No se encontró archivo de leases DHCPv6"
fi
echo ""

# ═══════════════════════════════════════════════════════════════
# 8. NFS
# ═══════════════════════════════════════════════════════════════
echo "━━━ 8. EXPORTACIONES NFS ━━━"
sudo exportfs -v
echo ""

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

echo "--- Uso de Disco ---"
df -h | grep -E "Filesystem|/dev/"
echo ""

# ═══════════════════════════════════════════════════════════════
# 10. PUERTOS ABIERTOS
# ═══════════════════════════════════════════════════════════════
echo "━━━ 10. PUERTOS EN ESCUCHA ━━━"
sudo ss -tulpn | grep LISTEN | grep -E ":(22|53|67|547|2049|111)" | awk '{print $5, $7}'
echo ""

echo "════════════════════════════════════════════════════════════"
echo "  FIN DEL DIAGNÓSTICO"
echo "════════════════════════════════════════════════════════════"
