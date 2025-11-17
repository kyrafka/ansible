# 🪟 Guía: VM Windows 11

Guía completa para crear y configurar una VM Windows 11 en el servidor GameCenter.

---

## 📋 Índice

1. [Requisitos](#requisitos)
2. [Crear la VM](#crear-la-vm)
3. [Instalar Windows 11](#instalar-windows-11)
4. [Habilitar SSH](#habilitar-ssh-opcional-pero-recomendado)
5. [Configurar Red IPv6](#configurar-red-ipv6)
6. [Configurar Usuarios](#configurar-usuarios)
7. [Instalar Software](#instalar-software)
8. [Troubleshooting](#troubleshooting)

---

## 1. Requisitos

### ISO de Windows 11

Descarga desde: https://www.microsoft.com/software-download/windows11

```bash
# Guardar en el servidor
sudo mv ~/Downloads/Win11*.iso /var/lib/libvirt/images/Win11.iso
```

### Recursos recomendados

| Uso | RAM | CPUs | Disco |
|-----|-----|------|-------|
| **Básico** (Office) | 2GB | 2 | 40GB |
| **Estándar** (navegación) | 4GB | 2 | 60GB |
| **Gaming** (juegos ligeros) | 8GB | 4 | 100GB |
| **Gaming Pro** (juegos AAA) | 16GB | 6 | 150GB |

---

## 2. Crear la VM

### Opción A: Script automático (recomendado)

```bash
cd ~/ansible

# VM estándar
./scripts/vms/crear-vm-windows11.sh

# VM para gaming
./scripts/vms/crear-vm-windows11.sh win11-gaming 8192 4 100

# VM para office
./scripts/vms/crear-vm-windows11.sh win11-office 2048 2 40
```

### Opción B: Manual con virt-manager

1. Abrir virt-manager
2. Click en "Crear nueva máquina virtual"
3. Seleccionar ISO de Windows 11
4. Configurar RAM y CPUs
5. Crear disco virtual
6. **Importante:** Antes de finalizar:
   - Agregar segundo CD con `virtio-win.iso`
   - Habilitar UEFI
   - Habilitar TPM 2.0
   - Habilitar Secure Boot

---

## 3. Instalar Windows 11

### Paso 1: Iniciar instalación

La VM se iniciará automáticamente con la instalación de Windows 11.

```bash
# Ver consola gráfica
virt-viewer windows11-01
```

### Paso 2: Cargar drivers de disco (IMPORTANTE)

Windows 11 no verá el disco virtual sin drivers VirtIO:

1. En la pantalla "¿Dónde quieres instalar Windows?"
2. Click en **"Cargar controlador"**
3. Click en **"Examinar"**
4. Seleccionar CD **"virtio-win"**
5. Navegar a: `amd64 → w11 → viostor.inf`
6. Click **"Aceptar"**
7. Ahora aparecerá el disco virtual

### Paso 3: Completar instalación

1. Seleccionar el disco y continuar
2. Esperar instalación (10-20 minutos)
3. Configurar región, teclado, etc.
4. **Crear cuenta local** (recomendado para laboratorio)
   - En "Iniciar sesión con Microsoft", click en "Opciones de inicio de sesión"
   - Seleccionar "Cuenta sin conexión"
   - Crear usuario: `admin` / contraseña: `123`

### Paso 4: Instalar drivers VirtIO completos

Después de iniciar Windows por primera vez:

1. Abrir **"Este equipo"**
2. Doble click en CD **"virtio-win"**
3. Ejecutar: **`virtio-win-guest-tools.exe`**
4. Instalar todo (siguiente, siguiente, finalizar)
5. **Reiniciar** la VM

Esto instala:
- ✅ Drivers de red (VirtIO Network)
- ✅ Drivers de gráficos (QXL)
- ✅ Drivers de balón de memoria
- ✅ Agente QEMU Guest Agent

---

## 4. Habilitar SSH (Opcional pero Recomendado)

Con SSH habilitado puedes usar Ansible para automatizar la configuración.

### Opción A: Script automático (recomendado)

1. En Windows, abrir **PowerShell como Administrador**
2. Copiar el script desde el servidor:

```bash
# En el servidor Ubuntu
cd ~/ansible
cat scripts/windows/setup-ssh-windows.ps1
```

3. Copiar el contenido y pegarlo en PowerShell de Windows
4. O descargar directamente:

```powershell
# En Windows PowerShell (como Admin)
cd C:\Users\admin\Downloads

# Si tienes internet en la VM
Invoke-WebRequest -Uri "http://[IPv6_SERVIDOR]/setup-ssh-windows.ps1" -OutFile "setup-ssh-windows.ps1"

# Ejecutar
.\setup-ssh-windows.ps1
```

### Opción B: Manual

```powershell
# En PowerShell como Administrador

# 1. Instalar OpenSSH Server
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# 2. Iniciar servicio
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'

# 3. Permitir en firewall
New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22

# 4. Verificar
Test-NetConnection -ComputerName localhost -Port 22
```

### Probar SSH desde el servidor

```bash
# En el servidor Ubuntu
ssh admin@[IPv6_DE_WINDOWS]

# Ejemplo:
ssh admin@fd00:cafe:cafe::100
```

---

## 5. Configurar Red IPv6

Windows 11 necesita configuración manual para IPv6.

### Paso 1: Obtener dirección IPv6

En el servidor Ubuntu:

```bash
# Ver VMs conectadas
sudo virsh net-dhcp-leases default

# Buscar la MAC de windows11-01
# Ejemplo: fd00:cafe:cafe::1234
```

### Paso 2: Configurar IPv6 en Windows

1. Abrir **"Configuración"** → **"Red e Internet"**
2. Click en **"Ethernet"** (o la conexión activa)
3. Click en **"Propiedades"**
4. Buscar **"Protocolo de Internet versión 6 (TCP/IPv6)"**
5. Click en **"Propiedades"**

Configurar:

```
☑ Usar la siguiente dirección IPv6:
  Dirección IPv6:     fd00:cafe:cafe::100  (la que te dio DHCP)
  Longitud prefijo:   64
  Puerta de enlace:   fd00:cafe:cafe::1

☑ Usar las siguientes direcciones de servidor DNS:
  DNS preferido:      fd00:cafe:cafe::1
  DNS alternativo:    (dejar vacío)
```

6. Click **"Aceptar"**
7. Click **"Cerrar"**

### Paso 3: Verificar conectividad

Abrir **PowerShell** o **CMD**:

```powershell
# Ver configuración IPv6
ipconfig

# Ping al servidor
ping fd00:cafe:cafe::1

# Ping a Google (vía NAT64)
ping google.com

# Navegar
# Abrir Edge/Chrome y visitar: https://www.google.com
```

---

## 6. Configurar Usuarios

### Opción A: Con Ansible (si SSH está habilitado)

```bash
# En el servidor Ubuntu
cd ~/ansible

# 1. Agregar la VM al inventario
nano inventory/hosts.ini

# Agregar:
[windows_vms]
windows11-01 ansible_host=fd00:cafe:cafe::100 ansible_user=admin ansible_password=123 ansible_connection=ssh ansible_shell_type=powershell

# 2. Ejecutar playbook
ansible-playbook -i inventory/hosts.ini playbooks/configure-windows11.yml
```

Esto creará automáticamente:
- ✅ Usuarios (admin, auditor, gamer01)
- ✅ Carpetas compartidas
- ✅ Permisos configurados
- ✅ Firewall configurado
- ✅ README en cada escritorio

### Opción B: Manual (sin SSH)

#### Crear usuarios con roles

Si no usaste Ansible, crear manualmente. Abrir **PowerShell como Administrador**:

```powershell
# Usuario administrador (ya existe: admin)

# Usuario auditor (solo lectura)
net user auditor 123 /add
net localgroup "Usuarios del registro de rendimiento" auditor /add
net localgroup "Lectores del registro de eventos" auditor /add

# Usuario gamer (usuario estándar)
net user gamer01 123 /add
net localgroup "Usuarios" gamer01 /add

# Ver usuarios creados
net user
```

#### Configurar permisos de carpetas

```powershell
# Crear carpetas compartidas
mkdir C:\Shared
mkdir C:\Shared\Admin
mkdir C:\Shared\Audits
mkdir C:\Shared\Games

# Permisos
icacls C:\Shared\Admin /grant admin:F
icacls C:\Shared\Audits /grant auditor:R
icacls C:\Shared\Games /grant gamer01:M
```

---

## 7. Instalar Software

### Actualizar Windows

1. **Configuración** → **Windows Update**
2. Click en **"Buscar actualizaciones"**
3. Instalar todas las actualizaciones
4. Reiniciar si es necesario

### Instalar software básico

#### Navegadores

```powershell
# Edge ya viene instalado

# Chrome (descargar desde edge)
# https://www.google.com/chrome/
```

#### Steam (para gaming)

```powershell
# Descargar desde:
# https://store.steampowered.com/about/

# O usar winget (Windows Package Manager)
winget install Valve.Steam
```

#### Otros útiles

```powershell
# 7-Zip
winget install 7zip.7zip

# VLC Media Player
winget install VideoLAN.VLC

# Discord
winget install Discord.Discord

# Visual Studio Code
winget install Microsoft.VisualStudioCode
```

---

## 8. Troubleshooting

### ❌ No aparece el disco durante instalación

**Problema:** Windows no ve el disco virtual

**Solución:**
1. Cargar drivers VirtIO (ver Paso 2 de instalación)
2. Verificar que el disco usa bus `virtio` en la configuración de la VM

### ❌ No hay red después de instalar Windows

**Problema:** No aparece adaptador de red

**Solución:**
1. Instalar `virtio-win-guest-tools.exe` desde el CD VirtIO
2. Reiniciar Windows
3. Verificar en "Administrador de dispositivos" que aparece "Red VirtIO Ethernet Adapter"

### ❌ No puedo acceder a Internet

**Problema:** IPv6 configurado pero sin Internet

**Verificar:**

```powershell
# 1. Ping al servidor
ping fd00:cafe:cafe::1
# Debe responder

# 2. Resolver DNS
nslookup google.com fd00:cafe:cafe::1
# Debe devolver una IPv6 (64:ff9b::...)

# 3. Ping a Google
ping google.com
# Debe responder
```

**Si falla el paso 1:** Problema de red local
- Verificar configuración IPv6 en Windows
- Verificar que la VM está en la red `default`

**Si falla el paso 2:** Problema de DNS64
- En el servidor: `sudo systemctl status named`
- Verificar configuración DNS64

**Si falla el paso 3:** Problema de NAT64
- En el servidor: `sudo systemctl status tayga`
- Verificar configuración NAT64

### ❌ Windows 11 pide TPM 2.0

**Problema:** Error durante instalación "Este PC no puede ejecutar Windows 11"

**Solución:**
1. Verificar que la VM tiene TPM habilitado:
   ```bash
   sudo virsh dumpxml windows11-01 | grep tpm
   ```
2. Si no aparece, agregar TPM:
   ```bash
   sudo virsh edit windows11-01
   ```
   Agregar dentro de `<devices>`:
   ```xml
   <tpm model='tpm-crb'>
     <backend type='emulator' version='2.0'/>
   </tpm>
   ```

### ❌ Rendimiento lento

**Optimizaciones:**

1. **Instalar VirtIO drivers** (mejora disco y red)
2. **Habilitar VirtIO Balloon** (mejor gestión de RAM)
3. **Usar CPU host-passthrough:**
   ```bash
   sudo virsh edit windows11-01
   ```
   Cambiar:
   ```xml
   <cpu mode='host-passthrough' check='none'/>
   ```

4. **Aumentar RAM/CPUs** si el servidor lo permite

### ❌ No puedo conectar por SSH

**Problema:** `ssh admin@[IPv6]` no conecta

**Verificar en Windows:**

```powershell
# 1. Verificar que SSH está corriendo
Get-Service sshd

# 2. Verificar puerto
Test-NetConnection -ComputerName localhost -Port 22

# 3. Ver logs de SSH
Get-Content C:\ProgramData\ssh\logs\sshd.log -Tail 20

# 4. Verificar firewall
Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP"
```

**Soluciones:**

```powershell
# Reiniciar SSH
Restart-Service sshd

# Verificar configuración
Get-Content C:\ProgramData\ssh\sshd_config

# Reinstalar (si es necesario)
Remove-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
```

### ❌ Ansible no puede conectar

**Problema:** `ansible windows_vms -m win_ping` falla

**Verificar:**

1. SSH funciona manualmente: `ssh admin@[IPv6]`
2. Inventario correcto:
   ```ini
   [windows_vms]
   windows11-01 ansible_host=fd00:cafe:cafe::100 ansible_user=admin ansible_password=123 ansible_connection=ssh ansible_shell_type=powershell
   ```
3. Instalar módulos de Windows en Ansible:
   ```bash
   pip install pywinrm
   ```

---

## 📊 Resumen de Usuarios

| Usuario | Contraseña | Rol | Permisos |
|---------|------------|-----|----------|
| **admin** | 123 | Administrador | Todo |
| **auditor** | 123 | Auditor | Solo lectura logs |
| **gamer01** | 123 | Usuario | Juegos y apps |

---

## 🎮 Siguiente Paso

Una vez configurada la VM Windows 11:

1. **Instalar juegos** (Steam, Epic, etc.)
2. **Configurar NFS** para compartir juegos entre VMs
3. **Crear más VMs** Windows para LAN parties

Ver: `GUIA-NFS-COMPARTIR-JUEGOS.md` (próximamente)

---

## 📚 Referencias

- [Documentación VirtIO](https://www.linux-kvm.org/page/WindowsGuestDrivers)
- [Windows 11 en KVM](https://www.reddit.com/r/VFIO/wiki/index)
- [Guía servidor](1-GUIA-SERVIDOR.md)
- [Guía Ubuntu Desktop](2-GUIA-VM-UBUNTU.md)

