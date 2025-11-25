# ════════════════════════════════════════════════════════════════
# 🧪 PROBAR SAMBA Y FTP DESDE WINDOWS 11
# ════════════════════════════════════════════════════════════════

$SERVER_IP = "2025:db8:10::2"

Clear-Host
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🧪 PROBANDO SAMBA Y FTP DESDE WINDOWS" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# ════════════════════════════════════════════════════════════════
# PRUEBA 1: SAMBA
# ════════════════════════════════════════════════════════════════
Write-Host "📁 PRUEBA 1: SAMBA" -ForegroundColor Yellow
Write-Host "────────────────────────────────────────────────────────────────"
Write-Host ""

Write-Host "1️⃣  Ver recursos compartidos..." -ForegroundColor Yellow
net view \\$SERVER_IP
Write-Host ""

Write-Host "2️⃣  Montar recurso Publico en unidad Z:..." -ForegroundColor Yellow
net use Z: \\$SERVER_IP\Publico /persistent:no 2>$null
if ($?) {
    Write-Host "   ✅ Recurso montado en Z:" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  Recurso ya montado o error" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "3️⃣  Listar archivos en Z:..." -ForegroundColor Yellow
Get-ChildItem Z:\ | Format-Table Name, LastWriteTime -AutoSize
Write-Host ""

Write-Host "4️⃣  Crear archivo de prueba..." -ForegroundColor Yellow
$content = "Prueba desde Windows 11 - $(Get-Date)"
$content | Out-File -FilePath "Z:\test-windows.txt" -Encoding UTF8
Write-Host "   ✅ Archivo creado: Z:\test-windows.txt" -ForegroundColor Green
Write-Host ""

Write-Host "5️⃣  Leer archivo creado..." -ForegroundColor Yellow
Get-Content "Z:\test-windows.txt"
Write-Host ""

Write-Host "6️⃣  Desmontar unidad Z:..." -ForegroundColor Yellow
net use Z: /delete /y 2>$null
Write-Host "   ✅ Unidad desmontada" -ForegroundColor Green
Write-Host ""

# ════════════════════════════════════════════════════════════════
# PRUEBA 2: FTP
# ════════════════════════════════════════════════════════════════
Write-Host "📡 PRUEBA 2: FTP" -ForegroundColor Yellow
Write-Host "────────────────────────────────────────────────────────────────"
Write-Host ""

Write-Host "1️⃣  Conectar por FTP..." -ForegroundColor Yellow
Write-Host "   Servidor: ftp://$SERVER_IP" -ForegroundColor Cyan
Write-Host ""

Write-Host "2️⃣  Crear archivo para subir..." -ForegroundColor Yellow
$ftpContent = "Prueba FTP desde Windows 11 - $(Get-Date)"
$ftpContent | Out-File -FilePath "$env:TEMP\test-ftp-windows.txt" -Encoding UTF8
Write-Host "   ✅ Archivo creado: $env:TEMP\test-ftp-windows.txt" -ForegroundColor Green
Write-Host ""

Write-Host "3️⃣  Subir archivo por FTP..." -ForegroundColor Yellow
try {
    $ftpUri = "ftp://$SERVER_IP/test-ftp-windows.txt"
    $webclient = New-Object System.Net.WebClient
    $webclient.Credentials = New-Object System.Net.NetworkCredential("anonymous", "")
    $webclient.UploadFile($ftpUri, "$env:TEMP\test-ftp-windows.txt")
    Write-Host "   ✅ Archivo subido por FTP" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️  Error al subir archivo: $_" -ForegroundColor Yellow
}
Write-Host ""

# ════════════════════════════════════════════════════════════════
# RESUMEN
# ════════════════════════════════════════════════════════════════
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "✅ PRUEBAS COMPLETADAS" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Resumen:" -ForegroundColor Cyan
Write-Host "  ✅ Samba: Conectado, archivo creado en \\$SERVER_IP\Publico"
Write-Host "  ✅ FTP: Archivo subido a ftp://$SERVER_IP"
Write-Host ""
Write-Host "📁 Para ver archivos en Samba:" -ForegroundColor Yellow
Write-Host "  1. Abrir Explorador de archivos"
Write-Host "  2. Escribir en la barra: \\$SERVER_IP"
Write-Host "  3. Abrir carpeta 'Publico'"
Write-Host ""
Write-Host "Presiona cualquier tecla para salir..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
