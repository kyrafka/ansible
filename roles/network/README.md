# Rol: Network

Configuración de red IPv6 y NAT66 para el servidor.

## ¿Qué hace?

- Configura interfaz **ens33** con IPv4 DHCP (internet)
- Configura interfaz **ens34** con IPv6 estática (red interna)
- Habilita IP forwarding (IPv4 e IPv6)
- Configura NAT66 para que las VMs salgan a internet
- Aplica configuración de red con netplan

## Configuración de red

```yaml
# En group_vars/all.yml
network_config:
  ipv6_network: "2025:db8:10::/64"
  ipv6_gateway: "2025:db8:10::1"
  server_ipv6: "2025:db8:10::2"
  internal_interface: "ens34"
  external_interface: "ens33"
```

## Interfaces configuradas

### ens33 (Internet)
- IPv4: DHCP automático
- Propósito: Salida a internet

### ens34 (Red interna)
- IPv6: 2025:db8:10::2/64
- Propósito: Red de VMs

## NAT66

El servidor actúa como gateway para que las VMs con IPv6 puedan salir a internet:

```
VMs (2025:db8:10::X) → Servidor (ens34) → NAT66 → Internet (ens33)
```

## Ejecutar solo este rol

```bash
./run.sh network
```

## Verificar configuración

```bash
# Ver interfaces
ip -6 addr show

# Ver rutas IPv6
ip -6 route

# Ver reglas de NAT
ip6tables -t nat -L -v

# Verificar forwarding
sysctl net.ipv6.conf.all.forwarding
```

## Archivos modificados

- `/etc/netplan/01-netcfg.yaml` - Configuración de red
- `/etc/sysctl.d/99-ipv6-forwarding.conf` - IP forwarding
