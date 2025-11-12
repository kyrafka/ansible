#!/bin/bash
# Sincronización automática de clientes DHCP a DNS

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

# Verificar que la clave existe
if [ ! -f "$DNS_KEY" ]; then
    log "❌ Clave DNS no existe: $DNS_KEY"
    exit 1
fi

# Contador
ADDED=0
UPDATED=0
SKIPPED=0
FAILED=0

# Extraer leases activos (ia-na con iaaddr)
log "📋 Leyendo leases activos..."

# Procesar leases
while read -r line; do
    if echo "$line" | grep -q "iaaddr"; then
        IP=$(echo "$line" | grep -oP 'iaaddr \K[0-9a-f:]+')
        CURRENT_IP="$IP"
    fi
    
    if echo "$line" | grep -q "client-hostname"; then
        HOSTNAME=$(echo "$line" | grep -oP 'client-hostname "\K[^"]+')
        
        if [ -n "$CURRENT_IP" ] && [ -n "$HOSTNAME" ]; then
            log "→ Procesando: $HOSTNAME → $CURRENT_IP"
            
            # Verificar si ya existe en DNS
            EXISTING=$(dig @127.0.0.1 "$HOSTNAME.$DNS_ZONE" AAAA +short 2>/dev/null | head -n1)
            
            if [ "$EXISTING" == "$CURRENT_IP" ]; then
                log "  ✓ Ya existe y es correcto"
                ((SKIPPED++))
            else
                # Agregar/actualizar en DNS
                nsupdate -k "$DNS_KEY" <<EOF
server 127.0.0.1
zone $DNS_ZONE
update delete $HOSTNAME.$DNS_ZONE AAAA
update add $HOSTNAME.$DNS_ZONE 86400 AAAA $CURRENT_IP
send
EOF
                
                if [ $? -eq 0 ]; then
                    if [ -n "$EXISTING" ]; then
                        log "  ✅ Actualizado: $HOSTNAME.$DNS_ZONE ($EXISTING → $CURRENT_IP)"
                        ((UPDATED++))
                    else
                        log "  ✅ Agregado: $HOSTNAME.$DNS_ZONE → $CURRENT_IP"
                        ((ADDED++))
                    fi
                else
                    log "  ❌ Error al actualizar: $HOSTNAME.$DNS_ZONE"
                    ((FAILED++))
                fi
            fi
            
            # Reset
            CURRENT_IP=""
            HOSTNAME=""
        fi
    fi
done < <(grep -A 5 "iaaddr" "$LEASE_FILE")

# Sincronizar zona
log "🔄 Sincronizando zona DNS..."
rndc sync -clean > /dev/null 2>&1

log "✅ Sincronización completada:"
log "   → Agregados: $ADDED"
log "   → Actualizados: $UPDATED"
log "   → Sin cambios: $SKIPPED"
log "   → Fallidos: $FAILED"
