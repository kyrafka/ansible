# 📁 ¿Qué es NFS y para qué sirve?

## 🎯 Concepto Simple

**NFS** = **Network File System** (Sistema de Archivos en Red)

Es como tener una **carpeta compartida en red** que varios equipos pueden usar al mismo tiempo.

---

## 🏢 Analogía del Mundo Real

Imagina que tienes:
- **Un servidor** = Una biblioteca central
- **Clientes (PCs)** = Personas que van a la biblioteca

Con NFS:
- El servidor tiene carpetas compartidas (libros en estantes)
- Los clientes pueden ver y usar esas carpetas como si fueran locales
- Todos ven los mismos archivos actualizados en tiempo real

---

## 🎮 En tu Proyecto GameCenter

### Servidor (Ubuntu Server):
```
/srv/nfs/games/     ← Carpeta con juegos e instaladores
/srv/nfs/shared/    ← Carpeta con archivos compartidos
```

### Clientes (PCs de Gaming):
```
/mnt/games/         ← Monta /srv/nfs/games del servidor
/mnt/shared/        ← Monta /srv/nfs/shared del servidor
```

**Resultado:** Los PCs de gaming ven las carpetas del servidor como si fueran locales.

---

## ✅ Ventajas de NFS

### 1. **Almacenamiento Centralizado**
- Guardas los juegos UNA VEZ en el servidor
- Todos los clientes pueden acceder
- No duplicas archivos en cada PC

### 2. **Fácil Mantenimiento**
- Actualizas un juego en el servidor
- Todos los clientes ven la actualización
- No necesitas ir PC por PC

### 3. **Ahorro de Espacio**
- Un juego de 50GB está solo en el servidor
- Los clientes no necesitan copiarlo
- Pueden ejecutarlo directamente desde la red

### 4. **Gestión Centralizada**
- Backups en un solo lugar
- Control de permisos desde el servidor
- Fácil agregar/quitar contenido

---

## 🔧 Cómo Funciona en tu Red

```
┌─────────────────────────────────────────────────────────────┐
│                    SERVIDOR (Ubuntu Server)                 │
│                                                             │
│  📁 /srv/nfs/games/                                         │
│     ├── Minecraft.zip                                       │
│     ├── Steam/                                              │
│     └── Instaladores/                                       │
│                                                             │
│  📁 /srv/nfs/shared/                                        │
│     ├── Documentos/                                         │
│     ├── Configuraciones/                                    │
│     └── Mods/                                               │
│                                                             │
│  🔧 NFS Server (exporta las carpetas)                       │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ Red IPv6
                            │ 2025:db8:10::/64
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│   PC Gamer 1  │   │   PC Gamer 2  │   │   PC Gamer 3  │
│               │   │               │   │               │
│ /mnt/games/   │   │ /mnt/games/   │   │ /mnt/games/   │
│ /mnt/shared/  │   │ /mnt/shared/  │   │ /mnt/shared/  │
│               │   │               │   │               │
│ (monta NFS)   │   │ (monta NFS)   │   │ (monta NFS)   │
└───────────────┘   └───────────────┘   └───────────────┘
```

---

## 📋 Configuración en tu Proyecto

### En el Servidor:

**1. Carpetas creadas:**
```bash
/srv/nfs/games/     # Juegos e instaladores
/srv/nfs/shared/    # Archivos compartidos
```

**2. Archivo de configuración:** `/etc/exports`
```
/srv/nfs/games    2025:db8:10::/64(rw,sync,no_subtree_check)
/srv/nfs/shared   2025:db8:10::/64(rw,sync,no_subtree_check)
```

**Significado:**
- `2025:db8:10::/64` = Solo tu red local puede acceder
- `rw` = Lectura y escritura
- `sync` = Cambios se guardan inmediatamente
- `no_subtree_check` = Mejor rendimiento

**3. Servicio:**
```bash
sudo systemctl start nfs-kernel-server
sudo systemctl enable nfs-kernel-server
```

### En los Clientes:

**1. Instalar cliente NFS:**
```bash
sudo apt install nfs-common
```

**2. Crear puntos de montaje:**
```bash
sudo mkdir -p /mnt/games
sudo mkdir -p /mnt/shared
```

**3. Montar carpetas NFS:**
```bash
sudo mount -t nfs [2025:db8:10::2]:/srv/nfs/games /mnt/games
sudo mount -t nfs [2025:db8:10::2]:/srv/nfs/shared /mnt/shared
```

**4. Montaje automático:** `/etc/fstab`
```
[2025:db8:10::2]:/srv/nfs/games   /mnt/games   nfs4   defaults   0 0
[2025:db8:10::2]:/srv/nfs/shared  /mnt/shared  nfs4   defaults   0 0
```

---

## 🔍 Comandos Útiles

### En el Servidor:

```bash
# Ver exports configurados
cat /etc/exports

# Ver exports activos
exportfs -v

# Ver qué clientes están conectados
showmount -a

# Recargar configuración
sudo exportfs -ra

# Ver logs
sudo journalctl -u nfs-kernel-server -n 50
```

### En los Clientes:

```bash
# Ver exports disponibles del servidor
showmount -e 2025:db8:10::2

# Ver montajes NFS activos
mount | grep nfs

# Desmontar
sudo umount /mnt/games
sudo umount /mnt/shared

# Probar acceso
ls -la /mnt/games
touch /mnt/games/test.txt
```

---

## 🎮 Casos de Uso Prácticos

### 1. **Biblioteca de Juegos Compartida**
```
Servidor: /srv/nfs/games/Steam/
Clientes: /mnt/games/Steam/

→ Instalas Steam games una vez
→ Todos los PCs pueden jugarlos
```

### 2. **Instaladores Centralizados**
```
Servidor: /srv/nfs/games/Instaladores/
         ├── Discord.exe
         ├── Chrome.exe
         └── Drivers/

→ Descargas programas una vez
→ Instalas desde cualquier PC
```

### 3. **Configuraciones Compartidas**
```
Servidor: /srv/nfs/shared/Configs/
         ├── game-settings.ini
         └── mods/

→ Cambias config en un lugar
→ Todos los PCs la usan
```

### 4. **Saves/Partidas Guardadas**
```
Servidor: /srv/nfs/shared/Saves/
         └── minecraft-world/

→ Guardas partida en el servidor
→ Continúas desde cualquier PC
```

---

## ⚠️ Consideraciones Importantes

### Rendimiento:
- ✅ Bueno para: Archivos pequeños, instaladores, documentos
- ⚠️ Regular para: Juegos grandes que se ejecutan desde la red
- 💡 Mejor: Instalar juegos localmente, usar NFS para instaladores

### Seguridad:
- Solo tu red local (2025:db8:10::/64) puede acceder
- Firewall del servidor protege el acceso
- Permisos de Linux se respetan

### Disponibilidad:
- Si el servidor se cae, los clientes pierden acceso
- Los archivos solo existen en el servidor
- **Importante:** Hacer backups del servidor

---

## 🚀 Flujo de Trabajo Típico

### Agregar un Juego:

**1. En el servidor:**
```bash
cd /srv/nfs/games
sudo mkdir Minecraft
sudo chown root:pcgamers Minecraft
sudo chmod 775 Minecraft
# Copiar archivos del juego
```

**2. En cualquier cliente:**
```bash
ls /mnt/games/Minecraft
# El juego ya está disponible
```

### Actualizar un Juego:

**1. En el servidor:**
```bash
cd /srv/nfs/games/Minecraft
sudo cp nuevo-mod.jar mods/
```

**2. En los clientes:**
```bash
# Automáticamente ven el nuevo mod
ls /mnt/games/Minecraft/mods/
```

---

## 📊 Resumen

| Característica | Descripción |
|----------------|-------------|
| **Qué es** | Sistema de archivos compartidos en red |
| **Para qué** | Compartir juegos, instaladores, archivos |
| **Ventaja** | Almacenamiento centralizado |
| **Protocolo** | NFS v4 sobre IPv6 |
| **Puerto** | 2049 (TCP/UDP) |
| **Servicio** | nfs-kernel-server |
| **Configuración** | /etc/exports |

---

## 🔧 Solución de Problemas

### Problema: "Permission denied"
```bash
# En el servidor, verificar permisos
ls -la /srv/nfs/games
sudo chown -R root:pcgamers /srv/nfs/games
sudo chmod -R 775 /srv/nfs/games
```

### Problema: "No route to host"
```bash
# Verificar firewall
sudo ufw allow from 2025:db8:10::/64 to any port 2049
```

### Problema: "Stale file handle"
```bash
# En el cliente, remontar
sudo umount -f /mnt/games
sudo mount -t nfs [2025:db8:10::2]:/srv/nfs/games /mnt/games
```

---

## ✅ Verificación Rápida

```bash
# En el servidor
bash scripts/run/validate-storage.sh

# Debe mostrar:
# ✅ NFS server está activo
# ✅ /srv/nfs/games existe
# ✅ /srv/nfs/shared existe
# ✅ Exports activos
```

---

**En resumen:** NFS es como Dropbox/Google Drive, pero en tu propia red local, más rápido y con control total.
