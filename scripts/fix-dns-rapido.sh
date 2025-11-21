#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Script para diagnosticar y arreglar DNS rápidamente
# ═══════════════════════════════════════════════════════════════

echo "════════════════════════════════════════════════════════════"
echo "  DIAGNÓSTICO Y REPARACIÓN DNS"
echo "════════════════════════════════════════════════════════════"
echo ""

echo "━━━ 1. VERIFICANDO SERVICIO BIND9 ━━━"
if systemctl is-active --quiet named; then
    echo "✓ named (BIND9) está ACTIVO"
elif systemctl is-active --quiet bind9; then
    echo "✓ bind9 está ACTIVO"
else
    echo "✗ DNS NO está activo"
    echo "Intentando iniciar..."
    sudo systemctl start bind9 2>/dev/null || sudo systemctl start named 2>/dev/null
    sleep 2
fi
echo ""

echo "━━━ 2. VERIFICANDO PUERTO 53 ━━━"
if sudo ss -tulpn | grep -q ":53"; then
    echo "✓ Puerto 53 está en escucha"
    sudo ss -tulpn | grep ":53"
else
    echo "✗ Puerto 53 NO está en escucha"
fi
echo ""

echo "━━━ 3. VERIFICANDO CONFIGURACIÓN DNS ━━━"
if [ -f /etc/bind/named.conf.local ]; then
    echo "Zonas configuradas:"
    sudo grep -E "zone|file" /etc/bind/named.conf.local | head -10
else
    echo "⚠ No se encuentra /etc/bind/named.conf.local"
fi
echo ""

echo "━━━ 4. PROBANDO RESOLUCIÓN LOCAL ━━━"
echo "Probando con dig:"
dig @localhost servidor.gamecenter.lan AAAA +short
echo ""

echo "━━━ 5. VERIFICANDO LOGS ━━━"
echo "Últimos errores de BIND:"
sudo journalctl -u bind9 -n 10 --no-pager | grep -i error
echo ""

echo "━━━ 6. VERIFICANDO ARCHIVOS DE ZONA ━━━"
if [ -f /var/lib/bind/db.gamecenter.lan ]; then
    echo "✓ Archivo de zona existe"
    echo "Contenido:"
    sudo cat /var/lib/bind/db.gamecenter.lan | head -20
else
    echo "✗ Archivo de zona NO existe"
    echo "Ubicación esperada: /var/lib/bind/db.gamecenter.lan"
fi
echo ""

echo "━━━ 7. SOLUCIÓN RÁPIDA ━━━"
echo "Si DNS no funciona, ejecuta:"
echo "  sudo systemctl restart bind9"
echo "  sudo systemctl status bind9"
echo ""
echo "Si persiste el problema:"
echo "  bash scripts/run/run-dns.sh"
echo ""

echo "════════════════════════════════════════════════════════════"
echo "  FIN DEL DIAGNÓSTICO"
echo "════════════════════════════════════════════════════════════"
