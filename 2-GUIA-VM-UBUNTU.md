# ════════════════════════════════════════════════════════════════
# GUÍA 2: CONFIGURACIÓN DE VM UBUNTU DESKTOP
# ════════════════════════════════════════════════════════════════

## 📋 Requisitos

- VM creada en ESXi
- Ubuntu Desktop 24.04 instalado
- Usuario inicial: administrador / Contraseña: 123
- Red: M_vm's (IPv6)

---

## 🎯 RESUMEN DE LO QUE SE CONFIGURA

- ✅ 3 usuarios con roles diferentes
- ✅ Internet (IPv6 + NAT64 + Proxy)
- ✅ DNS local
- ✅ Tema oscuro y optimizado
- ✅ Carpetas organizadas por rol

---

## 🚀 CONFIGURACIÓN

### OPCIÓN A: Con adaptador temporal (RECOMENDADO)

#### 1. Agregar adaptador de red temporal

En vSphere: Agregar segundo adaptador → VM Network (IPv4)

#### 2. Instalar dependencias (DENTRO DE LA VM)

```bash
sudo apt update
sudo apt install -y git openssh-server
```

#### 3. Clonar repositorio

```bash
cd ~
git clone <URL_REPO> ansible
cd ansible
```

#### 4. Ejecutar configuración completa

```bash
sudo bash scripts/vm-setup-complete.sh
```

**Este script configura:**
- Proxy (apt y sistema)
- SSH
- Ansible
- 3 usuarios (administrador, auditor, gamer01)
- Grupos y permisos
- Directorios

#### 5. Quitar adaptador temporal

- Apagar VM
- Quitar adaptador de VM Network
- Encender VM

#### 6. Verificar internet

```bash
ping6 google.com
```

---

### OPCIÓN B: Desde el servidor (con SSH)

#### 1. Obtener IP de la VM

En la VM:
```bash
ip -6 addr show ens33 | grep "scope global"
```

#### 2. Agregar al inventario (EN EL SERVIDOR)

Editar `inventory/hosts.ini`:
```ini
[ubuntu_desktops]
ubuntu123 ansible_host=2025:db8:10::dce9 ansible_user=administrador ansible_password=123 ansible_become_password=123
```

#### 3. Ejecutar configuración (EN EL SERVIDOR)

```bash
bash scripts/vms/configure-ubuntu-desktop-interactive.sh
```

---

## 🎨 PERSONALIZACIÓN (DENTRO DE LA VM)

### 1. Configuración local

```bash
cd ~/ansible
bash scripts/vm-local-setup.sh
```

**Qué hace:**
- Configura GNOME (tema oscuro, sin animaciones)
- Verifica internet y DNS
- Crea enlaces útiles
- Muestra comandos útiles

⚠️ **Debe ejecutarse CON sesión gráfica activa**

---

### 2. Mejorar apariencia

```bash
bash scripts/beautify-ubuntu-desktop.sh
```

**Qué hace:**
- Instala iconos Papirus
- Instala fuente Fira Code
- Configura dock (abajo, transparente)
- Terminal con colores VS Code

---

### 3. Aplicar tema a todos los usuarios

```bash
sudo bash scripts/apply-global-theme.sh
```

**Qué hace:**
- Aplica tema oscuro globalmente
- Configura para administrador, auditor, gamer01
- Pantalla de login con tema oscuro

---

### 4. Configurar proxy en Firefox

**Automático:**
```bash
gsettings set org.gnome.system.proxy mode 'manual'
gsettings set org.gnome.system.proxy.http host '2025:db8:10::2'
gsettings set org.gnome.system.proxy.http port 3128
gsettings set org.gnome.system.proxy.https host '2025:db8:10::2'
gsettings set org.gnome.system.proxy.https port 3128
```

**Manual (si no funciona):**
- Firefox → Configuración → Buscar "proxy"
- Manual: `2025:db8:10::2` puerto `3128`
- ✓ Usar también para HTTPS

---

### 5. Arreglar roles (si hay usuarios duplicados)

```bash
sudo bash scripts/fix-3-roles-only.sh
```

---

## 👥 USUARIOS CONFIGURADOS

| Usuario | Contraseña | Sudo | SSH Servidor | Función |
|---------|------------|------|--------------|---------|
| administrador | 123 | ✅ | ✅ | Admin completo |
| auditor | 123456 | ❌ | ❌ | Solo lectura |
| gamer01 | 123456 | ❌ | ❌ | Cliente/Gamer |

---

## 📁 CARPETAS

```
/srv/admin        → administrador (privada)
/srv/audits       → auditor (privada)
/srv/games        → compartida (grupo pcgamers)
/mnt/games        → NFS (juegos del servidor)
```

---

## 🧪 PROBAR ROLES

### Como administrador:

```bash
whoami                              # administrador
sudo whoami                         # root ✅
echo "test" > /srv/games/test.txt   # ✅ Funciona
ssh ubuntu@2025:db8:10::2           # ✅ Conecta
ping6 google.com                    # ✅ Internet
```

### Como auditor:

```bash
whoami                              # auditor
sudo whoami                         # ❌ Falla
cat /srv/games/test.txt             # ✅ Puede leer
echo "x" > /srv/games/test.txt      # ❌ No puede escribir
ssh ubuntu@2025:db8:10::2           # ❌ Bloqueado
journalctl -n 10                    # ✅ Puede ver logs
```

### Como gamer01:

```bash
whoami                              # gamer01
sudo whoami                         # ❌ Falla
cat /srv/games/test.txt             # ✅ Puede leer
echo "x" > /srv/games/test.txt      # ❌ No puede escribir
ssh ubuntu@2025:db8:10::2           # ❌ Bloqueado
journalctl -n 10                    # ❌ No puede ver logs
```

---

## ✅ VERIFICACIONES

```bash
# Internet
ping6 google.com

# DNS
dig ubuntu123.gamecenter.lan AAAA

# Servidor
ping6 2025:db8:10::2

# SSH (solo administrador)
ssh ubuntu@2025:db8:10::2

# Proxy
echo $http_proxy
```

---

## 🔧 SCRIPTS DISPONIBLES

| Script | Dónde ejecutar | Qué hace |
|--------|----------------|----------|
| `vm-setup-complete.sh` | Dentro VM (root) | Configuración inicial completa |
| `vm-local-setup.sh` | Dentro VM (usuario) | Configuración GNOME |
| `beautify-ubuntu-desktop.sh` | Dentro VM (usuario) | Mejora visual |
| `apply-global-theme.sh` | Dentro VM (root) | Tema para todos |
| `fix-3-roles-only.sh` | Dentro VM (root) | Limpia usuarios duplicados |
| `test-user-roles.sh` | Dentro VM (root) | Prueba permisos |
| `test-my-role.sh` | Dentro VM (usuario) | Prueba mi rol |

---

## 🎮 INSTALAR MINECRAFT (Opcional)

```bash
cd ~/ansible
sudo bash scripts/install-minecraft-server.sh
```

**Conectarse desde otro PC:**
```
Minecraft → Multijugador → Servidor Directo
Dirección: [2025:db8:10::dce9]:25565
```

---

# ════════════════════════════════════════════════════════════════
# FIN GUÍA VM UBUNTU
# ════════════════════════════════════════════════════════════════
