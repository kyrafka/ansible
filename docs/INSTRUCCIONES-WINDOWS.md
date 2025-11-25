# 🪟 INSTRUCCIONES ESPECÍFICAS PARA WINDOWS 11

## Demostración de Seguridad, Particiones, Roles y Automatización

---

## 🎯 OBJETIVO

Demostrar en Windows 11:
1. **Seguridad:** Firewall, usuarios, permisos
2. **Particiones:** Esquema de discos
3. **Roles:** Admin, Auditor, Cliente con diferentes accesos
4. **Automatización:** Configuración con Ansible

---

## 1️⃣ PREPARACIÓN INICIAL

### Requisitos:
- Windows 11 Home/Pro
- PowerShell como Administrador
- Red IPv6 configurada (DHCP automático)
- Ansible ejecutado desde el servidor

---

## 2️⃣ SCRIPT DE EVIDENCIAS COMPLETO

### Ejecutar script principal:

```powershell
# 1. Abrir PowerShell como Administrador
# Click derecho en el menú Inicio → Windows PowerShell (Admin)

# 2. Navegar al proyecto
cd C:\ansible-gestion-despliegue

# 3. Ejecutar script de evidencias
PowerShell -ExecutionPolicy Bypass -File scripts\windows\Test-WindowsEvidence.ps1
```

**Este script genera:**
- Información del sistema
- Configuración de red IPv6
- Pruebas de conectividad
- Usuarios y grupos
- Permisos de carpetas
- Reglas de firewall
- Particiones y discos
- Servicios importantes

---

## 3️⃣ DEMOSTRACIÓN DE SEGURIDAD

### A. Firewall de Windows

#### Ver estado del firewall:
```powershell
Get-NetFirewallProfile | Format-Table Name, Enabled
```

**Captura esperada:**
```
Name    Enabled
----    -------
Domain  True
Private True
Public  True
```

#### Ver reglas personalizadas:
```powershell
Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*Admin*" -or $_.DisplayName -like "*Auditor*" -or $_.DisplayName -like "*Cliente*"} | Format-Table DisplayName, Direction, Action, Enabled
```

**Reglas esperadas:**
- `Admin - SSH`: Outbound, Allow (solo para Admin)
- `Admin - RDP`: Inbound, Allow
- `Auditor - Bloquear SSH`: Outbound, Block
- `Cliente - Bloquear SSH`: Outbound, Block

#### Crear regla de firewall manualmente (ejemplo):
```powershell
# Bloquear SSH saliente para usuario Cliente
New-NetFirewallRule -DisplayName "Cliente - Bloquear SSH" `
    -Direction Outbound `
    -Action Block `
    -Protocol TCP `
    -RemotePort 22 `
    -Enabled True
```

### B. Usuarios y Grupos

#### Ver usuarios locales:
```powershell
Get-LocalUser | Format-Table Name, Enabled, Description
```

**Usuarios esperados:**
- `Administrador` - Enabled: True
- `Auditor` - Enabled: True
- `Gamer01` - Enabled: True

#### Ver grupos locales:
```powershell
Get-LocalGroup | Format-Table Name, Description
```

**Grupos esperados:**
- `Administradores`
- `PCGamers`
- `Usuarios`

#### Ver miembros de un grupo:
```powershell
Get-LocalGroupMember -Group "Administradores"
Get-LocalGroupMember -Group "PCGamers"
```

#### Crear usuario manualmente (ejemplo):
```powershell
# Crear usuario Gamer01
New-LocalUser -Name "Gamer01" `
    -Password (ConvertTo-SecureString "Game123!" -AsPlainText -Force) `
    -FullName "Usuario Gamer" `
    -Description "Usuario de gaming sin privilegios"

# Agregar a grupo PCGamers
Add-LocalGroupMember -Group "PCGamers" -Member "Gamer01"
```

### C. Permisos de Carpetas (ACLs)

#### Ver permisos de C:\Games:
```powershell
Get-Acl C:\Games | Format-List
```

**O en formato tabla:**
```powershell
Get-Acl C:\Games | Select-Object -ExpandProperty Access | Format-Table IdentityReference, FileSystemRights, AccessControlType
```

**Permisos esperados:**
- `Administrador`: FullControl, Allow
- `PCGamers`: ReadAndExecute, Allow
- `Gamer01`: ReadAndExecute, Allow

#### Ver permisos de todas las carpetas importantes:
```powershell
$folders = @("C:\Games", "C:\Instaladores", "C:\Admin", "C:\Audits")
foreach ($folder in $folders) {
    if (Test-Path $folder) {
        Write-Host "`n=== Permisos de $folder ===" -ForegroundColor Cyan
        Get-Acl $folder | Select-Object -ExpandProperty Access | Format-Table IdentityReference, FileSystemRights, AccessControlType
    }
}
```

#### Configurar permisos manualmente (ejemplo):
```powershell
# Dar permisos de lectura a PCGamers en C:\Games
$acl = Get-Acl "C:\Games"
$permission = "PCGamers", "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow"
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
$acl.SetAccessRule($accessRule)
Set-Acl "C:\Games" $acl
```

---

## 4️⃣ DEMOSTRACIÓN DE PARTICIONES

### A. Ver discos físicos:
```powershell
Get-Disk | Format-Table Number, FriendlyName, Size, PartitionStyle
```

**Captura esperada:**
```
Number FriendlyName        Size PartitionStyle
------ ------------        ---- --------------
0      VMware Virtual disk 60GB GPT
```

### B. Ver particiones:
```powershell
Get-Partition | Format-Table DiskNumber, PartitionNumber, DriveLetter, Size, Type
```

**Captura esperada:**
```
DiskNumber PartitionNumber DriveLetter Size   Type
---------- --------------- ----------- ----   ----
0          1                           100MB  System
0          2                           16MB   Reserved
0          3               C           59GB   Basic
```

### C. Ver volúmenes y uso de espacio:
```powershell
Get-Volume | Where-Object {$_.DriveLetter} | Format-Table DriveLetter, FileSystemLabel, FileSystem, Size, SizeRemaining
```

**Captura esperada:**
```
DriveLetter FileSystemLabel FileSystem Size  SizeRemaining
----------- --------------- ---------- ----  -------------
C           Windows         NTFS       59GB  45GB
```

### D. Administrador de discos (GUI):
```powershell
# Abrir Administrador de discos
diskmgmt.msc
```

**Tomar captura de pantalla mostrando:**
- Disco 0 con particiones
- Volumen C: con espacio usado/libre
- Tipo de partición (GPT/MBR)

### E. Crear partición adicional (opcional):
```powershell
# Ver espacio no asignado
Get-Disk

# Crear nueva partición (si hay espacio)
New-Partition -DiskNumber 0 -Size 10GB -DriveLetter D
Format-Volume -DriveLetter D -FileSystem NTFS -NewFileSystemLabel "Datos"
```

---

## 5️⃣ DEMOSTRACIÓN DE ROLES Y ACCESOS

### A. Probar Rol Administrador

```powershell
# Login como Administrador

# 1. Verificar permisos de administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
Write-Host "Es Administrador: $isAdmin"

# 2. Acceso a carpetas
Test-Path C:\Admin          # Debería ser True
Test-Path C:\Games          # Debería ser True
Test-Path C:\Instaladores   # Debería ser True

# 3. Puede instalar software
Write-Host "Puede instalar software: Sí"

# 4. Puede SSH al servidor
Test-NetConnection -ComputerName 2025:db8:10::2 -Port 22
```

**Evidencias:**
- ✅ Es administrador
- ✅ Acceso a todas las carpetas
- ✅ Puede instalar software
- ✅ SSH permitido

### B. Probar Rol Auditor

```powershell
# Login como Auditor

# 1. Verificar permisos
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
Write-Host "Es Administrador: $isAdmin"  # Debería ser False

# 2. Acceso a carpetas
Test-Path C:\Audits         # Debería ser True
Test-Path C:\Admin          # Debería ser False
Test-Path C:\Games          # Debería ser True (solo lectura)

# 3. Intentar crear archivo en C:\Games
New-Item -Path "C:\Games\test.txt" -ItemType File  # Debería fallar

# 4. SSH bloqueado
Test-NetConnection -ComputerName 2025:db8:10::2 -Port 22  # Debería fallar
```

**Evidencias:**
- ❌ NO es administrador
- ✅ Acceso a C:\Audits
- ❌ Sin acceso a C:\Admin
- ✅ Solo lectura en C:\Games
- ❌ SSH bloqueado

### C. Probar Rol Cliente (Gamer01)

```powershell
# Login como Gamer01

# 1. Verificar permisos
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
Write-Host "Es Administrador: $isAdmin"  # Debería ser False

# 2. Acceso a carpetas
Test-Path C:\Games          # Debería ser True (solo lectura)
Test-Path C:\Instaladores   # Debería ser True (solo lectura)
Test-Path C:\Admin          # Debería ser False
Test-Path C:\Audits         # Debería ser False

# 3. Intentar crear archivo
New-Item -Path "C:\Games\test.txt" -ItemType File  # Debería fallar

# 4. SSH bloqueado
Test-NetConnection -ComputerName 2025:db8:10::2 -Port 22  # Debería fallar
```

**Evidencias:**
- ❌ NO es administrador
- ✅ Solo lectura en C:\Games
- ✅ Solo lectura en C:\Instaladores
- ❌ Sin acceso a C:\Admin ni C:\Audits
- ❌ SSH bloqueado

---

## 6️⃣ DEMOSTRACIÓN DE CONECTIVIDAD

### A. Configuración de red:
```powershell
# Ver configuración IPv6
ipconfig | findstr "IPv6"
```

**Captura esperada:**
```
Dirección IPv6 . . . . . . . . . . : 2025:db8:10::110
```

### B. Ping al servidor:
```powershell
ping 2025:db8:10::2
```

**Captura esperada:**
```
Haciendo ping a 2025:db8:10::2 con 32 bytes de datos:
Respuesta desde 2025:db8:10::2: tiempo<1ms
```

### C. Resolución DNS:
```powershell
nslookup gamecenter.lan 2025:db8:10::2
```

**Captura esperada:**
```
Servidor:  gamecenter.lan
Address:  2025:db8:10::2

Nombre:  gamecenter.lan
Address:  2025:db8:10::2
```

### D. Acceso web:
```powershell
# Abrir navegador
start http://gamecenter.lan

# O probar con PowerShell
Invoke-WebRequest -Uri "http://gamecenter.lan" -UseBasicParsing
```

**Tomar captura del navegador mostrando la página**

---

## 7️⃣ DEMOSTRACIÓN DE AUTOMATIZACIÓN

### A. Mostrar que Windows fue configurado con Ansible:

```powershell
# Ver archivos de configuración de Ansible
Get-ChildItem C:\ansible-gestion-despliegue\roles\windows11\

# Ver playbook de Windows
Get-Content C:\ansible-gestion-despliegue\playbooks\create-windows11.yml
```

### B. Ver logs de configuración:

```powershell
# Ver eventos de WinRM (usado por Ansible)
Get-EventLog -LogName Application -Source "Windows Remote Management" -Newest 10
```

### C. Mostrar configuración aplicada:

```powershell
# Ver usuarios creados
Get-LocalUser | Where-Object {$_.Name -in @("Administrador", "Auditor", "Gamer01")}

# Ver grupos creados
Get-LocalGroup | Where-Object {$_.Name -eq "PCGamers"}

# Ver carpetas creadas
Get-ChildItem C:\ | Where-Object {$_.Name -in @("Games", "Instaladores", "Admin", "Audits")}
```

---

## 8️⃣ TABLA RESUMEN DE PERMISOS

| Acción | Administrador | Auditor | Gamer01 |
|--------|---------------|---------|---------|
| **Permisos de administrador** | ✅ Sí | ❌ No | ❌ No |
| **Acceso C:\Admin** | ✅ Total | ❌ No | ❌ No |
| **Acceso C:\Games** | ✅ Total | ✅ Lectura | ✅ Lectura |
| **Acceso C:\Instaladores** | ✅ Total | ❌ No | ✅ Lectura |
| **Acceso C:\Audits** | ✅ Total | ✅ Total | ❌ No |
| **Instalar software** | ✅ Sí | ❌ No | ❌ No |
| **SSH al servidor** | ✅ Sí | ❌ No | ❌ No |
| **Acceso web** | ✅ Sí | ✅ Sí | ✅ Sí |
| **Acceso DNS** | ✅ Sí | ✅ Sí | ✅ Sí |

---

## 9️⃣ COMANDOS PARA CAPTURAS DE PANTALLA

### Capturas obligatorias:

```powershell
# 1. Sistema operativo
Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion

# 2. Red IPv6
ipconfig

# 3. Ping al servidor
ping 2025:db8:10::2

# 4. DNS
nslookup gamecenter.lan 2025:db8:10::2

# 5. Usuarios
Get-LocalUser

# 6. Grupos
Get-LocalGroup
Get-LocalGroupMember -Group "Administradores"

# 7. Permisos de carpetas
Get-Acl C:\Games | Format-List

# 8. Firewall
Get-NetFirewallProfile
Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*Admin*"}

# 9. Particiones
Get-Disk
Get-Partition
Get-Volume

# 10. Administrador de discos (GUI)
diskmgmt.msc
```

---

## 🔟 TROUBLESHOOTING

### Problema: No hay conectividad IPv6

```powershell
# Verificar adaptador de red
Get-NetAdapter

# Verificar IPv6 habilitado
Get-NetAdapterBinding -ComponentID ms_tcpip6

# Renovar IP
ipconfig /release6
ipconfig /renew6
```

### Problema: DNS no resuelve

```powershell
# Verificar servidor DNS
Get-DnsClientServerAddress -AddressFamily IPv6

# Configurar DNS manualmente
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses "2025:db8:10::2"

# Limpiar caché DNS
ipconfig /flushdns
```

### Problema: Firewall bloqueando todo

```powershell
# Ver reglas activas
Get-NetFirewallRule | Where-Object {$_.Enabled -eq $true}

# Deshabilitar regla específica
Disable-NetFirewallRule -DisplayName "Nombre de la regla"

# Habilitar regla
Enable-NetFirewallRule -DisplayName "Nombre de la regla"
```

---

## ✅ CHECKLIST DE DEMOSTRACIÓN

### Antes de presentar:

- [ ] Windows 11 encendido y funcionando
- [ ] Red IPv6 configurada (DHCP)
- [ ] Usuarios creados (Administrador, Auditor, Gamer01)
- [ ] Carpetas creadas (C:\Games, C:\Instaladores, etc.)
- [ ] Firewall configurado con reglas por rol
- [ ] Conectividad al servidor funcionando
- [ ] Script de evidencias ejecutado
- [ ] Capturas de pantalla tomadas
- [ ] Administrador de discos abierto

---

## 🎯 ORDEN SUGERIDO DE DEMOSTRACIÓN

1. **Mostrar sistema operativo** (1 min)
   - `Get-ComputerInfo`

2. **Mostrar red IPv6** (2 min)
   - `ipconfig`
   - `ping 2025:db8:10::2`
   - `nslookup gamecenter.lan`

3. **Mostrar usuarios y grupos** (3 min)
   - `Get-LocalUser`
   - `Get-LocalGroup`
   - `Get-LocalGroupMember`

4. **Mostrar permisos diferenciados** (5 min)
   - Login como cada usuario
   - Intentar acceder a carpetas
   - Mostrar SSH bloqueado/permitido

5. **Mostrar particiones** (2 min)
   - `Get-Disk`, `Get-Partition`, `Get-Volume`
   - Administrador de discos (GUI)

6. **Mostrar firewall** (2 min)
   - `Get-NetFirewallProfile`
   - `Get-NetFirewallRule`

7. **Mostrar automatización** (2 min)
   - Archivos de Ansible
   - Configuración aplicada

---

**¡Éxito en tu demostración de Windows! 🪟🚀**
