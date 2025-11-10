# 🖥️ Comandos para ejecutar desde WSL (sin SSH al servidor)

Estos comandos interactúan directamente con ESXi/vCenter desde tu WSL, sin necesidad de SSH al servidor Ubuntu.

## 📋 Requisitos previos

### Instalar govc (CLI de VMware)
```bash
# Descargar e instalar govc
curl -L https://github.com/vmware/govmomi/releases/latest/download/govc_Linux_x86_64.tar.gz | tar -xz
sudo mv govc /usr/local/bin/
chmod +x /usr/local/bin/govc

# Verificar instalación
govc version
```

### Instalar Ansible en WSL
```bash
# Opción 1: Instalación rápida del sistema
sudo apt update
sudo apt install ansible python3-pip -y
pip3 install pyvmomi

# Opción 2: Usar el script (instala en venv)
bash scripts/setup/setup-ansible-env.sh --auto
# Luego activa el venv: source ~/.ansible-venv/bin/activate
```

**Nota:** Para WSL se recomienda la instalación del sistema (Opción 1) porque es más simple.

## 🎮 Scripts de gestión de VMs

### 1. Listar todas las VMs
```bash
bash scripts/vms/list-vms.sh
```
**Muestra:**
- Nombre de cada VM
- Estado (encendida/apagada)
- CPU y RAM asignadas
- Dirección IP (si tiene VMware Tools)
- VMs en inventario Ansible

---

### 2. Gestionar VMs (encender/apagar/reiniciar)
```bash
bash scripts/vms/vm-manager.sh
```
**Menú interactivo con opciones:**
1. Listar VMs
2. Encender VM
3. Apagar VM
4. Reiniciar VM
5. Ver estado de VM
6. Salir

---

### 3. Crear VM Ubuntu Desktop con rol
```bash
bash scripts/vms/create-vm-interactive.sh
```
**O directamente con Ansible:**
```bash
ansible-playbook playbooks/create-ubuntu-desktop.yml
```
**Roles disponibles:**
- `admin`: 2 CPU, 4GB RAM, 80GB disco - Acceso total + SSH
- `auditor`: 2 CPU, 3GB RAM, 40GB disco - Solo lectura, sin SSH
- `cliente`: 2 CPU, 4GB RAM, 60GB disco - Solo juegos, sin SSH

---

### 4. Crear VM Windows 11 con rol
```bash
ansible-playbook playbooks/create-windows11.yml
```
**Mismos roles que Ubuntu**

---

### 5. Crear VM del servidor Ubuntu
```bash
bash scripts/vms/create-server.sh
```

**O directamente con Ansible:**
```bash
ansible-playbook playbooks/create_ubpc.yml --tags create_vm
```

**Lo que hace:**
- Crea la VM vacía en ESXi
- Monta ISO de Ubuntu Server
- Enciende la VM

**Lo que NO hace:**
- NO instala Ubuntu (debes hacerlo manualmente)
- NO configura servicios (debes usar `site.yml` desde el servidor después)

**Después de crear la VM:**
1. Instala Ubuntu Server manualmente desde la consola
2. Conéctate al servidor Ubuntu
3. Ejecuta: `bash scripts/server/setup-server.sh`

---

## 🔍 Comandos govc directos

### Ver información de vCenter
```bash
# Configurar variables de entorno
export GOVC_URL="https://tu-vcenter:443"
export GOVC_USERNAME="tu-usuario"
export GOVC_PASSWORD="tu-password"
export GOVC_INSECURE=1

# Ver información de vCenter
govc about

# Listar VMs
govc ls /ha-datacenter/vm

# Ver info de una VM específica
govc vm.info nombre-vm

# Ver IP de una VM
govc vm.ip nombre-vm

# Encender VM
govc vm.power -on nombre-vm

# Apagar VM
govc vm.power -off nombre-vm

# Reiniciar VM
govc vm.power -reset nombre-vm

# Eliminar VM
govc vm.destroy nombre-vm
```

---

## 📊 Comandos de diagnóstico

### Verificar conectividad con vCenter
```bash
# Ping a vCenter
ping tu-vcenter

# Verificar puerto 443
nc -zv tu-vcenter 443

# Probar conexión con govc
govc about
```

### Ver recursos del ESXi
```bash
# Ver datastores
govc datastore.info

# Ver redes
govc ls /ha-datacenter/network

# Ver hosts ESXi
govc ls /ha-datacenter/host
```

---

## 🚀 Flujo completo de creación de VM desde WSL

### Ejemplo: Crear VM Ubuntu para cliente

```bash
# 1. Crear la VM con Ansible (solo crea la VM vacía)
ansible-playbook playbooks/create-ubuntu-desktop.yml \
  -e "vm_name=ubuntu-cliente01" \
  -e "vm_role=cliente"

# 2. Verificar que se creó
bash scripts/vms/list-vms.sh

# 3. INSTALAR UBUNTU MANUALMENTE
# - Conectarte a la consola de la VM en vCenter
# - Instalar Ubuntu Desktop desde la ISO
# - Configurar usuario y contraseña
# - Configurar red IPv6 (automática por DHCP o manual)

# 4. Verificar que tiene IP
govc vm.ip ubuntu-cliente01

# 5. La configuración de roles se hace desde el servidor, no desde WSL
```

---

---

## ⚠️ Diferencia importante

### Desde WSL (estos comandos):
- ✅ **Crean VMs vacías** en ESXi/vCenter
- ✅ **Gestionan VMs** existentes (encender/apagar/listar)
- ❌ **NO instalan** sistemas operativos
- ❌ **NO configuran** servicios en las VMs
- ❌ **NO configuran** el servidor físico Ubuntu

### Desde el servidor Ubuntu (directamente en la máquina):
- ✅ **Configuran el servidor físico** donde ejecutas los scripts
- ✅ Instalan y configuran servicios (DNS, DHCP, Firewall, NFS)
- ✅ Usan `site.yml` o scripts en `scripts/run/`
- Ejemplo: `bash scripts/server/setup-server.sh`

---

## 📝 Notas importantes

1. **Credenciales**: Los scripts leen automáticamente las credenciales de `group_vars/all.vault.yml`

2. **Red**: Las VMs se crean en la red `M_vm's` con IPv6

3. **ISOs**: Asegúrate de que las ISOs estén en el datastore:
   - Ubuntu: `[datastore1] ubuntu-24.04.3-desktop-amd64.iso`
   - Windows: `[datastore1] Win11_24H2_Spanish_Mexico_x64.iso`

4. **⚠️ Instalación manual REQUERIDA**: Los playbooks solo crean VMs vacías. Después debes:
   - **Conectarte a la consola de la VM** en vCenter/ESXi
   - **Instalar el SO manualmente** desde la ISO montada
   - **Configurar red IPv6** (DHCP o manual)
   - **Configurar servicios** desde el propio servidor (no desde WSL)

5. **Sin SSH al servidor**: Todos estos comandos se ejecutan desde WSL y solo interactúan con vCenter/ESXi, no necesitan SSH al servidor Ubuntu.

---

## 🔧 Troubleshooting

### Error: "govc: command not found"
```bash
# Reinstalar govc
curl -L https://github.com/vmware/govmomi/releases/latest/download/govc_Linux_x86_64.tar.gz | tar -xz
sudo mv govc /usr/local/bin/
```

### Error: "Cannot connect to vCenter"
```bash
# Verificar credenciales en group_vars/all.vault.yml
cat group_vars/all.vault.yml | grep vcenter

# Verificar conectividad
ping tu-vcenter
nc -zv tu-vcenter 443
```

### Error: "pyvmomi not found"
```bash
pip3 install pyvmomi
```

### VM creada pero sin IP
```bash
# Verificar que VMware Tools esté instalado en la VM
# Esperar unos minutos después del arranque
govc vm.ip nombre-vm
```
