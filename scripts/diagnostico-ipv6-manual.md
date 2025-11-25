# Diagnóstico Manual IPv6 - Windows

## 1. Verificar si IPv6 está habilitado

```powershell
# Ver estado de IPv6 en adaptadores
Get-NetAdapterBinding -ComponentID ms_tcpip6

# Debe mostrar "Enabled: True"
# Si está False, habilitar con:
Enable-NetAdapterBinding -Name "Ethernet*" -ComponentID ms_tcpip6
```

## 2. Ver TODAS las direcciones IPv6

```powershell
# Ver todas las IPs IPv6
Get-NetIPAddress -AddressFamily IPv6 | Format-Table IPAddress, InterfaceAlias, PrefixLength, Type

# Ver solo las que empiezan con 2025:
Get-NetIPAddress -AddressFamily IPv6 | Where-Object {$_.IPAddress -like "2025:*"}
```

**Deberías ver:**
- ✓ `fe80::...` (link-local) - Siempre presente
- ✓ `2025:db8:10::...` (global) - **Esta es la que falta**

## 3. Verificar Router Discovery (RA)

```powershell
# Ver configuración del adaptador activo
Get-NetIPInterface -AddressFamily IPv6 | Where-Object {$_.ConnectionState -eq "Connected"} | Format-Table InterfaceAlias, RouterDiscovery, ManagedAddressConfiguration, OtherStatefulConfiguration

# RouterDiscovery debe estar en "Enabled"
# ManagedAddressConfiguration debe estar en "Enabled" (para DHCPv6)
```

**Si RouterDiscovery está Disabled:**
```powershell
# Habilitar (reemplaza "Ethernet1" con tu adaptador)
Set-NetIPInterface -InterfaceAlias "Ethernet1" -AddressFamily IPv6 -RouterDiscovery Enabled
```

## 4. Verificar Gateway IPv6

```powershell
# Ver rutas IPv6
Get-NetRoute -AddressFamily IPv6 -DestinationPrefix "::/0"

# Debe mostrar NextHop: 2025:db8:10::1 (o fe80::...)
```

**Si NO hay gateway:**
- El servidor NO está enviando Router Advertisements (RA)
- O el firewall está bloqueando ICMPv6

## 5. Verificar servicio DHCP Client

```powershell
# Ver estado del servicio
Get-Service Dhcp

# Debe estar "Running"
# Si no, iniciar:
Start-Service Dhcp
```

## 6. Capturar tráfico ICMPv6 (Router Advertisements)

```powershell
# Escuchar Router Advertisements por 30 segundos
# Ejecutar como Administrador
netsh trace start capture=yes IPv6.Address=ff02::1 tracefile=C:\temp\ipv6-trace.etl maxsize=100

# Esperar 30 segundos...
# Detener:
netsh trace stop

# Ver el archivo con: Microsoft Message Analyzer o Wireshark
```

## 7. Reiniciar el adaptador de red

```powershell
# Ver adaptadores activos
Get-NetAdapter | Where-Object {$_.Status -eq "Up"}

# Reiniciar (reemplaza "Ethernet1" con tu adaptador)
Restart-NetAdapter -Name "Ethernet1"

# Esperar 10-30 segundos y verificar:
Get-NetIPAddress -AddressFamily IPv6
```

## 8. Limpiar caché y renovar

```powershell
# Limpiar caché de vecinos IPv6
Remove-NetNeighbor -AddressFamily IPv6 -Confirm:$false

# Limpiar rutas
Remove-NetRoute -AddressFamily IPv6 -Confirm:$false

# Reiniciar adaptador
Restart-NetAdapter -Name "Ethernet1"

# Esperar y verificar
Start-Sleep -Seconds 15
Get-NetIPAddress -AddressFamily IPv6
```

## 9. Verificar Firewall

```powershell
# Ver reglas de ICMPv6
Get-NetFirewallRule -DisplayName "*ICMPv6*" | Format-Table DisplayName, Enabled, Direction, Action

# Habilitar ICMPv6 si está bloqueado:
Enable-NetFirewallRule -DisplayName "Core Networking - Router Advertisement (ICMPv6-In)"
Enable-NetFirewallRule -DisplayName "Core Networking - Neighbor Discovery Advertisement (ICMPv6-In)"
```

## 10. Ver logs de eventos

```powershell
# Ver eventos de red recientes
Get-WinEvent -LogName "Microsoft-Windows-Dhcp-Client/Operational" -MaxEvents 20 | Format-Table TimeCreated, Message

# Ver eventos de Tcpip6
Get-WinEvent -LogName System -MaxEvents 50 | Where-Object {$_.ProviderName -like "*tcpip*"} | Format-Table TimeCreated, Message
```

---

## VERIFICAR EN EL SERVIDOR (Ubuntu)

Si Windows no recibe IPv6, el problema puede estar en el servidor:

### 1. Verificar servicios activos

```bash
# Ver estado de radvd (Router Advertisements)
sudo systemctl status radvd

# Ver estado de DHCPv6
sudo systemctl status isc-dhcp-server

# Si están inactivos, iniciar:
sudo systemctl start radvd
sudo systemctl start isc-dhcp-server
```

### 2. Ver logs del servidor

```bash
# Logs de radvd
sudo journalctl -u radvd -n 50 --no-pager

# Logs de DHCPv6
sudo journalctl -u isc-dhcp-server -n 50 --no-pager

# Ver leases activos
sudo cat /var/lib/dhcp/dhcpd6.leases
```

### 3. Verificar configuración de radvd

```bash
# Ver configuración
sudo cat /etc/radvd.conf

# Debe tener algo como:
# interface ens33 {
#   AdvSendAdvert on;
#   AdvManagedFlag on;
#   prefix 2025:db8:10::/64 {
#     AdvOnLink on;
#     AdvAutonomous off;
#   };
# };
```

### 4. Verificar que el servidor envía RA

```bash
# Capturar Router Advertisements
sudo tcpdump -i ens33 -vv icmp6 and 'ip6[40] == 134'

# Deberías ver paquetes cada 30-100 segundos
# Si no ves nada, radvd no está funcionando
```

### 5. Verificar firewall del servidor

```bash
# Ver reglas de firewall
sudo ufw status numbered

# Debe permitir:
# - DHCPv6 (puerto 547/udp)
# - ICMPv6 (para RA)

# Si no están, agregar:
sudo ufw allow 547/udp comment 'DHCPv6'
sudo ufw allow from any to ff02::1 comment 'ICMPv6 multicast'
```

### 6. Verificar interfaz de red del servidor

```bash
# Ver IPs del servidor
ip -6 addr show

# Debe tener:
# - 2025:db8:10::2/64 (o similar)
# - fe80::... (link-local)

# Ver si está enviando RA
cat /proc/sys/net/ipv6/conf/ens33/forwarding
# Debe ser 1 para enviar RA
```

---

## SOLUCIÓN RÁPIDA: Configuración Manual

Si necesitas que funcione YA mientras investigas:

```powershell
# En Windows (como Administrador):
# Reemplaza "Ethernet1" con tu adaptador
# Reemplaza la IP por una libre (ej: 2025:db8:10::200)

New-NetIPAddress -InterfaceAlias "Ethernet1" `
  -IPAddress "2025:db8:10::200" `
  -PrefixLength 64 `
  -DefaultGateway "2025:db8:10::1"

Set-DnsClientServerAddress -InterfaceAlias "Ethernet1" `
  -ServerAddresses "2025:db8:10::2","2001:4860:4860::8888"

# Verificar:
ping 2025:db8:10::2
```

---

## CHECKLIST DE DIAGNÓSTICO

### En Windows:
- [ ] IPv6 habilitado en adaptador
- [ ] RouterDiscovery habilitado
- [ ] Servicio DHCP Client corriendo
- [ ] Firewall permite ICMPv6
- [ ] No hay rutas estáticas conflictivas

### En el Servidor:
- [ ] radvd corriendo
- [ ] isc-dhcp-server corriendo
- [ ] Configuración correcta en /etc/radvd.conf
- [ ] Configuración correcta en /etc/dhcp/dhcpd6.conf
- [ ] Firewall permite DHCPv6 e ICMPv6
- [ ] IPv6 forwarding habilitado

### Red:
- [ ] Ambas máquinas en la misma red física
- [ ] No hay VLANs separándolas
- [ ] Switch/router no bloquea multicast IPv6
