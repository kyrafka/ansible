#!/bin/bash
# Script para agregar web.gamecenter.lan a zona DINÁMICA
# Ejecutar: sudo bash scripts/fix/add-web-dynamic.sh

if [ "$EUID" -ne 0 ]; then 
    echo "❌ Ejecuta como root: sudo bash $0"
    exit 1
fi

echo "════════════════════════════════════════════════════════"
echo "🌐 Agregando web.gamecenter.lan (zona dinámica)"
echo "════════════════════════════════════════════════════════"
echo ""

# Detectar dominio e IP
DOMAIN="gamecenter.lan"
SERVER_IP="2025:db8:10::2"

echo "Dominio: $DOMAIN"
echo "IP: $SERVER_IP"
echo ""

# Verificar si existe la clave DDNS
if [ ! -f "/etc/bind/dhcp-key.key" ]; then
    echo "❌ No existe /etc/bind/dhcp-key.key"
    echo "   Ejecuta primero: bash scripts/run/run-dns.sh"
    exit 1
fi

echo "1️⃣  Usando nsupdate para agregar registro web..."
echo ""

# Crear archivo temporal con comandos nsupdate
cat > /tmp/nsupdate-web.txt << EOF
server localhost
zone $DOMAIN
update delete web.$DOMAIN AAAA
update add web.$DOMAIN 86400 AAAA $SERVER_IP
send
EOF

# Ejecutar nsupdate con la clave DDNS
nsupdate -k /etc/bind/dhcp-key.key /tmp/nsupdate-web.txt

if [ $? -eq 0 ]; then
    echo "✅ Registro agregado con nsupdate"
else
    echo "❌ Error al agregar registro"
    echo ""
    echo "Intentando sin clave..."
    
    # Intentar sin clave
    cat > /tmp/nsupdate-web-nokey.txt << EOF
server localhost
zone $DOMAIN
update delete web.$DOMAIN AAAA
update add web.$DOMAIN 86400 AAAA $SERVER_IP
send
EOF
    
    nsupdate /tmp/nsupdate-web-nokey.txt
    
    if [ $? -eq 0 ]; then
        echo "✅ Registro agregado sin clave"
    else
        echo "❌ Falló completamente"
        rm -f /tmp/nsupdate-*.txt
        exit 1
    fi
fi

# Limpiar archivos temporales
rm -f /tmp/nsupdate-*.txt

echo ""
echo "2️⃣  Esperando propagación..."
sleep 3

echo ""
echo "3️⃣  Probando resolución..."
RESULT=$(dig @localhost web.$DOMAIN AAAA +short)

if [ -n "$RESULT" ]; then
    echo "✅ DNS resuelve web.$DOMAIN → $RESULT"
else
    echo "❌ DNS NO resuelve web.$DOMAIN"
    echo ""
    echo "Verificando zona:"
    rndc dumpdb -zones
    sleep 1
    grep "web" /var/cache/bind/named_dump.db 2>/dev/null || echo "No encontrado en dump"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ Proceso completado"
echo "════════════════════════════════════════════════════════"
echo ""
echo "🧪 Pruebas:"
echo "   dig @localhost web.$DOMAIN AAAA"
echo "   ping6 web.$DOMAIN"
echo ""
