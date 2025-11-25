# 🎯 DEMOSTRACIÓN MANUAL DEL SERVIDOR

## Cómo demostrar que cada servicio funciona

---

## 📋 PARTE 1: EJECUTAR SCRIPTS AUTOMÁTICOS

### Script 1: Mostrar Configuraciones

```bash
cd ~/ansible-gestion-despliegue
bash scripts/diagnostics/show-server-config.sh
```

**Qué hace:**
- Muestra TODAS las configuraciones del servidor
- Archivos de configuración de cada servicio
- Estado de servicios
- Usuarios y permisos
- Logs recientes

**Duración:** ~5 minutos (con pausas)

**Capturas necesarias:**
- Estado de cada servicio
- Configuraciones importantes
- Puertos abiertos

---

### Script 2: Probar Funcionamiento

```bash
bash scripts/diagnostics/test-server-functionality.sh
```

**Qué hace:**
- Prueba que cada servicio FUNCIONA
- Verifica conectividad
- Prueba DNS, DHCP, Web, SSH
- Genera reporte de éxito/fallo

**Duración:** ~3 minutos

**Capturas necesarias:**
- Resultados de cada prueba
- Resumen final con porcentaje

---

## 📋 PARTE 2: DEMOSTRACIONES MANUALES

### 1️⃣ DNS (BIND9) - Demostrar que funciona

#### A. Verificar que el servicio está activo

```bash
sudo systemctl status bind9
```

**Captura esperada:**
```
● bind9.service - BIND Domain Name Server
   Loaded: loaded
   Active: active (running)
```

#### B. Probar resolución DNS desde el servidor

```bash
# Resolver el dominio principal
dig @localhost gamecenter.lan AAAA +short

# Debería mostrar:
2025:db8:10::2
```

```bash
# Resolver un CNAME
dig @localhost www.gamecenter.lan AAAA +short

# Debería mostrar:
2025:db8:10::2
```

```bash
# Resolución inversa
dig @localhost -x 2025:db8:10::2 +short

# Debería mostrar:
servidor.gamecenter.lan.
```

#### C. Probar desde un cliente

**En Ubuntu Desktop o Windows:**

```bash
# Ubuntu
dig @2025:db8:10::2 gamecenter.lan AAAA

# Windows
nslookup gamecenter.lan 2025:db8:10::2
```

**Captura:** Debe resolver correctamente

#### D. Ver logs en tiempo real

```bash
# Terminal 1: Ver logs
sudo journalctl -u bind9 -f

# Terminal 2: Hacer consulta DNS
dig @localhost gamecenter.lan AAAA
```

**Captura:** Logs mostrando la consulta

---

### 2️⃣ DHCP IPv6 - Demostrar que funciona

#### A. Verificar servicio activo

```bash
sudo systemctl status isc-dhcp-server6
```

**Captura esperada:**
```
● isc-dhcp-server6.service - ISC DHCP IPv6 server
   Active: active (running)
```

#### B. Ver leases asignados

```bash
sudo cat /var/lib/dhcp/dhcpd6.leases
```

**Captura:** Debe mostrar IPs asignadas a clientes

#### C. Ver logs de asignaciones

```bash
sudo journalctl -u isc-dhcp-server6 -n 50
```

**Buscar líneas como:**
```
DHCPREQUEST for 2025:db8:10::100
DHCPACK on 2025:db8:10::100
```

#### D. Demostrar desde un cliente

**En Ubuntu Desktop:**

```bash
# Ver IP asignada
ip -6 addr show | grep "2025:db8:10"

# Renovar IP
sudo dhclient -6 -r ens33
sudo dhclient -6 ens33

# Ver nueva IP asignada
ip -6 addr show | grep "2025:db8:10"
```

**Captura:** IP asignada automáticamente

---

### 3️⃣ Servidor Web (Nginx) - Demostrar que funciona

#### A. Verificar servicio activo

```bash
sudo systemctl status nginx
```

#### B. Probar desde el servidor

```bash
# Acceso local
curl http://localhost

# Acceso por IPv6
curl -6 http://[2025:db8:10::2]

# Acceso por dominio
curl http://gamecenter.lan
```

**Captura:** Debe mostrar el HTML de la página

#### C. Probar desde navegador (cliente)

**En Ubuntu Desktop o Windows:**

1. Abrir navegador
2. Ir a: `http://gamecenter.lan`
3. Debe mostrar la página de bienvenida

**Captura:** Navegador mostrando la página

#### D. Ver logs de acceso en tiempo real

```bash
# Terminal 1: Ver logs
sudo tail -f /var/log/nginx/access.log

# Terminal 2 o navegador: Acceder a la página
curl http://gamecenter.lan
```

**Captura:** Logs mostrando el acceso

#### E. Ver estadísticas

```bash
# Ver conexiones activas
sudo ss -tulnp | grep :80

# Ver procesos de Nginx
ps aux | grep nginx
```

---

### 4️⃣ Firewall (UFW) - Demostrar que funciona

#### A. Ver estado y reglas

```bash
sudo ufw status verbose
```

**Captura:** Debe mostrar:
- Status: active
- Default: deny (incoming), allow (outgoing)
- Reglas para puertos 22, 53, 80, 547

#### B. Ver reglas numeradas

```bash
sudo ufw status numbered
```

#### C. Probar que bloquea puertos no autorizados

```bash
# Desde un cliente, intentar conectar a puerto cerrado
nc -6 -zv 2025:db8:10::2 3306

# Debería fallar: Connection refused o timeout
```

**Captura:** Conexión bloqueada

#### D. Ver logs del firewall

```bash
sudo tail -f /var/log/ufw.log
```

**Captura:** Logs de conexiones bloqueadas/permitidas

---

### 5️⃣ fail2ban - Demostrar que funciona

#### A. Ver estado

```bash
sudo fail2ban-client status
```

**Captura:** Lista de jails activos

#### B. Ver estado de SSH jail

```bash
sudo fail2ban-client status sshd
```

**Captura:** Debe mostrar:
- Currently failed: X
- Currently banned: X
- Total banned: X

#### C. Simular ataque (OPCIONAL - CUIDADO)

**⚠️ Solo si quieres demostrar que funciona:**

```bash
# Desde otro equipo, intentar SSH con contraseña incorrecta 5 veces
ssh usuario_falso@2025:db8:10::2
# Ingresar contraseña incorrecta 5 veces

# En el servidor, verificar que la IP fue bloqueada
sudo fail2ban-client status sshd
```

**Captura:** IP bloqueada después de 5 intentos

#### D. Ver logs de fail2ban

```bash
sudo tail -f /var/log/fail2ban.log
```

---

### 6️⃣ SSH - Demostrar que funciona

#### A. Verificar servicio activo

```bash
sudo systemctl status ssh
```

#### B. Ver configuración de seguridad

```bash
# Ver configuración importante
sudo grep -E "^PermitRootLogin|^PasswordAuthentication|^AllowUsers" /etc/ssh/sshd_config
```

**Captura:** Debe mostrar configuración segura

#### C. Probar acceso SSH

**Desde Ubuntu Desktop (como admin):**

```bash
ssh ubuntu@2025:db8:10::2
# Debería funcionar
```

**Captura:** Conexión exitosa

**Desde Ubuntu Desktop (como auditor o gamer01):**

```bash
ssh ubuntu@2025:db8:10::2
# Debería fallar o estar bloqueado
```

**Captura:** Conexión bloqueada

#### D. Ver conexiones SSH activas

```bash
# En el servidor
sudo ss -tn | grep :22 | grep ESTAB
```

**Captura:** Conexiones activas

#### E. Ver logs de SSH

```bash
sudo journalctl -u ssh -n 50
```

**Buscar líneas como:**
```
Accepted password for ubuntu from 2025:db8:10::100
```

---

### 7️⃣ NFS - Demostrar que funciona (si está configurado)

#### A. Verificar servicio activo

```bash
sudo systemctl status nfs-kernel-server
```

#### B. Ver exportaciones

```bash
sudo exportfs -v
```

**Captura:** Debe mostrar carpetas compartidas

#### C. Probar montaje desde cliente

**En Ubuntu Desktop:**

```bash
# Crear punto de montaje
sudo mkdir -p /mnt/nfs-games

# Montar carpeta compartida
sudo mount -t nfs -o vers=4 [2025:db8:10::2]:/srv/games /mnt/nfs-games

# Verificar montaje
df -h | grep nfs

# Listar contenido
ls -la /mnt/nfs-games
```

**Captura:** Carpeta montada y accesible

---

### 8️⃣ Usuarios y Permisos - Demostrar que funcionan

#### A. Ver usuarios del sistema

```bash
cat /etc/passwd | grep -E "ubuntu|auditor|dev"
```

#### B. Ver grupos

```bash
cat /etc/group | grep -E "sudo|auditors|developers"
```

#### C. Probar permisos sudo

```bash
# Como ubuntu (debería funcionar)
sudo apt update

# Como auditor (debería tener permisos limitados)
su - auditor
sudo journalctl -u bind9 -n 10  # Debería funcionar
sudo apt update                  # Debería fallar

# Como dev (debería tener permisos limitados)
su - dev
sudo systemctl restart nginx    # Debería funcionar
sudo apt update                  # Debería fallar
```

**Captura:** Permisos funcionando según rol

#### D. Ver permisos de carpetas

```bash
ls -la /srv/games
ls -la /home/auditor
ls -la /home/dev
```

---

### 9️⃣ Conectividad - Demostrar que funciona

#### A. Ping desde el servidor

```bash
# Ping a localhost
ping6 -c 4 ::1

# Ping a la IP del servidor
ping6 -c 4 2025:db8:10::2

# Ping a un cliente (si está conectado)
ping6 -c 4 2025:db8:10::100
```

#### B. Ping desde cliente al servidor

**En Ubuntu Desktop o Windows:**

```bash
# Ubuntu
ping6 -c 4 2025:db8:10::2

# Windows
ping 2025:db8:10::2
```

**Captura:** Ping exitoso

#### C. Traceroute

```bash
# Ubuntu
traceroute6 2025:db8:10::2

# Windows
tracert 2025:db8:10::2
```

---

### 🔟 Integración - Demostrar que todo funciona junto

#### Escenario completo:

1. **Cliente se conecta a la red**
   - Obtiene IP por DHCP
   - Obtiene configuración DNS

2. **Cliente resuelve nombre**
   - `dig @2025:db8:10::2 gamecenter.lan`
   - DNS responde con la IP

3. **Cliente accede al servidor web**
   - Abre navegador: `http://gamecenter.lan`
   - Nginx sirve la página

4. **Admin se conecta por SSH**
   - `ssh ubuntu@2025:db8:10::2`
   - SSH permite la conexión

5. **Firewall protege**
   - Bloquea puertos no autorizados
   - fail2ban bloquea ataques

**Captura:** Todo el flujo funcionando

---

## 📸 CAPTURAS OBLIGATORIAS

### Mínimo 20 capturas del servidor:

1. ✅ `systemctl status bind9`
2. ✅ `dig @localhost gamecenter.lan AAAA`
3. ✅ `systemctl status isc-dhcp-server6`
4. ✅ `cat /var/lib/dhcp/dhcpd6.leases`
5. ✅ `systemctl status nginx`
6. ✅ `curl http://gamecenter.lan`
7. ✅ Navegador mostrando página web
8. ✅ `sudo ufw status verbose`
9. ✅ `sudo fail2ban-client status`
10. ✅ `systemctl status ssh`
11. ✅ Conexión SSH exitosa
12. ✅ `ip -6 addr show`
13. ✅ `ip -6 route show`
14. ✅ `sudo ss -tulnp | grep -E "22|53|80"`
15. ✅ `cat /etc/passwd | grep -E "ubuntu|auditor|dev"`
16. ✅ `sudo -l -U auditor`
17. ✅ `ls -la /srv/games`
18. ✅ `ping6 2025:db8:10::2`
19. ✅ Logs de DNS en tiempo real
20. ✅ Logs de Nginx en tiempo real

---

## 🎯 ORDEN SUGERIDO DE DEMOSTRACIÓN

### Demostración de 15 minutos:

1. **Introducción** (1 min)
   - Mostrar topología
   - Explicar servicios

2. **Red IPv6** (2 min)
   - `ip -6 addr show`
   - `ip -6 route show`
   - Ping a localhost

3. **DNS** (3 min)
   - Estado del servicio
   - Resolución de nombres
   - Logs en tiempo real

4. **DHCP** (2 min)
   - Estado del servicio
   - Leases asignados
   - Cliente obteniendo IP

5. **Web** (2 min)
   - Estado del servicio
   - Acceso desde navegador
   - Logs de acceso

6. **Seguridad** (3 min)
   - Firewall activo
   - fail2ban funcionando
   - SSH con permisos por rol

7. **Integración** (2 min)
   - Todo funcionando junto
   - Cliente → DNS → Web

---

## ✅ CHECKLIST DE DEMOSTRACIÓN

Antes de presentar:

- [ ] Servidor encendido y funcionando
- [ ] Todos los servicios activos
- [ ] Al menos 1 cliente conectado
- [ ] Scripts probados
- [ ] Capturas tomadas
- [ ] Navegador listo para mostrar página
- [ ] Terminal con logs en tiempo real
- [ ] Comandos preparados en un archivo

---

## 💡 TIPS PARA LA DEMOSTRACIÓN

1. **Prepara los comandos:** Ten un archivo con todos los comandos listos para copiar/pegar

2. **Usa múltiples terminales:** Una para comandos, otra para logs en tiempo real

3. **Ten un plan B:** Si algo falla, ten capturas de respaldo

4. **Explica mientras ejecutas:** No solo muestres, explica qué hace cada comando

5. **Muestra los resultados:** No solo ejecutes, muestra que funcionó

6. **Usa colores:** Los scripts ya tienen colores para mejor visualización

---

**¡Éxito en tu demostración! 🚀**
