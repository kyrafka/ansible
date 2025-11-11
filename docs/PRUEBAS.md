# 🧪 Pruebas y Evidencias del Sistema

Este documento contiene todas las pruebas realizadas y evidencias del funcionamiento del sistema.

---

## 📋 Índice de Pruebas

1. [Pruebas de Red IPv6](#pruebas-de-red-ipv6)
2. [Pruebas de DNS](#pruebas-de-dns)
3. [Pruebas de DHCPv6](#pruebas-de-dhcpv6)
4. [Pruebas de Servidor Web](#pruebas-de-servidor-web)
5. [Pruebas de Firewall](#pruebas-de-firewall)
6. [Pruebas de Conectividad](#pruebas-de-conectividad)

---

## 🌐 Pruebas de Red IPv6

### Configuración de Interfaces

**Comando:**
```bash
ip -6 addr show
```

**Resultado esperado:**
- ens33: IP de Internet (NAT)
- ens34: `2025:db8:10::2/64` (red interna)

**Evidencia:**

![Interfaces de Red](../images/configuracion/interfaces-red.png)

### IPv6 Forwarding

**Comando:**
```bash
cat /proc/sys/net/ipv6/conf/all/forwarding
```

**Resultado esperado:** `1` (habilitado)

### Prueba de Conectividad IPv6

**Comando:**
```bash
ping6 -c 3 2025:db8:10::2
```

**Evidencia:**

![Ping IPv6](../images/pruebas/ping-ipv6.png)

---

## 🔍 Pruebas de DNS

### Resolución de Dominio Raíz

**Comando:**
```bash
dig @localhost gamecenter.local AAAA +short
```

**Resultado esperado:** `2025:db8:10::2`

**Evidencia:**

![Resolución DNS](../images/pruebas/dns-resolucion.png)

### Resolución de Subdominios

**Comandos:**
```bash
dig @localhost servidor.gamecenter.local AAAA +short
dig @localhost www.gamecenter.local AAAA +short
dig @localhost web.gamecenter.local AAAA +short
```

**Resultado esperado:** Todos resuelven a `2025:db8:10::2`

### Prueba desde Cliente

**Comando (desde Ubuntu Desktop):**
```bash
nslookup gamecenter.local
ping6 -c 3 gamecenter.local
```

**Evidencia:**

![DNS desde Cliente](../images/pruebas/dns-cliente.png)

---

## 📡 Pruebas de DHCPv6

### Asignación de IP

**Comando (en cliente):**
```bash
ip -6 addr show ens33
```

**Resultado esperado:** IP en el rango `2025:db8:10::10` - `::FFFF`

**Evidencia:**

![Asignación DHCP](../images/pruebas/dhcp-asignacion.png)

### Logs del Servidor DHCPv6

**Comando:**
```bash
sudo journalctl -u isc-dhcp-server6 -n 50
```

**Resultado esperado:** Mensajes de "Sending Reply" con IPs asignadas

**Evidencia:**

![Logs DHCP](../images/pruebas/dhcp-logs.png)

### Configuración DNS Automática

**Comando (en cliente):**
```bash
resolvectl status
```

**Resultado esperado:** DNS configurado como `2025:db8:10::2`

---

## 🌐 Pruebas de Servidor Web

### Acceso por Nombre de Dominio

**Comando:**
```bash
curl http://gamecenter.local
```

**Resultado esperado:** Código HTML de la página de bienvenida

**Evidencia:**

![Acceso Web por Nombre](../images/pruebas/web-acceso-nombre.png)

### Acceso por Alias

**URLs probadas:**
- `http://www.gamecenter.local`
- `http://web.gamecenter.local`
- `http://servidor.gamecenter.local`

**Evidencia:**

![Acceso Web WWW](../images/pruebas/web-acceso-www.png)

### Estado del Servicio

**Comando:**
```bash
systemctl status nginx
```

**Resultado esperado:** `active (running)`

**Evidencia:**

![Estado Nginx](../images/servicios/nginx-estado.png)

---

## 🛡️ Pruebas de Firewall

### Reglas Configuradas

**Comando:**
```bash
sudo ufw status verbose
```

**Resultado esperado:**
- Puerto 22/tcp (SSH) - LIMIT
- Puerto 53/tcp+udp (DNS) - ALLOW
- Puerto 80/tcp (HTTP) - ALLOW
- Puerto 546-547/udp (DHCPv6) - ALLOW

**Evidencia:**

![Reglas UFW](../images/servicios/firewall-reglas.png)

### Estado de fail2ban

**Comando:**
```bash
sudo fail2ban-client status
```

**Resultado esperado:** Jails activos (sshd, nginx-http-auth, etc.)

**Evidencia:**

![fail2ban Status](../images/servicios/fail2ban-jails.png)

---

## 🔗 Pruebas de Conectividad

### Conectividad Servidor → Cliente

**Comando (desde servidor):**
```bash
ping6 -c 3 2025:db8:10::885d  # IP del cliente
```

**Evidencia:**

![Ping Servidor a Cliente](../images/pruebas/ping-servidor-cliente.png)

### Conectividad Cliente → Servidor

**Comando (desde cliente):**
```bash
ping6 -c 3 servidor.gamecenter.local
```

**Evidencia:**

![Ping Cliente a Servidor](../images/pruebas/ping-cliente-servidor.png)

### Acceso SSH

**Comando:**
```bash
ssh ubuntu@servidor.gamecenter.local
```

**Evidencia:**

![Conexión SSH](../images/pruebas/ssh-conexion.png)

---

## 📊 Resultados de Validación

### Validación de Red

**Comando:**
```bash
bash scripts/run/validate-network.sh
```

**Evidencia:**

![Validación Network](../images/pruebas/validacion-network.png)

### Validación de DNS

**Comando:**
```bash
bash scripts/run/validate-dns.sh
```

**Evidencia:**

![Validación DNS](../images/pruebas/validacion-dns.png)

### Validación de Web

**Comando:**
```bash
bash scripts/run/validate-web.sh
```

**Evidencia:**

![Validación Web](../images/pruebas/validacion-web.png)

---

## 🔬 Diagnósticos Avanzados

### Diagnóstico Completo de DNS

**Comando:**
```bash
bash scripts/diagnostics/diagnose-dns.sh
```

**Evidencia:**

![Diagnóstico DNS](../images/pruebas/diagnostico-dns.png)

### Prueba de Todos los Registros DNS

**Comando:**
```bash
bash scripts/diagnostics/test-dns-records.sh
```

**Evidencia:**

![Test DNS Records](../images/pruebas/test-dns-records.png)

---

## ✅ Resumen de Pruebas

| Componente | Estado | Observaciones |
|------------|--------|---------------|
| Red IPv6 | ✅ Funcionando | Interfaces configuradas correctamente |
| DNS (BIND9) | ⚠️ En desarrollo | Algunos registros pendientes de validación |
| DHCPv6 | ✅ Funcionando | Asignación dinámica operativa |
| Nginx | ✅ Funcionando | Accesible por nombre de dominio |
| Firewall | ✅ Funcionando | Reglas aplicadas correctamente |
| fail2ban | ✅ Funcionando | Jails activos |

---

## 📝 Notas

- Todas las pruebas fueron realizadas en un entorno de laboratorio
- Las capturas de pantalla muestran el estado real del sistema
- Los comandos pueden ser reproducidos para verificar el funcionamiento

---

**Última actualización:** Noviembre 2025
