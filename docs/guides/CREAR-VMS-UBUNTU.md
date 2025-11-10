# Guía: Crear y Configurar VM Ubuntu Desktop

Guía completa para levantar UNA VM Ubuntu Desktop con 3 usuarios (admin, auditor, gamer01) cada uno con diferentes permisos.

---

## 📋 Índice

1. [Roles y Privilegios](#roles-y-privilegios)
2. [Grupos Unix](#grupos-unix)
3. [Crear VM en ESXi](#crear-vm-en-esxi)
4. [Instalar Ubuntu Desktop](#instalar-ubuntu-desktop)
5. [Configurar VM con Ansible](#configurar-vm-con-ansible)
6. [Verificación](#verificación)

---

## 🎯 Concepto

**UNA VM con 3 usuarios:**
- Cada usuario tiene diferentes permisos
- Todos comparten la misma máquina
- Cada uno inicia sesión con su propio usuario

## 👥 Usuarios y Privilegios

### **Usuario: admin (Administrador)**

**Propósito:** Administración completa del sistema

**Privilegios:**
- ✅ Acceso SSH al servidor
- ✅ Sudo sin contraseña
- ✅ Acceso a logs del sistema
- ✅ Puede instalar software
- ✅ Puede modificar configuraciones

**Grupos:**
- `sudo` - Privilegios de administrador
- `adm` - Acceso a logs
- `pcgamers` - Acceso a juegos compartidos

**Herramientas instaladas:**
- Ansible
- Python3
- Herramientas de monitoreo (htop, iotop, nethogs)
- Herramientas de red

**Firewall:**
- Puerto 22 (SSH) - Abierto
- Puerto 3389 (RDP) - Abierto

---

### **Usuario: auditor**

**Propósito:** Auditoría y monitoreo (solo lectura)

**Privilegios:**
- ❌ NO tiene acceso SSH al servidor
- ❌ NO puede usar sudo
- ✅ Puede ver logs del sistema (solo lectura)
- ❌ NO puede instalar software
- ❌ NO puede modificar configuraciones

**Grupos:**
- `adm` - Acceso de lectura a logs
- `pcgamers` - Acceso a juegos compartidos

**Herramientas instaladas:**
- Herramientas de auditoría (auditd, aide, lynis)
- Herramientas de monitoreo
- Python3

**Firewall:**
- Puerto 22 (SSH) - Cerrado
- Puerto 3389 (RDP) - Abierto

---

### **Usuario: gamer01 (Cliente)**

**Propósito:** Jugar juegos, uso normal

**Privilegios:**
- ❌ NO tiene acceso SSH al servidor
- ❌ NO puede usar sudo
- ❌ NO puede ver logs del sistema
- ❌ NO puede instalar software del sistema
- ✅ Puede instalar juegos en su directorio

**Grupos:**
- `pcgamers` - Acceso a juegos compartidos

**Herramientas instaladas:**
- Steam
- Wine/Winetricks
- GameMode
- Herramientas básicas

**Firewall:**
- Puerto 22 (SSH) - Cerrado
- Puerto 3389 (RDP) - Abierto

---

## 🔐 Grupos Unix

### **Grupo: pcgamers**

**Propósito:** Acceso a juegos y recursos compartidos

**Miembros:**
- Todos los usuarios (admin, auditor, cliente)

**Permisos:**
- Lectura/escritura en `/srv/nfs/games` (servidor)
- Lectura/escritura en `/mnt/games` (VMs)
- Lectura/escritura en `/mnt/shared`

**Uso:**
```bash
# Ver miembros del grupo
getent group pcgamers

# Agregar usuario al grupo
sudo usermod -aG pcgamers usuario
```

---

### **Grupo: servicios**

**Propósito:** Servicios del sistema (Steam, Epic, etc.)

**Miembros:**
- `steam_epic_svc` (usuario de servicio)

**Permisos:**
- Acceso a `/srv/steam_epic_svc`
- Sin shell de login (`/usr/sbin/nologin`)

---

## 🚀 Crear VM en ESXi

### **Paso 1: Preparar ISO**

Sube la ISO de Ubuntu Desktop a tu datastore de ESXi:

```bash
# Desde tu PC, sube la ISO a ESXi
# Ubicación en datastore: [datastore1] ISOs/ubuntu-22.04-desktop-amd64.iso
```

O descárgala directamente:
```bash
wget https://releases.ubuntu.com/22.04/ubuntu-22.04.3-desktop-amd64.iso
```

---

### **Paso 2: Ejecutar playbook de creación**

```bash
# Activar entorno Ansible
source activate-ansible.sh

# Crear la VM (UNA sola VM)
ansible-playbook create-vm-ubuntu-desktop.yml
```

---

### **Paso 3: Verificar creación**

El playbook creará UNA VM con:

| Característica | Valor |
|----------------|-------|
| **Nombre** | Ubuntu-Desktop-GameCenter |
| **RAM** | 8 GB |
| **CPUs** | 4 |
| **Disco** | 40 GB |
| **Red** | M_vm's (red interna IPv6) |
| **Usuarios** | admin, auditor, gamer01 (se crean después) |

---

## 💿 Instalar Ubuntu Desktop

### **Paso 1: Abrir consola de la VM**

1. Abre vSphere Client
2. Busca la VM creada
3. Click derecho → "Open Console"

---

### **Paso 2: Instalar Ubuntu**

Durante la instalación:

1. **Idioma:** Español (o el que prefieras)

2. **Teclado:** Español (o el que uses)

3. **Tipo de instalación:** Instalación normal

4. **Actualizaciones:** Descargar actualizaciones durante la instalación

5. **Tipo de instalación:** Borrar disco e instalar Ubuntu

6. **Zona horaria:** Tu zona horaria

7. **Usuario y contraseña:**

   **Usuario inicial (admin):**
   ```
   Nombre: Administrador
   Nombre de usuario: admin
   Contraseña: admin123
   Hostname: ubuntu-desktop-gamecenter
   ```
   
   **Nota:** Los otros usuarios (auditor, gamer01) se crearán después con Ansible

8. **Esperar instalación:** ~15-20 minutos

9. **Reiniciar**

---

### **Paso 3: Configuración inicial**

Después del primer inicio:

1. **Actualizar sistema:**
```bash
sudo apt update
sudo apt upgrade -y
```

2. **Instalar OpenSSH (solo para admin):**
```bash
sudo apt install openssh-server -y
sudo systemctl enable ssh
sudo systemctl start ssh
```

3. **Configurar red IPv6:**
```bash
sudo nano /etc/netplan/01-netcfg.yaml
```

Contenido:
```yaml
network:
  version: 2
  ethernets:
    ens33:  # Verifica el nombre con: ip link show
      dhcp4: false
      dhcp6: true
      accept-ra: true
      nameservers:
        addresses:
          - 2025:db8:10::2
        search:
          - gamecenter.local
```

Aplicar:
```bash
sudo netplan apply
```

4. **Verificar IP recibida:**
```bash
ip -6 addr show
# Deberías ver algo como: 2025:db8:10::100/64
```

5. **Probar conectividad:**
```bash
# Ping al servidor
ping6 2025:db8:10::2

# Ping a internet (NAT66)
ping6 google.com

# Resolver nombre DNS
nslookup server.gamecenter.local
```

---

## 🔧 Configurar VM con Ansible

### **Paso 1: Agregar VM al inventario**

En el servidor, edita `inventory/hosts.ini`:

```ini
[ubuntu_desktop]
ubuntu-desktop-gamecenter ansible_host=2025:db8:10::100 ansible_user=admin
```

**Nota:** Reemplaza la IP con la que recibió la VM por DHCP.

---

### **Paso 2: Probar conexión SSH**

```bash
# Desde el servidor
ansible ubuntu_desktop -m ping
```

---

### **Paso 3: Ejecutar configuración**

```bash
# Configurar la VM (creará los 3 usuarios)
ansible-playbook configure-ubuntu-desktop.yml --ask-become-pass
```

**Esto creará:**
- Usuario `admin` (ya existe, se actualizará)
- Usuario `auditor` (nuevo)
- Usuario `gamer01` (nuevo)

---

### **Paso 4: Verificar configuración**

El playbook configurará:

✅ **Red IPv6:**
- DHCP habilitado
- DNS apuntando al servidor
- Gateway configurado

✅ **Grupos y usuarios:**
- Usuario agregado a grupos según rol
- Permisos configurados

✅ **NFS:**
- `/mnt/games` montado
- `/mnt/shared` montado

✅ **Firewall:**
- Reglas según rol
- UFW habilitado

✅ **SSH:**
- Habilitado solo para admin
- Deshabilitado para auditor y cliente

✅ **Herramientas:**
- Instaladas según rol

---

## ✅ Verificación

### **En la VM:**

```bash
# 1. Verificar IP
ip -6 addr show
# Debe mostrar: 2025:db8:10::XXX/64

# 2. Verificar DNS
nslookup server.gamecenter.local
# Debe resolver a: 2025:db8:10::2

# 3. Verificar internet
ping6 google.com
# Debe funcionar (NAT66)

# 4. Verificar NFS
ls /mnt/games
ls /mnt/shared
# Deben mostrar contenido

# 5. Verificar grupos
groups
# Admin debe ver: admin sudo adm pcgamers
# Auditor debe ver: auditor adm pcgamers
# Cliente debe ver: gamer01 pcgamers

# 6. Verificar firewall
sudo ufw status
# Debe estar: Status: active
```

---

### **Desde el servidor:**

```bash
# 1. Ver leases DHCP
cat /var/lib/dhcp/dhcpd6.leases

# 2. Ver conexiones activas
sudo nfsstat -c

# 3. Probar SSH (solo admin)
ssh admin@2025:db8:10::100
# Debe conectar

ssh auditor@2025:db8:10::101
# Debe fallar (SSH deshabilitado)

# 4. Ver reglas de firewall del servidor
sudo ufw status numbered
# Admin debe poder SSH
# Auditor y cliente NO
```

---

## 📊 Resumen de configuración

**UNA VM con 3 usuarios:**

| Característica | admin | auditor | gamer01 |
|----------------|-------|---------|---------|
| **SSH al servidor** | ✅ Sí | ❌ No | ❌ No |
| **SSH local** | ✅ Sí | ❌ No | ❌ No |
| **Sudo** | ✅ Sí (sin contraseña) | ❌ No | ❌ No |
| **Ver logs** | ✅ Sí | ✅ Solo lectura | ❌ No |
| **Instalar software** | ✅ Sí | ❌ No | ❌ No |
| **Acceso NFS** | ✅ Sí | ✅ Sí | ✅ Sí |
| **Juegos** | ✅ Sí | ✅ Sí | ✅ Sí |

**Recursos de la VM:**
- RAM: 8 GB
- CPUs: 4
- Disco: 40 GB

---

## 🎯 Casos de uso

### **Admin:**
- Administrar el servidor desde la VM
- Configurar servicios
- Monitorear el sistema
- Instalar y actualizar software
- Acceso completo

### **Auditor:**
- Revisar logs del sistema
- Monitorear actividad
- Generar reportes
- Sin capacidad de modificar

### **Cliente:**
- Jugar juegos
- Usar aplicaciones
- Acceder a recursos compartidos
- Sin privilegios administrativos

---

## ❓ Troubleshooting

### **No recibe IP por DHCP:**
```bash
# Verificar configuración de netplan
sudo netplan --debug apply

# Reiniciar interfaz
sudo ip link set ens33 down
sudo ip link set ens33 up

# Ver logs de DHCP
sudo journalctl -u systemd-networkd -f
```

### **No puede hacer ping al servidor:**
```bash
# Verificar ruta
ip -6 route show

# Verificar firewall
sudo ufw status

# Desde el servidor, verificar que ens34 esté up
ip -6 addr show ens34
```

### **NFS no monta:**
```bash
# Verificar conectividad al servidor
ping6 2025:db8:10::2

# Verificar exportaciones NFS
showmount -e 2025:db8:10::2

# Montar manualmente
sudo mount -t nfs4 [2025:db8:10::2]:/srv/nfs/games /mnt/games
```

### **SSH no funciona (admin):**
```bash
# Verificar servicio
sudo systemctl status ssh

# Verificar puerto
sudo ss -tlnp | grep 22

# Ver logs
sudo journalctl -u ssh -f
```

---

## 📝 Notas importantes

1. **Contraseñas:** Las contraseñas están en `group_vars/all.vault.yml`

2. **IPs dinámicas:** Las VMs reciben IPs por DHCP. Anota las IPs asignadas.

3. **Firewall del servidor:** El servidor bloqueará SSH desde auditor y cliente automáticamente.

4. **NFS:** Los directorios compartidos se montan automáticamente al iniciar.

5. **Actualizaciones:** Ejecuta `sudo apt update && sudo apt upgrade` regularmente.

---

**Última actualización:** 2024
**Versión:** 1.0
