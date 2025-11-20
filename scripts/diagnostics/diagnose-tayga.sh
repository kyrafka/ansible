#!/bin/bash

# Arrays para almacenar problemas
declare -a ERRORES_CRITICOS
declare -a ADVERTENCIAS
declare -a INFO

echo "════════════════════════════════════════"
echo "🔍 DIAGNÓSTICO COMPLETO DE TAYGA"
echo "════════════════════════════════════════"
echo ""

# 1. Verificar archivo de configuración
echo "📋 1. Verificando archivo de configuración..."
if [ -f /etc/tayga.conf ]; then
    echo "✅ /etc/tayga.conf existe"
    cat /etc/tayga.conf
else
    echo "❌ /etc/tayga.conf NO existe"
    ERRORES_CRITICOS+=("Archivo /etc/tayga.conf no existe - TAYGA no puede funcionar sin configuración")
fi
echo ""

# 2. Verificar directorio de datos
echo "📋 2. Verificando directorio de datos..."
if [ -d /var/db/tayga ]; then
    echo "✅ /var/db/tayga existe"
    ls -la /var/db/tayga
else
    echo "❌ /var/db/tayga NO existe"
    ERRORES_CRITICOS+=("Directorio /var/db/tayga no existe - Crear con: sudo mkdir -p /var/db/tayga")
fi
echo ""

# 3. Verificar interfaz nat64
echo "📋 3. Verificando interfaz nat64..."
if ip link show nat64 &>/dev/null; then
    echo "✅ Interfaz nat64 existe"
    ip link show nat64
    ip addr show nat64
    
    # Verificar si está UP
    if ip link show nat64 | grep -q "state UP"; then
        echo "✅ Interfaz nat64 está UP"
    else
        echo "⚠️  Interfaz nat64 está DOWN"
        ADVERTENCIAS+=("Interfaz nat64 existe pero está DOWN - Levantar con: sudo ip link set nat64 up")
    fi
else
    echo "❌ Interfaz nat64 NO existe"
    ADVERTENCIAS+=("Interfaz nat64 no existe - Se creará automáticamente al iniciar TAYGA")
fi
echo ""

# 4. Intentar crear interfaz manualmente
echo "📋 4. Intentando crear interfaz manualmente..."
MKTUN_OUTPUT=$(sudo tayga --mktun 2>&1)
MKTUN_EXIT=$?
echo "$MKTUN_OUTPUT"
if [ $MKTUN_EXIT -eq 0 ]; then
    echo "✅ Interfaz creada exitosamente"
elif echo "$MKTUN_OUTPUT" | grep -q "File exists"; then
    echo "✅ Interfaz ya existe"
else
    echo "❌ Error al crear interfaz"
    ERRORES_CRITICOS+=("No se puede crear interfaz nat64: $MKTUN_OUTPUT")
fi
echo ""

# 5. Verificar si tayga puede ejecutarse
echo "📋 5. Probando ejecución de TAYGA..."
TAYGA_TEST=$(timeout 3 sudo tayga --nodetach 2>&1 &)
TAYGA_PID=$!
sleep 2

if ps -p $TAYGA_PID > /dev/null 2>&1; then
    echo "✅ TAYGA se está ejecutando correctamente"
    sudo kill $TAYGA_PID 2>/dev/null
    wait $TAYGA_PID 2>/dev/null
else
    echo "❌ TAYGA no se pudo ejecutar"
    TAYGA_ERROR=$(sudo tayga --nodetach 2>&1 | head -20)
    echo "Error: $TAYGA_ERROR"
    ERRORES_CRITICOS+=("TAYGA no puede ejecutarse: $TAYGA_ERROR")
fi
echo ""

# 6. Estado del servicio
echo "📋 6. Estado del servicio systemd..."
if systemctl is-active --quiet tayga; then
    echo "✅ Servicio tayga está ACTIVO"
    sudo systemctl status tayga --no-pager | head -15
else
    echo "❌ Servicio tayga NO está activo"
    SERVICIO_ERROR=$(sudo systemctl status tayga --no-pager 2>&1 | grep -E "Active:|Main PID:|Status:|failed|error" | head -10)
    echo "$SERVICIO_ERROR"
    ERRORES_CRITICOS+=("Servicio tayga no está activo")
fi
echo ""

# 7. Logs recientes
echo "📋 7. Últimos logs de tayga..."
LOGS=$(sudo journalctl -u tayga -n 15 --no-pager 2>&1)
echo "$LOGS"

# Analizar logs para encontrar errores específicos
if echo "$LOGS" | grep -q "Can't open PID file"; then
    ERRORES_CRITICOS+=("Problema con archivo PID - El servicio systemd está mal configurado")
fi

if echo "$LOGS" | grep -q "timeout"; then
    ERRORES_CRITICOS+=("Timeout al iniciar - TAYGA tarda demasiado en arrancar")
fi

if echo "$LOGS" | grep -q "Address already in use"; then
    ERRORES_CRITICOS+=("Dirección ya en uso - Otro proceso está usando los recursos de TAYGA")
fi

if echo "$LOGS" | grep -q "Permission denied"; then
    ERRORES_CRITICOS+=("Permisos denegados - Verificar permisos de /var/db/tayga")
fi
echo ""

# 8. Verificar archivo de servicio systemd
echo "📋 8. Verificando configuración de systemd..."
if [ -f /etc/systemd/system/tayga.service ]; then
    echo "✅ /etc/systemd/system/tayga.service existe"
    cat /etc/systemd/system/tayga.service
    
    # Verificar tipo de servicio
    if grep -q "Type=forking" /etc/systemd/system/tayga.service; then
        ADVERTENCIAS+=("Servicio usa Type=forking pero TAYGA no crea PID file correctamente - Cambiar a Type=simple")
    fi
else
    echo "❌ /etc/systemd/system/tayga.service NO existe"
    ERRORES_CRITICOS+=("Archivo de servicio systemd no existe")
fi
echo ""

# 9. Verificar IP forwarding
echo "📋 9. Verificando IP forwarding..."
IPV4_FWD=$(cat /proc/sys/net/ipv4/ip_forward)
IPV6_FWD=$(cat /proc/sys/net/ipv6/conf/all/forwarding)

if [ "$IPV4_FWD" = "1" ]; then
    echo "✅ IPv4 forwarding habilitado"
else
    echo "❌ IPv4 forwarding deshabilitado"
    ERRORES_CRITICOS+=("IPv4 forwarding deshabilitado - Habilitar con: sudo sysctl -w net.ipv4.ip_forward=1")
fi

if [ "$IPV6_FWD" = "1" ]; then
    echo "✅ IPv6 forwarding habilitado"
else
    echo "❌ IPv6 forwarding deshabilitado"
    ERRORES_CRITICOS+=("IPv6 forwarding deshabilitado - Habilitar con: sudo sysctl -w net.ipv6.conf.all.forwarding=1")
fi
echo ""

# 10. Verificar rutas NAT64
echo "📋 10. Verificando rutas NAT64..."
if ip -6 route | grep -q "64:ff9b::/96"; then
    echo "✅ Ruta IPv6 NAT64 configurada"
    ip -6 route | grep "64:ff9b::/96"
else
    echo "❌ Ruta IPv6 NAT64 NO configurada"
    ADVERTENCIAS+=("Ruta IPv6 NAT64 no existe - Agregar con: sudo ip -6 route add 64:ff9b::/96 dev nat64")
fi

if ip -4 route | grep -q "192.168.255.0/24"; then
    echo "✅ Ruta IPv4 NAT64 configurada"
    ip -4 route | grep "192.168.255.0/24"
else
    echo "❌ Ruta IPv4 NAT64 NO configurada"
    ADVERTENCIAS+=("Ruta IPv4 NAT64 no existe - Agregar con: sudo ip -4 route add 192.168.255.0/24 dev nat64")
fi
echo ""

# 11. Verificar permisos
echo "📋 11. Verificando permisos..."
if [ -x /usr/sbin/tayga ]; then
    echo "✅ /usr/sbin/tayga es ejecutable"
    ls -la /usr/sbin/tayga
else
    echo "❌ /usr/sbin/tayga NO es ejecutable"
    ERRORES_CRITICOS+=("TAYGA no tiene permisos de ejecución")
fi
echo ""

# ═══════════════════════════════════════════════════════════
# RESUMEN DINÁMICO DE PROBLEMAS
# ═══════════════════════════════════════════════════════════

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "🎯 RESUMEN DE PROBLEMAS ENCONTRADOS"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Contar problemas
NUM_CRITICOS=${#ERRORES_CRITICOS[@]}
NUM_ADVERTENCIAS=${#ADVERTENCIAS[@]}

if [ $NUM_CRITICOS -eq 0 ] && [ $NUM_ADVERTENCIAS -eq 0 ]; then
    echo "✅ ¡NO SE ENCONTRARON PROBLEMAS!"
    echo ""
    echo "TAYGA debería estar funcionando correctamente."
    echo "Si aún tienes problemas, ejecuta: sudo systemctl restart tayga"
else
    # Mostrar errores críticos
    if [ $NUM_CRITICOS -gt 0 ]; then
        echo "🔴 ERRORES CRÍTICOS ($NUM_CRITICOS):"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        for i in "${!ERRORES_CRITICOS[@]}"; do
            echo "  $((i+1)). ${ERRORES_CRITICOS[$i]}"
        done
        echo ""
    fi
    
    # Mostrar advertencias
    if [ $NUM_ADVERTENCIAS -gt 0 ]; then
        echo "⚠️  ADVERTENCIAS ($NUM_ADVERTENCIAS):"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        for i in "${!ADVERTENCIAS[@]}"; do
            echo "  $((i+1)). ${ADVERTENCIAS[$i]}"
        done
        echo ""
    fi
    
    # Solución rápida
    echo "💡 SOLUCIÓN RÁPIDA:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if [ $NUM_CRITICOS -gt 0 ]; then
        echo "1. Ejecuta el playbook de red completo:"
        echo "   bash scripts/run/run-network.sh"
        echo ""
        echo "2. O arregla manualmente los errores críticos listados arriba"
    else
        echo "Solo hay advertencias. Intenta:"
        echo "   sudo systemctl restart tayga"
        echo "   bash scripts/run/validate-network.sh"
    fi
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "🔍 FIN DEL DIAGNÓSTICO"
echo "════════════════════════════════════════════════════════════════"
