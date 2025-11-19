#!/bin/bash
# Script para agregar subdominio web.gamecenter.lan
# Ejecutar: sudo bash scripts/fix/add-web-subdomain.sh

echo "════════════════════════════════════════════════════════"
echo "🌐 Agregando subdominio web.gamecenter.lan"
echo "════════════════════════════════════════════════════════"
echo ""

# Verificar si somos root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script debe ejecutarse como root"
    echo "   Usa: sudo bash $0"
    exit 1
fi

# Detectar dominio
DOMAIN=$(grep -r "domain_name:" group_vars/all.yml 2>/dev/null | grep -v "^#" | awk '{print $2}' | tr -d '"' | head -n1)
if [ -z "$DOMAIN" ]; then
    DOMAIN="gamecenter.lan"
fi

echo "📋 Dominio detectado: $DOMAIN"
echo ""

# Detectar IPv6 del servidor
SERVER_IPV6=$(ip -6 addr show ens34 2>/dev/null | grep "inet6.*2025:db8:10" | awk '{print $2}' | cut -d'/' -f1 | head -1)

if [ -z "$SERVER_IPV6" ]; then
    echo "⚠️  No se detectó IPv6 en ens34, usando valor por defecto"
    SERVER_IPV6="2025:db8:10::2"
fi

echo "📍 IPv6 del servidor: $SERVER_IPV6"
echo ""

# Buscar archivo de zona
ZONE_FILE=""
if [ -f "/var/lib/bind/db.$DOMAIN" ]; then
    ZONE_FILE="/var/lib/bind/db.$DOMAIN"
elif [ -f "/etc/bind/zones/db.$DOMAIN" ]; then
    ZONE_FILE="/etc/bind/zones/db.$DOMAIN"
else
    echo "❌ No se encontró archivo de zona para $DOMAIN"
    echo "   Ejecuta primero: bash scripts/run/run-dns.sh"
    exit 1
fi

echo "📁 Archivo de zona: $ZONE_FILE"
echo ""

# Verificar si ya existe el subdominio web
if grep -q "^web" "$ZONE_FILE"; then
    echo "✅ Subdominio 'web' ya existe en la zona"
    echo ""
    grep "^web" "$ZONE_FILE"
    echo ""
    echo "Si quieres actualizarlo, edita manualmente:"
    echo "   sudo nano $ZONE_FILE"
    exit 0
fi

echo "1️⃣  Agregando subdominio 'web' a la zona..."
echo ""

# Hacer backup
cp "$ZONE_FILE" "${ZONE_FILE}.backup-$(date +%Y%m%d-%H%M%S)"

# Agregar registro web (antes de la línea en blanco final)
# Buscar la última línea con contenido y agregar después
sed -i "/^$/i web\t\tIN\tAAAA\t$SERVER_IPV6" "$ZONE_FILE"

# Si no funcionó con sed, agregar al final
if ! grep -q "^web" "$ZONE_FILE"; then
    echo "web		IN	AAAA	$SERVER_IPV6" >> "$ZONE_FILE"
fi

echo "✅ Subdominio agregado"
echo ""

echo "2️⃣  Incrementando serial de la zona..."
# Incrementar serial (formato: YYYYMMDDNN)
CURRENT_SERIAL=$(grep -oP '(?<=\s)\d{10}(?=\s*;\s*Serial)' "$ZONE_FILE")
if [ -n "$CURRENT_SERIAL" ]; then
    NEW_SERIAL=$((CURRENT_SERIAL + 1))
    sed -i "s/$CURRENT_SERIAL/$NEW_SERIAL/g" "$ZONE_FILE"
    echo "✅ Serial actualizado: $CURRENT_SERIAL → $NEW_SERIAL"
else
    echo "⚠️  No se pudo actualizar serial automáticamente"
fi
echo ""

echo "3️⃣  Verificando sintaxis de la zona..."
if named-checkzone "$DOMAIN" "$ZONE_FILE" &>/dev/null; then
    echo "✅ Zona válida"
else
    echo "❌ Error en la zona:"
    named-checkzone "$DOMAIN" "$ZONE_FILE"
    echo ""
    echo "Restaurando backup..."
    mv "${ZONE_FILE}.backup-"* "$ZONE_FILE"
    exit 1
fi
echo ""

echo "4️⃣  Recargando zona en BIND9..."
rndc reload "$DOMAIN"
sleep 2
echo "✅ Zona recargada"
echo ""

echo "5️⃣  Probando resolución de web.$DOMAIN..."
RESULT=$(dig @localhost "web.$DOMAIN" AAAA +short)

if [ -n "$RESULT" ]; then
    echo "✅ DNS resuelve web.$DOMAIN → $RESULT"
else
    echo "❌ DNS NO resuelve web.$DOMAIN"
    echo ""
    echo "Intentando recargar de nuevo..."
    rndc reload
    sleep 3
    RESULT=$(dig @localhost "web.$DOMAIN" AAAA +short)
    if [ -n "$RESULT" ]; then
        echo "✅ Ahora sí resuelve: $RESULT"
    else
        echo "❌ Aún no resuelve. Ver logs:"
        journalctl -u bind9 -n 20 --no-pager
        exit 1
    fi
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ Subdominio web.$DOMAIN configurado"
echo "════════════════════════════════════════════════════════"
echo ""
echo "📋 Contenido de la zona:"
cat "$ZONE_FILE"
echo ""
echo "🧪 Pruebas:"
echo "   dig @localhost web.$DOMAIN AAAA"
echo "   ping6 web.$DOMAIN"
echo ""
