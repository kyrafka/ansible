#!/bin/bash
# Script para crear el archivo .vault_pass
# Ejecutar: bash scripts/setup-vault-pass.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

echo "════════════════════════════════════════════════════════"
echo "🔐 Configuración de Contraseña del Vault"
echo "════════════════════════════════════════════════════════"
echo ""

# Verificar si ya existe
if [ -f ".vault_pass" ]; then
    echo "⚠️  El archivo .vault_pass ya existe"
    echo ""
    read -p "¿Deseas sobrescribirlo? (s/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        echo "❌ Cancelado"
        exit 0
    fi
fi

echo "Ingresa la contraseña del vault:"
echo "(Por defecto es: ubuntu123)"
echo ""
read -s -p "Contraseña: " VAULT_PASS
echo ""

if [ -z "$VAULT_PASS" ]; then
    echo "❌ Error: La contraseña no puede estar vacía"
    exit 1
fi

# Crear archivo
echo "$VAULT_PASS" > .vault_pass
chmod 600 .vault_pass

echo ""
echo "✅ Archivo .vault_pass creado correctamente"
echo ""

# Verificar que funciona
echo "🧪 Verificando que la contraseña es correcta..."
if ansible-vault view group_vars/all.vault.yml --vault-password-file .vault_pass &> /dev/null; then
    echo "✅ Contraseña correcta!"
    echo ""
    echo "Ahora puedes ejecutar los scripts sin que pidan contraseña:"
    echo "  bash scripts/run/run-dns.sh"
    echo "  bash scripts/run/run-dhcp.sh"
    echo "  bash scripts/run/run-network.sh"
else
    echo "❌ Error: La contraseña es incorrecta"
    echo ""
    echo "Intenta de nuevo con la contraseña correcta"
    rm -f .vault_pass
    exit 1
fi
