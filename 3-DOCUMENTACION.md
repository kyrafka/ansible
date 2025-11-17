# ════════════════════════════════════════════════════════════════
# GUÍA 3: DOCUMENTACIÓN TÉCNICA
# ════════════════════════════════════════════════════════════════

## 📚 CONCEPTOS CLAVE

### 🔀 IP Forwarding

**¿Qué es?**
Permite que el servidor reenvíe paquetes entre interfaces (actúa como router).

**Sin IP Forwarding:**
```
VM → Servidor → ❌ BLOQUEADO
```

**Con IP Forwarding:**
```
VM → Servidor → ✅ REENVÍA → Internet
```

**Comando:**
```bash
sysctl net.ipv6.conf.all.forwarding=1
```

---

### 🌐 NAT64 (Tayga)

**¿Qué hace?**
Traduce paquetes IPv6 → IPv4 (para que VMs con solo IPv6 accedan a internet IPv4).

**Flujo:**
```
VM (IPv6: 2025:db8:10::100)
    ↓
Quiere ir a google.com (IPv4: 8.8.8.8)
    ↓
DNS64: Traduce a 64:ff9b::808:808 (IPv6 falso)
    ↓
VM envía paquete a 64:ff9b::808:808
    ↓
NAT64 (Tayga): Traduce IPv6 → IPv4
    ↓
Sale a internet como IPv4
    ↓
Google responde
    ↓
NAT64: Traduce respuesta IPv4 → IPv6
    ↓
VM recibe respuesta
```

**Prefijo:** `64:ff9b::/96`

---

### 📖 BIND9

**¿Qué es?**
Servidor DNS (Domain Name System) - traduce nombres a IPs.

**Funciones:**
1. DNS local: Resuelve nombres internos (gamecenter.lan)
2. DNS64: Traduce nombres IPv4 a IPv6
3. DDNS: Registra VMs automáticamente
4. Forwarder: Reenvía consultas externas a Google DNS

**Ejemplo:**
```
ubuntu123.gamecenter.lan → 2025:db8:10::dce9
google.com → 64:ff9b::8.8.8.8 (DNS64)
```

---

### 🌐 Proxy (Squid)

**¿Qué hace?**
Cachea y optimiza descargas HTTP/HTTPS.

**Ventajas:**
- apt update más rápido
- Navegadores funcionan mejor
- Ahorra ancho de banda
- Caché compartido entre VMs

**Puerto:** 3128

---

### 📡 DHCP + DDNS

**DHCP:**
Asigna IPs automáticamente a las VMs.

**DDNS:**
Registra automáticamente las VMs en el DNS.

**Flujo:**
```
VM se conecta
    ↓
DHCP asigna IP: 2025:db8:10::dce9
    ↓
DDNS registra en DNS: ubuntu123.gamecenter.lan → 2025:db8:10::dce9
    ↓
Ahora puedes hacer: ping6 ubuntu123.gamecenter.lan
```

---

### 🗂️ NFS

**¿Qué es?**
Network File System - carpetas compartidas en red.

**Ventajas:**
- Un juego, múltiples VMs
- Actualiza una vez, todos lo ven
- Ahorro de espacio

**Ejemplo:**
```
Servidor: /srv/nfs/games/Minecraft
VM1: /mnt/games/Minecraft (mismo archivo)
VM2: /mnt/games/Minecraft (mismo archivo)
```

---

## 🏗️ ARQUITECTURA

```
┌─────────────────────────────────────────────────────────┐
│                    SERVIDOR                             │
│                                                         │
│  ens33 (IPv4)          ens34 (IPv6)                    │
│  172.17.25.45          2025:db8:10::2                  │
│       ↑                     ↑                           │
│       │                     │                           │
│  ┌────┴─────┐         ┌────┴─────┐                    │
│  │ NAT64    │         │ BIND9    │                     │
│  │ (Tayga)  │         │ (DNS)    │                     │
│  │ IPv6→IPv4│         │ DNS64    │                     │
│  └──────────┘         └──────────┘                     │
│       ↑                     ↑                           │
│       │                     │                           │
│  ┌────┴─────┐         ┌────┴─────┐                    │
│  │ Squid    │         │ DHCPv6   │                     │
│  │ (Proxy)  │         │ + DDNS   │                     │
│  │ :3128    │         │ :547     │                     │
│  └──────────┘         └──────────┘                     │
│                                                         │
│  IP Forwarding habilitado (actúa como router)          │
└─────────────────────────────────────────────────────────┘
       ↓                     ↓
   Internet              VMs (IPv6)
   (IPv4)                2025:db8:10::/64
```

---

## 🔄 FLUJO DE INTERNET

```
1. VM quiere ir a google.com
   ↓
2. Pregunta al DNS (2025:db8:10::2)
   ↓
3. DNS64 traduce: google.com → 64:ff9b::8.8.8.8
   ↓
4. VM envía paquete a 64:ff9b::8.8.8.8
   ↓
5. NAT64 (Tayga) traduce: IPv6 → IPv4
   ↓
6. Sale por ens33 (172.17.25.45) a internet
   ↓
7. Google responde
   ↓
8. NAT64 traduce respuesta: IPv4 → IPv6
   ↓
9. VM recibe respuesta
```

---

## 📊 PREFIJOS Y RANGOS

| Componente | Prefijo/Rango |
|------------|---------------|
| Red interna | 2025:db8:10::/64 |
| Servidor | 2025:db8:10::2 |
| Gateway | 2025:db8:10::1 |
| DHCP range | 2025:db8:10::10 - ::FFFF |
| NAT64 | 64:ff9b::/96 |
| Tayga pool | 192.168.255.0/24 |

---

## 🔐 SEGURIDAD

### Firewall (UFW)

**Puertos abiertos:**
- 22/tcp: SSH
- 53/tcp,udp: DNS
- 547/udp: DHCPv6
- 3128/tcp: Squid Proxy

### SSH

**Usuarios permitidos:**
- Servidor: ubuntu
- VM: administrador

**Usuarios bloqueados:**
- Servidor: auditor, dev
- VM: auditor, gamer01

---

## 👥 ROLES Y PERMISOS

### Servidor:

| Usuario | Sudo | SSH | Función |
|---------|------|-----|---------|
| ubuntu | ✅ | ✅ | Admin completo |
| auditor | ❌ | ❌ | Ver logs |
| dev | ⚡ | ❌ | Gestionar servicios |

### VM Ubuntu Desktop:

| Usuario | Sudo | SSH | Función |
|---------|------|-----|---------|
| administrador | ✅ | ✅ | Admin completo |
| auditor | ❌ | ❌ | Ver logs |
| gamer01 | ❌ | ❌ | Cliente/Gamer |

---

## 🔧 TROUBLESHOOTING

### VM sin internet

**Causa:** NAT64 no funciona

**Solución:**
```bash
# En el servidor
sudo systemctl stop tayga
sudo ip link delete nat64 2>/dev/null || true
sudo bash scripts/nat64/install-nat64-tayga.sh
```

### DNS no resuelve

**Causa:** BIND9 mal configurado

**Solución:**
```bash
sudo bash scripts/dns-clean-and-reload.sh
```

### DHCP no asigna IPs

**Causa:** Servicio detenido o mal configurado

**Solución:**
```bash
sudo systemctl restart isc-dhcp-server6
sudo journalctl -xeu isc-dhcp-server6
```

### SSH permite usuarios no autorizados

**Causa:** AllowUsers mal configurado

**Solución:**
```bash
sudo bash scripts/diagnose-ssh-problem.sh
sudo bash scripts/verify-ssh-restriction.sh
```

---

## 📦 DEPENDENCIAS

### Servidor:
- ansible
- python3-pip
- passlib
- bind9
- isc-dhcp-server
- tayga
- squid
- iptables-persistent
- ufw

### VM:
- openssh-server
- git
- nfs-common
- gnome-tweaks
- papirus-icon-theme
- fonts-firacode

---

# ════════════════════════════════════════════════════════════════
# FIN DOCUMENTACIÓN
# ════════════════════════════════════════════════════════════════
