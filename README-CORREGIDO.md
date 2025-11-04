# 🚀 Proyecto IPv6 - Servidor Ubuntu con Servicios Completos

## 📋 ¿Qué hace este proyecto?

Configura automáticamente un servidor Ubuntu con servicios IPv6 completos usando Ansible.

### 🌐 **Configuración de Red**
- **Red IPv6**: `2025:db8:10::/64`
- **Tu servidor Ubuntu**: `2025:db8:10::2` (IP ya asignada)
- **Gateway**: `2025:db8:10::1`
- **DHCP range**: desde `2025:db8:10::10` en adelante
- **Dominio**: `gamecenter.local`

### 🔧 **Servicios que instala**
1. **DNS/BIND9** (puerto 53) - Resuelve nombres del dominio
2. **Apache2** (puerto 80) - Servidor web
3. **DHCPv6** (puerto 547) - Asigna IPs automáticamente
4. **Firewall UFW + fail2ban** - Seguridad
5. **Monitoreo** - Scripts de verificación

## 🚀 **Ejecución**

### **Opción 1: Desde Windows 11 con WSL2 (RECOMENDADO)** ⭐
```powershell
# En PowerShell como Administrador
.\scripts\setup-wsl2.ps1 -Install
# Reiniciar Windows si es necesario
.\scripts\setup-wsl2.ps1 -Configure

# Dentro de WSL2 Ubuntu
wsl -d Ubuntu-24.04
git clone <tu-repo> ansible-gestion-despliegue
cd ansible-gestion-despliegue
./scripts/crear-vm-ubuntu.sh
```
Ver guía completa: [INSTALACION-WINDOWS.md](INSTALACION-WINDOWS.md)

### **Opción 2: Desde VirtualBox**
```bash
# 1. Crear VM controladora en VirtualBox
./scripts/setup-virtualbox-controller.sh

# 2. Dentro de la VM, ejecutar proyecto
./scripts/crear-vm-ubuntu.sh
```
Ver guía completa: [INSTALACION-VIRTUALBOX.md](INSTALACION-VIRTUALBOX.md)

### **Opción 2: Solo configurar servidor actual**
```bash
# Configurar servicios IPv6 en tu servidor Ubuntu actual
./scripts/configurar-servidor.sh
```

### **Opción 2: Crear VM Ubuntu en ESXi + Configurar**
```bash
# Paso 1: Crear VM vacía en ESXi
./scripts/crear-vm-ubuntu.sh

# Paso 2: Instalar Ubuntu manualmente (red IPv6 automática por DHCP)
# Paso 3: Configurar servicios automáticamente
ansible-playbook site.yml --limit nueva_vm_ubpc
```

### **Opción 3: Ansible Directo**
```bash
# Solo servidor actual
ansible-playbook site.yml --limit servidores_ubuntu --connection=local

# Solo crear VM
ansible-playbook site.yml --limit vmware_servers --tags create_vm

# Solo configurar VM existente
ansible-playbook site.yml --limit nueva_vm_ubpc --tags configure_vm
```

## 📁 **Archivos Importantes**

### **Configuración Principal**
- `group_vars/all.yml` - Variables de red IPv6
- `site.yml` - Playbook principal corregido
- `inventory/hosts.ini` - Configuración de hosts

### **Roles Activos**
- `roles/dns_bind/` - Servidor DNS
- `roles/dhcpv6/` - Servidor DHCP IPv6
- `roles/http_web/` - Servidor web
- `roles/firewall/` - Seguridad
- `roles/common/` - Configuración básica

### **Scripts**
- `scripts/configurar-servidor.sh` - Instalación automática
- `scripts/verificar-proyecto.sh` - Verificación de servicios

## 🔍 **Verificación**

### **Servicios que deben estar activos:**
```bash
systemctl status bind9          # DNS
systemctl status apache2        # Web
systemctl status isc-dhcp-server6  # DHCP IPv6
systemctl status fail2ban       # Seguridad
systemctl status ufw           # Firewall
```

### **Puertos abiertos:**
```bash
ss -tuln | grep -E "(53|80|547)"
```

### **Acceso a servicios:**
- **Web**: `http://[2025:db8:10::2]`
- **DNS**: `nslookup gamecenter.local [2025:db8:10::2]`

## 🎯 **Lo que NO hace este proyecto**

❌ **No configura IP estática** - tu servidor ya tiene `2025:db8:10::2`  
❌ **No incluye FTP** - eliminado por innecesario  
❌ **No crea VMs automáticamente** - solo configura el servidor actual  
❌ **No usa redes múltiples** - solo la red principal `2025:db8:10::/64`

## 🐛 **Troubleshooting**

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

3. **Web no accesible:**
   ```bash
   systemctl status apache2
   curl -6 http://[2025:db8:10::2]
   ```

## 📊 **Estructura Simplificada**

```
ansible-gestion-despliegue/
├── group_vars/all.yml          # Variables IPv6 corregidas
├── site.yml                    # Playbook principal corregido
├── inventory/hosts.ini         # Host con IPv6
├── roles/
│   ├── dns_bind/              # DNS/BIND9
│   ├── dhcpv6/               # DHCP IPv6
│   ├── http_web/             # Apache2
│   ├── firewall/             # UFW + fail2ban
│   ├── common/               # Configuración básica
│   └── storage/              # Monitoreo
└── scripts/
    ├── configurar-servidor.sh  # Instalación automática
    └── verificar-proyecto.sh   # Verificación
```

## 🎉 **Resultado Final**

Después de ejecutar el proyecto tendrás:

✅ **Servidor DNS** resolviendo `gamecenter.local`  
✅ **Servidor web** en `http://[2025:db8:10::2]`  
✅ **DHCP IPv6** asignando IPs desde `::10`  
✅ **Firewall** protegiendo el servidor  
✅ **Monitoreo** de todos los servicios  

Todo funcionando en tu red IPv6 `2025:db8:10::/64` 🚀