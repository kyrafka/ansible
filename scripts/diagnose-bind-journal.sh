#!/bin/bash
# Diagnóstico profundo de BIND9 y journals

echo "════════════════════════════════════════════════════════"
echo "🔬 Diagnóstico profundo de BIND9 + Journals"
echo "════════════════════════════════════════════════════════"
echo ""

ZONE="gamecenter.lan"
ZONE_FILE="/var/lib/bind/db.$ZONE"
JOURNAL_FILE="/var/lib/bind/db.$ZONE.jnl"

# 1. Verificar archivos
echo "1️⃣  Archivos de zona:"
echo "────────────────────────────────────────────────────────"
if [ -f "$ZONE_FILE" ]; then
    echo "✅ Zona existe: $ZONE_FILE"
    ls -lh "$ZONE_FILE"
    echo "   Última modificación: $(stat -c %y "$ZONE_FILE")"
else
    echo "❌ Zona NO existe"
fi

echo ""
if [ -f "$JOURNAL_FILE" ]; then
    echo "✅ Journal existe: $JOURNAL_FILE"
    ls -lh "$JOURNAL_FILE"
    echo "   Última modificación: $(stat -c %y "$JOURNAL_FILE")"
    echo "   Tamaño: $(stat -c %s "$JOURNAL_FILE") bytes"
else
    echo "⚠️  Journal NO existe (puede ser normal si no hay cambios)"
fi

# 2. Leer contenido del journal
echo ""
echo "2️⃣  Contenido del journal:"
echo "────────────────────────────────────────────────────────"
if [ -f "$JOURNAL_FILE" ]; then
    echo "Intentando leer journal..."
    sudo named-journalprint "$JOURNAL_FILE" 2>&1 | head -n 50
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        echo ""
        echo "✅ Journal legible"
        RECORDS=$(sudo named-journalprint "$JOURNAL_FILE" 2>/dev/null | grep -c "add")
        echo "   Registros agregados: $RECORDS"
    else
        echo "❌ Journal corrupto o ilegible"
    fi
else
    echo "⚠️  No hay journal para leer"
fi

# 3. Verificar configuración de BIND
echo ""
echo "3️⃣  Configuración de zona en named.conf.local:"
echo "────────────────────────────────────────────────────────"
sudo grep -A 10 "zone \"$ZONE\"" /etc/bind/named.conf.local

# 4. Verificar que BIND tiene la zona cargada
echo ""
echo "4️⃣  Estado de la zona en BIND:"
echo "────────────────────────────────────────────────────────"
sudo rndc status | grep -i "zone"
echo ""
sudo rndc zonestatus "$ZONE" 2>&1

# 5. Verificar permisos
echo ""
echo "5️⃣  Permisos del directorio:"
echo "────────────────────────────────────────────────────────"
ls -ld /var/lib/bind/
echo ""
echo "Archivos en /var/lib/bind/:"
ls -lh /var/lib/bind/ | grep "$ZONE"

# 6. Verificar proceso de BIND
echo ""
echo "6️⃣  Proceso de BIND:"
echo "────────────────────────────────────────────────────────"
ps aux | grep named | grep -v grep
echo ""
echo "Archivos abiertos por BIND:"
sudo lsof -p $(pgrep named) | grep "$ZONE" || echo "   (ninguno relacionado con $ZONE)"

# 7. Probar actualización y lectura
echo ""
echo "7️⃣  Prueba de actualización + lectura:"
echo "────────────────────────────────────────────────────────"
TEST_HOST="diagnose-$(date +%s)"
TEST_IP="2025:db8:10::9999"

echo "→ Agregando registro: $TEST_HOST.$ZONE → $TEST_IP"
nsupdate -k /etc/bind/dhcp-key.key <<EOF
server 127.0.0.1
zone $ZONE
update add $TEST_HOST.$ZONE 60 AAAA $TEST_IP
send
EOF

if [ $? -eq 0 ]; then
    echo "✅ nsupdate exitoso"
    
    # Esperar
    sleep 2
    
    # Verificar en journal
    echo ""
    echo "→ Verificando en journal..."
    if [ -f "$JOURNAL_FILE" ]; then
        if sudo named-journalprint "$JOURNAL_FILE" 2>/dev/null | grep -q "$TEST_HOST"; then
            echo "✅ Registro está en el journal"
        else
            echo "❌ Registro NO está en el journal"
        fi
    fi
    
    # Verificar en DNS
    echo ""
    echo "→ Consultando DNS..."
    RESULT=$(dig @127.0.0.1 "$TEST_HOST.$ZONE" AAAA +short)
    if [ "$RESULT" == "$TEST_IP" ]; then
        echo "✅ DNS devuelve el registro correctamente"
        echo "   Resultado: $RESULT"
    else
        echo "❌ DNS NO devuelve el registro"
        echo "   Esperado: $TEST_IP"
        echo "   Obtenido: $RESULT"
        
        # Diagnóstico adicional
        echo ""
        echo "→ Consulta detallada:"
        dig @127.0.0.1 "$TEST_HOST.$ZONE" AAAA
    fi
    
    # Limpiar
    nsupdate -k /etc/bind/dhcp-key.key <<EOF > /dev/null 2>&1
server 127.0.0.1
zone $ZONE
update delete $TEST_HOST.$ZONE AAAA
send
EOF
else
    echo "❌ nsupdate falló"
fi

# 8. Logs recientes
echo ""
echo "8️⃣  Logs recientes de BIND:"
echo "────────────────────────────────────────────────────────"
sudo journalctl -u named -n 20 --no-pager | grep -E "update|journal|zone|error"

echo ""
echo "════════════════════════════════════════════════════════"
echo "💡 Diagnóstico completado"
echo "════════════════════════════════════════════════════════"
