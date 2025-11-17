#!/bin/bash
# Script para configurar VM Ubuntu con IPv6 únicamente (SIN tocar resolv.conf)

echo "════════════════════════════════════════"
echo "🖥️  Configurando VM Ubuntu para IPv6"
echo "════════════════════════════════════════"
echo ""

# Detectar interfaz
if [ -n "$1" ]; then
    IFACE=$1
else
    IFACE=$(ip -6 addr show | grep "2025:db8:10" | head -1 | awk '{print $NF}')
    if [ -z "$IFACE" ]; then
        IFACE=$(ip -o link show | grep -v "lo:" | grep "state UP" | head -1 | awk '{print $2}' | sed 's/://')
    fi
fi

echo "📡 Interfaz: $IFACE"
echo ""

echo "1️⃣  Verificando IP actual..."
IPV6_ADDR=$(ip -6 addr show $IFACE | grep "2025:db8:10" | grep "scope global" | awk '{print $2}')
echo "   IP actual: $IPV6_ADDR"
echo ""

echo "2️⃣  Cambiando máscara de /128 a /64..."
IPV6_ONLY=$(echo $IPV6_ADDR | cut -d'/' -f1)
if [[ $IPV6_ADDR == *"/128"* ]]; then
    sudo ip -6 addr del ${IPV6_ADDR} dev $IFACE 2>/dev/null || true
    sudo ip -6 addr add ${IPV6_ONLY}/64 dev $IFACE
    echo "   ✅ Cambiado a /64"
else
    echo "   ℹ️  Ya tiene /64"
fi
echo ""

echo "3️⃣  Detectando gateway..."
GATEWAY=$(ip -6 route | grep default | awk '{print $3}')
echo "   Gateway: $GATEWAY"
echo ""

echo "4️⃣  Agregando ruta NAT64..."
sudo ip -6 route add 64:ff9b::/96 via $GATEWAY dev $IFACE 2>/dev/null && echo "   ✅ Ruta agregada" || echo "   ℹ️  Ruta ya existe"
echo ""

echo "5️⃣  Creando script de post-configuración..."
sudo bash -c "cat > /usr/local/bin/setup-ipv6-routes.sh << 'EOFSCRIPT'
#!/bin/bash
sleep 5
IFACE=\$(ip -6 addr show | grep \"2025:db8:10\" | head -1 | awk '{print \$NF}')
if [ -z \"\$IFACE\" ]; then
    IFACE=\$(ip -o link show | grep -v \"lo:\" | grep \"state UP\" | head -1 | awk '{print \$2}' | sed 's/://')
fi
IPV6_ADDR=\$(ip -6 addr show \$IFACE | grep \"2025:db8:10\" | grep \"scope global\" | awk '{print \$2}')
IPV6_ONLY=\$(echo \$IPV6_ADDR | cut -d'/' -f1)
if [[ \$IPV6_ADDR == *\"/128\"* ]]; then
    ip -6 addr del \${IPV6_ADDR} dev \$IFACE 2>/dev/null || true
    ip -6 addr add \${IPV6_ONLY}/64 dev \$IFACE 2>/dev/null || true
fi
GATEWAY=\$(ip -6 route | grep default | awk '{print \$3}')
ip -6 route add 64:ff9b::/96 via \$GATEWAY dev \$IFACE 2>/dev/null || true
EOFSCRIPT"

sudo chmod +x /usr/local/bin/setup-ipv6-routes.sh
echo "   ✅ Script creado"
echo ""

echo "6️⃣  Creando servicio systemd..."
sudo bash -c 'cat > /etc/systemd/system/ipv6-routes.service << EOF
[Unit]
Description=Setup IPv6 Routes for NAT64
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/setup-ipv6-routes.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF'

sudo systemctl daemon-reload
sudo systemctl enable ipv6-routes.service
echo "   ✅ Servicio habilitado"
echo ""

echo "════════════════════════════════════════"
echo "🧪 Verificando configuración"
echo "════════════════════════════════════════"
echo ""

echo "📋 IP configurada:"
ip -6 addr show $IFACE | grep "2025:db8:10"
echo ""

echo "📋 Rutas:"
ip -6 route | grep -E "default|64:ff9b|2025:db8:10"
echo ""

echo "🧪 Ping al servidor:"
ping6 -c 3 2025:db8:10::2
echo ""

echo "🧪 Ping NAT64:"
ping6 -c 3 64:ff9b::8.8.8.8
echo ""

echo "7️⃣  Configurando proxy del servidor..."
# Variables de entorno para terminal
sudo bash -c 'cat >> /etc/environment << EOF
http_proxy="http://[2025:db8:10::2]:3128"
https_proxy="http://[2025:db8:10::2]:3128"
HTTP_PROXY="http://[2025:db8:10::2]:3128"
HTTPS_PROXY="http://[2025:db8:10::2]:3128"
no_proxy="localhost,127.0.0.1,2025:db8:10::/64"
NO_PROXY="localhost,127.0.0.1,2025:db8:10::/64"
EOF'

# Configuración de APT para usar proxy
sudo bash -c 'cat > /etc/apt/apt.conf.d/95proxies << EOF
Acquire::http::Proxy "http://[2025:db8:10::2]:3128";
Acquire::https::Proxy "http://[2025:db8:10::2]:3128";
EOF'

echo "   ✅ Proxy configurado"
echo ""

echo "════════════════════════════════════════"
if ping6 -c 1 64:ff9b::8.8.8.8 &>/dev/null; then
    echo "✅ NAT64 funciona - Tienes internet IPv6"
else
    echo "⚠️  NAT64 no funciona - Verifica el servidor"
fi
echo ""
echo "📋 Para usar el proxy en el navegador:"
echo "   Settings > Network > Manual Proxy"
echo "   HTTP Proxy: 2025:db8:10::2"
echo "   Port: 3128"
echo "════════════════════════════════════════"
