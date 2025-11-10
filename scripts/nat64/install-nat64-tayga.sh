#!/bin/bash
# Script para instalar y configurar Tayga (NAT64)
# Permite que VMs con IPv6-only accedan a internet IPv4

echo "════════════════════════════════════════════════════════"
echo "🌐 Instalando NAT64 con Tayga"
echo "════════════════════════════════════════════════════════"

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script debe ejecutarse como root"
    echo "   Usa: sudo bash $0"
    exit 1
fi

echo "1️⃣  Instalando Tayga..."
apt update
apt install tayga -y

echo "2️⃣  Configurando Tayga..."
cat > /etc/tayga.conf << 'EOF'
# Configuración de Tayga NAT64

# Prefijo IPv6 para NAT64 (debe coincidir con DNS64)
prefix 64:ff9b::/96

# Pool de IPs IPv4 dinámicas para traducción
dynamic-pool 192.168.255.0/24

# Dirección IPv4 del túnel
ipv4-addr 192.168.255.1

# Dirección IPv6 del túnel (requerida para IPs privadas)
ipv6-addr 2025:db8:10::ffff

# Interfaz de túnel
tun-device nat64

# Directorio de datos
data-dir /var/spool/tayga
EOF

echo "3️⃣  Creando directorio de datos..."
mkdir -p /var/spool/tayga
chown tayga:tayga /var/spool/tayga

echo "4️⃣  Configurando interfaz de túnel..."
cat > /etc/network/if-up.d/tayga << 'EOF'
#!/bin/bash
if [ "$IFACE" = "ens34" ]; then
    # Iniciar Tayga
    tayga --mktun
    ip link set nat64 up
    ip addr add 192.168.255.1 dev nat64
    ip addr add 2025:db8:10::ffff dev nat64
    ip route add 192.168.255.0/24 dev nat64
    ip route add 64:ff9b::/96 dev nat64
    tayga
fi
EOF

chmod +x /etc/network/if-up.d/tayga

echo "5️⃣  Iniciando Tayga..."
tayga --mktun
ip link set nat64 up
ip addr add 192.168.255.1 dev nat64
ip addr add 2025:db8:10::ffff dev nat64
ip route add 192.168.255.0/24 dev nat64
ip route add 64:ff9b::/96 dev nat64
tayga

echo "7️⃣  Verificando Tayga..."
sleep 2
if ps aux | grep -v grep | grep tayga > /dev/null; then
    echo "   ✅ Tayga está corriendo"
else
    echo "   ❌ Tayga no se inició correctamente"
    echo "   Ver logs: journalctl -xe"
fi

echo "6️⃣  Configurando NAT para Tayga..."
iptables -t nat -A POSTROUTING -s 192.168.255.0/24 -o ens33 -j MASQUERADE
iptables -A FORWARD -i nat64 -o ens33 -j ACCEPT
iptables -A FORWARD -i ens33 -o nat64 -m state --state RELATED,ESTABLISHED -j ACCEPT

# Guardar reglas
iptables-save > /etc/iptables/rules.v4

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ Tayga NAT64 instalado y configurado"
echo "════════════════════════════════════════════════════════"
echo ""
echo "📋 Verificar:"
echo "   ip addr show nat64"
echo "   ip route | grep 64:ff9b"
echo "   ps aux | grep tayga"
echo ""
echo "📋 Probar desde la VM:"
echo "   ping6 64:ff9b::808:808  # Ping a 8.8.8.8"
echo "   ping6 google.com"
echo ""
