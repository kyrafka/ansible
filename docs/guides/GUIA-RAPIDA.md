# Guía Rápida: Configuración Completa

Pasos simples para configurar todo el sistema.

---

## 🎯 Objetivo

1. Crear VM Ubuntu Desktop en ESXi
2. Configurar servidor Ubuntu con servicios de red
3. Configurar VM Ubuntu Desktop con usuarios

---

## 📝 Paso 1: Crear VM Ubuntu Desktop

**Ejecutar desde tu PC:**

```bash
# En tu PC Windows
cd C:\Users\Diego\Desktop\sdqwqd\ansible-gestion-despliegue
ansible-playbook create-vm-ubuntu-desktop.yml
```

**Resultado:**
- ✅ VM creada: Ubuntu-Desktop-GameCenter
- ✅ 8 GB RAM, 4 CPUs, 40 GB disco
- ✅ Conectada a red M_vm's

**Siguiente paso:**
- Abre vSphere Client
- Instala Ubuntu Desktop manualmente
- Usuario: admin / 123456
- Hostname: ubuntu-desktop-gamecenter

---

## 📝 Paso 2: Configurar Servidor Ubuntu

**Ejecutar desde el servidor:**

```bash
# SSH al servidor
ssh ubuntu@172.17.25.45

# Ir al directorio de Ansible
cd ~/ansible

# Ejecutar script de configuración
chmod +x setup-server.sh
./setup-server.sh
```

**¿Qué hace?**
- Configura red IPv6 (ens33, ens34)
- Instala y configura DNS (BIND9)
- Instala y configura DHCP (ISC DHCPv6)
- Configura firewall (UFW + fail2ban)
- Configura NFS (almacenamiento compartido)

**Tiempo estimado:** 5-10 minutos

**Resultado:**
- ✅ Servidor completamente configurado
- ✅ Servicios de red activos
- ✅ Listo para que las VMs se conecten

---

## 📝 Paso 3: Configurar Red en la VM

**En la VM Ubuntu Desktop:**

```bash
# Editar configuración de red
sudo nano /etc/netplan/01-netcfg.yaml
```

Contenido:
```yaml
network:
  version: 2
  ethernets:
    ens33:
      dhcp6: true
      accept-ra: true
      nameservers:
        addresses:
          - 2025:db8:10::2
        search:
          - gamecenter.local
```

Aplicar:
```bash
sudo netplan apply
```

Verificar:
```bash
ip -6 addr show ens33
# Debe mostrar: 2025:db8:10::XXX/64
```

---

## 📝 Paso 4: Agregar VM al Inventario

**En el servidor:**

```bash
# Editar inventario
vim ~/ansible/inventory/hosts.ini
```

Agregar:
```ini
[ubuntu_desktop]
ubuntu-desktop-gamecenter ansible_host=2025:db8:10::102 ansible_user=admin
```

**Nota:** Reemplaza `::102` con la IP que recibió la VM por DHCP.

---

## 📝 Paso 5: Configurar VM Ubuntu Desktop

**Desde el servidor:**

```bash
cd ~/ansible
ansible-playbook configure-ubuntu-desktop.yml --ask-become-pass
# Contraseña: 123456
```

**¿Qué hace?**
- Crea usuarios: auditor, gamer01
- Configura permisos y grupos
- Monta NFS del servidor
- Configura firewall
- Instala herramientas de gaming

**Tiempo estimado:** 5-10 minutos

**Resultado:**
- ✅ 3 usuarios creados (admin, auditor, gamer01)
- ✅ NFS montado en /mnt/games y /mnt/shared
- ✅ Firewall configurado
- ✅ Listo para usar

---

## ✅ Verificación Final

### **En el servidor:**

```bash
# Ver servicios
systemctl status named                   # DNS
systemctl status isc-dhcp-server6        # DHCP
sudo ufw status                          # Firewall
showmount -e localhost                   # NFS

# Ver red
ip -6 addr show ens34                    # Debe mostrar 2025:db8:10::2/64

# Ver leases DHCP
cat /var/lib/dhcp/dhcpd6.leases
```

### **En la VM:**

```bash
# Ver usuarios
cat /etc/passwd | grep -E "admin|auditor|gamer01"

# Ver red
ip -6 addr show ens33                    # Debe mostrar 2025:db8:10::XXX/64

# Probar conectividad
ping6 2025:db8:10::2                     # Ping al servidor
ping6 google.com                         # Internet (NAT66)

# Probar DNS
nslookup server.gamecenter.local

# Probar NFS
ls /mnt/games
ls /mnt/shared
```

---

## 🎮 Iniciar Sesión en la VM

```
Usuario: admin
Contraseña: 123456
Permisos: Sudo completo, SSH

Usuario: auditor
Contraseña: 123456
Permisos: Solo lectura

Usuario: gamer01
Contraseña: 123456
Permisos: Sin privilegios, solo juegos
```

---

## 🔧 Scripts Útiles

### **En el servidor:**

```bash
# Configurar servidor completo
./setup-server.sh

# Ejecutar rol específico
./run.sh common      # Solo paquetes base
./run.sh network     # Solo red
./run.sh dns         # Solo DNS
./run.sh dhcp        # Solo DHCP
./run.sh firewall    # Solo firewall
./run.sh storage     # Solo NFS
```

---

## 📊 Resumen de IPs

| Dispositivo | IP | Propósito |
|-------------|-----|-----------|
| **Servidor** | 2025:db8:10::2 | Gateway, DNS, DHCP, NFS |
| **VM Ubuntu Desktop** | 2025:db8:10::102 | Desktop con 3 usuarios |
| **Rango DHCP** | ::100 - ::200 | IPs disponibles para VMs |

---

## ❓ Problemas Comunes

### **VM no recibe IP:**
```bash
sudo netplan --debug apply
sudo systemctl restart systemd-networkd
```

### **NFS no monta:**
```bash
showmount -e 2025:db8:10::2
sudo mount -t nfs4 [2025:db8:10::2]:/srv/nfs/games /mnt/games
```

### **Servicio no arranca:**
```bash
# Ver logs
sudo journalctl -u nombre-servicio -n 50

# Reiniciar servicio
sudo systemctl restart nombre-servicio
```

---

## 📚 Documentación Completa

- `CREAR-VMS-UBUNTU.md` - Guía detallada de creación de VMs
- `USUARIOS-Y-CONTRASEÑAS.md` - Documentación de usuarios
- `TOPOLOGIA-RED.md` - Diagrama de red
- `DONDE-EJECUTAR-PLAYBOOKS.md` - Dónde ejecutar cada playbook
- `SCRIPTS-Y-PLAYBOOKS.md` - Documentación de scripts

---

**Última actualización:** 2024
**Versión:** 1.0
