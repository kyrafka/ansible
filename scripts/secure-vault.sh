#!/bin/bash
# Script para gestión segura del vault

set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
VAULT_FILE="$PROJECT_DIR/group_vars/all.vault.yml"
VAULT_PASSWORD_FILE="$PROJECT_DIR/.vault_pass"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Función para crear contraseña segura del vault
create_vault_password() {
    if [ -f "$VAULT_PASSWORD_FILE" ]; then
        log_warning "Archivo .vault_pass ya existe"
        read -p "¿Sobrescribir? (y/N): " confirm
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi
    
    log_info "Generando contraseña segura para el vault..."
    
    # Generar contraseña aleatoria de 32 caracteres
    vault_password=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
    
    echo "$vault_password" > "$VAULT_PASSWORD_FILE"
    chmod 600 "$VAULT_PASSWORD_FILE"
    
    log_success "Contraseña del vault creada: $VAULT_PASSWORD_FILE"
    log_warning "¡GUARDA ESTA CONTRASEÑA EN UN LUGAR SEGURO!"
    echo "Contraseña: $vault_password"
}

# Función para cifrar el vault
encrypt_vault() {
    if [ ! -f "$VAULT_PASSWORD_FILE" ]; then
        log_error "Archivo .vault_pass no encontrado"
        log_info "Ejecuta primero: $0 create-password"
        exit 1
    fi
    
    if ansible-vault encrypt "$VAULT_FILE" --vault-password-file "$VAULT_PASSWORD_FILE"; then
        log_success "Vault cifrado exitosamente"
    else
        log_error "Error al cifrar el vault"
        exit 1
    fi
}

# Función para descifrar el vault
decrypt_vault() {
    if [ ! -f "$VAULT_PASSWORD_FILE" ]; then
        log_error "Archivo .vault_pass no encontrado"
        exit 1
    fi
    
    if ansible-vault decrypt "$VAULT_FILE" --vault-password-file "$VAULT_PASSWORD_FILE"; then
        log_success "Vault descifrado exitosamente"
        log_warning "¡Recuerda cifrarlo de nuevo después de editarlo!"
    else
        log_error "Error al descifrar el vault"
        exit 1
    fi
}

# Función para editar el vault
edit_vault() {
    if [ ! -f "$VAULT_PASSWORD_FILE" ]; then
        log_error "Archivo .vault_pass no encontrado"
        exit 1
    fi
    
    ansible-vault edit "$VAULT_FILE" --vault-password-file "$VAULT_PASSWORD_FILE"
}

# Función para verificar seguridad
check_security() {
    log_info "Verificando configuración de seguridad..."
    
    # Verificar permisos del archivo de contraseña
    if [ -f "$VAULT_PASSWORD_FILE" ]; then
        perms=$(stat -c "%a" "$VAULT_PASSWORD_FILE" 2>/dev/null || stat -f "%A" "$VAULT_PASSWORD_FILE" 2>/dev/null)
        if [ "$perms" = "600" ]; then
            log_success ".vault_pass tiene permisos correctos (600)"
        else
            log_warning ".vault_pass tiene permisos incorrectos ($perms), corrigiendo..."
            chmod 600 "$VAULT_PASSWORD_FILE"
        fi
    else
        log_warning ".vault_pass no existe"
    fi
    
    # Verificar si el vault está cifrado
    if grep -q "ANSIBLE_VAULT" "$VAULT_FILE" 2>/dev/null; then
        log_success "Vault está cifrado"
    else
        log_warning "Vault NO está cifrado"
        log_info "Ejecuta: $0 encrypt"
    fi
    
    # Verificar claves SSH
    if [ -f ~/.ssh/id_ed25519 ]; then
        log_success "Clave SSH privada existe"
        ssh_perms=$(stat -c "%a" ~/.ssh/id_ed25519 2>/dev/null || stat -f "%A" ~/.ssh/id_ed25519 2>/dev/null)
        if [ "$ssh_perms" = "600" ]; then
            log_success "Clave SSH tiene permisos correctos"
        else
            log_warning "Clave SSH tiene permisos incorrectos, corrigiendo..."
            chmod 600 ~/.ssh/id_ed25519
        fi
    else
        log_warning "Clave SSH no existe, se generará automáticamente"
    fi
}

# Función principal
case "${1:-help}" in
    "create-password")
        create_vault_password
        ;;
    "encrypt")
        encrypt_vault
        ;;
    "decrypt")
        decrypt_vault
        ;;
    "edit")
        edit_vault
        ;;
    "check")
        check_security
        ;;
    "help"|*)
        echo "🔐 Gestión segura del vault de Ansible"
        echo "====================================="
        echo ""
        echo "Uso: $0 [comando]"
        echo ""
        echo "Comandos:"
        echo "  create-password  - Generar contraseña segura para el vault"
        echo "  encrypt         - Cifrar el vault"
        echo "  decrypt         - Descifrar el vault"
        echo "  edit            - Editar el vault cifrado"
        echo "  check           - Verificar configuración de seguridad"
        echo ""
        echo "Flujo recomendado:"
        echo "1. $0 create-password"
        echo "2. $0 encrypt"
        echo "3. $0 check"
        ;;
esac