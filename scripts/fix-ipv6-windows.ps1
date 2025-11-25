# ═══════════════════════════════════════════════════════════════
# Script para Diagnosticar y Configurar IPv6 en Windows
# ═══════════════════════════════════════════════════════════════

Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  DIAGNÓSTICO Y CONFIGURACIÓN IPv6 - WINDOWS" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# ═══════════════════════════════════════════════════════════════
# 1. VERIFICAR ESTADO DE IPv6
# ═══════════════════════════════════════════════════════════════
Write-Host "━━━ 1. VERIFICANDO ESTADO DE IPv6 ━━━" -ForegroundColor Yellow
Write-Host ""

# Verificar si IPv6 está habilitado
$ipv6Enabled = Get-NetAdapterBinding -ComponentID ms_tcpip6 | Where-Object {$_.Enabled -eq $true}
if ($ipv6Enabled) {
    Write-Host "✓ IPv6 está HABILITADO en los adaptadores" -ForegroundColor Green
    $ipv6Enabled | Format-Table Name, DisplayName, Enabled
} else {
    Write-Host "✗ IPv6 está DESHABILITADO" -ForegroundColor Red
    Write-Host ""
    Write-Host "Para habilitar IPv6, ejecuta como Administrador:" -ForegroundColor Yellow
    Write-Host "Enable-NetAdapterBinding -Name 'Ethernet*' -ComponentID ms_tcpip6" -ForegroundColor Cyan
    Write-Host ""
}

# ═══════════════════════════════════════════════════════════════
# 2. MOSTRAR DIRECCIONES IPv6 ACTUALES
# ═══════════════════════════════════════════════════════════════
Write-Host "━━━ 2. DIRECCIONES IPv6 ACTUALES ━━━" -ForegroundColor Yellow
Write-Host ""

$allIPv6 = Get-NetIPAddress -AddressFamily IPv6
Write-Host "Todas las direcciones IPv6:"
$allIPv6 | Format-Table IPAddress, InterfaceAlias, PrefixLength, Type

$globalIPv6 = $allIPv6 | Where-Object {$_.IPAddress -like "2025:*"}
if ($globalIPv6) {
    Write-Host "✓ Tienes direcciones IPv6 GLOBALES configuradas:" -ForegroundColor Green
    $globalIPv6 | Format-Table IPAddress, InterfaceAlias
} else {
    Write-Host "✗ NO tienes direcciones IPv6 GLOBALES (2025:db8:10::...)" -ForegroundColor Red
    Write-Host "  Solo tienes direcciones link-local (fe80::...)" -ForegroundColor Yellow
}
Write-Host ""

# ═══════════════════════════════════════════════════════════════
# 3. VERIFICAR ROUTER ADVERTISEMENTS (RA)
# ═══════════════════════════════════════════════════════════════
Write-Host "━━━ 3. VERIFICANDO ROUTER ADVERTISEMENTS ━━━" -ForegroundColor Yellow
Write-Host ""

$activeAdapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object -First 1
if ($activeAdapter) {
    Write-Host "Adaptador activo: $($activeAdapter.Name)"
    
    # Verificar configuración de autoconfiguración
    $ipInterface = Get-NetIPInterface -InterfaceAlias $activeAdapter.Name -AddressFamily IPv6
    Write-Host "Estado de autoconfiguración:"
    Write-Host "  RouterDiscovery: $($ipInterface.RouterDiscovery)"
    Write-Host "  ManagedAddressConfiguration: $($ipInterface.ManagedAddressConfiguration)"
    Write-Host "  OtherStatefulConfiguration: $($ipInterface.OtherStatefulConfiguration)"
    Write-Host ""
    
    if ($ipInterface.RouterDiscovery -eq "Disabled") {
        Write-Host "⚠ Router Discovery está DESHABILITADO" -ForegroundColor Yellow
        Write-Host "Para habilitar, ejecuta como Administrador:" -ForegroundColor Yellow
        Write-Host "Set-NetIPInterface -InterfaceAlias '$($activeAdapter.Name)' -AddressFamily IPv6 -RouterDiscovery Enabled" -ForegroundColor Cyan
        Write-Host ""
    }
}

# ═══════════════════════════════════════════════════════════════
# 4. VERIFICAR CONECTIVIDAD CON EL SERVIDOR
# ═══════════════════════════════════════════════════════════════
Write-Host "━━━ 4. VERIFICANDO CONECTIVIDAD CON EL SERVIDOR ━━━" -ForegroundColor Yellow
Write-Host ""

$serverIP = "2025:db8:10::2"
Write-Host "Intentando ping al servidor ($serverIP)..."
$pingResult = Test-Connection -ComputerName $serverIP -Count 2 -IPv6 -ErrorAction SilentlyContinue
if ($pingResult) {
    Write-Host "✓ Servidor ACCESIBLE" -ForegroundColor Green
} else {
    Write-Host "✗ Servidor NO ACCESIBLE" -ForegroundColor Red
    Write-Host "  Esto es normal si no tienes IPv6 global configurado" -ForegroundColor Yellow
}
Write-Host ""

# ═══════════════════════════════════════════════════════════════
# 5. VERIFICAR GATEWAY IPv6
# ═══════════════════════════════════════════════════════════════
Write-Host "━━━ 5. VERIFICANDO GATEWAY IPv6 ━━━" -ForegroundColor Yellow
Write-Host ""

$defaultRoute = Get-NetRoute -AddressFamily IPv6 -DestinationPrefix "::/0" -ErrorAction SilentlyContinue
if ($defaultRoute) {
    Write-Host "✓ Gateway IPv6 configurado:" -ForegroundColor Green
    $defaultRoute | Format-Table DestinationPrefix, NextHop, InterfaceAlias
} else {
    Write-Host "✗ NO hay gateway IPv6 configurado" -ForegroundColor Red
    Write-Host "  Esto significa que no estás recibiendo Router Advertisements" -ForegroundColor Yellow
}
Write-Host ""

# ═══════════════════════════════════════════════════════════════
# 6. VERIFICAR DHCP IPv6
# ═══════════════════════════════════════════════════════════════
Write-Host "━━━ 6. VERIFICANDO CLIENTE DHCPv6 ━━━" -ForegroundColor Yellow
Write-Host ""

$dhcpService = Get-Service -Name "Dhcp" -ErrorAction SilentlyContinue
if ($dhcpService) {
    if ($dhcpService.Status -eq "Running") {
        Write-Host "✓ Servicio DHCP Client: ACTIVO" -ForegroundColor Green
    } else {
        Write-Host "✗ Servicio DHCP Client: $($dhcpService.Status)" -ForegroundColor Red
        Write-Host "Para iniciar el servicio, ejecuta como Administrador:" -ForegroundColor Yellow
        Write-Host "Start-Service Dhcp" -ForegroundColor Cyan
    }
} else {
    Write-Host "✗ Servicio DHCP Client no encontrado" -ForegroundColor Red
}
Write-Host ""

# ═══════════════════════════════════════════════════════════════
# 7. SOLUCIONES PROPUESTAS
# ═══════════════════════════════════════════════════════════════
Write-Host "━━━ 7. SOLUCIONES ━━━" -ForegroundColor Yellow
Write-Host ""

if (-not $globalIPv6) {
    Write-Host "OPCIÓN A: Configuración Automática (DHCPv6 + RA)" -ForegroundColor Cyan
    Write-Host "─────────────────────────────────────────────────" -ForegroundColor Cyan
    Write-Host "1. Asegúrate que el servidor DHCP/RA esté funcionando"
    Write-Host "2. Reinicia el adaptador de red:"
    Write-Host "   Restart-NetAdapter -Name 'Ethernet*'" -ForegroundColor White
    Write-Host "3. Espera 10-30 segundos y verifica:"
    Write-Host "   Get-NetIPAddress -AddressFamily IPv6" -ForegroundColor White
    Write-Host ""
    
    Write-Host "OPCIÓN B: Configuración Manual (Temporal)" -ForegroundColor Cyan
    Write-Host "─────────────────────────────────────────────────" -ForegroundColor Cyan
    Write-Host "Si necesitas configurar manualmente una IP:"
    Write-Host ""
    
    if ($activeAdapter) {
        $suggestedIP = "2025:db8:10::100"  # IP de ejemplo
        Write-Host "# Configurar IP estática:" -ForegroundColor Green
        Write-Host "New-NetIPAddress -InterfaceAlias '$($activeAdapter.Name)' -IPAddress '$suggestedIP' -PrefixLength 64 -DefaultGateway '2025:db8:10::1'" -ForegroundColor White
        Write-Host ""
        Write-Host "# Configurar DNS:" -ForegroundColor Green
        Write-Host "Set-DnsClientServerAddress -InterfaceAlias '$($activeAdapter.Name)' -ServerAddresses '2025:db8:10::2','2001:4860:4860::8888'" -ForegroundColor White
        Write-Host ""
        Write-Host "⚠ NOTA: Cambia '$suggestedIP' por la IP que quieras usar" -ForegroundColor Yellow
        Write-Host "⚠ Verifica que no esté en uso con: Test-Connection -ComputerName $suggestedIP -Count 1" -ForegroundColor Yellow
    }
    Write-Host ""
    
    Write-Host "OPCIÓN C: Verificar el Servidor" -ForegroundColor Cyan
    Write-Host "─────────────────────────────────────────────────" -ForegroundColor Cyan
    Write-Host "En el servidor, verifica que estos servicios estén activos:"
    Write-Host "  sudo systemctl status radvd" -ForegroundColor White
    Write-Host "  sudo systemctl status isc-dhcp-server" -ForegroundColor White
    Write-Host ""
    Write-Host "Verifica los logs:"
    Write-Host "  sudo journalctl -u radvd -n 20" -ForegroundColor White
    Write-Host "  sudo journalctl -u isc-dhcp-server -n 20" -ForegroundColor White
}

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  FIN DEL DIAGNÓSTICO" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
