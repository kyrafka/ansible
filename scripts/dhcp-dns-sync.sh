#!/bin/bash
# Script para sincronizar clientes DHCP con DNS automáticamente

LEASE_FILE="/var/lib/dhcp/dhcpd6.leases"
DNS_ZONE="gamecenter.lan"
DNS_KEY="/etc/bind/dhcp-key.key"
LOG_FILE="/var/log/dhcp-dns-sync.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "🔄 Iniciando sincronización DHCP → DNS"

# Verificar que el archivo de leases existe
if [ ! -f "$LEASE_FILE" ]; then
    log "❌ Archivo de leases no existe: $LEASE_FILE"
    exit 1
fi

# Leer leases activos
ACTIVE_LEASES=$(grep -A 20 "^ia-na" "$LEASE_FILE" | grep -E "iaaddr|client-hostname" | paste -d " " - -)

# Contador
ADDED=0
FAILED=0

# Procesar cada lease
while IFS= read -r line; do
    # Extraer IP
    IP=$(echo "$line" | grep -oP 'iaaddr \K[0-9a-f:]+')
    # Extraer hostname
    HOSTNAME=$(echo "$line" | grep -oP 'client-hostname "\K[^"]+')
    
    if [ -n "$IP" ] && [ -n "$HOSTNAME" ]; then
        log "→ Procesando: $HOSTNAME → $IP"
        
        # Verificar si ya existe en DNS
        EXISTING=$(dig @127.0.0.1 "$HOSTNAME.$DNS_ZONE" AAAA +short 2>/dev/null)
        
        if [ "$EXISTING" == "$IP" ]; then
            log "  ✓ Ya existe y es correcto"
            continue
        fi
        
        # Agregar/actualizar en DNS
        nsupdate -k "$DNS_KEY" <<EOF
server 127.0.0.1
zone $DNS_ZONE
update delete $HOSTNAME.$DNS_ZONE AAAA
update add $HOSTNAME.$DNS_ZONE 300 AAAA $IP
send
EOF
        
        if [ $? -eq 0 ]; then
            log "  ✅ Agregado: $HOSTNAME.$DNS_ZONE → $IP"
            ((ADDED++))
        else
            log "  ❌ Error al agregar: $HOSTNAME.$DNS_ZONE"
            ((FAILED++))
        fi
    fi
done <<< "$ACTIVE_LEASES"

# Sincronizar zona
rndc sync -clean > /dev/null 2>&1

log "✅ Sincronización completada: $ADDED agregados, $FAILED fallidos"
