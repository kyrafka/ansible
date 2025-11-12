#!/bin/bash
# Script para solucionar el bloqueo de AppArmor a BIND9

echo "════════════════════════════════════════════════════════"
echo "🔧 Solucionando bloqueo de AppArmor a BIND9"
echo "════════════════════════════════════════════════════════"
echo ""

echo "1️⃣  Poniendo AppArmor en 'complain mode' para BIND"
echo "   (Registra violaciones pero no bloquea)"
sudo aa-complain /usr/sbin/named
echo "   ✅ Modo queja activado"
echo ""

echo "2️⃣  Reiniciando BIND9"
sudo systemctl restart bind9
echo "   ⏳ Esperando 10 segundos..."
sleep 10
echo "   ✅ BIND9 reiniciado"
echo ""

echo "3️⃣  Verificando logs recientes"
echo "────────────────────────────────────────────────────────"
sudo journalctl -u named -n 30 --no-pager | tail -n 15
echo "────────────────────────────────────────────────────────"
echo ""

echo "4️⃣  Probando resolución DNS local"
echo "────────────────────────────────────────────────────────"
RESULT=$(dig @127.0.0.1 gamecenter.lan AAAA +short)
if [ -n "$RESULT" ]; then
    echo "✅ ¡ÉXITO! DNS resuelve gamecenter.lan"
    echo "   → $RESULT"
    echo ""
    echo "🎉 Problema resuelto"
else
    echo "❌ Aún no resuelve"
    echo "   Verifica los logs arriba para más detalles"
fi
echo "────────────────────────────────────────────────────────"
echo ""

echo "💡 Para hacer el cambio permanente:"
echo "   → bash scripts/run/run-dns.sh"
echo "   (El playbook ahora incluye la configuración de AppArmor)"
