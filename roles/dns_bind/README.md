# Rol: DNS (BIND9)

Servidor DNS autoritativo para la red interna.

## ¿Qué hace?

- Instala y configura BIND9
- Crea zona directa (gamecenter.local)
- Crea zona inversa (IPv6)
- Configura resolución DNS para VMs
- Habilita logs de consultas DNS

## Configuración DNS

```yaml
# En group_vars/all.yml
network_config:
  domain_name: "gamecenter.local"
  ipv6_network: "2025:db8:10::/64"
  dns_forwarders:
    - "8.8.8.8"
    - "8.8.4.4"
```

## Zonas DNS

### Zona directa: gamecenter.local
Resuelve nombres a IPs:
```
server.gamecenter.local → 2025:db8:10::2
```

### Zona inversa: 0.1.8.b.d.5.2.0.2.ip6.arpa
Resuelve IPs a nombres:
```
2025:db8:10::2 → server.gamecenter.local
```

## Registros DNS creados

- **NS:** Servidor DNS autoritativo
- **A/AAAA:** Servidor (IPv6)
- **PTR:** Resolución inversa

## Ejecutar solo este rol

```bash
./run.sh dns
```

## Verificar funcionamiento

```bash
# Ver estado del servicio
systemctl status named

# Probar resolución directa
dig @localhost server.gamecenter.local AAAA

# Probar resolución inversa
dig @localhost -x 2025:db8:10::2

# Ver logs
tail -f /var/log/dns/queries.log
```

## Archivos creados

- `/etc/bind/named.conf.options` - Opciones de BIND9
- `/etc/bind/named.conf.local` - Zonas locales
- `/etc/bind/zones/db.gamecenter.local` - Zona directa
- `/etc/bind/zones/db.2025.db8.10` - Zona inversa
- `/var/log/dns/queries.log` - Log de consultas

## Puertos abiertos

- **53/tcp** - DNS sobre TCP
- **53/udp** - DNS sobre UDP
