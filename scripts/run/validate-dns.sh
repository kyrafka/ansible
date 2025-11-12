#!/bin/bash
# Script para validar el servidor DNS (BIND9)
# Ejecutar: bash scripts/run/validate-dns.sh

echo "════════════════════════════════════════════════════════"
echo "🔍 Validando Servidor DNS (BIND9)"
echo "════════════════════════════════════════════════════════"
echo ""

ERRORS=0

# Detectar dominio configurado automáticamente
DOMAIN=$(grep -r "domain_name:" group_vars/all.yml | grep -v "^#" | awk '{print $2}' | tr -d '"' | head -n1)
if [ -z "$DOMAIN" ]; then
    DOMAIN="gamecenter.lan"
    echo "⚠️  No se pudo detectar dominio, usando por defecto: $DOMAIN"
else
    echo "🌐 Dominio detectado: $DOMAIN"
fi
echo ""

# Verificar servicio
echo "🔧 Servicio BIND9:"
if systemctl is-active --quiet named; then
    echo "✅ named está activo"
    UPTIME=$(systemctl show named --property=ActiveEnterTimestamp --value)
    echo "   ⏱️  Iniciado: $UPTIME"
else
    echo "❌ named NO está activo"
    echo "   💡 Inicia el servicio: sudo systemctl start named"
    ((ERRORS++))
fi

if systemctl is-enabled --quiet named; then
    echo "✅ named habilitado al inicio"
else
    echo "❌ named NO habilitado al inicio"
    echo "   💡 Habilita el servicio: sudo systemctl enable named"
    ((ERRORS++))
fi

echo ""
echo "🌐 Puerto DNS:"
if ss -tulpn 2>/dev/null | grep -q ":53.*named"; then
    echo "✅ BIND9 escuchando en puerto 53"
    PORT_COUNT=$(ss -tulpn 2>/dev/null | grep ":53" | grep "named" | wc -l)
    echo "   📡 Sockets activos: $PORT_COUNT"
else
    echo "❌ BIND9 NO escuchando en puerto 53"
    
    # Verificar si otro servicio está usando el puerto
    if ss -tulpn 2>/dev/null | grep -q ":53"; then
        CONFLICT=$(ss -tulpn 2>/dev/null | grep ":53" | awk '{print $NF}' | sort -u | head -n1)
        echo "   ⚠️  Puerto 53 ocupado por: $CONFLICT"
        echo "   💡 Ejecuta: bash scripts/run/run-dns.sh (corrige conflictos automáticamente)"
    fi
    ((ERRORS++))
fi

echo ""
echo "📝 Archivos de configuración:"

# Verificar sintaxis de named.conf
if sudo named-checkconf 2>/dev/null; then
    echo "✅ named.conf sintaxis correcta"
else
    echo "❌ named.conf tiene errores de sintaxis"
    echo "   💡 Verifica: sudo named-checkconf"
    ((ERRORS++))
fi

if [ -f "/etc/bind/named.conf.local" ]; then
    echo "✅ named.conf.local existe"
else
    echo "❌ named.conf.local NO existe"
    echo "   💡 Ejecuta: bash scripts/run/run-dns.sh"
    ((ERRORS++))
fi

ZONE_FILE="/etc/bind/zones/db.${DOMAIN}"
if [ -f "$ZONE_FILE" ]; then
    echo "✅ Zona $DOMAIN existe"
    
    # Verificar sintaxis de la zona
    if sudo named-checkzone "$DOMAIN" "$ZONE_FILE" &>/dev/null; then
        echo "✅ Sintaxis de zona correcta"
    else
        echo "❌ Zona tiene errores de sintaxis"
        echo "   💡 Verifica: sudo named-checkzone $DOMAIN $ZONE_FILE"
        ((ERRORS++))
    fi
else
    echo "❌ Zona $DOMAIN NO existe"
    echo "   📁 Esperado: $ZONE_FILE"
    
    if [ -d "/etc/bind/zones" ]; then
        AVAILABLE=$(ls -1 /etc/bind/zones/ 2>/dev/null | wc -l)
        if [ "$AVAILABLE" -gt 0 ]; then
            echo "   📂 Archivos disponibles:"
            ls -1 /etc/bind/zones/ | sed 's/^/      /'
        fi
    fi
    echo "   💡 Ejecuta: bash scripts/run/run-dns.sh"
    ((ERRORS++))
fi

echo ""
echo "📋 Verificando archivos de zona:"

# Verificar que el directorio de zonas existe
if [ ! -d "/etc/bind/zones" ]; then
    echo "❌ Directorio /etc/bind/zones NO existe"
    echo "   💡 Ejecuta: bash scripts/run/run-dns.sh"
    ((ERRORS++))
else
    echo "✅ Directorio /etc/bind/zones existe"
fi

# Verificar que el archivo de zona existe
if [ ! -f "$ZONE_FILE" ]; then
    echo "❌ Archivo $ZONE_FILE NO existe"
    echo "   💡 Ejecuta: bash scripts/run/run-dns.sh"
    ((ERRORS++))
else
    echo "✅ Archivo db.$DOMAIN existe"
    
    # Verificar contenido del archivo
    if sudo grep -q "@ *IN *AAAA" "$ZONE_FILE"; then
        ROOT_IP=$(sudo grep "@ *IN *AAAA" "$ZONE_FILE" | awk '{print $NF}')
        echo "✅ Registro raíz (@) configurado: $ROOT_IP"
    else
        echo "❌ Falta registro raíz (@) en la zona"
        echo "   💡 Verifica el template: roles/dns_bind/templates/db.domain.j2"
        ((ERRORS++))
    fi
    
    # Verificar que tiene registros AAAA
    if sudo grep -q "IN *AAAA" "$ZONE_FILE"; then
        AAAA_COUNT=$(sudo grep -c "IN *AAAA" "$ZONE_FILE")
        echo "✅ Archivo tiene $AAAA_COUNT registros AAAA"
    else
        echo "❌ No hay registros AAAA en el archivo"
        ((ERRORS++))
    fi
fi

echo ""
echo "🧪 Prueba de resolución:"

# Probar dominio raíz
echo "→ Probando $DOMAIN..."
RESULT=$(dig @localhost "$DOMAIN" AAAA +short 2>/dev/null)
if [ -n "$RESULT" ]; then
    echo "✅ DNS resuelve $DOMAIN → $RESULT"
else
    echo "❌ DNS NO resuelve $DOMAIN"
    echo "   💡 Verifica logs: sudo journalctl -u named -n 20"
    echo "   💡 Recarga zona: sudo rndc reload"
    ((ERRORS++))
fi

# Probar subdominios comunes
for SUBDOMAIN in servidor www web dns; do
    echo "→ Probando $SUBDOMAIN.$DOMAIN..."
    RESULT=$(dig @localhost "$SUBDOMAIN.$DOMAIN" AAAA +short 2>/dev/null)
    if [ -n "$RESULT" ]; then
        echo "✅ DNS resuelve $SUBDOMAIN.$DOMAIN → $RESULT"
    else
        echo "⚠️  DNS NO resuelve $SUBDOMAIN.$DOMAIN (puede no estar configurado)"
    fi
done

echo ""
echo "════════════════════════════════════════════════════════"
if [ $ERRORS -eq 0 ]; then
    echo "✅ DNS CONFIGURADO CORRECTAMENTE"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "📊 Dominio configurado: $DOMAIN"
    echo ""
    echo "🔧 Comandos útiles:"
    echo "   → Probar DNS: dig @localhost $DOMAIN AAAA"
    echo "   → Ver logs: sudo journalctl -u named -n 50"
    echo "   → Recargar zona: sudo rndc reload"
    echo "   → Ver zona: sudo cat $ZONE_FILE"
    echo ""
    exit 0
else
    echo "❌ ENCONTRADOS $ERRORS PROBLEMAS"
    echo "════════════════════════════════════════════════════════"
    echo ""
    
    # Diagnóstico inteligente
    echo "🔍 DIAGNÓSTICO AUTOMÁTICO:"
    echo ""
    
    if ! systemctl is-active --quiet named; then
        echo "   🔴 Servicio BIND9 no está corriendo"
        echo "      → sudo systemctl start named"
        echo "      → sudo systemctl status named"
        echo ""
    fi
    
    if [ ! -d "/etc/bind/zones" ]; then
        echo "   🔴 Falta directorio de zonas"
        echo "      → bash scripts/run/run-dns.sh"
        echo ""
    fi
    
    if [ ! -f "$ZONE_FILE" ]; then
        echo "   🔴 Falta archivo de zona: $ZONE_FILE"
        echo "      → bash scripts/run/run-dns.sh"
        echo ""
        
        # Mostrar archivos disponibles
        if [ -d "/etc/bind/zones" ]; then
            AVAILABLE=$(ls -1 /etc/bind/zones/ 2>/dev/null | wc -l)
            if [ "$AVAILABLE" -gt 0 ]; then
                echo "      📂 Archivos de zona disponibles:"
                ls -1 /etc/bind/zones/ | sed 's/^/         /'
                echo ""
            fi
        fi
    fi
    
    # Verificar conflicto de puertos
    if ss -tulpn 2>/dev/null | grep -q ":53.*systemd-resolved"; then
        echo "   🔴 systemd-resolved está usando el puerto 53"
        echo "      → bash scripts/run/run-dns.sh (esto lo corrige automáticamente)"
        echo ""
    fi
    
    # Verificar configuración de named.conf.local
    if [ -f "/etc/bind/named.conf.local" ]; then
        if ! sudo grep -q "zone \"$DOMAIN\"" /etc/bind/named.conf.local; then
            echo "   🔴 Zona $DOMAIN no está declarada en named.conf.local"
            echo "      → bash scripts/run/run-dns.sh"
            echo ""
        fi
    fi
    
    echo "💡 SOLUCIÓN RÁPIDA:"
    echo ""
    echo "   1️⃣  Ejecutar playbook completo:"
    echo "      → bash scripts/run/run-dns.sh"
    echo ""
    echo "   2️⃣  Ver logs detallados:"
    echo "      → sudo journalctl -u named -n 50 --no-pager"
    echo ""
    echo "   3️⃣  Verificar configuración:"
    echo "      → sudo named-checkconf"
    echo ""
    echo "   4️⃣  Debug avanzado:"
    echo "      → bash scripts/debug-dns-resolution.sh"
    echo ""
    exit 1
fi
