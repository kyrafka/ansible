# 📊 TABLAS DE RED COMPLETAS - PROYECTO SO

## Configuración de Red IPv6 para Game Center

---

## 1️⃣ TABLA GENERAL DE RED

| Parámetro | Valor | Descripción |
|-----------|-------|-------------|
| **Red IPv6** | 2025:db8:10::/64 | Red principal del proyecto |
| **Máscara** | /64 | 64 bits para red, 64 bits para hosts |
| **Gateway** | 2025:db8:10::1 | Puerta de enlace (router virtual) |
| **Servidor DNS** | 2025:db8:10::2 | Servidor Ubuntu |
| **Dominio** | gamecenter.lan | Dominio local |
| **Rango DHCP** | 2025:db8:10::10 - ::FFFF | IPs dinámicas para clientes |
| **IPs Estáticas** | 2025:db8:10::1 - ::9 | Reservadas para infraestructura |

---

## 2️⃣ TABLA DE HOSTS Y DIRECCIONES IP

### Infraestructura

| Host | Dirección IPv6 | Máscara | Tipo | Sistema Operativo | Rol |
|------|----------------|---------|------|-------------------|-----|
| **Gateway** | 2025:db8:10::1 | /64 | Estática | Router Virtual (GNS3) | Gateway |
| **Servidor** | 2025:db8:10::2 | /64 | Estática | Ubuntu Server 24.04 LTS | Servidor principal |

### Clientes (Asignación Dinámica DHCP)

| Host | Dirección IPv6 | Máscara | Tipo | Sistema Operativo | Rol | Usuario |
|------|----------------|---------|------|-------------------|-----|---------|
| Ubuntu Desktop 1 | 2025:db8:10::100 | /64 | DHCP | Ubuntu Desktop 24.04 | Admin | administrador |
| Ubuntu Desktop 2 | 2025:db8:10::101 | /64 | DHCP | Ubuntu Desktop 24.04 | Auditor | auditor |
| Ubuntu Desktop 3 | 2025:db8:10::102 | /64 | DHCP | Ubuntu Desktop 24.04 | Cliente | gamer01 |
| Windows 11 - 1 | 2025:db8:10::110 | /64 | DHCP | Windows 11 Home | Admin | Administrador |
| Windows 11 - 2 | 2025:db8:10::111 | /64 | DHCP | Windows 11 Home | Auditor | Auditor |
| Windows 11 - 3 | 2025:db8:10::112 | /64 | DHCP | Windows 11 Home | Cliente | Gamer01 |

---

## 3️⃣ TABLA DE INTERFACES DE RED

### Servidor Ubuntu (2025:db8:10::2)

| Interfaz | Tipo | Dirección IPv6 | Máscara | Gateway | MTU | Estado | Uso |
|----------|------|----------------|---------|---------|-----|--------|-----|
| **ens33** | WAN | DHCP IPv4 | /24 | Auto | 1500 | UP | Internet (NAT) |
| **ens34** | LAN | 2025:db8:10::2 | /64 | - | 1500 | UP | Red interna VMs |
| **lo** | Loopback | ::1 | /128 | - | 65536 | UP | Local |

### Clientes Ubuntu Desktop

| Interfaz | Tipo | Dirección IPv6 | Máscara | Gateway | DNS | Estado |
|----------|------|----------------|---------|---------|-----|--------|
| **ens33** | LAN | DHCP (2025:db8:10::100+) | /64 | 2025:db8:10::1 | 2025:db8:10::2 | UP |
| **lo** | Loopback | ::1 | /128 | - | - | UP |

### Clientes Windows 11

| Interfaz | Tipo | Dirección IPv6 | Máscara | Gateway | DNS | Estado |
|----------|------|----------------|---------|---------|-----|--------|
| **Ethernet** | LAN | DHCP (2025:db8:10::110+) | /64 | 2025:db8:10::1 | 2025:db8:10::2 | UP |
| **Loopback** | Loopback | ::1 | /128 | - | - | UP |

---

## 4️⃣ TABLA DE SERVICIOS Y PUERTOS

### Servicios del Servidor

| Servicio | Software | Puerto | Protocolo | Estado | Acceso | Descripción |
|----------|----------|--------|-----------|--------|--------|-------------|
| **SSH** | OpenSSH | 22 | TCP | ✅ Activo | Limitado | Acceso remoto seguro |
| **DNS** | BIND9 | 53 | TCP+UDP | ✅ Activo | Todos | Resolución de nombres |
| **HTTP** | Nginx | 80 | TCP | ✅ Activo | Todos | Servidor web |
| **DHCPv6 Server** | isc-dhcp-server6 | 547 | UDP | ✅ Activo | Todos | Asignación de IPs |
| **DHCPv6 Client** | - | 546 | UDP | ✅ Activo | Todos | Recepción de IPs |
| **NFS** | nfs-kernel-server | 2049 | TCP | ✅ Activo | LAN | Compartir archivos |
| **FTP Pasivo** | vsftpd | 21000-21010 | TCP | ⚠️ Opcional | LAN | Transferencia archivos |
| **Samba** | smbd | 139, 445 | TCP | ⚠️ Opcional | LAN | Compartir con Windows |

### Puertos Bloqueados (Firewall)

| Puerto | Protocolo | Servicio | Estado | Razón |
|--------|-----------|----------|--------|-------|
| 23 | TCP | Telnet | ❌ Bloqueado | Inseguro |
| 21 | TCP | FTP Control | ❌ Bloqueado | Solo modo pasivo |
| 25 | TCP | SMTP | ❌ Bloqueado | No es servidor de correo |
| 3306 | TCP | MySQL | ❌ Bloqueado | Base de datos no expuesta |
| 5432 | TCP | PostgreSQL | ❌ Bloqueado | Base de datos no expuesta |
| 3389 | TCP | RDP | ❌ Bloqueado | No es servidor Windows |

---

## 5️⃣ TABLA DE REGLAS DE FIREWALL (UFW)

| # | Puerto | Protocolo | Acción | Origen | Destino | Comentario |
|---|--------|-----------|--------|--------|---------|------------|
| 1 | 22 | TCP | LIMIT | Any | Any | SSH con rate limiting |
| 2 | 53 | TCP | ALLOW | Any | Any | DNS TCP |
| 3 | 53 | UDP | ALLOW | Any | Any | DNS UDP |
| 4 | 80 | TCP | ALLOW | Any | Any | HTTP Web Server |
| 5 | 546 | UDP | ALLOW | Any | Any | DHCPv6 Client |
| 6 | 547 | UDP | ALLOW | Any | Any | DHCPv6 Server |
| 7 | 21000:21010 | TCP | ALLOW | Any | Any | FTP Passive Ports |
| 8 | 22 | TCP | ALLOW | Admin VMs | Server | SSH desde Admin |
| 9 | 22 | TCP | DENY | Non-Admin VMs | Server | Bloquear SSH desde Auditor/Cliente |

### Políticas por Defecto

| Dirección | Política | Descripción |
|-----------|----------|-------------|
| **Incoming** | DENY | Todo bloqueado por defecto |
| **Outgoing** | ALLOW | Todo permitido |
| **Forward** | DENY | No hay reenvío |

---

## 6️⃣ TABLA DE RUTAS IPv6

### Servidor Ubuntu

| Destino | Gateway | Interfaz | Métrica | Tipo |
|---------|---------|----------|---------|------|
| ::/0 | fe80::... (ISP) | ens33 | 100 | Default (Internet) |
| 2025:db8:10::/64 | - | ens34 | 0 | Connected |
| ::1/128 | - | lo | 0 | Local |
| fe80::/64 | - | ens33 | 256 | Link-local |
| fe80::/64 | - | ens34 | 256 | Link-local |

### Clientes

| Destino | Gateway | Interfaz | Métrica | Tipo |
|---------|---------|----------|---------|------|
| ::/0 | 2025:db8:10::1 | ens33/Ethernet | 100 | Default |
| 2025:db8:10::/64 | - | ens33/Ethernet | 0 | Connected |
| ::1/128 | - | lo/Loopback | 0 | Local |
| fe80::/64 | - | ens33/Ethernet | 256 | Link-local |

---

## 7️⃣ TABLA DE REGISTROS DNS

### Zona Directa: gamecenter.lan

| Nombre | Tipo | Valor | TTL | Descripción |
|--------|------|-------|-----|-------------|
| @ | SOA | ns1.gamecenter.lan. | 86400 | Start of Authority |
| @ | NS | ns1.gamecenter.lan. | 86400 | Name Server |
| @ | AAAA | 2025:db8:10::2 | 3600 | Dominio raíz |
| servidor | AAAA | 2025:db8:10::2 | 3600 | Servidor principal |
| ns1 | AAAA | 2025:db8:10::2 | 3600 | Name server |
| dns | AAAA | 2025:db8:10::2 | 3600 | Alias DNS |
| www | CNAME | servidor | 3600 | Alias web |
| web | CNAME | servidor | 3600 | Alias web alternativo |
| ftp | CNAME | servidor | 3600 | Alias FTP |
| nfs | CNAME | servidor | 3600 | Alias NFS |

### Zona Inversa: 0.1.0.8.b.d.5.2.0.2.ip6.arpa

| Dirección | Tipo | Nombre | TTL |
|-----------|------|--------|-----|
| 2.0.0.0... | PTR | servidor.gamecenter.lan. | 3600 |

### Registros Dinámicos (DDNS)

Los clientes se registran automáticamente cuando obtienen IP por DHCP:

| Hostname | IP Asignada | Tipo | Actualización |
|----------|-------------|------|---------------|
| ubuntu-desktop-1 | 2025:db8:10::100 | AAAA | Automática (DDNS) |
| windows11-1 | 2025:db8:10::110 | AAAA | Automática (DDNS) |

---

## 8️⃣ TABLA DE CONFIGURACIÓN DHCP

### Parámetros Globales

| Parámetro | Valor | Descripción |
|-----------|-------|-------------|
| **Subnet** | 2025:db8:10::/64 | Red a servir |
| **Range** | 2025:db8:10::10 - ::FFFF | Rango de IPs |
| **Default Lease Time** | 600 segundos | Tiempo de préstamo por defecto |
| **Max Lease Time** | 7200 segundos | Tiempo máximo de préstamo |
| **DNS Servers** | 2025:db8:10::2 | Servidor DNS |
| **Domain Name** | gamecenter.lan | Dominio de búsqueda |

### Opciones DHCPv6

| Opción | Código | Valor | Descripción |
|--------|--------|-------|-------------|
| domain-name-servers | 23 | 2025:db8:10::2 | DNS |
| domain-search | 24 | gamecenter.lan | Dominio de búsqueda |

---

## 9️⃣ TABLA DE CONECTIVIDAD ENTRE HOSTS

### Matriz de Conectividad

| Origen ↓ / Destino → | Servidor | Ubuntu Desktop | Windows 11 | Internet |
|----------------------|----------|----------------|------------|----------|
| **Servidor** | ✅ Local | ✅ Ping, SSH, HTTP | ✅ Ping, HTTP | ✅ NAT64 |
| **Ubuntu Desktop (Admin)** | ✅ Ping, SSH, HTTP, DNS | ✅ Ping | ✅ Ping | ✅ Proxy |
| **Ubuntu Desktop (Auditor)** | ✅ Ping, HTTP, DNS | ✅ Ping | ✅ Ping | ✅ Proxy |
| **Ubuntu Desktop (Cliente)** | ✅ Ping, HTTP, DNS | ✅ Ping | ✅ Ping | ✅ Proxy |
| **Windows 11 (Admin)** | ✅ Ping, SSH, HTTP, DNS | ✅ Ping | ✅ Ping | ✅ Proxy |
| **Windows 11 (Auditor)** | ✅ Ping, HTTP, DNS | ✅ Ping | ✅ Ping | ✅ Proxy |
| **Windows 11 (Cliente)** | ✅ Ping, HTTP, DNS | ✅ Ping | ✅ Ping | ✅ Proxy |

**Leyenda:**
- ✅ = Permitido y funcional
- ❌ = Bloqueado por firewall
- ⚠️ = Limitado o condicional

---

## 🔟 TABLA DE ANCHO DE BANDA Y LATENCIA

### Latencias Esperadas

| Origen | Destino | Latencia Promedio | Jitter | Pérdida de Paquetes |
|--------|---------|-------------------|--------|---------------------|
| Cliente → Servidor | LAN | < 1 ms | < 0.5 ms | 0% |
| Cliente → Internet | NAT64 | 10-50 ms | < 5 ms | < 1% |
| Servidor → Internet | Directo | 5-30 ms | < 3 ms | < 0.5% |

### Ancho de Banda

| Enlace | Velocidad | Tipo | Uso |
|--------|-----------|------|-----|
| ens33 (WAN) | 1 Gbps | Ethernet | Internet |
| ens34 (LAN) | 1 Gbps | Ethernet | Red interna |
| Cliente → Servidor | 1 Gbps | Ethernet | Servicios locales |

---

## 1️⃣1️⃣ COMANDOS DE VERIFICACIÓN

### En el Servidor

```bash
# Ver configuración de red
ip -6 addr show ens34
ip -6 route show

# Ver servicios activos
sudo systemctl status bind9
sudo systemctl status isc-dhcp-server6
sudo systemctl status nginx

# Ver firewall
sudo ufw status verbose

# Ver conexiones activas
sudo ss -tulnp | grep -E ":(22|53|80|547)"

# Ver leases DHCP
sudo cat /var/lib/dhcp/dhcpd6.leases

# Ver zona DNS
sudo cat /var/lib/bind/db.gamecenter.lan
```

### En los Clientes

```bash
# Ubuntu
ip -6 addr show
ip -6 route show
ping6 2025:db8:10::2
dig @2025:db8:10::2 gamecenter.lan AAAA
curl http://gamecenter.lan

# Windows (PowerShell)
ipconfig
Get-NetIPAddress -AddressFamily IPv6
Test-Connection 2025:db8:10::2
Resolve-DnsName gamecenter.lan -Server 2025:db8:10::2
```

---

## 1️⃣2️⃣ DIAGRAMA DE RED ASCII

```
                    INTERNET (IPv4)
                          │
                          │ ens33 (DHCP IPv4)
                          │
                    ┌─────▼─────┐
                    │  SERVIDOR │
                    │  Ubuntu   │
                    │  ::2      │
                    └─────┬─────┘
                          │ ens34 (2025:db8:10::2/64)
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
        │         RED IPv6: 2025:db8:10::/64│
        │         Gateway: ::1              │
        │         DHCP: ::10 - ::FFFF       │
        │                                   │
   ┌────▼────┐      ┌────▼────┐      ┌────▼────┐
   │ Ubuntu  │      │ Ubuntu  │      │Windows11│
   │ Desktop │      │ Desktop │      │         │
   │  Admin  │      │ Auditor │      │  Admin  │
   │  ::100  │      │  ::101  │      │  ::110  │
   └─────────┘      └─────────┘      └─────────┘
```

---

**Fecha:** Noviembre 2025  
**Proyecto:** Game Center con IPv6  
**Curso:** Sistemas Operativos
