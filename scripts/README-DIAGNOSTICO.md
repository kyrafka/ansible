# Scripts de Diagnóstico de Red

Scripts para verificar la conectividad y estado de tu infraestructura IPv6.

## 📋 Scripts Disponibles

### 1. `diagnostico-servidor.sh` - Para el Servidor
Ejecutar en el servidor principal para verificar:
- Estado de servicios (DNS, DHCP, NFS, SSH, etc.)
- Conectividad con todos los clientes
- Leases DHCP activos
- Exportaciones NFS
- Recursos del sistema
- Puertos en escucha

**Uso:**
```bash
cd scripts
chmod +x diagnostico-servidor.sh
sudo ./diagnostico-servidor.sh
```

### 2. `diagnostico-ubuntu-desktop.sh` - Para Ubuntu Desktop
Ejecutar en máquinas Ubuntu Desktop para verificar:
- Configuración de red IPv6
- Conectividad con el servidor
- **Conectividad con todas las máquinas Windows** ✓
- DNS y resolución de nombres
- Montajes NFS
- Recursos del sistema

**Uso:**
```bash
cd scripts
chmod +x diagnostico-ubuntu-desktop.sh
./diagnostico-ubuntu-desktop.sh
```

### 3. `diagnostico-windows.ps1` - Para Windows 11
Ejecutar en máquinas Windows 11 para verificar:
- Configuración de red IPv6
- Conectividad con el servidor
- **Conectividad con Ubuntu Desktop** ✓
- Conectividad con otras máquinas Windows
- DNS y resolución de nombres
- Servicios importantes
- Recursos del sistema

**Uso:**
```powershell
cd scripts
powershell -ExecutionPolicy Bypass -File .\diagnostico-windows.ps1
```

O desde PowerShell:
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\diagnostico-windows.ps1
```

## 🔍 Qué Verifica Cada Script

### Conectividad Verificada

#### Desde Ubuntu Desktop:
- ✓ Ping al servidor (2025:db8:10::2)
- ✓ Ping a Windows 11-01 (2025:db8:10::11)
- ✓ Ping a Windows 11-Gaming (2025:db8:10::56)
- ✓ Ping a Windows 11-Office (2025:db8:10::72)
- ✓ Ping a Internet (Google DNS IPv6)

#### Desde Windows:
- ✓ Ping al servidor (2025:db8:10::2)
- ✓ Ping a Ubuntu Desktop (2025:db8:10::dce9)
- ✓ Ping a otras máquinas Windows
- ✓ Ping a Internet (Google DNS IPv6)

#### Desde Servidor:
- ✓ Ping a Ubuntu Desktop (2025:db8:10::dce9)
- ✓ Ping a todas las máquinas Windows

## 📊 Información Recopilada

Todos los scripts recopilan:
- **Red**: IPs, gateway, DNS, rutas
- **Conectividad**: Ping a todos los hosts de la red
- **DNS**: Resolución de nombres local y externa
- **Recursos**: CPU, memoria, disco
- **Servicios**: Estado de servicios críticos
- **Usuarios**: Usuarios y grupos del sistema

## 💾 Guardar Resultados

Para guardar la salida en un archivo:

**Linux:**
```bash
./diagnostico-servidor.sh > diagnostico-$(date +%Y%m%d-%H%M%S).txt
```

**Windows:**
```powershell
.\diagnostico-windows.ps1 | Out-File -FilePath "diagnostico-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
```

## 🚨 Solución de Problemas

### Si no hay conectividad:

1. **Verificar IPv6 está habilitado:**
   - Linux: `ip -6 addr show`
   - Windows: `Get-NetIPAddress -AddressFamily IPv6`

2. **Verificar firewall:**
   - Linux: `sudo ufw status`
   - Windows: `Get-NetFirewallProfile`

3. **Verificar rutas:**
   - Linux: `ip -6 route show`
   - Windows: `Get-NetRoute -AddressFamily IPv6`

4. **Verificar servicios en el servidor:**
   ```bash
   sudo systemctl status bind9
   sudo systemctl status isc-dhcp-server
   sudo systemctl status radvd
   ```

## 📝 IPs de Referencia

| Host | IPv6 |
|------|------|
| Servidor | 2025:db8:10::2 |
| Ubuntu Desktop | 2025:db8:10::dce9 |
| Windows 11-01 | 2025:db8:10::11 |
| Windows 11-Gaming | 2025:db8:10::56 |
| Windows 11-Office | 2025:db8:10::72 |
| Google DNS | 2001:4860:4860::8888 |

## 🔄 Ejecución Automática

Para ejecutar periódicamente y monitorear:

**Linux (cron):**
```bash
# Ejecutar cada hora
0 * * * * /ruta/a/scripts/diagnostico-ubuntu-desktop.sh >> /var/log/diagnostico.log 2>&1
```

**Windows (Task Scheduler):**
```powershell
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File C:\ruta\scripts\diagnostico-windows.ps1"
$trigger = New-ScheduledTaskTrigger -Daily -At 9am
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "Diagnostico Red" -Description "Diagnóstico diario de red"
```
