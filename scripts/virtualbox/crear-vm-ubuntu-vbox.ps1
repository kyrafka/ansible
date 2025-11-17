# ════════════════════════════════════════════════════════════════
# Script PowerShell para crear VM Ubuntu Desktop en VirtualBox
# Para Windows
# ════════════════════════════════════════════════════════════════

param(
    [string]$VMName = "ubuntu-desktop-01",
    [int]$RAM = 4096,
    [int]$CPUs = 2,
    [int]$DiskSizeMB = 40960,
    [string]$ISOPath = ""
)

Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🖥️  Crear VM Ubuntu Desktop en VirtualBox" -ForegroundColor Cyan
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
    Write-Host ""
    Write-Host "Descarga VirtualBox desde:" -ForegroundColor Yellow
    Write-Host "https://www.virtualbox.org/wiki/Downloads" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ VirtualBox encontrado" -ForegroundColor Green
Write-Host ""

# Buscar ISO si no se especificó
if (-not $ISOPath) {
    Write-Host "🔍 Buscando ISO de Ubuntu..." -ForegroundColor Yellow
    
    $SearchPaths = @(
        "$env:USERPROFILE\Desktop\ubuntu-*.iso",
        "$env:USERPROFILE\Downloads\ubuntu-*.iso"
    )
    
    foreach ($pattern in $SearchPaths) {
        $found = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) {
            $ISOPath = $found.FullName
            break
        }
    }
    
    if (-not $ISOPath) {
        Write-Host ""
        Write-Host "❌ No se encontró ISO de Ubuntu" -ForegroundColor Red
        Write-Host ""
        Write-Host "Especifica la ruta:" -ForegroundColor Yellow
        Write-Host "  .\scripts\virtualbox\crear-vm-ubuntu-vbox.ps1 -ISOPath 'C:\Users\Diego\Desktop\ubuntu-24.04-desktop-amd64.iso'" -ForegroundColor White
        Write-Host ""
        exit 1
    }
}

# Verificar que existe la ISO
if (-not (Test-Path $ISOPath)) {
    Write-Host "❌ No se encuentra el archivo ISO: $ISOPath" -ForegroundColor Red
    exit 1
}

Write-Host "📋 Configuración de la VM:" -ForegroundColor White
Write-Host ""
Write-Host "  Nombre:     $VMName" -ForegroundColor Cyan
Write-Host "  RAM:        $RAM MB" -ForegroundColor Cyan
Write-Host "  CPUs:       $CPUs" -ForegroundColor Cyan
Write-Host "  Disco:      $([math]::Round($DiskSizeMB / 1024, 2)) GB" -ForegroundColor Cyan
Write-Host "  ISO:        $ISOPath" -ForegroundColor Cyan
Write-Host ""

$confirm = Read-Host "¿Crear VM '$VMName'? [S/n]"
if ($confirm -eq 'n' -or $confirm -eq 'N') {
    Write-Host "Operación cancelada" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "1️⃣  Creando VM..." -ForegroundColor Yellow

# Crear VM
& $VBoxManage createvm --name $VMName --ostype Ubuntu_64 --register

Write-Host "  ✓ VM creada y registrada" -ForegroundColor Green

Write-Host ""
Write-Host "2️⃣  Configurando hardware..." -ForegroundColor Yellow

# Configurar RAM y CPUs
& $VBoxManage modifyvm $VMName `
    --memory $RAM `
    --cpus $CPUs `
    --vram 128 `
    --graphicscontroller vmsvga `
    --accelerate3d on

Write-Host "  ✓ RAM: $RAM MB" -ForegroundColor Green
Write-Host "  ✓ CPUs: $CPUs" -ForegroundColor Green
Write-Host "  ✓ Video: 128MB con aceleración 3D" -ForegroundColor Green

Write-Host ""
Write-Host "3️⃣  Creando disco virtual..." -ForegroundColor Yellow

# Obtener carpeta de VMs
$vmInfo = & $VBoxManage showvminfo $VMName --machinereadable
$cfgLine = $vmInfo | Where-Object { $_ -match 'CfgFile=' }
$cfgPath = $cfgLine -replace 'CfgFile="(.+)"', '$1'
$vmFolder = Split-Path $cfgPath
$diskPath = Join-Path $vmFolder "$VMName.vdi"

# Crear disco
& $VBoxManage createhd --filename $diskPath --size $DiskSizeMB --format VDI

# Crear controlador SATA
& $VBoxManage storagectl $VMName --name "SATA" --add sata --controller IntelAhci --portcount 2

# Adjuntar disco
& $VBoxManage storageattach $VMName --storagectl "SATA" --port 0 --device 0 --type hdd --medium $diskPath

Write-Host "  ✓ Disco creado: $([math]::Round($DiskSizeMB / 1024, 2)) GB" -ForegroundColor Green

Write-Host ""
Write-Host "4️⃣  Configurando red..." -ForegroundColor Yellow

# Detectar adaptadores de red disponibles
$adapters = & $VBoxManage list bridgedifs | Select-String "^Name:" | ForEach-Object { $_ -replace "Name:\s+", "" }

if ($adapters.Count -eq 0) {
    Write-Host "  ⚠️  No se encontraron adaptadores bridge" -ForegroundColor Yellow
    Write-Host "  Configurando NAT por defecto" -ForegroundColor Yellow
    & $VBoxManage modifyvm $VMName --nic1 nat
    Write-Host "  ✓ Red: NAT (cambiar a Bridge manualmente)" -ForegroundColor Green
} else {
    Write-Host "  Adaptadores disponibles:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $adapters.Count; $i++) {
        Write-Host "    [$i] $($adapters[$i])" -ForegroundColor White
    }
    Write-Host ""
    
    $choice = Read-Host "  Selecciona adaptador para Bridge [0-$($adapters.Count-1)] o Enter para NAT"
    
    if ($choice -match '^\d+$' -and [int]$choice -lt $adapters.Count) {
        $selectedAdapter = $adapters[[int]$choice]
        & $VBoxManage modifyvm $VMName `
            --nic1 bridged `
            --bridgeadapter1 $selectedAdapter `
            --nictype1 82540EM `
            --cableconnected1 on
        Write-Host "  ✓ Red: Bridge → $selectedAdapter" -ForegroundColor Green
        Write-Host "  ℹ️  La VM obtendrá DHCP del servidor" -ForegroundColor Cyan
    } else {
        & $VBoxManage modifyvm $VMName --nic1 nat
        Write-Host "  ✓ Red: NAT (internet directo)" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "5️⃣  Adjuntando ISO..." -ForegroundColor Yellow

# Crear controlador IDE para CD
& $VBoxManage storagectl $VMName --name "IDE" --add ide

# Adjuntar ISO
& $VBoxManage storageattach $VMName --storagectl "IDE" --port 0 --device 0 --type dvddrive --medium $ISOPath

Write-Host "  ✓ ISO adjuntada" -ForegroundColor Green

Write-Host ""
Write-Host "6️⃣  Configuraciones adicionales..." -ForegroundColor Yellow

# Habilitar EFI, USB, etc.
& $VBoxManage modifyvm $VMName `
    --firmware efi `
    --boot1 dvd `
    --boot2 disk `
    --boot3 none `
    --boot4 none `
    --audio none `
    --usb on `
    --usbehci on `
    --clipboard bidirectional `
    --draganddrop bidirectional

Write-Host "  ✓ UEFI habilitado" -ForegroundColor Green
Write-Host "  ✓ USB habilitado" -ForegroundColor Green
Write-Host "  ✓ Clipboard bidireccional" -ForegroundColor Green

Write-Host ""
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✅ VM creada exitosamente" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Host "📋 Información:" -ForegroundColor White
Write-Host ""
Write-Host "  Nombre:     $VMName" -ForegroundColor Cyan
Write-Host "  RAM:        $RAM MB" -ForegroundColor Cyan
Write-Host "  CPUs:       $CPUs" -ForegroundColor Cyan
Write-Host "  Disco:      $([math]::Round($DiskSizeMB / 1024, 2)) GB" -ForegroundColor Cyan
Write-Host "  Red:        NAT (internet directo)" -ForegroundColor Cyan
Write-Host ""

Write-Host "🚀 Iniciar VM:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  & '$VBoxManage' startvm '$VMName'" -ForegroundColor White
Write-Host ""

Write-Host "📝 Próximos pasos:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Iniciar la VM e instalar Ubuntu Desktop" -ForegroundColor White
Write-Host "2. Usuario recomendado: admin / 123" -ForegroundColor White
Write-Host "3. Instalar OpenSSH Server" -ForegroundColor White
Write-Host ""

Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
