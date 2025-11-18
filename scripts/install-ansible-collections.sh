#!/bin/bash
# Script para instalar colecciones de Ansible necesarias
# Ejecutar: bash scripts/install-ansible-collections.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

echo "════════════════════════════════════════════════════════"
echo "📦 Instalando Colecciones de Ansible"
echo "════════════════════════════════════════════════════════"
echo ""

# Verificar si ansible-galaxy está disponible
if ! command -v ansible-galaxy &> /dev/null; then
    echo "❌ Error: ansible-galaxy no está instalado"
    echo "Instala Ansible primero con: sudo apt install ansible"
    echo "O ejecuta: bash scripts/setup/setup-ansible-env.sh --auto"
    exit 1
fi

# Crear directorios necesarios
echo "📁 Creando directorios..."
mkdir -p ~/.ansible/collections
mkdir -p ./collections/ansible_collections

echo ""
echo "📥 Instalando colecciones necesarias..."
echo ""

# Lista de colecciones requeridas
COLLECTIONS=(
    "community.general"
    "ansible.posix"
    "community.vmware"
    "community.windows"
)

# Instalar cada colección
for collection in "${COLLECTIONS[@]}"; do
    echo "→ Instalando $collection..."
    if ansible-galaxy collection install "$collection" --force 2>&1 | grep -q "successfully\|already"; then
        echo "  ✅ $collection instalado"
    else
        echo "  ⚠️  Error instalando $collection (puede que ya esté instalado)"
    fi
done

# Instalar desde requirements.yml si existe
if [ -f "requirements.yml" ]; then
    echo ""
    echo "→ Instalando también desde requirements.yml..."
    ansible-galaxy collection install -r requirements.yml --force 2>&1 | grep -v "Skipping" || true
fi

echo ""
echo "✅ Colecciones instaladas correctamente"
echo ""

# Verificar instalación
echo "🔍 Verificando instalación..."
echo ""
echo "Colecciones instaladas:"
ansible-galaxy collection list 2>/dev/null | grep -E "community\.|ansible\." || echo "  (No se pudieron listar)"

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ INSTALACIÓN COMPLETADA"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Colecciones instaladas en:"
echo "  → ~/.ansible/collections"
echo "  → /usr/share/ansible/collections"
echo ""
echo "Ahora puedes ejecutar los playbooks:"
echo "  bash scripts/run/run-dns.sh"
echo "  bash scripts/run/run-firewall.sh"
echo "  bash scripts/run/run-network.sh"
echo ""
