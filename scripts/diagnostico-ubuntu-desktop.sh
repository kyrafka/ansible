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
# 10. USUARIOS DEL SISTEMA
# ═══════════════════════════════════════════════════════════════
echo "━━━ 10. USUARIOS DEL SISTEMA ━━━"
echo "Usuarios con shell de login:"
grep -E "/bin/bash|/bin/sh" /etc/passwd | cut -d: -f1
echo ""
sleep 5

echo "════════════════════════════════════════════════════════════"
echo "  FIN DEL DIAGNÓSTICO"
echo "════════════════════════════════════════════════════════════"
