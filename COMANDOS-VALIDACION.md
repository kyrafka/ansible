# 🔍 COMANDOS DE VALIDACIÓN DIRECTOS

## Scripts de Validación Existentes

Ya tienes estos scripts listos para usar:

```bash
# Validar TODO
bash scripts/run/validate-all.sh

# Validar servicios individuales
bash scripts/run/validate-dns.sh
bash scripts/run/validate-dhcp.sh
bash scripts/run/validate-network.sh
bash scripts/run/validate-firewall.sh
bash scripts/run/validate-storage.sh
```

---

## 📋 COMANDOS CRUDOS PARA VALIDACIÓN MANUAL

### 1️⃣ VERIFICAR SERVICIOS SYSTEMD

```bash
# Ver estado de todos los servicios importantes
sudo systemctl status bind9
sudo systemctl status isc-dhcp-server6
sudo systemctl status tayga
sudo systemctl status radvd

# Ver si están activos (respuesta rápida)
systemctl is-active bind9
systemctl is-active isc-dhcp-server6
systemctl is-active tayga
systemctl is-active radvd

# Ver si están habilitados al inicio
systemctl is-enabled bind9
systemctl is-enabled isc-dhcp-server6
systemctl is-enabled tayga
systemctl is-enabled radvd
```

---

### 2️⃣ VERIFICAR PUERTOS DE RED

```bash
# Ver todos los puertos escuchando
sudo ss -tulpn

# Ver solo DNS (puerto 53)
sudo ss -tulpn | grep :53

# Ver solo DHCPv6 (puerto 547)
sudo ss -ulpn | grep :547

# Ver procesos de red
sudo netstat -tulpn | grep -E "bind|dhcp|tayga"
```

---

### 3️⃣ VERIFICAR DNS (BIND9)

```bash
# Verificar configuración de BIND
sudo named-checkconf

# Verificar zona específica
sudo named-checkzone gamecenter.lan /etc/bind/zones/db.gamecenter.lan

# Probar resolución DNS local
dig @localhost gamecenter.lan AAAA
dig @localhost google.com AAAA

# Ver si DNS64 funciona (debe devolver 64:ff9b::)
dig @localhost google.com AAAA +short

# Recargar zonas DNS
sudo rndc reload

# Ver estadísticas de BIND
sudo rndc status

# Ver logs de BIND
sudo journalctl -u bind9 -n 50
sudo journalctl -u bind9 -f  # seguir logs en tiempo real

# Ver archivos de zona
sudo cat /etc/bind/zones/db.gamecenter.lan
sudo cat /var/lib/bind/db.gamecenter.lan

# Ver configuración
sudo cat /etc/bind/named.conf.local
sudo cat /etc/bind/named.conf.options
```

---

### 4️⃣ VERIFICAR DHCP IPv6

```bash
# Ver configuración DHCPv6
sudo cat /etc/dhcp/dhcpd6.conf

# Ver leases activos
sudo cat /var/lib/dhcp/dhcpd6.leases

# Ver logs de DHCP
sudo journalctl -u isc-dhcp-server6 -n 50
sudo journalctl -u isc-dhcp-server6 -f  # seguir logs

# Ver qué interfaz está usando
sudo cat /etc/default/isc-dhcp-server

# Reiniciar DHCP
sudo systemctl restart isc-dhcp-server6

# Ver clientes conectados
sudo dhcp-lease-list --lease /var/lib/dhcp/dhcpd6.leases
```

---

### 5️⃣ VERIFICAR NAT64 (TAYGA)

```bash
# Ver estado de Tayga
sudo systemctl status tayga

# Ver configuración de Tayga
sudo cat /etc/tayga.conf

# Ver interfaz nat64
ip link show nat64
ip addr show nat64

# Ver rutas NAT64
ip -6 route | grep 64:ff9b
ip -4 route | grep 192.168.255

# Ver reglas de iptables para NAT
sudo iptables -t nat -L POSTROUTING -n -v

# Probar conectividad NAT64
ping6 -c 4 64:ff9b::8.8.8.8
ping6 -c 4 64:ff9b::1.1.1.1

# Ver logs de Tayga
sudo journalctl -u tayga -n 50
sudo journalctl -u tayga -f
```

---

### 6️⃣ VERIFICAR RED IPv6

```bash
# Ver todas las interfaces con IPv6
ip -6 addr show

# Ver interfaces específicas
ip -6 addr show ens33
ip -6 addr show ens34

# Ver rutas IPv6
ip -6 route

# Verificar IP forwarding
cat /proc/sys/net/ipv4/ip_forward
cat /proc/sys/net/ipv6/conf/all/forwarding

# Ver configuración de radvd
sudo cat /etc/radvd.conf

# Ver logs de radvd
sudo journalctl -u radvd -n 50

# Probar conectividad IPv6
ping6 -c 4 2001:4860:4860::8888  # Google DNS
ping6 -c 4 2606:4700:4700::1111  # Cloudflare DNS
```

---

### 7️⃣ VERIFICAR FIREWALL (UFW)

```bash
# Ver estado del firewall
sudo ufw status verbose

# Ver reglas numeradas
sudo ufw status numbered

# Ver reglas de iptables directamente
sudo iptables -L -n -v
sudo ip6tables -L -n -v

# Ver reglas NAT
sudo iptables -t nat -L -n -v
```

---

### 8️⃣ VERIFICAR ARCHIVOS DE CONFIGURACIÓN

```bash
# DNS
ls -la /etc/bind/
ls -la /etc/bind/zones/
ls -la /var/lib/bind/

# DHCP
ls -la /etc/dhcp/
ls -la /var/lib/dhcp/

# NAT64
ls -la /etc/tayga.conf
ls -la /var/db/tayga/

# Red
ls -la /etc/netplan/
cat /etc/netplan/*.yaml
```

---

### 9️⃣ VERIFICAR LOGS GENERALES

```bash
# Ver todos los logs del sistema
sudo journalctl -n 100

# Ver logs de los últimos 5 minutos
sudo journalctl --since "5 minutes ago"

# Ver logs de un servicio específico
sudo journalctl -u bind9 --since today
sudo journalctl -u isc-dhcp-server6 --since today
sudo journalctl -u tayga --since today

# Seguir logs en tiempo real
sudo journalctl -f

# Ver solo errores
sudo journalctl -p err -n 50
```

---

### 🔟 PRUEBAS DE CONECTIVIDAD

```bash
# Desde el servidor, probar DNS
dig @localhost gamecenter.lan AAAA
nslookup gamecenter.lan localhost

# Probar DNS64
dig @localhost google.com AAAA
dig @localhost facebook.com AAAA

# Probar NAT64
ping6 64:ff9b::8.8.8.8
curl -6 http://[64:ff9b::8.8.8.8]

# Probar conectividad IPv6 pura
ping6 google.com
ping6 2001:4860:4860::8888

# Ver tabla de vecinos IPv6 (clientes conectados)
ip -6 neigh show
```

---

## 🚀 COMANDOS RÁPIDOS DE DIAGNÓSTICO

```bash
# Ver TODO de un vistazo
echo "=== SERVICIOS ===" && \
systemctl is-active bind9 isc-dhcp-server6 tayga radvd && \
echo -e "\n=== PUERTOS ===" && \
sudo ss -tulpn | grep -E ":53|:547" && \
echo -e "\n=== INTERFAZ NAT64 ===" && \
ip link show nat64 && \
echo -e "\n=== FORWARDING ===" && \
echo "IPv4: $(cat /proc/sys/net/ipv4/ip_forward)" && \
echo "IPv6: $(cat /proc/sys/net/ipv6/conf/all/forwarding)"

# Probar DNS completo
echo "=== DNS LOCAL ===" && \
dig @localhost gamecenter.lan AAAA +short && \
echo -e "\n=== DNS64 ===" && \
dig @localhost google.com AAAA +short | grep 64:ff9b

# Ver clientes DHCP
echo "=== LEASES DHCP ===" && \
sudo grep -E "^lease6|binding state" /var/lib/dhcp/dhcpd6.leases | tail -20

# Ver errores recientes
echo "=== ERRORES RECIENTES ===" && \
sudo journalctl -p err --since "10 minutes ago" --no-pager
```

---

## 🔧 COMANDOS DE REPARACIÓN RÁPIDA

```bash
# Reiniciar todos los servicios
sudo systemctl restart bind9
sudo systemctl restart isc-dhcp-server6
sudo systemctl restart tayga
sudo systemctl restart radvd

# Recargar configuración DNS sin reiniciar
sudo rndc reload

# Limpiar y reiniciar Tayga
sudo systemctl stop tayga
sudo ip link delete nat64 2>/dev/null || true
sudo rm -rf /var/db/tayga/*
sudo systemctl start tayga
sleep 2
sudo ip link set nat64 up
sudo ip -6 route add 64:ff9b::/96 dev nat64
sudo ip -4 route add 192.168.255.0/24 dev nat64

# Verificar y corregir permisos DNS
sudo chown -R bind:bind /var/lib/bind
sudo chmod 775 /var/lib/bind

# Habilitar forwarding si está desactivado
sudo sysctl -w net.ipv4.ip_forward=1
sudo sysctl -w net.ipv6.conf.all.forwarding=1
```

---

## 📊 MONITOREO EN TIEMPO REAL

```bash
# Ver logs de todos los servicios en tiempo real
sudo journalctl -f -u bind9 -u isc-dhcp-server6 -u tayga -u radvd

# Ver tráfico de red en tiempo real
sudo tcpdump -i ens34 -n ip6

# Ver conexiones activas
watch -n 2 'sudo ss -tulpn | grep -E "bind|dhcp|tayga"'

# Ver clientes conectados
watch -n 5 'ip -6 neigh show'
```

---

## ✅ CHECKLIST RÁPIDO

Copia y pega esto para verificar todo:

```bash
#!/bin/bash
echo "🔍 VALIDACIÓN RÁPIDA DEL SERVIDOR"
echo "=================================="
echo ""
echo "1. Servicios:"
systemctl is-active bind9 && echo "  ✅ DNS" || echo "  ❌ DNS"
systemctl is-active isc-dhcp-server6 && echo "  ✅ DHCP" || echo "  ❌ DHCP"
systemctl is-active tayga && echo "  ✅ NAT64" || echo "  ❌ NAT64"
systemctl is-active radvd && echo "  ✅ RADVD" || echo "  ❌ RADVD"
echo ""
echo "2. Puertos:"
sudo ss -tulpn | grep -q ":53.*named" && echo "  ✅ DNS:53" || echo "  ❌ DNS:53"
sudo ss -ulpn | grep -q ":547.*dhcpd" && echo "  ✅ DHCP:547" || echo "  ❌ DHCP:547"
echo ""
echo "3. Forwarding:"
[ "$(cat /proc/sys/net/ipv4/ip_forward)" == "1" ] && echo "  ✅ IPv4" || echo "  ❌ IPv4"
[ "$(cat /proc/sys/net/ipv6/conf/all/forwarding)" == "1" ] && echo "  ✅ IPv6" || echo "  ❌ IPv6"
echo ""
echo "4. NAT64:"
ip link show nat64 &>/dev/null && echo "  ✅ Interfaz nat64" || echo "  ❌ Interfaz nat64"
ip -6 route | grep -q "64:ff9b::/96" && echo "  ✅ Ruta NAT64" || echo "  ❌ Ruta NAT64"
echo ""
echo "5. DNS:"
dig @localhost gamecenter.lan AAAA +short &>/dev/null && echo "  ✅ Resuelve dominio local" || echo "  ❌ No resuelve dominio local"
dig @localhost google.com AAAA +short 2>/dev/null | grep -q "64:ff9b" && echo "  ✅ DNS64 funciona" || echo "  ❌ DNS64 no funciona"
echo ""
```

Guarda esto como `check.sh` y ejecútalo con `bash check.sh`
