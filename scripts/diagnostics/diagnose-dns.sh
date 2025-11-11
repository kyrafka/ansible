#!/bin/bash
# Script de diagnóstico avanzado para DNS (BIND9)
# Ejecutar: bash scripts/diagnostics/diagnose-dns.sh

echo "════════════════════════════════════════════════════════"
echo "🔬 DIAGNÓSTICO AVANZADO DE DNS (BIND9)"
echo "════════════════════════════════════════════════════════"
echo ""

# 1. Probar DNS directamente
echo "🧪 1. Probando DNS directamente en el servidor:"
echo "→ dig @localhost gamecenter.local AAAA"
dig @localhost gamecenter.local AAAA
echo ""

# 2. Ver interfaces donde escucha BIND9
echo "🔌 2. Interfaces donde BIND9 está escuchando:"
echo "→ sudo ss -tulpn | grep :53"
sudo ss -tulpn | grep :53
echo ""

# 3. Ver logs de errores
echo "📋 3. Logs de BIND9 (últimos 50, solo errores):"
echo "→ sudo journalctl -u named -n 50 | grep -i error"
sudo journalctl -u named -n 50 | grep -i error
echo ""

# 4. Ver contenido del archivo de zona
echo "📄 4. Contenido del archivo de zona:"
echo "→ sudo cat /etc/bind/zones/db.gamecenter.local"
sudo cat /etc/bind/zones/db.gamecenter.local
echo ""

# 5. Verificar sintaxis del archivo de zona
echo "✔️  5. Verificando sintaxis del archivo de zona:"
echo "→ sudo named-checkzone gamecenter.local /etc/bind/zones/db.gamecenter.local"
sudo named-checkzone gamecenter.local /etc/bind/zones/db.gamecenter.local
echo ""

# 6. Verificar configuración de BIND9
echo "⚙️  6. Verificando configuración de BIND9:"
echo "→ sudo named-checkconf"
sudo named-checkconf && echo "✅ Configuración válida" || echo "❌ Configuración inválida"
echo ""

# 7. Ver estado del servicio
echo "🔧 7. Estado del servicio BIND9:"
echo "→ sudo systemctl status named --no-pager -l"
sudo systemctl status named --no-pager -l
echo ""

# 8. Ver named.conf.local
echo "📝 8. Configuración de zonas locales:"
echo "→ sudo cat /etc/bind/named.conf.local"
sudo cat /etc/bind/named.conf.local
echo ""

# 9. Probar resolución de otros registros
echo "🧪 9. Probando otros registros DNS:"
echo "→ servidor.gamecenter.local"
dig @localhost servidor.gamecenter.local AAAA +short
echo "→ www.gamecenter.local"
dig @localhost www.gamecenter.local AAAA +short
echo "→ web.gamecenter.local"
dig @localhost web.gamecenter.local AAAA +short
echo ""

echo "════════════════════════════════════════════════════════"
echo "🔍 ANÁLISIS DE RESULTADOS"
echo "════════════════════════════════════════════════════════"
echo ""

ISSUES=0

# Analizar si DNS resuelve
if dig @localhost gamecenter.local AAAA +short | grep -q "2025:db8:10::2"; then
    echo "✅ DNS resuelve gamecenter.local correctamente"
else
    echo "❌ PROBLEMA: DNS NO resuelve gamecenter.local"
    echo "   💡 Posibles causas:"
    echo "      - El archivo de zona no tiene el registro @"
    echo "      - BIND9 no cargó la zona correctamente"
    echo "      - Hay un error de sintaxis en el archivo"
    ((ISSUES++))
fi

# Analizar si BIND9 está escuchando
if sudo ss -tulpn | grep -q ":53.*named"; then
    echo "✅ BIND9 está escuchando en puerto 53"
else
    echo "❌ PROBLEMA: BIND9 NO está escuchando en puerto 53"
    echo "   💡 Posibles causas:"
    echo "      - El servicio no está iniciado"
    echo "      - Hay un error en la configuración"
    echo "      - Otro proceso está usando el puerto 53"
    ((ISSUES++))
fi

# Analizar si el archivo de zona existe
if [ -f "/etc/bind/zones/db.gamecenter.local" ]; then
    echo "✅ Archivo de zona existe"
    
    # Verificar si tiene el registro @
    if sudo grep -q "@ *IN *AAAA *2025:db8:10::2" /etc/bind/zones/db.gamecenter.local; then
        echo "✅ Archivo tiene registro raíz (@)"
    else
        echo "❌ PROBLEMA: Falta registro raíz (@) en el archivo"
        echo "   💡 Solución:"
        echo "      - Agregar línea: @  IN  AAAA  2025:db8:10::2"
        echo "      - Ejecutar: sudo rndc reload"
        ((ISSUES++))
    fi
else
    echo "❌ PROBLEMA: Archivo de zona NO existe"
    echo "   💡 Solución:"
    echo "      - Ejecutar: bash scripts/run/run-dns.sh"
    ((ISSUES++))
fi

# Analizar sintaxis
if sudo named-checkzone gamecenter.local /etc/bind/zones/db.gamecenter.local &>/dev/null; then
    echo "✅ Sintaxis del archivo de zona es correcta"
else
    echo "❌ PROBLEMA: Sintaxis del archivo de zona tiene errores"
    echo "   💡 Ver detalles arriba en la sección 5"
    ((ISSUES++))
fi

# Analizar configuración general
if sudo named-checkconf &>/dev/null; then
    echo "✅ Configuración de BIND9 es válida"
else
    echo "❌ PROBLEMA: Configuración de BIND9 tiene errores"
    echo "   💡 Ver detalles arriba en la sección 6"
    ((ISSUES++))
fi

echo ""
echo "════════════════════════════════════════════════════════"
if [ $ISSUES -eq 0 ]; then
    echo "✅ TODO ESTÁ BIEN - DNS FUNCIONANDO CORRECTAMENTE"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "🎉 El DNS está configurado y funcionando correctamente"
    echo ""
else
    echo "❌ ENCONTRADOS $ISSUES PROBLEMAS"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "📋 RESUMEN DE PROBLEMAS ENCONTRADOS:"
    echo ""
    
    # Listar problemas específicos
    if ! dig @localhost gamecenter.local AAAA +short | grep -q "2025:db8:10::2"; then
        echo "   1. DNS no resuelve gamecenter.local"
        echo "      → Causa más probable: Falta registro @ en el archivo de zona"
        echo "      → Solución: Verificar archivo /etc/bind/zones/db.gamecenter.local"
        echo ""
    fi
    
    if ! sudo ss -tulpn | grep -q ":53.*named"; then
        echo "   2. BIND9 no está escuchando en puerto 53"
        echo "      → Causa más probable: Servicio no iniciado o error en configuración"
        echo "      → Solución: sudo systemctl restart named"
        echo ""
    fi
    
    if [ ! -f "/etc/bind/zones/db.gamecenter.local" ]; then
        echo "   3. Archivo de zona no existe"
        echo "      → Causa: El playbook no se ejecutó correctamente"
        echo "      → Solución: bash scripts/run/run-dns.sh"
        echo ""
    fi
    
    echo "💡 ACCIÓN RECOMENDADA:"
    echo ""
    echo "   1. Ejecutar: bash scripts/run/run-dns.sh"
    echo "   2. Verificar: bash scripts/run/validate-dns.sh"
    echo "   3. Si persiste: Revisar logs arriba (sección 3)"
    echo ""
fi
