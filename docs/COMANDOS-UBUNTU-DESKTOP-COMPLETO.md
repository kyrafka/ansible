# 📋 COMANDOS COMPLETOS PARA UBUNTU DESKTOP

## 🎯 VALIDACIÓN DE SERVICIOS DEL SERVIDOR

### 1️⃣ DNS (BIND9)
```bash
# Estado del servicio
sudo systemctl status named

# Configuración principal
sudo cat /etc/bind/named.conf.options

# Zonas configuradas
sudo cat /etc/bind/named.conf.local

# Archivo de zona
sudo cat /etc/bind/db.gamecenter.local

# Probar resolución DNS
nslookup servidor.gamecenter.local
nslookup www.gamecenter.local
dig @2025:db8:10::1 servidor.gamecenter.local AAAA
```

### 2️⃣ DHCP IPv6
```bash
# Estado del servicio
sudo systemctl status isc-dhcp-server6

# Configuración principal
sudo cat /etc/dhcp/dhcpd6.conf

# Ver leases activos
sudo cat /var/lib/dhcp/dhcpd6.leases

# Ver configuración de red obtenida
ip -6 addr show
ip -6 route show
```

### 3️⃣ FIREWALL (UFW)
```bash
# Estado del firewall
sudo ufw status verbose

# Reglas numeradas
sudo ufw status numbered

# Ver logs del firewall
sudo tail -50 /var/log/ufw.log

# Estado de fail2ban
sudo systemctl status fail2ban

# Configuración fail2ban
sudo cat /etc/fail2ban/jail.local
```

### 4️⃣ SSH
```bash
# Estado del servicio
sudo systemctl status ssh

# Configuración principal
sudo cat /etc/ssh/sshd_config

# Ver intentos de conexión
sudo tail -50 /var/log/auth.log

# Probar conexión SSH (desde cliente)
ssh admin@servidor.gamecenter.local
ssh auditor@servidor.gamecenter.local  # Debe fallar
ssh cliente@servidor.gamecenter.local  # Debe fallar
```

### 5️⃣ NFS
```bash
# Estado del servicio
sudo systemctl status nfs-server

# Exportaciones configuradas
sudo cat /etc/exports

# Ver exportaciones activas
sudo exportfs -v

# Montar desde cliente
sudo mount -t nfs -o vers=4 servidor.gamecenter.local:/srv/nfs/compartido /mnt/nfs
ls -la /mnt/nfs
```

### 6️⃣ SAMBA
```bash
# Estado de los servicios
sudo systemctl status smbd
sudo systemctl status nmbd

# Configuración principal
sudo cat /etc/samba/smb.conf

# Ver recursos compartidos
smbclient -L //servidor.gamecenter.local -N

# Montar desde cliente
sudo mount -t cifs //servidor.gamecenter.local/compartido /mnt/samba -o guest
ls -la /mnt/samba

# Desde Windows
# \\servidor.gamecenter.local\compartido
```

### 7️⃣ FTP (vsftpd)
```bash
# Estado del servicio
sudo systemctl status vsftpd

# Configuración principal
sudo cat /etc/vsftpd.conf

# Probar conexión FTP
ftp servidor.gamecenter.local
# Usuario: anonymous
# Contraseña: (vacía)

# Con cliente gráfico (FileZilla)
# Host: ftp://servidor.gamecenter.local
# Usuario: anonymous
```

### 8️⃣ HTTP/Web (Nginx - opcional)
```bash
# Estado del servicio
sudo systemctl status nginx

# Configuración principal
sudo cat /etc/nginx/nginx.conf

# Sitios habilitados
sudo cat /etc/nginx/sites-enabled/default

# Probar desde navegador
firefox http://www.gamecenter.local
firefox http://servidor.gamecenter.local
```

---

## 🖥️ VALIDACIÓN EN UBUNTU DESKTOP

### 1️⃣ CONECTIVIDAD BÁSICA
```bash
# Ping al servidor
ping6 -c 4 2025:db8:10::1
ping6 -c 4 servidor.gamecenter.local

# Ping a Internet (NAT64)
ping -c 4 8.8.8.8
ping -c 4 google.com

# Traceroute
traceroute6 2025:db8:10::1
traceroute google.com

# Ver configuración de red
ip -6 addr show
ip -6 route show
cat /etc/resolv.conf
```

### 2️⃣ RESOLUCIÓN DNS
```bash
# Resolver nombres locales
nslookup servidor.gamecenter.local
nslookup www.gamecenter.local
nslookup desktop.gamecenter.local

# Resolver nombres externos
nslookup google.com
nslookup facebook.com

# Consultas detalladas
dig servidor.gamecenter.local AAAA
dig google.com A
```

### 3️⃣ NAVEGACIÓN WEB
```bash
# Abrir navegador
firefox http://www.gamecenter.local &
firefox http://google.com &

# Probar con curl
curl -6 http://www.gamecenter.local
curl http://google.com
```

### 4️⃣ SSH SEGÚN ROL
```bash
# Como usuario admin (DEBE FUNCIONAR)
ssh admin@servidor.gamecenter.local
# Contraseña: Admin2024!

# Como usuario auditor (DEBE FALLAR)
ssh auditor@servidor.gamecenter.local
# Debe mostrar: Permission denied

# Como usuario cliente (DEBE FALLAR)
ssh cliente@servidor.gamecenter.local
# Debe mostrar: Permission denied

# Ver logs de intentos
sudo tail -20 /var/log/auth.log
```

### 5️⃣ PERMISOS DIFERENCIADOS
```bash
# Como admin
sudo su - admin
touch /home/admin/test-admin.txt
ls -la /home/admin/

# Como auditor
sudo su - auditor
touch /home/auditor/test-auditor.txt
ls -la /home/auditor/
# Intentar acceder a /home/admin (debe fallar)
ls /home/admin/

# Como cliente
sudo su - cliente
touch /home/cliente/test-cliente.txt
ls -la /home/cliente/
# Intentar acceder a otros homes (debe fallar)
ls /home/admin/
ls /home/auditor/
```

### 6️⃣ PARTICIONES Y ALMACENAMIENTO
```bash
# Ver todas las particiones
lsblk
sudo fdisk -l

# Ver uso de disco
df -h

# Ver montajes
mount | grep -E "sda|sdb"

# Ver detalles de particiones
sudo parted -l

# Ver UUID de particiones
sudo blkid
```

### 7️⃣ USUARIOS Y GRUPOS
```bash
# Listar usuarios del sistema
cat /etc/passwd | grep -E "admin|auditor|cliente"

# Ver grupos
cat /etc/group | grep -E "admin|auditor|cliente"

# Ver pertenencia a grupos
groups admin
groups auditor
groups cliente

# Ver usuarios conectados
who
w
last | head -20
```

### 8️⃣ SERVICIOS MONTADOS (NFS/SAMBA)
```bash
# Crear puntos de montaje
sudo mkdir -p /mnt/nfs /mnt/samba

# Montar NFS
sudo mount -t nfs -o vers=4 servidor.gamecenter.local:/srv/nfs/compartido /mnt/nfs
ls -la /mnt/nfs
echo "Prueba NFS" | sudo tee /mnt/nfs/test-nfs.txt

# Montar Samba
sudo mount -t cifs //servidor.gamecenter.local/compartido /mnt/samba -o guest
ls -la /mnt/samba
echo "Prueba Samba" | sudo tee /mnt/samba/test-samba.txt

# Ver montajes activos
mount | grep -E "nfs|cifs"
df -h | grep -E "nfs|samba"
```

### 9️⃣ PROBAR FTP
```bash
# Instalar cliente FTP si no está
sudo apt install -y ftp

# Conectar por FTP
ftp servidor.gamecenter.local
# Usuario: anonymous
# Contraseña: (Enter)
# Comandos: ls, pwd, quit

# Con FileZilla (GUI)
sudo apt install -y filezilla
filezilla &
# Host: ftp://servidor.gamecenter.local
# Usuario: anonymous
```

---

## 📸 CAPTURAS NECESARIAS PARA LA RÚBRICA

### CONECTIVIDAD (5 capturas)
1. `ping6` al servidor
2. `ping` a Internet (Google)
3. `nslookup` de nombres locales
4. `nslookup` de nombres externos
5. Navegador mostrando página web

### SSH (2 capturas)
6. SSH exitoso como admin
7. SSH bloqueado como auditor/cliente

### PERMISOS (3 capturas)
8. Permisos de admin (puede crear archivos)
9. Permisos de auditor (limitados)
10. Permisos de cliente (muy limitados)

### PARTICIONES (2 capturas)
11. `lsblk` mostrando particiones
12. `df -h` mostrando uso de disco

### USUARIOS (2 capturas)
13. Lista de usuarios del sistema
14. Grupos y pertenencias

### SERVICIOS (1 captura)
15. Montajes NFS/Samba activos

---

## 🚀 SCRIPT RÁPIDO DE VALIDACIÓN

```bash
#!/bin/bash
echo "=== VALIDACIÓN RÁPIDA UBUNTU DESKTOP ==="

echo -e "\n1. Conectividad:"
ping6 -c 2 servidor.gamecenter.local

echo -e "\n2. DNS:"
nslookup servidor.gamecenter.local

echo -e "\n3. Internet:"
ping -c 2 google.com

echo -e "\n4. Particiones:"
lsblk

echo -e "\n5. Usuarios:"
cat /etc/passwd | grep -E "admin|auditor|cliente"

echo -e "\n6. Red:"
ip -6 addr show | grep inet6

echo -e "\n=== VALIDACIÓN COMPLETA ==="
```

Guarda esto como `validar-desktop.sh` y ejecuta:
```bash
chmod +x validar-desktop.sh
./validar-desktop.sh
```
