#!/bin/bash
# Script para probar funciones de logging localmente

set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🧪 PRUEBAS DE LOGGING LOCAL${NC}"
echo "=========================="
echo ""

# Crear directorios de prueba
TEST_LOG_DIR="/tmp/test-logs"
mkdir -p "$TEST_LOG_DIR"/{dns,dhcp,security,ansible}

echo -e "${BLUE}📁 Directorio de logs de prueba: $TEST_LOG_DIR${NC}"
echo ""

# 1. Simular logs de diferentes servicios
echo -e "${BLUE}1. Generando logs de prueba...${NC}"

# DNS logs
cat > "$TEST_LOG_DIR/dns/named.log" << 'EOF'
[2024-01-15T10:30:45+00:00] test-server DNS[1234]: client 2025:db8:10::15#54321 (gamecenter.local): query: gamecenter.local IN AAAA + (2025:db8:10::10)
[2024-01-15T10:30:46+00:00] test-server DNS[1234]: client 2025:db8:10::16#12345 (servidor.gamecenter.local): query: servidor.gamecenter.local IN AAAA + (2025:db8:10::10)
[2024-01-15T10:30:47+00:00] test-server DNS[1234]: zone gamecenter.local/IN: loaded serial 2024011501
EOF

# DHCP logs
cat > "$TEST_LOG_DIR/dhcp/dhcpd6.log" << 'EOF'
[2024-01-15T10:31:00+00:00] test-server DHCP[5678]: Solicit message from 2025:db8:10::0 port 546, transaction ID 0x12345678
[2024-01-15T10:31:01+00:00] test-server DHCP[5678]: Advertise NA: address 2025:db8:10::15 to client with duid 00:01:00:01:27:71:4e:a1:00:0c:29:2c:9c:27
[2024-01-15T10:31:02+00:00] test-server DHCP[5678]: Request message from 2025:db8:10::15 port 546, transaction ID 0x87654321
EOF

# Security logs
cat > "$TEST_LOG_DIR/security/fail2ban.log" << 'EOF'
[2024-01-15T10:32:00+00:00] test-server SECURITY[9012]: fail2ban.actions: WARNING [sshd] Ban 192.168.1.100
[2024-01-15T10:32:30+00:00] test-server SECURITY[9012]: fail2ban.filter: INFO [sshd] Found 192.168.1.101 - 2024-01-15 10:32:30
[2024-01-15T10:33:00+00:00] test-server SECURITY[9012]: fail2ban.actions: NOTICE [sshd] Unban 192.168.1.100
EOF

# SSH logs
cat > "$TEST_LOG_DIR/security/ssh.log" << 'EOF'
[2024-01-15T10:33:15+00:00] test-server SSH[3456]: Accepted publickey for ubuntu from 2025:db8:10::5 port 54321 ssh2: ED25519 SHA256:abc123def456
[2024-01-15T10:33:45+00:00] test-server SSH[3456]: Failed password for invalid user admin from 192.168.1.200 port 12345 ssh2
[2024-01-15T10:34:00+00:00] test-server SSH[3456]: Connection closed by 192.168.1.200 port 12345 [preauth]
EOF

# Ansible logs
cat > "$TEST_LOG_DIR/ansible/ansible.log" << 'EOF'
[2024-01-15T10:35:00+00:00] test-server ANSIBLE: PLAY [Configurar servicios IPv6] **********************
[2024-01-15T10:35:01+00:00] test-server ANSIBLE: TASK [dns_bind : Instalar BIND9] **********************
[2024-01-15T10:35:15+00:00] test-server ANSIBLE: ok: [localhost] => changed=true
EOF

echo -e "  ✅ Logs de prueba generados en $TEST_LOG_DIR"

echo ""

# 2. Probar análisis de logs
echo -e "${BLUE}2. Analizando logs generados...${NC}"

echo "📊 Estadísticas por servicio:"
for service in dns dhcp security ansible; do
    if [ -d "$TEST_LOG_DIR/$service" ]; then
        count=$(find "$TEST_LOG_DIR/$service" -name "*.log" -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
        size=$(du -sh "$TEST_LOG_DIR/$service" 2>/dev/null | cut -f1)
        echo "  $service: $count líneas, $size"
    fi
done

echo ""

# 3. Probar filtros de logs
echo -e "${BLUE}3. Probando filtros de logs...${NC}"

echo "🔍 Errores y advertencias:"
grep -i -E "(error|warning|fail)" "$TEST_LOG_DIR"/*/*.log 2>/dev/null | head -5 | sed 's/^/  /' || echo "  No se encontraron errores"

echo ""
echo "🌐 Actividad DNS:"
grep -i "query" "$TEST_LOG_DIR/dns"/*.log 2>/dev/null | head -3 | sed 's/^/  /' || echo "  No hay actividad DNS"

echo ""
echo "🔧 Asignaciones DHCP:"
grep -i "advertise\|request" "$TEST_LOG_DIR/dhcp"/*.log 2>/dev/null | head -3 | sed 's/^/  /' || echo "  No hay actividad DHCP"

echo ""
echo "🛡️ Eventos de seguridad:"
grep -i -E "(ban|unban|failed|accepted)" "$TEST_LOG_DIR/security"/*.log 2>/dev/null | head -3 | sed 's/^/  /' || echo "  No hay eventos de seguridad"

echo ""

# 4. Probar rotación de logs simulada
echo -e "${BLUE}4. Simulando rotación de logs...${NC}"

for service in dns dhcp security ansible; do
    if [ -d "$TEST_LOG_DIR/$service" ]; then
        for logfile in "$TEST_LOG_DIR/$service"/*.log; do
            if [ -f "$logfile" ]; then
                # Simular compresión
                gzip -c "$logfile" > "${logfile}.1.gz" 2>/dev/null
                echo "  ✅ Rotado: $(basename "$logfile") -> $(basename "$logfile").1.gz"
            fi
        done
    fi
done

echo ""

# 5. Probar monitoreo en tiempo real (simulado)
echo -e "${BLUE}5. Simulando monitoreo en tiempo real...${NC}"
echo "Agregando nuevas entradas a los logs..."

# Agregar nuevas entradas
echo "[$(date -Iseconds)] test-server DNS[1234]: New query received" >> "$TEST_LOG_DIR/dns/named.log"
echo "[$(date -Iseconds)] test-server DHCP[5678]: New lease assigned" >> "$TEST_LOG_DIR/dhcp/dhcpd6.log"
echo "[$(date -Iseconds)] test-server SECURITY[9012]: Security check passed" >> "$TEST_LOG_DIR/security/fail2ban.log"

echo "📈 Nuevas entradas agregadas:"
tail -1 "$TEST_LOG_DIR"/*/*.log 2>/dev/null | grep -v "==>" | sed 's/^/  /'

echo ""

# 6. Generar reporte de logs
echo -e "${BLUE}6. Generando reporte de logs...${NC}"

report_file="$TEST_LOG_DIR/log-report-$(date +%Y%m%d-%H%M).txt"
{
    echo "REPORTE DE LOGS - $(date)"
    echo "========================"
    echo ""
    echo "Servidor: test-server"
    echo "Directorio: $TEST_LOG_DIR"
    echo ""
    
    echo "RESUMEN POR SERVICIO:"
    echo "--------------------"
    for service in dns dhcp security ansible; do
        if [ -d "$TEST_LOG_DIR/$service" ]; then
            echo "$service:"
            find "$TEST_LOG_DIR/$service" -name "*.log" -exec wc -l {} + 2>/dev/null | while read count file; do
                echo "  $(basename "$file"): $count líneas"
            done
            echo ""
        fi
    done
    
    echo "EVENTOS RECIENTES:"
    echo "-----------------"
    tail -5 "$TEST_LOG_DIR"/*/*.log 2>/dev/null | grep -v "==>"
    
} > "$report_file"

echo -e "  📄 Reporte generado: ${GREEN}$report_file${NC}"

echo ""
echo -e "${GREEN}✅ Pruebas de logging completadas${NC}"
echo ""
echo -e "${YELLOW}📁 Logs de prueba en: $TEST_LOG_DIR${NC}"
echo -e "${YELLOW}💡 Para limpiar: rm -rf $TEST_LOG_DIR${NC}"
echo ""
echo -e "${BLUE}🔧 Comandos útiles para logs reales:${NC}"
echo "  journalctl -u bind9 -f"
echo "  tail -f /var/log/dns/*.log"
echo "  grep ERROR /var/log/security/*.log"
echo "  logs stats  # (cuando esté instalado)"