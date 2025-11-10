# ¿Dónde Ejecutar Cada Playbook?

Guía rápida de dónde ejecutar cada playbook.

---

## 🖥️ Desde tu PC (Windows)

### **Playbooks de creación de VMs:**

Estos playbooks se conectan a ESXi para crear VMs, por lo tanto deben ejecutarse desde tu PC que tiene acceso a la IP de gestión de ESXi.

```bash
# En tu PC Windows (PowerShell, CMD o Git Bash)
cd C:\Users\Diego\Desktop\sdqwqd\ansible-gestion-despliegue

# Ejecutar playbooks de creación:
ansible-playbook create-vm-ubuntu-desktop.yml
ansible-playbook create-vm-gamecenter.yml
```

**Playbooks que van desde el PC:**
- ✅ `create-vm-ubuntu-desktop.yml` - Crear VM Ubuntu Desktop
- ✅ `create-vm-gamecenter.yml` - Crear VM del servidor
- ✅ Cualquier playbook que use `community.vmware.vmware_guest`

**¿Por qué desde el PC?**
- Tu PC puede acceder a ESXi en `168.121.48.254:10111`
- El servidor está **dentro** de ESXi y puede no tener acceso a la IP de gestión

---

## 🖥️ Desde el Servidor (Ubuntu)

### **Playbooks de configuración:**

Estos playbooks configuran las VMs después de crearlas, por lo tanto deben ejecutarse desde el servidor que tiene acceso a la red interna (2025:db8:10::/64).

```bash
# En el servidor Ubuntu
cd ~/ansible
source ~/.ansible-venv/bin/activate

# Ejecutar playbooks de configuración:
ansible-playbook configure-ubuntu-desktop.yml --ask-become-pass
ansible-playbook site.yml --connection=local --become --ask-become-pass
```

**Playbooks que van desde el servidor:**
- ✅ `site.yml` - Configurar el servidor mismo
- ✅ `configure-ubuntu-desktop.yml` - Configurar VM Ubuntu Desktop
- ✅ Cualquier playbook que configure servicios en las VMs

**¿Por qué desde el servidor?**
- El servidor está en la red interna (2025:db8:10::2)
- Puede acceder a las VMs por IPv6 (2025:db8:10::100-200)
- Tiene los servicios de red (DNS, DHCP, NFS)

---

## 📊 Tabla Resumen

| Playbook | Ejecutar desde | Razón |
|----------|----------------|-------|
| `create-vm-ubuntu-desktop.yml` | 🖥️ PC | Conecta a ESXi (168.121.48.254) |
| `create-vm-gamecenter.yml` | 🖥️ PC | Conecta a ESXi (168.121.48.254) |
| `site.yml` | 🖥️ Servidor | Configura el servidor mismo (localhost) |
| `configure-ubuntu-desktop.yml` | 🖥️ Servidor | Configura VMs en red interna (2025:db8:10::X) |
| `site-interactive.yml` | 🖥️ Servidor | Configura el servidor mismo (localhost) |

---

## 🔧 Configuración de Ansible en el PC

Si vas a ejecutar playbooks desde tu PC, necesitas tener Ansible instalado.

### **Opción 1: WSL (Windows Subsystem for Linux)**

```bash
# Instalar WSL
wsl --install

# Dentro de WSL
sudo apt update
sudo apt install ansible python3-pip

# Instalar colecciones de VMware
ansible-galaxy collection install community.vmware
```

### **Opción 2: Git Bash + Python**

```bash
# Instalar Python desde python.org
# Luego en Git Bash:
pip install ansible
pip install pyvmomi

# Instalar colecciones
ansible-galaxy collection install community.vmware
```

### **Opción 3: Usar el servidor como proxy**

Si no quieres instalar Ansible en tu PC, puedes copiar el repositorio al servidor y ejecutar desde ahí, pero necesitas configurar acceso a ESXi.

---

## 🌐 Verificar Conectividad

### **Desde tu PC:**

```bash
# Verificar acceso a ESXi
ping 168.121.48.254

# Verificar puerto de ESXi
curl -k https://168.121.48.254:10111/ui/
# Debe mostrar HTML de vSphere
```

### **Desde el servidor:**

```bash
# Verificar acceso a VMs
ping6 2025:db8:10::100

# Verificar DNS
nslookup server.gamecenter.local

# Verificar servicios
systemctl status named
systemctl status isc-dhcp-server6
```

---

## 🚀 Flujo Completo

```
1. Desde tu PC:
   ansible-playbook create-vm-ubuntu-desktop.yml
   ↓
   Crea VM en ESXi

2. Instalar Ubuntu manualmente en la VM
   ↓
   Usuario: admin / 123456

3. Desde el servidor:
   ansible-playbook configure-ubuntu-desktop.yml
   ↓
   Configura la VM (crea usuarios, monta NFS, etc.)

4. ¡Listo! Inicia sesión en la VM
```

---

## ⚠️ Problemas Comunes

### **Error: "No se pudo conectar a ESXi"**

**Causa:** Estás ejecutando desde el servidor

**Solución:** Ejecuta desde tu PC

```bash
# ❌ Mal (desde el servidor)
ubuntu@server:~/ansible$ ansible-playbook create-vm-ubuntu-desktop.yml
# Error: No puede conectar a 168.121.48.254

# ✅ Bien (desde tu PC)
C:\Users\Diego\...\ansible-gestion-despliegue> ansible-playbook create-vm-ubuntu-desktop.yml
```

---

### **Error: "No se pudo conectar a la VM"**

**Causa:** Estás ejecutando desde tu PC

**Solución:** Ejecuta desde el servidor

```bash
# ❌ Mal (desde tu PC)
C:\Users\Diego\...> ansible-playbook configure-ubuntu-desktop.yml
# Error: No puede conectar a 2025:db8:10::102

# ✅ Bien (desde el servidor)
ubuntu@server:~/ansible$ ansible-playbook configure-ubuntu-desktop.yml
```

---

## 📝 Resumen

**Regla simple:**
- **Crear VMs** → Desde tu PC (acceso a ESXi)
- **Configurar VMs** → Desde el servidor (acceso a red interna)

---

**Última actualización:** 2024
**Versión:** 1.0
