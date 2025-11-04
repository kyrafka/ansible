#!/bin/bash
# Script para ejecutar playbooks con vault de forma segura

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
VAULT_PASSWORD_FILE="$PROJECT_DIR/.vault_pass"

# Función para mostrar ayuda
show_help() {
    echo "🔧 EJECUTOR DE PLAYBOOKS CON VAULT"
    echo "=================================="
    echo "Uso: $0 [opción] [playbook] [argumentos]"
    echo ""
    echo "Opciones:"
    echo "  ubuntu       - Ejecutar configuración completa de Ubuntu"
    echo "  vmware       - Ejecutar creación de VM en VMware"
    echo "  custom       - Ejecutar playbook personalizado"
    echo "  test         - Probar conectividad"
    echo "  help         - Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  $0 ubuntu"
    echo "  $0 custom playbooks/configure_ipv6.yml"
    echo "  $0 test"
}

# Función para verificar vault
check_vault() {
    if [ ! -f "$VAULT_PASSWORD_FILE" ]; then
        echo -e "${YELLOW}⚠️  Archivo de contraseña del vault no encontrado${NC}"
        read -s -p "Ingresa la contraseña del vault: " vault_pass
        echo ""
        echo "$vault_pass" > "$VAULT_PASSWORD_FILE"
        chmod 600 "$VAULT_PASSWORD_FILE"
        echo -e "${GREEN}✅ Archivo de vault creado${NC}"
    fi
}

# Función para ejecutar configuración de Ubuntu
run_ubuntu() {
    echo -e "${BLUE}🐧 Ejecutando configuración completa de Ubuntu${NC}"
    echo "=============================================="
    
    cd "$PROJECT_DIR"
    
    ansible-playbook -i inventory/hosts.ini site.yml \
        --vault-password-file "$VAULT_PASSWORD_FILE" \
        --limit servidores_ubuntu \
        -v
    
    echo -e "${GREEN}✅ Configuración de Ubuntu completada${NC}"
}

# Función para ejecutar creación de VM
run_vmware() {
    echo -e "${BLUE}🖥️  Ejecutando creación de VM en VMware${NC}"
    echo "======================================"
    
    cd "$PROJECT_DIR"
    
    ansible-playbook -i inventory/hosts.ini site.yml \
        --vault-password-file "$VAULT_PASSWORD_FILE" \
        --limit vmware_servers \
        -v
    
    echo -e "${GREEN}✅ Creación de VM completada${NC}"
}

# Función para ejecutar playbook personalizado
run_custom() {
    local playbook="$1"
    local extra_args="$2"
    
    if [ -z "$playbook" ]; then
        echo -e "${RED}❌ Debes especificar un playbook${NC}"
        echo "Uso: $0 custom <playbook> [argumentos]"
        exit 1
    fi
    
    if [ ! -f "$PROJECT_DIR/$playbook" ]; then
        echo -e "${RED}❌ Playbook no encontrado: $playbook${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}🎯 Ejecutando playbook personalizado: $playbook${NC}"
    echo "================================================"
    
    cd "$PROJECT_DIR"
    
    ansible-playbook -i inventory/hosts.ini "$playbook" \
        --vault-password-file "$VAULT_PASSWORD_FILE" \
        $extra_args \
        -v
    
    echo -e "${GREEN}✅ Playbook personalizado completado${NC}"
}

# Función para probar conectividad
test_connectivity() {
    echo -e "${BLUE}🔗 Probando conectividad con hosts${NC}"
    echo "================================="
    
    cd "$PROJECT_DIR"
    
    echo "Probando servidores Ubuntu:"
    ansible servidores_ubuntu -i inventory/hosts.ini -m ping --vault-password-file "$VAULT_PASSWORD_FILE"
    
    echo ""
    echo "Probando servidores VMware:"
    ansible vmware_servers -i inventory/hosts.ini -m ping --vault-password-file "$VAULT_PASSWORD_FILE" || echo "No hay hosts VMware configurados"
    
    echo ""
    echo -e "${GREEN}✅ Prueba de conectividad completada${NC}"
}

# Función principal
main() {
    case "${1:-help}" in
        "ubuntu")
            check_vault
            run_ubuntu
            ;;
        "vmware")
            check_vault
            run_vmware
            ;;
        "custom")
            check_vault
            run_custom "$2" "$3"
            ;;
        "test")
            check_vault
            test_connectivity
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# Ejecutar función principal
main "$@"