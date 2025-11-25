# 🌐 CONFIGURACIÓN DE RED DEL SERVIDOR

## Archivo: /etc/netplan/99-server-network.yaml

---

## 📋 CONFIGURACIÓN ACTUAL

Basado en tu captura de pantalla, tu servidor tiene esta configuración:

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ens33:
      # WAN - Internet
      dhcp4: true
      dhcp6: false
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
          - 2001:4860:4860::8888
    
    ens34:
      # LAN - Red interna IPv6
      dhcp4: false
      dhcp6: false
      accept-ra: false
      ipv6-privacy: false
      addresses:
        - 2025:db8:10::1/64
        - 2025:db8:10::2/64
```

---

## 🔍 ANÁLISIS DE LA CONFIGURACIÓN

### Interfaz ens33 (WAN - Internet)

| Parámetro | Valor | Descripción |
|-----------|-------|-------------|
| **dhcp4** | true | Obtiene IPv4 automáticamente |
| **dhcp6** | false | No usa DHCPv6 para esta interfaz |
| **nameservers** | 8.8.8.8, 8.8.4.4, 2001:4860:4860::8888 | DNS de Google |
| **Uso** | Conexión a Internet | Salida a internet para el servidor |

### Interfaz ens34 (LAN - Red Interna)

| Parámetro | Valor | Descripción |
|-----------|-------|-------------|
| **dhcp4** | false | IP estática IPv4 |
| **dhcp6** | false | IP estática IPv6 |
| **accept-ra** | false | No acepta Router Advertisements |
| **ipv6-privacy** | false | No usa direcciones temporales |
| **addresses** | 2025:db8:10::1/64<br>2025:db8:10::2/64 | Dos IPs IPv6 estáticas |
| **Uso** | Red interna | Sirve a las VMs clientes |

---

## 🎯 EXPLICACIÓN DE LAS DOS IPs

### ¿Por qué dos direcciones IPv6 en ens34?

```
- 2025:db8:10::1/64   → Gateway (router virtual)
- 2025:db8:10::2/64   → Servidor (servicios)
```

**Razón:**
- **::1** actúa como gateway para los clientes
- **::2** es la IP del servidor para DNS, DHCP, Web, etc.

**Ventaja:**
- Separación lógica de funciones
- Los clientes usan ::1 como gateway
- Los servicios escuchan en ::2

---

## 📊 TABLA DE INTERFACES

| Interfaz | Tipo | IPv4 | IPv6 | Gateway | Uso |
|----------|------|------|------|---------|-----|
| **ens33** | WAN | DHCP | - | Auto | Internet |
| **ens34** | LAN | - | 2025:db8:10::1/64<br>2025:db8:10::2/64 | - | Red interna |
| **lo** | Loopback | 127.0.0.1 | ::1 | - | Local |

---

## 🔧 COMANDOS DE VERIFICACIÓN

### Ver configuración actual:

```bash
# Ver archivo de configuración
sudo cat /etc/netplan/99-server-network.yaml

# Ver interfaces activas
ip -6 addr show

# Ver rutas IPv6
ip -6 route show

# Ver configuración de ens34 específicamente
ip -6 addr show ens34
```

### Resultado esperado de `ip -6 addr show ens34`:

```
3: ens34: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    inet6 2025:db8:10::1/64 scope global
       valid_lft forever preferred_lft forever
    inet6 2025:db8:10::2/64 scope global
       valid_lft forever preferred_lft forever
    inet6 fe80::xxxx:xxxx:xxxx:xxxx/64 scope link
       valid_lft forever preferred_lft forever
```

---

## 🔄 APLICAR CAMBIOS

Si modificas el archivo de configuración:

```bash
# Probar configuración (no aplica cambios)
sudo netplan try

# Aplicar configuración
sudo netplan apply

# Ver estado
sudo networkctl status
```

---

## 🌐 FLUJO DE RED

```
┌─────────────────────────────────────────────────────────┐
│                      INTERNET                           │
└────────────────────┬────────────────────────────────────┘
                     │
                     │ ens33 (DHCP IPv4)
                     │
              ┌──────▼──────┐
              │   SERVIDOR  │
              │   Ubuntu    │
              │             │
              │  ens33: WAN │ → Internet
              │  ens34: LAN │ → Red interna
              └──────┬──────┘
                     │ ens34 (2025:db8:10::1/64, ::2/64)
                     │
        ┌────────────┼────────────┐
        │                         │
   ┌────▼────┐              ┌────▼────┐
   │ Ubuntu  │              │Windows11│
   │ Desktop │              │         │
   │ ::100   │              │ ::110   │
   └─────────┘              └─────────┘
```

---

## 📝 CONFIGURACIÓN COMPLETA RECOMENDADA

Si quieres agregar más opciones:

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ens33:
      # WAN - Internet
      dhcp4: true
      dhcp6: false
      nameservers:
        addresses: