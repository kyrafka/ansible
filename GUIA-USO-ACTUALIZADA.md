# ════════════════════════════════════════════════════════════════
# GUÍA DE USO - Ansible GameCenter (Actualizada)
# ════════════════════════════════════════════════════════════════

## 📋 Índice
1. Configuración inicial
2. Configuración del servidor (paso a paso)
3. Configuración de VMs Ubuntu Desktop
4. Validaciones y diagnóstico
5. Comandos útiles

---

# ────────────────────────────────────────────────────────────────
# 1. CONFIGURACIÓN INICIAL
# ────────────────────────────────────────────────────────────────

## 1.1 Instalar Ansible (sin entorno virtual)

```bash
sudo apt update
sudo apt install -y ansible python3-pip git
pip3 install passlib  # Para encriptar contraseñas
```

## 1.2 Clonar repositorio

```bash
cd ~
git clone <URL_DEL_REPO> ansible
cd ansible
```

---

# ────────────────────────────────────────────────────────────────
# 2. CONFIGURACIÓN DEL SERVIDOR (Orden correcto)
# ────────────────────────────────────────────────────────────────

## ⚠️ ORDEN IMPORTANTE: Firewall ANTES que DNS

El firewall instala `iptables-persistent` que DNS necesita para NAT.

---

## PASO 1: Paquetes base

**¿Qué hace?** Instala herramientas básicas del sistema

```bash
bash scripts/run/run-common.sh
```

**Instala:**
- vim, curl, wget, git (herramientas básicas)
- htop, net-tools (monitoreo)
- python3, pip (para Ansible)

**Validar:**
```bash
bash scripts/run/validate-common.sh
```

---

## PASO 2: Firewall (UFW)

**¿Qué hace?** Configura el firewall y instala iptables-persistent

**⚠️ IMPORTANTE:** Ejecutar ANTES que DNS porque instala dependencias necesarias

```bash
bash scripts/run/run-firewall.sh
bash scripts/run/run-firewall.sh  # Ejecutar DOS VECES si falla
```

**Configura:**
- Puertos abiertos: 22 (SSH), 53 (DNS), 547 (DHCP), 3128 (Proxy)
- Instala `iptables-persistent` (necesario para NAT)
- Instala `fail2ban` (seguridad)

**Validar:**
```bash
bash scripts/run/validate-firewall.sh
sudo ufw status verbose
```

---

## PASO 3: Red (IPv6 + Forwarding)

**¿Qué hace?** Configura las interfaces de red y habilita routing

```bash
bash scripts/run/run-network.sh
```

**Configura:**
- ens33: IPv4 DHCP (internet)
- ens34: IPv6 2025:db8:10::2/64 (red interna)
- IP forwarding (para que el servidor actúe como router)
- NAT66 (traducción IPv6 → IPv6)

**Validar:**
```bash
bash scripts/run/validate-network.sh
ip -6 addr show ens34
sysctl net.ipv6.conf.all.forwarding
```

---

## PASO 4: DNS (BIND9)

**¿Qué hace?** Servidor DNS para resolver nombres internos

```bash
bash scripts/run/run-dns.sh
```

**Configura:**
- Zona: gamecenter.lan
- Servidor: ns1.gamecenter.lan (2025:db8:10::2)
- Genera clave DDNS (para que DHCP actualice DNS automáticamente)
- Forwarders: 8.8.8.8, 8.8.4.4 (para internet)

**Validar:**
```bash
bash scripts/run/validate-dns.sh
dig @localhost gamecenter.lan SOA
dig @localhost servidor.gamecenter.lan AAAA
```

---

## PASO 5: DNS64

**¿Qué hace?** Traduce nombres IPv4 a IPv6 (para NAT64)

```bash
sudo bash scripts/configure-dns64-simple.sh
```

**Configura:**
- Prefijo DNS64: 64:ff9b::/96
- Traduce respuestas DNS IPv4 → IPv6
- Ejemplo: google.com (IPv4) → 64:ff9b::8.8.8.8 (IPv6)

**Validar:**
```bash
dig @localhost google.com AAAA
# Debe mostrar direcciones 64:ff9b::... si el sitio solo tiene IPv4
```

---

## PASO 6: NAT64 (Tayga) ⭐ CRÍTICO

**¿Qué hace?** Traduce paquetes IPv6 → IPv4 (para que VMs accedan a internet)

```bash
sudo bash scripts/nat64/install-nat64-tayga.sh
```

**Configura:**
- Interfaz virtual: nat64
- Prefijo: 64:ff9b::/96
- Pool IPv4: 192.168.255.0/24
- Traduce paquetes IPv6 de las VMs a IPv4 para internet

**Validar:**
```bash
sudo systemctl status tayga
ip addr show nat64
ip -6 route | grep 64:ff9b
ping6 64:ff9b::808:808  # Ping a 8.8.8.8 vía NAT64
```

**Si falla:**
```bash
sudo systemctl stop tayga
sudo ip link delete nat64 2>/dev/null || true
sudo bash scripts/nat64/install-nat64-tayga.sh
```

---

## PASO 7: Proxy (Squid)

**¿Qué hace?** Cachea y optimiza descargas HTTP/HTTPS

```bash
sudo bash scripts/install-squid-proxy.sh
```

**Configura:**
- Puerto: 3128
- Cachea descargas de apt, navegadores
- Optimiza ancho de banda
- Acelera descargas repetidas

**Validar:**
```bash
sudo systemctl status squid
curl -x http://[2025:db8:10::2]:3128 http://google.com
```

---

## PASO 8: DHCP (DHCPv6 + DDNS)

**¿Qué hace?** Asigna IPs automáticamente y registra en DNS

```bash
bash scripts/run/run-dhcp.sh
```

**Configura:**
- Rango: 2025:db8:10::10 - 2025:db8:10::FFFF
- DDNS: Registra VMs automáticamente en DNS
- Envía DNS server: 2025:db8:10::2
- Envía dominio: gamecenter.lan

**Validar:**
```bash
bash scripts/run/validate-dhcp.sh
sudo systemctl status isc-dhcp-server6
sudo journalctl -u isc-dhcp-server6 -n 50
```

---

## PASO 9: Restringir SSH

**¿Qué hace?** Solo permite SSH a usuarios autorizados

```bash
sudo bash scripts/fix-ssh-access.sh
```

**Configura:**
- Usuarios permitidos: ubuntu, administrador
- Usuarios bloqueados: auditor, gamer01, root

**Validar:**
```bash
sudo grep "^AllowUsers" /etc/ssh/sshd_config
```

---

## PASO 10: NFS (Opcional - Juegos compartidos)

**¿Qué hace?** Comparte carpetas en red para juegos

```bash
sudo apt install nfs-kernel-server -y
sudo mkdir -p /srv/nfs/games
sudo chmod 777 /srv/nfs/games
echo '/srv/nfs/games 2025:db8:10::/64(rw,sync,no_subtree_check)' | sudo tee -a /etc/exports
sudo exportfs -ra
sudo systemctl restart nfs-kernel-server
```

**Validar:**
```bash
sudo systemctl status nfs-kernel-server
sudo exportfs -v
```

---

# ────────────────────────────────────────────────────────────────
# 3. CONFIGURACIÓN DE VMs UBUNTU DESKTOP
# ────────────────────────────────────────────────────────────────

## 3.1 Crear VM

```bash
cd ~/ansible
bash scripts/vms/crear-vm.sh
```

**Durante instalación:**
- Usuario: administrador
- Contraseña: 123
- Hostname: ubuntu123
- Red: IPv6 Automatic (DHCP) en M_vm's

---

## 3.2 Configuración inicial (con internet temporal)

**Opción A: Agregar adaptador temporal**
1. Agregar segundo adaptador (VM Network) en vSphere
2. Instalar paquetes:
```bash
sudo apt update
sudo apt install -y git openssh-server
cd ~
git clone <URL_REPO> ansible
cd ansible
sudo bash scripts/vm-setup-complete.sh
```
3. Apagar VM y quitar adaptador temporal

**Opción B: Desde el servidor (con SSH)**
```bash
# Agregar a inventory/hosts.ini:
[ubuntu_desktops]
ubuntu123 ansible_host=2025:db8:10::dce9 ansible_user=administrador ansible_password=123 ansible_become_password=123

# Ejecutar configuración:
bash scripts/vms/configure-ubuntu-desktop-interactive.sh
```

---

## 3.3 Personalización

```bash
# Configuración local (en la VM con sesión gráfica):
cd ~/ansible
bash scripts/vm-local-setup.sh

# ¿Qué hace vm-local-setup.sh?
# - Configura GNOME (tema oscuro, animaciones, etc.)
# - Verifica internet (ping6 google.com)
# - Verifica DNS (dig ubuntu123.gamecenter.lan)
# - Verifica NFS (si está montado /mnt/games)
# - Crea enlaces útiles en el escritorio
# - Muestra comandos útiles
#
# ⚠️ IMPORTANTE: Debe ejecutarse CON sesión gráfica activa
# (no funciona por SSH porque necesita acceso a GNOME)

# Mejorar apariencia:
bash scripts/beautify-ubuntu-desktop.sh

# Aplicar tema global (para todos los usuarios):
sudo bash scripts/apply-global-theme.sh

# Arreglar roles (3 usuarios):
sudo bash scripts/fix-3-roles-only.sh

# Configurar proxy del sistema (Firefox lo usará automáticamente):
gsettings set org.gnome.system.proxy mode 'manual'
gsettings set org.gnome.system.proxy.http host '2025:db8:10::2'
gsettings set org.gnome.system.proxy.http port 3128
gsettings set org.gnome.system.proxy.https host '2025:db8:10::2'
gsettings set org.gnome.system.proxy.https port 3128
gsettings set org.gnome.system.proxy ignore-hosts "['localhost', '127.0.0.0/8', '2025:db8:10::/64']"

# Si Firefox no lo detecta automáticamente, configurar manualmente:
# Firefox → Configuración → Buscar "proxy" → Configuración manual
# HTTP Proxy: 2025:db8:10::2  Puerto: 3128
# ✓ Usar también para HTTPS
# No usar proxy para: localhost, 127.0.0.1, 2025:db8:10::2
```

---

# ────────────────────────────────────────────────────────────────
# 4. VALIDACIONES Y DIAGNÓSTICO
# ────────────────────────────────────────────────────────────────

## 4.1 Validar servidor completo

```bash
bash scripts/run/validate-all.sh
```

## 4.2 Validar componentes individuales

```bash
bash scripts/run/validate-common.sh
bash scripts/run/validate-firewall.sh
bash scripts/run/validate-network.sh
bash scripts/run/validate-dns.sh
bash scripts/run/validate-dhcp.sh
```

## 4.3 Probar desde VM

```bash
ping6 google.com                        # Internet (NAT64)
dig ubuntu123.gamecenter.lan AAAA       # DNS local
ping6 2025:db8:10::2                    # Servidor
ssh ubuntu@2025:db8:10::2               # SSH (solo administrador)
```

---

# ────────────────────────────────────────────────────────────────
# 5. COMANDOS ÚTILES
# ────────────────────────────────────────────────────────────────

## Servicios

```bash
# Ver estado
sudo systemctl status named              # DNS
sudo systemctl status isc-dhcp-server6   # DHCP
sudo systemctl status tayga              # NAT64
sudo systemctl status squid              # Proxy

# Reiniciar
sudo systemctl restart named
sudo systemctl restart isc-dhcp-server6
sudo systemctl restart tayga
sudo systemctl restart squid

# Ver logs
sudo journalctl -fu named
sudo journalctl -fu isc-dhcp-server6
sudo journalctl -fu tayga
```

## Red

```bash
# Ver IPs
ip -6 addr show

# Ver rutas
ip -6 route

# Ver NAT
sudo ip6tables -t nat -L -v -n

# Ver firewall
sudo ufw status verbose
```

## DNS

```bash
# Probar resolución
dig @localhost gamecenter.lan SOA
dig @localhost google.com AAAA
nslookup ubuntu123.gamecenter.lan

# Limpiar y recargar
sudo bash scripts/dns-clean-and-reload.sh
```

---

# ════════════════════════════════════════════════════════════════
# RESUMEN DEL ORDEN CORRECTO
# ════════════════════════════════════════════════════════════════

1. ✅ Paquetes base
2. ✅ **Firewall** (instala iptables-persistent)
3. ✅ Red (IPv6 + forwarding)
4. ✅ DNS (BIND9)
5. ✅ DNS64 (traducción IPv4→IPv6)
6. ✅ **NAT64** (Tayga - CRÍTICO para internet)
7. ✅ Proxy (Squid - optimización)
8. ✅ DHCP (asignación automática)
9. ✅ SSH (restricción de acceso)
10. ✅ NFS (opcional - juegos compartidos)

# ════════════════════════════════════════════════════════════════
