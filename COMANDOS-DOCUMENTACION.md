# 📸 COMANDOS PARA DOCUMENTAR CON CAPTURAS

## 🎯 INFORMACIÓN GENERAL DEL SISTEMA

```bash
# Información del sistema
uname -a
lsb_release -a
hostnamectl

# Versión de Ansible
ansible --version

# Colecciones instaladas
ansible-galaxy collection list

# Estructura del proyecto
tree -L 2 -d .
# O si no tienes tree:
ls -la
ls -la roles/
ls -la scripts/
```

---

## 1️⃣ COMMON (Paquetes Base)

```bash
# Ver paquetes instalados por common
dpkg -l | grep -E "python3|git|curl|wget|vim|net-tools|dnsutils"

# Versiones de herramientas
python3 --version
git --version
curl --version

# Usuarios del sistema
cat /etc/passwd | grep -E "ubuntu|administrador|gamer|auditor"

# Grupos
cat /etc/group | grep -E "sudo|admin"

# Configuración de timezone
timedatectl

# Hostname
hostname
cat /etc/hostname
```

---

## 2️⃣ NETWORK (Red IPv6)

```bash
# Interfaces de red
ip addr show
ip -6 addr show

# Interfaces específicas
ip -6 addr show ens33
ip -6 addr show ens34

# Rutas IPv6
ip -6 route

# Forwarding habilitado
cat /proc/sys/net/ipv6/conf/all/forwarding
cat /proc/sys/net/ipv4/ip_forward

# Configuración de netplan
cat /etc/netplan/*.yaml

# Tabla de vecinos IPv6
ip -6 neigh show

# Estadísticas de red
ss -s
ss -tulpn | grep -E ":53|:547|:80"
```

---

## 3️⃣ DNS (BIND9)

```bash
# Estado del servicio
sudo systemctl status bind9

# Verificar configuración
sudo named-checkconf

# Ver configuración principal
sudo cat /etc/bind/named.conf
sudo cat /etc/bind/named.conf.options
sudo cat /etc/bind/named.conf.local

# Ver zonas DNS
sudo cat /etc/bind/zones/db.gamecenter.lan
sudo cat /var/lib/bind/db.gamecenter.lan

# Zona inversa
sudo cat /var/lib/bind/db.0.1.0.8.b.d.5.2.0.2.ip6.arpa

# Probar resolución DNS
dig @localhost gamecenter.lan AAAA
dig @localhost google.com AAAA
nslookup gamecenter.lan localhost

# Ver logs de BIND
sudo journalctl -u bind9 -n 50 --no-pager

# Estadísticas de BIND
sudo rndc status

# Puerto DNS
sudo ss -tulpn | grep :53

# Permisos de archivos
ls -la /var/lib/bind/
ls -la /etc/bind/zones/
```

---

## 4️⃣ DHCP IPv6

```bash
# Estado del servicio
sudo systemctl status isc-dhcp-server6

# Configuración
sudo cat /etc/dhcp/dhcpd6.conf

# Interfaz configurada
sudo cat /etc/default/isc-dhcp-server

# Leases activos
sudo cat /var/lib/dhcp/dhcpd6.leases

# Ver clientes conectados
sudo grep "^lease6" /var/lib/dhcp/dhcpd6.leases

# Logs de DHCP
sudo journalctl -u isc-dhcp-server6 -n 50 --no-pager

# Puerto DHCP
sudo ss -ulpn | grep :547
```

---

## 5️⃣ RADVD (Router Advertisement)

```bash
# Estado del servicio
sudo systemctl status radvd

# Configuración
sudo cat /etc/radvd.conf

# Logs
sudo journalctl -u radvd -n 30 --no-pager

# Verificar anuncios
sudo tcpdump -i ens34 -n icmp6 -c 5
```

---

## 6️⃣ NAT64 (TAYGA)

```bash
# Estado del servicio
sudo systemctl status tayga

# Configuración
sudo cat /etc/tayga.conf

# Interfaz nat64
ip link show nat64
ip addr show nat64

# Rutas NAT64
ip -6 route | grep 64:ff9b
ip -4 route | grep 192.168.255

# Reglas de iptables
sudo iptables -t nat -L POSTROUTING -n -v

# Probar NAT64
ping6 -c 4 64:ff9b::8.8.8.8
ping6 -c 4 64:ff9b::1.1.1.1

# Logs de Tayga
sudo journalctl -u tayga -n 30 --no-pager

# Estadísticas
sudo cat /proc/net/dev | grep nat64
```

---

## 7️⃣ FIREWALL (UFW)

```bash
# Estado del firewall
sudo ufw status verbose
sudo ufw status numbered

# Reglas de iptables
sudo iptables -L -n -v
sudo ip6tables -L -n -v

# Reglas NAT
sudo iptables -t nat -L -n -v

# Logs del firewall
sudo tail -50 /var/log/ufw.log

# Aplicaciones permitidas
sudo ufw app list
```

---

## 8️⃣ STORAGE (NFS)

```bash
# Estado del servicio
sudo systemctl status nfs-kernel-server

# Exports configurados
sudo cat /etc/exports

# Directorios compartidos
ls -la /srv/nfs/
ls -la /srv/nfs/games/
ls -la /srv/nfs/shared/

# Verificar exports activos
sudo exportfs -v

# Logs de NFS
sudo journalctl -u nfs-kernel-server -n 30 --no-pager
```

---

## 9️⃣ VALIDACIONES COMPLETAS

```bash
# Validar TODO
bash scripts/run/validate-all.sh

# Validaciones individuales
bash scripts/run/validate-common.sh
bash scripts/run/validate-network.sh
bash scripts/run/validate-dns.sh
bash scripts/run/validate-dhcp.sh
bash scripts/run/validate-firewall.sh
bash scripts/run/validate-storage.sh
```

---

## 🔟 PRUEBAS DE CONECTIVIDAD

```bash
# Ping IPv6 local
ping6 -c 4 2025:db8:10::1

# Ping IPv6 internet
ping6 -c 4 2001:4860:4860::8888
ping6 -c 4 google.com

# Ping NAT64
ping6 -c 4 64:ff9b::8.8.8.8

# Curl con IPv6
curl -6 http://google.com
curl -6 http://[64:ff9b::8.8.8.8]

# Traceroute IPv6
traceroute6 google.com

# DNS lookup
dig @localhost gamecenter.lan AAAA +short
dig @localhost google.com AAAA +short
dig @localhost facebook.com AAAA +short
```

---

## 📊 MONITOREO EN TIEMPO REAL

```bash
# Ver logs en tiempo real
sudo journalctl -f

# Logs de servicios específicos
sudo journalctl -f -u bind9 -u isc-dhcp-server6 -u tayga -u radvd

# Tráfico de red
sudo tcpdump -i ens34 -n ip6

# Conexiones activas
watch -n 2 'sudo ss -tulpn | grep -E ":53|:547"'

# Clientes conectados
watch -n 5 'ip -6 neigh show'

# Uso de CPU y memoria
htop
# O
top
```

---

## 📁 ARCHIVOS DE CONFIGURACIÓN IMPORTANTES

```bash
# Ansible
cat ansible.cfg
cat inventory.yml
cat group_vars/all.yml
# NO mostrar: group_vars/all.vault.yml (está encriptado)

# Ver estructura de roles
ls -la roles/
ls -la roles/dns_bind/
ls -la roles/dhcpv6/
ls -la roles/nat64_tayga/

# Ver playbooks
ls -la playbooks/
cat site.yml

# Ver scripts
ls -la scripts/
ls -la scripts/run/
```

---

## 🎨 INFORMACIÓN VISUAL

```bash
# Árbol de procesos
pstree -p | grep -E "bind|dhcp|tayga|radvd"

# Uso de disco
df -h

# Uso de memoria
free -h

# Procesos de red
sudo netstat -tulpn | grep -E "bind|dhcp|tayga"

# Información de hardware
lscpu
lsmem
lsblk
```

---

## 🔍 DIAGNÓSTICO AVANZADO

```bash
# Verificar DNS completo
bash scripts/diagnose-nat64.sh

# Debug DNS
bash scripts/debug-dns-resolution.sh

# Escanear red
bash scripts/scan-network-ipv6.sh

# Ver zona DNS
bash scripts/show-dns-zone.sh

# Sincronizar DHCP-DNS
bash scripts/sync-dhcp-to-dns.sh
```

---

## 📋 RESUMEN EJECUTIVO (Para captura final)

```bash
# Un solo comando que muestra TODO
cat << 'EOF'
════════════════════════════════════════════════════════════
           RESUMEN DE CONFIGURACIÓN DEL SERVIDOR
════════════════════════════════════════════════════════════

SISTEMA:
EOF
uname -a
echo ""

echo "SERVICIOS:"
systemctl is-active bind9 && echo "  ✅ DNS (BIND9)" || echo "  ❌ DNS"
systemctl is-active isc-dhcp-server6 && echo "  ✅ DHCPv6" || echo "  ❌ DHCPv6"
systemctl is-active tayga && echo "  ✅ NAT64 (Tayga)" || echo "  ❌ NAT64"
systemctl is-active radvd && echo "  ✅ RADVD" || echo "  ❌ RADVD"
echo ""

echo "RED IPv6:"
ip -6 addr show ens34 | grep "inet6" | grep -v "fe80"
echo ""

echo "DNS:"
dig @localhost gamecenter.lan AAAA +short
echo ""

echo "NAT64:"
ip -6 route | grep 64:ff9b
echo ""

echo "FIREWALL:"
sudo ufw status | head -5
echo ""

echo "════════════════════════════════════════════════════════════"
```

---

## 💾 GUARDAR TODA LA CONFIGURACIÓN EN UN ARCHIVO

```bash
# Crear reporte completo
bash << 'EOF' > reporte-configuracion.txt
echo "REPORTE DE CONFIGURACIÓN - $(date)"
echo "========================================"
echo ""
echo "=== SISTEMA ==="
uname -a
lsb_release -a
echo ""
echo "=== SERVICIOS ==="
systemctl status bind9 --no-pager
systemctl status isc-dhcp-server6 --no-pager
systemctl status tayga --no-pager
echo ""
echo "=== RED ==="
ip -6 addr show
ip -6 route
echo ""
echo "=== DNS ==="
sudo cat /etc/bind/named.conf.local
echo ""
echo "=== DHCP ==="
sudo cat /etc/dhcp/dhcpd6.conf
echo ""
echo "=== NAT64 ==="
sudo cat /etc/tayga.conf
EOF

cat reporte-configuracion.txt
```

---

## 🎯 COMANDOS CORTOS PARA CAPTURAS RÁPIDAS

```bash
# Captura 1: Servicios
systemctl status bind9 isc-dhcp-server6 tayga radvd --no-pager

# Captura 2: Red
ip -6 addr show && ip -6 route

# Captura 3: DNS
dig @localhost gamecenter.lan AAAA && dig @localhost google.com AAAA

# Captura 4: Puertos
sudo ss -tulpn | grep -E ":53|:547"

# Captura 5: Firewall
sudo ufw status verbose

# Captura 6: NAT64
ping6 -c 4 64:ff9b::8.8.8.8

# Captura 7: Validación
bash scripts/run/validate-all.sh
```

---

## 📸 ORDEN SUGERIDO PARA DOCUMENTAR

1. **Información del sistema** → `uname -a`, `lsb_release -a`
2. **Estructura del proyecto** → `tree` o `ls -la`
3. **Servicios activos** → `systemctl status`
4. **Configuración de red** → `ip addr`, `ip route`
5. **DNS funcionando** → `dig` commands
6. **DHCP configurado** → `cat /etc/dhcp/dhcpd6.conf`
7. **NAT64 activo** → `ping6 64:ff9b::8.8.8.8`
8. **Firewall** → `ufw status`
9. **Validaciones** → `validate-all.sh`
10. **Pruebas de conectividad** → `ping6`, `curl`
