@echo off
REM ════════════════════════════════════════════════════════════════
REM 🪟 SCRIPT SIMPLE PARA CONFIGURAR WINRM
REM ════════════════════════════════════════════════════════════════
REM Ejecutar como Administrador (clic derecho -> Ejecutar como administrador)
REM ════════════════════════════════════════════════════════════════

echo ════════════════════════════════════════════════════════════════
echo 🪟 CONFIGURANDO WINRM PARA ANSIBLE
echo ════════════════════════════════════════════════════════════════
echo.

echo 1️⃣  Habilitando WinRM...
powershell -Command "Enable-PSRemoting -Force -SkipNetworkProfileCheck"
echo    ✅ WinRM habilitado
echo.

echo 2️⃣  Configurando autenticación...
powershell -Command "Set-Item WSMan:\localhost\Service\Auth\Basic -Value $true"
powershell -Command "Set-Item WSMan:\localhost\Service\AllowUnencrypted -Value $true"
echo    ✅ Autenticación configurada
echo.

echo 3️⃣  Configurando firewall...
powershell -Command "New-NetFirewallRule -Name 'WinRM-HTTP' -DisplayName 'WinRM HTTP' -Enabled True -Direction Inbound -Protocol TCP -LocalPort 5985 -ErrorAction SilentlyContinue"
echo    ✅ Firewall configurado
echo.

echo 4️⃣  Configurando red como privada...
powershell -Command "Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private"
echo    ✅ Red configurada
echo.

echo 5️⃣  Reiniciando servicio...
net stop WinRM
net start WinRM
echo    ✅ Servicio reiniciado
echo.

echo ════════════════════════════════════════════════════════════════
echo ✅ CONFIGURACIÓN COMPLETADA
echo ════════════════════════════════════════════════════════════════
echo.
echo 📋 Verificar con: winrm get winrm/config
echo.
pause
