#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Script para arreglar errores de BIND9
# ═══════════════════════════════════════════════════════════════

echo "════════════════════════════════════════════════════════════"
echo "  REPARACIÓN DE ERRORES BIND9"
echo "════════════════════════════════════════════════════════════"
echo ""

echo "━━━ 1. VERIFICANDO ARCHIVOS PROBLEMÁTICOS ━━━"
echo ""

# Verificar archivo problemático
if [ -f /etc/bind/db.roz.drop-aaaa ]; then
    echo "⚠ Archivo problemático encontrado: /etc/bind/db.roz.drop-aaaa"
    echo "Contenido:"
    sudo cat /etc/bind/db.roz.drop-aaaa
    echo ""
    
    echo "Respaldando archivo..."
    sudo cp /etc/bind/db.roz.drop-aaaa /etc/bind/db.roz.drop-aaaa.backup-$(date +%Y%m%d-%H%M%S)
    echo "✓ Backup creado"
else
    echo "✓ Archivo db.roz.drop-aaaa no existe"
fi
echo ""

echo "━━━ 2. VERIFICANDO SINTAXIS DE ZONAS ━━━"
echo ""

# Verificar zona gamecenter.lan
if [ -f /var/lib/bind/db.gamecenter.lan ]; then
    echo "Verificando db.gamecenter.lan..."
    sudo named-checkzone gamecenter.lan /var/lib/bind/db.gamecenter.lan
    if [ $? -eq 0 ]; then
        echo "✓ Zona gamecenter.lan: OK"
    else
        echo "✗ Zona gamecenter.lan: ERROR"
    fi
else
    echo "⚠ Archivo db.gamecenter.lan no existe"
fi
echo ""

# Verificar zona reversa
REVERSE_ZONE=$(ls /var/lib/bind/db.*.ip6.arpa 2>/dev/null | head -1)
if [ -n "$REVERSE_ZONE" ]; then
    ZONE_NAME=$(basename "$REVERSE_ZONE" | sed 's/^db\.//')
    echo "Verificando zona reversa $ZONE_NAME..."
    sudo named-checkzone "$ZONE_NAME" "$REVERSE_ZONE"
    if [ $? -eq 0 ]; then
        echo "✓ Zona reversa: OK"
    else
        echo "✗ Zona reversa: ERROR"
    fi
else
    echo "⚠ No se encontró zona reversa"
fi
echo ""

echo "━━━ 3. VERIFICANDO CONFIGURACIÓN GENERAL ━━━"
echo ""
sudo named-checkconf
if [ $? -eq 0 ]; then
    echo "✓ Configuración general: OK"
else
    echo "✗ Configuración general: ERROR"
fi
echo ""

echo "━━━ 4. REINICIANDO BIND9 ━━━"
echo ""
sudo systemctl restart bind9
sleep 2

if systemctl is-active --quiet bind9; then
    echo "✓ BIND9 reiniciado correctamente"
else
    echo "✗ BIND9 falló al reiniciar"
    echo ""
    echo "Logs de error:"
    sudo journalctl -u bind9 -n 20 --no-pager
fi
echo ""

echo "━━━ 5. PROBANDO RESOLUCIÓN DNS ━━━"
echo ""
echo "Probando servidor.gamecenter.lan:"
dig @localhost servidor.gamecenter.lan AAAA +short
echo ""

echo "Probando resolución externa:"
dig @localhost google.com A +short | head -1
echo ""

echo "════════════════════════════════════════════════════════════"
echo "  FIN DE LA REPARACIÓN"
echo "════════════════════════════════════════════════════════════"
echo ""

if systemctl is-active --quiet bind9; then
    echo "✓ BIND9 está funcionando"
    echo ""
    echo "Si aún hay problemas, ejecuta:"
    echo "  bash scripts/run/run-dns.sh"
else
    echo "✗ BIND9 tiene problemas"
    echo ""
    echo "Solución: Reconfigurar DNS desde cero"
    echo "  bash scripts/run/run-dns.sh"
fi
echo ""
