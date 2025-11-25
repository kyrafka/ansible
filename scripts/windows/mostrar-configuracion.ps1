# ════════════════════════════════════════════════════════════════
# 📋 MOSTRAR CONFIGURACIÓN DE WINDOWS 11 (PowerShell)
# ════════════════════════════════════════════════════════════════

Clear-Host
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "📋 CONFIGURACIÓN DE WINDOWS 11" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# 1. Usuarios
Write-Host "1️⃣  USUARIOS DEL SISTEMA" -ForegroundColor Yellow
Write-Host "────────────────────────────────────────────────────────────────"
Get-LocalUser | Select-Object Name, Enabled, Description | Format-Table -AutoSize
Write-Host ""

# 2. Carpetas creadas
Write-Host "2️⃣  CARPETAS CREADAS POR ANSIBLE" -ForegroundColor Yellow
Write-Host "────────────────────────────────────────────────────────────────"
Get-ChildItem C:\ | Where-Object {$_.Name -match 'Compartido|Dev'} | Select-Object Name, LastWriteTime | Format-Table -AutoSize
Write-Host ""

# 3. Configuración de red
Write-Host "3️⃣  CONFIGURACIÓN DE RED (IPv6)" -ForegroundColor Yellow
Write-Host "────────────────────────────────────────────────────────────────"
Get-NetIPAddress -AddressFamily IPv6 | Where-Object {$_.IPAddress -like '2025:*'} | Select-Object IPAddress, InterfaceAlias | Format-Table -AutoSize
Write-Host ""

# 4. Firewall
Write-Host "4️⃣  REGLAS DE FIREWALL CONFIGURADAS" -ForegroundColor Yellow
Write-Host "────────────────────────────────────────────────────────────────"
Get-NetFirewallRule | Where-Object {$_.DisplayName -match 'WinRM|ICMPv6|File and Printer'} | Select-Object DisplayName, Enabled, Direction | Format-Table -AutoSize
Write-Host ""

# 5. Servicio WinRM
Write-Host "5️⃣  SERVICIO WINRM" -ForegroundColor Yellow
Write-Host "────────────────────────────────────────────────────────────────"
Get-Service WinRM | Select-Object Name, Status, StartType | Format-Table -AutoSize
Write-Host ""

# 6. Información del sistema
Write-Host "6️⃣  INFORMACIÓN DEL SISTEMA" -ForegroundColor Yellow
Write-Host "────────────────────────────────────────────────────────────────"
Write-Host "Hostname: $env:COMPUTERNAME"
Write-Host "Usuario actual: $env:USERNAME"
Write-Host "Sistema operativo: $((Get-WmiObject Win32_OperatingSystem).Caption)"
Write-Host ""

# 7. Archivo creado por Ansible
Write-Host "7️⃣  ARCHIVO CREADO POR ANSIBLE" -ForegroundColor Yellow
Write-Host "────────────────────────────────────────────────────────────────"
if (Test-Path "C:\Users\jose\Desktop\ansible-test.txt") {
    Write-Host "✅ Archivo encontrado: C:\Users\jose\Desktop\ansible-test.txt" -ForegroundColor Green
    Write-Host "Contenido:"
    Get-Content "C:\Users\jose\Desktop\ansible-test.txt"
} else {
    Write-Host "⚠️  Archivo no encontrado" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✅ CONFIGURACIÓN MOSTRADA" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Presiona cualquier tecla para salir..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
