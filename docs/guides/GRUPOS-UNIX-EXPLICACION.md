# Grupos Unix: Servidor y VMs

Explicación detallada de cómo funcionan los grupos Unix en el servidor y las VMs.

---

## 🎯 Concepto

Los grupos Unix se usan para **controlar permisos de archivos** compartidos entre el servidor y las VMs a través de NFS.

**Regla de oro:** El **GID (Group ID)** debe ser **el mismo** en el servidor y en las VMs para que NFS funcione correctamente.

---

## 📊 Grupos definidos

### **Grupo: pcgamers**

**GID:** 3000 (fijo en servidor y VMs)

**Propósito:** Acceso a juegos y archivos compartidos

**Miembros en el servidor:**
- `ubuntu` (usuario admin del servidor)
- `steam_epic_svc` (usuario de servicio)
- `gamer01` (opcional)

**Miembros en la VM:**
- `admin` (administrador)
- `auditor` (auditor)
- `gamer01` (cliente/gamer)

**Permisos:**
- Lectura/escritura en `/srv/nfs/games` (servidor)
- Lectura/escritura en `/srv/nfs/shared` (servidor)
- Lectura/escritura en `/mnt/games` (VM, montaje NFS)
- Lectura/escritura en `/mnt/shared` (VM, montaje NFS)

---

### **Grupo: servicios**

**GID:** Automático (solo en el servidor)

**Propósito:** Servicios del sistema (Steam, Epic, etc.)

**Miembros:**
- `steam_epic_svc` (usuario de servicio)

**Permisos:**
- Acceso a `/srv/steam_epic_svc`
- Sin shell de login (`/usr/sbin/nologin`)

---

## 🔧 Configuración en el servidor

### **Archivo: `group_vars/all.yml`**

```yaml
unix_groups: 
  - name: pcgamers
    state: present
    gid: 3000  # GID fijo para NFS
  - name: servicios
    state: present

users:
  - name: gamer01
    state: present
    primary_group: pcgamers
    groups: [pcgamers]
    shell: /bin/bash
    
  - name: steam_epic_svc
    state: present
    shell: /usr/sbin/nologin
    groups: [pcgamers]
    primary_group: servicios
    home: /srv/steam_epic_svc
    create_home: true
```

### **Creación (rol: common)**

```yaml
- name: Existe el grupo
  ansible.builtin.group:
    name: "{{ item.name }}"
    state: "{{ item.state | default('present') }}"
    gid: "{{ item.gid | default(omit) }}"
  loop: "{{ unix_groups | default([]) }}"
```

### **Resultado en el servidor:**

```bash
# Ver grupos
getent group pcgamers
# Salida: pcgamers:x:3000:ubuntu,steam_epic_svc

getent group servicios
# Salida: servicios:x:1001:steam_epic_svc

# Ver permisos de directorios NFS
ls -la /srv/nfs/
# drwxrws--- 2 root pcgamers 4096 /srv/nfs/games
# drwxrws--- 2 root pcgamers 4096 /srv/nfs/shared
```

---

## 🔧 Configuración en la VM

### **Archivo: `configure-ubuntu-desktop.yml`**

```yaml
- name: "👥 Crear grupo pcgamers (GID 3000 - mismo que el servidor)"
  group:
    name: pcgamers
    state: present
    gid: 3000  # IMPORTANTE: Mismo GID que el servidor

- name: "👤 Crear/actualizar usuarios del sistema"
  user:
    name: "{{ item.name }}"
    groups: "{{ item.groups }}"
  loop:
    - name: admin
      groups: [sudo, adm, pcgamers]
    - name: auditor
      groups: [adm, pcgamers]
    - name: gamer01
      groups: [pcgamers]
```

### **Resultado en la VM:**

```bash
# Ver grupos
getent group pcgamers
# Salida: pcgamers:x:3000:admin,auditor,gamer01

# Ver permisos de montajes NFS
ls -la /mnt/
# drwxrws--- 2 root pcgamers 4096 /mnt/games
# drwxrws--- 2 root pcgamers 4096 /mnt/shared
```

---

## 🔗 Cómo funciona NFS con grupos

### **Escenario: Usuario en VM accede a archivo en servidor**

```
1. Usuario "gamer01" en la VM intenta crear un archivo:
   touch /mnt/games/nuevo_juego.txt

2. NFS envía la petición al servidor con:
   - UID: 1002 (gamer01 en la VM)
   - GID: 3000 (pcgamers en la VM)

3. El servidor verifica permisos en /srv/nfs/games:
   - Propietario: root
   - Grupo: pcgamers (GID 3000)
   - Permisos: drwxrws--- (2770)

4. El servidor comprueba:
   - ¿El GID 3000 tiene permisos de escritura? ✅ Sí
   - Permite la operación

5. El archivo se crea con:
   - Propietario: gamer01 (UID 1002)
   - Grupo: pcgamers (GID 3000)
```

### **Si el GID fuera diferente:**

```
1. Usuario "gamer01" en la VM (GID 3001) intenta crear archivo

2. NFS envía: GID 3001

3. Servidor verifica: /srv/nfs/games tiene grupo GID 3000

4. ❌ GID 3001 ≠ GID 3000 → Permission denied
```

---

## 📋 Verificación

### **En el servidor:**

```bash
# 1. Ver grupos
getent group pcgamers
getent group servicios

# 2. Ver GID
grep pcgamers /etc/group
# Debe mostrar: pcgamers:x:3000:...

# 3. Ver permisos de directorios NFS
ls -lan /srv/nfs/
# Debe mostrar GID 3000

# 4. Ver exportaciones NFS
cat /etc/exports
# Debe tener: /srv/nfs/games 2025:db8:10::/64(rw,sync,no_subtree_check)
```

### **En la VM:**

```bash
# 1. Ver grupos
getent group pcgamers

# 2. Ver GID
grep pcgamers /etc/group
# Debe mostrar: pcgamers:x:3000:admin,auditor,gamer01

# 3. Ver montajes NFS
mount | grep nfs
# Debe mostrar: [2025:db8:10::2]:/srv/nfs/games on /mnt/games

# 4. Probar permisos
touch /mnt/games/test.txt
ls -l /mnt/games/test.txt
# Debe mostrar: -rw-r--r-- 1 gamer01 pcgamers ...

# 5. Ver desde el servidor
# En el servidor:
ls -l /srv/nfs/games/test.txt
# Debe mostrar el mismo archivo
```

---

## 🎯 Casos de uso

### **Caso 1: Instalar juego en el servidor**

```bash
# En el servidor (como ubuntu)
sudo su - steam_epic_svc
cd /srv/nfs/games
# Instalar juego aquí

# El juego queda con:
# - Owner: steam_epic_svc
# - Group: pcgamers (GID 3000)
# - Permisos: rw-rw-r--

# Desde la VM, cualquier usuario puede acceder:
ls /mnt/games/
# Puede ver y ejecutar el juego
```

### **Caso 2: Usuario en VM guarda partida**

```bash
# En la VM (como gamer01)
cd /mnt/shared/
mkdir partidas_gamer01
echo "Partida guardada" > partidas_gamer01/save.dat

# El archivo queda con:
# - Owner: gamer01 (UID de la VM)
# - Group: pcgamers (GID 3000)

# Desde el servidor:
ls -l /srv/nfs/shared/partidas_gamer01/
# Puede ver el archivo
# Owner: 1002 (UID de gamer01 en la VM)
# Group: pcgamers
```

### **Caso 3: Compartir archivo entre usuarios**

```bash
# Usuario admin en la VM crea archivo:
touch /mnt/shared/documento.txt
chmod 664 /mnt/shared/documento.txt

# Usuario auditor en la VM puede leer:
cat /mnt/shared/documento.txt  # ✅ Funciona

# Usuario gamer01 en la VM puede leer:
cat /mnt/shared/documento.txt  # ✅ Funciona

# Todos tienen grupo pcgamers (GID 3000)
```

---

## ⚠️ Problemas comunes

### **Problema 1: Permission denied en NFS**

**Síntoma:**
```bash
touch /mnt/games/test.txt
# touch: cannot touch '/mnt/games/test.txt': Permission denied
```

**Causa:** GID diferente entre servidor y VM

**Solución:**
```bash
# En la VM:
grep pcgamers /etc/group
# Debe mostrar: pcgamers:x:3000:...

# En el servidor:
grep pcgamers /etc/group
# Debe mostrar: pcgamers:x:3000:...

# Si son diferentes, recrear el grupo con GID correcto:
sudo groupmod -g 3000 pcgamers
```

---

### **Problema 2: Usuario no está en el grupo**

**Síntoma:**
```bash
touch /mnt/games/test.txt
# touch: cannot touch '/mnt/games/test.txt': Permission denied
```

**Causa:** Usuario no pertenece al grupo pcgamers

**Solución:**
```bash
# Ver grupos del usuario
groups gamer01

# Si no está en pcgamers:
sudo usermod -aG pcgamers gamer01

# Cerrar sesión y volver a iniciar
```

---

### **Problema 3: Permisos incorrectos en el servidor**

**Síntoma:**
```bash
ls /mnt/games
# ls: cannot open directory '/mnt/games': Permission denied
```

**Causa:** Permisos incorrectos en `/srv/nfs/games`

**Solución:**
```bash
# En el servidor:
sudo chown root:pcgamers /srv/nfs/games
sudo chmod 2770 /srv/nfs/games

# El bit setgid (2) hace que los archivos creados hereden el grupo
```

---

## 📊 Resumen

| Elemento | Servidor | VM | Debe coincidir |
|----------|----------|-----|----------------|
| **Grupo** | pcgamers | pcgamers | ✅ Nombre |
| **GID** | 3000 | 3000 | ✅ **CRÍTICO** |
| **Miembros** | ubuntu, steam_epic_svc | admin, auditor, gamer01 | ❌ Pueden ser diferentes |
| **Permisos** | 2770 en /srv/nfs/* | Heredados por NFS | ✅ Automático |

**Regla de oro:** El **GID debe ser 3000** en servidor y VMs para que NFS funcione.

---

**Última actualización:** 2024
**Versión:** 1.0
