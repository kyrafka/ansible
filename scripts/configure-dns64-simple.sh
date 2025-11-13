#!/bin/bash
# Script simple para configurar DNS64 en BIND9

# Auto-permisos
[ ! -x "$0" ] && chmod +x "$0" 2>/dev/null

echo "════════════════════════════════════════"
echo "🌐 Configurando DNS64 en BIND9"
echo "════════════════════════════════════════"
echo ""

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script debe ejecutarse como root"
    echo "   Usa: sudo bash $0"
    exit 1
fi

echo "1️⃣  Verificando configuración actual de BIND9..."
if ! grep -q "dns64 64:ff9b::/96" /etc/bind/named.conf.options; then
    echo "   → DNS64 no está configurado, agregando..."
    
    # Hacer backup
    cp /etc/bind/named.conf.options /etc/bind/named.conf.options.backup
    
    # Agregar DNS64 después de la línea "listen-on { any; };"
    sed -i '/listen-on { any; };/a\    \n    // DNS64: Traduce respuestas IPv4 a IPv6 usando prefijo NAT64\n    dns64 64:ff9b::/96 {\n        clients { any; };\n        mapped { !2025:db8:10::/64; any; };\n        exclude { 64:ff9b::/96; ::ffff:0:0/96; };\n        recursive-only yes;\n    };' /etc/bind/named.conf.options
    
    echo "   ✓ DNS64 agregado a la configuración"
else
    echo "   ✓ DNS64 ya está configurado"
fi

echo ""
echo "2️⃣  Verificando sintaxis de BIND9..."
if named-checkconf; then
    echo "   ✓ Configuración correcta"
else
    echo "   ❌ Error en la configuración"
    echo "   Restaurando backup..."
    cp /etc/bind/named.conf.options.backup /etc/bind/named.conf.options
    exit 1
fi

echo ""
echo "3️⃣  Reiniciando BIND9..."
systemctl restart named

if systemctl is-active --quiet named; then
    echo "   ✓ BIND9 reiniciado correctamente"
else
    echo "   ❌ Error al reiniciar BIND9"
    echo "   Ver logs: journalctl -xeu named"
    exit 1
fi

echo ""
echo "4️⃣  Verificando DNS64..."
sleep 2
RESULT=$(dig @localhost ipv4.google.com AAAA +short | head -1)

if [[ $RESULT == 64:ff9b::* ]]; then
    echo "   ✓ DNS64 funcionando correctamente"
    echo "   → Respuesta: $RESULT"
else
    echo "   ⚠️  DNS64 podría no estar funcionando"
    echo "   → Respuesta: $RESULT"
    echo "   (Nota: Algunos sitios tienen IPv6 nativo y no necesitan DNS64)"
fi

echo ""
echo "════════════════════════════════════════"
echo "✅ Configuración completada"
echo "════════════════════════════════════════"
echo ""
echo "🧪 Pruebas desde tu VM Ubuntu Desktop:"
echo ""
echo "1. Verificar DNS64:"
echo "   dig google.com AAAA"
echo ""
echo "2. Hacer ping:"
echo "   ping6 google.com"
echo ""
echo "3. Probar navegación:"
echo "   curl -6 http://google.com"
echo ""
echo "════════════════════════════════════════"
