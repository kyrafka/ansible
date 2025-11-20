#!/bin/bash

echo "════════════════════════════════════════════════════════════════"
echo "🔧 ARREGLAR DNS64 - FILTRAR AAAA DE INTERNET"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Este script configura BIND para filtrar respuestas AAAA de internet"
echo "forzando que DNS64 traduzca TODO a través de NAT64."
echo ""

# Backup de configuración actual
echo "📋 Haciendo backup de configuración actual..."
sudo cp /etc/bind/named.conf.options /etc/bind/named.conf.options.backup-$(date +%Y%m%d-%H%M%S)

# Crear nueva configuración
echo "📝 Creando nueva configuración DNS64..."
sudo tee /etc/bind/named.conf.options > /dev/null << 'EOF'
# Configuración común
acl clients-ipv6 {
    2025:db8:10::/64;
    localhost;
};

# Opciones globales
options {
    directory "/var/cache/bind";
    
    // Forwarders
    forwarders {
        8.8.8.8;
        8.8.4.4;
        1.1.1.1;
        1.0.0.1;
    };
    
    // Configuración de seguridad
    dnssec-validation no;
    
    // Configuración de red
    listen-on-v6 { any; };
    listen-on { any; };
    
    // DNS64: Traduce respuestas IPv4 a IPv6
    dns64 64:ff9b::/96 {
        clients { any; };
        mapped { any; };
        exclude { 2025:db8:10::/64; ::ffff:0:0/96; };
        recursive-only yes;
        break-dnssec yes;
    };
    
    // CLAVE: Filtrar respuestas AAAA de internet
    filter-aaaa-on-v4 break-dnssec;
    
    // Permitir consultas
    allow-query { 
        localhost; 
        localnets;
        2025:db8:10::/64;
    };
    
    // Permitir recursión
    recursion yes;
    allow-recursion { 
        localhost; 
        localnets;
        2025:db8:10::/64;
    };
    
    // Configuración de transferencias
    allow-transfer { none; };
    
    // Configuración de notificaciones
    notify no;
    
    // Configuración de versión (seguridad)
    version none;
    hostname none;
    server-id none;
    
    // Configuración para zonas dinámicas
    ixfr-from-differences yes;
};
EOF

echo "✓ Configuración creada"
echo ""

# Verificar configuración
echo "🔍 Verificando configuración..."
if sudo named-checkconf; then
    echo "✅ Configuración válida"
else
    echo "❌ Error en configuración"
    echo "Restaurando backup..."
    sudo cp /etc/bind/named.conf.options.backup-* /etc/bind/named.conf.options
    exit 1
fi

# Reiniciar BIND
echo ""
echo "🔄 Reiniciando BIND9..."
sudo systemctl restart bind9

# Verificar que inició
sleep 2
if sudo systemctl is-active --quiet bind9; then
    echo "✅ BIND9 activo"
else
    echo "❌ BIND9 falló al iniciar"
    sudo journalctl -u bind9 -n 20
    exit 1
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✅ DNS64 CONFIGURADO CON FILTRO AAAA"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "🧪 Prueba ahora:"
echo ""
echo "  # Desde el servidor"
echo "  dig @localhost google.com AAAA"
echo "  # Debería devolver 64:ff9b::..."
echo ""
echo "  # Desde el cliente"
echo "  ping6 google.com"
echo "  curl -6 http://google.com"
echo "  firefox http://www.google.com"
echo ""
echo "════════════════════════════════════════════════════════════════"
