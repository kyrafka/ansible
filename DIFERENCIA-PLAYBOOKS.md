# 📚 DIFERENCIA ENTRE PLAYBOOKS

## ⚠️ IMPORTANTE: NO CONFUNDIR

Hay **DOS tipos de playbooks** en este proyecto:

---

## 🖥️ 1. PLAYBOOK DEL SERVIDOR

**Archivo:** `site.yml`  
**Script:** `bash scripts/server/setup-server.sh`

### ¿Cuándo usar?
- Al configurar el **SERVIDOR Ubuntu** por primera vez
- Para instalar servicios de red (DNS, DHCP, NAT64, etc.)
- Cuando necesites reconfigurar servicios del servidor

### ¿Qué hace?
✅ Instala y configura:
- BIND9 (DNS + DNS64)
- ISC-DHCP-SERVER6 (DHCPv6)
- TAYGA (NAT64)
- RADVD (Router Advertisement)
- UFW (Firewall)
- NFS Server (almacenamiento compartido)
- Configuración de red IPv6

❌ NO hace:
- NO crea usuarios adicionales (gamer01, admin, auditor)
- NO instala entorno gráfico
- NO configura clientes

### Roles incluidos:
```yaml
roles:
  - common      # Paquetes base
  - network     # Configuración de red
  - dns_bind    # Servidor DNS
  - dhcpv6      # Servidor DHCP
  - firewall    # Firewall
  - storage     # NFS
```

### Usuario final:
- Solo el usuario `ubuntu` (el que ya existe)
- Contraseña: la que configuraste en la instalación

---

## 🎮 2. PLAYBOOK DE CLIENTES/VMs

**Archivo:** `playbooks/vms/configure-ubuntu-desktop.yml`  
**Script:** `bash scripts/vms/configure-ubuntu-desktop.sh`

### ¿Cuándo usar?
- Al configurar **máquinas CLIENTE** (PCs de gaming)
- Para VMs Ubuntu Desktop que se conectarán al servidor
- Cuando necesites crear usuarios con diferentes roles

### ¿Qué hace?
✅ Instala y configura:
- Entorno de escritorio optimizado
- 3 usuarios con diferentes permisos:
  - `admin` - Administrador (sudo completo, SSH)
  - `auditor` - Auditor (solo lectura)
  - `gamer01` - Cliente/Gamer (sin privilegios)
- Cliente NFS (monta /mnt/games y /mnt/shared)
- Steam, Wine, herramientas de gaming
- Firewall de cliente
- Configuración de red IPv6 DHCP

❌ NO hace:
- NO instala servicios de servidor (DNS, DHCP, etc.)
- NO configura NAT64
- NO crea exports NFS

### Roles incluidos:
```yaml
roles:
  - ubuntu_desktop  # Crea usuarios y configura escritorio
  - seguridad       # Configuración de seguridad por tipo
```

### Usuarios finales:
- `admin` - Contraseña: 123456
- `auditor` - Contraseña: 123456
- `gamer01` - Contraseña: 123456

---

## 🔴 PROBLEMA COMÚN

### ❌ Error: Ejecutar playbook equivocado

Si ejecutas `configure-ubuntu-desktop.yml` en el **SERVIDOR**:
- Se crearán usuarios innecesarios (gamer01, admin, auditor)
- Se instalarán paquetes de gaming que no necesitas
- Tendrás problemas de login

### ✅ Solución:

1. **Para el SERVIDOR:**
   ```bash
   bash scripts/server/setup-server.sh
   # O directamente:
   ansible-playbook site.yml --connection=local --become --ask-become-pass
   ```

2. **Para CLIENTES/VMs:**
   ```bash
   bash scripts/vms/configure-ubuntu-desktop.sh
   # O directamente:
   ansible-playbook playbooks/vms/configure-ubuntu-desktop.yml
   ```

---

## 📊 COMPARACIÓN RÁPIDA

| Característica | SERVIDOR (site.yml) | CLIENTE (configure-ubuntu-desktop.yml) |
|----------------|---------------------|----------------------------------------|
| DNS Server | ✅ | ❌ |
| DHCP Server | ✅ | ❌ |
| NAT64 | ✅ | ❌ |
| NFS Server | ✅ | ❌ |
| NFS Client | ❌ | ✅ |
| Usuarios múltiples | ❌ | ✅ (admin, auditor, gamer01) |
| Gaming tools | ❌ | ✅ (Steam, Wine) |
| Entorno gráfico | ❌ | ✅ |
| Usuario final | ubuntu | admin/auditor/gamer01 |

---

## 🚀 FLUJO CORRECTO DE INSTALACIÓN

### 1️⃣ Primero: Configurar el SERVIDOR
```bash
# En el servidor Ubuntu
cd /ruta/al/proyecto
bash scripts/server/setup-server.sh
```

### 2️⃣ Verificar servicios del servidor
```bash
bash scripts/run/validate-all.sh
```

### 3️⃣ Luego: Configurar CLIENTES (si los hay)
```bash
# Desde el servidor, hacia las VMs cliente
ansible-playbook playbooks/vms/configure-ubuntu-desktop.yml
```

---

## 🔧 SI YA EJECUTASTE EL PLAYBOOK EQUIVOCADO

### Problema: Ejecutaste `configure-ubuntu-desktop.yml` en el servidor

**Síntomas:**
- Usuario `gamer01` existe y no debería
- No puedes iniciar sesión con las contraseñas esperadas
- Hay usuarios `admin` y `auditor` que no necesitas

**Solución:**
```bash
# 1. Recuperar acceso (Recovery Mode o TTY)
# Presiona Ctrl+Alt+F3 o usa Recovery Mode

# 2. Eliminar usuarios no deseados
sudo bash scripts/setup/fix-login-passwords.sh

# 3. Reconfigurar el servidor correctamente
bash scripts/server/setup-server.sh
```

---

## 📝 RESUMEN

- **SERVIDOR** = `site.yml` = Solo servicios de red, usuario `ubuntu`
- **CLIENTE** = `configure-ubuntu-desktop.yml` = Usuarios múltiples, gaming, escritorio

**Regla de oro:** Si es el servidor que da servicios de red, usa `site.yml`. Si es una máquina que se conecta al servidor, usa `configure-ubuntu-desktop.yml`.
