#!/usr/bin/env bash
# BIND DDNS Diagnostic Script

ZONE="gamecenter.lan"
ZONE_FILE="/var/lib/bind/db.${ZONE}"
JNLS_FILE="${ZONE_FILE}.jnl"
LOG_FILE="/tmp/bind-diagnose.log"

echo "🔍 Diagnóstico de BIND/DDNS iniciado para zona: $ZONE"
echo "=============================================" | tee $LOG_FILE

# 1️⃣ Estado del servicio BIND
echo -e "\n🟦 Verificando servicio BIND..."
if systemctl is-active --quiet named; then
    echo "✅ BIND está corriendo."
else
    echo "❌ BIND no está activo. Actívalo con: sudo systemctl start named"
    exit 1
fi

# 2️⃣ Verificar que el archivo de zona existe
echo -e "\n🟦 Verificando archivo de zona..."
if [ -f "$ZONE_FILE" ]; then
    echo "✅ Archivo de zona encontrado: $ZONE_FILE"
else
    echo "❌ No existe el archivo de zona: $ZONE_FILE"
    exit 1
fi

# 3️⃣ Verificar permisos
echo -e "\n🟦 Verificando permisos sobre la carpeta y archivo..."
ls -ld /var/lib/bind | tee -a $LOG_FILE
ls -l $ZONE_FILE* 2>/dev/null | tee -a $LOG_FILE
USER=$(stat -c "%U" "$ZONE_FILE")
if [ "$USER" != "bind" ]; then
    echo "⚠️ El archivo no pertenece al usuario 'bind'."
    echo "   -> Solución: sudo chown bind:bind /var/lib/bind/db.*"
else
    echo "✅ Permisos correctos para el usuario 'bind'."
fi

# 4️⃣ Validar sintaxis del archivo de zona
echo -e "\n🟦 Comprobando sintaxis de la zona..."
named-checkzone "$ZONE" "$ZONE_FILE" | tee -a $LOG_FILE
if [ $? -ne 0 ]; then
    echo "❌ El archivo de zona tiene errores de sintaxis."
    exit 1
fi

# 5️⃣ Revisar estado dinámico de la zona
echo -e "\n🟦 Verificando si la zona es dinámica..."
rndc zonestatus $ZONE | grep dynamic | tee -a $LOG_FILE
if rndc zonestatus $ZONE | grep -q "dynamic: yes"; then
    echo "✅ Zona cargada como dinámica."
else
    echo "❌ Zona NO es dinámica. Ejecuta: sudo rndc thaw $ZONE"
fi

# 6️⃣ Revisar logs recientes
echo -e "\n🟦 Revisando logs de BIND (últimos 20 segundos)..."
sudo journalctl -u named --since "20 seconds ago" | grep -E "update|journal|error" | tee -a $LOG_FILE

# 7️⃣ Intentar un update de prueba
echo -e "\n🟦 Probando una actualización de prueba (AAAA test)..."
nsupdate -v <<EOF
server 127.0.0.1
zone $ZONE
update add test.$ZONE. 30 AAAA 2001:db8::beef
send
EOF
sleep 1

# 8️⃣ Revisar si se creó o modificó el journal
echo -e "\n🟦 Verificando archivo .jnl..."
if [ -f "$JNLS_FILE" ]; then
    echo "✅ Journal encontrado: $JNLS_FILE"
    ls -lh "$JNLS_FILE"
    echo "🧾 Contenido (head):"
    sudo named-journalprint "$JNLS_FILE" | head -n 15
else
    echo "❌ No se creó el archivo journal. Probablemente fallo de permisos o zona congelada."
fi

# 9️⃣ Probar resolución del registro test
echo -e "\n🟦 Consultando test.$ZONE..."
dig @127.0.0.1 test.$ZONE AAAA +short

echo -e "\n✅ Diagnóstico finalizado. Revisa detalles en: $LOG_FILE"
echo "============================================="
