#!/bin/bash
# Script para validar el servidor DHCPv6
# Ejecutar: bash scripts/run/validate-dhcp.sh

echo "════════════════════════════════════════════════════════"
echo "🔍 Validando Servidor DHCPv6"
echo "════════════════════════════════════════════════════════"
echo ""

ERRORS=0

# Verificar servicio
echo "🔧 Servicio DHCPv6:"
if systemctl is-active --quiet isc-dhcp-server6; then
    echo "✅ isc-dhcp-server6 está activo"
else
    echo "❌ isc-dhcp-server6 NO está activo"
    ((ERRORS++))
fi

if systemctl is-enabled --quiet isc-dhcp-server6; then
    echo "✅ isc-dhcp-server6 habilitado al inicio"
else
    echo "❌ isc-dhcp-server6 NO habilitado al inicio"
    ((ERRORS++))
fi

echo ""
echo "🌐 Puerto DHCP:"

# Intentar con y sin sudo para detectar el puerto
PORT_CHECK=$(sudo ss -ulpn 2>/dev/null | grep ":547.*dhcpd" || ss -ulpn 2>/dev/null | grep ":547.*dhcpd")

if [ -n "$PORT_CHECK" ]; then
    echo "✅ DHCPv6 escuchando en puerto 547"
    
    # Mostrar interfaz donde escucha
    INTERFACE=$(echo "$PORT_CHECK" | awk '{print $5}' | head -1)
    if [ -n "$INTERFACE" ]; then
        echo "   📡 Escuchando en: $INTERFACE"
    fi
    
    # Mostrar detalles del socket
    SOCKET_COUNT=$(echo "$PORT_CHECK" | wc -l)
    echo "   🔌 Sockets activos: $SOCKET_COUNT"
else
    echo "❌ DHCPv6 NO escuchando en puerto 547"
    
    # Verificar si el servicio está corriendo pero no escucha
    if systemctl is-active --quiet isc-dhcp-server6; then
        echo "   ⚠️  Servicio activo pero no escucha en puerto 547"
        echo "   💡 Ver logs: sudo journalctl -u isc-dhcp-server6 -n 20"
    else
        echo "   ⚠️  Servicio no está activo"
        echo "   💡 Ejecuta: sudo systemctl start isc-dhcp-server6"
    fi
    ((ERRORS++))
fi

echo ""
echo "📝 Archivos de configuración:"
if [ -f "/etc/dhcp/dhcpd6.conf" ]; then
    echo "✅ dhcpd6.conf existe"
    if grep -q "2025:db8:10::" /etc/dhcp/dhcpd6.conf; then
        echo "✅ Configuración de red correcta"
    else
        echo "❌ Configuración de red incorrecta"
        ((ERRORS++))
    fi
else
    echo "❌ dhcpd6.conf NO existe"
    ((ERRORS++))
fi

echo ""
echo "📂 Archivo de leases:"
if [ -f "/var/lib/dhcp/dhcpd6.leases" ]; then
    echo "✅ dhcpd6.leases existe"
else
    echo "❌ dhcpd6.leases NO existe"
    ((ERRORS++))
fi

echo ""
if [ $ERRORS -eq 0 ]; then
    echo "✅ DHCPv6 configurado correctamente"
    exit 0
else
    echo "❌ Hay $ERRORS problemas de configuración"
    exit 1
fi
