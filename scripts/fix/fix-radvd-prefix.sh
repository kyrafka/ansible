#!/bin/bash

echo "════════════════════════════════════════════════════════════════"
echo "🔧 CORREGIR CONFIGURACIÓN DE RADVD Y PREFIJO IPv6"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script debe ejecutarse como root"
    echo "   Usa: sudo bash $0"
    exit 1
fi

echo "Paso 1: Verificando configuración actual"
echo "────────────────────────────────────────────────────────"

echo "Configuración de RADVD actual:"
if [ -f "/etc/radvd.conf" ]; then
    cat /etc/radvd.conf
else
    echo "❌ /etc/radvd.conf no existe"
    exit 1
fi

echo ""
echo "Paso 2: Verificando interfaz de red"
echo "────────────────────────────────────────────────────────"

# Detectar interfaz LAN
LAN_INTERFACE=$(ip -6 addr show | grep "2025:db8:10" | awk '{print $NF}' | head -1)

if [ -z "$LAN_INTERFACE" ]; then
    echo "❌ No se encontró interfaz con red 2025:db8:10::/64"
    echo ""
    echo "Interfaces disponibles:"
    ip -6 addr show
    exit 1
fi

echo "✓ Interfaz LAN detectada: $LAN_INTERFACE"
echo ""
echo "Configuración actual de $LAN_INTERFACE:"
ip -6 addr show $LAN_INTERFACE

echo ""
echo "Paso 3: Corrigiendo configuración de RADVD"
echo "────────────────────────────────────────────────────────"

# Crear configuración correcta de RADVD
cat > /etc/radvd.conf << 'EOF'
# Configuración de radvd para anunciar red IPv6
# Red: 2025:db8:10::/64

interface ens34
{
    # Enviar Router Advertisements
    AdvSendAdvert on;
    
    # Intervalo entre anuncios (en segundos)
    MinRtrAdvInterval 3;
    MaxRtrAdvInterval 10;
    
    # Anunciar este router como gateway por defecto
    AdvDefaultLifetime 1800;
    AdvDefaultPreference high;
    
    # Prefijo de red IPv6 - CORRECTO CON /64
    prefix 2025:db8:10::/64
    {
        # El prefijo está en el mismo enlace
        AdvOnLink on;
        
        # DESACTIVAR SLAAC - Solo usar DHCPv6
        # Los clientes NO pueden autoconfigurar sus IPs
        AdvAutonomous off;
        
        # Tiempo de vida del prefijo
        AdvValidLifetime 3600;
        AdvPreferredLifetime 1800;
    };
    
    # Flags para forzar DHCPv6
    # M = Managed (obtener IP por DHCPv6)
    # O = Other (obtener DNS/dominio por DHCPv6)
    AdvManagedFlag on;
    AdvOtherConfigFlag on;
    
    # Servidor DNS recursivo
    RDNSS 2025:db8:10::1
    {
        AdvRDNSSLifetime 300;
    };
    
    # Dominio de búsqueda DNS
    DNSSL gamecenter.lan
    {
        AdvDNSSLLifetime 300;
    };
};
EOF

echo "✓ Configuración de RADVD actualizada"

echo ""
echo "Paso 4: Reiniciando RADVD"
echo "────────────────────────────────────────────────────────"

systemctl restart radvd

if [ $? -eq 0 ]; then
    echo "✓ RADVD reiniciado correctamente"
else
    echo "❌ Error al reiniciar RADVD"
    systemctl status radvd
    exit 1
fi

sleep 2

echo ""
echo "Paso 5: Verificando estado de RADVD"
echo "────────────────────────────────────────────────────────"

systemctl status radvd --no-pager

echo ""
echo "Paso 6: Verificando anuncios de Router Advertisement"
echo "────────────────────────────────────────────────────────"

echo "Esperando anuncios RA (10 segundos)..."
timeout 10 radvdump 2>/dev/null || echo "⚠️  No se pudieron capturar anuncios RA"

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✅ CONFIGURACIÓN DE RADVD CORREGIDA"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "📋 Configuración aplicada:"
echo "  • Red: 2025:db8:10::/64"
echo "  • Gateway: 2025:db8:10::1"
echo "  • DNS: 2025:db8:10::1"
echo "  • Prefijo: /64 (correcto)"
echo "  • DHCPv6: Habilitado (Managed + Other)"
echo ""
echo "🔄 AHORA EN LOS CLIENTES:"
echo ""
echo "  Windows 11:"
echo "    1. Abre PowerShell como Administrador"
echo "    2. Ejecuta:"
echo "       ipconfig /release6"
echo "       ipconfig /renew6"
echo "    3. Verifica con: ipconfig /all"
echo "    4. Deberías ver: 2025:db8:10::XXX/64"
echo ""
echo "  Ubuntu Desktop:"
echo "    1. Ejecuta:"
echo "       sudo dhclient -6 -r ens33"
echo "       sudo dhclient -6 ens33"
echo "    2. Verifica con: ip -6 addr show"
echo "    3. Deberías ver: 2025:db8:10::XXX/64"
echo ""
echo "════════════════════════════════════════════════════════════════"
