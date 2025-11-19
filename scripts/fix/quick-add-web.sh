#!/bin/bash
# Script rápido para agregar web.gamecenter.lan
# Ejecutar: sudo bash scripts/fix/quick-add-web.sh

if [ "$EUID" -ne 0 ]; then 
    echo "❌ Ejecuta como root: sudo bash $0"
    exit 1
fi

echo "🌐 Agregando web.gamecenter.lan..."

# Agregar registro web
sed -i '/^dns.*IN.*AAAA/a web\t\tIN\tAAAA\t2025:db8:10::2' /var/lib/bind/db.gamecenter.lan

# Incrementar serial
CURRENT=$(grep -oP '\d{10}(?=\s*;\s*Serial)' /var/lib/bind/db.gamecenter.lan)
NEW=$((CURRENT + 1))
sed -i "s/$CURRENT/$NEW/g" /var/lib/bind/db.gamecenter.lan

# Recargar
rndc reload gamecenter.lan

echo "✅ Listo!"
echo ""
echo "Prueba:"
dig @localhost web.gamecenter.lan AAAA +short
