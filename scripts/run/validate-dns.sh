#!/bin/bash
# Script para validar el servidor DNS (BIND9)
# Ejecutar: bash scripts/run/validate-dns.sh

echo "════════════════════════════════════════════════════════"
echo "🔍 Validando Servidor DNS (BIND9)"
echo "════════════════════════════════════════════════════════"
echo ""

ERRORS=0

# Verificar servicio
echo "🔧 Servicio BIND9:"
if systemctl is-active --quiet named; then
    echo "✅ named está activo"
else
    echo "❌ named NO está activo"
    ((ERRORS++))
fi

if systemctl is-enabled --quiet named; then
    echo "✅ named habilitado al inicio"
else
    echo "❌ named NO habilitado al inicio"
    ((ERRORS++))
fi

echo ""
echo "🌐 Puerto DNS:"
if ss -tulpn | grep -q ":53.*named"; then
    echo "✅ BIND9 escuchando en puerto 53"
else
    echo "❌ BIND9 NO escuchando en puerto 53"
    ((ERRORS++))
fi

echo ""
echo "📝 Archivos de configuración:"
if [ -f "/etc/bind/named.conf.local" ]; then
    echo "✅ named.conf.local existe"
else
    echo "❌ named.conf.local NO existe"
    ((ERRORS++))
fi

if [ -f "/etc/bind/zones/db.gamecenter.local" ]; then
    echo "✅ Zona gamecenter.local existe"
else
    echo "❌ Zona gamecenter.local NO existe"
    ((ERRORS++))
fi

echo ""
echo "📋 Verificando archivos de zona:"

# Verificar que el directorio de zonas existe
if [ ! -d "/etc/bind/zones" ]; then
    echo "❌ Directorio /etc/bind/zones NO existe"
    echo "   💡 Solución: El playbook de DNS debe crear este directorio"
    ((ERRORS++))
else
    echo "✅ Directorio /etc/bind/zones existe"
fi

# Verificar que el archivo de zona existe
if [ ! -f "/etc/bind/zones/db.gamecenter.local" ]; then
    echo "❌ Archivo /etc/bind/zones/db.gamecenter.local NO existe"
    echo "   💡 Solución: Ejecuta 'bash scripts/run/run-dns.sh' para crear el archivo"
    echo "   💡 O verifica que el template 'roles/dns_bind/templates/db.domain.j2' existe"
    ((ERRORS++))
else
    echo "✅ Archivo db.gamecenter.local existe"
    
    # Verificar contenido del archivo
    if sudo grep -q "@ *IN *AAAA *2025:db8:10::2" /etc/bind/zones/db.gamecenter.local; then
        echo "✅ Registro raíz (@) configurado correctamente"
    else
        echo "❌ Falta registro raíz (@) en la zona"
        echo "   💡 Debería tener: @  IN  AAAA  2025:db8:10::2"
        echo "   💡 Verifica el template: roles/dns_bind/templates/db.domain.j2"
        ((ERRORS++))
    fi
    
    # Verificar que tiene registros AAAA
    if sudo grep -q "IN *AAAA" /etc/bind/zones/db.gamecenter.local; then
        AAAA_COUNT=$(sudo grep -c "IN *AAAA" /etc/bind/zones/db.gamecenter.local)
        echo "✅ Archivo tiene $AAAA_COUNT registros AAAA"
    else
        echo "❌ No hay registros AAAA en el archivo"
        echo "   💡 El archivo debe tener al menos un registro AAAA"
        ((ERRORS++))
    fi
fi

echo ""
echo "🧪 Prueba de resolución:"
echo "→ Probando gamecenter.local..."
RESULT=$(dig @localhost gamecenter.local AAAA +short)
if echo "$RESULT" | grep -q "2025:db8:10::2"; then
    echo "✅ DNS resuelve gamecenter.local → $RESULT"
else
    echo "❌ DNS NO resuelve gamecenter.local"
    echo "   Resultado: $RESULT"
    ((ERRORS++))
fi

echo "→ Probando servidor.gamecenter.local..."
RESULT=$(dig @localhost servidor.gamecenter.local AAAA +short)
if echo "$RESULT" | grep -q "2025:db8:10::2"; then
    echo "✅ DNS resuelve servidor.gamecenter.local → $RESULT"
else
    echo "❌ DNS NO resuelve servidor.gamecenter.local"
    ((ERRORS++))
fi

echo "→ Probando www.gamecenter.local..."
RESULT=$(dig @localhost www.gamecenter.local AAAA +short)
if echo "$RESULT" | grep -q "2025:db8:10::2"; then
    echo "✅ DNS resuelve www.gamecenter.local → $RESULT"
else
    echo "❌ DNS NO resuelve www.gamecenter.local"
    ((ERRORS++))
fi

echo ""
echo "════════════════════════════════════════════════════════"
if [ $ERRORS -eq 0 ]; then
    echo "✅ DNS CONFIGURADO CORRECTAMENTE"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "📊 Dominios disponibles:"
    echo "   → gamecenter.local"
    echo "   → servidor.gamecenter.local"
    echo "   → www.gamecenter.local"
    echo "   → web.gamecenter.local"
    echo ""
    echo "🔧 Comandos útiles:"
    echo "   → Probar DNS: dig @localhost gamecenter.local AAAA"
    echo "   → Ver logs: sudo journalctl -u named -n 50"
    echo "   → Recargar zona: sudo rndc reload"
    echo ""
    exit 0
else
    echo "❌ ENCONTRADOS $ERRORS PROBLEMAS"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "📋 RESUMEN DE PROBLEMAS:"
    echo ""
    
    # Listar problemas específicos
    if [ ! -d "/etc/bind/zones" ]; then
        echo "   1. Falta directorio /etc/bind/zones"
    fi
    
    if [ ! -f "/etc/bind/zones/db.gamecenter.local" ]; then
        echo "   2. Falta archivo de zona db.gamecenter.local"
    fi
    
    if ! systemctl is-active --quiet named; then
        echo "   3. Servicio named no está activo"
    fi
    
    echo ""
    echo "💡 SOLUCIONES:"
    echo ""
    echo "   Paso 1: Ejecutar playbook de DNS"
    echo "   → bash scripts/run/run-dns.sh"
    echo ""
    echo "   Paso 2: Verificar que el rol dns_bind existe"
    echo "   → ls -la roles/dns_bind/"
    echo ""
    echo "   Paso 3: Verificar templates"
    echo "   → ls -la roles/dns_bind/templates/"
    echo ""
    echo "   Paso 4: Ver logs de Ansible"
    echo "   → ansible-playbook site.yml --tags dns -vv"
    echo ""
    exit 1
fi
