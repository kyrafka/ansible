#!/bin/bash
# Script para debuggear por qué DNS no resuelve

echo "🔍 DEBUG: Resolución DNS"
echo "========================================"
echo ""

echo "1️⃣  Contenido del archivo de zona:"
echo "----------------------------------------"
sudo cat /etc/bind/zones/db.gamecenter.lan
echo ""

echo "2️⃣  Verificar sintaxis de la zona:"
echo "----------------------------------------"
sudo named-checkzone gamecenter.lan /etc/bind/zones/db.gamecenter.lan
echo ""

echo "3️⃣  Verificar named.conf.local:"
echo "----------------------------------------"
sudo cat /etc/bind/named.conf.local
echo ""

echo "4️⃣  Logs recientes de BIND:"
echo "----------------------------------------"
sudo journalctl -u named -n 30 --no-pager
echo ""

echo "5️⃣  Probar consulta DNS directa:"
echo "----------------------------------------"
echo "→ Consultando gamecenter.lan:"
dig @127.0.0.1 gamecenter.lan AAAA +short
echo ""
echo "→ Consultando con +trace:"
dig @127.0.0.1 gamecenter.lan AAAA +trace
echo ""

echo "6️⃣  Estado de BIND:"
echo "----------------------------------------"
sudo rndc status
echo ""

echo "✅ Debug completado"
