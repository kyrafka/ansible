#!/bin/bash

# ════════════════════════════════════════════════════════════════
# 📋 GENERADOR COMPLETO DE EVIDENCIAS PARA RÚBRICA
# ════════════════════════════════════════════════════════════════
# Este script genera TODAS las evidencias necesarias para la rúbrica
# Ejecutar en el servidor o en los clientes

OUTPUT_DIR="$HOME/evidencias-rubrica"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="$OUTPUT_DIR/reporte_$TIMESTAMP.txt"

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Crear directorio de salida
mkdir -p "$OUTPUT_DIR"

echo "════════════════════════════════════════════════════════════════" | tee "$REPORT_FILE"
echo "📋 GENERACIÓN COMPLETA DE EVIDENCIAS PARA RÚBRICA" | tee -a "$REPORT_FILE"
echo "════════════════════════════════════════════════════════════════" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"
echo "Fecha: $(date)" | tee -a "$REPORT_FILE"
echo "Host: $(hostname)" | tee -a "$REPORT_FILE"
echo "Usuario: $(whoami)" | tee -a "$REPORT_FILE"
echo "Directorio de salida: $OUTPUT_DIR" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

# ════════════════════════════════════════════════════════════════
# 1️⃣  INFORMACIÓN DEL SISTEMA
# ════════════════════════════════════════════════════════════════
echo "════════════════════════════════════════════════════════════════" | tee -a "$REPORT_FILE"
echo "1️⃣  INFORMACIÓN DEL SISTEMA" | tee -a "$REPORT_FILE"
echo "════════════════════════════════════════════════════════════════" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

echo "Sistema Operativo:" | tee -a "$REPORT_FILE"
cat /etc/os-release | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

echo "Kernel:" | tee -a "$REPORT_FILE"
uname -a | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

echo "Uptime:" | tee -a "$REPORT_FILE"
uptime | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

# ════════════════════════════════════════════════════════════════
# 2️⃣  CONFIGURACIÓN DE RED
# ════════════════════════════════════════════════════════════════
echo "════════════════════════════════════════════════════════════════" | tee -a "$REPORT_FILE"
echo "2️⃣  CONFIGURACIÓN DE RED IPv6" | tee -a "$REPORT_FILE"
echo "════════════════════════════════════════════════════════════════" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

echo "Interfaces de red:" | tee -a "$REPORT_FILE"
ip -6 addr show | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

echo "Rutas IPv6:" | tee -a "$REPORT_FILE"
ip -6 route show | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

echo "Tabla de rutas (formato tabla):" | tee -a "$REPORT_FILE"
ip -6 route show | column -t | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

# ════════════════════════════════════════════════════════════════
# 3️⃣  PRUEBAS DE CONECTIVIDAD
# ════════════════════════════════════════════════════════════════
echo "════════════════════════════════════════════════════════════════" | tee -a "$REPORT_FILE"
echo "3️⃣  PRUEBAS DE CONECTIVIDAD" | tee -a "$REPORT_FILE"
echo "════════════════════════════════════════════════════════════════" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

SERVER_IP="2025:db8:10::2"
DOMAIN="gamecenter.lan"

echo "Ping al servidor ($SERVER_IP):" | tee -a "$REPORT_FILE"
ping6 -c 4 $SERVER_IP 2>&1 | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

echo "Resolución DNS de $DOMAIN:" | tee -a "$REPORT_FILE"
dig @$SERVER_IP $DOMAIN AAAA +short 2>&1 | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

echo "Acceso HTTP:" | tee -a "$REPORT_FILE"
curl -6 http://$DOMAIN -I 2>&1 | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

# ════════════════════════════════════════════════════════════════
# 4️⃣  SERVICIOS (Solo en servidor)
# ════════════════════════════════════════════════════════════════
if [ "$(hostname)" = "ubpc" ] || [ "$(hostname)" = "servidor" ]; then
    echo "════════════════════════════════════════════════════════════════" | tee -a "$REPORT_FILE"
    echo "4️⃣  SERVICIOS DEL SERVIDOR" | tee -a "$REPORT_FILE"
    echo "════════════════════════════════════════════════════════════════" | tee -a "$REPORT_FILE"
    echo "" | tee -a "$REPORT_FILE"
    
    for service in bind9 isc-dhcp-server6 nginx ssh ufw fail2ban; do
        echo "Estado de $service:" | tee -a "$REPORT_FILE"
        sudo systemctl status $service --no-pager 2>&1 | head -10 | tee -a "$REPORT_FILE"
        echo "" | tee -a "$REPORT_FILE"
    done
    
    echo "Puertos abiertos:" | tee -a "$REPORT_FILE"
    sudo ss -tulnp | grep -E ":(22|53|80|547)" | tee -a "$REPORT_FILE"
    echo "" | tee -a "$REPORT_FILE"
    
    echo "Reglas de firewall:" | tee -a "$REPORT_FILE"
    sudo ufw status verbose | tee -a "$REPORT_FILE"
    echo "" | tee -a "$REPORT_FILE"
fi

# ════════════════════════════════════════════════════════════════
# 5️⃣  PARTICIONES Y ALMACENAMIENTO
# ════════════════════════════════════════════════════════════════
echo "════════════════════════════════════════════════════════════════" | tee -a "$REPORT_FILE"
echo "5️⃣  PARTICIONES Y ALMACENAMIENTO" | tee -a "$REPORT_FILE"
echo "════════════════════════════════════════════════════════════════" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

echo "Bloques de dispositivos:" | tee -a "$REPORT_FILE"
lsblk | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

echo "Uso de disco:" | tee -a "$REPORT_FILE"
df -h | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

if command -v pvdisplay &> /dev/null; then
    echo "LVM - Physical Volumes:" | tee -a "$REPORT_FILE"
    sudo pvdisplay 2>/dev/null | grep -E "PV Name|VG Name|PV Size" | tee -a "$REPORT_FILE"
    echo "" | tee -a "$REPORT_FILE"
    
    echo "LVM - Volume Groups:" | tee -a "$REPORT_FILE"
    sudo vgdisplay 2>/dev/null | grep -E "VG Name|VG Size|Free" | tee -a "$REPORT_FILE"
    echo "" | tee -a "$REPORT_FILE"
    
    echo "LVM - Logical Volumes:" | tee -a "$REPORT_FILE"
    sudo lvdisplay 2>/dev/null | grep -E "LV Path|LV Name|LV Size" | tee -a "$REPORT_FILE"
    echo "" | tee -a "$REPORT_FILE"
fi

# ════════════════════════════════════════════════════════════════
# 6️⃣  USUARIOS Y GRUPOS
# ════════════════════════════════════════════════════════════════
echo "════════════════════════════════════════════════════════════════" | tee -a "$REPORT_FILE"
echo "6️⃣  USUARIOS Y GRUPOS" | tee -a "$REPORT_FILE"
echo "════════════════════════════════════════════════════════════════" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

echo "Usuarios del sistema:" | tee -a "$REPORT_FILE"
cat /etc/passwd | grep -E "ubuntu|auditor|dev|gamer01|administrador" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

echo "Grupos importantes:" | tee -a "$REPORT_FILE"
cat /etc/group | grep -E "sudo|auditors|pcgamers|developers" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

CURRENT_USER=$(whoami)
echo "Usuario actual: $CURRENT_USER" | tee -a "$REPORT_FILE"
echo "Grupos del usuario actual:" | tee -a "$REPORT_FILE"
groups $CURRENT_USER | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

# ════════════════════════════════════════════════════════════════
# 7️⃣  PERMISOS Y SEGURIDAD
# ════════════════════════════════════════════════════════════════
echo "════════════════════════════════════════════════════════════════" | tee -a "$REPORT_FILE"
echo "7️⃣  PERMISOS Y SEGURIDAD" | tee -a "$REPORT_FILE"
echo "════════════════════════════════════════════════════════════════" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

if [ -d "/srv/games" ]; then
    echo "Permisos de /srv/games:" | tee -a "$REPORT_FILE"
    ls -ld /srv/games | tee -a "$REPORT_FILE"
    echo "" | tee -a "$REPORT_FILE"
fi

if [ -d "/home/auditor" ]; then
    echo "Permisos de /home/auditor:" | tee -a "$REPORT_FILE"
    ls -ld /home/auditor | tee -a "$REPORT_FILE"
    echo "" | tee -a "$REPORT_FILE"
fi

if [ -d "/home/gamer01" ]; then
    echo "Permisos de /home/gamer01:" | tee -a "$REPORT_FILE"
    ls -ld /home/gamer01 | tee -a "$REPORT_FILE"
    echo "" | tee -a "$REPORT_FILE"
fi

# ════════════════════════════════════════════════════════════════
# 8️⃣  LOGS DE SEGURIDAD
# ════════════════════════════════════════════════════════════════
echo "════════════════════════════════════════════════════════════════" | tee -a "$REPORT_FILE"
echo "8️⃣  LOGS DE SEGURIDAD (últimas 20 líneas)" | tee -a "$REPORT_FILE"
echo "════════════════════════════════════════════════════════════════" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

if [ -f "/var/log/auth.log" ]; then
    echo "Últimos intentos de autenticación:" | tee -a "$REPORT_FILE"
    sudo tail -20 /var/log/auth.log | tee -a "$REPORT_FILE"
    echo "" | tee -a "$REPORT_FILE"
fi

# ════════════════════════════════════════════════════════════════
# 9️⃣  RESUMEN Y ESTADÍSTICAS
# ════════════════════════════════════════════════════════════════
echo "════════════════════════════════════════════════════════════════" | tee -a "$REPORT_FILE"
echo "9️⃣  RESUMEN Y ESTADÍSTICAS" | tee -a "$REPORT_FILE"
echo "════════════════════════════════════════════════════════════════" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

# Contar pruebas exitosas
TESTS_PASSED=0
TESTS_TOTAL=5

ping6 -c 1 $SERVER_IP &>/dev/null && ((TESTS_PASSED++))
dig @$SERVER_IP $DOMAIN AAAA +short &>/dev/null && ((TESTS_PASSED++))
curl -6 -s http://$DOMAIN &>/dev/null && ((TESTS_PASSED++))
nc -6 -zv $SERVER_IP 53 &>/dev/null && ((TESTS_PASSED++))
nc -6 -zv $SERVER_IP 80 &>/dev/null && ((TESTS_PASSED++))

echo "Pruebas de conectividad: $TESTS_PASSED/$TESTS_TOTAL exitosas" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

if [ $TESTS_PASSED -eq $TESTS_TOTAL ]; then
    echo "✅ NIVEL 4 ALCANZADO - Conectividad completa y funcional" | tee -a "$REPORT_FILE"
elif [ $TESTS_PASSED -ge 3 ]; then
    echo "⚠️  NIVEL 3 - Conectividad básica con funcionalidad" | tee -a "$REPORT_FILE"
else
    echo "❌ NIVEL 1-2 - Conectividad parcial o inestable" | tee -a "$REPORT_FILE"
fi
echo "" | tee -a "$REPORT_FILE"

# ════════════════════════════════════════════════════════════════
# 🔟 ARCHIVOS GENERADOS
# ════════════════════════════════════════════════════════════════
echo "════════════════════════════════════════════════════════════════" | tee -a "$REPORT_FILE"
echo "🔟 ARCHIVOS GENERADOS" | tee -a "$REPORT_FILE"
echo "════════════════════════════════════════════════════════════════" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

# Guardar configuraciones importantes
if [ "$(hostname)" = "ubpc" ] || [ "$(hostname)" = "servidor" ]; then
    echo "Guardando configuraciones del servidor..." | tee -a "$REPORT_FILE"
    
    # Netplan
    if [ -f "/etc/netplan/50-cloud-init.yaml" ]; then
        cp /etc/netplan/50-cloud-init.yaml "$OUTPUT_DIR/netplan_$TIMESTAMP.yaml"
        echo "  ✓ Netplan guardado" | tee -a "$REPORT_FILE"
    fi
    
    # DNS zones
    if [ -f "/var/lib/bind/db.gamecenter.lan" ]; then
        sudo cp /var/lib/bind/db.gamecenter.lan "$OUTPUT_DIR/dns_zone_$TIMESTAMP.txt"
        echo "  ✓ Zona DNS guardada" | tee -a "$REPORT_FILE"
    fi
    
    # DHCP leases
    if [ -f "/var/lib/dhcp/dhcpd6.leases" ]; then
        sudo cp /var/lib/dhcp/dhcpd6.leases "$OUTPUT_DIR/dhcp_leases_$TIMESTAMP.txt"
        echo "  ✓ Leases DHCP guardados" | tee -a "$REPORT_FILE"
    fi
    
    # Firewall rules
    sudo ufw status verbose > "$OUTPUT_DIR/firewall_rules_$TIMESTAMP.txt"
    echo "  ✓ Reglas de firewall guardadas" | tee -a "$REPORT_FILE"
fi

echo "" | tee -a "$REPORT_FILE"
echo "════════════════════════════════════════════════════════════════" | tee -a "$REPORT_FILE"
echo "✅ GENERACIÓN DE EVIDENCIAS COMPLETADA" | tee -a "$REPORT_FILE"
echo "════════════════════════════════════════════════════════════════" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"
echo "Reporte guardado en: $REPORT_FILE" | tee -a "$REPORT_FILE"
echo "Archivos adicionales en: $OUTPUT_DIR" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"
echo "📸 COMANDOS PARA CAPTURAS DE PANTALLA:" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"
echo "1. Ver reporte completo:" | tee -a "$REPORT_FILE"
echo "   cat $REPORT_FILE" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"
echo "2. Listar archivos generados:" | tee -a "$REPORT_FILE"
echo "   ls -lh $OUTPUT_DIR" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"
echo "3. Ejecutar pruebas individuales:" | tee -a "$REPORT_FILE"
echo "   bash scripts/diagnostics/test-connectivity-full.sh" | tee -a "$REPORT_FILE"
echo "   bash scripts/diagnostics/show-partitions.sh" | tee -a "$REPORT_FILE"
echo "   bash scripts/diagnostics/check-user-permissions.sh" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"
echo "════════════════════════════════════════════════════════════════" | tee -a "$REPORT_FILE"

# Hacer ejecutables los scripts
chmod +x "$OUTPUT_DIR"/*.sh 2>/dev/null

echo ""
echo -e "${GREEN}✅ Reporte generado exitosamente${NC}"
echo -e "${BLUE}📁 Ubicación: $OUTPUT_DIR${NC}"
echo ""
