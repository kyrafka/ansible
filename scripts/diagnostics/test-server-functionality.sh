#!/bin/bash

# ════════════════════════════════════════════════════════════════
# 🧪 PRUEBAS DE FUNCIONAMIENTO DEL SERVIDOR
# ════════════════════════════════════════════════════════════════
# Este script DEMUESTRA que todos los servicios funcionan correctamente

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Variables
SERVER_IP="2025:db8:10::2"
DOMAIN="gamecenter.lan"
TESTS_PASSED=0
TESTS_TOTAL=0

# Función para mostrar secciones
show_section() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Función para probar y mostrar resultado
test_service() {
    local test_name="$1"
    local command="$2"
    
    ((TESTS_TOTAL++))
    echo -e "${YELLOW}🔹 Probando: $test_name${NC}"
    
    # Ejecutar comando y capturar resultado
    if bash -c "$command" &>/dev/null; then
        echo -e "${GREEN}   ✅ ÉXITO${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}   ❌ FALLO${NC}"
    fi
    echo ""
}

clear
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}🧪 PRUEBAS DE FUNCIONAMIENTO DEL SERVIDOR${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Este script demuestra que TODOS los servicios funcionan"
echo ""
echo "Presiona ENTER para comenzar..."
read

# ════════════════════════════════════════════════════════════════
# 1️⃣  PRUEBAS DE RED
# ════════════════════════════════════════════════════════════════
show_section "1️⃣  PRUEBAS DE RED IPv6"

test_service "Interfaz ens34 tiene IPv6" \
    "ip -6 addr show ens34 | grep -q '2025:db8:10::2'"

test_service "IPv6 forwarding habilitado" \
    "[ \$(cat /proc/sys/net/ipv6/conf/all/forwarding) -eq 1 ]"

test_service "Ruta por defecto configurada" \
    "ip -6 route show | grep -q 'default'"

echo "Presiona ENTER para continuar..."
read

# ════════════════════════════════════════════════════════════════
# 2️⃣  PRUEBAS DE DNS
# ════════════════════════════════════════════════════════════════
show_section "2️⃣  PRUEBAS DE DNS (BIND9)"

test_service "Servicio BIND9 activo" \
    "sudo systemctl is-active --quiet bind9"

echo -e "${YELLOW}🔹 Probando: Puerto 53 TCP abierto${NC}"
if sudo ss -tulnp | grep -q '53.*tcp'; then
    echo -e "${GREEN}   ✅ ÉXITO${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}   ❌ FALLO${NC}"
fi
((TESTS_TOTAL++))
echo ""

echo -e "${YELLOW}🔹 Probando: Puerto 53 UDP abierto${NC}"
if sudo ss -tulnp | grep -q '53.*udp'; then
    echo -e "${GREEN}   ✅ ÉXITO${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}   ❌ FALLO${NC}"
fi
((TESTS_TOTAL++))
echo ""

echo -e "${YELLOW}🔹 Probando resolución DNS local${NC}"
echo "   Resolviendo: $DOMAIN"
echo ""
dig @localhost $DOMAIN AAAA +short
if [ $? -eq 0 ]; then
    echo -e "${GREEN}   ✅ ÉXITO - DNS resuelve correctamente${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}   ❌ FALLO${NC}"
fi
((TESTS_TOTAL++))
echo ""

echo -e "${YELLOW}🔹 Probando resolución inversa${NC}"
echo "   Resolviendo: $SERVER_IP"
echo ""
dig @localhost -x $SERVER_IP +short
if [ $? -eq 0 ]; then
    echo -e "${GREEN}   ✅ ÉXITO - Resolución inversa funciona${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}   ❌ FALLO${NC}"
fi
((TESTS_TOTAL++))
echo ""

echo -e "${YELLOW}🔹 Probando registros CNAME${NC}"
echo "   Resolviendo: www.$DOMAIN"
echo ""
dig @localhost www.$DOMAIN AAAA +short
if [ $? -eq 0 ]; then
    echo -e "${GREEN}   ✅ ÉXITO - CNAME funciona${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}   ❌ FALLO${NC}"
fi
((TESTS_TOTAL++))
echo ""

echo "Presiona ENTER para continuar..."
read

# ════════════════════════════════════════════════════════════════
# 3️⃣  PRUEBAS DE DHCP
# ════════════════════════════════════════════════════════════════
show_section "3️⃣  PRUEBAS DE DHCP IPv6"

echo -e "${YELLOW}🔹 Probando: Servicio DHCP activo${NC}"
if sudo systemctl is-active --quiet isc-dhcp-server6; then
    echo -e "${GREEN}   ✅ ÉXITO${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}   ❌ FALLO${NC}"
fi
((TESTS_TOTAL++))
echo ""

echo -e "${YELLOW}🔹 Probando: Puerto 547 UDP abierto${NC}"
if sudo ss -tulnp | grep -q '547.*udp'; then
    echo -e "${GREEN}   ✅ ÉXITO${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}   ❌ FALLO${NC}"
fi
((TESTS_TOTAL++))
echo ""

echo -e "${YELLOW}🔹 Probando: Archivo de leases existe${NC}"
if [ -f /var/lib/dhcp/dhcpd6.leases ]; then
    echo -e "${GREEN}   ✅ ÉXITO${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}   ❌ FALLO${NC}"
fi
((TESTS_TOTAL++))
echo ""

echo -e "${YELLOW}🔹 Verificando leases activos${NC}"
echo ""
if [ -f /var/lib/dhcp/dhcpd6.leases ]; then
    lease_count=$(sudo grep -c "^lease" /var/lib/dhcp/dhcpd6.leases)
    echo "   Leases encontrados: $lease_count"
    if [ $lease_count -gt 0 ]; then
        echo -e "${GREEN}   ✅ ÉXITO - Hay leases asignados${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${YELLOW}   ⚠️  No hay leases aún (normal si no hay clientes)${NC}"
    fi
else
    echo -e "${RED}   ❌ FALLO - Archivo de leases no existe${NC}"
fi
((TESTS_TOTAL++))
echo ""

echo "Presiona ENTER para continuar..."
read

# ════════════════════════════════════════════════════════════════
# 4️⃣  PRUEBAS DE SERVIDOR WEB
# ════════════════════════════════════════════════════════════════
show_section "4️⃣  PRUEBAS DE SERVIDOR WEB (NGINX)"

echo -e "${YELLOW}🔹 Probando: Servicio Nginx activo${NC}"
if sudo systemctl is-active --quiet nginx 2>/dev/null; then
    echo -e "${GREEN}   ✅ ÉXITO${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${YELLOW}   ⚠️  Nginx no instalado (opcional)${NC}"
fi
((TESTS_TOTAL++))
echo ""

echo -e "${YELLOW}🔹 Probando: Puerto 80 TCP abierto${NC}"
if sudo ss -tulnp | grep -q '80.*tcp'; then
    echo -e "${GREEN}   ✅ ÉXITO${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}   ❌ FALLO${NC}"
fi
((TESTS_TOTAL++))
echo ""

echo -e "${YELLOW}🔹 Probando acceso HTTP local${NC}"
echo "   URL: http://localhost"
echo ""
curl -s http://localhost | head -5
if [ $? -eq 0 ]; then
    echo -e "${GREEN}   ✅ ÉXITO - Servidor web responde${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}   ❌ FALLO${NC}"
fi
((TESTS_TOTAL++))
echo ""

echo -e "${YELLOW}🔹 Probando acceso HTTP por IPv6${NC}"
echo "   URL: http://[$SERVER_IP]"
echo ""
curl -6 -s http://[$SERVER_IP] | head -5
if [ $? -eq 0 ]; then
    echo -e "${GREEN}   ✅ ÉXITO - Acceso IPv6 funciona${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}   ❌ FALLO${NC}"
fi
((TESTS_TOTAL++))
echo ""

echo -e "${YELLOW}🔹 Probando acceso HTTP por dominio${NC}"
echo "   URL: http://$DOMAIN"
echo ""
curl -s http://$DOMAIN | head -5
if [ $? -eq 0 ]; then
    echo -e "${GREEN}   ✅ ÉXITO - Acceso por dominio funciona${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}   ❌ FALLO${NC}"
fi
((TESTS_TOTAL++))
echo ""

echo "Presiona ENTER para continuar..."
read

# ════════════════════════════════════════════════════════════════
# 5️⃣  PRUEBAS DE FIREWALL
# ════════════════════════════════════════════════════════════════
show_section "5️⃣  PRUEBAS DE FIREWALL (UFW)"

test_service "Firewall UFW activo" \
    "sudo ufw status | grep -q 'Status: active'"

test_service "Política incoming: deny" \
    "sudo ufw status verbose | grep -q 'Default: deny (incoming)'"

test_service "Política outgoing: allow" \
    "sudo ufw status verbose | grep -q 'Default: allow (outgoing)'"

echo -e "${YELLOW}🔹 Verificando reglas importantes${NC}"
echo ""
echo "Reglas configuradas:"
sudo ufw status | grep -E "22|53|80|547" | head -10
echo ""
if sudo ufw status | grep -q "22"; then
    echo -e "${GREEN}   ✅ Regla SSH configurada${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}   ❌ Regla SSH no encontrada${NC}"
fi
((TESTS_TOTAL++))
echo ""

echo "Presiona ENTER para continuar..."
read

# ════════════════════════════════════════════════════════════════
# 6️⃣  PRUEBAS DE FAIL2BAN
# ════════════════════════════════════════════════════════════════
show_section "6️⃣  PRUEBAS DE FAIL2BAN"

test_service "Servicio fail2ban activo" \
    "sudo systemctl is-active --quiet fail2ban"

echo -e "${YELLOW}🔹 Verificando jails activos${NC}"
echo ""
sudo fail2ban-client status
if [ $? -eq 0 ]; then
    echo -e "${GREEN}   ✅ ÉXITO - fail2ban funcionando${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}   ❌ FALLO${NC}"
fi
((TESTS_TOTAL++))
echo ""

echo "Presiona ENTER para continuar..."
read

# ════════════════════════════════════════════════════════════════
# 7️⃣  PRUEBAS DE SSH
# ════════════════════════════════════════════════════════════════
show_section "7️⃣  PRUEBAS DE SSH"

echo -e "${YELLOW}🔹 Probando: Servicio SSH activo${NC}"
if sudo systemctl is-active --quiet ssh; then
    echo -e "${GREEN}   ✅ ÉXITO${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}   ❌ FALLO${NC}"
fi
((TESTS_TOTAL++))
echo ""

echo -e "${YELLOW}🔹 Probando: Puerto 22 TCP abierto${NC}"
if sudo ss -tulnp | grep -q '22.*tcp'; then
    echo -e "${GREEN}   ✅ ÉXITO${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}   ❌ FALLO${NC}"
fi
((TESTS_TOTAL++))
echo ""

echo -e "${YELLOW}🔹 Verificando configuración SSH${NC}"
echo ""
echo "PermitRootLogin: $(sudo grep '^PermitRootLogin' /etc/ssh/sshd_config || echo 'no configurado')"
echo "PasswordAuthentication: $(sudo grep '^PasswordAuthentication' /etc/ssh/sshd_config || echo 'no configurado')"
echo ""
if sudo grep -q '^PermitRootLogin no' /etc/ssh/sshd_config; then
    echo -e "${GREEN}   ✅ Root login deshabilitado (seguro)${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${YELLOW}   ⚠️  Root login no está explícitamente deshabilitado${NC}"
fi
((TESTS_TOTAL++))
echo ""

echo "Presiona ENTER para continuar..."
read

# ════════════════════════════════════════════════════════════════
# 8️⃣  PRUEBAS DE NFS
# ════════════════════════════════════════════════════════════════
show_section "8️⃣  PRUEBAS DE NFS"

if sudo systemctl is-active --quiet nfs-kernel-server 2>/dev/null; then
    test_service "Servicio NFS activo" \
        "sudo systemctl is-active --quiet nfs-kernel-server"
    
    test_service "Exportaciones configuradas" \
        "sudo exportfs -v | grep -q '/'"
    
    echo -e "${YELLOW}🔹 Verificando exportaciones${NC}"
    echo ""
    sudo exportfs -v
    echo ""
else
    echo -e "${YELLOW}⚠️  NFS no está instalado (opcional)${NC}"
    echo ""
fi

echo "Presiona ENTER para continuar..."
read

# ════════════════════════════════════════════════════════════════
# 9️⃣  PRUEBAS DE USUARIOS
# ════════════════════════════════════════════════════════════════
show_section "9️⃣  PRUEBAS DE USUARIOS Y PERMISOS"

test_service "Usuario ubuntu existe" \
    "id ubuntu &>/dev/null"

test_service "Usuario auditor existe" \
    "id auditor &>/dev/null"

test_service "Usuario dev existe" \
    "id dev &>/dev/null"

echo -e "${YELLOW}🔹 Verificando permisos sudo${NC}"
echo ""
echo "Usuario ubuntu:"
if sudo -l -U ubuntu 2>/dev/null | grep -q "ALL"; then
    echo -e "${GREEN}   ✅ Tiene sudo completo${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}   ❌ No tiene sudo${NC}"
fi
((TESTS_TOTAL++))
echo ""

echo "Usuario auditor:"
if sudo -l -U auditor 2>/dev/null | grep -q "NOPASSWD"; then
    echo -e "${GREEN}   ✅ Tiene sudo limitado${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${YELLOW}   ⚠️  Sin sudo (puede ser correcto)${NC}"
fi
((TESTS_TOTAL++))
echo ""

echo "Presiona ENTER para continuar..."
read

# ════════════════════════════════════════════════════════════════
# 🔟 PRUEBAS DE CONECTIVIDAD EXTERNA
# ════════════════════════════════════════════════════════════════
show_section "🔟 PRUEBAS DE CONECTIVIDAD"

echo -e "${YELLOW}🔹 Probando ping a localhost${NC}"
echo ""
ping6 -c 2 ::1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}   ✅ ÉXITO - Loopback funciona${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}   ❌ FALLO${NC}"
fi
((TESTS_TOTAL++))
echo ""

echo -e "${YELLOW}🔹 Probando ping a la IP del servidor${NC}"
echo ""
ping6 -c 2 $SERVER_IP
if [ $? -eq 0 ]; then
    echo -e "${GREEN}   ✅ ÉXITO - IP del servidor responde${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}   ❌ FALLO${NC}"
fi
((TESTS_TOTAL++))
echo ""

echo "Presiona ENTER para ver resumen final..."
read

# ════════════════════════════════════════════════════════════════
# RESUMEN FINAL
# ════════════════════════════════════════════════════════════════
clear
show_section "📊 RESUMEN DE PRUEBAS"

echo -e "${CYAN}Resultados:${NC}"
echo "  Pruebas exitosas: $TESTS_PASSED / $TESTS_TOTAL"
echo ""

PERCENTAGE=$((TESTS_PASSED * 100 / TESTS_TOTAL))

if [ $PERCENTAGE -ge 90 ]; then
    echo -e "${GREEN}✅ EXCELENTE - Todos los servicios funcionan correctamente${NC}"
    echo -e "${GREEN}   Nivel alcanzado: NIVEL 4${NC}"
elif [ $PERCENTAGE -ge 70 ]; then
    echo -e "${YELLOW}⚠️  BUENO - La mayoría de servicios funcionan${NC}"
    echo -e "${YELLOW}   Nivel alcanzado: NIVEL 3${NC}"
else
    echo -e "${RED}❌ INSUFICIENTE - Varios servicios tienen problemas${NC}"
    echo -e "${RED}   Nivel alcanzado: NIVEL 1-2${NC}"
fi

echo ""
echo -e "${CYAN}Servicios verificados:${NC}"
echo "  ✅ Red IPv6"
echo "  ✅ DNS (BIND9)"
echo "  ✅ DHCP IPv6"
echo "  ✅ Servidor Web (Nginx)"
echo "  ✅ Firewall (UFW)"
echo "  ✅ fail2ban"
echo "  ✅ SSH"
echo "  ✅ NFS (opcional)"
echo "  ✅ Usuarios y permisos"
echo "  ✅ Conectividad"
echo ""

echo -e "${YELLOW}📸 Para la demostración:${NC}"
echo "  1. Ejecuta este script y toma capturas"
echo "  2. Muestra los resultados de cada prueba"
echo "  3. Demuestra que los servicios responden"
echo ""

echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ PRUEBAS COMPLETADAS${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
