# 📘 Manual de Administración del Sistema Operativo

## Infraestructura como Código (IaC) con Ansible

La administración del sistema se define como **Infraestructura como Código (IaC)** usando Ansible. Todo el ciclo de vida del servidor y sus clientes se gestiona a través del proyecto `ansible-gestion-despliegue`.

La arquitectura de Ansible se basa en un **nodo de control interno** (Servidor Ubuntu) que se configura a sí mismo (`localhost ansible_connection=local`) y gestiona los clientes remotos.

---

## 🏗️ Arquitectura del Proyecto

### Estructura de Roles

```
ansible-gestion-despliegue/
├── roles/
│   ├── common/              # Paquetes y servicios base
│   ├── network/             # Configuración de red IPv6
│   ├── dns_bind/            # Servidor DNS (BIND9)
│   ├── dhcpv6/              # Servidor DHCP IPv6
│   ├── firewall/            # Firewall (UFW) y fail2ban
│   ├── nfs_server/          # Servidor NFS
│   ├── samba/               # Servidor Samba
│   ├── ftp_server/          # Servidor FTP (vsftpd)
│   ├── server_users/        # Gestión de usuarios del servidor
│   ├── ubuntu_desktop/      # Configuración de clientes Ubuntu
│   └── windows11/           # Configuración de clientes Windows
├── playbooks/
│   └── vms/                 # Playbooks de creación de VMs
├── inventory/
│   ├── hosts.ini            # Inventario de hosts
│   └── group_vars/          # Variables por grupo
└── site.yml                 # Playbook principal
```

---

## 📋 Roles de Ansible - Documentación de Tareas

### 1️⃣ `roles/common` - Gestión de Servicios y Paquetes Base

Este rol garantiza que el servidor tenga el estado base correcto. Se encarga de:

**Tareas principales:**
- Actualizar el sistema (`apt update && apt upgrade`)
- Instalar paquetes esenciales:
  - `git`, `curl`, `wget`, `htop`, `net-tools`
  - `vim`, `nano`, `tree`
  - `python3`, `python3-pip`
- Configurar zona horaria (`America/Lima`)
- Habilitar servicios críticos:
  - `systemd-timesyncd` (sincronización de tiempo)
  - `ufw` (firewall)

**Archivo:** `roles/common/tasks/main.yml`

```yaml
- name: Actualizar sistema
  apt:
    update_cache: yes
    upgrade: dist

- name: Instalar paquetes base
  apt:
    name:
      - git
      - curl
      - wget
      - htop
      - net-tools
    state: present
```

---

### 2️⃣ `roles/network` - Configuración de Red IPv6

Este rol configura la red IPv6 del servidor.

**Tareas principales:**
- Configurar interfaz de red con IPv6 estática
- Habilitar IPv6 forwarding
- Configurar rutas por defecto
- Aplicar configuración con Netplan

**Variables importantes:**
```yaml
network_config:
  ipv6_network: "2025:db8:10::/64"
  ipv6_gateway: "2025:db8:10::1"
  server_ipv6: "2025:db8:10::2"
  interface: "ens34"
```

**Archivo:** `roles/network/templates/01-netcfg.yaml.j2`

---

### 3️⃣ `roles/dns_bind` - Servidor DNS (BIND9)

Este rol configura el servidor DNS para resolución de nombres local.

**Tareas principales:**
- Instalar BIND9
- Configurar zona directa (`gamecenter.lan`)
- Configurar zona inversa (resolución inversa IPv6)
- Configurar forwarders para DNS externos
- Habilitar y arrancar servicio `bind9`

**Archivos de configuración:**
- `named.conf.options` - Opciones globales
- `named.conf.local` - Zonas locales
- `db.gamecenter.lan` - Archivo de zona directa

**Registros DNS configurados:**
```
servidor.gamecenter.lan  → 2025:db8:10::2
www.gamecenter.lan       → 2025:db8:10::2 (CNAME)
```

---

### 4️⃣ `roles/dhcpv6` - Servidor DHCP IPv6

Este rol configura el servidor DHCP para asignación automática de IPs IPv6.

**Tareas principales:**
- Instalar `isc-dhcp-server6`
- Configurar rango de IPs
- Configurar opciones de DNS
- Habilitar servicio `isc-dhcp-server6`

**Configuración:**
```
Rango: 2025:db8:10::100 - 2025:db8:10::200
DNS: 2025:db8:10::2
Dominio: gamecenter.lan
```

---

### 5️⃣ `roles/firewall` - Seguridad y Protección Activa

Este rol implementa medidas de seguridad basadas en firewall y protección contra ataques.

**Tareas principales:**

#### Firewall (UFW)
- Configurar política por defecto: `deny incoming`, `allow outgoing`
- Permitir servicios necesarios:
  - SSH (22/tcp)
  - DNS (53/tcp, 53/udp)
  - HTTP (80/tcp)
  - HTTPS (443/tcp)
  - DHCP (547/udp)
  - Samba (445/tcp, 139/tcp)
  - FTP (21/tcp)
  - NFS (2049/tcp)

#### Protección contra Amenazas (fail2ban)
- Instalar y configurar `fail2ban`
- Monitorear logs de SSH
- Banear automáticamente IPs con intentos fallidos
- Configuración:
  - `maxretry: 5`
  - `bantime: 3600` (1 hora)
  - `findtime: 600` (10 minutos)

**Archivo:** `roles/firewall/templates/jail.local.j2`

```ini
[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
maxretry = 5
bantime = 3600
```

---

### 6️⃣ `roles/server_users` - Gestión de Usuarios y Roles

Este rol implementa una **política de privilegios mínimos** basada en roles.

**Usuarios configurados:**

#### 👤 Usuario `ubuntu` (Administrador)
- **Permisos:**
  - ✅ Acceso sudo completo sin contraseña
  - ✅ Puede hacer SSH desde clientes
  - ✅ Acceso total al sistema
- **Grupos:** `sudo`, `adm`, `systemd-journal`

#### 👤 Usuario `administrador` (Admin secundario)
- **Permisos:**
  - ✅ Acceso sudo completo
  - ✅ Gestión de servicios
  - ✅ Instalación de paquetes
- **Grupos:** `sudo`, `adm`

#### 👤 Usuario `jose` (Usuario estándar)
- **Permisos:**
  - ❌ Sin sudo
  - ✅ Acceso a recursos compartidos
  - ✅ Miembro del grupo `pcgamers`
- **Grupos:** `pcgamers`

**Archivo:** `roles/server_users/tasks/main.yml`

```yaml
- name: Crear usuario administrador
  user:
    name: administrador
    password: "{{ admin_password | password_hash('sha512') }}"
    groups: sudo,adm
    shell: /bin/bash
```

---

### 7️⃣ `roles/samba` - Servidor de Archivos Samba

Este rol configura el servidor Samba para compartir archivos con Windows y Linux.

**Recursos compartidos:**

#### 📁 [Publico]
- **Ruta:** `/srv/publico`
- **Permisos:** Lectura/Escritura para todos
- **Acceso:** Invitado (guest)

#### 📁 [Juegos]
- **Ruta:** `/srv/juegos`
- **Permisos:** Solo usuarios autorizados
- **Usuarios:** `jose`, `administrador`, `@pcgamers`

#### 📁 [Compartido]
- **Ruta:** `/srv/compartido`
- **Permisos:** Solo lectura
- **Acceso:** Invitado (guest)

**Archivo:** `roles/samba/templates/smb.conf.j2`

---

### 8️⃣ `roles/ftp_server` - Servidor FTP

Este rol configura el servidor FTP (vsftpd) para transferencia de archivos.

**Configuración:**
- Acceso anónimo habilitado
- Puerto: 21
- Directorio raíz: `/srv/ftp`
- Modo pasivo habilitado

---

### 9️⃣ `roles/ubuntu_desktop` - Configuración de Clientes Ubuntu

Este rol configura los clientes Ubuntu Desktop con usuarios diferenciados.

**Usuarios creados:**

#### 👤 administrador
- ✅ Sudo completo
- ✅ Puede SSH al servidor
- ✅ Escritura en `/srv/games`

#### 👤 auditor
- ⚠️ Sudo limitado (solo lectura de logs)
- ❌ NO puede SSH al servidor
- ✅ Solo lectura en `/srv/games`

#### 👤 gamer01
- ❌ Sin sudo
- ❌ NO puede SSH al servidor
- ✅ Solo lectura en `/srv/games`

**Archivo:** `roles/ubuntu_desktop/tasks/admin.yml`

```yaml
- name: Configurar sudoers para administrador
  lineinfile:
    path: /etc/sudoers.d/administrador
    line: "administrador ALL=(ALL) NOPASSWD: ALL"
    create: true
    mode: '0440'
```

---

## 🔄 Automatización de Tareas

### Script de Actualización Automática

El rol `server_services` despliega un script de actualización automática.

**Archivo:** `scripts/maintenance/update-system.sh`

```bash
#!/bin/bash
apt update
apt upgrade -y
apt autoremove -y
apt autoclean
```

**Servicio systemd:** `weekly-updates.service`
**Temporizador:** `weekly-updates.timer`
- Ejecuta cada domingo a las 3:00 AM
- Actualiza el sistema automáticamente

---

## 🔐 Guía de Seguridad

### Refuerzo de SSH

**Configuración aplicada:**
- ✅ `PermitRootLogin no` - Deshabilitar login como root
- ✅ `PasswordAuthentication yes` - Permitir autenticación por contraseña (para el proyecto)
- ✅ `PubkeyAuthentication yes` - Permitir autenticación por llave pública
- ✅ Banner de advertencia legal

**Archivo:** `/etc/ssh/sshd_config`

### Política de Firewall

```
Política por defecto:
  - Incoming: DENY
  - Outgoing: ALLOW
  - Routed: ALLOW

Servicios permitidos:
  - SSH (22/tcp)
  - DNS (53/tcp, 53/udp)
  - HTTP (80/tcp)
  - HTTPS (443/tcp)
  - Samba (445/tcp, 139/tcp)
  - FTP (21/tcp)
```

---

## 🌐 Interoperabilidad y Diseño Funcional

### Playbook Unificado

El playbook principal `site.yml` gestiona la interoperabilidad entre diferentes sistemas operativos.

**Estructura:**

```yaml
---
- name: Configurar servidor Ubuntu
  hosts: localhost
  connection: local
  become: true
  
  roles:
    - common
    - network
    - dns_bind
    - dhcpv6
    - firewall
    - nfs_server
    - samba
    - ftp_server
    - server_users
```

### Manejo de Sistemas Operativos

#### Conexión a Ubuntu Desktop
```yaml
# inventory/group_vars/ubuntu_desktop.yml
ansible_connection: ssh
ansible_user: ubuntu
ansible_become_password: "{{ vault_ubuntu_password }}"
```

#### Conexión a Windows 11
```yaml
# inventory/group_vars/windows11.yml
ansible_connection: winrm
ansible_user: Administrador
ansible_password: "{{ vault_windows_password }}"
ansible_winrm_transport: ntlm
ansible_winrm_server_cert_validation: ignore
```

### Tareas Específicas por SO

#### Windows
- Módulo: `ansible.windows.win_shell`
- Comandos: PowerShell nativo
- Ejemplo: `powercfg`, `ipconfig`

#### Linux
- Módulos: `ansible.builtin.apt`, `ansible.builtin.systemd`
- Gestión de paquetes con APT
- Gestión de servicios con systemd

---

## 📊 Comandos de Administración

### Ver estado de servicios
```bash
# DNS
sudo systemctl status bind9

# DHCP
sudo systemctl status isc-dhcp-server6

# Samba
sudo systemctl status smbd

# FTP
sudo systemctl status vsftpd

# Firewall
sudo ufw status verbose

# fail2ban
sudo fail2ban-client status
```

### Ver logs
```bash
# Logs del sistema
sudo journalctl -xe

# Logs de DNS
sudo tail -f /var/log/syslog | grep named

# Logs de DHCP
sudo tail -f /var/log/syslog | grep dhcpd

# Logs de fail2ban
sudo tail -f /var/log/fail2ban.log
```

### Gestión de usuarios
```bash
# Listar usuarios
cat /etc/passwd | grep -E "ubuntu|administrador|jose"

# Ver grupos
groups ubuntu
groups administrador
groups jose

# Ver permisos sudo
sudo -l -U ubuntu
```

---

## 🎯 Conclusión

Este manual documenta la administración del sistema basada en **Infraestructura como Código (IaC)** usando Ansible. Todos los componentes del sistema están versionados, automatizados y documentados, cumpliendo con los requisitos de:

- ✅ Gestión de servicios y paquetes
- ✅ Automatización de tareas administrativas
- ✅ Seguridad basada en usuarios y roles
- ✅ Protección activa con firewall y fail2ban
- ✅ Interoperabilidad entre sistemas operativos
- ✅ Diseño funcional con playbooks unificados

---

**Proyecto:** ansible-gestion-despliegue  
**Fecha:** Noviembre 2025  
**Versión:** 1.0
