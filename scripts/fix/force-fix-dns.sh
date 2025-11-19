#!/bin/bash
# Script para forzar la corrección del DNS
# Ejecutar: sudo bash scripts/fix/force-fix-dns.sh

echo "════════════════════════════════════════════════════════"
echo "🔧 Corrección FORZADA de DNS"
echo "════════════════════════════════════════════════════════"
echo ""

# Verificar si somos root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script debe ejecutarse como root"
    echo "   Usa: sudo bash $0"
    exit 1
fi

echo "1️⃣  Deteniendo todos los servicios DNS..."
systemctl stop bind9 2>/dev/null || true
systemctl stop named 2>/dev/null || true
systemctl stop systemd-resolved 2>/dev/null || true
sleep 2
echo "✅ Servicios detenidos"
echo ""

echo "2️⃣  Verificando puerto 53..."
PORT_CHECK=$(ss -tulpn | grep ":53 " || true)

if [ -n "$PORT_CHECK" ]; then
    echo "⚠️  Aún hay algo en puerto 53:"
    echo "$PORT_CHECK"
    echo ""
    
    # Intentar matar procesos en puerto 53
    echo "🔪 Matando procesos en puerto 53..."
    fuser -k 53/tcp 2>/dev/null || true
    fuser -k 53/udp 2>/dev/null || true
    sleep 2
    echo "✅ Procesos terminados"
else
    echo "✅ Puerto 53 libre"
fi
echo ""

echo "3️⃣  Configurando systemd-resolved..."
mkdir -p /etc/systemd/resolved.conf.d/

cat > /etc/systemd/resolved.conf.d/dns.conf << 'EOF'
[Resolve]
DNSStubListener=no
DNS=127.0.0.1
FallbackDNS=8.8.8.8 1.1.1.1
EOF

echo "✅ Configuración creada"
echo ""

echo "4️⃣  Iniciando systemd-resolved (sin puerto 53)..."
systemctl daemon-reload
systemctl restart systemd-resolved
sleep 2

if systemctl is-active --quiet systemd-resolved; then
    echo "✅ systemd-resolved activo (sin usar puerto 53)"
else
    echo "⚠️  systemd-resolved no inició, pero continuamos..."
fi
echo ""

echo "5️⃣  Verificando puerto 53 de nuevo..."
if ss -tulpn | grep -q ":53 "; then
    echo "❌ Puerto 53 aún ocupado:"
    ss -tulpn | grep ":53 "
    echo ""
    echo "💡 Intenta reiniciar el servidor:"
    echo "   sudo reboot"
    exit 1
else
    echo "✅ Puerto 53 completamente libre"
fi
echo ""

echo "6️⃣  Verificando configuración de BIND9..."
if ! named-checkconf 2>/dev/null; then
    echo "❌ Configuración de BIND9 tiene errores"
    echo ""
    echo "Ejecuta primero el rol de DNS:"
    echo "   bash scripts/run/run-dns.sh"
    exit 1
else
    echo "✅ Configuración de BIND9 válida"
fi
echo ""

echo "7️⃣  Iniciando BIND9..."
systemctl enable bind9
systemctl start bind9
sleep 3

if systemctl is-active --quiet bind9; then
    echo "✅ BIND9 iniciado correctamente"
else
    echo "❌ BIND9 falló al iniciar"
    echo ""
    echo "📋 Logs de error:"
    journalctl -u bind9 -n 30 --no-pager
    exit 1
fi
echo ""

echo "8️⃣  Verificando que BIND9 escucha en puerto 53..."
sleep 2

if ss -tulpn | grep -q ":53.*named"; then
    echo "✅ BIND9 escuchando en puerto 53"
    echo ""
    echo "📊 Puertos DNS activos:"
    ss -tulpn | grep ":53.*named"
else
    echo "❌ BIND9 NO está escuchando en puerto 53"
    echo ""
    echo "📊 Estado de puertos:"
    ss -tulpn | grep ":53"
    echo ""
    echo "📋 Estado del servicio:"
    systemctl status bind9 --no-pager -l
    exit 1
fi
echo ""

echo "9️⃣  Probando resolución DNS..."
sleep 2

# Detectar dominio
DOMAIN=$(grep -r "domain_name:" group_vars/all.yml 2>/dev/null | grep -v "^#" | awk '{print $2}' | tr -d '"' | head -n1)
if [ -z "$DOMAIN" ]; then
    DOMAIN="gamecenter.lan"
fi

DNS_TEST=$(dig @localhost "$DOMAIN" AAAA +short 2>/dev/null | head -1)

if [ -n "$DNS_TEST" ]; then
    echo "✅ DNS resuelve $DOMAIN → $DNS_TEST"
else
    echo "⚠️  DNS no resuelve $DOMAIN aún"
    echo ""
    echo "Recargando zonas..."
    rndc reload
    sleep 3
    
    DNS_TEST=$(dig @localhost "$DOMAIN" AAAA +short 2>/dev/null | head -1)
    if [ -n "$DNS_TEST" ]; then
        echo "✅ Ahora sí resuelve: $DNS_TEST"
    else
        echo "❌ Aún no resuelve"
        echo ""
        echo "📋 Verificar zona:"
        echo "   sudo cat /var/lib/bind/db.$DOMAIN"
        echo "   sudo named-checkzone $DOMAIN /var/lib/bind/db.$DOMAIN"
    fi
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ Corrección de DNS completada"
echo "════════════════════════════════════════════════════════"
echo ""
echo "🧪 Pruebas adicionales:"
echo "   dig @localhost $DOMAIN AAAA"
echo "   dig @localhost google.com AAAA"
echo "   bash scripts/run/validate-dns.sh"
echo ""
echo "📊 Ver estado:"
echo "   systemctl status bind9"
echo "   sudo ss -tulpn | grep :53"
echo ""
