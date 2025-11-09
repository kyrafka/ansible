# Rol: DHCPv6

Servidor DHCPv6 para asignación automática de IPs a las VMs.

## ¿Qué hace?

- Instala y configura ISC DHCP Server (IPv6)
- Asigna IPs automáticamente desde un rango
- Proporciona DNS y gateway a las VMs
- Configura leases (arrendamientos) de IPs

## Configuración DHCP

```yaml
# En group_vars/all.yml
network_config:
  dhcp_range_start: "2025:db8:10::100"
  dhcp_range_end: "2025:db8:10::200"
  ipv6_gateway: "2025:db8:10::1"
  domain_name: "gamecenter.local"
```

## Rango de IPs asignadas

- **Servidor:** 2025:db8:10::2 (estática)
- **VMs (DHCP):** 2025:db8:10::100 a 2025:db8:10::200
- **Total:** 101 IPs disponibles

## Información proporcionada a las VMs

- **IP:** Del rango configurado
- **Gateway:** 2025:db8:10::1
- **DNS:** 2025:db8:10::2 (el servidor)
- **Dominio:** gamecenter.local

## Ejecutar solo este rol

```bash
./run.sh dhcp
```

## Verificar funcionamiento

```bash
# Ver estado del servicio
systemctl status isc-dhcp-server6

# Ver leases activos
cat /var/lib/dhcp/dhcpd6.leases

# Ver logs
tail -f /var/log/dhcp/dhcpd6.log

# Ver configuración
cat /etc/dhcp/dhcpd6.conf
```

## Archivos creados

- `/etc/dhcp/dhcpd6.conf` - Configuración principal
- `/var/lib/dhcp/dhcpd6.leases` - IPs asignadas
- `/var/log/dhcp/dhcpd6.log` - Logs del servidor

## Puertos abiertos

- **547/udp** - DHCPv6 Server
- **546/udp** - DHCPv6 Client

## Troubleshooting

Si el servicio no arranca:

```bash
# Ver errores
journalctl -u isc-dhcp-server6 -n 50

# Verificar sintaxis
dhcpd -6 -t -cf /etc/dhcp/dhcpd6.conf

# Verificar interfaz
ip -6 addr show ens34
```
