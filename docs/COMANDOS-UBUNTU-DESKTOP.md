# 🖥️ COMANDOS PARA UBUNTU DESKTOP - VALIDACIÓN RÚBRICA

## Lista de comandos para demostrar todo desde Ubuntu Desktop

---

## 1️⃣ INFORMACIÓN DEL SISTEMA

```bash
# Sistema operativo
cat /etc/os-release | grep PRETTY_NAME

# Usuario actual
whoami

# Grupos del usuario
groups

# Hostname
hostname
```

---

## 2️⃣ CONFIGURACIÓN DE RED IPv6

```bash
# Ver IP asignada por DHCP
ip -6 addr show | grep "inet6 2025"

# Ver gateway
ip -6 route show | grep default

# Ver DNS configurado
cat /etc/resolv.conf | grep nameserver

# Ver todas las interfaces
ip -6 addr show
```

---

## 3️⃣ CONECTIVIDAD AL SERVIDOR

```bash
# Ping al servidor
ping6 -c 4 2025:db8:10::2

# Ping al gateway
ping6 -c 4 2025:db8:10::1

# Traceroute
traceroute6 2025:db8:10::2
```

---

## 4️⃣ PRUEBAS DE DNS

```bash
# Resolver dominio principal
dig @2025:db8:10::2 gamecenter.lan AAAA +short

# Resolver www
dig @2025:db8:10::2 www.gamecenter.lan AAAA +short

# Resolver servidor
dig @2025:db8:10::2 servidor.gamecenter.lan AAAA +short

# Resolución inversa
dig @2025:db8:10::2 -x 2025:db8:10::2 +short

# Usando nslookup
nslookup gamecenter.lan 2025:db8:10::2
```

---

## 5️⃣ PRUEBAS DE ACCESO WEB

```bash
# Acceso HTTP por IP
curl -6 http://[2025:db8:10::2]

# Acceso HTTP por dominio
curl http://gamecenter.lan

# Ver solo headers
curl -I http://gamecenter.lan

# Abrir en navegador (GUI)
firefox http://gamecenter.lan &
# o
xdg-open http://gamecenter.lan
```

---

## 6️⃣ PRUEBAS DE SSH (SEGÚN ROL)

### Si eres ADMINISTRADOR:
```bash
# Debería funcionar
ssh ubuntu@2025:db8:10::2

# O por dominio
ssh ubuntu@gamecenter.lan
```

### Si eres AUDITOR o GAMER01:
```bash
# Debería estar BLOQUEADO
ssh ubuntu@2025:db8:10::2
# Esperado: Connection refused o timeout
```

---

## 7️⃣ VERIFICAR PERMISOS DEL USUARIO

```bash
# Ver si tienes sudo
sudo -l

# Intentar instalar algo (solo admin debería poder)
sudo apt update

# Ver permisos de carpetas
ls -la /srv/games
ls -la /mnt/games

# Intentar escribir en /srv/games
touch /srv/games/test.txt
# Admin: debería funcionar
# Auditor/Cliente: debería fallar
```

---

## 8️⃣ PRUEBAS DE NFS (ALMACENAMIENTO COMPARTIDO)

```bash
# Ver si está montado
df -h | grep nfs

# Montar carpeta compartida
sudo mkdir -p /mnt/nfs-games
sudo mount -t nfs -o vers=4 [2025:db8:10::2]:/srv/nfs/games /mnt/nfs-games

# Verificar montaje
ls -la /mnt/nfs-games

# Desmontar
sudo umount /mnt/nfs-games
```

---

## 9️⃣ PRUEBAS DE SAMBA (COMPARTIR CON WINDOWS)

```bash
# Ver recursos compartidos del servidor
smbclient -L //2025:db8:10::2 -N

# Conectar a carpeta compartida
smbclient //2025:db8:10::2/Compartido -U dev
# Contraseña: 123

# Montar carpeta Samba
sudo mkdir -p /mnt/samba-shared
sudo mount -t cifs //2025:db8:10::2/Compartido /mnt/samba-shared -o username=dev,password=123

# Ver contenido
ls -la /mnt/samba-shared
```

---

## 🔟 PRUEBAS DE FTP

```bash
# Conectar por FTP
ftp 2025:db8:10::2
# Usuario: dev
# Contraseña: 123

# O con lftp (más moderno)
lftp ftp://dev:123@2025:db8:10::2

# Listar archivos
ls

# Salir
quit
```

---

## 1️⃣1️⃣ VERIFICAR USUARIOS Y GRUPOS

```bash
# Ver usuario actual
id

# Ver todos los usuarios importantes
cat /etc/passwd | grep -E "administrador|auditor|gamer01"

# Ver grupos importantes
cat /etc/group | grep -E "sudo|pcgamers|auditors"

# Ver miembros del grupo pcgamers
getent group pcgamers
```

---

## 1️⃣2️⃣ VERIFICAR PARTICIONES

```bash
# Ver particiones
lsblk

# Uso de disco
df -h

# Ver LVM (si aplica)
sudo pvdisplay
sudo vgdisplay
sudo lvdisplay
```

---

## 1️⃣3️⃣ VERIFICAR SERVICIOS LOCALES

```bash
# Ver servicios activos
systemctl list-units --type=service --state=running

# Ver puertos abiertos localmente
sudo ss -tulnp

# Ver conexiones activas
sudo ss -tn | grep ESTAB
```

---

## 1️⃣4️⃣ LOGS Y SEGURIDAD

```bash
# Ver logs de autenticación
sudo tail -20 /var/log/auth.log

# Ver intentos de SSH
sudo grep "Failed password" /var/log/auth.log | tail -10

# Ver logs del sistema
sudo journalctl -n 50
```

---

## 📸 CAPTURAS OBLIGATORIAS PARA LA RÚBRICA

### Conectividad (5 capturas):
1. `ip -6 addr show` - Mostrar IP asignada
2. `ping6 2025:db8:10::2` - Ping exitoso
3. `dig @2025:db8:10::2 gamecenter.lan AAAA` - DNS funciona
4. `curl http://gamecenter.lan` - Web funciona
5. Navegador mostrando página web

### SSH según rol (2 capturas):
6. SSH funcionando (si eres admin)
7. SSH bloqueado (si eres auditor/cliente)

### Permisos (3 capturas):
8. `sudo -l` - Mostrar permisos sudo
9. `ls -la /srv/games` - Permisos de carpetas
10. Intentar escribir en /srv/games (éxito/fallo según rol)

### Particiones (2 capturas):
11. `lsblk` - Esquema de particiones
12. `df -h` - Uso de disco

### Usuarios (2 capturas):
13. `id` - Información del usuario
14. `groups` - Grupos del usuario

---

## 🚀 SCRIPT RÁPIDO PARA TODO

```bash
# Ejecutar script de conectividad
bash scripts/diagnostics/test-connectivity-full.sh

# Ejecutar script de permisos
bash scripts/diagnostics/check-user-permissions.sh
```

---

## ✅ CHECKLIST DE VALIDACIÓN

### Como ADMINISTRADOR:
- [ ] Tiene IP por DHCP
- [ ] Ping al servidor funciona
- [ ] DNS resuelve nombres
- [ ] Puede acceder a la web
- [ ] Puede hacer SSH al servidor ✅
- [ ] Tiene sudo completo ✅
- [ ] Puede escribir en /srv/games ✅

### Como AUDITOR:
- [ ] Tiene IP por DHCP
- [ ] Ping al servidor funciona
- [ ] DNS resuelve nombres
- [ ] Puede acceder a la web
- [ ] NO puede hacer SSH al servidor ❌
- [ ] NO tiene sudo ❌
- [ ] Solo lectura en /srv/games ✅

### Como GAMER01 (Cliente):
- [ ] Tiene IP por DHCP
- [ ] Ping al servidor funciona
- [ ] DNS resuelve nombres
- [ ] Puede acceder a la web
- [ ] NO puede hacer SSH al servidor ❌
- [ ] NO tiene sudo ❌
- [ ] Solo lectura en /srv/games ✅

---

**¡Con estos comandos puedes validar TODO para la rúbrica! 🎯*