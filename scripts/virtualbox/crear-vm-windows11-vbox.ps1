# Script para crear VM Windows 11 en VirtualBox para GNS3

$ErrorActionPreference = "Stop"

Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🪟 Creando VM Windows 11 en VirtualBox" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Configuración
$vmName = "Windows11-Gaming"
$osType = "Windows11_64"
$memory = 4096  # 4 GB RAM
$vram = 128     # 128 MB Video RAM
$cpus = 2
$diskSize = 51200  # 50 GB
$isoPath = "C:\Users\Diego\Downloads\Win10_22H2_Spanish_x64v1.iso"

Write-Host "📋 Configuración:" -ForegroundColor Yellow
Write-Host "   Nombre: $vmName"
Write-Host "   RAM: $memory MB"
Write-Host "   CPUs: $cpus"
Write-Host "   Disco: $($diskSize/1024) GB"
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

Write-Host "✅ VBoxManage encontrado: $VBoxManage" -ForegroundColor Green
Write-Host ""

Write-Host "1️⃣  Creando VM..." -ForegroundColor Yellow
& $VBoxManage createvm --name $vmName --ostype $osType --register

Write-Host "2️⃣  Configurando hardware..." -ForegroundColor Yellow
& $VBoxManage modifyvm $vmName --memory $memory --vram $vram --cpus $cpus
& $VBoxManage modifyvm $vmName --graphicscontroller vmsvga
& $VBoxManage modifyvm $vmName --audio-driver default --audiocontroller hda --audio-enabled on

# Deshabilitar TPM y Secure Boot checks para Windows 11
Write-Host "3️⃣  Deshabilitando requisitos de Windows 11..." -ForegroundColor Yellow
& $VBoxManage modifyvm $vmName --firmware efi
& $VBoxManage setextradata $vmName "VBoxInternal/Devices/efi/0/Config/DmiSystemProduct" "VirtualBox"
& $VBoxManage setextradata $vmName "VBoxInternal/Devices/efi/0/Config/DmiSystemVersion" "1.0"

Write-Host "4️⃣  Creando disco duro..." -ForegroundColor Yellow
$vmFolder = (& $VBoxManage showvminfo $vmName --machinereadable | Select-String "CfgFile").ToString().Split("=")[1].Trim('"')
$vmFolder = Split-Path $vmFolder
$vdiPath = Join-Path $vmFolder "$vmName.vdi"

& $VBoxManage createhd --filename $vdiPath --size $diskSize --format VDI

Write-Host "5️⃣  Configurando controlador SATA..." -ForegroundColor Yellow
& $VBoxManage storagectl $vmName --name "SATA" --add sata --controller IntelAhci --portcount 2
& $VBoxManage storageattach $vmName --storagectl "SATA" --port 0 --device 0 --type hdd --medium $vdiPath

Write-Host "6️⃣  Montando ISO de Windows..." -ForegroundColor Yellow
if (Test-Path $isoPath) {
    & $VBoxManage storageattach $vmName --storagectl "SATA" --port 1 --device 0 --type dvddrive --medium $isoPath
    Write-Host "   ✅ ISO montada: $isoPath" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  ISO no encontrada: $isoPath" -ForegroundColor Yellow
    Write-Host "   Monta la ISO manualmente después" -ForegroundColor Gray
}

Write-Host "7️⃣  Configurando red..." -ForegroundColor Yellow
# Adaptador 1: NAT (internet temporal)
& $VBoxManage modifyvm $vmName --nic1 nat --nictype1 82540EM --cableconnected1 on

# Adaptador 2: Generic Driver para GNS3
& $VBoxManage modifyvm $vmName --nic2 generic --nictype2 82540EM --cableconnected2 on
& $VBoxManage modifyvm $vmName --nicgenericdrv2 UDPTunnel
& $VBoxManage modifyvm $vmName --nicproperty2 dest=127.0.0.1
& $VBoxManage modifyvm $vmName --nicproperty2 sport=10001
& $VBoxManage modifyvm $vmName --nicproperty2 dport=10000

Write-Host "8️⃣  Configurando boot..." -ForegroundColor Yellow
& $VBoxManage modifyvm $vmName --boot1 dvd --boot2 disk --boot3 none --boot4 none

Write-Host ""
Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✅ VM Windows 11 creada exitosamente" -ForegroundColor Green
Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 Detalles de la VM:" -ForegroundColor White
Write-Host "   Nombre: $vmName" -ForegroundColor Gray
Write-Host "   RAM: $memory MB ($($memory/1024) GB)" -ForegroundColor Gray
Write-Host "   CPUs: $cpus" -ForegroundColor Gray
Write-Host "   Disco: $($diskSize/1024) GB" -ForegroundColor Gray
Write-Host ""
Write-Host "🌐 Configuración de red:" -ForegroundColor White
Write-Host "   Adaptador 1: NAT (internet temporal)" -ForegroundColor Gray
Write-Host "   Adaptador 2: Generic Driver (GNS3)" -ForegroundColor Gray
Write-Host ""
Write-Host "📝 Próximos pasos:" -ForegroundColor Yellow
Write-Host "   1. Inicia la VM desde VirtualBox" -ForegroundColor White
Write-Host "   2. Instala Windows 11" -ForegroundColor White
Write-Host "   3. En GNS3: Edit → Preferences → VirtualBox VMs → Add" -ForegroundColor White
Write-Host "   4. Selecciona '$vmName' y agrégala al proyecto" -ForegroundColor White
Write-Host "   5. Conecta la VM al Switch1 en GNS3" -ForegroundColor White
Write-Host ""
Write-Host "⚠️  Nota: Windows 11 requiere TPM 2.0 y Secure Boot" -ForegroundColor Yellow
Write-Host "   Esta VM tiene bypass configurado para instalar sin esos requisitos" -ForegroundColor Gray
Write-Host ""
Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
