#!/bin/bash
# Script para actualizar DNS desde archivo de hosts

HOSTS_FILE="${1:-dns-hosts.txt}"
DNS_ZONE="gamecenter.lan"
DNS_KEY="/etc/bind/dhcp-key.key"

if [ ! -f "$HOSTS_FILE" ]; then
    echo "❌ Archivo no encontrado: $HOSTS_FILE"
    echo "Uso: $0 [archivo-hosts]"
    exit 1
fi

echo "════════════════════════════════════════════════════════"
echo "📝 Actualizando DNS desde: $HOSTS_FILE"
echo "════════════════════════════════════════════════════════"
echo ""

ADDED=0
FAILED=0

# Leer archivo línea por línea
while IFS=',' read -r hostname ipv6 || [ -n "$hostname" ]; do
    # Ignorar comentarios y líneas vacías
    [[ "$hostname" =~ ^#.*$ ]] && continue
    [[ -z "$hostname" ]] && continue
    
    # Limpiar espacios
    hostname=$(echo "$hostname" | xargs)
    ipv6=$(echo "$ipv6" | xargs)
    
    if [ -z "$ipv6" ]; then
        echo "⚠️  Saltando línea inválida: $hostname"
        continue
    fi
    
    echo "→ Procesando: $hostname.$DNS_ZONE → $ipv6"
    
    # Verificar si ya existe
    EXISTING=$(dig @127.0.0.1 "$hostname.$DNS_ZONE" AAAA +short 2>/dev/null)
    
    if [ "$EXISTING" == "$ipv6" ]; then
        echo "  ✓ Ya existe y es correcto"
        continue
    fi
    
    # Actualizar DNS
    nsupdate -k "$DNS_KEY" <<EOF
server 127.0.0.1
zone $DNS_ZONE
update delete $hostname.$DNS_ZONE AAAA
update add $hostname.$DNS_ZONE 86400 AAAA $ipv6
send
EOF
    
    if [ $? -eq 0 ]; then
        echo "  ✅ Actualizado"
        ((ADDED++))
    else
        echo "  ❌ Error"
        ((FAILED++))
    fi
    
done < "$HOSTS_FILE"

# Sincronizar
echo ""
echo "🔄 Sincronizando zona..."
sudo rndc sync -clean > /dev/null 2>&1

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ Completado: $ADDED actualizados, $FAILED fallidos"
echo "════════════════════════════════════════════════════════"
echo ""
echo "🧪 Prueba con:"
echo "   dig @127.0.0.1 <hostname>.gamecenter.lan AAAA"
