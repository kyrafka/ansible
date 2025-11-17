# ════════════════════════════════════════════════════════════════
# Script para configurar VM Ubuntu Desktop en VirtualBox con Ansible
# ════════════════════════════════════════════════════════════════

Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🔧 Configurar Ubuntu Desktop en VirtualBox" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Verificar que Ansible está instalado
if (-not (Get-Command ansible-playbook -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Ansible no está instalado" -ForegroundColor Red
    Write-Host ""
    Write-Host "Instala Ansible en WSL/Git Bash:" -ForegroundColor Yellow
    Write-Host "  sudo apt install ansible -y" -ForegroundColor White
    exit 1
}

Write-Host "✅ Ansible encontrado" -ForegroundColor Green
Write-Host ""

Write-Host "📋 Configuración:" -ForegroundColor White
Write-Host "  VM: ubuntu-desktop-local" -ForegroundColor Cyan
Write-Host "  SSH: localhost:2222" -ForegroundColor Cyan
Write-Host "  Usuario: admin" -ForegroundColor Cyan
Write-Host "  Contraseña: 123" -ForegroundColor Cyan
Write-Host ""

Write-Host "Se configurará:" -ForegroundColor Yellow
Write-Host "  - 3 usuarios (admin, auditor, gamer01)" -ForegroundColor White
Write-Host "  - SSH restringido a admin" -ForegroundColor White
Write-Host "  - Firewall (UFW)" -ForegroundColor White
Write-Host "  - Directorios compartidos" -ForegroundColor White
Write-Host ""

$confirm = Read-Host "¿Continuar? [S/n]"
if ($confirm -eq 'n' -or $confirm -eq 'N') {
    Write-Host "Operación cancelada" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "🚀 Ejecutando playbook de Ansible..." -ForegroundColor Yellow
Write-Host ""

# Ejecutar playbook
ansible-playbook -i inventory/virtualbox.ini playbooks/configure-virtualbox-ubuntu.yml

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "✅ Configuración completada" -ForegroundColor Green
    Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Conectar por SSH:" -ForegroundColor Yellow
    Write-Host "  ssh -p 2222 admin@localhost" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "❌ Error en la configuración" -ForegroundColor Red
    Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}
