#!/bin/bash
# Script para mostrar el contenido de la zona DNS generada

DOMAIN=$(grep -r "domain_name:" group_vars/all.yml | grep -v "^#" | awk '{print $2}' | tr -d '"' | head -n1)
ZONE_FILE="/etc/bind/zones/db.${DOMAIN}"

echo "🔍 Mostrando zona DNS: $DOMAIN"
echo "📁 Archivo: $ZONE_FILE"
echo "════════════════════════════════════════════════════════"
echo ""

if [ -f "$ZONE_FILE" ]; then
    sudo cat "$ZONE_FILE"
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "✅ Archivo existe"
    
    # Verificar sintaxis
    echo ""
    echo "🔍 Verificando sintaxis..."
    if sudo named-checkzone "$DOMAIN" "$ZONE_FILE"; then
        echo "✅ Sintaxis correcta"
    else
        echo "❌ Errores de sintaxis encontrados"
    fi
else
    echo "❌ Archivo no existe: $ZONE_FILE"
    echo ""
    echo "📂 Archivos disponibles en /etc/bind/zones/:"
    ls -la /etc/bind/zones/ 2>/dev/null || echo "   Directorio no existe"
fi
