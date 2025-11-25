# 🎯 GUÍA COMPLETA PARA DEMOSTRAR LA RÚBRICA

## Objetivo: Alcanzar Nivel 4 en todos los criterios

---

## 📋 CHECKLIST DE LA RÚBRICA

### ✅ Criterio 1: Conectividad entre distintos SO (Nivel 4)

**Objetivo:** Estable, funcional, con evidencia y optimización

**Qué demostrar:**
- [x] Ubuntu Desktop → Servidor (ping, SSH, HTTP, DNS)
- [x] Windows 11 → Servidor (ping, HTTP, DNS)
- [x] Servidor → Internet (NAT64)
- [x] Tabla de conectividad completa
- [x] Capturas de pantalla de cada prueba

**Cómo demostrarlo:**

#### En Ubuntu Desktop:
```bash
# 1. Ejecutar script completo de conectividad
bash scripts/diagnostics/test-connectivity-full.sh

# 2. Tomar capturas de:
ping6 -c 4 2025:db8:10::2
ssh administrador@2025:db8:10::2
curl http://gamecenter.lan
dig @2025:db8:10::2 gamecenter.lan AAAA
```

#### En Windows 11:
```powershell
# 1. Ejecutar script de evidencias (como Administrador)
PowerShell -ExecutionPolicy Bypass -File scripts\windows\Test-WindowsEvidence.ps1

# 2. Tomar capturas de:
ping 2025:db8:10::2
nslookup gamecenter.lan 2025:db8:10::2
# Abrir navegador: http://gamecenter.lan
```

**Evidencias necesarias:**
- ✅ Captura de ping exitoso desde Ubuntu
- ✅ Captura de ping exitoso desde Windows
- ✅ Captura de SSH desde Ubuntu (solo admin)
- ✅ Captura de navegador web desde Windows
- ✅ Tabla de conectividad (ver `docs/TABLAS-RED-COMPLETAS.md`)

---

### ✅ Criterio 2: Configuración de red y servicios (Nivel 4)

**Objetivo:** Funcionalidad completa con evidencia

**Qué demostrar:**
- [x] Tabla de IPs, máscaras, gateway
- [x] Servicios funcionando (DNS, DHCP, Web, SSH, Firewall)
- [x] Configuración de cada servicio
- [x] Puertos abiertos y cerrados

**Cómo demostrarlo:**

#### En el Servidor:
```bash
# 1. Generar reporte completo
bash scripts/diagnostics/generate-full-evidence.sh

# 2. Ver configuración de red
ip -6 addr show ens34
ip -6 route show

# 3. Ver servicios
sudo systemctl status bind9
sudo systemctl status isc-dhcp-server6
sudo systemctl status nginx
sudo systemctl status ssh

# 4. Ver firewall
sudo ufw status verbose

# 5. Ver puertos abiertos
sudo ss -tulnp | grep -E ":(22|53|80|547)"
```

**Evidencias necesarias:**
- ✅ Tabla de red completa (ver `docs/TABLAS-RED-COMPLETAS.md`)
- ✅ Captura de `ip -6 addr show`
- ✅ Captura de `ip -6 route show`
- ✅ Captura de servicios activos
- ✅ Captura de firewall configurado
- ✅ Tabla de puertos y servicios

---

### ✅ Criterio 3: Toma de decisiones técnicas (Nivel 4)

**Objetivo:** Técnicamente justificadas y basadas en estándares

**Qué demostrar:**
- [x] Justificación de Ubuntu Server vs otras opciones
- [x] Justificación de IPv6 puro
- [x] Justificación de BIND9, isc-dhcp-server6, UFW
- [x] Justificación de arquitectura de 3 roles
- [x] Comparativa de alternativas

**Evidencias necesarias:**
- ✅ Documento de decisiones técnicas (ver `docs/EVIDENCIAS-RUBRICA.md` sección 7)
- ✅ Tabla comparativa de SO
- ✅ Justificación de cada tecnología elegida

---

### ✅ Criterio 4: Diseño y documentación final (Nivel 4)

**Objetivo:** Diseño profesional, documentado y probado

**Qué demostrar:**
- [x] Tablas de red completas
- [x] Esquema de particiones
- [x] Gestión de usuarios y permisos
- [x] Documentación de seguridad
- [x] Evidencias visuales (capturas)

**Evidencias necesarias:**
- ✅ `docs/TABLAS-RED-COMPLETAS.md` - Todas las tablas de red
- ✅ `docs/EVIDENCIAS-RUBRICA.md` - Evidencias organizadas
- ✅ `POLITICAS-FIREWALL.md` - Seguridad documentada
- ✅ Capturas de particiones
- ✅ Capturas de usuarios y permisos

---

## 🚀 PASOS PARA GENERAR TODAS LAS EVIDENCIAS

### Paso 1: En el Servidor Ubuntu

```bash
# 1. Generar reporte completo
cd ~/ansible-gestion-despliegue
bash scripts/diagnostics/generate-full-evidence.sh

# 2. Ver particiones
bash scripts/diagnostics/show-partitions.sh

# 3. Ver usuarios y permisos
bash scripts/diagnostics/check-user-permissions.sh

# 4. Ver servicios
bash scripts/diagnostics/check-server-ready.sh

# 5. Validar todo
bash scripts/run/validate-all.sh
```

**Resultado:** Se crea carpeta `~/evidencias-rubrica/` con todos los reportes

### Paso 2: En Ubuntu Desktop (cada rol)

```bash
# Ejecutar como cada usuario: administrador, auditor, gamer01

# 1. Prueba de conectividad
bash scripts/diagnostics/test-connectivity-full.sh

# 2. Ver permisos del usuario
bash scripts/diagnostics/check-user-permissions.sh

# 3. Intentar SSH (solo admin debería poder)
ssh ubuntu@2025:db8:10::2
```

**Tomar capturas de:**
- Conectividad exitosa
- SSH permitido/bloqueado según rol
- Permisos de carpetas

### Paso 3: En Windows 11 (cada rol)

```powershell
# Ejecutar como Administrador

# 1. Generar evidencias
cd C:\ansible-gestion-despliegue
PowerShell -ExecutionPolicy Bypass -File scripts\windows\Test-WindowsEvidence.ps1

# 2. Comandos individuales para capturas
ipconfig
ping 2025:db8:10::2
nslookup gamecenter.lan 2025:db8:10::2
Get-LocalUser
Get-LocalGroup
Get-Acl C:\Games | Format-List
Get-NetFirewallProfile
Get-Disk
Get-Partition
Get-Volume
```

**Tomar capturas de:**
- Configuración de red
- Conectividad
- Usuarios y grupos
- Permisos de carpetas
- Firewall
- Particiones

---

## 📸 CAPTURAS OBLIGATORIAS

### Conectividad (10 capturas mínimo)

1. **Ubuntu Desktop → Servidor:**
   - `ping6 2025:db8:10::2`
   - `ssh administrador@2025:db8:10::2`
   - `curl http://gamecenter.lan`
   - `dig @2025:db8:10::2 gamecenter.lan AAAA`

2. **Windows 11 → Servidor:**
   - `ping 2025:db8:10::2`
   - `nslookup gamecenter.lan`
   - Navegador web: `http://gamecenter.lan`

3. **Servidor:**
   - `ip -6 addr show`
   - `ip -6 route show`
   - `sudo ss -tulnp`

### Servicios (8 capturas mínimo)

1. **DNS:**
   - `sudo systemctl status bind9`
   - `dig @2025:db8:10::2 gamecenter.lan AAAA`

2. **DHCP:**
   - `sudo systemctl status isc-dhcp-server6`
   - `sudo cat /var/lib/dhcp/dhcpd6.leases`

3. **Web:**
   - `sudo systemctl status nginx`
   - Navegador mostrando página

4. **Firewall:**
   - `sudo ufw status verbose`
   - `sudo fail2ban-client status`

### Particiones (5 capturas mínimo)

1. `lsblk`
2. `df -h`
3. `sudo pvdisplay` (si usa LVM)
4. `sudo vgdisplay` (si usa LVM)
5. `sudo lvdisplay` (si usa LVM)

### Usuarios y Permisos (10 capturas mínimo)

1. **Servidor:**
   - `cat /etc/passwd | grep -E "ubuntu|auditor|dev"`
   - `cat /etc/group | grep -E "sudo|auditors"`
   - `sudo -l -U auditor`

2. **Ubuntu Desktop:**
   - `cat /etc/passwd | grep -E "administrador|auditor|gamer01"`
   - `groups administrador`
   - `ls -la /srv/games`
   - `ls -la /home/auditor`

3. **Windows 11:**
   - `Get-LocalUser`
   - `Get-LocalGroup`
   - `Get-LocalGroupMember -Group "Administradores"`
   - `Get-Acl C:\Games | Format-List`

### Seguridad (5 capturas mínimo)

1. `sudo ufw status verbose`
2. `sudo fail2ban-client status sshd`
3. `sudo tail -20 /var/log/auth.log`
4. SSH bloqueado para auditor/cliente
5. SSH permitido para admin

---

## 📊 TABLAS REQUERIDAS

### 1. Tabla de Red (OBLIGATORIA)

Ver `docs/TABLAS-RED-COMPLETAS.md` sección 2

| Host | IP | Máscara | Gateway | DNS | Rol |
|------|-----|---------|---------|-----|-----|
| Servidor | 2025:db8:10::2 | /64 | - | - | Servidor |
| Ubuntu Desktop | 2025:db8:10::100 | /64 | ::1 | ::2 | Admin |
| Windows 11 | 2025:db8:10::110 | /64 | ::1 | ::2 | Admin |

### 2. Tabla de Servicios (OBLIGATORIA)

Ver `docs/TABLAS-RED-COMPLETAS.md` sección 4

| Servicio | Puerto | Protocolo | Estado |
|----------|--------|-----------|--------|
| SSH | 22 | TCP | ✅ Activo |
| DNS | 53 | TCP+UDP | ✅ Activo |
| HTTP | 80 | TCP | ✅ Activo |
| DHCPv6 | 547 | UDP | ✅ Activo |

### 3. Tabla de Usuarios (OBLIGATORIA)

Ver `docs/EVIDENCIAS-RUBRICA.md` sección 4

| Usuario | Grupos | Sudo | SSH | Permisos |
|---------|--------|------|-----|----------|
| ubuntu | sudo | ✅ Sí | ✅ Sí | Completo |
| auditor | auditors | ❌ No | ❌ No | Solo lectura |
| gamer01 | pcgamers | ❌ No | ❌ No | Limitado |

### 4. Tabla de Particiones (OBLIGATORIA)

Ver `docs/EVIDENCIAS-RUBRICA.md` sección 3

| Partición | Montaje | Tamaño | Tipo |
|-----------|---------|--------|------|
| /dev/sda1 | /boot | 1 GB | ext4 |
| /dev/ubuntu-vg/root | / | 10 GB | ext4 |
| /dev/ubuntu-vg/var | /var | 5 GB | ext4 |

### 5. Tabla de Firewall (OBLIGATORIA)

Ver `POLITICAS-FIREWALL.md`

| Puerto | Protocolo | Acción | Comentario |
|--------|-----------|--------|------------|
| 22 | TCP | LIMIT | SSH con rate limiting |
| 53 | TCP+UDP | ALLOW | DNS |
| 80 | TCP | ALLOW | HTTP |

---

## 🎯 DEMOSTRACIÓN DE AUTOMATIZACIÓN

### Ansible - Roles Implementados

```bash
# 1. Mostrar roles
ls -la roles/

# 2. Ejecutar configuración completa
ansible-playbook site.yml --connection=local --become --ask-become-pass

# 3. Crear VM automáticamente
ansible-playbook playbooks/create-ubuntu-desktop.yml -e "vm_role=admin"

# 4. Configurar rol en VM
ansible-playbook playbooks/configure-ubuntu-role.yml -e "vm_role=admin"
```

**Evidencias:**
- Captura de ejecución de Ansible
- Lista de roles
- Captura de creación de VM
- Logs de configuración

---

## 🔐 DEMOSTRACIÓN DE SEGURIDAD

### 1. Firewall

```bash
# Ver reglas
sudo ufw status verbose

# Ver logs
sudo tail -f /var/log/ufw.log
```

### 2. fail2ban

```bash
# Ver estado
sudo fail2ban-client status
sudo fail2ban-client status sshd

# Ver IPs bloqueadas
sudo fail2ban-client status sshd | grep "Banned IP"
```

### 3. Restricciones SSH

```bash
# Como admin (debería funcionar)
ssh ubuntu@2025:db8:10::2

# Como auditor (debería fallar)
ssh ubuntu@2025:db8:10::2
```

### 4. Permisos de carpetas

```bash
# Ver permisos
ls -la /srv/games
ls -la /home/auditor

# Intentar acceder como otro usuario
sudo -u gamer01 ls /home/auditor  # Debería fallar
```

---

## 📦 DEMOSTRACIÓN DE PARTICIONES

### Linux (Servidor y Ubuntu Desktop)

```bash
# 1. Ver esquema completo
bash scripts/diagnostics/show-partitions.sh

# 2. Comandos individuales
lsblk
df -h
sudo pvdisplay
sudo vgdisplay
sudo lvdisplay
```

### Windows 11

```powershell
# 1. Ver discos
Get-Disk

# 2. Ver particiones
Get-Partition

# 3. Ver volúmenes
Get-Volume

# 4. Administrador de discos (GUI)
diskmgmt.msc
```

**Evidencias:**
- Captura de `lsblk` (Linux)
- Captura de `df -h` (Linux)
- Captura de LVM (si aplica)
- Captura de Administrador de discos (Windows)
- Diagrama de particiones

---

## 👥 DEMOSTRACIÓN DE ROLES Y ACCESOS

### Probar cada rol

#### 1. Rol Admin (Ubuntu Desktop)

```bash
# Login como administrador
su - administrador

# Debería poder:
sudo apt update                    # ✅ Sudo funciona
ssh ubuntu@2025:db8:10::2         # ✅ SSH permitido
ls /srv/games                      # ✅ Lectura OK
touch /srv/games/test.txt          # ✅ Escritura OK
```

#### 2. Rol Auditor (Ubuntu Desktop)

```bash
# Login como auditor
su - auditor

# Debería poder:
cat /var/log/syslog               # ✅ Lectura de logs
ls /srv/games                      # ✅ Lectura OK

# NO debería poder:
sudo apt update                    # ❌ Sin sudo
ssh ubuntu@2025:db8:10::2         # ❌ SSH bloqueado
touch /srv/games/test.txt          # ❌ Sin escritura
ls /home/administrador             # ❌ Sin acceso
```

#### 3. Rol Cliente (Ubuntu Desktop)

```bash
# Login como gamer01
su - gamer01

# Debería poder:
ls /srv/games                      # ✅ Lectura OK

# NO debería poder:
sudo apt update                    # ❌ Sin sudo
ssh ubuntu@2025:db8:10::2         # ❌ SSH bloqueado
touch /srv/games/test.txt          # ❌ Sin escritura
ls /home/auditor                   # ❌ Sin acceso
```

#### 4. Roles en Windows 11

Similar, pero usando:
- Administrador: Control total
- Auditor: Solo lectura de logs
- Gamer01: Solo juegos

**Evidencias:**
- Captura de cada usuario ejecutando comandos
- Captura de permisos denegados
- Captura de SSH bloqueado/permitido
- Tabla de permisos por rol

---

## 📁 ESTRUCTURA DE ENTREGA

```
evidencias-rubrica/
├── 01-conectividad/
│   ├── ubuntu-ping.png
│   ├── ubuntu-ssh.png
│   ├── ubuntu-http.png
│   ├── windows-ping.png
│   ├── windows-web.png
│   └── tabla-conectividad.md
├── 02-servicios/
│   ├── dns-status.png
│   ├── dhcp-status.png
│   ├── web-status.png
│   ├── firewall-rules.png
│   └── tabla-servicios.md
├── 03-particiones/
│   ├── lsblk.png
│   ├── df-h.png
│   ├── lvm-display.png
│   ├── windows-disks.png
│   └── diagrama-particiones.md
├── 04-usuarios/
│   ├── usuarios-servidor.png
│   ├── usuarios-ubuntu.png
│   ├── usuarios-windows.png
│   ├── permisos-carpetas.png
│   └── tabla-usuarios.md
├── 05-seguridad/
│   ├── firewall-ufw.png
│   ├── fail2ban-status.png
│   ├── ssh-bloqueado.png
│   ├── ssh-permitido.png
│   └── politicas-seguridad.md
├── 06-automatizacion/
│   ├── ansible-roles.png
│   ├── ansible-execution.png
│   ├── vm-creation.png
│   └── scripts-list.png
└── reportes/
    ├── reporte-completo.txt
    ├── TABLAS-RED-COMPLETAS.md
    ├── EVIDENCIAS-RUBRICA.md
    └── POLITICAS-FIREWALL.md
```

---

## ✅ CHECKLIST FINAL

### Antes de entregar, verificar:

- [ ] Todas las capturas de pantalla tomadas
- [ ] Todas las tablas completadas
- [ ] Reportes generados con scripts
- [ ] Documentación revisada
- [ ] Evidencias organizadas por carpetas
- [ ] README actualizado
- [ ] Pruebas de conectividad exitosas
- [ ] Servicios funcionando
- [ ] Usuarios y permisos correctos
- [ ] Firewall configurado
- [ ] Automatización demostrada

---

## 🎓 TIPS PARA LA PRESENTACIÓN

1. **Orden sugerido:**
   - Mostrar topología de red
   - Demostrar conectividad
   - Mostrar servicios funcionando
   - Explicar decisiones técnicas
   - Demostrar seguridad
   - Mostrar automatización

2. **Preparar:**
   - Servidor encendido y funcionando
   - Al menos 1 Ubuntu Desktop y 1 Windows 11
   - Scripts listos para ejecutar
   - Capturas organizadas

3. **Destacar:**
   - IPv6 puro (innovador)
   - Automatización con Ansible
   - 3 roles con permisos diferenciados
   - Seguridad multicapa
   - Documentación completa

---

**¡Éxito en tu presentación! 🚀**
