# 🚀 Flujo Completo: Creación VM UBPC con Servicios IPv6

## 📋 Resumen del Proceso

Este proyecto automatiza completamente la creación de una nueva VM Ubuntu llamada "UBPC" desde un servidor Ubuntu existente, configurándola con todos los servicios IPv6 necesarios.

### 🏗️ Arquitectura del Despliegue

```
Servidor Ubuntu Existente (192.168.100.125)
           ↓ (ejecuta Ansible)
    ESXi Server (172.17.25.11)
           ↓ (crea VM)
    Nueva VM "UBPC" (192.168.100.126)
           ↓ (se configura automáticamente)
    Servicios IPv6 Completos
```

## 🎯 Lo que hace el proyecto

### **Desde el servidor Ubuntu (192.168.100.125):**
1. Se conecta a ESXi (172.17.25.11) vía SSH
2. Crea una nueva VM llamada "UBPC" 
3. Instala Ubuntu 24.04 en la VM
4. Configura automáticamente todos los servicios

### **En la nueva VM UBPC:**
- **DNS/BIND9**: Servidor DNS con soporte IPv6 (puerto 53)
- **Apache2**: Servidor web con página del proyecto (puerto 80)
- **vsftpd**: Servidor FTP con acceso anónimo (puerto 21)
- **DHCPv6**: Servidor DHCP para IPv6 (puerto 547)
- **Firewall**: UFW + fail2ban con reglas personalizadas
- **Monitoreo**: Scripts de verificación y reportes

## 🚀 Ejecución Rápida

### **Opción 1: Script Automático Completo**
```bash
# Desde el servidor Ubuntu (192.168.100.125)
cd ansible-gestion-despliegue
./scripts/crear-ubpc-completo.sh
```

### **Opción 2: Paso a Paso**
```bash
# 1. Configurar credenciales
echo "tu_password_vault" > .vault_pass
chmod 600 .vault_pass

# 2. Crear y configurar VM UBPC
ansible-playbook -i inventory/hosts.ini playbooks/create_ubpc.yml --vault-password-file .vault_pass

# 3. Verificar servicios
./scripts/verificar-proyecto.sh
```

## 📁 Archivos Clave Corregidos

### **1. Inventario Corregido (`inventory/hosts.ini`)**
```ini
[servidores_ubuntu]
labjuegos ansible_host=192.168.100.125 ansible_user=salamaleca

[vmware_servers] 
vcenter1 ansible_host=172.17.25.11 ansible_user=root

[nueva_vm_ubpc]
# Se popula dinámicamente después de crear la VM
```

### **2. Playbook Principal (`site.yml`)**
- ✅ Corregidos nombres de grupos de hosts
- ✅ Agregado flujo para nueva VM UBPC
- ✅ Configuración IPv6 específica

### **3. Configuración VMware (`group_vars/ubpc.yml`)**
- ✅ Puerto corregido (443 en lugar de 10111)
- ✅ Configuración completa de la VM
- ✅ Parámetros de red IPv6

### **4. Nuevo Playbook Específico (`playbooks/create_ubpc.yml`)**
- 🆕 Orquesta todo el proceso
- 🆕 Crea VM en ESXi
- 🆕 Configura servicios automáticamente
- 🆕 Verifica instalación

## 🔧 Configuración de Red

### **Red IPv6 Configurada:**
- **Red principal**: `2001:db8:1::/64`
- **Servidor Ubuntu**: `2001:db8:1::10` (existente)
- **Nueva VM UBPC**: `2001:db8:1::20`
- **Gateway**: `2001:db8:1::1`
- **DNS**: Google DNS IPv6 + DNS local
- **Dominio**: `gamecenter.local`

## 🔐 Seguridad y Credenciales

### **Configurar Vault (IMPORTANTE):**
```bash
# 1. Crear archivo de credenciales
ansible-vault create group_vars/all.vault.yml

# 2. Agregar credenciales:
vault_vcenter_username: "root"
vault_vcenter_password: "tu_password_esxi"
vault_win_admin_password: "password_windows"

# 3. Crear archivo de password
echo "tu_vault_password" > .vault_pass
chmod 600 .vault_pass
```

## 📊 Verificación Post-Instalación

### **Servicios que deben estar activos:**
```bash
# En la nueva VM UBPC (ssh ubuntu@192.168.100.126)
systemctl status bind9        # DNS
systemctl status apache2      # Web
systemctl status vsftpd       # FTP
systemctl status isc-dhcp-server6  # DHCPv6
systemctl status fail2ban     # Seguridad
systemctl status ufw          # Firewall
```

### **Puertos que deben estar abiertos:**
```bash
ss -tuln | grep -E "(53|80|21|547|22)"
```

### **Acceso a servicios:**
- **Web**: `http://192.168.100.126` o `http://[2001:db8:1::20]`
- **FTP**: `ftp://192.168.100.126`
- **SSH**: `ssh ubuntu@192.168.100.126`
- **DNS**: `nslookup gamecenter.local 192.168.100.126`

## 🐛 Troubleshooting

### **Problemas Comunes:**

1. **No se puede conectar a ESXi:**
   ```bash
   # Verificar conectividad
   ping 172.17.25.11
   ssh root@172.17.25.11
   ```

2. **VM no arranca:**
   ```bash
   # Verificar en ESXi
   vim-cmd vmsvc/getallvms
   vim-cmd vmsvc/power.getstate <vmid>
   ```

3. **Servicios no arrancan:**
   ```bash
   # En la VM UBPC
   journalctl -u bind9 -f
   systemctl restart apache2
   ```

4. **Problemas de red IPv6:**
   ```bash
   # Verificar configuración
   ip -6 addr show
   ip -6 route
   ```

## 📈 Monitoreo Continuo

### **Scripts de Monitoreo:**
```bash
# Verificación completa
./scripts/verificar-proyecto.sh

# Monitoreo de firewall
ssh ubuntu@192.168.100.126 'fw-monitor'

# Estado de servicios
ssh ubuntu@192.168.100.126 'systemctl status bind9 apache2 vsftpd'
```

## 🎯 Próximos Pasos

Después de la instalación exitosa:

1. **Personalizar servicios** según necesidades específicas
2. **Configurar backups** automáticos
3. **Implementar monitoreo** avanzado
4. **Documentar procedimientos** específicos del entorno

---

## 📞 Soporte

Si encuentras problemas:

1. Revisa los logs: `journalctl -xe`
2. Verifica conectividad de red
3. Confirma credenciales del vault
4. Ejecuta verificaciones: `./scripts/verificar-proyecto.sh`