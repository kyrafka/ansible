# ════════════════════════════════════════════════════════════════
# Script para cambiar VM de NAT a Bridge
# ════════════════════════════════════════════════════════════════

param(
    [string]$VMName = "ubuntu-desktop-01"
)

Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🔧 Cambiar red de VM a Bridge" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Buscar VBoxManage
$VBoxManage = ""
$PossiblePaths = @(
    "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe",
    "C:\Program Files (x86)\Oracle\VirtualBox\VBoxManage.exe"
)

foreach ($path in $PossiblePaths) {
    if (Test-Path $path) {
        $VBoxManage = $path
        break
    }
}

if (-not $VBoxManage) {
    Write-Host "❌ VirtualBox no está instalado" -ForegroundColor Red
    exit 1
}

# Verificar que la VM existe
$vms = & $VBoxManage list vms
$vmExists = $false
foreach ($vm in $vms) {
    if ($vm -match "`"$VMName`"") {
        $vmExists = $true
        break
    }
}

if (-not $vmExists) {
    Write-Host "❌ VM '$VMName' no encontrada" -ForegroundColor Red
    Write-Host ""
    Write-Host "VMs disponibles:" -ForegroundColor Yellow
    & $VBoxManage list vms
    exit 1
}

Write-Host "VM: $VMName" -ForegroundColor Cyan
Write-Host ""

# Listar adaptadores bridge disponibles
Write-Host "🔍 Detectando adaptadores de red..." -ForegroundColor Yellow
Write-Host ""

$adapters = & $VBoxManage list bridgedifs | Select-String "^Name:" | ForEach-Object { $_ -replace "Name:\s+", "" }

if ($adapters.Count -eq 0) {
    Write-Host "❌ No se encontraron adaptadores bridge" -ForegroundColor Red
    exit 1
}

Write-Host "Adaptadores disponibles:" -ForegroundColor Green
Write-Host ""

for ($i = 0; $i -lt $adapters.Count; $i++) {
    Write-Host "  [$i] $($adapters[$i])" -ForegroundColor White
}

Write-Host ""
$choice = Read-Host "Selecciona adaptador [0-$($adapters.Count-1)]"

if (-not ($choice -match '^\d+$') -or [int]$choice -ge $adapters.Count) {
    Write-Host "❌ Selección inválida" -ForegroundColor Red
    exit 1
}

$selectedAdapter = $adapters[[int]$choice]

Write-Host ""
Write-Host "Configurando Bridge..." -ForegroundColor Yellow

# Apagar VM si está corriendo
$vmState = & $VBoxManage showvminfo $VMName --machinereadable | Select-String "VMState=" | ForEach-Object { $_ -replace 'VMState="(.+)"', '$1' }

if ($vmState -eq "running") {
    Write-Host "  ⚠️  VM está corriendo, apagando..." -ForegroundColor Yellow
    & $VBoxManage controlvm $VMName poweroff
    Start-Sleep -Seconds 3
}

# Cambiar a Bridge
& $VBoxManage modifyvm $VMName `
    --nic1 bridged `
    --bridgeadapter1 $selectedAdapter `
    --nictype1 82540EM `
    --cableconnected1 on

Write-Host ""
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✅ Red configurada" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "VM:        $VMName" -ForegroundColor Cyan
Write-Host "Red:       Bridge" -ForegroundColor Cyan
Write-Host "Adaptador: $selectedAdapter" -ForegroundColor Cyan
Write-Host ""
Write-Host "📝 Próximos pasos:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Iniciar la VM:" -ForegroundColor White
Write-Host "   & '$VBoxManage' startvm '$VMName'" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. En la VM, la red debería obtener DHCP automáticamente" -ForegroundColor White
Write-Host "   del servidor Ubuntu (en ESXi)" -ForegroundColor White
Write-Host ""
Write-Host "3. Verificar conectividad:" -ForegroundColor White
Write-Host "   ip addr show" -ForegroundColor Cyan
Write-Host "   ping fd00:cafe:cafe::1  # Servidor" -ForegroundColor Cyan
Write-Host ""
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
