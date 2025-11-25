# ⚡ VALIDACIÓN RÁPIDA DESDE UBUNTU DESKTOP

## 🎯 Comandos esenciales para demostrar la rúbrica

### 1. CONECTIVIDAD (2 min)
```bash
# Ping al servidor
ping6 -c 4 2025:db8:10::2

# Ping a Internet
ping -c 4 google.com

# Ver IP obtenida por DHCP
ip -6 addr show | grep inet6
```

### 2. DNS (1 min)
```bash
# Resolver nombre del servidor
nslookup gamecenter.lan

# Resolver nombre externo
nslookup google.com
```

### 3. NAVEGACIÓN WEB (1 min)
```bash
# Abrir navegador
firefox http://google.com &
```

### 4. SAMBA - Montar recursos (3 min)
```bash
# Crear puntos de montaje
sudo mkdir -p /mnt/publico /mnt/juegos

# Montar recurso público
sudo mount -t cifs //gamecenter.lan/Publico /mnt/publico -o guest,uid=1000,gid=1000

# Ver contenido
ls -la /mnt/publico

# Crear archivo de prueba
echo "Prueba desde Ubuntu Desktop" | sudo tee /mnt/publico/test-desktop.txt

# Verificar
cat /mnt/publico/test-desktop.txt
```

### 5. FTP (2 min)
```bash
# Instalar cliente si no está
sudo apt install -y lftp

# Conectar por FTP
lftp ftp://gamecenter.lan
# Comandos: ls, pwd, quit
```

### 6. SSH (1 min)
```bash
# Conectar por SSH
ssh ubuntu@gamecenter.lan
# Salir: exit
```

### 7. PARTICIONES (1 min)
```bash
# Ver particiones
lsblk

# Ver uso de disco
df -h
```

### 8. USUARIOS (1 min)
```bash
# Ver usuarios del sistema
cat /etc/passwd | tail -10

# Ver usuario actual
whoami
id
```

---

## 📸 CAPTURAS NECESARIAS (15 total)

### CONECTIVIDAD (5)
1. `ping6 2025:db8:10::2` - Ping al servidor
2. `ping google.com` - Ping a Internet
3. `nslookup gamecenter.lan` - DNS local
4. `nslookup google.com` - DNS externo
5. Firefox mostrando Google

### SERVICIOS (5)
6. `ls -la /mnt/publico` - Samba montado
7. `cat /mnt/publico/test-desktop.txt` - Archivo creado
8. `lftp ftp://gamecenter.lan` - FTP conectado
9. `ssh ubuntu@gamecenter.lan` - SSH conectado
10. `mount | grep cifs` - Montajes activos

### SISTEMA (5)
11. `lsblk` - Particiones
12. `df -h` - Uso de disco
13. `ip -6 addr show` - Configuración IPv6
14. `cat /etc/passwd | tail -10` - Usuarios
15. `whoami` e `id` - Usuario actual

---

## 🚀 SCRIPT AUTOMÁTICO

```bash
#!/bin/bash
echo "=== VALIDACIÓN UBUNTU DESKTOP ==="

echo -e "\n1. Conectividad al servidor:"
ping6 -c 2 2025:db8:10::2

echo -e "\n2. Conectividad a Internet:"
ping -c 2 google.com

echo -e "\n3. DNS local:"
nslookup gamecenter.lan

echo -e "\n4. DNS externo:"
nslookup google.com

echo -e "\n5. Configuración IPv6:"
ip -6 addr show | grep inet6

echo -e "\n6. Particiones:"
lsblk

echo -e "\n7. Usuario actual:"
whoami
id

echo -e "\n=== VALIDACIÓN COMPLETA ==="
```

Guarda como `validar-desktop.sh` y ejecuta:
```bash
chmod +x validar-desktop.sh
./validar-desktop.sh
```

---

## 📋 CHECKLIST PARA LA DEMOSTRACIÓN

- [ ] Servidor encendido y servicios activos
- [ ] Ubuntu Desktop conectado a la red
- [ ] IP obtenida por DHCP
- [ ] Ping al servidor funciona
- [ ] Ping a Internet funciona
- [ ] DNS resuelve nombres locales
- [ ] DNS resuelve nombres externos
- [ ] Navegador accede a Internet
- [ ] Samba monta recursos
- [ ] Puede crear archivos en Samba
- [ ] FTP conecta al servidor
- [ ] SSH conecta al servidor
- [ ] Particiones visibles
- [ ] Usuarios configurados

---

## ⏱️ TIEMPO TOTAL: ~12 minutos

**¡Listo para demostrar Nivel 4!** 🚀
