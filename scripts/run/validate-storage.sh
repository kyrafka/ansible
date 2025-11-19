#!/bin/bash
# Script para validar el almacenamiento NFS
# Ejecutar: bash scripts/run/validate-storage.sh

echo "════════════════════════════════════════════════════════"
echo "🔍 Validando Almacenamiento NFS"
echo "════════════════════════════════════════════════════════"
echo ""

ERRORS=0

# Verificar servicio NFS (puede ser nfs-server o nfs-kernel-server)
echo "🔧 Servicio NFS:"
if systemctl is-active --quiet nfs-kernel-server || systemctl is-active --quiet nfs-server; then
    echo "✅ NFS server está activo"
    SERVICE_NAME=$(systemctl is-active --quiet nfs-kernel-server && echo "nfs-kernel-server" || echo "nfs-server")
    echo "   📦 Servicio: $SERVICE_NAME"
else
    echo "❌ NFS server NO está activo"
    echo "   💡 Ejecuta: sudo systemctl start nfs-kernel-server"
    ((ERRORS++))
fi

if systemctl is-enabled --quiet nfs-kernel-server || systemctl is-enabled --quiet nfs-server; then
    echo "✅ NFS server habilitado al inicio"
else
    echo "❌ NFS server NO habilitado al inicio"
    echo "   💡 Ejecuta: sudo systemctl enable nfs-kernel-server"
    ((ERRORS++))
fi

echo ""
echo "📂 Directorios NFS:"
if [ -d "/srv/nfs/games" ]; then
    echo "✅ /srv/nfs/games existe"
    ls -ld /srv/nfs/games | awk '{print "   Permisos:", $1, "Propietario:", $3":"$4}'
else
    echo "❌ /srv/nfs/games NO existe"
    ((ERRORS++))
fi

if [ -d "/srv/nfs/shared" ]; then
    echo "✅ /srv/nfs/shared existe"
    ls -ld /srv/nfs/shared | awk '{print "   Permisos:", $1, "Propietario:", $3":"$4}'
else
    echo "❌ /srv/nfs/shared NO existe"
    ((ERRORS++))
fi

echo ""
echo "📝 Exports NFS:"
if [ -f "/etc/exports" ]; then
    echo "✅ /etc/exports existe"
    if grep -q "/srv/nfs/games" /etc/exports; then
        echo "✅ /srv/nfs/games exportado"
    else
        echo "❌ /srv/nfs/games NO exportado"
        ((ERRORS++))
    fi
    if grep -q "/srv/nfs/shared" /etc/exports; then
        echo "✅ /srv/nfs/shared exportado"
    else
        echo "❌ /srv/nfs/shared NO exportado"
        ((ERRORS++))
    fi
else
    echo "❌ /etc/exports NO existe"
    ((ERRORS++))
fi

echo ""
echo "🌐 Exports activos:"
if showmount -e localhost 2>/dev/null | grep -q "/srv/nfs"; then
    echo "✅ NFS exports activos:"
    showmount -e localhost | grep "/srv/nfs" | sed 's/^/   /'
else
    echo "❌ No hay exports NFS activos"
    ((ERRORS++))
fi

echo ""
if [ $ERRORS -eq 0 ]; then
    echo "✅ NFS configurado correctamente"
    exit 0
else
    echo "❌ Hay $ERRORS problemas de configuración"
    exit 1
fi
