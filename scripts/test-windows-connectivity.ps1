# Script PowerShell para verificar conectividad desde Windows

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

function Test-NetworkConnectivity {
    Write-Info "Verificando conectividad de red desde Windows..."
    
    # Información de red de Windows
    Write-Output ""
    Write-Output "🌐 Información de red de Windows:"
    $networkAdapters = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -ne "127.0.0.1" }
    foreach ($adapter in $networkAdapters) {
        Write-Output "   $($adapter.InterfaceAlias): $($adapter.IPAddress)"
    }
    
    # Test ESXi
    Write-Output ""
    Write-Info "Probando conectividad con ESXi..."
    $esxiIP = "172.17.25.11"
    
    if (Test-Connection -ComputerName $esxiIP -Count 2 -Quiet) {
        Write-Success "ESXi ($esxiIP): ✅ ACCESIBLE"
        
        # Test puerto SSH
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        try {
            $tcpClient.Connect($esxiIP, 22)
            Write-Success "ESXi SSH (puerto 22): ✅ ABIERTO"
            $tcpClient.Close()
        } catch {
            Write-Warning "ESXi SSH (puerto 22): ❌ CERRADO O FILTRADO"
        }
        
        # Test puerto HTTPS
        try {
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $tcpClient.Connect($esxiIP, 443)
            Write-Success "ESXi HTTPS (puerto 443): ✅ ABIERTO"
            $tcpClient.Close()
        } catch {
            Write-Warning "ESXi HTTPS (puerto 443): ❌ CERRADO O FILTRADO"
        }
    } else {
        Write-Warning "ESXi ($esxiIP): ❌ NO ACCESIBLE"
    }
    
    # Test DNS
    Write-Output ""
    Write-Info "Probando DNS..."
    if (Test-Connection -ComputerName "8.8.8.8" -Count 2 -Quiet) {
        Write-Success "DNS externo (8.8.8.8): ✅ ACCESIBLE"
    } else {
        Write-Warning "DNS externo (8.8.8.8): ❌ NO ACCESIBLE"
    }
}

function Test-WSL2Status {
    Write-Output ""
    Write-Info "Verificando estado de WSL2..."
    
    try {
        $wslVersion = wsl --version
        Write-Success "WSL2 está instalado"
        
        # Listar distribuciones
        $distributions = wsl --list --verbose
        Write-Output "Distribuciones WSL:"
        Write-Output $distributions
        
        # Test conectividad desde WSL2
        Write-Output ""
        Write-Info "Probando conectividad desde WSL2..."
        
        $wslScript = @"
#!/bin/bash
echo "📍 IP de WSL2:"
ip addr show eth0 | grep "inet " | awk '{print `$2}' 2>/dev/null || echo "No disponible"

echo ""
echo "🔍 Test desde WSL2:"
if ping -c 2 172.17.25.11 >/dev/null 2>&1; then
    echo "✅ ESXi accesible desde WSL2"
else
    echo "❌ ESXi NO accesible desde WSL2"
fi
"@
        
        $tempFile = "$env:TEMP\wsl-test.sh"
        $wslScript | Out-File -FilePath $tempFile -Encoding UTF8
        
        wsl -d Ubuntu-24.04 bash -c "$(Get-Content $tempFile -Raw)" 2>$null
        
        Remove-Item $tempFile -ErrorAction SilentlyContinue
        
    } catch {
        Write-Warning "WSL2 no está instalado o no está funcionando"
        Write-Info "Ejecuta: .\setup-wsl2.ps1 -Install"
    }
}

function Show-Recommendations {
    Write-Output ""
    Write-Output "💡 RECOMENDACIONES:"
    Write-Output "=================="
    Write-Output ""
    
    Write-Output "✅ Si ESXi es accesible desde Windows:"
    Write-Output "   - WSL2 también tendrá acceso"
    Write-Output "   - Puedes ejecutar el proyecto Ansible"
    Write-Output ""
    
    Write-Output "⚠️  Si ESXi NO es accesible:"
    Write-Output "   - Verificar que estás en la misma red"
    Write-Output "   - Verificar firewall de Windows"
    Write-Output "   - Verificar configuración de red"
    Write-Output ""
    
    Write-Output "🔧 Próximos pasos:"
    Write-Output "   1. Instalar WSL2: .\setup-wsl2.ps1 -Install"
    Write-Output "   2. Configurar Ubuntu: .\setup-wsl2.ps1 -Configure"
    Write-Output "   3. Clonar proyecto en WSL2"
    Write-Output "   4. Ejecutar: ./scripts/crear-vm-ubuntu.sh"
}

# Función principal
Write-Output "🔍 VERIFICACIÓN DE CONECTIVIDAD DESDE WINDOWS 11"
Write-Output "==============================================="

Test-NetworkConnectivity
Test-WSL2Status
Show-Recommendations

Write-Output ""
Write-Success "Verificación completada"