#!/bin/bash
# Script rápido para solucionar problema de puerto 53
# Ejecutar: sudo bash scripts/fix/fix-dns-port53.sh

echo "════════════════════════════════════════════════════════"
echo "🔧 Solucionando problema de puerto 53"
echo "════════════════════════════════════════════════════════"
echo ""

# Verificar si somos root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script debe ejecutarse como root"
    echo "   Usa: sudo bash $0"
    exit 1
fi

echo "1️⃣  Verificando qué está usando el puerto 53..."
echo ""

PORT_USER=$(ss -tulpn | grep ":53" | grep -v "named" | head -1)

if [ -n "$PORT_USER" ]; then
    echo "⚠️  Puerto 53 ocupado por:"
    echo "$PORT_USER"
    echo ""
    
    if echo "$PORT_USER" | grep -q "systemd-resolved"; then
        echo "🔍 Detectado: systemd-resolved está usando el puerto 53"
        echo ""
        echo "2️⃣  Configurando systemd-resolved para liberar puerto 53..."
        
        # Configurar systemd-resolved
        cat > /etc/systemd/resolved.conf << 'EOF'
[Resolve]
DNSStubListener=no
DNS=127.0.0.1 8.8.8.8 8.8.4.4
FallbackDNS=1.1.1.1 1.0.0.1
Domains=gamecenter.lan
EOF
        
        echo "✅ Configuración actualizada"
        echo ""
        
        echo "3️⃣  Reiniciando systemd-resolved..."
        systemctl restart systemd-resolved
        sleep 2
        echo "✅ systemd-resolved reiniciado"
        echo ""
        
        echo "4️⃣  Recreando enlace simbólico de resolv.conf..."
        rm -f /etc/resolv.conf
        ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
        echo "✅ Enlace recreado"
        echo ""
    else
        echo "⚠️  Otro servicio está usando el puerto 53"
        echo "   Debes detenerlo manualmente"
        exit 1
    fi
else
    echo "✅ Puerto 53 está libre"
    echo ""
fi

echo "5️⃣  Reiniciando BIND9..."
systemctl stop bind9
sleep 2
systemctl start bind9
sleep 3

if systemctl is-active --quiet bind9; then
    echo "✅ BIND9 iniciado correctamente"
else
    echo "❌ BIND9 falló al iniciar"
    echo ""
    echo "Ver logs:"
    journalctl -u bind9 -n 20 --no-pager
    exit 1
fi

echo ""
echo "6️⃣  Verificando que BIND9 escucha en puerto 53..."
sleep 2

if ss -tulpn | grep -q ":53.*named"; then
    echo "✅ BIND9 está escuchando en puerto 53"
    echo ""
    ss -tulpn | grep ":53.*named"
else
    echo "❌ BIND9 NO está escuchando en puerto 53"
    echo ""
    echo "Puertos actuales:"
    ss -tulpn | grep ":53"
    exit 1
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ Problema de puerto 53 solucionado"
echo "════════════════════════════════════════════════════════"
echo ""
echo "🧪 Prueba de resolución DNS:"
dig @localhost gamecenter.lan AAAA +short
echo ""
echo "💡 Si no resuelve, ejecuta:"
echo "   sudo rndc reload"
echo "   bash scripts/run/validate-dns.sh"
echo ""
