#!/bin/bash
# Script para probar y diagnosticar DDNS

echo "════════════════════════════════════════════════════════"
echo "🧪 Diagnóstico completo de DDNS"
echo "════════════════════════════════════════════════════════"
echo ""

ERRORS=0

# 1. Verificar BIND
echo "1️⃣  Verificando BIND9..."
if systemctl is-active --quiet bind9; then
    echo "   ✅ BIND9 está corriendo"
else
    echo "   ❌ BIND9 NO está corriendo"
    ((ERRORS++))
fi

# 2. Verificar clave DDNS
echo ""
echo "2️⃣  Verificando clave DDNS..."
if [ -f /etc/bind/dhcp-key.key ]; then
    echo "   ✅ Clave existe: /etc/bind/dhcp-key.key"
    KEY_NAME=$(grep "key " /etc/bind/dhcp-key.key | awk '{print $2}' | tr -d '";')
    echo "   → Nombre: $KEY_NAME"
else
    echo "   ❌ Clave NO existe"
    ((ERRORS++))
fi

# 3. Verificar permisos de /var/lib/bind
echo ""
echo "3️⃣  Verificando permisos..."
if [ -d /var/lib/bind ]; then
    PERMS=$(stat -c "%a %U:%G" /var/lib/bind)
    echo "   ✅ /var/lib/bind existe"
    echo "   → Permisos: $PERMS"
    
    if [ ! -w /var/lib/bind ]; then
        echo "   ⚠️  BIND puede no tener permisos de escritura"
    fi
else
    echo "   ❌ /var/lib/bind NO existe"
    ((ERRORS++))
fi

# 4. Verificar archivos de zona
echo ""
echo "4️⃣  Verificando archivos de zona..."
if [ -f /var/lib/bind/db.gamecenter.lan ]; then
    echo "   ✅ Zona existe: db.gamecenter.lan"
    if [ -f /var/lib/bind/db.gamecenter.lan.jnl ]; then
        echo "   ✅ Journal existe (zona dinámica activa)"
    else
        echo "   ⚠️  Journal NO existe (puede ser normal)"
    fi
else
    echo "   ❌ Zona NO existe"
    ((ERRORS++))
fi

# 5. Probar actualización DNS
echo ""
echo "5️⃣  Probando actualización DNS..."
TEST_HOSTNAME="test-$(date +%s)"
TEST_IP="2025:db8:10::9999"

nsupdate -k /etc/bind/dhcp-key.key > /tmp/nsupdate-test.log 2>&1 <<EOF
server 127.0.0.1
zone gamecenter.lan
update add $TEST_HOSTNAME.gamecenter.lan 60 AAAA $TEST_IP
send
EOF

if [ $? -eq 0 ]; then
    echo "   ✅ nsupdate ejecutado sin errores"
    
    # Esperar un momento
    sleep 2
    
    # Verificar si se agregó
    RESULT=$(dig @127.0.0.1 "$TEST_HOSTNAME.gamecenter.lan" AAAA +short)
    if [ "$RESULT" == "$TEST_IP" ]; then
        echo "   ✅ Registro agregado correctamente"
        echo "   → $TEST_HOSTNAME.gamecenter.lan → $TEST_IP"
        
        # Limpiar
        nsupdate -k /etc/bind/dhcp-key.key <<EOF > /dev/null 2>&1
server 127.0.0.1
zone gamecenter.lan
update delete $TEST_HOSTNAME.gamecenter.lan AAAA
send
EOF
    else
        echo "   ❌ Registro NO aparece en DNS"
        echo "   → Esperado: $TEST_IP"
        echo "   → Obtenido: $RESULT"
        ((ERRORS++))
    fi
else
    echo "   ❌ nsupdate falló"
    cat /tmp/nsupdate-test.log
    ((ERRORS++))
fi

# 6. Verificar logs de BIND
echo ""
echo "6️⃣  Últimos logs de BIND..."
sudo journalctl -u named -n 10 --no-pager | grep -i "update\|error\|fail" || echo "   → Sin errores recientes"

# Resumen
echo ""
echo "════════════════════════════════════════════════════════"
if [ $ERRORS -eq 0 ]; then
    echo "✅ DDNS FUNCIONA CORRECTAMENTE"
    echo ""
    echo "🎉 Tu sistema está listo para registrar clientes DHCP en DNS"
    echo ""
    echo "📋 Próximos pasos:"
    echo "   1. Ejecuta: sudo bash scripts/dhcp-dns-sync.sh"
    echo "   2. Verifica: dig @127.0.0.1 <hostname>.gamecenter.lan AAAA"
else
    echo "❌ ENCONTRADOS $ERRORS PROBLEMAS"
    echo ""
    echo "💡 Soluciones:"
    echo "   1. Ejecuta: bash scripts/run/run-dns.sh"
    echo "   2. Verifica logs: sudo journalctl -u named -n 50"
    echo "   3. Ejecuta este script de nuevo"
fi
echo "════════════════════════════════════════════════════════"
