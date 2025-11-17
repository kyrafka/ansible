# ════════════════════════════════════════════════════════════════
# PROYECTO GAMECENTER - ÍNDICE DE DOCUMENTACIÓN
# ════════════════════════════════════════════════════════════════

## 📚 Guías disponibles

### 1️⃣ [GUIA-SERVIDOR.md](1-GUIA-SERVIDOR.md)
**Configuración completa del servidor Ubuntu Server**

- Instalación de componentes
- Orden correcto de ejecución
- Validaciones y diagnóstico
- Comandos útiles

**Componentes:**
- Red (IPv6 + Forwarding)
- DNS (BIND9 + DNS64)
- NAT64 (Tayga) - CRÍTICO
- Proxy (Squid)
- DHCP (DHCPv6 + DDNS)
- Firewall (UFW)
- Usuarios (ubuntu, auditor, dev)

---

### 2️⃣ [GUIA-VM-UBUNTU.md](2-GUIA-VM-UBUNTU.md)
**Configuración de VMs Ubuntu Desktop**

- Creación de VMs
- Configuración inicial (con/sin internet temporal)
- Personalización visual
- 3 usuarios con roles
- Pruebas de permisos

**Scripts:**
- Configuración completa
- Personalización visual
- Gestión de roles
- Instalación de Minecraft

---

### 3️⃣ [GUIA-VM-WINDOWS11.md](docs/GUIA-VM-WINDOWS11.md)
**Configuración de VMs Windows 11**

- Creación automática con script
- Instalación de Windows 11
- Drivers VirtIO (red y disco)
- Configuración de red IPv6
- Gestión de usuarios (admin, auditor, gamer01)

**Características:**
- TPM 2.0 y Secure Boot
- Acceso a Internet vía NAT64
- Configuración manual (no Ansible)
- Listo para gaming

---

### 4️⃣ [DOCUMENTACION.md](3-DOCUMENTACION.md)
**Documentación técnica del proyecto**

- Conceptos clave (NAT64, DNS64, NFS, etc.)
- Arquitectura de red
- Flujos de datos
- Roles y permisos
- Troubleshooting
- Dependencias

---

### 5️⃣ [GUIA-VIRTUALBOX.md](docs/GUIA-VIRTUALBOX.md)
**Usar VirtualBox en PC local (desarrollo)**

- Diferencias KVM vs VirtualBox
- Scripts adaptados para VirtualBox
- Configuración de red (NAT/Internal)
- Réplica del servidor en local
- Comandos útiles VBoxManage

**Para:**
- Desarrollo y pruebas en PC
- Probar scripts antes de producción
- Aprender sin servidor físico

---

## 🎯 ¿Por dónde empezar?

### Si eres nuevo:
1. Lee [DOCUMENTACION.md](3-DOCUMENTACION.md) para entender los conceptos
2. Sigue [GUIA-SERVIDOR.md](1-GUIA-SERVIDOR.md) para configurar el servidor
3. Sigue [GUIA-VM-UBUNTU.md](2-GUIA-VM-UBUNTU.md) para crear VMs Ubuntu
4. Sigue [GUIA-VM-WINDOWS11.md](docs/GUIA-VM-WINDOWS11.md) para crear VMs Windows

### Si ya tienes el servidor configurado:
1. Ve directo a [GUIA-VM-UBUNTU.md](2-GUIA-VM-UBUNTU.md) para Ubuntu
2. O a [GUIA-VM-WINDOWS11.md](docs/GUIA-VM-WINDOWS11.md) para Windows 11

### Si tienes problemas:
1. Revisa la sección de Troubleshooting en cada guía
2. Consulta [DOCUMENTACION.md](3-DOCUMENTACION.md) para entender el problema

---

## 🏗️ Arquitectura del proyecto

```
Internet (IPv4)
    ↓
Servidor Ubuntu (ens33: IPv4, ens34: IPv6)
    ├── BIND9 (DNS + DNS64)
    ├── Tayga (NAT64) ⭐ CRÍTICO
    ├── Squid (Proxy)
    ├── DHCPv6 (+ DDNS)
    └── NFS (juegos compartidos)
    ↓
Switch M_vm's (IPv6)
    ↓
VMs Ubuntu Desktop (IPv6 only)
    ├── administrador (admin)
    ├── auditor (lectura)
    └── gamer01 (cliente)
```

---

## 👥 Usuarios del sistema

### Servidor:
- **ubuntu** (123) - Admin completo, SSH ✅
- **auditor** (123) - Solo lectura, SSH ❌
- **dev** (123) - Gestión servicios, SSH ❌

### VM Ubuntu Desktop:
- **administrador** (123) - Admin completo, SSH ✅
- **auditor** (123456) - Solo lectura, SSH ❌
- **gamer01** (123456) - Cliente, SSH ❌

---

## 🔧 Scripts principales

### Servidor:
- `scripts/nat64/install-nat64-tayga.sh` - Instalar NAT64
- `scripts/install-squid-proxy.sh` - Instalar proxy
- `scripts/configure-dns64-simple.sh` - Configurar DNS64
- `scripts/server-create-users.sh` - Crear usuarios
- `scripts/verify-ssh-restriction.sh` - Restringir SSH

### VM Ubuntu:
- `scripts/vm-setup-complete.sh` - Configuración inicial
- `scripts/vm-local-setup.sh` - Configuración GNOME
- `scripts/beautify-ubuntu-desktop.sh` - Mejora visual
- `scripts/apply-global-theme.sh` - Tema global
- `scripts/fix-3-roles-only.sh` - Arreglar roles

### VM Windows:
- `scripts/vms/crear-vm-windows11.sh` - Crear VM Windows 11

### Diagnóstico:
- `scripts/diagnose-ssh-problem.sh` - Diagnosticar SSH
- `scripts/test-user-roles.sh` - Probar permisos
- `scripts/run/validate-all.sh` - Validar todo

---

## 📝 Archivos importantes

```
ansible-gestion-despliegue/
├── 0-INDICE.md                    ← Estás aquí
├── 1-GUIA-SERVIDOR.md             ← Configurar servidor
├── 2-GUIA-VM-UBUNTU.md            ← Configurar VMs
├── 3-DOCUMENTACION.md             ← Conceptos técnicos
├── group_vars/
│   ├── all.yml                    ← Variables globales
│   └── all.vault.yml              ← Contraseñas encriptadas
├── inventory/
│   └── hosts.ini                  ← Inventario de VMs
├── playbooks/                     ← Playbooks de Ansible
├── roles/                         ← Roles de Ansible
└── scripts/                       ← Scripts de automatización
    ├── nat64/                     ← NAT64 (Tayga)
    ├── vms/                       ← Gestión de VMs
    └── run/                       ← Ejecución y validación
```

---

## 🆘 Soporte rápido

### VM sin internet:
```bash
# En servidor
sudo bash scripts/nat64/install-nat64-tayga.sh
```

### DNS no funciona:
```bash
sudo bash scripts/dns-clean-and-reload.sh
```

### SSH permite usuarios incorrectos:
```bash
sudo bash scripts/verify-ssh-restriction.sh
```

### Roles no funcionan:
```bash
sudo bash scripts/fix-3-roles-only.sh
```

---

# ════════════════════════════════════════════════════════════════
# FIN ÍNDICE
# ════════════════════════════════════════════════════════════════
