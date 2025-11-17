# ════════════════════════════════════════════════════════════════
# GUÍA 1: CONFIGURACIÓN DEL SERVIDOR
# ════════════════════════════════════════════════════════════════

## 📋 Requisitos

- Ubuntu Server 24.04
- Usuario: ubuntu / Contraseña: 123
- 2 interfaces de red:
  - ens33: Internet (IPv4 DHCP) - VM Network
  - ens34: Red interna (IPv6) - M_vm's

---

## 🚀 INSTALACIÓN INICIAL

### 1. Instalar dependencias

```bash
sudo apt update
sudo apt install -y ansible python3-pip git
pip3 install passlib
```

### 2. Clonar repositorio

```bash
cd ~
git clone <kyrafka/ansible.git> ansible
cd ansible
```

---

## 🔧 CONFIGURACIÓN POR COMPONENTES

### ⚠️ ORDEN IMPORTANTE

1. Paquetes base
2. **Firewall** (instala iptables-persistent que DNS necesita)
3. Red
4. DNS
5. DNS64
6. **NAT64** (CRÍTICO para internet)
7. Proxy
8. DHCP
9. SSH
10. Usuarios

---

### PASO 1: Paquetes base

```bash
bash scripts/run/run-common.sh
bash scripts/run/validate-common.sh
```

---

### PASO 2: Firewall

```bash
bash scripts/run/run-firewall.sh
bash scripts/run/run-firewall.sh  # Ejecutar DOS VECES
bash scripts/run/validate-firewall.sh
```

**Puertos abiertos:** 22 (SSH), 53 (DNS), 547 (DHCP), 3128 (Proxy)

---

### PASO 3: Red

```bash
bash scripts/run/run-network.sh
bash scripts/run/validate-network.sh
```

**Verifica:**
```bash
ip -6 addr show ens34 | grep 2025:db8:10::2
sysctl net.ipv6.conf.all.forwarding
```

---

### PASO 4: DNS

```bash
bash scripts/run/run-dns.sh
bash scripts/run/validate-dns.sh
```

**Verifica:**
```bash
dig @localhost gamecenter.lan SOA
dig @localhost servidor.gamecenter.lan AAAA
```

---

### PASO 5: DNS64

```bash
sudo bash scripts/configure-dns64-simple.sh
```

**Verifica:**
```bash
dig @localhost google.com AAAA
```

---

### PASO 6: NAT64 ⭐ CRÍTICO

```bash
sudo bash scripts/nat64/install-nat64-tayga.sh
```

**Verifica:**
```bash
sudo systemctl status tayga
ip addr show nat64
ping6 64:ff9b::808:808
```

**Si falla:**
```bash
sudo systemctl stop tayga
sudo ip link delete nat64 2>/dev/null || true
sudo bash scripts/nat64/install-nat64-tayga.sh
```

---

### PASO 7: Proxy

```bash
sudo bash scripts/install-squid-proxy.sh
```

**Verifica:**
```bash
sudo systemctl status squid
```

---

### PASO 8: DHCP

```bash
bash scripts/run/run-dhcp.sh
bash scripts/run/validate-dhcp.sh
```

**Verifica:**
```bash
sudo systemctl status isc-dhcp-server6
sudo journalctl -u isc-dhcp-server6 -n 50
```

---

### PASO 9: SSH

```bash
sudo bash scripts/verify-ssh-restriction.sh
```

**Verifica:**
```bash
sudo grep "^AllowUsers" /etc/ssh/sshd_config
```

---

### PASO 10: Usuarios

```bash
sudo bash scripts/server-create-users.sh
```

**Usuarios creados:**
- ubuntu (admin) - Contraseña: 123
- auditor - Contraseña: 123
- dev - Contraseña: 123

---

## ✅ VALIDACIÓN COMPLETA

```bash
bash scripts/run/validate-all.sh
```

### Verificaciones manuales:

```bash
# Red
ip -6 addr show ens34
ip -6 route

# DNS
dig @localhost gamecenter.lan SOA

# NAT64
ping6 64:ff9b::808:808

# Servicios
sudo systemctl status named
sudo systemctl status isc-dhcp-server6
sudo systemctl status tayga
sudo systemctl status squid
```

---

## 🔍 DIAGNÓSTICO

### Problema: VMs sin internet

```bash
# Verificar NAT64
sudo systemctl status tayga
ip addr show nat64
ping6 64:ff9b::808:808

# Reinstalar si falla
sudo systemctl stop tayga
sudo ip link delete nat64 2>/dev/null || true
sudo bash scripts/nat64/install-nat64-tayga.sh
```

### Problema: DNS no resuelve

```bash
sudo systemctl status named
sudo journalctl -xeu named
sudo bash scripts/dns-clean-and-reload.sh
```

### Problema: DHCP no asigna IPs

```bash
sudo systemctl status isc-dhcp-server6
sudo journalctl -xeu isc-dhcp-server6
sudo systemctl restart isc-dhcp-server6
```

### Problema: SSH permite usuarios no autorizados

```bash
sudo bash scripts/diagnose-ssh-problem.sh
sudo bash scripts/verify-ssh-restriction.sh
```

---

## 📊 ESTADO ESPERADO

### Servicios corriendo:
```bash
sudo systemctl status named
sudo systemctl status isc-dhcp-server6
sudo systemctl status tayga
sudo systemctl status squid
```

### Red configurada:
```
ens33: 172.17.25.45/24 (IPv4 DHCP)
ens34: 2025:db8:10::2/64 (IPv6 estática)
nat64: 192.168.255.1/24 + 64:ff9b::1/96
```

### Usuarios:
```
ubuntu  - Admin completo
auditor - Solo lectura
dev     - Gestión de servicios
```

---

## 🔄 COMANDOS ÚTILES

```bash
# Reiniciar servicios
sudo systemctl restart named
sudo systemctl restart isc-dhcp-server6
sudo systemctl restart tayga
sudo systemctl restart squid

# Ver logs
sudo journalctl -fu named
sudo journalctl -fu isc-dhcp-server6
sudo journalctl -fu tayga

# Ver red
ip -6 addr show
ip -6 route
sudo ip6tables -t nat -L -v -n

# Ver firewall
sudo ufw status verbose
```

---

# ════════════════════════════════════════════════════════════════
# FIN GUÍA SERVIDOR
# ════════════════════════════════════════════════════════════════
