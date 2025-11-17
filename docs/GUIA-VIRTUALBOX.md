# 🖥️ Guía: Usar VirtualBox en PC Local

Guía para replicar el entorno GameCenter en tu PC con VirtualBox (para desarrollo/pruebas).

---

## 📋 Diferencias: KVM vs VirtualBox

| Aspecto | KVM (Servidor ESXi) | VirtualBox (PC Local) |
|---------|---------------------|----------------------|
| **Ubicación** | VM Ubuntu en ESXi | PC Windows/Linux/Mac |
| **Hipervisor** | KVM/QEMU | VirtualBox |
| **Red** | Bridge/Internal | NAT/Internal |
| **Comandos** | `virsh`, `virt-install` | `VBoxManage` |
| **GUI** | `virt-manager` | VirtualBox Manager |
| **Uso** | Producción | Desarrollo/Pruebas |

---

## 🎯 Escenarios de Uso

### Escenario 1: Desarrollo Local Simple

```
PC (Windows/Linux/Mac)
  └── VirtualBox
      ├── VM Ubuntu Desktop (NAT)
      └── VM Windows 11 (NAT)
```

**Ventajas:**
- ✅ Fácil de configurar
- ✅ Internet directo
- ✅ No necesita servidor

**Desventajas:**
- ❌ No replica la red IPv6
- ❌ No prueba NAT64/DNS64

### Escenario 2: Réplica Completa del Servidor

```
PC (Windows/Linux/Mac)
  └── VirtualBox
      ├── VM Ubuntu Server (NAT + Red Interna)
      │   ├── NAT64/DNS64
      │   └── DHCP IPv6
      └── Red Interna "gamecenter"
          ├── VM Ubuntu Desktop (IPv6)
          └── VM Windows 11 (IPv6)
```

**Ventajas:**
- ✅ Réplica exacta del servidor
- ✅ Prueba NAT64/DNS64
- ✅ Prueba configuración completa

**Desventajas:**
- ❌ Más complejo
- ❌ Requiere más recursos

---

## 🚀 Opción 1: Desarrollo Simple (Recomendado para empezar)

### 1. Instalar VirtualBox

Descargar desde: https://www.virtualbox.org/wiki/Downloads

```bash
# Verificar instalación
VBoxManage --version
```

### 2. Crear VM Ubuntu Desktop

```bash
cd ~/ansible

# Crear VM (el script detecta VirtualBox)
bash scripts/virtualbox/crear-vm-ubuntu-vbox.sh

# O con parámetros personalizados
bash scripts/virtualbox/crear-vm-ubuntu-vbox.sh ubuntu-dev 8192 4 81920
```

### 3. Cambiar a NAT (para internet directo)

```bash
# Cambiar red a NAT
VBoxManage modifyvm "ubuntu-desktop-01" --nic1 nat

# Iniciar VM
VBoxManage startvm "ubuntu-desktop-01"
```

### 4. Instalar Ubuntu

1. Instalar Ubuntu Desktop normalmente
2. Usuario: `admin` / Contraseña: `123`
3. Actualizar sistema:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

### 5. Configurar SSH

```bash
# En la VM Ubuntu
sudo apt install openssh-server -y
sudo systemctl enable ssh
sudo systemctl start ssh

# Obtener IP
ip addr show
```

### 6. Conectar desde tu PC

```bash
# Configurar port forwarding en VirtualBox
VBoxManage modifyvm "ubuntu-desktop-01" --natpf1 "ssh,tcp,,2222,,22"

# Conectar desde tu PC
ssh -p 2222 admin@localhost
```

---

## 🏗️ Opción 2: Réplica Completa del Servidor

### 1. Crear VM Ubuntu Server

```bash
# Descargar Ubuntu Server ISO
# https://ubuntu.com/download/server

# Crear VM manualmente en VirtualBox:
# - Nombre: ubuntu-server
# - RAM: 2048 MB
# - Disco: 20 GB
# - Red 1: NAT (para internet)
# - Red 2: Red interna "gamecenter"
```

### 2. Instalar Ubuntu Server

```bash
# Durante instalación:
# - Usuario: ubuntu / 123
# - Instalar OpenSSH Server
# - No instalar nada más
```

### 3. Configurar servidor

```bash
# Conectar por SSH (port forwarding)
VBoxManage modifyvm "ubuntu-server" --natpf1 "ssh,tcp,,2222,,22"
ssh -p 2222 ubuntu@localhost

# Copiar proyecto ansible
scp -P 2222 -r ~/ansible ubuntu@localhost:~/

# En el servidor, ejecutar configuración
cd ~/ansible
sudo bash scripts/install-all-server.sh
```

### 4. Crear VMs clientes

```bash
# En tu PC, crear VMs con red interna
bash scripts/virtualbox/crear-vm-ubuntu-vbox.sh ubuntu-client-01
bash scripts/virtualbox/crear-vm-windows-vbox.sh windows11-01

# Las VMs usarán la red interna "gamecenter"
# El servidor Ubuntu les dará IPv6 y NAT64
```

---

## 📝 Scripts para VirtualBox

### Crear VM Ubuntu Desktop

```bash
# Básico
bash scripts/virtualbox/crear-vm-ubuntu-vbox.sh

# Gaming
bash scripts/virtualbox/crear-vm-ubuntu-vbox.sh ubuntu-gaming 8192 4 81920

# Office
bash scripts/virtualbox/crear-vm-ubuntu-vbox.sh ubuntu-office 2048 2 40960
```

### Crear VM Windows 11

```bash
# Básico
bash scripts/virtualbox/crear-vm-windows-vbox.sh

# Gaming
bash scripts/virtualbox/crear-vm-windows-vbox.sh win11-gaming 8192 4 102400

# Office
bash scripts/virtualbox/crear-vm-windows-vbox.sh win11-office 2048 2 40960
```

### Comandos útiles VirtualBox

```bash
# Listar VMs
VBoxManage list vms

# Ver info de una VM
VBoxManage showvminfo "nombre-vm"

# Iniciar VM (con GUI)
VBoxManage startvm "nombre-vm"

# Iniciar VM (sin GUI)
VBoxManage startvm "nombre-vm" --type headless

# Detener VM
VBoxManage controlvm "nombre-vm" poweroff

# Pausar VM
VBoxManage controlvm "nombre-vm" pause

# Reanudar VM
VBoxManage controlvm "nombre-vm" resume

# Eliminar VM
VBoxManage unregistervm "nombre-vm" --delete

# Cambiar red a NAT
VBoxManage modifyvm "nombre-vm" --nic1 nat

# Cambiar red a Red Interna
VBoxManage modifyvm "nombre-vm" --nic1 intnet --intnet1 "gamecenter"

# Port forwarding (SSH)
VBoxManage modifyvm "nombre-vm" --natpf1 "ssh,tcp,,2222,,22"

# Port forwarding (HTTP)
VBoxManage modifyvm "nombre-vm" --natpf1 "http,tcp,,8080,,80"

# Eliminar port forwarding
VBoxManage modifyvm "nombre-vm" --natpf1 delete "ssh"
```

---

## 🔧 Configuración de Red

### NAT (Internet directo)

```bash
# Configurar VM con NAT
VBoxManage modifyvm "nombre-vm" --nic1 nat

# Port forwarding para SSH
VBoxManage modifyvm "nombre-vm" --natpf1 "ssh,tcp,,2222,,22"

# Conectar
ssh -p 2222 usuario@localhost
```

**Ventajas:**
- Internet directo
- Fácil de configurar

**Desventajas:**
- No replica red IPv6
- Cada VM necesita port forwarding

### Red Interna (Réplica del servidor)

```bash
# Configurar VM con red interna
VBoxManage modifyvm "nombre-vm" --nic1 intnet --intnet1 "gamecenter"
```

**Ventajas:**
- Réplica exacta del servidor
- Prueba NAT64/DNS64

**Desventajas:**
- Necesita VM servidor
- Más complejo

### Bridge (Red local)

```bash
# Configurar VM con bridge
VBoxManage modifyvm "nombre-vm" --nic1 bridged --bridgeadapter1 "eth0"
```

**Ventajas:**
- VM en la misma red que tu PC
- Acceso directo sin port forwarding

**Desventajas:**
- Depende de tu router
- Puede no funcionar en redes corporativas

---

## 🎮 Casos de Uso Prácticos

### Caso 1: Probar scripts de configuración

```bash
# 1. Crear VM con NAT
bash scripts/virtualbox/crear-vm-ubuntu-vbox.sh test-vm
VBoxManage modifyvm "test-vm" --nic1 nat
VBoxManage startvm "test-vm"

# 2. Instalar Ubuntu
# 3. Copiar scripts
scp -P 2222 -r ~/ansible ubuntu@localhost:~/

# 4. Probar scripts
ssh -p 2222 ubuntu@localhost
cd ~/ansible
sudo bash scripts/vm-setup-complete.sh
```

### Caso 2: Probar Ansible

```bash
# 1. Crear VM
bash scripts/virtualbox/crear-vm-ubuntu-vbox.sh ansible-test

# 2. Configurar port forwarding
VBoxManage modifyvm "ansible-test" --natpf1 "ssh,tcp,,2222,,22"

# 3. Agregar al inventario
nano inventory/hosts.ini

[test_vms]
ansible-test ansible_host=localhost ansible_port=2222 ansible_user=ubuntu

# 4. Probar conexión
ansible test_vms -m ping

# 5. Ejecutar playbook
ansible-playbook -i inventory/hosts.ini playbooks/configure-ubuntu-desktop.yml
```

### Caso 3: Desarrollo de playbooks

```bash
# 1. Crear snapshot antes de probar
VBoxManage snapshot "test-vm" take "antes-de-cambios"

# 2. Probar cambios
ansible-playbook -i inventory/hosts.ini playbooks/mi-playbook.yml

# 3. Si algo sale mal, restaurar
VBoxManage snapshot "test-vm" restore "antes-de-cambios"
VBoxManage startvm "test-vm"
```

---

## 📊 Comparación de Recursos

### Configuraciones recomendadas

| Escenario | VMs | RAM Total | Disco Total |
|-----------|-----|-----------|-------------|
| **Mínimo** | 1 Ubuntu | 2GB | 20GB |
| **Desarrollo** | 1 Ubuntu + 1 Windows | 6GB | 80GB |
| **Completo** | 1 Server + 2 Clientes | 8GB | 120GB |
| **Gaming** | 1 Server + 2 Gaming | 16GB | 250GB |

---

## 🆘 Troubleshooting

### ❌ VBoxManage no encontrado

**Windows:**
```cmd
# Agregar a PATH
set PATH=%PATH%;C:\Program Files\Oracle\VirtualBox
```

**Linux:**
```bash
# Instalar VirtualBox
sudo apt install virtualbox
```

### ❌ Error de virtualización

```bash
# Verificar que VT-x/AMD-V está habilitado en BIOS
# Verificar que Hyper-V está deshabilitado (Windows)

# Windows: Deshabilitar Hyper-V
bcdedit /set hypervisorlaunchtype off
```

### ❌ VM muy lenta

```bash
# Aumentar RAM
VBoxManage modifyvm "nombre-vm" --memory 4096

# Aumentar CPUs
VBoxManage modifyvm "nombre-vm" --cpus 4

# Habilitar aceleración 3D
VBoxManage modifyvm "nombre-vm" --accelerate3d on
```

---

## 📚 Referencias

- [VirtualBox Manual](https://www.virtualbox.org/manual/)
- [VBoxManage Reference](https://www.virtualbox.org/manual/ch08.html)
- [Guía servidor](1-GUIA-SERVIDOR.md)
- [Guía Ubuntu Desktop](2-GUIA-VM-UBUNTU.md)
- [Guía Windows 11](GUIA-VM-WINDOWS11.md)

