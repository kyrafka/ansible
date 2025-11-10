#!/bin/bash
# Script para diagnosticar y corregir rutas de NAT64

echo "════════════════════════════════════════════════════════"
echo "🔧 Diagnosticando y corrigiendo rutas NAT64"
echo "════════════════════════════════════════════════════════"

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script debe ejecutarse como root"
    echo "   Usa: sudo bash $0"
    exit 1
fi

echo ""
echo "1️⃣  Verificando interfaz nat64..."
if ! ip link show nat64 &>/dev/null; then
    echo "   ❌ Interfaz nat64 NO existe"
    echo "   Creando interfaz..."
    tayga --mktun
    ip link set nat64 up
    ip addr add 192.168.255.1 dev nat64
    ip addr add 2025:db8:10::ffff dev nat64
fi

ip addr show nat64
echo ""

echo "2️⃣  Eliminando rutas antiguas (si existen)..."
ip route del 192.168.255.0/24 dev nat64 2>/dev/null && echo "   Ruta IPv4 eliminada" || echo "   No había ruta IPv4"
ip route del 64:ff9b::/96 dev nat64 2>/dev/null && echo "   Ruta IPv6 eliminada" || echo "   No había ruta IPv6"
echo ""

echo "3️⃣  Agregando ruta IPv4 (192.168.255.0/24)..."
if ip route add 192.168.255.0/24 dev nat64 2>&1; then
    echo "   ✅ Ruta IPv4 agregada"
else
    echo "   ⚠️  Error al agregar ruta IPv4"
    ip route | grep 192.168.255
fi
echo ""

echo "4️⃣  Agregando ruta IPv6 (64:ff9b::/96)..."
if ip route add 64:ff9b::/96 dev nat64 2>&1; then
    echo "   ✅ Ruta IPv6 agregada"
else
    echo "   ⚠️  Error al agregar ruta IPv6"
    ip -6 route | grep 64:ff9b
fi
echo ""

echo "5️⃣  Verificando rutas configuradas..."
echo "Rutas IPv4:"
ip route | grep -E "(192.168.255|nat64)" || echo "   ❌ No hay rutas IPv4"
echo ""
echo "Rutas IPv6:"
ip -6 route | grep -E "(64:ff9b|nat64)" || echo "   ❌ No hay rutas IPv6"
echo ""

echo "6️⃣  Verificando Tayga..."
if ps aux | grep -v grep | grep tayga > /dev/null; then
    echo "   ✅ Tayga está corriendo"
else
    echo "   ⚠️  Tayga NO está corriendo, iniciando..."
    tayga
    sleep 1
    if ps aux | grep -v grep | grep tayga > /dev/null; then
        echo "   ✅ Tayga iniciado"
    else
        echo "   ❌ Error al iniciar Tayga"
    fi
fi
echo ""

echo "7️⃣  Verificando iptables..."
if iptables -t nat -L POSTROUTING -v -n | grep 192.168.255 > /dev/null; then
    echo "   ✅ Reglas NAT configuradas"
else
    echo "   ⚠️  Configurando reglas NAT..."
    iptables -t nat -A POSTROUTING -s 192.168.255.0/24 -o ens33 -j MASQUERADE
    iptables -A FORWARD -i nat64 -o ens33 -j ACCEPT
    iptables -A FORWARD -i ens33 -o nat64 -m state --state RELATED,ESTABLISHED -j ACCEPT
    echo "   ✅ Reglas NAT agregadas"
fi
echo ""

echo "8️⃣  Test de conectividad..."
echo "Ping a 8.8.8.8 desde el servidor:"
if ping -c 2 8.8.8.8 &>/dev/null; then
    echo "   ✅ Conectividad IPv4 OK"
else
    echo "   ❌ Sin conectividad IPv4"
fi
echo ""

echo "════════════════════════════════════════════════════════"
echo "📋 Resumen final:"
echo "════════════════════════════════════════════════════════"

# Verificar todo
TAYGA_OK=false
NAT64_OK=false
ROUTES_OK=false

ps aux | grep -v grep | grep tayga > /dev/null && TAYGA_OK=true
ip link show nat64 &>/dev/null && NAT64_OK=true
ip route | grep 64:ff9b > /dev/null && ROUTES_OK=true

if $TAYGA_OK; then
    echo "✅ Tayga está corriendo"
else
    echo "❌ Tayga NO está corriendo"
fi

if $NAT64_OK; then
    echo "✅ Interfaz nat64 existe"
else
    echo "❌ Interfaz nat64 NO existe"
fi

if $ROUTES_OK; then
    echo "✅ Rutas NAT64 configuradas"
else
    echo "❌ Rutas NAT64 NO configuradas"
fi

echo ""
if $TAYGA_OK && $NAT64_OK && $ROUTES_OK; then
    echo "🎉 ¡Todo configurado correctamente!"
    echo ""
    echo "📋 Prueba desde la VM:"
    echo "   ping6 64:ff9b::808:808"
    echo "   ping6 google.com"
else
    echo "⚠️  Hay problemas en la configuración"
    echo "   Revisa los errores arriba"
fi
echo ""
echo "════════════════════════════════════════════════════════"
