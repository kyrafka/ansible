# ⚠️ NOTA IMPORTANTE: CONFIGURACIÓN DE RED

## Tu configuración usa un archivo diferente

---

## ✅ ARCHIVO CORRECTO

Tu servidor usa:
```
/etc/netplan/99-server-network.yaml
```

**NO usa:**
```
/etc/netplan/50-cloud-init.yaml  ❌
```

---

## 🔍 TU CONFIGURACIÓN ACTUAL

Según tu captura de pantalla:

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
        - 2025:db8:10::1/64   ← Gateway
        - 2025:db8:10::2/64   ← Servidor
```

---

## 🎯 CARACTERÍSTICAS CLAVE

### Dos IPs en ens34:

1. **2025:db8:10::1/64** - Gateway
   - Actúa como puerta de enlace para los clientes
   - Los clientes usan esta IP como default gateway

2. **2025:db8:10::2/64** - Servidor
   - Servicios DNS, DHCP, Web escuchan aquí
   - Los clientes se conectan a esta IP para servicios

### Ventajas de esta configuración:

✅ Separación lógica de funciones  
✅ Gateway y servidor en IPs diferentes  
✅ Más claro para troubleshooting  
✅ Permite futuras expansiones  

---

## 📋 COMANDOS ACTUALIZADOS

### Ver tu configuración:

```bash
# Ver archivo correcto
sudo cat /etc/netplan/99-server-network.yaml

# Ver las dos IPs en ens34
ip -6 addr show ens34 | grep "2025:db8:10"

# Debería mostrar:
# inet6 2025:db8:10::1/64 scope global
# inet6 2025:db8:10::2/64 scope global
```

---

## ✅ SCRIPTS ACTUALIZADOS

Los siguientes scripts ya están actualizados para buscar el archivo correcto:

1. ✅ `scripts/diagnostics/show-server-config.sh`
   - Busca `/etc/netplan/99-server-network.yaml` primero
   - Fallback a `50-cloud-init.yaml` si no existe
   - Muestra las dos IPs de ens34

2. ✅ `docs/CONFIGURACION-RED-SERVIDOR.md`
   - Documento nuevo con tu configuración exacta
   - Explicación de las dos IPs
   - Comandos de verificación

---

## 📸 PARA LA DEMOSTRACIÓN

### Mostrar configuración de red:

```bash
# 1. Mostrar archivo
sudo cat /etc/netplan/99-server-network.yaml

# 2. Mostrar interfaces
ip -6 addr show ens34

# 3. Verificar las dos IPs
ping6 -c 2 2025:db8:10::1
ping6 -c 2 2025:db8:10::2

# 4. Mostrar que los servicios escuchan en ::2
sudo ss -tulnp | grep "2025:db8:10::2"
```

---

## 🎯 PARA LA RÚBRICA

**Tabla de configuración de red:**

| Interfaz | IP | Máscara | Uso |
|----------|-----|---------|-----|
| ens33 | DHCP IPv4 | /24 | Internet (WAN) |
| ens34 | 2025:db8:10::1 | /64 | Gateway |
| ens34 | 2025:db8:10::2 | /64 | Servidor (servicios) |

**Servicios escuchando en ::2:**
- DNS (BIND9): puerto 53
- DHCP: puerto 547
- Web (Nginx): puerto 80
- SSH: puerto 22

---

## ✅ TODO ESTÁ ACTUALIZADO

No necesitas cambiar nada más. Los scripts ya buscan el archivo correcto y muestran tu configuración exacta.

---

**Fecha:** Noviembre 2025  
**Actualizado:** Para reflejar tu configuración real
