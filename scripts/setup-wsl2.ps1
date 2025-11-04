# Script PowerShell para configurar WSL2 y el proyecto Ansible
# Ejecutar como Administrador

param(
    [switch]$Install,
    [switch]$Configure,
    [switch]$Help
)

# Colores para PowerShell
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    } else {
        $input | Write-Output
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-Info($message) {
    Write-ColorOutput Blue "[INFO] $message"
}

function Write-Success($message) {
    Write-ColorOutput Green "[OK] $message"
}

function Write-Warning($message) {
    Write-ColorOutput Yellow "[WARN] $message"
}

function Write-Error($message) {
    Write-ColorOutput Red "[ERROR] $message"
}

function Show-Banner {
    Write-ColorOutput Cyan @"
╔════════════════════════════════════════════════════════════╗
║              CONFIGURAR ANSIBLE EN WINDOWS 11              ║
║                                                            ║
║  Este script configura WSL2 + Ubuntu para ejecutar        ║
║  el proyecto Ansible desde Windows 11 Home                ║
║                                                            ║
║  WSL2 te dará acceso completo a la red física             ║
║  sin necesidad de VMs pesadas                              ║
╚════════════════════════════════════════════════════════════╝
"@
}

function Test-AdminRights {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Install-WSL2 {
    Write-Info "Instalando WSL2 y Ubuntu..."
    
    # Verificar si WSL ya está instalado
    try {
        $wslVersion = wsl --version
        Write-Success "WSL ya está instalado"
        Write-Output $wslVersion
    } catch {
        Write-Info "Instalando WSL2..."
        wsl --install
        Write-Warning "Reinicia Windows y ejecuta este script de nuevo con -Configure"
        return
    }
    
    # Verificar si Ubuntu está instalado
    $distributions = wsl --list --quiet
    if ($distributions -notcontains "Ubuntu-24.04") {
        Write-Info "Instalando Ubuntu 24.04..."
        wsl --install -d Ubuntu-24.04
        Write-Success "Ubuntu 24.04 instalado"
    } else {
        Write-Success "Ubuntu 24.04 ya está instalado"
    }
    
    # Configurar WSL2 como versión por defecto
    wsl --set-default-version 2
    Write-Success "WSL2 configurado como versión por defecto"
}

function Configure-Ubuntu {
    Write-Info "Configurando Ubuntu en WSL2..."
    
    # Script para ejecutar dentro de WSL2
    $ubuntuScript = @"
#!/bin/bash
echo "🔧 Configurando Ubuntu para Ansible..."

# Actualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar herramientas necesarias
sudo apt install -y ansible git openssh-client sshpass curl wget python3-pip unzip

# Verificar instalación
echo "✅ Ansible instalado: `$(ansible --version | head -1)"

# Instalar colecciones de Ansible
ansible-galaxy collection install community.vmware community.general

# Generar clave SSH
if [ ! -f ~/.ssh/id_ed25519 ]; then
    ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
    echo "✅ Clave SSH generada"
else
    echo "✅ Clave SSH ya existe"
fi

# Mostrar información de red
echo ""
echo "🌐 Información de red en WSL2:"
ip addr show eth0 | grep "inet "

echo ""
echo "🎉 Configuración completada!"
echo "Ahora puedes clonar tu proyecto y ejecutarlo"
"@
    
    # Guardar script temporal
    $tempScript = "$env:TEMP\configure-ubuntu.sh"
    $ubuntuScript | Out-File -FilePath $tempScript -Encoding UTF8
    
    # Ejecutar en WSL2
    wsl -d Ubuntu-24.04 bash -c "$(Get-Content $tempScript -Raw)"
    
    # Limpiar archivo temporal
    Remove-Item $tempScript
    
    Write-Success "Ubuntu configurado exitosamente"
}

function Test-Connectivity {
    Write-Info "Probando conectividad desde WSL2..."
    
    $testScript = @"
#!/bin/bash
echo "🔍 Probando conectividad de red..."

# Test básico
echo "📍 IP de WSL2:"
ip addr show eth0 | grep "inet " | awk '{print `$2}'

echo ""
echo "🌐 Probando conectividad:"

# Test gateway
gateway=`$(ip route | grep default | awk '{print `$3}')
if ping -c 2 `$gateway >/dev/null 2>&1; then
    echo "✅ Gateway (`$gateway): ACCESIBLE"
else
    echo "❌ Gateway (`$gateway): NO ACCESIBLE"
fi

# Test ESXi
esxi_ip="172.17.25.11"
if ping -c 3 `$esxi_ip >/dev/null 2>&1; then
    echo "✅ ESXi (`$esxi_ip): ACCESIBLE"
else
    echo "❌ ESXi (`$esxi_ip): NO ACCESIBLE"
fi

# Test DNS
if ping -c 2 8.8.8.8 >/dev/null 2>&1; then
    echo "✅ DNS externo: ACCESIBLE"
else
    echo "❌ DNS externo: NO ACCESIBLE"
fi

echo ""
echo "💡 Si ESXi es accesible, puedes ejecutar el proyecto Ansible"
"@
    
    $tempScript = "$env:TEMP\test-connectivity.sh"
    $testScript | Out-File -FilePath $tempScript -Encoding UTF8
    
    wsl -d Ubuntu-24.04 bash -c "$(Get-Content $tempScript -Raw)"
    
    Remove-Item $tempScript
}

function Show-NextSteps {
    Write-Success "¡Configuración completada!"
    Write-Output ""
    Write-ColorOutput Cyan "📋 Próximos pasos:"
    Write-Output ""
    Write-Output "1. 📁 Clonar tu proyecto en WSL2:"
    Write-Output "   wsl -d Ubuntu-24.04"
    Write-Output "   git clone <tu-repositorio> ansible-gestion-despliegue"
    Write-Output "   cd ansible-gestion-despliegue"
    Write-Output ""
    Write-Output "2. 🔧 Configurar credenciales:"
    Write-Output "   ./scripts/secure-vault.sh create-password"
    Write-Output "   ./scripts/secure-vault.sh decrypt"
    Write-Output ""
    Write-Output "3. 🚀 Ejecutar proyecto:"
    Write-Output "   ./scripts/crear-vm-ubuntu.sh"
    Write-Output ""
    Write-ColorOutput Yellow "💡 Para acceder a WSL2 siempre:"
    Write-Output "   - Abrir 'Ubuntu 24.04' desde el menú inicio"
    Write-Output "   - O ejecutar: wsl -d Ubuntu-24.04"
    Write-Output ""
    Write-ColorOutput Green "🎉 ¡Tu Windows 11 está listo para Ansible!"
}

function Show-Help {
    Write-Output @"
🔧 CONFIGURADOR DE ANSIBLE PARA WINDOWS 11
==========================================

Uso: .\setup-wsl2.ps1 [parámetros]

Parámetros:
  -Install     Instalar WSL2 y Ubuntu
  -Configure   Configurar Ubuntu con Ansible
  -Help        Mostrar esta ayuda

Ejemplos:
  .\setup-wsl2.ps1 -Install
  .\setup-wsl2.ps1 -Configure

Flujo completo:
1. Ejecutar como Administrador: .\setup-wsl2.ps1 -Install
2. Reiniciar Windows si es necesario
3. Ejecutar: .\setup-wsl2.ps1 -Configure
4. Clonar proyecto en WSL2 y ejecutar

Requisitos:
- Windows 11 Home/Pro
- Ejecutar PowerShell como Administrador
- Conexión a internet
"@
}

# Función principal
function Main {
    Show-Banner
    
    if ($Help) {
        Show-Help
        return
    }
    
    if (-not (Test-AdminRights)) {
        Write-Error "Este script debe ejecutarse como Administrador"
        Write-Info "Haz clic derecho en PowerShell y selecciona 'Ejecutar como administrador'"
        return
    }
    
    if ($Install) {
        Install-WSL2
        Write-Info "Si WSL2 se instaló por primera vez, reinicia Windows"
        Write-Info "Después ejecuta: .\setup-wsl2.ps1 -Configure"
        return
    }
    
    if ($Configure) {
        Configure-Ubuntu
        Test-Connectivity
        Show-NextSteps
        return
    }
    
    # Si no se especifica parámetro, mostrar menú
    Write-Output "Selecciona una opción:"
    Write-Output "1. Instalar WSL2 y Ubuntu"
    Write-Output "2. Configurar Ubuntu con Ansible"
    Write-Output "3. Probar conectividad"
    Write-Output "4. Mostrar ayuda"
    
    $choice = Read-Host "Opción (1-4)"
    
    switch ($choice) {
        "1" { Install-WSL2 }
        "2" { Configure-Ubuntu; Test-Connectivity; Show-NextSteps }
        "3" { Test-Connectivity }
        "4" { Show-Help }
        default { Write-Warning "Opción no válida" }
    }
}

# Ejecutar función principal
Main