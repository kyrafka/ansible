# ════════════════════════════════════════════════════════════════
# ORDEN CORRECTO DE CONFIGURACIÓN DEL SERVIDOR
# ════════════════════════════════════════════════════════════════

## ⚠️ IMPORTANTE: Orden de Ejecución

El orden es crítico porque algunos servicios dependen de otros:

1. **DNS debe ir ANTES de DHCP** → El DHCP necesita la clave DDNS que genera el DNS
2. **Firewall puede ir al final** → Para no bloquear la configuración

## 📋 Orden Correcto

```bash
# 1. Paquetes base
bash scripts/run/run-common.sh

# 2. Configuración de red IPv6 + NAT
bash scripts/run/run-network.sh

# 3. DNS (BIND9) - Genera la clave DDNS
bash scripts/run/run-dns.sh

# 4. DHCP (DHCPv6) - Usa la clave del DNS
bash scripts/run/run-dhcp.sh

# 5. Firewall (UFW) - Ejecutar 2 veces si falla
bash scripts/run/run-firewall.sh
bash scripts/run/run-firewall.sh  # Segunda vez si la primera falló

# 6. Almacenamiento (NFS)
bash scripts/run/run-storage.sh
```

## 🔍 Validar Todo

```bash
bash scripts/run/validate-all.sh
```

## ❓ ¿Por qué este orden?

### DNS antes de DHCP
- El DNS genera `/etc/bind/dhcp-key.key`
- El DHCP copia esa clave a `/etc/dhcp/dhcp-key.key`
- Esto permite que DHCP actualice registros DNS automáticamente (DDNS)

### Firewall al final
- Si configuras el firewall primero, puede bloquear las conexiones
- Es mejor configurar todos los servicios y luego protegerlos

### Network al principio
- IPv6 y NAT deben estar configurados antes de los servicios
- Los servicios necesitan la red funcionando

## 🚨 Si ejecutaste en orden incorrecto

Si ejecutaste DHCP antes que DNS:

```bash
# 1. Ejecuta DNS para generar la clave
bash scripts/run/run-dns.sh

# 2. Vuelve a ejecutar DHCP para que copie la clave
bash scripts/run/run-dhcp.sh

# 3. Valida que todo funcione
bash scripts/run/validate-dhcp.sh
bash scripts/run/validate-dns.sh
```

## 📝 Notas

- **DDNS es opcional**: Si no ejecutas DNS primero, DHCP funcionará pero sin actualización dinámica de DNS
- **Firewall puede fallar la primera vez**: Es normal, ejecútalo dos veces
- **Validaciones**: Siempre ejecuta las validaciones después de cada paso

## 🎯 Script Todo-en-Uno (Recomendado)

Si prefieres ejecutar todo de una vez:

```bash
bash scripts/server/setup-server.sh
```

Este script ejecuta todo en el orden correcto automáticamente.

## ════════════════════════════════════════════════════════════════
