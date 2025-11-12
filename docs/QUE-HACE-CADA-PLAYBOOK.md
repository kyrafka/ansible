# 📋 ¿Qué Hace Cada Playbook?

Documentación detallada de todos los playbooks y sus funciones.

---

## 🏗️ PLAYBOOKS DE INFRAESTRUCTURA

### 1. `playbooks/infrastructure/playbook-common.yml`

**Script:** `bash scripts/run/run-common.sh`

**¿Qué hace?**
- ✅ Instala paquetes esenciales del sistema
- ✅ Configura logging centralizado (rsyslog)
- ✅ Configura rotación de logs (logrotate)
- ✅ Crea directorios de logs del proyecto
- ✅ Instala herramientas de monitoreo

**Paquetes instalados:**
- `ufw` - Firewall
- `fail2ban` - Protección contra ataques
- `net-tools` - Herramientas de red
- `curl`, `wget` - Descarga de archivos
- `vim`, `nano` - Editores de texto
- `git` - Control de versiones
- `htop` - Monitor de procesos
- `iotop` - Monitor de I/O

**Directorios creados:**
```
/var/log/dns/          # Logs de BIND9
/var/log/dhcp/         # Logs de DHCPv6
/var/log/security/     # Logs de seguridad
/var/log/ansible/      # Logs de Ansible
```

**Scripts creados:**
- `/usr/local/bin/logs` - Ver logs del proyecto

**Tiempo estimado:** 2-3 minutos

---

### 2. `playbooks/infrastructure/playbook-dns.yml`

**Script:** `bash scripts/run/run-dns.sh`

**¿Qué hace?**
- ✅ Instala BIND9 (servidor DNS)
- ✅ Configura zona DNS `gamecenter.local`
- ✅ Configura DNS64 (traduce IPv4 a IPv6)
- ✅ Genera clave DDNS para actualización dinámica
- ✅ Configura zonas directa e inversa
- ✅ Habilita logging de consultas DNS
- ✅ Configura AppArmor para BIND9

**Zonas DNS configuradas:**
- **Zona directa:** `gamecenter.local`
- **Zona inversa:** `0.1.0.8.b.d.5.2.0.2.ip6.arpa`
- **DNS64:** Prefijo `64:ff9b::/96`

**Registros DNS creados:**
```
gamecenter.local.           AAAA    2025:db8:10::2
servidor.gamecenter.local.  AAAA    2025:db8:10::2
ns1.gamecenter.local.       AAAA    2025:db8:10::2
```

**Archivos importantes:**
- `/etc/bind/named.conf.local` - Configuración de zonas
- `/etc/bind/named.conf.options` - Opciones de BIND9
- `/var/lib/bind/db.gamecenter.local` - Zona directa
- `/etc/bind/dhcp-key.key` - **Clave DDNS (necesaria para DHCP)**

**Puertos abiertos:**
- `53/tcp` - DNS sobre TCP
- `53/udp` - DNS sobre UDP

**Tiempo estimado:** 3-5 minutos

**⚠️ IMPORTANTE:** Este playbook debe ejecutarse ANTES de `playbook-dhcp.yml` porque genera la clave DDNS.

---

### 3. `playbooks/infrastructure/playbook-dhcp.yml`

**Script:** `bash scripts/run/run-dhcp.sh`

**¿Qué hace?**
- ✅ Instala isc-dhcp-server (DHCPv6)
- ✅ Configura rango de IPs IPv6
- ✅ Configura actualización dinámica de DNS (DDNS)
- ✅ Copia clave DDNS del DNS
- ✅ Configura AppArmor para DHCP
- ✅ Configura systemd para escuchar en ens34

**Configuración DHCP:**
```yaml
Interfaz: ens34
Red: 2025:db8:10::/64
Rango: 2025:db8:10::100 - 2025:db8:10::200
DNS: 2025:db8:10::2
Dominio: gamecenter.local
Lease time: 600 segundos (10 minutos)
```

**Archivos importantes:**
- `/etc/dhcp/dhcpd6.conf` - Configuración principal
- `/etc/dhcp/dhcp-key.key` - Clave DDNS (copiada del DNS)
- `/etc/default/isc-dhcp-server` - Interfaz de escucha

**Puertos abiertos:**
- `546/udp` - DHCPv6 Client
- `547/udp` - DHCPv6 Server

**Tiempo estimado:** 2-3 minutos

**⚠️ IMPORTANTE:** Requiere que `playbook-dns.yml` se haya ejecutado primero.

---

### 4. `playbooks/infrastructure/playbook-firewall.yml`

**Script:** `bash scripts/run/run-firewall.sh`

**¿Qué hace?**
- ✅ Instala UFW (firewall)
- ✅ Instala fail2ban (protección contra ataques)
- ✅ Configura reglas de firewall
- ✅ Habilita rate limiting en SSH
- ✅ Abre puertos necesarios para servicios
- ✅ Configura protección contra fuerza bruta

**Política de firewall:**
- **Entrada:** DENY (denegar todo por defecto)
- **Salida:** ALLOW (permitir todo)

**Puertos abiertos:**
```
22/tcp      - SSH (con rate limiting)
53/tcp,udp  - DNS
546/udp     - DHCPv6 Client
547/udp     - DHCPv6 Server
2049/tcp    - NFS
```

**Protección fail2ban:**
- **Bantime:** 1 hora
- **Maxretry:** 5 intentos
- **Findtime:** 10 minutos

**Scripts creados:**
- `/usr/local/bin/firewall-monitor.sh` - Monitor de firewall
- `/usr/local/bin/fw-monitor` - Alias del monitor

**Tiempo estimado:** 2-3 minutos

**⚠️ NOTA:** Puede fallar la primera vez, ejecutar dos veces si es necesario.

---

### 5. `playbooks/infrastructure/playbook-storage.yml`

**Script:** `bash scripts/run/run-storage.sh`

**¿Qué hace?**
- ✅ Instala servidor NFS
- ✅ Crea directorios compartidos
- ✅ Configura exportaciones NFS
- ✅ Configura permisos de directorios
- ✅ Habilita monitoreo de disco

**Directorios compartidos:**
```
/srv/nfs/games/     - Juegos compartidos (rw)
/srv/nfs/shared/    - Archivos compartidos (rw)
/srv/nfs/backups/   - Backups (ro)
```

**Exportaciones NFS:**
```
/srv/nfs/games    2025:db8:10::/64(rw,sync,no_subtree_check,no_root_squash)
/srv/nfs/shared   2025:db8:10::/64(rw,sync,no_subtree_check)
/srv/nfs/backups  2025:db8:10::/64(ro,sync,no_subtree_check)
```

**Puertos abiertos:**
- `2049/tcp` - NFS
- `111/tcp` - Portmapper
- `20048/tcp` - Mountd

**Scripts creados:**
- `/usr/local/bin/storage-monitor` - Monitor de almacenamiento

**Tiempo estimado:** 2-3 minutos

---

### 6. `playbooks/infrastructure/setup-complete-infrastructure.yml`

**Script:** `bash scripts/server/setup-server.sh`

**¿Qué hace?**
- ✅ Ejecuta TODOS los playbooks anteriores en orden
- ✅ Configura el servidor completo de una vez

**Orden de ejecución:**
1. Common (paquetes base)
2. DNS (BIND9)
3. DHCP (DHCPv6)
4. Firewall (UFW + fail2ban)
5. Storage (NFS)

**Tiempo estimado:** 10-15 minutos

**⚠️ RECOMENDADO:** Usar este playbook para configuración inicial completa.

---

## 🖥️ PLAYBOOKS DE VMs

### 7. `playbooks/create-ubuntu-desktop.yml`

**Script:** `ansible-playbook playbooks/create-ubuntu-desktop.yml`

**¿Qué hace?**
- ✅ Crea VM Ubuntu Desktop en VMware
- ✅ Asigna recursos según rol (admin/auditor/cliente)
- ✅ Conecta a red interna (M_vm's)
- ✅ Monta ISO de Ubuntu Desktop

**Recursos por rol:**
```yaml
admin:
  CPU: 2 cores
  RAM: 4096 MB
  Disco: 50 GB

auditor:
  CPU: 2 cores
  RAM: 3072 MB
  Disco: 30 GB

cliente:
  CPU: 2 cores
  RAM: 4096 MB
  Disco: 40 GB
```

**Configuración de red:**
- **Red:** M_vm's (red interna)
- **Adaptador:** vmxnet3
- **IPv6:** Asignado por DHCP

**Pasos después de crear:**
1. Instalar Ubuntu Desktop desde ISO
2. Configurar usuario: `administrador` / `123456`
3. Configurar red: IPv6 Automatic (DHCP)
4. Agregar a `inventory/hosts.ini`
5. Ejecutar: `ansible-playbook playbooks/configure-ubuntu-role.yml`

**Tiempo estimado:** 2-3 minutos (solo creación de VM)

---

### 8. `playbooks/create-windows11.yml`

**Script:** `ansible-playbook playbooks/create-windows11.yml`

**¿Qué hace?**
- ✅ Crea VM Windows 11 en VMware
- ✅ Asigna recursos según rol (admin/auditor/cliente)
- ✅ Conecta a red interna (M_vm's)
- ✅ Monta ISO de Windows 11
- ✅ Habilita Secure Boot y TPM 2.0

**Recursos por rol:**
```yaml
admin:
  CPU: 2 cores
  RAM: 4096 MB
  Disco: 50 GB

auditor:
  CPU: 2 cores
  RAM: 3072 MB
  Disco: 30 GB

cliente:
  CPU: 2 cores
  RAM: 4096 MB
  Disco: 40 GB
```

**Configuración de red:**
- **Red:** M_vm's (red interna)
- **Adaptador:** vmxnet3
- **IPv6:** Asignado por DHCP

**Pasos después de crear:**
1. Instalar Windows 11 desde ISO
2. Configurar usuario: `Administrador` / `123456`
3. Habilitar WinRM (ver README)
4. Agregar a `inventory/hosts.ini`
5. Ejecutar: `ansible-playbook playbooks/configure-windows-role.yml`

**Tiempo estimado:** 2-3 minutos (solo creación de VM)

---

### 9. `playbooks/create-server-vm.yml`

**Script:** `bash scripts/vms/create-server.sh`

**¿Qué hace?**
- ✅ Crea VM del servidor Ubuntu
- ✅ Configura 2 adaptadores de red
- ✅ Monta ISO de Ubuntu Server

**Recursos:**
```yaml
CPU: 2 cores
RAM: 4096 MB
Disco: 30 GB
```

**Adaptadores de red:**
```
ens33 (Adaptador 1): VM Network (Internet/WAN)
ens34 (Adaptador 2): M_vm's (Red interna/LAN)
```

**Pasos después de crear:**
1. Instalar Ubuntu Server desde ISO
2. Configurar usuario: `ubuntu` / `123456`
3. Configurar ens33: DHCP (internet)
4. Configurar ens34: `2025:db8:10::2/64` (fija)
5. Habilitar SSH: `sudo apt install openssh-server`
6. Ejecutar: `bash scripts/server/setup-server.sh`

**Tiempo estimado:** 2-3 minutos (solo creación de VM)

---

### 10. `playbooks/configure-ubuntu-role.yml`

**Script:** `ansible-playbook playbooks/configure-ubuntu-role.yml --limit <vm_name>`

**¿Qué hace?**
- ✅ Configura VM Ubuntu Desktop según su rol
- ✅ Instala software específico del rol
- ✅ Configura permisos y accesos
- ✅ Monta NFS si es necesario

**Configuración por rol:**

**Admin:**
- Acceso SSH completo
- Sudo sin contraseña
- Herramientas de administración
- Acceso a todos los recursos NFS

**Auditor:**
- Acceso SSH limitado
- Solo lectura en logs
- Herramientas de auditoría
- Acceso limitado a NFS

**Cliente:**
- Sin acceso SSH
- Solo acceso a juegos
- Software de usuario final
- Acceso solo a /srv/nfs/games

**Tiempo estimado:** 5-10 minutos

---

### 11. `playbooks/configure-windows-role.yml`

**Script:** `ansible-playbook playbooks/configure-windows-role.yml --limit <vm_name>`

**¿Qué hace?**
- ✅ Configura VM Windows según su rol
- ✅ Instala software específico del rol
- ✅ Configura políticas de grupo
- ✅ Configura firewall de Windows

**Configuración por rol:**

**Admin:**
- Acceso remoto completo (RDP)
- Permisos de administrador
- Herramientas de administración
- Acceso a todos los recursos

**Auditor:**
- Acceso remoto limitado
- Solo lectura en logs
- Herramientas de auditoría
- Acceso limitado a recursos

**Cliente:**
- Sin acceso remoto
- Usuario estándar
- Software de usuario final
- Acceso solo a juegos

**Tiempo estimado:** 10-15 minutos

---

## 🎮 PLAYBOOKS DE GAMING

### 12. `playbooks/gaming/setup-gaming-desktop.yml`

**Script:** `ansible-playbook playbooks/gaming/setup-gaming-desktop.yml`

**¿Qué hace?**
- ✅ Instala Steam
- ✅ Instala Lutris
- ✅ Instala Wine
- ✅ Configura drivers de GPU
- ✅ Monta NFS de juegos
- ✅ Configura optimizaciones de gaming

**Software instalado:**
- Steam (cliente de juegos)
- Lutris (gestor de juegos)
- Wine (compatibilidad Windows)
- GameMode (optimizaciones)
- MangoHud (overlay de FPS)

**Tiempo estimado:** 15-20 minutos

---

## 📊 RESUMEN DE ORDEN DE EJECUCIÓN

### Configuración del Servidor (Primera vez)

```bash
# Opción 1: Todo de una vez (RECOMENDADO)
bash scripts/server/setup-server.sh

# Opción 2: Paso a paso
bash scripts/run/run-common.sh      # 1. Paquetes base
bash scripts/run/run-dns.sh         # 2. DNS (genera clave DDNS)
bash scripts/run/run-dhcp.sh        # 3. DHCP (usa clave del DNS)
bash scripts/run/run-firewall.sh    # 4. Firewall
bash scripts/run/run-storage.sh     # 5. NFS
```

### Crear VMs

```bash
# Servidor
bash scripts/vms/create-server.sh

# Ubuntu Desktop
ansible-playbook playbooks/create-ubuntu-desktop.yml

# Windows 11
ansible-playbook playbooks/create-windows11.yml
```

### Configurar VMs

```bash
# Ubuntu Desktop
ansible-playbook playbooks/configure-ubuntu-role.yml --limit <vm_name>

# Windows 11
ansible-playbook playbooks/configure-windows-role.yml --limit <vm_name>

# Gaming Desktop
ansible-playbook playbooks/gaming/setup-gaming-desktop.yml --limit <vm_name>
```

---

## 🔍 VALIDACIONES

Cada playbook tiene su script de validación:

```bash
bash scripts/run/validate-common.sh
bash scripts/run/validate-dns.sh
bash scripts/run/validate-dhcp.sh
bash scripts/run/validate-firewall.sh
bash scripts/run/validate-storage.sh

# O validar todo
bash scripts/run/validate-all.sh
```

---

## ⏱️ TIEMPOS ESTIMADOS

| Playbook | Tiempo |
|----------|--------|
| Common | 2-3 min |
| DNS | 3-5 min |
| DHCP | 2-3 min |
| Firewall | 2-3 min |
| Storage | 2-3 min |
| **Setup completo** | **10-15 min** |
| Crear VM | 2-3 min |
| Configurar Ubuntu | 5-10 min |
| Configurar Windows | 10-15 min |
| Gaming Desktop | 15-20 min |

---

## 🆘 TROUBLESHOOTING

### Firewall falla la primera vez
```bash
# Ejecutar dos veces
bash scripts/run/run-firewall.sh
bash scripts/run/run-firewall.sh
```

### DHCP no encuentra clave DDNS
```bash
# Ejecutar DNS primero
bash scripts/run/run-dns.sh
# Luego DHCP
bash scripts/run/run-dhcp.sh
```

### DNS no resuelve
```bash
# Recargar zonas
sudo rndc reload
# Verificar
dig @localhost gamecenter.local AAAA
```

### NFS no monta
```bash
# Verificar exportaciones
showmount -e localhost
# Reiniciar servicio
sudo systemctl restart nfs-server
```

---

## ════════════════════════════════════════════════════════════════
