#!/bin/bash

echo "════════════════════════════════════════════════════════════════"
echo "🌐 PRUEBA COMPLETA DE CONECTIVIDAD ENTRE SISTEMAS OPERATIVOS"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "📋 Esta prueba valida la conectividad para la rúbrica de SO"
echo ""

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para verificar resultado
check_result() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ ÉXITO${NC}"
    else
        echo -e "${RED}❌ FALLO${NC}"
    fi
}

# Variables
SERVER_IP="2025:db8:10::2"
DOMAIN="gamecenter.lan"

echo "════════════════════════════════════════════════════════════════"
echo "1️⃣  PRUEBA DE CONECTIVIDAD IPv6"
echo "════════════════════════════════════════════════════════════════"
echo ""

echo "🔹 Mostrando IP local asignada por DHCP:"
ip -6 addr show | grep "inet6 2025" | grep -v "fe80"
echo ""

echo "🔹 Ping al servidor ($SERVER_IP):"
ping6 -c 4 $SERVER_IP
check_result
echo ""

echo "════════════════════════════════════════════════════════════════"
echo "2️⃣  PRUEBA DE RESOLUCIÓN DNS"
echo "════════════════════════════════════════════════════════════════"
echo ""

echo "🔹 Resolución de $DOMAIN:"
dig @$SERVER_IP $DOMAIN AAAA +short
check_result
echo ""

echo "🔹 Resolución inversa del servidor:"
dig @$SERVER_IP -x $SERVER_IP +short
check_result
echo ""

echo "🔹 Verificar todos los registros DNS:"
dig @$SERVER_IP $DOMAIN ANY +noall +answer
echo ""

echo "════════════════════════════════════════════════════════════════"
echo "3️⃣  PRUEBA DE ACCESO HTTP"
echo "════════════════════════════════════════════════════════════════"
echo ""

echo "🔹 Acceso HTTP al servidor web:"
curl -6 http://$DOMAIN -I 2>/dev/null | head -5
check_result
echo ""

echo "🔹 Contenido de la página:"
curl -6 http://$DOMAIN 2>/dev/null | grep -i "gamecenter\|bienvenido" | head -3
echo ""

echo "════════════════════════════════════════════════════════════════"
echo "4️⃣  PRUEBA DE PUERTOS Y SERVICIOS"
echo "════════════════════════════════════════════════════════════════"
echo ""

echo "🔹 Escaneando puertos principales del servidor:"
if command -v nmap &> /dev/null; then
    nmap -6 $SERVER_IP -p 22,53,80 2>/dev/null
else
    echo "⚠️  nmap no instalado, usando nc..."
    for port in 22 53 80; do
        nc -6 -zv $SERVER_IP $port 2>&1 | grep -E "succeeded|open"
    done
fi
echo ""

echo "════════════════════════════════════════════════════════════════"
echo "5️⃣  PRUEBA DE ACCESO SSH (Solo para rol Admin)"
echo "════════════════════════════════════════════════════════════════"
echo ""

echo "🔹 Verificando si puedes hacer SSH:"
echo "   Intentando conexión SSH..."

# Verificar si el usuario actual puede SSH
CURRENT_USER=$(whoami)
if [ "$CURRENT_USER" = "administrador" ]; then
    echo "   Usuario: $CURRENT_USER (Admin) - Debería tener acceso"
    ssh -6 -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@$SERVER_IP "echo '✅ SSH funcional' && hostname" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ SSH PERMITIDO (correcto para Admin)${NC}"
    else
        echo -e "${YELLOW}⚠️  SSH falló (verifica credenciales)${NC}"
    fi
elif [ "$CURRENT_USER" = "auditor" ] || [ "$CURRENT_USER" = "gamer01" ]; then
    echo "   Usuario: $CURRENT_USER - NO debería tener acceso SSH"
    ssh -6 -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@$SERVER_IP "hostname" 2>/dev/null
    if [ $? -ne 0 ]; then
        echo -e "${GREEN}✅ SSH BLOQUEADO (correcto para $CURRENT_USER)${NC}"
    else
        echo -e "${RED}❌ SSH PERMITIDO (ERROR: debería estar bloqueado)${NC}"
    fi
else
    echo "   Usuario: $CURRENT_USER - Verificando acceso..."
    ssh -6 -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@$SERVER_IP "hostname" 2>/dev/null
    check_result
fi
echo ""

echo "════════════════════════════════════════════════════════════════"
echo "6️⃣  INFORMACIÓN DE RED LOCAL"
echo "════════════════════════════════════════════════════════════════"
echo ""

echo "🔹 Tabla de rutas IPv6:"
ip -6 route show | grep -v "fe80"
echo ""

echo "🔹 Gateway configurado:"
ip -6 route show default
echo ""

echo "🔹 Servidor DNS configurado:"
cat /etc/resolv.conf | grep nameserver
echo ""

echo "════════════════════════════════════════════════════════════════"
echo "📊 RESUMEN DE CONECTIVIDAD"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Resumen
TESTS_PASSED=0
TESTS_TOTAL=5

# Test 1: Ping
ping6 -c 1 $SERVER_IP &>/dev/null && ((TESTS_PASSED++))

# Test 2: DNS
dig @$SERVER_IP $DOMAIN AAAA +short &>/dev/null && ((TESTS_PASSED++))

# Test 3: HTTP
curl -6 -s http://$DOMAIN &>/dev/null && ((TESTS_PASSED++))

# Test 4: Puerto 53
nc -6 -zv $SERVER_IP 53 &>/dev/null && ((TESTS_PASSED++))

# Test 5: Puerto 80
nc -6 -zv $SERVER_IP 80 &>/dev/null && ((TESTS_PASSED++))

echo "Pruebas exitosas: $TESTS_PASSED/$TESTS_TOTAL"
echo ""

if [ $TESTS_PASSED -eq $TESTS_TOTAL ]; then
    echo -e "${GREEN}✅ CONECTIVIDAD COMPLETA - NIVEL 4 ALCANZADO${NC}"
    echo "   Todos los servicios funcionan correctamente"
elif [ $TESTS_PASSED -ge 3 ]; then
    echo -e "${YELLOW}⚠️  CONECTIVIDAD PARCIAL - NIVEL 3${NC}"
    echo "   Algunos servicios tienen problemas"
else
    echo -e "${RED}❌ CONECTIVIDAD INSUFICIENTE - NIVEL 1-2${NC}"
    echo "   Revisar configuración de red y servicios"
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "📸 COMANDOS PARA CAPTURAS DE PANTALLA"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Para la rúbrica, ejecuta estos comandos y toma capturas:"
echo ""
echo "1. Mostrar IP:"
echo "   ip -6 addr show | grep 2025"
echo ""
echo "2. Ping al servidor:"
echo "   ping6 -c 4 $SERVER_IP"
echo ""
echo "3. Resolución DNS:"
echo "   dig @$SERVER_IP $DOMAIN AAAA"
echo ""
echo "4. Acceso web:"
echo "   curl http://$DOMAIN"
echo ""
echo "5. SSH (solo admin):"
echo "   ssh ubuntu@$SERVER_IP"
echo ""
echo "════════════════════════════════════════════════════════════════"
