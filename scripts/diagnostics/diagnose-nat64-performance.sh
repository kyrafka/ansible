#!/bin/bash

echo "════════════════════════════════════════════════════════════════"
echo "🔍 DIAGNÓSTICO DE RENDIMIENTO NAT64"
echo "════════════════════════════════════════════════════════════════"
echo ""

# 1. Verificar MTU de interfaz nat64
echo "📋 1. MTU de interfaz nat64:"
MTU=$(ip link show nat64 | grep -o "mtu [0-9]*" | awk '{print $2}')
echo "MTU actual: $MTU"
if [ "$MTU" -lt 1280 ]; then
    echo "⚠️  MTU muy bajo - Puede causar fragmentación y lentitud"
    echo "   Recomendado: 1280 o más"
else
    echo "✅ MTU correcto"
fi
echo ""

# 2. Verificar DNS64
echo "📋 2. Probando DNS64:"
echo "Resolviendo google.com..."
DNS_RESULT=$(dig @localhost google.com AAAA +short | head -1)
echo "Resultado: $DNS_RESULT"

if echo "$DNS_RESULT" | grep -q "64:ff9b"; then
    echo "✅ DNS64 funcionando - Respuesta con prefijo NAT64"
else
    echo "⚠️  DNS64 no está traduciendo - Puede causar problemas de conectividad"
fi
echo ""

# 3. Medir latencia DNS
echo "📋 3. Latencia de DNS:"
DNS_TIME=$(dig @localhost google.com AAAA | grep "Query time:" | awk '{print $4}')
echo "Tiempo de consulta DNS: ${DNS_TIME}ms"
if [ "$DNS_TIME" -gt 100 ]; then
    echo "⚠️  DNS lento - Puede causar demoras al cargar páginas"
else
    echo "✅ DNS rápido"
fi
echo ""

# 4. Probar conectividad NAT64
echo "📋 4. Probando conectividad NAT64 a 8.8.8.8:"
PING_RESULT=$(ping6 -c 4 64:ff9b::8.8.8.8 2>&1)
echo "$PING_RESULT"

AVG_TIME=$(echo "$PING_RESULT" | grep "rtt min/avg/max" | awk -F'/' '{print $5}')
if [ ! -z "$AVG_TIME" ]; then
    echo "Latencia promedio: ${AVG_TIME}ms"
    if (( $(echo "$AVG_TIME > 100" | bc -l) )); then
        echo "⚠️  Latencia alta - Conexión lenta"
    else
        echo "✅ Latencia normal"
    fi
fi
echo ""

# 5. Verificar carga del servidor
echo "📋 5. Carga del servidor:"
LOAD=$(uptime | awk -F'load average:' '{print $2}')
echo "Load average:$LOAD"
CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
echo "CPU usage: ${CPU}%"
MEM=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
echo "Memory usage: ${MEM}%"
echo ""

# 6. Verificar estado de TAYGA
echo "📋 6. Estado de TAYGA:"
if systemctl is-active --quiet tayga; then
    echo "✅ TAYGA activo"
    TAYGA_CPU=$(ps aux | grep "[t]ayga" | awk '{print $3}')
    TAYGA_MEM=$(ps aux | grep "[t]ayga" | awk '{print $4}')
    echo "   CPU: ${TAYGA_CPU}%"
    echo "   MEM: ${TAYGA_MEM}%"
else
    echo "❌ TAYGA no está activo"
fi
echo ""

# 7. Verificar tabla de conexiones NAT
echo "📋 7. Conexiones NAT activas:"
NAT_CONNS=$(sudo conntrack -L 2>/dev/null | wc -l)
if [ $? -eq 0 ]; then
    echo "Conexiones activas: $NAT_CONNS"
    if [ "$NAT_CONNS" -gt 1000 ]; then
        echo "⚠️  Muchas conexiones - Puede causar lentitud"
    else
        echo "✅ Número normal de conexiones"
    fi
else
    echo "⚠️  No se puede verificar (conntrack no disponible)"
fi
echo ""

# 8. Probar velocidad de descarga
echo "📋 8. Probando velocidad de descarga (pequeño archivo):"
TIME_START=$(date +%s.%N)
curl -6 -s -o /dev/null -w "%{http_code}" http://[64:ff9b::8.8.8.8] --max-time 5 2>&1
TIME_END=$(date +%s.%N)
DOWNLOAD_TIME=$(echo "$TIME_END - $TIME_START" | bc)
echo "Tiempo de conexión: ${DOWNLOAD_TIME}s"
if (( $(echo "$DOWNLOAD_TIME > 3" | bc -l) )); then
    echo "⚠️  Conexión lenta"
else
    echo "✅ Conexión rápida"
fi
echo ""

# 9. Verificar reglas de iptables
echo "📋 9. Reglas NAT para TAYGA:"
sudo iptables -t nat -L POSTROUTING -n -v | grep "192.168.255"
echo ""

# 10. Verificar fragmentación
echo "📋 10. Verificar fragmentación de paquetes:"
FRAG=$(cat /proc/sys/net/ipv4/ip_no_pmtu_disc)
echo "PMTU Discovery: $FRAG (0=habilitado, 1=deshabilitado)"
if [ "$FRAG" -eq 1 ]; then
    echo "⚠️  PMTU Discovery deshabilitado - Puede causar problemas"
else
    echo "✅ PMTU Discovery habilitado"
fi
echo ""

# ═══════════════════════════════════════════════════════════
# RESUMEN Y RECOMENDACIONES
# ═══════════════════════════════════════════════════════════

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "🎯 DIAGNÓSTICO Y RECOMENDACIONES"
echo "════════════════════════════════════════════════════════════════"
echo ""

declare -a PROBLEMAS
declare -a SOLUCIONES

# Analizar MTU
if [ "$MTU" -lt 1280 ]; then
    PROBLEMAS+=("MTU bajo ($MTU) - Causa fragmentación")
    SOLUCIONES+=("Aumentar MTU: sudo ip link set nat64 mtu 1400")
fi

# Analizar DNS
if [ "$DNS_TIME" -gt 100 ]; then
    PROBLEMAS+=("DNS lento (${DNS_TIME}ms)")
    SOLUCIONES+=("Verificar forwarders DNS en /etc/bind/named.conf.options")
fi

# Analizar latencia
if [ ! -z "$AVG_TIME" ] && (( $(echo "$AVG_TIME > 100" | bc -l) )); then
    PROBLEMAS+=("Latencia alta (${AVG_TIME}ms)")
    SOLUCIONES+=("Verificar conexión a internet del servidor")
fi

# Mostrar resultados
if [ ${#PROBLEMAS[@]} -eq 0 ]; then
    echo "✅ NO SE ENCONTRARON PROBLEMAS DE RENDIMIENTO"
    echo ""
    echo "Si aún experimentas lentitud, puede ser:"
    echo "  • Ancho de banda limitado"
    echo "  • Congestión de red"
    echo "  • Problemas en el cliente"
else
    echo "🔴 PROBLEMAS ENCONTRADOS:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    for i in "${!PROBLEMAS[@]}"; do
        echo "  $((i+1)). ${PROBLEMAS[$i]}"
    done
    echo ""
    
    echo "💡 SOLUCIONES RECOMENDADAS:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    for i in "${!SOLUCIONES[@]}"; do
        echo "  $((i+1)). ${SOLUCIONES[$i]}"
    done
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "🔍 FIN DEL DIAGNÓSTICO"
echo "════════════════════════════════════════════════════════════════"
