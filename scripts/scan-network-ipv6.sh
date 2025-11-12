#!/bin/bash
# Script para escanear la red IPv6 y detectar hosts activos

NETWORK="2025:db8:10::"
INTERFACE="ens34"

echo "════════════════════════════════════════════════════════"
echo "🔍 Escaneando red IPv6: ${NETWORK}/64"
echo "════════════════════════════════════════════════════════"
echo ""

echo "📡 Hosts activos en la red:"
echo ""

# Usar ping6 para descubrir hosts
for i in {1..20} {100..120} {200..220}; do
    IP="${NETWORK}${i}"
    if ping6 -c 1 -W 1 "$IP" > /dev/null 2>&1; then
        # Intentar obtener hostname
        HOSTNAME=$(dig -x "$IP" +short 2>/dev/null | sed 's/\.$//')
        if [ -z "$HOSTNAME" ]; then
            HOSTNAME="(sin nombre)"
        fi
        echo "✅ $IP → $HOSTNAME"
    fi
done

echo ""
echo "💡 También puedes ver la tabla de vecinos IPv6:"
echo "   ip -6 neigh show dev $INTERFACE"
echo ""
ip -6 neigh show dev "$INTERFACE" | grep -v "FAILED\|INCOMPLETE"

echo ""
echo "════════════════════════════════════════════════════════"
echo "📋 Para agregar hosts al DNS:"
echo "   1. Edita: dns-hosts.txt"
echo "   2. Ejecuta: bash scripts/update-dns-from-file.sh"
echo "════════════════════════════════════════════════════════"
