# ════════════════════════════════════════════════════════════════
# 🪟 SCRIPT PARA CONFIGURAR WINRM EN WINDOWS 11
# ════════════════════════════════════════════════════════════════
# Ejecutar en Windows como Administrador
# ════════════════════════════════════════════════════════════════

Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🪟 CONFIGURANDO WINRM PARA ANSIBLE" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# 1. Habilitar WinRM
Write-Host "1️⃣  Habilitando WinRM..." -ForegroundColor Yellow
Enable-PSRemoting -Force -SkipNetworkProfileCheck
Write-Host "   ✅ WinRM habilitado" -ForegroundColor Green
Write-Host ""

# 2. Configurar autenticación básica
Write-Host "2️⃣  Configurando autenticación..." -ForegroundColor Yellow
Set-Item WSMan:\localhost\Service\Auth\Basic -Value $true
Set-Item WSMan:\localhost\Service\AllowUnencrypted -Value $true
Write-Host "   ✅ Autenticación configurada" -ForegroundColor Green
Write-Host ""

# 3. Configurar firewall
Write-Host "3️⃣  Configurando firewall..." -ForegroundColor Yellow
New-NetFirewallRule -Name "WinRM-HTTP" -DisplayName "WinRM HTTP" -Enabled True -Direction Inbound -Protocol TCP -LocalPort 5985 -ErrorAction SilentlyContinue
Write-Host "   ✅ Firewall configurado" -ForegroundColor Green
Write-Host ""

# 4. Configurar red como privada (necesario para WinRM)
Write-Host "4️⃣  Configurando red como privada..." -ForegroundColor Yellow
Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private
Write-Host "   ✅ Red configurada" -ForegroundColor Green
Write-Host ""

# 5. Reiniciar servicio WinRM
Write-Host "5️⃣  Reiniciando servicio WinRM..." -ForegroundColor Yellow
Restart-Service WinRM
Write-Host "   ✅ Servicio reiniciado" -ForegroundColor Green
Write-Host ""

# 6. Verificar configuración
Write-Host "6️⃣  Verificando configuración..." -ForegroundColor Yellow
Write-Host ""
winrm get winrm/config
Write-Host ""

# 7. Mostrar listeners
Write-Host "7️⃣  Listeners activos:" -ForegroundColor Yellow
winrm enumerate winrm/config/listener
Write-Host ""

# Resumen
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✅ CONFIGURACIÓN COMPLETADA" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 Información de conexión:" -ForegroundColor Cyan
Write-Host "   Puerto: 5985" -ForegroundColor White
Write-Host "   Protocolo: HTTP" -ForegroundColor White
Write-Host "   Autenticación: Basic" -ForegroundColor White
Write-Host ""
Write-Host "🔐 Credenciales para Ansible:" -ForegroundColor Cyan
Write-Host "   Usuario: $env:USERNAME" -ForegroundColor White
Write-Host "   IP: $(Get-NetIPAddress -AddressFamily IPv6 | Where-Object {$_.IPAddress -like '2025:*'} | Select-Object -ExpandProperty IPAddress)" -ForegroundColor White
Write-Host ""
