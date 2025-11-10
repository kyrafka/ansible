# Usuarios y Contraseñas del Sistema

Resumen de todos los usuarios, contraseñas y privilegios.

---

## 🖥️ Servidor Ubuntu (Ubuntu_server_virtual)

### **Usuario: ubuntu**
```
Usuario: ubuntu
Contraseña: ubuntu123
Grupos: sudo, adm
Privilegios: Administrador completo del servidor
SSH: ✅ Sí
Sudo: ✅ Sí
```

**Uso:**
- Administrar el servidor
- Configurar servicios (DNS, DHCP, NFS, Firewall)
- Ejecutar playbooks de Ansible

---

### **Usuario: steam_epic_svc** (servicio)
```
Usuario: steam_epic_svc
Contraseña: N/A (sin login)
Shell: /usr/sbin/nologin
Grupos: servicios, pcgamers
Privilegios: Usuario de servicio (sin login interactivo)
```

**Uso:**
- Ejecutar servicios de Steam/Epic en background
- Propietario de `/srv/steam_epic_svc`
- NO puede iniciar sesión

---

### **Usuario: gamer01** (opcional en servidor)
```
Usuario: gamer01
Contraseña: (definida en all.yml)
Grupos: pcgamers
Privilegios: Usuario normal
```

**Uso:**
- Usuario opcional en el servidor
- Acceso a `/srv/nfs/games`

---

## 🖥️ VM Ubuntu Desktop (Ubuntu-Desktop-GameCenter)

### **Usuario 1: admin**
```
Usuario: admin
Contraseña: 123456
Grupos: sudo, adm, pcgamers
Shell: /bin/bash
```

**Privilegios:**
- ✅ Sudo completo (sin contraseña)
- ✅ SSH al servidor (2025:db8:10::2)
- ✅ SSH local (dentro de la VM)
- ✅ Ver y modificar logs del sistema
- ✅ Instalar software
- ✅ Modificar configuraciones
- ✅ Acceso a juegos compartidos (NFS)

**Comandos útiles:**
```bash
# Iniciar sesión
Usuario: admin
Contraseña: 123456

# SSH al servidor
ssh ubuntu@2025:db8:10::2

# Instalar software
sudo apt install paquete

# Ver logs
sudo journalctl -f

# Monitorear sistema
htop
```

**Archivos de configuración:**
- `/home/admin/.ssh/` - Claves SSH
- `/home/admin/Games/` - Juegos locales
- `/home/admin/SharedGames/` → `/mnt/games` (NFS)

---

### **Usuario 2: auditor**
```
Usuario: auditor
Contraseña: 123456
Grupos: adm, pcgamers
Shell: /bin/bash
```

**Privilegios:**
- ❌ NO puede usar sudo
- ❌ NO tiene SSH al servidor (bloqueado por firewall)
- ❌ NO puede hacer SSH local
- ✅ Puede VER logs (solo lectura)
- ❌ NO puede instalar software
- ❌ NO puede modificar configuraciones
- ✅ Acceso a juegos compartidos (NFS)

**Comandos útiles:**
```bash
# Iniciar sesión
Usuario: auditor
Contraseña: 123456

# Ver logs (solo lectura)
journalctl -f

# Monitorear sistema
htop

# Ver configuraciones (solo lectura)
cat /etc/netplan/01-netcfg.yaml

# Acceder a juegos
cd ~/SharedGames
```

**Restricciones:**
```bash
# Estos comandos NO funcionarán:
sudo apt install paquete  # Error: no está en sudoers
ssh ubuntu@2025:db8:10::2  # Bloqueado por firewall del servidor
sudo nano /etc/hosts      # Error: no está en sudoers
```

---

### **Usuario 3: gamer01**
```
Usuario: gamer01
Contraseña: 123456
Grupos: pcgamers
Shell: /bin/bash
```

**Privilegios:**
- ❌ NO puede usar sudo
- ❌ NO tiene SSH al servidor (bloqueado por firewall)
- ❌ NO puede hacer SSH local
- ❌ NO puede ver logs del sistema
- ❌ NO puede instalar software del sistema
- ✅ Puede instalar juegos en su directorio
- ✅ Acceso completo a juegos compartidos (NFS)

**Comandos útiles:**
```bash
# Iniciar sesión
Usuario: gamer01
Contraseña: 123456

# Ver juegos compartidos
ls ~/SharedGames

# Instalar juego en directorio local
cd ~/Games
# Instalar juego aquí

# Acceder a archivos compartidos
ls /mnt/shared

# Jugar
cd ~/SharedGames/Steam
./juego.sh
```

**Restricciones:**
```bash
# Estos comandos NO funcionarán:
sudo apt install paquete  # Error: no está en sudoers
journalctl -f             # Error: sin permisos
ssh ubuntu@2025:db8:10::2  # Bloqueado por firewall del servidor
```

---

## 🔐 Resumen de Contraseñas

### **Servidor:**
| Usuario | Contraseña | Ubicación |
|---------|------------|-----------|
| ubuntu | ubuntu123 | `vault_ubuntu_password` |
| steam_epic_svc | N/A (nologin) | - |

### **VM Ubuntu Desktop:**
| Usuario | Contraseña | Ubicación |
|---------|------------|-----------|
| admin | 123456 | `vault_ubuntu_desktop_admin_password` |
| auditor | 123456 | `vault_ubuntu_desktop_auditor_password` |
| gamer01 | 123456 | `vault_ubuntu_desktop_cliente_password` |

**Archivo:** `group_vars/all.vault.yml`

---

## 🔒 Seguridad

### **SSH:**
```yaml
# En el servidor:
- ubuntu: ✅ Puede SSH desde cualquier lugar

# En la VM:
- admin: ✅ Puede SSH al servidor
- auditor: ❌ Bloqueado por firewall del servidor
- gamer01: ❌ Bloqueado por firewall del servidor

# SSH local (dentro de la VM):
- admin: ✅ Puede hacer SSH
- auditor: ❌ NO puede hacer SSH
- gamer01: ❌ NO puede hacer SSH
```

**Configuración SSH de la VM:**
```
# /etc/ssh/sshd_config
AllowUsers admin
```

### **Sudo:**
```yaml
# En el servidor:
- ubuntu: ✅ Sudo con contraseña

# En la VM:
- admin: ✅ Sudo SIN contraseña
- auditor: ❌ NO está en sudoers
- gamer01: ❌ NO está en sudoers
```

**Configuración sudo:**
```
# /etc/sudoers.d/admin
admin ALL=(ALL) NOPASSWD:ALL
```

### **Firewall del servidor:**
```yaml
# Reglas UFW en el servidor:
- Puerto 22 (SSH):
  - Desde admin (2025:db8:10::102): ✅ ALLOW
  - Desde auditor: ❌ DENY
  - Desde gamer01: ❌ DENY

# Esto se configura automáticamente cuando agregas
# las VMs al inventario con vm_role definido
```

---

## 📁 Directorios por Usuario

### **admin:**
```
/home/admin/
├── .ssh/                 # Claves SSH
├── Games/                # Juegos locales
├── SharedGames/          # → /mnt/games (NFS)
└── LEEME.txt            # Información del usuario
```

### **auditor:**
```
/home/auditor/
├── Games/                # Juegos locales
├── SharedGames/          # → /mnt/games (NFS)
└── LEEME.txt            # Información del usuario
```

### **gamer01:**
```
/home/gamer01/
├── Games/                # Juegos locales
├── SharedGames/          # → /mnt/games (NFS)
└── LEEME.txt            # Información del usuario
```

---

## 🎮 Grupo: pcgamers

**Todos los usuarios pertenecen a este grupo:**

```bash
# Ver miembros
getent group pcgamers
# Salida: pcgamers:x:3000:admin,auditor,gamer01
```

**Permisos:**
- Lectura/escritura en `/mnt/games` (NFS)
- Lectura/escritura en `/mnt/shared` (NFS)
- GID: 3000 (mismo en servidor y VM)

---

## 🔄 Cambiar Contraseñas

### **En el servidor:**
```bash
# Cambiar contraseña de ubuntu
sudo passwd ubuntu

# Actualizar en Ansible
vim group_vars/all.vault.yml
# Cambiar: vault_ubuntu_password
```

### **En la VM:**
```bash
# Como admin (puede cambiar cualquier contraseña)
sudo passwd admin
sudo passwd auditor
sudo passwd gamer01

# Como auditor o gamer01 (solo su propia contraseña)
passwd
```

### **Actualizar en Ansible:**
```bash
# Editar archivo de contraseñas
vim group_vars/all.vault.yml

# Cambiar:
vault_ubuntu_desktop_admin_password: "nueva_contraseña"
vault_ubuntu_desktop_auditor_password: "nueva_contraseña"
vault_ubuntu_desktop_cliente_password: "nueva_contraseña"

# Volver a ejecutar configuración
ansible-playbook configure-ubuntu-desktop.yml --ask-become-pass
```

---

## 🔐 Encriptar Contraseñas

Para mayor seguridad, encripta el archivo de contraseñas:

```bash
# Encriptar
./encrypt-vault.sh

# Editar después de encriptar
ansible-vault edit group_vars/all.vault.yml --vault-password-file .vault_pass

# Desencriptar (si es necesario)
ansible-vault decrypt group_vars/all.vault.yml --vault-password-file .vault_pass
```

---

## 📊 Tabla Comparativa

| Acción | admin | auditor | gamer01 |
|--------|-------|---------|---------|
| **Iniciar sesión en VM** | ✅ | ✅ | ✅ |
| **Sudo** | ✅ Sin contraseña | ❌ | ❌ |
| **SSH al servidor** | ✅ | ❌ | ❌ |
| **SSH local** | ✅ | ❌ | ❌ |
| **Ver logs** | ✅ | ✅ Solo lectura | ❌ |
| **Instalar software** | ✅ | ❌ | ❌ |
| **Modificar sistema** | ✅ | ❌ | ❌ |
| **Acceso NFS** | ✅ | ✅ | ✅ |
| **Jugar juegos** | ✅ | ✅ | ✅ |
| **Contraseña** | 123456 | 123456 | 123456 |

---

## ⚠️ Notas de Seguridad

1. **Contraseñas simples:** Las contraseñas actuales (123456) son para desarrollo/testing. En producción, usa contraseñas más seguras.

2. **Encriptación:** Considera encriptar `all.vault.yml` con `./encrypt-vault.sh` antes de subir a git.

3. **SSH Keys:** Para mayor seguridad, configura autenticación por clave SSH en lugar de contraseña.

4. **Firewall:** El firewall del servidor bloquea SSH desde auditor y gamer01 automáticamente.

5. **Logs:** Todos los intentos de sudo y SSH se registran en `/var/log/auth.log`.

---

**Última actualización:** 2024
**Versión:** 1.0
