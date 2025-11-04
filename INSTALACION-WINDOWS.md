# 🪟 Instalación y Configuración desde Windows 11

## 📋 **Escenario:**
Ejecutar el proyecto Ansible desde Windows 11 Home, conectándose a ESXi a través de la red física.

## 🎯 **Opciones disponibles:**

### **OPCIÓN 1: WSL2 (Recomendado) ⭐**
Windows Subsystem for Linux - Ubuntu dentro de Windows

### **OPCIÓN 2: VirtualBox con Ubuntu**
VM Ubuntu completa en VirtualBox

### **OPCIÓN 3: Docker Desktop**
Contenedor con Ansible

### **OPCIÓN 4: Ansible nativo en Windows**
PowerShell + Ansible (limitado)

---

## 🚀 **OPCIÓN 1: WSL2 (Más fácil y rápido)**

### **PASO 1: Instalar WSL2**
```powershell
# Abrir PowerShell como Administrador
wsl --install

# O si ya tienes WSL, instalar Ubuntu
wsl --install -d Ubuntu-24.04
```

### **PASO 2: Configurar Ubuntu en WSL2**
```bash
# Dentro de WSL2 Ubuntu
sudo apt update && sudo apt upgrade -y

# Instalar herramientas necesarias
sudo apt install -y ansible git openssh-client sshpass curl wget python3-pip

# Verificar instalación
ansible --version
```

### **PASO 3: Obtener el proyecto**
```bash
# Clonar desde WSL2
git clone <tu-repositorio> ansible-gestion-despliegue
cd ansible-gestion-despliegue

# Hacer scripts ejecutables
chmod +x scripts/*.sh
```

### **PASO 4: Configurar SSH**
```bash
# Generar clave SSH
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""

# Ver clave pública
cat ~/.ssh/id_ed25519.pub
```

### **PASO 5: Verificar conectividad**
```bash
# Verificar red (WSL2 usa la red de Windows)
./scripts/test-network-connectivity.sh
```

### **PASO 6: Ejecutar proyecto**
```bash
# Configurar vault
./scripts/secure-vault.sh create-password
./scripts/secure-vault.sh decrypt

# Ejecutar creación de VM
./scripts/crear-vm-ubuntu.sh
```

---

## 🖥️ **OPCIÓN 2: VirtualBox con Ubuntu**

### **PASO 1: Instalar VirtualBox**
1. Descargar desde: https://www.virtualbox.org/
2. Instalar normalmente en Windows 11

### **PASO 2: Crear VM Ubuntu**
```powershell
# Desde PowerShell en Windows
cd ansible-gestion-despliegue
.\scripts\setup-virtualbox-controller.ps1
```

### **PASO 3-6: Igual que WSL2**
Seguir pasos 3-6 de la opción WSL2 pero dentro de la VM Ubuntu.

---

## 🐳 **OPCIÓN 3: Docker Desktop**

### **PASO 1: Instalar Docker Desktop**
1. Descargar desde: https://www.docker.com/products/docker-desktop/
2. Instalar y habilitar WSL2 backend

### **PASO 2: Crear contenedor Ansible**
```powershell
# Crear Dockerfile
```

---

## 💻 **OPCIÓN 4: PowerShell nativo (Limitado)**

### **PASO 1: Instalar Python y Ansible**
```powershell
# Instalar Python desde Microsoft Store o python.org
# Instalar Ansible
pip install ansible

# Instalar colecciones VMware
ansible-galaxy collection install community.vmware
```

**⚠️ Limitaciones:**
- Algunos módulos no funcionan bien en Windows
- Scripts bash no funcionan
- Configuración más compleja

---

## 🎯 **Recomendación: WSL2**

### **¿Por qué WSL2?**
✅ **Fácil instalación** - Un comando en PowerShell  
✅ **Rendimiento nativo** - Acceso directo a red de Windows  
✅ **Compatibilidad total** - Todos los scripts funcionan  
✅ **Integración** - Acceso a archivos de Windows  
✅ **Sin overhead** - No es una VM completa  

### **Desventajas de otras opciones:**
❌ **VirtualBox**: Más pesado, configuración de red compleja  
❌ **Docker**: Configuración adicional, menos persistente  
❌ **PowerShell nativo**: Muchas limitaciones  

---

## 🔧 **Configuración específica para Windows:**

### **Acceso a archivos entre Windows y WSL2:**
```bash
# Desde WSL2, acceder a archivos de Windows
cd /mnt/c/Users/Diego/Desktop/

# Desde Windows, acceder a archivos de WSL2
\\wsl$\Ubuntu-24.04\home\usuario\
```

### **Configuración de red en WSL2:**
```bash
# WSL2 usa automáticamente la red de Windows
# No necesita configuración adicional
# Tendrá acceso directo a 172.17.25.11 (ESXi)
```

### **Variables de entorno útiles:**
```bash
# En WSL2
export ANSIBLE_HOST_KEY_CHECKING=False
export ANSIBLE_STDOUT_CALLBACK=yaml
```

---

## 🚀 **Instalación rápida WSL2:**

### **Script automático:**
```powershell
# Ejecutar en PowerShell como Administrador
wsl --install -d Ubuntu-24.04

# Reiniciar Windows si es necesario
# Abrir Ubuntu desde el menú inicio
# Crear usuario y contraseña

# Dentro de Ubuntu WSL2:
sudo apt update && sudo apt install -y ansible git openssh-client
git clone <tu-repo> ansible-gestion-despliegue
cd ansible-gestion-despliegue
chmod +x scripts/*.sh
./scripts/test-network-connectivity.sh
```

---

## 🐛 **Troubleshooting Windows:**

### **WSL2 no instala:**
```powershell
# Habilitar características de Windows
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# Reiniciar y volver a intentar
wsl --install
```

### **Problemas de red:**
```bash
# Verificar IP en WSL2
ip addr show eth0

# Debe tener IP en rango de Windows (192.168.x.x o similar)
# WSL2 hace NAT automáticamente
```

### **Permisos de archivos:**
```bash
# En WSL2, los archivos de Windows pueden tener permisos incorrectos
# Copiar proyecto a home de WSL2
cp -r /mnt/c/Users/Diego/Desktop/ansible-gestion-despliegue ~/
cd ~/ansible-gestion-despliegue
```

---

## 🎉 **Resultado esperado:**

Con WSL2 tendrás:
- ✅ Ubuntu completo dentro de Windows 11
- ✅ Acceso directo a la red física
- ✅ Todos los scripts funcionando
- ✅ Conexión directa a ESXi sin problemas
- ✅ Proyecto ejecutándose perfectamente

**¡WSL2 es la solución perfecta para tu Windows 11!** 🚀