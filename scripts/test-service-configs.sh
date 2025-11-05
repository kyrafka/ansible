#!/bin/bash
# Script para probar configuraciones de servicios

set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🧪 PRUEBAS DE CONFIGURACIONES DE SERVICIOS${NC}"
echo "=========================================="
echo ""

TEST_DIR="/tmp/service-config-test-$(date +%Y%m%d-%H%M)"
mkdir -p "$TEST_DIR"

# 1. Probar configuración DNS
echo -e "${BLUE}1. Probando configuración DNS/BIND9...${NC}"

# Generar named.conf
ansible localhost -m template \
    -a "src=roles/dns_bind/templates/named.conf.options.j2 dest=$TEST_DIR/named.conf.options" \
    -e "dns_forwarders=['8.8.8.8','8.8.4.4']" \
    -e "network_config={ipv6_network:'2025:db8:10::/64'}" \
    --connection=local >/dev/null 2>&1

if [ -f "$TEST_DIR/named.conf.options" ]; then
    echo -e "  ✅ named.conf.options: ${GREEN}GENERADO${NC}"
    
    # Verificar sintaxis (si bind9-utils está disponible)
    if command -v named-checkconf >/dev/null 2>&1; then
        if named-checkconf "$TEST_DIR/named.conf.options" 2>/dev/null; then
            echo -e "  ✅ Sintaxis BIND: ${GREEN}VÁLIDA${NC}"
        else
            echo -e "  ⚠️  Sintaxis BIND: ${YELLOW}REVISAR${NC}"
        fi
    else
        echo -e "  ℹ️  bind9-utils no instalado, no se puede verificar sintaxis"
    fi
else
    echo -e "  ❌ named.conf.options: ${RED}ERROR${NC}"
fi

echo ""

# 2. Probar configuración DHCPv6
echo -e "${BLUE}2. Probando configuración DHCPv6...${NC}"

ansible localhost -m template \
    -a "src=roles/dhcpv6/templates/dhcpd6.conf.j2 dest=$TEST_DIR/dhcpd6.conf" \
    -e "network_config={ipv6_network:'2025:db8:10::/64',dhcp_range_start:'2025:db8:10::10',dhcp_range_end:'2025:db8:10::FFFF',dns_servers:['2001:4860:4860::8888'],domain_name:'gamecenter.local'}" \
    -e "dhcp6_config={default_lease_time:600,max_lease_time:7200}" \
    --connection=local >/dev/null 2>&1

if [ -f "$TEST_DIR/dhcpd6.conf" ]; then
    echo -e "  ✅ dhcpd6.conf: ${GREEN}GENERADO${NC}"
    echo "  Configuración incluye:"
    grep -E "(subnet6|range6|option)" "$TEST_DIR/dhcpd6.conf" | sed 's/^/    /'
else
    echo -e "  ❌ dhcpd6.conf: ${RED}ERROR${NC}"
fi

echo ""

# 3. Probar configuración de firewall
echo -e "${BLUE}3. Probando configuración de firewall...${NC}"

ansible localhost -m template \
    -a "src=roles/firewall/templates/jail.local.j2 dest=$TEST_DIR/jail.local" \
    --connection=local >/dev/null 2>&1

if [ -f "$TEST_DIR/jail.local" ]; then
    echo -e "  ✅ jail.local: ${GREEN}GENERADO${NC}"
    echo "  Jails configuradas:"
    grep -E "^\[.*\]" "$TEST_DIR/jail.local" | sed 's/^/    /'
else
    echo -e "  ❌ jail.local: ${RED}ERROR${NC}"
fi

echo ""

# 4. Probar variables del proyecto
echo -e "${BLUE}4. Probando variables del proyecto...${NC}"

echo "📊 Variables principales:"
if [ -f "group_vars/all.yml" ]; then
    echo "  network_config:"
    grep -A 10 "network_config:" group_vars/all.yml | sed 's/^/    /'
    echo ""
    echo "  servicios_necesarios:"
    grep -A 10 "servicios_necesarios:" group_vars/all.yml | sed 's/^/    /'
fi

echo ""

# 5. Probar generación de inventario dinámico
echo -e "${BLUE}5. Probando inventario dinámico...${NC}"

cat > "$TEST_DIR/dynamic-inventory.yml" << 'EOF'
---
- name: Test dynamic inventory
  hosts: localhost
  connection: local
  tasks:
    - name: Add test host to inventory
      add_host:
        name: "test-vm"
        groups: nueva_vm_ubpc
        ansible_host: "2025:db8:10::15"
        ansible_user: "ubuntu"
        test_var: "dynamic_value"
    
    - name: Show dynamic host
      debug:
        msg: |
          Host dinámico agregado:
          - Nombre: test-vm
          - IP: 2025:db8:10::15
          - Usuario: ubuntu
          - Grupo: nueva_vm_ubpc
EOF

if ansible-playbook "$TEST_DIR/dynamic-inventory.yml" --check >/dev/null 2>&1; then
    echo -e "  ✅ Inventario dinámico: ${GREEN}FUNCIONA${NC}"
else
    echo -e "  ❌ Inventario dinámico: ${RED}ERROR${NC}"
fi

echo ""

# 6. Mostrar ejemplos de configuraciones generadas
echo -e "${BLUE}6. Ejemplos de configuraciones generadas:${NC}"
echo ""

echo -e "${YELLOW}📄 Fragmento de DHCPv6:${NC}"
head -10 "$TEST_DIR/dhcpd6.conf" 2>/dev/null | sed 's/^/  /' || echo "  No disponible"

echo ""
echo -e "${YELLOW}📄 Fragmento de fail2ban:${NC}"
head -15 "$TEST_DIR/jail.local" 2>/dev/null | sed 's/^/  /' || echo "  No disponible"

echo ""
echo -e "${GREEN}✅ Pruebas de configuraciones completadas${NC}"
echo ""
echo -e "${YELLOW}📁 Configuraciones generadas en: $TEST_DIR${NC}"
echo -e "${YELLOW}💡 Para limpiar: rm -rf $TEST_DIR${NC}"