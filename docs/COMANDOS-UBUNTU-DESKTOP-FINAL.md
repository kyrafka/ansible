# 🖥️ COMANDOS PARA UBUNTU DESKTOP

## ⚡ VALIDACIÓN RÁPIDA (10 minutos)

### 1️⃣ CONECTIVIDAD (2 min)
```bash
# Ping al servidor
ping6 -c 4 2025:db8:10::2

# Ping a Internet
ping -c 4 google.com

# Ver IP obtenida por DHCP
ip -6 addr show | grep "inet6 2025"

# Ver ruta por defecto
ip -6 route show
```

### 2️⃣ DNS (1 min)
```bash
# Resolver nombre del servidor
nslookup gamecenter.lan

# Resolver nombre externo
nslookup google.com

# Ver servidor DNS configurado
cat /etc/resolv.conf
```

### 3️⃣ NAVEGACIÓN WEB (1 min)
```bash
# Abrir navegador
firefox http://google.com &

# O probar con curl
curl -I http://google.com
```

### 4️⃣ SSH AL SERVIDOR (1 min)
```bash
# Conectar por SSH
ssh ubuntu@gamecenter.lan
# O por IP
ssh ubuntu@2025:db8:10::2

# Salir
exit
```

### 5️⃣ SAMBA - Montar recursos (3 min)
```bash
# Instalar cliente Samba si no está
sudo apt install -y cifs-utils smbclient

# Ver recursos compartidos disponibles
smbclient -L //gamecenter.lan -N

# Crear puntos de montaje
sudo mkdir -p /mnt/publico /mnt/juegos /mnt/compartido

# Montar recurso PÚBLICO (lectura/escritura)
sudo mount -t cifs //gamecenter.lan/Publico /mnt/publico -o guest,uid=1000,gid=1000

# Ver contenido
ls -la /mnt/publico

# Crear archivo de prueba
echo "Prueba desde Ubuntu Desktop $(date)" | sudo tee /mnt/publico/test-ubuntu-desktop.txt

# Leer el archivo
cat /mnt/publico/test-ubuntu-desktop.txt

# Montar recurso JUEGOS (requiere usuario)
sudo mount -t cifs //gamecenter.lan/Juegos /mnt/juegos -o username=jose,password=tu_password,uid=1000,gid=1000

# Montar recurso COMPARTIDO (solo lectura)
sudo mount -t cifs //gamecenter.lan/Compartido /mnt/compartido -o guest,uid=1000,gid=1000

# Ver todos los montajes
mount | grep cifs
df -h | grep mnt
```

### 6️⃣ FTP (2 min)
```bash
# Instalar cliente FTP
sudo apt install -y ftp lftp

# Conectar por FTP
ftp gamecenter.lan
# Usuario: anonymous
# Password: (Enter)
# Comandos: ls, pwd, quit

# O con lftp (mejor)
lftp ftp://gamecenter.lan
# ls, cd, quit
```

### 7️⃣ PARTICIONES Y ALMACENAMIENTO (1 min)
```bash
# Ver todas las particiones
lsblk

# Ver uso de disco
df -h

# Ver detalles de particiones
sudo fdisk -l

# Ver UUID
sudo blkid
```

### 8️⃣ USUARIOS Y SISTEMA (1 min)
```bash
# Usuario actual
whoami
id

# Ver usuarios del sistema
cat /etc/passwd | tail -10

# Ver grupos
groups

# Ver hostname
hostname
hostname -I
```

---

## 📸 CAPTURAS PARA LA RÚBRICA (15 total)

### CONECTIVIDAD (5 capturas)
```bash
# 1. Ping al servidor
ping6 -c 4 2025:db8:10::2

# 2. Ping a Internet
ping -c 4 google.com

# 3. DNS local
nslookup gamecenter.lan

# 4. DNS externo
nslookup google.com

# 5. Navegador
firefox http://google.com &
```

### SERVICIOS (5 capturas)
```bash
# 6. Recursos Samba disponibles
smbclient -L //gamecenter.lan -N

# 7. Samba montado
ls -la /mnt/publico

# 8. Crear archivo en Samba
echo "Prueba" | sudo tee /mnt/publico/test.txt
cat /mnt/publico/test.txt

# 9. FTP conectado
ftp gamecenter.lan

# 10. SSH conectado
ssh ubuntu@gamecenter.lan
```

### SISTEMA (5 capturas)
```bash
# 11. Particiones
lsblk

# 12. Uso de disco
df -h

# 13. Configuración IPv6
ip -6 addr show

# 14. Montajes activos
mount | grep cifs

# 15. Usuario e ID
whoami
id
```

---

## 🚀 SCRIPT AUTOMÁTICO DE VALIDACIÓN

```bash
#!/bin/bash
# Guardar como: validar-ubuntu-desktop.sh

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     VALIDACIÓN UBUNTU DESKTOP - RÚBRICA NIVEL 4            ║"
echo "╚════════════════════════════════════════════════════════════╝"

echo ""
echo "1️⃣  CONECTIVIDAD AL SERVIDOR"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ping6 -c 2 2025:db8:10::2 && echo "✅ Servidor alcanzable" || echo "❌ Servidor no responde"

echo ""
echo "2️⃣  CONECTIVIDAD A INTERNET"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ping -c 2 google.com && echo "✅ Internet funciona" || echo "❌ Sin Internet"

echo ""
echo "3️⃣  RESOLUCIÓN DNS LOCAL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
nslookup gamecenter.lan | grep -q "2025:db8:10::2" && echo "✅ DNS local funciona" || echo "❌ DNS local falla"

echo ""
echo "4️⃣  RESOLUCIÓN DNS EXTERNA"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
nslookup google.com > /dev/null && echo "✅ DNS externo funciona" || echo "❌ DNS externo falla"

echo ""
echo "5️⃣  CONFIGURACIÓN IPv6"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ip -6 addr show | grep "inet6 2025" && echo "✅ IPv6 configurado por DHCP" || echo "❌ Sin IPv6"

echo ""
echo "6️⃣  RECURSOS SAMBA"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
smbclient -L //gamecenter.lan -N 2>/dev/null | grep -q "Publico" && echo "✅ Samba disponible" || echo "❌ Samba no responde"

echo ""
echo "7️⃣  PARTICIONES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
lsblk | head -10

echo ""
echo "8️⃣  USUARIO ACTUAL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Usuario: $(whoami)"
echo "UID/GID: $(id)"

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                  ✅ VALIDACIÓN COMPLETA                    ║"
echo "╚════════════════════════════════════════════════════════════╝"
```

**Ejecutar:**
```bash
chmod +x validar-ubuntu-desktop.sh
./validar-ubuntu-desktop.sh
```

---

## 📋 CHECKLIST PARA LA DEMOSTRACIÓN

- [ ] Servidor encendido
- [ ] Ubuntu Desktop encendido
- [ ] IP obtenida por DHCP (`ip -6 addr`)
- [ ] Ping al servidor funciona
- [ ] Ping a Internet funciona
- [ ] DNS resuelve `gamecenter.lan`
- [ ] DNS resuelve `google.com`
- [ ] Navegador accede a Internet
- [ ] `smbclient -L` muestra recursos
- [ ] Samba monta `/mnt/publico`
- [ ] Puede crear archivos en Samba
- [ ] FTP conecta al servidor
- [ ] SSH conecta al servidor
- [ ] `lsblk` muestra particiones
- [ ] `df -h` muestra uso de disco

---

## ⏱️ TIEMPO ESTIMADO: 10-12 minutos

**¡Todo listo para demostrar Nivel 4!** 🚀
