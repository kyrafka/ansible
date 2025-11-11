#!/bin/bash
# Script para probar todos los registros DNS
# Ejecutar: bash scripts/diagnostics/test-dns-records.sh

echo "════════════════════════════════════════════════════════"
echo "🧪 PROBANDO REGISTROS DNS"
echo "════════════════════════════════════════════════════════"
echo ""

echo "1️⃣  Probando gamecenter.local (dominio raíz):"
echo "→ dig @localhost gamecenter.local AAAA +short"
RESULT=$(dig @localhost gamecenter.local AAAA +short)
if [ -z "$RESULT" ]; then
    echo "❌ Sin respuesta"
else
    echo "✅ $RESULT"
fi
echo ""

echo "2️⃣  Probando servidor.gamecenter.local:"
echo "→ dig @localhost servidor.gamecenter.local AAAA +short"
RESULT=$(dig @localhost servidor.gamecenter.local AAAA +short)
if [ -z "$RESULT" ]; then
    echo "❌ Sin respuesta"
else
    echo "✅ $RESULT"
fi
echo ""

echo "3️⃣  Probando www.gamecenter.local (CNAME):"
echo "→ dig @localhost www.gamecenter.local AAAA +short"
RESULT=$(dig @localhost www.gamecenter.local AAAA +short)
if [ -z "$RESULT" ]; then
    echo "❌ Sin respuesta"
else
    echo "✅ $RESULT"
fi
echo ""

echo "4️⃣  Probando web.gamecenter.local (CNAME):"
echo "→ dig @localhost web.gamecenter.local AAAA +short"
RESULT=$(dig @localhost web.gamecenter.local AAAA +short)
if [ -z "$RESULT" ]; then
    echo "❌ Sin respuesta"
else
    echo "✅ $RESULT"
fi
echo ""

echo "5️⃣  Probando gamecenter.local sin especificar tipo:"
echo "→ dig @localhost gamecenter.local +short"
RESULT=$(dig @localhost gamecenter.local +short)
if [ -z "$RESULT" ]; then
    echo "❌ Sin respuesta"
else
    echo "✅ $RESULT"
fi
echo ""

echo "6️⃣  Probando gamecenter.local con ANY:"
echo "→ dig @localhost gamecenter.local ANY +short"
RESULT=$(dig @localhost gamecenter.local ANY +short)
if [ -z "$RESULT" ]; then
    echo "❌ Sin respuesta"
else
    echo "✅ Respuestas:"
    echo "$RESULT"
fi
echo ""

echo "7️⃣  Probando con el FQDN completo (con punto):"
echo "→ dig @localhost gamecenter.local. AAAA +short"
RESULT=$(dig @localhost gamecenter.local. AAAA +short)
if [ -z "$RESULT" ]; then
    echo "❌ Sin respuesta"
else
    echo "✅ $RESULT"
fi
echo ""

echo "════════════════════════════════════════════════════════"
echo "📋 RESUMEN"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Si servidor.gamecenter.local funciona pero gamecenter.local no,"
echo "entonces el problema es específico del registro raíz (@)."
echo ""

echo "════════════════════════════════════════════════════════"
echo "🔍 VERIFICANDO CONFIGURACIÓN DE BIND9"
echo "════════════════════════════════════════════════════════"
echo ""

echo "📄 Configuración de named.conf.options:"
echo "→ sudo cat /etc/bind/named.conf.options | grep -v '^//' | grep -v '^$'"
sudo cat /etc/bind/named.conf.options | grep -v "^//" | grep -v "^$"
echo ""

echo "🔍 Buscando filtros de AAAA:"
echo "→ sudo grep -r 'filter-aaaa' /etc/bind/"
FILTER_RESULT=$(sudo grep -r "filter-aaaa" /etc/bind/ 2>/dev/null)
if [ -z "$FILTER_RESULT" ]; then
    echo "✅ No hay filtros de AAAA configurados"
else
    echo "⚠️  Filtros encontrados:"
    echo "$FILTER_RESULT"
fi
echo ""

echo "🔍 Verificando si IPv6 está habilitado en BIND9:"
echo "→ sudo grep -r 'listen-on-v6' /etc/bind/"
sudo grep -r "listen-on-v6" /etc/bind/ 2>/dev/null
echo ""
