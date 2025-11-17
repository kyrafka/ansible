#!/bin/bash
# Script para configurar Ubuntu Desktop como cliente IPv6

echo "════════════════════════════════════════"
echo "🖥️  Configurando Ubuntu Desktop Cliente"
echo "════════════════════════════════════════"
echo ""

# Detectar o especificar interfaz de red
if [ -n "$1" ]; then
    IFACE=$1
    echo "📡 Interfaz especificada: $IFACE"
else
    echo "📡 Interfaces disponibles:"
    ip -o link show | grep -v "lo:" | awk '{print "   ", $2, $9}'
    echo ""
    
    # Detectar interfaz con IPv6 de la red 2025:db8:10
    IFACE=$(ip -6 addr show | grep "2025:db8:10" | head -1 | awk '{print $NF}')
    
    if [ -z "$IFACE" ]; then
        # Si no hay IPv6 asignada, tomar la primera interfaz UP
        IFACE=$(ip -o link show | grep -v "lo:" | grep "state UP" | head -1 | awk '{print $2}' | sed 's/://')
    fi
    
    if [ -z "$IFACE" ]; then
        echo "❌ No se detectó ninguna interfaz de red"
        exit 1
    fi
    
    echo "📡 Interfaz detectada: $IFACE"
fi
echo ""

echo "1️⃣  Deshabilitando systemd-resolved..."
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved
sudo rm -f /etc/resolv.conf

echo "2️⃣  Configurando DNS del servidor..."
sudo bash -c 'cat > /etc/resolv.conf << EOF
nameserver 2025:db8:10::2
search gamecenter.lan
EOF'

echo "3️⃣  Protegiendo resolv.conf..."
sudo chattr +i /etc/resolv.conf

echo "4️⃣  Configurando hostname..."
HOSTNAME=$(hostname)
sudo bash -c "echo '127.0.0.1 $HOSTNAME' >> /etc/hosts"
sudo bash -c "echo '::1 $HOSTNAME' >> /etc/hosts"

echo "5️⃣  Renovando DHCP IPv6..."
sudo dhclient -6 -r $IFACE 2>/dev/null || true
sleep 2
sudo dhclient -6 $IFACE

echo "6️⃣  Esperando asignación de IP..."
sleep 3

echo "7️⃣  Cambiando máscara de /128 a /64..."
IPV6_ADDR=$(ip -6 addr show $IFACE | grep "2025:db8:10" | grep "scope global" | awk '{print $2}' | cut -d'/' -f1)
if [ -n "$IPV6_ADDR" ]; then
    echo "   IP detectada: $IPV6_ADDR"
    sudo ip -6 addr del ${IPV6_ADDR}/128 dev $IFACE 2>/dev/null || true
    sudo ip -6 addr add ${IPV6_ADDR}/64 dev $IFACE
    echo "   ✅ Máscara cambiada a /64"
else
    echo "   ❌ No se detectó IP IPv6"
fi

echo "8️⃣  Detectando gateway..."
GATEWAY=$(ip -6 route | grep default | awk '{print $3}')
echo "   Gateway: $GATEWAY"

echo "9️⃣  Agregando ruta NAT64..."
sudo ip -6 route add 64:ff9b::/96 via $GATEWAY dev $IFACE 2>/dev/null || echo "   (Ruta ya existe)"

echo "🔟 Creando script de post-configuración..."
sudo bash -c "cat > /usr/local/bin/setup-ipv6-client.sh << 'EOF'
#!/bin/bash
IFACE=\$(ip -o link show | grep -v \"lo:\" | head -1 | awk '{print \$2}' | sed 's/://')
sleep 5
IPV6_ADDR=\$(ip -6 addr show \$IFACE | grep \"2025:db8:10\" | grep \"scope global\" | awk '{print \$2}' | cut -d'/' -f1)
if [ -n \"\$IPV6_ADDR\" ]; then
    ip -6 addr del \${IPV6_ADDR}/128 dev \$IFACE 2>/dev/null || true
    ip -6 addr add \${IPV6_ADDR}/64 dev \$IFACE 2>/dev/null || true
fi
GATEWAY=\$(ip -6 route | grep default | awk '{print \$3}')
ip -6 route add 64:ff9b::/96 via \$GATEWAY dev \$IFACE 2>/dev/null || true
EOF"

sudo chmod +x /usr/local/bin/setup-ipv6-client.sh

echo "1️⃣1️⃣  Creando servicio systemd..."
sudo bash -c 'cat > /etc/systemd/system/ipv6-client-setup.service << EOF
[Unit]
Description=IPv6 Client Network Setup
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/setup-ipv6-client.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF'

sudo systemctl daemon-reload
sudo systemctl enable ipv6-client-setup.service

echo ""
echo "════════════════════════════════════════"
echo "🧪 Verificando configuración..."
echo "════════════════════════════════════════"
echo ""

echo "📋 Configuración de red:"
ip -6 addr show $IFACE | grep "2025:db8:10"
echo ""

echo "📋 Rutas IPv6:"
ip -6 route | grep -E "default|64:ff9b|2025:db8:10"
echo ""

echo "📋 DNS:"
cat /etc/resolv.conf
echo ""

echo "🧪 Prueba de conectividad al servidor:"
ping6 -c 3 2025:db8:10::2
echo ""

echo "🧪 Prueba de DNS:"
dig @2025:db8:10::2 google.com AAAA +short | head -3
echo ""

echo "🧪 Prueba de NAT64:"
ping6 -c 3 64:ff9b::8.8.8.8
echo ""

echo "════════════════════════════════════════"
echo "✅ Configuración completada"
echo "════════════════════════════════════════"
echo ""
echo "Si el ping a 64:ff9b::8.8.8.8 funciona, ya tienes internet."
echo "Si no funciona, el problema está en el servidor NAT64."
echo ""
echo "Ahora puedes apagar la VM y cambiar el adaptador a M_vm's"
