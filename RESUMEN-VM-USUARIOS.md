# Resumen: VM Ubuntu Desktop con 3 Usuarios

## 🎯 Concepto

**UNA sola VM** con **3 usuarios** diferentes, cada uno con permisos específicos.

```
┌─────────────────────────────────────────────────────────────┐
│         VM: Ubuntu-Desktop-GameCenter                       │
│         IP: 2025:db8:10::100 (DHCP)                        │
│         RAM: 8 GB | CPUs: 4 | Disco: 40 GB                 │
│         Red: M_vm's (red interna IPv6)                     │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │   admin      │  │   auditor    │  │   gamer01    │    │
│  │              │  │              │  │              │    │
│  │ Contraseña:  │  │ Contraseña:  │  │ Contraseña:  │    │
│  │ admin123     │  │ audit123     │  │ gamer123     │    │
│  │              │  │              │  │              │    │
│  │ ✅ Sudo      │  │ ❌ Sudo      │  │ ❌ Sudo      │    │
│  │ ✅ SSH       │  │ ❌ SSH       │  │ ❌ SSH       │    │
│  │ ✅ Logs      │  │ 👁️ Logs     │  │ ❌ Logs      │    │
│  └──────────────┘  └──────────────┘  └──────────────┘    │
│                                                             │
│  Todos comparten:                                          │
│  • /mnt/games (NFS del servidor)                          │
│  • /mnt/shared (NFS del servidor)                         │
│  • Grupo: pcgamers                                        │
└─────────────────────────────────────────────────────────────┘
```

---

## 👥 Usuarios y Permisos

### 1. **admin** (Administrador)

**Inicio de sesión:**
```
Usuario: admin
Contraseña: admin123
```

**Permisos:**
- ✅ Sudo completo (sin contraseña)
- ✅ SSH al servidor (2025:db8:10::2)
- ✅ SSH local (dentro de la VM)
- ✅ Ver y modificar logs
- ✅ Instalar software
- ✅ Modificar configuraciones

**Grupos:**
- `sudo` - Privilegios de administrador
- `adm` - Acceso a logs
- `pcgamers` - Acceso a juegos

**Comandos útiles:**
```bash
# Ver logs del sistema
sudo journalctl -f

# Instalar software
sudo apt install paquete

# SSH al servidor
ssh ubuntu@2025:db8:10::2

# Monitorear sistema
htop
```

---

### 2. **auditor** (Auditor)

**Inicio de sesión:**
```
Usuario: auditor
Contraseña: audit123
```

**Permisos:**
- ❌ NO puede usar sudo
- ❌ NO tiene SSH al servidor
- ❌ NO puede hacer SSH local
- ✅ Puede VER logs (solo lectura)
- ❌ NO puede instalar software
- ❌ NO puede modificar configuraciones

**Grupos:**
- `adm` - Acceso de lectura a logs
- `pcgamers` - Acceso a juegos

**Comandos útiles:**
```bash
# Ver logs (solo lectura)
journalctl -f

# Monitorear sistema
htop

# Ver configuraciones (solo lectura)
cat /etc/netplan/01-netcfg.yaml
```

**Restricciones:**
```bash
# Estos comandos NO funcionarán:
sudo apt install paquete  # Error: no está en sudoers
ssh ubuntu@2025:db8:10::2  # Bloqueado por firewall del servidor
```

---

### 3. **gamer01** (Cliente/Gamer)

**Inicio de sesión:**
```
Usuario: gamer01
Contraseña: gamer123
```

**Permisos:**
- ❌ NO puede usar sudo
- ❌ NO tiene SSH al servidor
- ❌ NO puede hacer SSH local
- ❌ NO puede ver logs del sistema
- ❌ NO puede instalar software del sistema
- ✅ Puede instalar juegos en su directorio
- ✅ Acceso completo a juegos compartidos

**Grupos:**
- `pcgamers` - Acceso a juegos

**Directorios:**
```bash
~/Games/          # Juegos locales (solo este usuario)
~/SharedGames/    # Enlace a /mnt/games (todos los usuarios)
/mnt/shared/      # Archivos compartidos (todos los usuarios)
```

**Comandos útiles:**
```bash
# Ver juegos compartidos
ls ~/SharedGames

# Instalar juego en directorio local
cd ~/Games
# Instalar juego aquí

# Acceder a archivos compartidos
ls /mnt/shared
```

**Restricciones:**
```bash
# Estos comandos NO funcionarán:
sudo apt install paquete  # Error: no está en sudoers
journalctl -f             # Error: sin permisos
ssh ubuntu@2025:db8:10::2  # Bloqueado por firewall del servidor
```

---

## 🔐 Grupo: pcgamers

**Todos los usuarios pertenecen a este grupo:**

```bash
# Ver miembros
getent group pcgamers
# Salida: pcgamers:x:3000:admin,auditor,gamer01
```

**Permisos del grupo:**
- Lectura/escritura en `/mnt/games`
- Lectura/escritura en `/mnt/shared`
- Acceso a juegos instalados

**Archivos compartidos:**
```
/mnt/games/
├── Steam/
├── Epic/
└── GOG/

/mnt/shared/
├── Documentos/
├── Imagenes/
└── Videos/
```

---

## 🚪 Inicio de sesión

### **Desde la interfaz gráfica:**

1. Cierra sesión del usuario actual
2. En la pantalla de login, selecciona el usuario
3. Ingresa la contraseña

### **Desde SSH (solo admin):**

```bash
# Desde el servidor
ssh admin@2025:db8:10::100

# Desde otra máquina
ssh admin@2025:db8:10::100
```

### **Cambiar de usuario (dentro de la VM):**

```bash
# Desde admin a auditor
su - auditor
# Contraseña: audit123

# Desde admin a gamer01
su - gamer01
# Contraseña: gamer123
```

---

## 🔒 Seguridad

### **SSH:**
- Solo `admin` puede hacer SSH
- Configurado en `/etc/ssh/sshd_config`:
  ```
  AllowUsers admin
  ```

### **Firewall del servidor:**
- Admin: ✅ Puede SSH al servidor
- Auditor: ❌ Bloqueado por firewall
- Gamer01: ❌ Bloqueado por firewall

### **Sudo:**
- Solo `admin` tiene sudo
- Admin: sudo sin contraseña
- Auditor: no está en sudoers
- Gamer01: no está en sudoers

---

## 📁 Estructura de directorios

### **Usuario admin:**
```
/home/admin/
├── .ssh/                 # Claves SSH
├── Games/                # Juegos locales
├── SharedGames/          # → /mnt/games
└── LEEME.txt            # Información del usuario
```

### **Usuario auditor:**
```
/home/auditor/
├── Games/                # Juegos locales
├── SharedGames/          # → /mnt/games
└── LEEME.txt            # Información del usuario
```

### **Usuario gamer01:**
```
/home/gamer01/
├── Games/                # Juegos locales
├── SharedGames/          # → /mnt/games
└── LEEME.txt            # Información del usuario
```

---

## ✅ Verificación

### **Verificar usuarios creados:**
```bash
# Listar usuarios
cat /etc/passwd | grep -E "admin|auditor|gamer01"

# Ver grupos de cada usuario
groups admin
groups auditor
groups gamer01
```

### **Verificar permisos:**
```bash
# Probar sudo (solo admin debe funcionar)
sudo -l

# Ver configuración SSH
cat /etc/ssh/sshd_config | grep AllowUsers

# Ver reglas de firewall
sudo ufw status
```

### **Verificar NFS:**
```bash
# Ver montajes
df -h | grep nfs

# Listar juegos compartidos
ls -la /mnt/games
ls -la ~/SharedGames
```

---

## 🎮 Casos de uso

### **Admin:**
```bash
# Administrar el servidor
ssh ubuntu@2025:db8:10::2
sudo systemctl status named

# Instalar software en la VM
sudo apt install steam

# Ver logs
sudo journalctl -u ssh -f

# Configurar red
sudo nano /etc/netplan/01-netcfg.yaml
sudo netplan apply
```

### **Auditor:**
```bash
# Revisar logs (solo lectura)
journalctl -f

# Monitorear sistema
htop

# Ver configuraciones
cat /etc/netplan/01-netcfg.yaml

# Jugar juegos
cd ~/SharedGames
./juego.sh
```

### **Gamer01:**
```bash
# Jugar juegos compartidos
cd ~/SharedGames
./juego.sh

# Instalar juego local
cd ~/Games
# Instalar juego aquí

# Acceder a archivos compartidos
ls /mnt/shared
```

---

## 📊 Comparación rápida

| Acción | admin | auditor | gamer01 |
|--------|-------|---------|---------|
| `sudo apt install` | ✅ | ❌ | ❌ |
| `ssh ubuntu@server` | ✅ | ❌ | ❌ |
| `journalctl -f` | ✅ | ✅ | ❌ |
| `ls /mnt/games` | ✅ | ✅ | ✅ |
| `nano /etc/hosts` | ✅ | ❌ | ❌ |
| Jugar juegos | ✅ | ✅ | ✅ |
| Ver logs | ✅ | ✅ (solo lectura) | ❌ |
| Modificar sistema | ✅ | ❌ | ❌ |

---

## 🔄 Flujo de trabajo

### **Crear y configurar la VM:**

```bash
# 1. Crear VM en ESXi
ansible-playbook create-vm-ubuntu-desktop.yml

# 2. Instalar Ubuntu Desktop manualmente
#    Usuario inicial: admin / admin123

# 3. Configurar red IPv6
sudo netplan apply

# 4. Agregar al inventario (en el servidor)
vim inventory/hosts.ini

# 5. Configurar VM con Ansible (crea los 3 usuarios)
ansible-playbook configure-ubuntu-desktop.yml --ask-become-pass

# 6. ¡Listo! Ahora puedes iniciar sesión con cualquier usuario
```

### **Usar la VM:**

```bash
# Iniciar sesión como admin
# → Administrar sistema, SSH al servidor

# Iniciar sesión como auditor
# → Revisar logs, monitorear

# Iniciar sesión como gamer01
# → Jugar juegos
```

---

**Última actualización:** 2024
**Versión:** 1.0
