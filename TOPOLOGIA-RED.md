# Topología de Red - GameCenter

Diagrama completo de la red física y virtual.

---

## 🌐 Topología Completa

```
                    Internet
                       ↓
        ┌──────────────────────────────┐
        │  Router_Fisico (1941)        │
        │  Gig0/0                      │
        └──────────────┬───────────────┘
                       ↓
        ┌──────────────────────────────┐
        │  S_Fisico (2960-24TT)        │  ← Switch físico
        │  Fa0/1, Fa0/3, Fa0/4, Fa0/5  │
        └──────────────┬───────────────┘
                       ↓ Fa0/2
        ┌──────────────────────────────┐
        │  S_virtual ESXi (2960-24TT)  │  ← Switch virtual en ESXi
        │  Fa0/1                       │
        └──────────────┬───────────────┘
                       ↓
        ┌──────────────────────────────┐
        │  Servidor Ubuntu             │
        │  (Ubuntu_server_virtual)     │
        │                              │
        │  ens33 (Gig1) ← Internet     │  ← Adaptador 1: WAN
        │  ens34 (Fa0)  ← Red interna  │  ← Adaptador 2: LAN
        └──────────────┬───────────────┘
                       ↓ ens34
        ┌──────────────────────────────┐
        │  Red: M_vm's                 │  ← Red virtual en ESXi
        │  (Switc_Interno_Virtual)     │
        │  2025:db8:10::/64            │
        └──────┬───────────────┬───────┘
               ↓               ↓
    ┌──────────────┐   ┌──────────────┐
    │  Linux2      │   │  W11-H2      │
    │  (ens33)     │   │  (Ethernet0) │
    │  ::100/64    │   │  ::101/64    │
    └──────────────┘   └──────────────┘
               ↓               ↓
    ┌──────────────────────────────────┐
    │  Ubuntu-Desktop-GameCenter       │  ← Nueva VM
    │  (ens33)                         │
    │  ::102/64                        │
    │                                  │
    │  Usuarios:                       │
    │  • admin                         │
    │  • auditor                       │
    │  • gamer01                       │
    └──────────────────────────────────┘
```

---

## 📊 Tabla de Interfaces

### **Servidor Ubuntu (Ubuntu_server_virtual)**

| Interfaz | Nombre en diagrama | Red VMware | Propósito | Configuración |
|----------|-------------------|------------|-----------|---------------|
| **ens33** | Gig1 | VM Network | Internet (WAN) | IPv4 DHCP |
| **ens34** | Fa0 | M_vm's | Red interna (LAN) | IPv6 2025:db8:10::2/64 |

### **VMs Cliente**

| VM | Interfaz | Red VMware | IP asignada | Propósito |
|----|----------|------------|-------------|-----------|
| **Linux2** | ens33 | M_vm's | 2025:db8:10::100/64 | Cliente Linux |
| **W11-H2** | Ethernet0 | M_vm's | 2025:db8:10::101/64 | Cliente Windows |
| **Ubuntu-Desktop-GameCenter** | ens33 | M_vm's | 2025:db8:10::102/64 | Desktop con 3 usuarios |

---

## 🔧 Configuración de Redes en VMware

### **Red: VM Network**
- **Tipo:** Bridged o NAT
- **Propósito:** Salida a internet
- **Conectado a:** ens33 del servidor
- **Configuración:** IPv4 DHCP desde el router físico

### **Red: M_vm's**
- **Tipo:** Internal (red privada)
- **Propósito:** Red interna IPv6 para VMs
- **Conectado a:**
  - ens34 del servidor (gateway)
  - ens33 de Linux2
  - Ethernet0 de W11-H2
  - ens33 de Ubuntu-Desktop-GameCenter
- **Configuración:** IPv6 2025:db8:10::/64

---

## 🌐 Flujo de Tráfico

### **VM → Internet:**

```
1. Ubuntu-Desktop-GameCenter (2025:db8:10::102)
   ↓
2. Red M_vm's (switch virtual)
   ↓
3. Servidor ens34 (2025:db8:10::2)
   ↓ [NAT66]
4. Servidor ens33 (IPv4)
   ↓
5. S_virtual ESXi
   ↓
6. S_Fisico
   ↓
7. Router_Fisico
   ↓
8. Internet
```

### **VM → Servidor (DNS/DHCP/NFS):**

```
1. Ubuntu-Desktop-GameCenter (2025:db8:10::102)
   ↓
2. Red M_vm's
   ↓
3. Servidor ens34 (2025:db8:10::2)
   ↓
   Servicios:
   - DNS (puerto 53)
   - DHCP (puerto 547)
   - NFS (puerto 2049)
```

### **VM ↔ VM:**

```
1. Ubuntu-Desktop-GameCenter (2025:db8:10::102)
   ↓
2. Red M_vm's
   ↓
3. Linux2 (2025:db8:10::100)

(Comunicación directa, sin pasar por el servidor)
```

---

## 📋 Configuración de la VM Ubuntu Desktop

### **Especificaciones:**
```yaml
Nombre: Ubuntu-Desktop-GameCenter
RAM: 8 GB
CPUs: 4
Disco: 40 GB
Red: M_vm's (1 adaptador)
```

### **Adaptador de red:**
```yaml
Adaptador 1:
  - Nombre en Ubuntu: ens33
  - Red VMware: M_vm's
  - Tipo: VMXNET3
  - Configuración: IPv6 DHCP
```

### **Configuración de red (netplan):**
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

### **IP asignada:**
- **IP:** 2025:db8:10::102/64 (por DHCP)
- **Gateway:** 2025:db8:10::1
- **DNS:** 2025:db8:10::2

---

## 🔍 Verificación

### **Desde el servidor:**

```bash
# Ver interfaces
ip -6 addr show

# Debe mostrar:
# ens33: inet X.X.X.X/24 (IPv4)
# ens34: inet6 2025:db8:10::2/64

# Ver leases DHCP
cat /var/lib/dhcp/dhcpd6.leases

# Debe mostrar:
# 2025:db8:10::100 (Linux2)
# 2025:db8:10::101 (W11-H2)
# 2025:db8:10::102 (Ubuntu-Desktop-GameCenter)

# Ver NAT66
ip6tables -t nat -L -v

# Debe tener regla MASQUERADE
```

### **Desde la VM Ubuntu Desktop:**

```bash
# Ver interfaz
ip -6 addr show ens33

# Debe mostrar:
# inet6 2025:db8:10::102/64

# Probar conectividad al servidor
ping6 2025:db8:10::2

# Probar DNS
nslookup server.gamecenter.local

# Probar internet
ping6 google.com

# Ver montajes NFS
df -h | grep nfs

# Debe mostrar:
# [2025:db8:10::2]:/srv/nfs/games on /mnt/games
# [2025:db8:10::2]:/srv/nfs/shared on /mnt/shared
```

---

## 🎯 Resumen de IPs

| Dispositivo | Interfaz | IP | Tipo |
|-------------|----------|-----|------|
| **Servidor** | ens33 | IPv4 DHCP | WAN |
| **Servidor** | ens34 | 2025:db8:10::2/64 | LAN (gateway) |
| **Linux2** | ens33 | 2025:db8:10::100/64 | DHCP |
| **W11-H2** | Ethernet0 | 2025:db8:10::101/64 | DHCP |
| **Ubuntu-Desktop** | ens33 | 2025:db8:10::102/64 | DHCP |

---

## 🔐 Servicios del Servidor

| Servicio | Puerto | Protocolo | Accesible desde |
|----------|--------|-----------|-----------------|
| **DNS** | 53 | TCP/UDP | Todas las VMs |
| **DHCPv6** | 547 | UDP | Todas las VMs |
| **NFS** | 2049 | TCP | Todas las VMs |
| **SSH** | 22 | TCP | Solo admin (firewall) |

---

## 📝 Notas importantes

1. **Red M_vm's:** Es una red **privada** en ESXi, no tiene salida directa a internet.

2. **NAT66:** El servidor hace NAT66 para que las VMs puedan salir a internet.

3. **Nombres de interfaces:**
   - En el servidor: `ens33`, `ens34`
   - En las VMs: `ens33` (o `eth0`, `enp0s3`, depende del SO)
   - Los nombres son **locales** a cada máquina

4. **Firewall del servidor:**
   - Solo `admin` puede hacer SSH al servidor
   - `auditor` y `gamer01` están bloqueados

5. **DHCP:**
   - Rango: 2025:db8:10::100 a 2025:db8:10::200
   - IPs asignadas automáticamente
   - Leases guardados en `/var/lib/dhcp/dhcpd6.leases`

---

**Última actualización:** 2024
**Versión:** 1.0
