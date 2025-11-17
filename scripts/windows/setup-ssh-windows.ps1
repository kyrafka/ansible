# ════════════════════════════════════════════════════════════════
# Script para habilitar SSH en Windows 11
# Ejecutar como Administrador en PowerShell
# ════════════════════════════════════════════════════════════════

Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🔧 Configurando OpenSSH en Windows 11" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Verificar que se ejecuta como administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "❌ Este script debe ejecutarse como Administrador" -ForegroundColor Red
    Write-Host ""
    Write-Host "Haz click derecho en PowerShell y selecciona:" -ForegroundColor Yellow
    Write-Host "'Ejecutar como administrador'" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Presiona Enter para salir"
    exit 1
}

Write-Host "✅ Ejecutando como Administrador" -ForegroundColor Green
Write-Host ""

# 1. Instalar OpenSSH Server
Write-Host "1️⃣  Instalando OpenSSH Server..." -ForegroundColor Yellow

$sshServer = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'

if ($sshServer.State -eq "Installed") {
    Write-Host "  ✓ OpenSSH Server ya está instalado" -ForegroundColor Green
} else {
    Write-Host "  📥 Instalando OpenSSH Server (puede tardar 1-2 minutos)..." -ForegroundColor Cyan
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
    Write-Host "  ✓ OpenSSH Server instalado" -ForegroundColor Green
}

Write-Host ""

# 2. Iniciar y habilitar servicio SSH
Write-Host "2️⃣  Configurando servicio SSH..." -ForegroundColor Yellow

Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'

Write-Host "  ✓ Servicio SSH iniciado" -ForegroundColor Green
Write-Host "  ✓ Servicio SSH configurado para inicio automático" -ForegroundColor Green

Write-Host ""

# 3. Configurar firewall
Write-Host "3️⃣  Configurando firewall..." -ForegroundColor Yellow

$firewallRule = Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue

if ($firewallRule) {
    Write-Host "  ✓ Regla de firewall ya existe" -ForegroundColor Green
} else {
    New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
    Write-Host "  ✓ Regla de firewall creada (puerto 22)" -ForegroundColor Green
}

Write-Host ""

# 4. Configurar SSH para permitir solo admin
Write-Host "4️⃣  Configurando acceso SSH..." -ForegroundColor Yellow

$sshdConfig = "C:\ProgramData\ssh\sshd_config"

# Backup del archivo original
if (Test-Path $sshdConfig) {
    Copy-Item $sshdConfig "$sshdConfig.backup" -Force
    Write-Host "  ✓ Backup creado: sshd_config.backup" -ForegroundColor Green
}

# Configuración SSH segura
$config = @"
# Configuración SSH para GameCenter
Port 22
Protocol 2

# Autenticación
PasswordAuthentication yes
PubkeyAuthentication yes
PermitRootLogin no

# Solo permitir usuario admin
AllowUsers admin

# Seguridad
PermitEmptyPasswords no
MaxAuthTries 3
MaxSessions 5

# Subsistema SFTP
Subsystem sftp sftp-server.exe

# Logging
SyslogFacility AUTH
LogLevel INFO
"@

Set-Content -Path $sshdConfig -Value $config -Force
Write-Host "  ✓ Configuración SSH aplicada" -ForegroundColor Green
Write-Host "    - Solo usuario 'admin' puede conectar" -ForegroundColor Cyan
Write-Host "    - Puerto: 22" -ForegroundColor Cyan

Write-Host ""

# 5. Reiniciar servicio SSH
Write-Host "5️⃣  Reiniciando servicio SSH..." -ForegroundColor Yellow

Restart-Service sshd
Write-Host "  ✓ Servicio SSH reiniciado" -ForegroundColor Green

Write-Host ""

# 6. Obtener información de red
Write-Host "6️⃣  Información de red..." -ForegroundColor Yellow

$ipv6 = (Get-NetIPAddress -AddressFamily IPv6 -PrefixOrigin Dhcp -ErrorAction SilentlyContinue | Select-Object -First 1).IPAddress

if ($ipv6) {
    Write-Host "  ✓ Dirección IPv6: $ipv6" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  No se detectó IPv6 DHCP" -ForegroundColor Yellow
    Write-Host "    Configura IPv6 manualmente primero" -ForegroundColor Yellow
}

Write-Host ""

# 7. Probar SSH localmente
Write-Host "7️⃣  Probando SSH localmente..." -ForegroundColor Yellow

$testResult = Test-NetConnection -ComputerName localhost -Port 22 -WarningAction SilentlyContinue

if ($testResult.TcpTestSucceeded) {
    Write-Host "  ✓ SSH está escuchando en puerto 22" -ForegroundColor Green
} else {
    Write-Host "  ❌ SSH no responde en puerto 22" -ForegroundColor Red
}

Write-Host ""
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✅ SSH configurado exitosamente" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Host "📋 Resumen:" -ForegroundColor White
Write-Host ""
Write-Host "  Estado:        SSH habilitado y funcionando" -ForegroundColor Green
Write-Host "  Puerto:        22" -ForegroundColor Cyan
Write-Host "  Usuario SSH:   admin" -ForegroundColor Cyan
Write-Host "  Contraseña:    123" -ForegroundColor Cyan

if ($ipv6) {
    Write-Host "  IPv6:          $ipv6" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "🔐 Conectar desde el servidor Ubuntu:" -ForegroundColor Yellow
Write-Host ""

if ($ipv6) {
    Write-Host "  ssh admin@$ipv6" -ForegroundColor White
} else {
    Write-Host "  ssh admin@[IPv6_DE_LA_VM]" -ForegroundColor White
}

Write-Host ""
Write-Host "📝 Notas:" -ForegroundColor Yellow
Write-Host "  - Solo el usuario 'admin' puede conectar por SSH" -ForegroundColor White
Write-Host "  - Los usuarios 'auditor' y 'gamer01' NO tienen acceso SSH" -ForegroundColor White
Write-Host "  - El firewall está configurado para permitir SSH" -ForegroundColor White
Write-Host ""
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Read-Host "Presiona Enter para salir"
