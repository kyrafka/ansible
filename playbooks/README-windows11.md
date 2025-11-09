# Windows 11 con Roles

## 🎯 Flujo de trabajo

### 1. Crear VM Windows 11
```bash
ansible-playbook playbooks/create-windows11.yml
```

Te pedirá:
- **Nombre de la VM**: Ejemplo: `win11-admin`, `win11-cliente01`
- **Rol**: `admin`, `auditor` o `cliente`

La VM se creará con recursos optimizados según el rol:
- **Admin**: 2 CPU, 4GB RAM, 80GB disco
- **Auditor**: 2 CPU, 3GB RAM, 40GB disco
- **Cliente**: 2 CPU, 4GB RAM, 60GB disco

### 2. Instalar Windows 11
1. La VM arrancará con la ISO de Windows 11
2. Instalar Windows normalmente
3. Configurar red (obtendrá IPv6 por DHCP del servidor)

### 3. Habilitar WinRM
Ejecutar en PowerShell como Administrador en la VM Windows:

```powershell
# Habilitar WinRM
Enable-PSRemoting -Force

# Configurar WinRM para HTTPS
$cert = New-SelfSignedCertificate -DnsName "localhost" -CertStoreLocation "Cert:\LocalMachine\My"
New-Item -Path WSMan:\LocalHost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $cert.Thumbprint -Force

# Abrir firewall
New-NetFirewallRule -DisplayName "WinRM HTTPS" -Direction Inbound -LocalPort 5986 -Protocol TCP -Action Allow

# Permitir conexiones remotas
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*" -Force
Restart-Service WinRM
```

### 4. Agregar al inventario
Editar `inventory/hosts.ini` y agregar en `[windows_desktops]`:

```ini
win11-admin ansible_host=2025:db8:10::20 vm_role=admin ansible_user=Administrador ansible_password="{{ vault_windows11_admin_password }}"
win11-cliente01 ansible_host=2025:db8:10::22 vm_role=cliente ansible_user=Gamer01 ansible_password="{{ vault_windows11_cliente_password }}"
```

### 5. Configurar rol
```bash
ansible-playbook playbooks/configure-windows-role.yml --limit win11-admin
```

## 🔐 Roles y Privilegios

### Admin
- **Usuario**: `Administrador`
- **Password**: `Admin123!` (en vault)
- **Grupos**: Administradores, Usuarios de escritorio remoto
- **Carpetas**: 
  - `C:\Admin` (privada)
  - `C:\Games` (compartida, puede instalar juegos)
  - `C:\Instaladores` (puede subir instaladores)
- **Firewall**: Permite SSH (22), HTTP (80), HTTPS (443), RDP (3389)
- **Acceso servidor**: ✅ Puede hacer SSH al servidor (si instala cliente SSH)
- **Permisos**: Acceso total, UAC deshabilitado

### Auditor
- **Usuario**: `Auditor`
- **Password**: `Audit123!` (en vault)
- **Grupos**: Usuarios, Lectores del registro de eventos
- **Carpetas**:
  - `C:\Audits` (privada)
  - `C:\Windows\System32\winevt\Logs` (solo lectura)
- **Firewall**: Solo RDP (3389), SSH bloqueado
- **Acceso servidor**: ❌ NO puede hacer SSH al servidor
- **Permisos**: Solo lectura de logs, no puede instalar software

### Cliente
- **Usuario**: `Gamer01`
- **Password**: `Gamer123!` (en vault)
- **Grupos**: Usuarios, PCGamers
- **Carpetas**:
  - `C:\Users\Gamer01` (privada)
  - `C:\Games` (compartida, solo lectura)
  - `C:\Instaladores` (solo lectura)
- **Firewall**: Solo salida (DNS, HTTP, HTTPS, DHCP), SSH bloqueado
- **Acceso servidor**: ❌ NO puede hacer SSH al servidor
- **Permisos**: Sin instalación de software, CMD/PowerShell deshabilitados

## 🌐 Red

Todas las VMs se conectan a `M_vm's` (switch interno) y obtienen IPv6 por DHCP:
- Red: `2025:db8:10::/64`
- Gateway: `2025:db8:10::1`
- Servidor: `2025:db8:10::2`
- VMs: `2025:db8:10::10+` (asignadas por DHCP)

## 🔥 Firewall del Servidor

El servidor filtra acceso según rol (Ubuntu y Windows):
- **Admin**: Puede SSH al servidor
- **Auditor**: NO puede SSH
- **Cliente**: NO puede SSH
- **Todos**: Pueden usar DNS y DHCP

Para aplicar reglas:
```bash
ansible-playbook playbook-firewall.yml
```

## 📝 Ejemplo completo

```bash
# 1. Crear VM admin
ansible-playbook playbooks/create-windows11.yml
# Nombre: win11-admin
# Rol: admin

# 2. Instalar Windows 11 en la VM

# 3. Habilitar WinRM (ver arriba)

# 4. Agregar a inventario
nano inventory/hosts.ini
# win11-admin ansible_host=2025:db8:10::20 vm_role=admin ansible_user=Administrador ansible_password="{{ vault_windows11_admin_password }}"

# 5. Configurar rol
ansible-playbook playbooks/configure-windows-role.yml --limit win11-admin

# 6. Actualizar firewall del servidor
ansible-playbook playbook-firewall.yml

# 7. Crear cliente
ansible-playbook playbooks/create-windows11.yml
# Nombre: win11-cliente01
# Rol: cliente

# 8. Configurar cliente
ansible-playbook playbooks/configure-windows-role.yml --limit win11-cliente01
```

## 🎮 Compartir juegos

El admin instala juegos en `C:\Games`:
```powershell
# Desde VM admin
Copy-Item -Path "C:\Users\Administrador\juego" -Destination "C:\Games\" -Recurse

# Dar permisos al grupo PCGamers
icacls "C:\Games\juego" /grant "PCGamers:(OI)(CI)RX" /T
```

Los clientes pueden acceder:
```powershell
# Desde VM cliente
dir C:\Games
C:\Games\juego\ejecutar.exe
```

## 🔑 Contraseñas

Todas las contraseñas están en `group_vars/all.vault.yml`:
```yaml
vault_windows11_admin_password: "Admin123!"
vault_windows11_auditor_password: "Audit123!"
vault_windows11_cliente_password: "Gamer123!"
```

Para encriptar:
```bash
ansible-vault encrypt group_vars/all.vault.yml
```

## 🐛 Troubleshooting

### Error de conexión WinRM
```bash
# Verificar conectividad
ansible windows_desktops -m win_ping

# Si falla, verificar en la VM Windows:
Test-WSMan -ComputerName localhost
Get-Service WinRM
```

### Firewall bloqueando WinRM
```powershell
# En la VM Windows
Get-NetFirewallRule -DisplayName "WinRM*"
Enable-NetFirewallRule -DisplayName "WinRM HTTPS"
```

## 📚 Diferencias con Ubuntu

| Característica | Ubuntu Desktop | Windows 11 |
|----------------|----------------|------------|
| Conexión | SSH | WinRM (HTTPS 5986) |
| Firewall | UFW | Windows Firewall |
| Permisos | chmod/chown | ACL (icacls) |
| Usuarios | useradd | win_user |
| Grupos | groupadd | win_group |
| Carpetas | /srv/games | C:\Games |
