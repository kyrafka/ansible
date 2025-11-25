# 📋 EVIDENCIAS PARA RÚBRICA - SISTEMAS OPERATIVOS

## Unidad 4: Conectividad y Configuración de Red

---

## 1️⃣ CONECTIVIDAD ENTRE DISTINTOS SO

### 🌐 Topología de Red

```
┌─────────────────────────────────────────────────────────────┐
│                    RED IPv6: 2025:db8:10::/64              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐         ┌──────────────┐                │
│  │ Ubuntu Server│◄────────►│Ubuntu Desktop│                │
│  │  ::2         │   SSH    │  ::100       │                │
│  │              │   DNS    │              │                │
│  │              │   DHCP   │              │                │
│  └──────┬───────┘          └──────────────┘                │
│         │                                                   │
│         │                  ┌──────────────┐                │
│         └──────────────────►│ Windows 11   │                │
│                   HTTP      │  ::101       │                │
│                   DNS       │              │                │
│                             └──────────────┘                │
└─────────────────────────────────────────────────────────────┘
```

### 📊 Tabla de Conectividad

| Origen | Destino | Protocolo | Puerto | Estado | Evidencia |
|--------|---------|-----------|--------|--------|-----------|
| Ubuntu Desktop → Servidor | SSH | TCP | 22 | ✅ Funcional | `ssh ubuntu@2025:db8:10::2` |
| Ubuntu Desktop → Servidor | DNS | UDP | 53 | ✅ Funcional | `dig @2025:db8:10::2 gamecenter.lan` |
| Ubuntu Desktop → Servidor | HTTP | TCP | 80 | ✅ Funcional | `curl http://gamecenter.lan` |
| Windows 11 → Servidor | DNS | UDP | 53 | ✅ Funcional | `nslookup gamecenter.lan` |
| Windows 11 → Servidor | HTTP | TCP | 80 | ✅ Funcional | Navegador web |
| Windows 11 → Servidor | SSH | TCP | 22 | ❌ Bloqueado | Solo rol Admin |
| Servidor → Internet | NAT64 | - | - | ✅ Funcional | `ping6 google.com` |

### 🧪 Script de Prueba de Conectividad

**Ubicación:** `scripts/diagnostics/test-connectivity-full.sh`

```bash
#!/bin/bash
# Prueba completa de conectividad entre sistemas

echo "════════════════════════════════════════════════════════"
echo "🌐 PRUEBA DE CONECTIVIDAD ENTRE SISTEMAS OPERATIVOS"
echo "════════════════════════════════════════════════════════"

# 1. Ping IPv6 al servidor
echo "1. Ping IPv6 al servidor (2025:db8:10::2)"
ping6 -c 4 2025:db8:10::2

# 2. Resolución DNS
echo "2. Resolución DNS"
dig @2025:db8:10::2 gamecenter.lan AAAA +short

# 3. Acceso HTTP
echo "3. Acceso HTTP al servidor web"
curl -6 http://gamecenter.lan -I

# 4. Prueba SSH (solo si eres admin)
echo "4. Verificar acceso SSH"
ssh -6 ubuntu@2025:db8:10::2 "hostname && uname -a"

# 5. Verificar servicios
echo "5. Puertos abiertos en el servidor"
nmap -6 2025:db8:10::2 -p 22,53,80

echo "════════════════════════════════════════════════════════"
echo "✅ Prueba completada"
```

### 📸 Comandos para Evidencias

**Desde Ubuntu Desktop:**
```bash
# Mostrar IP asignada por DHCP
ip -6 addr show | grep "inet6 2025"

# Ping al servidor
ping6 -c 4 2025:db8:10::2

# Resolución DNS
dig @2025:db8:10::2 gamecenter.lan AAAA

# Acceso web
curl http://gamecenter.lan

# SSH al servidor (solo admin)
ssh administrador@2025:db8:10::2
```

**Desde Windows 11:**
```powershell
# Mostrar IP asignada
ipconfig | findstr "IPv6"

# Ping al servidor
ping 2025:db8:10::2

# Resolución DNS
nslookup gamecenter.lan 2025:db8:10::2

# Acceso web (abrir navegador)
start http://gamecenter.lan
```

---

## 2️⃣ CONFIGURACIÓN DE RED Y SERVICIOS

### 📡 Tabla de Configuración de Red

#### Servidor Ubuntu (2025:db8:10::2)

| Interfaz | Tipo | Dirección IPv6 | Máscara | Gateway | Uso |
|----------|------|----------------|---------|---------|-----|
| **ens33** | WAN | DHCP IPv4 | /24 | Auto | Internet |
| **ens34** | LAN | 2025:db8:10::2 | /64 | - | Red interna VMs |
| **lo** | Loopback | ::1 | /128 | - | Local |

#### Clientes (DHCP)

| Host | IP Asignada | Máscara | Gateway | DNS | Rol |
|------|-------------|---------|---------|-----|-----|
| Ubuntu Desktop | 2025:db8:10::100 | /64 | ::1 | ::2 | Admin |
| Windows 11 | 2025:db8:10::101 | /64 | ::1 | ::2 | Cliente |

### 🔧 Servicios Configurados

| Servicio | Software | Puerto | Estado | Configuración |
|----------|----------|--------|--------|---------------|
| **DNS** | BIND9 | 53/TCP+UDP | ✅ Activo | `/etc/bind/named.conf` |
| **DHCP** | isc-dhcp-server6 | 547/UDP | ✅ Activo | `/etc/dhcp/dhcpd6.conf` |
| **Web** | Nginx | 80/TCP | ✅ Activo | `/etc/nginx/sites-available/` |
| **SSH** | OpenSSH | 22/TCP | ✅ Activo | `/etc/ssh/sshd_config` |
| **Firewall** | UFW | - | ✅ Activo | `ufw status` |
| **IDS** | fail2ban | - | ✅ Activo | `/etc/fail2ban/jail.local` |
| **NFS** | nfs-kernel-server | 2049/TCP | ✅ Activo | `/etc/exports` |

### 📋 Comandos de Verificación

```bash
# Ver configuración de red
ip -6 addr show ens34
ip -6 route show

# Estado de servicios
sudo systemctl status bind9
sudo systemctl status isc-dhcp-server6
sudo systemctl status nginx
sudo systemctl status ssh

# Firewall
sudo ufw status verbose

# Puertos abiertos
sudo ss -tulnp | grep -E ":(22|53|80|547)"
```

---

## 3️⃣ PARTICIONES Y ALMACENAMIENTO

### 💾 Esquema de Particiones del Servidor

```
┌─────────────────────────────────────────────────────────┐
│                    Disco: /dev/sda (20 GB)             │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  /dev/sda1  →  /boot      (1 GB)   ext4               │
│  /dev/sda2  →  LVM PV     (19 GB)                     │
│                                                         │
│  ┌─────────────────────────────────────────────────┐  │
│  │  Volume Group: ubuntu-vg                        │  │
│  ├─────────────────────────────────────────────────┤  │
│  │  /dev/ubuntu-vg/root  →  /       (10 GB) ext4  │  │
│  │  /dev/ubuntu-vg/var   →  /var    (5 GB)  ext4  │  │
│  │  /dev/ubuntu-vg/home  →  /home   (2 GB)  ext4  │  │
│  │  /dev/ubuntu-vg/swap  →  swap    (2 GB)        │  │
│  └─────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### 📊 Tabla de Particiones

| Partición | Punto de Montaje | Tamaño | Sistema de Archivos | Uso |
|-----------|------------------|--------|---------------------|-----|
| /dev/sda1 | /boot | 1 GB | ext4 | Kernel y bootloader |
| /dev/ubuntu-vg/root | / | 10 GB | ext4 | Sistema operativo |
| /dev/ubuntu-vg/var | /var | 5 GB | ext4 | Logs y servicios |
| /dev/ubuntu-vg/home | /home | 2 GB | ext4 | Usuarios |
| /dev/ubuntu-vg/swap | swap | 2 GB | swap | Memoria virtual |

### 🔍 Comandos de Verificación

```bash
# Ver particiones
lsblk
sudo fdisk -l

# Ver uso de disco
df -h

# Ver LVM
sudo pvdisplay    # Physical Volumes
sudo vgdisplay    # Volume Groups
sudo lvdisplay    # Logical Volumes

# Uso por directorio
du -sh /var/log
du -sh /home/*
```

### 📸 Script de Evidencia de Particiones

**Ubicación:** `scripts/diagnostics/show-partitions.sh`

---

## 4️⃣ GESTIÓN DE USUARIOS Y PERMISOS

### 👥 Tabla de Usuarios del Servidor

| Usuario | UID | Grupos | Shell | Sudo | Descripción |
|---------|-----|--------|-------|------|-------------|
| **ubuntu** | 1000 | sudo, adm | /bin/bash | ✅ Completo | Administrador principal |
| **auditor** | 1001 | auditors, adm | /bin/bash | ⚠️ Limitado | Solo lectura de logs |
| **dev** | 1002 | developers | /bin/bash | ⚠️ Limitado | Desarrollo |

### 👥 Tabla de Usuarios de Clientes Ubuntu

| Usuario | Grupos | Sudo | SSH al Servidor | Permisos |
|---------|--------|------|-----------------|----------|
| **administrador** | sudo, pcgamers | ✅ Sí | ✅ Permitido | Acceso total |
| **auditor** | auditors, adm | ❌ No | ❌ Bloqueado | Solo lectura |
| **gamer01** | pcgamers | ❌ No | ❌ Bloqueado | Solo juegos |

### 👥 Tabla de Usuarios de Windows 11

| Usuario | Grupo | Permisos | SSH al Servidor | Instalación Software |
|---------|-------|----------|-----------------|----------------------|
| **Administrador** | Administradores | Control total | ✅ Permitido | ✅ Sí |
| **Auditor** | Usuarios | Solo lectura | ❌ Bloqueado | ❌ No |
| **Gamer01** | PCGamers | Limitado | ❌ Bloqueado | ❌ No |

### 🔐 Permisos por Carpeta

| Carpeta | Propietario | Grupo | Permisos | Acceso |
|---------|-------------|-------|----------|--------|
| /srv/games | root | pcgamers | 2775 | Lectura: todos, Escritura: admin |
| /srv/instaladores | root | pcgamers | 2755 | Lectura: todos, Escritura: root |
| /var/log | root | adm | 0755 | Lectura: auditor, Escritura: root |
| /home/auditor | auditor | auditors | 0750 | Solo auditor |
| /home/gamer01 | gamer01 | pcgamers | 0750 | Solo gamer01 |

### 📋 Comandos de Verificación

```bash
# Ver usuarios
cat /etc/passwd | grep -E "ubuntu|auditor|dev|gamer01|administrador"

# Ver grupos
cat /etc/group | grep -E "sudo|auditors|pcgamers"

# Ver permisos sudo
sudo -l -U auditor
sudo -l -U dev

# Ver permisos de carpetas
ls -la /srv/games
ls -la /home/auditor
getfacl /srv/games
```

---

## 5️⃣ SEGURIDAD Y FIREWALL

### 🔥 Reglas de Firewall (UFW)

| Puerto | Protocolo | Servicio | Acción | Comentario |
|--------|-----------|----------|--------|------------|
| 22 | TCP | SSH | LIMIT | Rate limiting (6 conn/30s) |
| 53 | TCP+UDP | DNS | ALLOW | Servidor DNS |
| 80 | TCP | HTTP | ALLOW | Servidor web |
| 546 | UDP | DHCPv6 Client | ALLOW | Cliente DHCP |
| 547 | UDP | DHCPv6 Server | ALLOW | Servidor DHCP |
| 21000-21010 | TCP | FTP Pasivo | ALLOW | Transferencia archivos |
| Otros | Todos | - | DENY | Bloqueado por defecto |

### 🛡️ Protección fail2ban

| Servicio | Puerto | Intentos | Tiempo Ban | Estado |
|----------|--------|----------|------------|--------|
| SSH | 22 | 5 fallos | 10 minutos | ✅ Activo |
| Nginx | 80 | 5 fallos | 10 minutos | ✅ Activo |

### 🔐 Restricciones SSH

| Usuario/Rol | Acceso SSH | Método | Configuración |
|-------------|------------|--------|---------------|
| ubuntu | ✅ Permitido | Clave + Password | `/etc/ssh/sshd_config` |
| administrador | ✅ Permitido | Password | AllowUsers |
| auditor | ❌ Bloqueado | - | `/etc/ssh/ssh_config` Match User |
| gamer01 | ❌ Bloqueado | - | `/etc/ssh/ssh_config` Match User |
| root | ❌ Bloqueado | - | PermitRootLogin no |

### 📋 Comandos de Verificación

```bash
# Estado del firewall
sudo ufw status verbose
sudo ufw status numbered

# fail2ban
sudo fail2ban-client status
sudo fail2ban-client status sshd

# Logs de seguridad
sudo journalctl -u ssh -n 50
sudo tail -f /var/log/auth.log
```

---

## 6️⃣ AUTOMATIZACIÓN CON ANSIBLE

### 🤖 Roles Implementados

| Rol | Descripción | Archivos | Automatiza |
|-----|-------------|----------|------------|
| **common** | Configuración base | 5 tasks | Paquetes, timezone, hostname |
| **network** | Red IPv6 | 8 tasks | Netplan, radvd, NAT66 |
| **dns_bind** | DNS | 12 tasks | BIND9, zonas, DDNS |
| **dhcpv6** | DHCP | 6 tasks | isc-dhcp-server6 |
| **firewall** | Seguridad | 15 tasks | UFW, fail2ban, reglas |
| **server_users** | Usuarios | 10 tasks | Creación, permisos, sudo |
| **vmware** | VMs | 20 tasks | Creación automática de VMs |
| **ubuntu_desktop** | Clientes Ubuntu | 18 tasks | Usuarios, temas, permisos |
| **windows11** | Clientes Windows | 15 tasks | Usuarios, ACLs, firewall |

### 📊 Estadísticas de Automatización

```
Total de roles:        17
Total de tasks:        150+
Total de scripts:      100+
Líneas de código:      15,000+
Tiempo manual:         8 horas
Tiempo automatizado:   15 minutos
```

### 🚀 Playbooks Principales

| Playbook | Propósito | Tiempo |
|----------|-----------|--------|
| `site.yml` | Configurar servidor completo | ~10 min |
| `create-ubuntu-desktop.yml` | Crear VM Ubuntu | ~5 min |
| `create-windows11.yml` | Crear VM Windows | ~8 min |
| `configure-ubuntu-role.yml` | Configurar rol en Ubuntu | ~2 min |

### 📋 Evidencia de Ejecución

```bash
# Ejecutar configuración completa
ansible-playbook site.yml --connection=local --become --ask-become-pass

# Crear VM con rol específico
ansible-playbook playbooks/create-ubuntu-desktop.yml -e "vm_role=admin"

# Validar configuración
bash scripts/run/validate-all.sh
```

---

## 7️⃣ TOMA DE DECISIONES TÉCNICAS

### 🎯 Decisiones Justificadas

| Decisión | Alternativas | Elección | Justificación |
|----------|--------------|----------|---------------|
| **SO Servidor** | Debian, CentOS, Ubuntu | Ubuntu Server 24.04 LTS | Soporte 5 años, documentación, Ansible |
| **Red** | IPv4, Dual Stack, IPv6 | IPv6 puro | Aprendizaje, futuro, simplicidad |
| **DNS** | dnsmasq, Unbound, BIND9 | BIND9 | Estándar industria, DDNS, zonas |
| **DHCP** | dnsmasq, Kea, isc-dhcp | isc-dhcp-server6 | Estabilidad, integración BIND |
| **Firewall** | iptables, nftables, UFW | UFW + fail2ban | Simplicidad, protección activa |
| **Automatización** | Scripts, Puppet, Chef | Ansible | Agentless, YAML, comunidad |
| **Virtualización** | VirtualBox, KVM, VMware | VMware ESXi | Profesional, API, escalable |

### 📊 Comparativa de Sistemas Operativos

| Característica | Ubuntu Server | Debian | CentOS |
|----------------|---------------|--------|--------|
| Soporte LTS | 5 años | 3-5 años | 10 años |
| Actualizaciones | Frecuentes | Estables | Lentas |
| Documentación | Excelente | Buena | Buena |
| Ansible | Nativo | Nativo | Nativo |
| Comunidad | Grande | Grande | Media |
| **Elección** | ✅ | ❌ | ❌ |

---

## 8️⃣ COMANDOS PARA GENERAR EVIDENCIAS

### 📸 Capturas Necesarias

```bash
# 1. Conectividad
ping6 -c 4 2025:db8:10::2
ssh administrador@2025:db8:10::2
curl http://gamecenter.lan

# 2. Servicios
sudo systemctl status bind9
sudo systemctl status isc-dhcp-server6
sudo systemctl status nginx
sudo ufw status verbose

# 3. Particiones
lsblk
df -h
sudo lvdisplay

# 4. Usuarios
cat /etc/passwd | tail -10
groups administrador
sudo -l -U auditor

# 5. Red
ip -6 addr show
ip -6 route show
ss -tulnp

# 6. Seguridad
sudo fail2ban-client status
sudo tail -20 /var/log/auth.log
```

---

## ✅ CHECKLIST DE EVIDENCIAS

### Conectividad (Nivel 4)
- [ ] Captura de ping entre Ubuntu Desktop → Servidor
- [ ] Captura de ping entre Windows 11 → Servidor
- [ ] Captura de SSH desde Ubuntu Desktop
- [ ] Captura de acceso web desde Windows
- [ ] Tabla de conectividad completa

### Configuración de Red (Nivel 4)
- [ ] Tabla de IPs, máscaras, gateway
- [ ] Captura de `ip addr` y `ip route`
- [ ] Captura de servicios activos
- [ ] Tabla de puertos y servicios

### Particiones (Nivel 4)
- [ ] Captura de `lsblk`
- [ ] Captura de `df -h`
- [ ] Captura de LVM (`lvdisplay`)
- [ ] Diagrama de particiones

### Usuarios y Permisos (Nivel 4)
- [ ] Tabla de usuarios y grupos
- [ ] Captura de permisos sudo
- [ ] Captura de permisos de carpetas
- [ ] Evidencia de restricciones SSH

### Seguridad (Nivel 4)
- [ ] Captura de reglas UFW
- [ ] Captura de fail2ban activo
- [ ] Tabla de firewall
- [ ] Logs de seguridad

### Automatización (Nivel 4)
- [ ] Captura de ejecución de Ansible
- [ ] Lista de roles y playbooks
- [ ] Evidencia de creación automática de VM
- [ ] Scripts de validación

---

**Fecha de generación:** Noviembre 2025  
**Proyecto:** Infraestructura Game Center con IPv6  
**Curso:** Sistemas Operativos
