# 🖥️ Instalación y Configuración desde VirtualBox

## 📋 **Escenario:**
Ejecutar el proyecto Ansible desde una VM Ubuntu en VirtualBox local, conectándose a ESXi a través de la red física.

## 🌐 **Arquitectura de red:**
```
Internet
    ↓
Router físico (172.17.25.1)
    ↓
Switch físico
    ├── ESXi (172.17.25.11)
    │   └── Servidor Ubuntu (2025:db8:10::2) ← Firewall bloquea SSH externo
    └── Tu PC física
        └── VirtualBox (modo bridged)
            └── VM Ubuntu (172.17.25.x) ← Controlador Ansible
```

## 🚀 **Instalación paso a paso:**

### **PASO 1: Crear VM en VirtualBox**
```bash
# Desde tu PC física (Windows)
cd ansible-gestion-despliegue
./scripts/setup-virtualbox-controller.sh
```

**¿Qué hace?**
- Crea VM "ansible-controller" en VirtualBox
- Configura red en modo bridged
- Monta ISO de Ubuntu 24.04
- Inicia la VM para instalación

### **PASO 2: Instalar Ubuntu en la VM**
**En la VM que se abrió:**
1. Instalar Ubuntu 24.04 normalmente
2. Crear usuario (ej: `ansible`)
3. Configurar red automática (DHCP)
4. Reiniciar

### **PASO 3: Configurar herramientas**
**Dentro de la VM Ubuntu:**
```bash
# Actualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar herramientas necesarias
sudo apt install -y ansible git openssh-client sshpass curl wget

# Verificar instalación
ansible --version
```

### **PASO 4: Obtener el proyecto**
```bash
# Clonar repositorio
git clone <tu-repositorio> ansible-gestion-despliegue
cd ansible-gestion-despliegue

# Hacer scripts ejecutables
chmod +x scripts/*.sh
```

### **PASO 5: Configurar SSH**
```bash
# Generar clave SSH
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""

# Ver clave pública (para copiar si es necesario)
cat ~/.ssh/id_ed25519.pub
```

### **PASO 6: Verificar conectividad**
```bash
# Verificar red y conectividad
./scripts/test-network-connectivity.sh
```

**Deberías ver:**
- ✅ Tu IP en rango 172.17.25.x
- ✅ ESXi (172.17.25.11) accesible
- ⚠️ Servidor Ubuntu puede no ser accesible (normal por firewall)

### **PASO 7: Configurar credenciales**
```bash
# Configurar vault
./scripts/secure-vault.sh create-password
./scripts/secure-vault.sh decrypt

# Editar credenciales si es necesario
nano group_vars/all.vault.yml

# Cifrar de nuevo
./scripts/secure-vault.sh encrypt
```

### **PASO 8: Ejecutar proyecto**
```bash
# Opción 1: Solo configurar servidor existente (si es accesible)
./scripts/configurar-servidor.sh

# Opción 2: Crear nueva VM Ubuntu en ESXi
./scripts/crear-vm-ubuntu.sh
```

## 🔧 **Configuración de red específica:**

### **Si IPv6 no funciona desde VirtualBox:**
Editar `inventory/hosts.ini`:
```ini
[servidores_ubuntu]
# Usar IPv4 en lugar de IPv6
labjuegos ansible_host=172.17.25.125 ansible_user=salamaleca
```

### **Si necesitas configurar IP estática en la VM:**
```bash
# En la VM Ubuntu
sudo nano /etc/netplan/01-network-manager-all.yaml
```

```yaml
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: false
      addresses:
        - 172.17.25.100/24
      gateway4: 172.17.25.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
```

```bash
sudo netplan apply
```

## 🐛 **Troubleshooting:**

### **Problema: No puedo acceder a ESXi**
```bash
# Verificar IP de la VM
ip addr show

# Debe estar en rango 172.17.25.x
# Si no, verificar configuración de VirtualBox (modo bridged)
```

### **Problema: SSH a servidor Ubuntu falla**
```bash
# Normal por firewall, pero puedes probar:
ssh -o ConnectTimeout=5 salamaleca@2025:db8:10::2

# Si falla, usar la nueva VM que crearás
```

### **Problema: Ansible no encuentra hosts**
```bash
# Verificar inventario
ansible-inventory -i inventory/hosts.ini --list

# Test de conectividad
ansible all -i inventory/hosts.ini -m ping --vault-password-file .vault_pass
```

## 🎯 **Ventajas de este método:**

✅ **Acceso completo** a la red física desde VirtualBox  
✅ **Sin problemas de firewall** (estás en la red interna)  
✅ **Aislamiento** del proyecto en VM dedicada  
✅ **Fácil backup** de la VM completa  
✅ **Portabilidad** - puedes mover la VM  

## 📊 **Resultado esperado:**

Después de seguir estos pasos tendrás:
- VM Ubuntu funcionando como controlador Ansible
- Acceso completo a ESXi para crear VMs
- Capacidad de ejecutar todo el proyecto sin restricciones de firewall
- Nueva VM UBPC creada y configurada automáticamente

¡Tu proyecto funcionará perfectamente desde VirtualBox! 🚀