#!/bin/bash
# Script de hardening de seguridad para el proyecto

set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

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

# Función para asegurar permisos de archivos
secure_file_permissions() {
    log_info "Asegurando permisos de archivos sensibles..."
    
    # Vault password file
    if [ -f ".vault_pass" ]; then
        chmod 600 .vault_pass
        log_success "Permisos de .vault_pass: 600"
    fi
    
    # SSH keys
    if [ -f ~/.ssh/id_ed25519 ]; then
        chmod 600 ~/.ssh/id_ed25519
        log_success "Permisos de clave SSH privada: 600"
    fi
    
    if [ -f ~/.ssh/id_ed25519.pub ]; then
        chmod 644 ~/.ssh/id_ed25519.pub
        log_success "Permisos de clave SSH pública: 644"
    fi
    
    # Scripts ejecutables
    chmod +x scripts/*.sh
    log_success "Scripts marcados como ejecutables"
}

# Función para verificar vault cifrado
check_vault_encryption() {
    log_info "Verificando cifrado del vault..."
    
    if grep -q "ANSIBLE_VAULT" group_vars/all.vault.yml 2>/dev/null; then
        log_success "Vault está cifrado"
    else
        log_warning "Vault NO está cifrado"
        log_info "Ejecuta: ./scripts/secure-vault.sh encrypt"
    fi
}

# Función para limpiar archivos temporales
cleanup_temp_files() {
    log_info "Limpiando archivos temporales..."
    
    # Archivos temporales de Ansible
    find . -name "*.retry" -delete 2>/dev/null || true
    find . -name ".ansible_*" -delete 2>/dev/null || true
    
    # Archivos de backup de editores
    find . -name "*~" -delete 2>/dev/null || true
    find . -name "*.bak" -delete 2>/dev/null || true
    
    log_success "Archivos temporales limpiados"
}

# Función para verificar configuración SSH
check_ssh_config() {
    log_info "Verificando configuración SSH..."
    
    if [ -f ~/.ssh/config ]; then
        if grep -q "StrictHostKeyChecking no" ~/.ssh/config; then
            log_warning "SSH configurado con StrictHostKeyChecking=no (inseguro)"
            log_info "Considera usar la configuración de ssh_config_template"
        else
            log_success "Configuración SSH parece segura"
        fi
    else
        log_info "No hay configuración SSH personalizada"
        log_info "Puedes usar ssh_config_template como base"
    fi
}

# Función para generar reporte de seguridad
generate_security_report() {
    log_info "Generando reporte de seguridad..."
    
    report_file="security_report_$(date +%Y%m%d_%H%M).txt"
    
    {
        echo "REPORTE DE SEGURIDAD - PROYECTO ANSIBLE"
        echo "======================================="
        echo "Fecha: $(date)"
        echo "Usuario: $(whoami)"
        echo ""
        
        echo "ARCHIVOS SENSIBLES:"
        echo "-------------------"
        [ -f ".vault_pass" ] && echo "✓ .vault_pass existe ($(stat -c "%a" .vault_pass 2>/dev/null || echo "permisos desconocidos"))"
        [ -f "group_vars/all.vault.yml" ] && echo "✓ vault.yml existe"
        [ -f ~/.ssh/id_ed25519 ] && echo "✓ Clave SSH privada existe ($(stat -c "%a" ~/.ssh/id_ed25519 2>/dev/null || echo "permisos desconocidos"))"
        
        echo ""
        echo "CIFRADO:"
        echo "--------"
        if grep -q "ANSIBLE_VAULT" group_vars/all.vault.yml 2>/dev/null; then
            echo "✓ Vault cifrado"
        else
            echo "✗ Vault NO cifrado"
        fi
        
        echo ""
        echo "RECOMENDACIONES:"
        echo "----------------"
        echo "1. Mantener vault siempre cifrado"
        echo "2. Usar claves SSH en lugar de contraseñas"
        echo "3. Rotar contraseñas regularmente"
        echo "4. Hacer backup seguro de .vault_pass"
        echo "5. No commitear archivos sensibles a git"
        
    } > "$report_file"
    
    log_success "Reporte generado: $report_file"
}

# Función principal
main() {
    echo "🔒 HARDENING DE SEGURIDAD"
    echo "========================="
    echo ""
    
    secure_file_permissions
    check_vault_encryption
    cleanup_temp_files
    check_ssh_config
    generate_security_report
    
    echo ""
    log_success "Hardening de seguridad completado"
    echo ""
    echo "💡 Próximos pasos recomendados:"
    echo "1. Cifrar el vault: ./scripts/secure-vault.sh encrypt"
    echo "2. Hacer backup de .vault_pass en lugar seguro"
    echo "3. Configurar SSH con ssh_config_template"
    echo "4. Ejecutar verificaciones: ./scripts/secure-vault.sh check"
}

main "$@"