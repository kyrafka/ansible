# ═══════════════════════════════════════════════════════════════
# Script de Diagnóstico - WINDOWS 11
# ═══════════════════════════════════════════════════════════════

Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  DIAGNÓSTICO WINDOWS 11 - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# ═══════════════════════════════════════════════════════════════
# 1. INFORMACIÓN DEL SISTEMA
# ═══════════════════════════════════════════════════════════════
Write-Host "━━━ 1. INFORMACIÓN DEL SISTEMA ━━━" -ForegroundColor Yellow
$computerInfo = Get-ComputerInfo
Write-Host "Hostname: $env:COMPUTERNAME"
Write-Host "Sistema Operativo: $($computerInfo.OsName)"
Write-Host "Versión: $($computerInfo.OsVersion)"
Write-Host "Uptime: $((Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime | Select-Object -ExpandProperty Days) días"
Write-Host "Usuario actual: $env:USERNAME"
Write-Host ""

# ═══════════════════════════════════════════════════════════════
# 2. CONFIGURACIÓN DE RED
# ═══════════════════════════════════════════════════════════════
Write-Host "━━━ 2. CONFIGURACIÓN DE RED ━━━" -ForegroundColor Yellow
Write-Host ""
Write-Host "--- Adaptadores de red ---"
Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Format-Table Name, InterfaceDescription, Status, LinkSpeed

Write-Host "--- Direcciones IPv6 ---"
$ipv6Addresses = Get-NetIPAddress -AddressFamily IPv6 | Where-Object {$_.IPAddress -like "2025:*"}
if ($ipv6Addresses) {
    $ipv6Addresses | Format-Table IPAddress, InterfaceAlias, PrefixLength
    $myIPv6 = $ipv6Addresses[0].IPAddress
    Write-Host "Mi IPv6 principal: $myIPv6" -ForegroundColor Green
} else {
    Write-Host "No se encontraron direcciones IPv6 configuradas" -ForegroundColor Red
}
Write-Host ""

Write-Host "--- Gateway predeterminado ---"
Get-NetRoute -AddressFamily IPv6 -DestinationPrefix "::/0" | Format-Table DestinationPrefix, NextHop, InterfaceAlias
Write-Host ""

Write-Host "--- Servidores DNS ---"
Get-DnsClientServerAddress -AddressFamily IPv6 | Where-Object {$_.ServerAddresses} | Format-Table InterfaceAlias, ServerAddresses
Write-Host ""

# ═══════════════════════════════════════════════════════════════
# 3. CONECTIVIDAD - PING AL SERVIDOR
# ═══════════════════════════════════════════════════════════════
Write-Host "━━━ 3. CONECTIVIDAD CON EL SERVIDOR ━━━" -ForegroundColor Yellow
Write-Host ""

$serverIP = "2025:db8:10::2"
Write-Host "--- Ping al servidor ($serverIP) ---"
$pingResult = Test-Connection -ComputerName $serverIP -Count 4 -IPv6 -ErrorAction SilentlyContinue
if ($pingResult) {
    Write-Host "✓ Servidor: ACCESIBLE" -ForegroundColor Green
    $avgTime = ($pingResult | Measure-Object -Property ResponseTime -Average).Average
    Write-Host "Tiempo promedio de respuesta: $([math]::Round($avgTime, 2)) ms"
} else {
    Write-Host "✗ Servidor: NO ACCESIBLE" -ForegroundColor Red
}
Write-Host ""

# ═══════════════════════════════════════════════════════════════
# 4. CONECTIVIDAD - PING A UBUNTU
# ═══════════════════════════════════════════════════════════════
Write-Host "━━━ 4. CONECTIVIDAD CON UBUNTU DESKTOP ━━━" -ForegroundColor Yellow
Write-Host ""

$ubuntuIP = "2025:db8:10::dce9"
Write-Host "--- Ping a Ubuntu Desktop ($ubuntuIP) ---"
$pingResult = Test-Connection -ComputerName $ubuntuIP -Count 3 -IPv6 -ErrorAction SilentlyContinue
if ($pingResult) {
    Write-Host "✓ Ubuntu Desktop: ACCESIBLE" -ForegroundColor Green
    $avgTime = ($pingResult | Measure-Object -Property ResponseTime -Average).Average
    Write-Host "Tiempo promedio de respuesta: $([math]::Round($avgTime, 2)) ms"
} else {
    Write-Host "✗ Ubuntu Desktop: NO ACCESIBLE" -ForegroundColor Red
}
Write-Host ""

# ═══════════════════════════════════════════════════════════════
# 5. CONECTIVIDAD - PING A OTRAS WINDOWS
# ═══════════════════════════════════════════════════════════════
Write-Host "━━━ 5. CONECTIVIDAD CON OTRAS MÁQUINAS WINDOWS ━━━" -ForegroundColor Yellow
Write-Host ""

$windowsIPs = @{
    "Windows 11-01" = "2025:db8:10::11"
    "Windows 11-Gaming" = "2025:db8:10::56"
    "Windows 11-Office" = "2025:db8:10::72"
}

foreach ($machine in $windowsIPs.GetEnumerator()) {
    # Skip si es nuestra propia IP
    if ($machine.Value -eq $myIPv6) {
        Write-Host "--- $($machine.Key) ($($machine.Value)) ---"
        Write-Host "  (Esta es mi máquina)" -ForegroundColor Cyan
        Write-Host ""
        continue
    }
    
    Write-Host "--- Ping a $($machine.Key) ($($machine.Value)) ---"
    $pingResult = Test-Connection -ComputerName $machine.Value -Count 3 -IPv6 -ErrorAction SilentlyContinue
    if ($pingResult) {
        Write-Host "✓ $($machine.Key): ACCESIBLE" -ForegroundColor Green
        $avgTime = ($pingResult | Measure-Object -Property ResponseTime -Average).Average
        Write-Host "Tiempo promedio: $([math]::Round($avgTime, 2)) ms"
    } else {
        Write-Host "✗ $($machine.Key): NO ACCESIBLE" -ForegroundColor Red
    }
    Write-Host ""
}

# ═══════════════════════════════════════════════════════════════
# 6. CONECTIVIDAD EXTERNA
# ═══════════════════════════════════════════════════════════════
Write-Host "━━━ 6. CONECTIVIDAD EXTERNA ━━━" -ForegroundColor Yellow
Write-Host ""
Write-Host "--- Ping a Google DNS IPv6 ---"
$pingResult = Test-Connection -ComputerName "2001:4860:4860::8888" -Count 3 -IPv6 -ErrorAction SilentlyContinue
if ($pingResult) {
    Write-Host "✓ Internet IPv6: ACCESIBLE" -ForegroundColor Green
    $avgTime = ($pingResult | Measure-Object -Property ResponseTime -Average).Average
    Write-Host "Tiempo promedio: $([math]::Round($avgTime, 2)) ms"
} else {
    Write-Host "✗ Internet IPv6: NO ACCESIBLE" -ForegroundColor Red
}
Write-Host ""

# ═══════════════════════════════════════════════════════════════
# 7. DNS
# ═══════════════════════════════════════════════════════════════
Write-Host "━━━ 7. PRUEBAS DNS ━━━" -ForegroundColor Yellow
Write-Host ""
Write-Host "--- Resolución del servidor ---"
try {
    Resolve-DnsName -Name "servidor.gamecenter.lan" -Type AAAA -ErrorAction Stop | Format-Table Name, Type, IPAddress
} catch {
    Write-Host "Error al resolver servidor.gamecenter.lan" -ForegroundColor Red
}
Write-Host ""

Write-Host "--- Resolución externa ---"
try {
    Resolve-DnsName -Name "google.com" -Type AAAA -ErrorAction Stop | Select-Object -First 1 | Format-Table Name, Type, IPAddress
} catch {
    Write-Host "Error al resolver google.com" -ForegroundColor Red
}
Write-Host ""

# ═══════════════════════════════════════════════════════════════
# 8. FIREWALL
# ═══════════════════════════════════════════════════════════════
Write-Host "━━━ 8. ESTADO DEL FIREWALL ━━━" -ForegroundColor Yellow
Get-NetFirewallProfile | Format-Table Name, Enabled
Write-Host ""

# ═══════════════════════════════════════════════════════════════
# 9. SERVICIOS IMPORTANTES
# ═══════════════════════════════════════════════════════════════
Write-Host "━━━ 9. SERVICIOS IMPORTANTES ━━━" -ForegroundColor Yellow
$services = @("sshd", "Dnscache", "Dhcp", "WinRM")
foreach ($service in $services) {
    $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
    if ($svc) {
        if ($svc.Status -eq "Running") {
            Write-Host "✓ $service : ACTIVO" -ForegroundColor Green
        } else {
            Write-Host "✗ $service : $($svc.Status)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "- $service : NO INSTALADO" -ForegroundColor Gray
    }
}
Write-Host ""

# ═══════════════════════════════════════════════════════════════
# 10. RECURSOS DEL SISTEMA
# ═══════════════════════════════════════════════════════════════
Write-Host "━━━ 10. RECURSOS DEL SISTEMA ━━━" -ForegroundColor Yellow
Write-Host ""

Write-Host "--- Uso de CPU ---"
$cpu = Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average
Write-Host "CPU en uso: $([math]::Round($cpu.Average, 2))%"
Write-Host ""

Write-Host "--- Uso de Memoria ---"
$os = Get-CimInstance Win32_OperatingSystem
$totalMem = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
$freeMem = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
$usedMem = $totalMem - $freeMem
$memPercent = [math]::Round(($usedMem / $totalMem) * 100, 2)
Write-Host "Memoria Total: $totalMem GB"
Write-Host "Memoria Usada: $usedMem GB ($memPercent%)"
Write-Host "Memoria Libre: $freeMem GB"
Write-Host ""

Write-Host "--- Uso de Disco ---"
Get-PSDrive -PSProvider FileSystem | Where-Object {$_.Used -gt 0} | Format-Table Name, @{Name="Usado(GB)";Expression={[math]::Round($_.Used/1GB,2)}}, @{Name="Libre(GB)";Expression={[math]::Round($_.Free/1GB,2)}}, @{Name="Total(GB)";Expression={[math]::Round(($_.Used+$_.Free)/1GB,2)}}
Write-Host ""

# ═══════════════════════════════════════════════════════════════
# 11. USUARIOS Y GRUPOS
# ═══════════════════════════════════════════════════════════════
Write-Host "━━━ 11. USUARIOS Y GRUPOS ━━━" -ForegroundColor Yellow
Write-Host ""
Write-Host "--- Usuarios locales ---"
Get-LocalUser | Where-Object {$_.Enabled -eq $true} | Format-Table Name, Enabled, LastLogon
Write-Host ""

Write-Host "--- Grupos importantes ---"
$groups = @("Administradores", "Administrators", "pcgamers", "Usuarios", "Users")
foreach ($group in $groups) {
    $grp = Get-LocalGroup -Name $group -ErrorAction SilentlyContinue
    if ($grp) {
        Write-Host "Grupo: $($grp.Name)"
        try {
            $members = Get-LocalGroupMember -Group $grp.Name -ErrorAction SilentlyContinue
            if ($members) {
                $members | ForEach-Object { Write-Host "  - $($_.Name)" }
            }
        } catch {
            Write-Host "  (No se pudieron listar los miembros)"
        }
    }
}
Write-Host ""

Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  FIN DEL DIAGNÓSTICO" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
