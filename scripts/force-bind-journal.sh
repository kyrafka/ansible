#!/bin/bash
# Script para forzar a BIND a crear y usar journals

echo "🔧 Forzando creación de journals en BIND..."

# Detener BIND
echo "→ Deteniendo BIND..."
sudo systemctl stop bind9

# Asegurar permisos correctos
echo "→ Configurando permisos..."
sudo chown -R bind:bind /var/lib/bind/
sudo chmod 775 /var/lib/bind/

# Eliminar journals viejos
echo "→ Limpiando journals antiguos..."
sudo rm -f /var/lib/bind/*.jnl

# Iniciar BIND
echo "→ Iniciando BIND..."
sudo systemctl start bind9

# Esperar
sleep 5

# Verificar
echo "→ Verificando estado..."
systemctl status bind9 --no-pager | head -n 10

echo ""
echo "✅ BIND reiniciado"
echo ""
echo "🧪 Probando actualización..."

# Probar actualización
nsupdate -k /etc/bind/dhcp-key.key <<EOF
server 127.0.0.1
zone gamecenter.lan
update add force-test.gamecenter.lan 60 AAAA 2025:db8:10::8888
send
EOF

if [ $? -eq 0 ]; then
    echo "✅ nsupdate exitoso"
    
    # Esperar
    sleep 2
    
    # Verificar journal
    if [ -f /var/lib/bind/db.gamecenter.lan.jnl ]; then
        echo "✅ Journal creado"
        ls -lh /var/lib/bind/db.gamecenter.lan.jnl
    else
        echo "❌ Journal NO se creó"
    fi
    
    # Probar DNS
    RESULT=$(dig @127.0.0.1 force-test.gamecenter.lan AAAA +short)
    if [ -n "$RESULT" ]; then
        echo "✅ DNS funciona: $RESULT"
    else
        echo "❌ DNS no devuelve el registro"
    fi
else
    echo "❌ nsupdate falló"
fi
