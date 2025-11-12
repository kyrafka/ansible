#!/bin/bash
# Script para sincronizar zonas DNS dinámicas

echo "🔄 Sincronizando zonas DNS dinámicas..."

# Sincronizar todas las zonas
sudo rndc sync -clean

# Esperar un momento
sleep 2

# Verificar que BIND está corriendo
if systemctl is-active --quiet bind9; then
    echo "✅ Zonas sincronizadas"
else
    echo "❌ BIND no está corriendo"
    exit 1
fi
