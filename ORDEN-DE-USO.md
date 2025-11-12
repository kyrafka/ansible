# 📋 Orden de Uso - Scripts y Playbooks

Guía paso a paso para configurar toda la infraestructura desde cero.

---

## 🚀 Configuración Inicial (Una sola vez)

### 1️⃣ Configurar Entorno de Ansible

```bash
# Ejecutar en tu PC o servidor
bash scripts/setup/setup-ansible-env.sh
```

**Qué hace:**
- Instala Python y dependencias
- Crea entorno virtual de Ansible
- Instala colecciones necesarias

### 2️⃣ Activar Entorno Virtual

```bash
# Ansible está disponible globalmente, no necesitas activar nada
ansible --version  # Verificar que esté instalado
```

---

## 🖥️ Configuración del Servidor

### Opción A: Configuración Completa Automática (RECOMENDADO)

```bash
# Configura TODO el servidor de una vez
ansible-playbook -i inventory/hosts.ini playbooks/infrastructure/setup-complete-infrastructure.yml -K
```

**Qué configura:**
- ✅ Red IPv6 (ens34: 2025:db8:10::2/64)
- ✅ DHCP IPv6 (rango 2025:db8:10::100-200)
- ✅ DNS con BIND9 + DNS64
- ✅ Tayga NAT64 (traduce IPv6→IPv4)
- ✅ Squid Proxy (HTTP/HTTPS)
- ✅ radvd (Router Advertisements)
- ✅ Firewall (UFW)

**Tiempo estimado:** 10-15 minutos

---

### Opción B: Configuración Paso a Paso

Si prefieres configurar componente por componente:

#### 1. Configurar Red

```bash
bash scripts/run/run-network.sh
```

**Qué hace:**
- Configura interfaces ens33 (WAN) y ens34 (LAN)
- Instala radvd
- Configura Tayga NAT64
- Instala Squid Proxy
- Configura iptables

#### 2. Configurar DHCP IPv6

```bash
bash scripts/run/run-dhcp.sh
```

**Qué hace:**
- Instala isc-dhcp-server
- Configura rango 2025:db8:10::100-200
- Corrige permisos de AppArmor

#### 3. Configurar DNS + DNS64

```bash
bash scripts/run/run-dns.sh
```

**Qué hace:**
- Instala BIND9
- Configura zona gamecenter.local
- Configura DNS64 (prefijo 64:ff9b::/96)

#### 4. Configurar Servidor Web (Nginx)

```bash
bash scripts/run/run-web.sh
```

**Qué hace:**
- Instala Nginx
- Configura sitio web con página de bienvenida
- Abre puerto 80 en firewall
- Configura dominios: gamecenter.local, www.gamecenter.local

**Validar:**
```bash
bash scripts/run/validate-web.sh
```

#### 5. Configurar Firewall

```bash
bash scripts/run/run-firewall.sh
```

**Qué hace:**
- Instala UFW y fail2ban
- Abre puertos necesarios (SSH, DNS, DHCP, HTTP)
- Protege servicios con fail2ban

---

## 🔍 Verificación del Servidor

Después de configurar el servidor, verifica que todo funciona:

```bash
# Verificar estado de NAT64
sudo bash scripts/diagnostics/check-nat64-status.sh

# Verificar conectividad de red
bash scripts/diagnostics/test-network-connectivity.sh

# Verificar SSH al servidor
bash scripts/diagnostics/test-ssh-ubpc.sh
```

---

## 🖥️ Crear y Configurar VMs

### 1️⃣ Crear VM en ESXi

```bash
ansible-playbook -i inventory/hosts.ini playbooks/vms/create-vm-ubuntu-desktop.yml
```

**Qué hace:**
- Crea VM en ESXi con:
  - 8GB RAM
  - 4 CPUs
  - 40GB disco
  - Conectada a red M_vm's

**Después de esto:**
1. Abre la consola de la VM en ESXi
2. Instala Ubuntu Desktop manualmente
3. Crea usuario: `administrador` / `123456`
4. Hostname: `ubuntu-desktop-gamecenter`

### 2️⃣ Configurar Red en la VM

**Dentro de la VM**, ejecuta:

```bash
sudo nano /etc/netplan/01-netcfg.yaml
```

Contenido:

```yaml
network:
  version: 2
  ethernets:
    ens34:
      dhcp4: no
      dhcp6: yes
      accept-ra: yes
      nameservers:
        addresses:
          - 2025:db8:10::2
        search:
          - gamecenter.local
```

Aplicar:

```bash
sudo netplan apply

# Verificar IP obtenida
ip -6 addr show ens34

# Probar internet
ping6 google.com
```

### 3️⃣ Agregar VM al Inventory

Edita `inventory/hosts.ini` y agrega la VM:

```ini
[ubuntu_desktops]
ubuntu-desktop-gamecenter ansible_host=2025:db8:10:0:20c:29ff:fe35:9751 ansible_user=administrador ansible_password=123456
```

(Reemplaza la IP con la que obtuvo tu VM)

### 4️⃣ Configurar Usuarios en la VM

```bash
ansible-playbook -i inventory/hosts.ini playbooks/vms/configure-ubuntu-desktop.yml
```

**Qué hace:**
- Crea 3 usuarios:
  - `admin`: Administrador con sudo
  - `auditor`: Solo lectura
  - `gamer01`: Usuario gaming
- Todos con contraseña: `123456`
- Todos en grupo `pcgamers`

### 5️⃣ Instalar Software Gaming

```bash
ansible-playbook -i inventory/hosts.ini playbooks/gaming/setup-gaming-desktop.yml
```

**Qué instala:**
- Steam, Lutris, Heroic Games Launcher
- Discord, OBS Studio
- GameMode, MangoHud, ProtonUp-Qt
- Emuladores (RetroArch, PCSX2, Dolphin)

**Optimizaciones:**
- Kernel XanMod gaming
- CPU governor en performance
- Swap optimizado
- Audio de baja latencia

**Personalización:**
- Tema Sweet Dark
- Iconos Papirus
- Wallpapers gaming
- Conky para monitoreo

**Tiempo estimado:** 20-30 minutos

**Después:** Reinicia la VM para aplicar todos los cambios.

---

## 🔧 Scripts de Corrección (Si algo falla)

### Si DHCP no funciona:

```bash
# Corrección rápida
sudo bash scripts/dhcp/fix-dhcp-quick.sh

# O corrección completa
sudo bash scripts/dhcp/fix-dhcp-permissions.sh

# Verificar
sudo bash scripts/dhcp/check-dhcp.sh
```

### Si NAT64 no funciona:

```bash
# Corregir rutas
sudo bash scripts/nat64/fix-nat64-routes.sh

# Verificar estado
sudo bash scripts/diagnostics/check-nat64-status.sh

# Si sigue sin funcionar, reinstalar Tayga
sudo bash scripts/nat64/install-nat64-tayga.sh

# O instalar Squid Proxy como alternativa
sudo bash scripts/nat64/install-squid-proxy.sh
```

### Si HTTP/HTTPS no funciona en la VM:

**En la VM**, configura Squid Proxy:

```bash
echo 'Acquire::http::Proxy "http://[2025:db8:10::2]:3128";' | sudo tee /etc/apt/apt.conf.d/proxy.conf
sudo apt update
```

---

## 📊 Resumen del Flujo Completo

```
1. Setup Inicial
   └─> scripts/setup/setup-ansible-env.sh
   └─> Ansible queda disponible globalmente

2. Configurar Servidor
   └─> playbooks/infrastructure/setup-complete-infrastructure.yml
   └─> Verificar con scripts/diagnostics/check-nat64-status.sh

3. Crear VM
   └─> playbooks/vms/create-vm-ubuntu-desktop.yml
   └─> Instalar Ubuntu Desktop manualmente
   └─> Configurar red en la VM

4. Configurar VM
   └─> Agregar VM a inventory/hosts.ini
   └─> playbooks/vms/configure-ubuntu-desktop.yml

5. Instalar Gaming
   └─> playbooks/gaming/setup-gaming-desktop.yml
   └─> Reiniciar VM

6. ¡Listo para jugar! 🎮
```

---

## 🔄 Mantenimiento y Actualizaciones

### Actualizar Servidor

```bash
# Re-ejecutar configuración completa
ansible-playbook -i inventory/hosts.ini playbooks/infrastructure/setup-complete-infrastructure.yml -K
```

### Actualizar VM

```bash
# Re-ejecutar configuración de gaming
ansible-playbook -i inventory/hosts.ini playbooks/gaming/setup-gaming-desktop.yml
```

### Crear más VMs

```bash
# Crear nueva VM
ansible-playbook -i inventory/hosts.ini playbooks/vms/create-vm-ubuntu-desktop.yml

# Configurar usuarios
ansible-playbook -i inventory/hosts.ini playbooks/vms/configure-ubuntu-desktop.yml

# Instalar gaming
ansible-playbook -i inventory/hosts.ini playbooks/gaming/setup-gaming-desktop.yml
```

---

## 🆘 Comandos de Emergencia

### Reiniciar todos los servicios del servidor:

```bash
sudo systemctl restart isc-dhcp-server6
sudo systemctl restart bind9
sudo systemctl restart radvd
sudo systemctl restart squid
sudo bash scripts/nat64/fix-nat64-routes.sh
```

### Ver logs de servicios:

```bash
# DHCP
sudo journalctl -u isc-dhcp-server6 -n 50

# DNS
sudo journalctl -u bind9 -n 50

# Squid
sudo tail -f /var/log/squid/access.log
```

### Verificar conectividad desde la VM:

```bash
# Ver IP
ip -6 addr show ens34

# Ver rutas
ip -6 route show

# Probar DNS
dig @2025:db8:10::2 google.com AAAA

# Probar internet
ping6 google.com
curl http://google.com
```

---

## 📝 Notas Importantes

1. **Ansible está disponible globalmente**, úsalo directamente:
   ```bash
   ansible --version  # Verificar instalación
   ```

2. **Ejecuta playbooks desde el directorio raíz** del proyecto

3. **Usa `-K` en playbooks** que requieren sudo:
   ```bash
   ansible-playbook ... -K
   ```

4. **Verifica el inventory** antes de ejecutar playbooks en VMs

5. **Reinicia la VM** después de instalar gaming para aplicar kernel y optimizaciones

---

## 🎯 Atajos Útiles

```bash
# Configuración completa desde cero (servidor + VM)
bash scripts/quick-deploy/quick-deploy.sh

# Ver todas las VMs
bash scripts/vms/list-vms.sh

# Gestionar VMs interactivamente
bash scripts/vms/vm-manager.sh

# Crear VM interactivamente
bash scripts/vms/create-vm-interactive.sh
```

---

**¡Disfruta tu infraestructura gaming!** 🎮🚀
