# Script para crear usuarios en Windows

Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "👥 Creando usuarios en Windows" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Contraseñas
$auditorPass = ConvertTo-SecureString "auditor123" -AsPlainText -Force
$gamerPass = ConvertTo-SecureString "gamer123" -AsPlainText -Force

Write-Host "1️⃣  Creando usuario 'auditor'..." -ForegroundColor Yellow
try {
    New-LocalUser -Name "auditor" -Password $auditorPass -FullName "Usuario Auditor" -Description "Auditor del sistema" -ErrorAction Stop
    Write-Host "   ✅ Usuario auditor creado" -ForegroundColor Green
} catch {
    Write-Host "   ℹ️  Usuario auditor ya existe" -ForegroundColor Gray
}

Write-Host ""
Write-Host "2️⃣  Creando usuario 'gamer01'..." -ForegroundColor Yellow
try {
    New-LocalUser -Name "gamer01" -Password $gamerPass -FullName "Usuario Gamer" -Description "Usuario para juegos" -ErrorAction Stop
    Write-Host "   ✅ Usuario gamer01 creado" -ForegroundColor Green
} catch {
    Write-Host "   ℹ️  Usuario gamer01 ya existe" -ForegroundColor Gray
}

Write-Host ""
Write-Host "3️⃣  Configurando permisos..." -ForegroundColor Yellow

# Auditor: solo lectura (grupo Users)
Add-LocalGroupMember -Group "Users" -Member "auditor" -ErrorAction SilentlyContinue

# Gamer: usuario estándar
Add-LocalGroupMember -Group "Users" -Member "gamer01" -ErrorAction SilentlyContinue

Write-Host "   ✅ Permisos configurados" -ForegroundColor Green

Write-Host ""
Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✅ Usuarios creados" -ForegroundColor Green
Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 Usuarios del sistema:" -ForegroundColor White
Write-Host ""
Write-Host "👤 Tu usuario (Administrador)" -ForegroundColor White
Write-Host "   - Rol: Administrador" -ForegroundColor Gray
Write-Host "   - Permisos: Administración completa" -ForegroundColor Gray
Write-Host ""
Write-Host "👤 auditor" -ForegroundColor White
Write-Host "   - Rol: Auditor" -ForegroundColor Gray
Write-Host "   - Permisos: Solo lectura" -ForegroundColor Gray
Write-Host "   - Contraseña: auditor123" -ForegroundColor Yellow
Write-Host ""
Write-Host "👤 gamer01" -ForegroundColor White
Write-Host "   - Rol: Cliente/Gamer" -ForegroundColor Gray
Write-Host "   - Permisos: Usuario estándar" -ForegroundColor Gray
Write-Host "   - Contraseña: gamer123" -ForegroundColor Yellow
Write-Host ""
Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
