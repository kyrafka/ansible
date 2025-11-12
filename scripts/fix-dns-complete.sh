#!/bin/bash
# Script completo para solucionar DNS con confirmaciones

set -e  # Salir si hay error

echo "════════════════════════════════════════════════════════"
echo "🔧 Solución completa de DNS BIND9"
echo "════════════════════════════════════════════════════════"
echo ""

# Función para pausar y confirmar
pause() {
    echo ""
    read -p "Presiona ENTER para continuar..."
    echo ""
}

# Función para verificar comando
check_step() {
    if [ $? -eq 0 ]; then
        echo "✅ Paso completado exitosamente"
    else
        echo "❌ Error en el paso"
        exit 1
    fi
}

echo "📋 PASO 1: Verificar estado actual de BIND9"
echo "────────────────────────────────────────────────────────"
systemctl status bind9 --no-pager | head -n 10
pause

echo "📋 PASO 2: Verificar si apparmor-utils está instalado"
echo "────────────────────────────────────────────────────────"
if dpkg -l | grep -q apparmor-utils; then
    echo "✅ apparmor-utils ya está instalado"
else
    echo "⚠️  apparmor-utils NO está instalado"
    echo "→ Instalando apparmor-utils..."
    sudo apt install -y apparmor-utils
    check_step
fi
pause

echo "📋 PASO 3: Configurar AppArmor en modo 'complain' para BIND"
echo "────────────────────────────────────────────────────────"
echo "→ Esto permite que BIND funcione sin restricciones de AppArmor"
sudo aa-complain /usr/sbin/named
check_step
echo "✅ AppArmor configurado en modo queja (no bloquea)"
pause

echo "📋 PASO 4: Verificar perfil de AppArmor"
echo "────────────────────────────────────────────────────────"
sudo aa-status | grep named || echo "No hay restricciones activas"
pause

echo "📋 PASO 5: Reiniciar BIND9"
echo "────────────────────────────────────────────────────────"
sudo systemctl restart bind9
check_step
echo "✅ BIND9 reiniciado"
echo "⏳ Esperando 10 segundos para que BIND se estabilice..."
sleep 10
pause

echo "📋 PASO 6: Verificar que BIND está corriendo"
echo "────────────────────────────────────────────────────────"
if systemctl is-active --quiet bind9; then
    echo "✅ BIND9 está activo"
else
    echo "❌ BIND9 NO está activo"
    echo "→ Ver logs:"
    sudo journalctl -u bind9 -n 20 --no-pager
    exit 1
fi
pause

echo "📋 PASO 7: Verificar puerto 53"
echo "────────────────────────────────────────────────────────"
sudo netstat -tulpn | grep :53
pause

echo "📋 PASO 8: Ver logs recientes de BIND"
echo "────────────────────────────────────────────────────────"
sudo journalctl -u named -n 30 --no-pager | tail -n 20
pause

echo "📋 PASO 9: Probar resolución DNS local"
echo "────────────────────────────────────────────────────────"
echo "→ Probando gamecenter.lan..."
RESULT=$(dig @127.0.0.1 gamecenter.lan AAAA +short)
if [ -n "$RESULT" ]; then
    echo "✅ ¡ÉXITO! DNS resuelve gamecenter.lan"
    echo "   Resultado: $RESULT"
else
    echo "❌ DNS NO resuelve gamecenter.lan"
    echo ""
    echo "→ Intentando diagnóstico adicional..."
    echo ""
    echo "Prueba sin recursión:"
    dig @127.0.0.1 gamecenter.lan AAAA +norecurse +short
    echo ""
    echo "Prueba con trace:"
    dig @127.0.0.1 gamecenter.lan AAAA +trace | head -n 20
fi
pause

echo "📋 PASO 10: Probar subdominios"
echo "────────────────────────────────────────────────────────"
for subdomain in servidor www ns1 dns; do
    echo "→ Probando $subdomain.gamecenter.lan..."
    RESULT=$(dig @127.0.0.1 "$subdomain.gamecenter.lan" AAAA +short)
    if [ -n "$RESULT" ]; then
        echo "   ✅ $RESULT"
    else
        echo "   ⚠️  No resuelve"
    fi
done
pause

echo "📋 PASO 11: Verificar archivo de zona"
echo "────────────────────────────────────────────────────────"
echo "→ Contenido de db.gamecenter.lan:"
sudo cat /etc/bind/zones/db.gamecenter.lan
pause

echo "📋 PASO 12: Verificar sintaxis de zona"
echo "────────────────────────────────────────────────────────"
sudo named-checkzone gamecenter.lan /etc/bind/zones/db.gamecenter.lan
check_step
pause

echo ""
echo "════════════════════════════════════════════════════════"
echo "🎉 PROCESO COMPLETADO"
echo "════════════════════════════════════════════════════════"
echo ""
echo "📊 Resumen:"
echo "   → BIND9: $(systemctl is-active bind9)"
echo "   → AppArmor: Modo complain (no bloquea)"
echo "   → Puerto 53: $(ss -tulpn | grep -c ':53.*named') sockets activos"
echo ""
echo "🔧 Comandos útiles:"
echo "   → Ver logs: sudo journalctl -u named -f"
echo "   → Recargar zona: sudo rndc reload"
echo "   → Validar todo: bash scripts/run/validate-dns.sh"
echo ""
