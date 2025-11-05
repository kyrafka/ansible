#!/bin/bash
# Script para probar generación de templates Jinja2

set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🧪 PRUEBAS DE TEMPLATES JINJA2${NC}"
echo "=============================="
echo ""

# Crear directorio temporal
TEST_DIR="/tmp/jinja-test-$(date +%Y%m%d-%H%M)"
mkdir -p "$TEST_DIR"

echo -e "${BLUE}📁 Directorio de pruebas: $TEST_DIR${NC}"
echo ""

# 1. Probar template de rsyslog
echo -e "${BLUE}1. Probando template de rsyslog...${NC}"
ansible localhost -m template \
    -a "src=roles/common/templates/rsyslog-proyecto.conf.j2 dest=$TEST_DIR/rsyslog-test.conf" \
    -e "servicios_necesarios=['bind9','isc-dhcp-server6','fail2ban']" \
    -e "ansible_hostname=test-server" \
    --connection=local

if [ -f "$TEST_DIR/rsyslog-test.conf" ]; then
    echo -e "  ✅ rsyslog-proyecto.conf.j2: ${GREEN}GENERADO${NC}"
    echo "  Líneas generadas: $(wc -l < "$TEST_DIR/rsyslog-test.conf")"
    echo "  Servicios configurados:"
    grep -E "programname.*isequal" "$TEST_DIR/rsyslog-test.conf" | sed 's/^/    /'
else
    echo -e "  ❌ rsyslog-proyecto.conf.j2: ${RED}ERROR${NC}"
fi

echo ""

# 2. Probar template de logrotate
echo -e "${BLUE}2. Probando template de logrotate...${NC}"
ansible localhost -m template \
    -a "src=roles/common/templates/logrotate-proyecto.conf.j2 dest=$TEST_DIR/logrotate-test.conf" \
    -e "storage={dns_log_retention_days:14,dhcp_log_retention_days:7,security_log_retention_days:30}" \
    -e "ansible_hostname=test-server" \
    --connection=local

if [ -f "$TEST_DIR/logrotate-test.conf" ]; then
    echo -e "  ✅ logrotate-proyecto.conf.j2: ${GREEN}GENERADO${NC}"
    echo "  Configuraciones de rotación:"
    grep -E "^/var/log" "$TEST_DIR/logrotate-test.conf" | sed 's/^/    /'
else
    echo -e "  ❌ logrotate-proyecto.conf.j2: ${RED}ERROR${NC}"
fi

echo ""

# 3. Probar template de monitoreo de logs
echo -e "${BLUE}3. Probando template de log-monitor...${NC}"
ansible localhost -m template \
    -a "src=roles/common/templates/log-monitor.sh.j2 dest=$TEST_DIR/log-monitor-test.sh mode=0755" \
    -e "ansible_hostname=test-server" \
    -e "network_config={ipv6_network:'2025:db8:10::/64'}" \
    --connection=local

if [ -f "$TEST_DIR/log-monitor-test.sh" ]; then
    echo -e "  ✅ log-monitor.sh.j2: ${GREEN}GENERADO${NC}"
    echo "  Script ejecutable: $([ -x "$TEST_DIR/log-monitor-test.sh" ] && echo "SÍ" || echo "NO")"
    echo "  Funciones disponibles:"
    grep -E "^[a-zA-Z_]+\(\)" "$TEST_DIR/log-monitor-test.sh" | sed 's/^/    /'
else
    echo -e "  ❌ log-monitor.sh.j2: ${RED}ERROR${NC}"
fi

echo ""

# 4. Probar template de user-data para VM
echo -e "${BLUE}4. Probando template de user-data...${NC}"
ansible localhost -m template \
    -a "src=roles/vmware/templates/user-data.j2 dest=$TEST_DIR/user-data-test.yml" \
    -e "vault_ubuntu_user=ubuntu" \
    -e "vault_ubuntu_password=ubuntu123" \
    -e "ssh_authorized_key='ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... test@example.com'" \
    --connection=local

if [ -f "$TEST_DIR/user-data-test.yml" ]; then
    echo -e "  ✅ user-data.j2: ${GREEN}GENERADO${NC}"
    echo "  Configuración cloud-init válida:"
    if command -v python3 >/dev/null 2>&1; then
        if python3 -c "import yaml; yaml.safe_load(open('$TEST_DIR/user-data-test.yml'))" 2>/dev/null; then
            echo -e "    ${GREEN}YAML válido${NC}"
        else
            echo -e "    ${RED}YAML inválido${NC}"
        fi
    fi
else
    echo -e "  ❌ user-data.j2: ${RED}ERROR${NC}"
fi

echo ""

# 5. Mostrar contenido de ejemplo
echo -e "${BLUE}5. Ejemplo de contenido generado:${NC}"
echo ""
echo -e "${YELLOW}📄 Fragmento de rsyslog generado:${NC}"
head -15 "$TEST_DIR/rsyslog-test.conf" 2>/dev/null | sed 's/^/  /' || echo "  No disponible"

echo ""
echo -e "${YELLOW}📄 Fragmento de logrotate generado:${NC}"
head -10 "$TEST_DIR/logrotate-test.conf" 2>/dev/null | sed 's/^/  /' || echo "  No disponible"

echo ""
echo -e "${GREEN}✅ Pruebas de templates Jinja2 completadas${NC}"
echo ""
echo -e "${YELLOW}📁 Archivos generados en: $TEST_DIR${NC}"
echo -e "${YELLOW}💡 Para limpiar: rm -rf $TEST_DIR${NC}"