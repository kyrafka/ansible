# 🚀 Proyecto Ansible - Gestión y Despliegue IPv6

## 📋 **¿Qué hace este proyecto?**

Automatiza completamente la creación y configuración de servidores Ubuntu con servicios IPv6 profesionales, desde cero hasta producción.

### **🎯 Dos flujos de trabajo:**

#### **FLUJO 1: Configurar servidor actual**
- Toma tu servidor Ubuntu actual (`2025:db8:10::2`)
- Lo convierte en un servidor de red IPv6 completo
- Instala y configura todos los servicios automáticamente

#### **FLUJO 2: Crear nueva VM Ubuntu + Configurar**
- Se conecta a tu ESXi (172.17.25.11)
- Crea una VM Ubuntu completamente nueva
- La configura automáticamente con los mismos servicios

---

## 🌐 **Configuración de Red IPv6**

```
Red: 2025:db8:10::/64
├── Gateway: 2025:db8:10::1
├── Tu servidor: 2025:db8:10::2 (DHCPv6 server)
└── Nuevas VMs: 2025:db8:10::10+ (clientes DHCP)
```

---

## 🔧 **Servicios que instala automáticamente:**

### **1. DNS/BIND9** (puerto 53)
- Resuelve nombres del dominio `gamecenter.local`
- Forwarders a Google DNS
- Configuración IPv6 completa

### **2. DHCPv6 Server** (puerto 547)
- Asigna IPs automáticamente desde `2025:db8:10::10`
- Configuración de DNS automática
- Gestión de leases

### **3. Firewall UFW + fail2ban**
- Protección contra ataques de fuerza bruta
- Rate limiting en SSH
- Reglas específicas para servicios IPv6
- Monitoreo en tiempo real

### **4. Sistema de monitoreo**
- Scripts de verificación de servicios
- Reportes de almacenamiento
- Alertas de uso de disco
- Logs centralizados

---

## 🚀 **Instalación y Ejecución**

### **Opción 1: Desde Windows 11 con WSL2 (RECOMENDADO)** ⭐

#### **Instalación automática:**
```powershell
# En PowerShell como Administrador
.\scripts\setup-wsl2.ps1 -Install
# Reiniciar Windows si es necesario
.\scripts\setup-wsl2.ps1 -Configure
```

#### **Ejecutar proyecto:**
```bash
# Dentro de WSL2 Ubuntu
wsl -d Ubuntu-24.04
git clone <tu-repo> ansible-gestion-despliegue
cd ansible-gestion-despliegue
./scripts/crear-vm-ubuntu.sh
```

#### **¿Por qué WSL2?**
✅ **Fácil instalación** - Un comando en PowerShell  
✅ **Acceso directo** a tu red física (172.17.25.x)  
✅ **Sin VMs pesadas** - Ubuntu integrado en Windows  
✅ **Todos los scripts funcionan** - Compatibilidad total  

### **Opción 2: Desde VirtualBox**
```bash
# 1. Crear VM controladora en VirtualBox
./scripts/setup-virtualbox-controller.sh

# 2. Dentro de la VM, ejecutar proyecto
./scripts/crear-vm-ubuntu.sh
```

### **Opción 3: Solo configurar servidor actual**
```bash
# Configurar servicios IPv6 en tu servidor Ubuntu actual
./scripts/configurar-servidor.sh
```

### **Opción 4: Ansible directo**
```bash
# Solo servidor actual
ansible-playbook site.yml --limit servidores_ubuntu --connection=local

# Solo crear VM
ansible-playbook site.yml --limit vmware_servers --tags create_vm

# Solo configurar VM existente
ansible-playbook site.yml --limit nueva_vm_ubpc --tags configure_vm
```

---

## 💾 **Gestión profesional de particiones LVM:**

### **Esquema automático para VMs:**
```
Disco 20GB
├── /boot/efi (512MB) - EFI
├── /boot (1GB) - Kernel
└── LVM vg0 (18GB)
    ├── / (8GB) - Sistema
    ├── /var (4GB) - Datos
    ├── /var/log (2GB) - Logs
    ├── /tmp (1GB) - Temporal (seguro)
    └── /home (3GB) - Usuarios
```

### **Ventajas:**
- **Seguridad**: `/tmp` con `noexec,nosuid`
- **Estabilidad**: Logs separados
- **Flexibilidad**: LVM redimensionable
- **Monitoreo**: Cada partición supervisada

---

## 🔐 **Seguridad implementada:**

### **Básica (incluida):**
- **SSH** con claves + contraseña de respaldo
- **Firewall UFW** con reglas específicas
- **fail2ban** contra ataques de fuerza bruta
- **Particiones seguras** (`/tmp` con `noexec`)
- **Usuarios** con sudo configurado
- **Logs separados** para auditoría

### **Avanzada (opcional):**
- **Lynis** - Auditoría de seguridad del sistema
- **RKHunter** - Detector de rootkits y malware
- **AIDE** - Monitoreo de integridad de archivos
- **ClamAV** - Antivirus en tiempo real
- **PSAD** - Detector de escaneos de puertos
- **Logwatch** - Análisis automático de logs

---

## 🛠️ **Scripts de gestión:**

### **Instalación y configuración:**
- `setup-wsl2.ps1` - Configurar WSL2 en Windows
- `setup-virtualbox-controller.sh` - VM en VirtualBox
- `crear-vm-ubuntu.sh` - VM completa automática
- `configurar-servidor.sh` - Solo servidor actual

### **Verificación y monitoreo:**
- `verificar-proyecto.sh` - Estado de servicios
- `verificar-particiones.sh` - Info de almacenamiento
- `test-ssh-ubpc.sh` - Conectividad SSH
- `test-network-connectivity.sh` - Conectividad de red

### **Seguridad:**
- `secure-vault.sh` - Gestión del vault cifrado
- `security-hardening.sh` - Hardening completo
- `test-windows-connectivity.ps1` - Test desde Windows

---

## 📁 **Estructura del proyecto:**

```
ansible-gestion-despliegue/
├── group_vars/
│   ├── all.yml              # Variables globales
│   ├── all.vault.yml        # Credenciales cifradas
│   ├── ubpc.yml            # Configuración VM
│   └── virtualbox.yml      # Configuración VirtualBox
├── inventory/
│   └── hosts.ini           # Inventario de hosts
├── roles/
│   ├── common/             # Configuración básica
│   ├── dns_bind/           # DNS/BIND9
│   ├── dhcpv6/            # DHCP IPv6
│   ├── firewall/          # UFW + fail2ban
│   ├── vmware/            # Gestión de VMs
│   ├── procesos/          # Gestión de servicios
│   ├── storage/           # Monitoreo de almacenamiento
│   └── security_advanced/ # Seguridad avanzada (opcional)
├── scripts/
│   ├── Windows (PowerShell)
│   └── Linux (Bash)
├── playbooks/
│   └── create_ubpc.yml    # Creación completa de VM
└── site.yml              # Playbook principal
```

---

## 🔧 **Configuración inicial:**

### **1. Configurar credenciales del vault:**
```bash
# Crear contraseña segura
./scripts/secure-vault.sh create-password

# Editar credenciales
./scripts/secure-vault.sh edit

# Cifrar vault
./scripts/secure-vault.sh encrypt
```

### **2. Verificar conectividad:**
```bash
# Desde Linux/WSL2
./scripts/test-network-connectivity.sh

# Desde Windows
.\scripts\test-windows-connectivity.ps1
```

### **3. Ejecutar proyecto:**
```bash
# Opción completa (crear VM + configurar)
./scripts/crear-vm-ubuntu.sh

# Solo configurar servidor actual
./scripts/configurar-servidor.sh
```

---

## 📊 **Verificación post-instalación:**

### **Servicios que deben estar activos:**
```bash
systemctl status bind9          # DNS
systemctl status isc-dhcp-server6  # DHCP IPv6
systemctl status fail2ban       # Seguridad
systemctl status ufw           # Firewall
```

### **Puertos abiertos:**
```bash
ss -tuln | grep -E "(22|53|547)"
```

### **Acceso a servicios:**
- **SSH**: `ssh ubuntu@[IP_asignada]`
- **DNS**: `nslookup gamecenter.local [IP_asignada]`

---

## 🐛 **Troubleshooting:**

### **Problemas comunes:**

1. **DNS no resuelve:**
   ```bash
   named-checkconf
   systemctl restart bind9
   ```

2. **DHCP no asigna IPs:**
   ```bash
   systemctl status isc-dhcp-server6
   journalctl -u isc-dhcp-server6
   ```

3. **Problemas de red IPv6:**
   ```bash
   ip -6 addr show
   ip -6 route
   ```

### **WSL2 no instala (Windows):**
```powershell
# Habilitar características de Windows
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# Reiniciar y volver a intentar
wsl --install
```

---

## 🎯 **Casos de uso:**

### **Caso 1: Servidor único**
- Configuras tu Ubuntu actual como servidor de red
- Ideal para entornos pequeños
- Un solo punto de administración

### **Caso 2: Infraestructura redundante**
- Servidor principal + VM secundaria
- Alta disponibilidad de servicios
- Balanceo de carga posible
- Separación de servicios

### **Caso 3: Laboratorio de pruebas**
- Creas VMs rápidamente para testing
- Configuración consistente
- Fácil destrucción y recreación

---

## 🌐 **Arquitectura de red:**

### **Desde Windows 11:**
```
Windows 11 (tu IP física: 172.17.25.x)
    ↓ (NAT automático)
WSL2 Ubuntu (IP interna, acceso a red física)
    ↓ (acceso directo)
ESXi (172.17.25.11) ← ¡Sin problemas de firewall!
    ↓ (crea VM)
Nueva VM Ubuntu (2025:db8:10::10+)
```

### **Desde VirtualBox:**
```
Tu PC → VirtualBox (bridged) → Red física → ESXi → Nueva VM Ubuntu
```

---

## 🎉 **Resultado final:**

Después de ejecutar el proyecto tendrás:

✅ **Servidor DNS** resolviendo `gamecenter.local`  
✅ **DHCP IPv6** asignando IPs desde `::10`  
✅ **Firewall** protegiendo el servidor  
✅ **Monitoreo** de todos los servicios  
✅ **Particiones LVM** profesionales  
✅ **Seguridad** de nivel empresarial  

Todo funcionando en tu red IPv6 `2025:db8:10::/64` 🚀

---

## 💡 **Comandos útiles:**

### **Gestión de servicios:**
```bash
systemctl status bind9 isc-dhcp-server6 fail2ban ufw
```

### **Logs:**
```bash
journalctl -u bind9 -f        # DNS en tiempo real
journalctl -u isc-dhcp-server6 -f  # DHCP en tiempo real
tail -f /var/log/fail2ban.log # Fail2ban
```

### **Red:**
```bash
ip -6 addr show              # Interfaces IPv6
ip -6 route                  # Rutas IPv6
ss -tuln                     # Puertos abiertos
```

### **Seguridad:**
```bash
ufw status verbose           # Estado del firewall
fail2ban-client status       # Estado de jails
./scripts/security-hardening.sh  # Hardening completo
```

---

**¡Tu proyecto es una fábrica automatizada de servidores IPv6 que nunca duerme!** 🤖✨