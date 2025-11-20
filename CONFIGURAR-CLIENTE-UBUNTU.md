# 🖥️ CONFIGURAR CLIENTE UBUNTU DESKTOP DESDE CERO

## 📋 **Requisitos previos:**

1. ✅ Servidor GameCenter configurado y funcionando
2. ✅ NAT64 (TAYGA) activo en el servidor
3. ✅ DNS (BIND9) funcionando en el servidor
4. ✅ Ubuntu Desktop instalado (con internet temporal)

---

## 🚀 **PASOS PARA CONFIGURAR EL CLIENTE:**

### **1. Preparar la VM (CON INTERNET)**

Primero, con la VM conectada a internet (adaptador NAT o Bridged):

```bash
# Actualizar sistema
sudo apt update
sudo apt upgrade -y

# Instalar git para clonar el proyecto
sudo apt install -y git

# Clonar el proyecto (o copiar por USB)
git clone <tu-repositorio> ~/ansible-gestion-despliegue
cd ~/ansible-gestion-despliegue
```

---

### **2. Ejecutar script de configuración**

```bash
# Ejecutar como root
sudo bash scripts/vm-setup-complete.sh
```

**Este script hará:**
- ✅ Configurar DNS del servidor (2025:db8:10::2)
- ✅ Deshabilitar systemd-resolved
- ✅ Instalar paquetes necesarios (SSH, Ansible, etc.)
- ✅ Configurar grupos y permisos
- ✅ Desactivar proxy (usar NAT64 directamente)

---

### **3. Cambiar adaptador de red**

Una vez completado el script:

1. **Apagar la VM**
2. **Cambiar adaptador de red:**
   - VMware: De "NAT" a "Custom: M_vm's" (red interna)
   - VirtualBox: De "NAT" a "Red interna: M_vm's"
3. **Encender la VM**

---

### **4. Verificar conectividad**

Una vez iniciada con la red interna:

```bash
# 1. Verificar IPv6 asignada
ip -6 addr show ens33 | grep "2025:db8:10"

# 2. Verificar DNS
cat /etc/resolv.conf
# Debe mostrar: nameserver 2025:db8:10::2

# 3. Verificar que NO hay proxy
env | grep -i proxy
# No debe mostrar nada

# 4. Ping al servidor
ping6 2025:db8:10::2

# 5. Ping a través de NAT64
ping6 64:ff9b::8.8.8.8

# 6. Resolver nombres
dig google.com AAAA

# 7. Probar HTTP
curl -6 http://google.com

# 8. Abrir Firefox
firefox http://www.google.com
```

---

## ✅ **VERIFICACIÓN COMPLETA:**

Si todo funciona correctamente, deberías poder:

- ✅ Hacer ping al servidor
- ✅ Resolver nombres DNS
- ✅ Navegar en Firefox
- ✅ Ejecutar `sudo apt update`
- ✅ Descargar archivos con `wget` o `curl`

---

## 🔧 **SOLUCIÓN DE PROBLEMAS:**

### **Problema: No hay internet**

```bash
# Verificar DNS
resolvectl status

# Verificar rutas
ip -6 route

# Verificar gateway
ip -6 route | grep default
```

### **Problema: Proxy configurado**

```bash
# Eliminar proxy
bash scripts/client/remove-proxy.sh

# O manual:
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY no_proxy NO_PROXY
```

### **Problema: DNS no funciona**

```bash
# Reconfigurar DNS
sudo chattr -i /etc/resolv.conf
sudo bash -c 'cat > /etc/resolv.conf << EOF
nameserver 2025:db8:10::2
search gamecenter.lan
EOF'
sudo chattr +i /etc/resolv.conf
```

---

## 📝 **NOTAS IMPORTANTES:**

1. **NO uses proxy** - NAT64 maneja todo el tráfico automáticamente
2. **systemd-resolved debe estar deshabilitado** - Interfiere con el DNS
3. **El archivo /etc/resolv.conf debe estar protegido** - Para que no se sobrescriba
4. **Firefox debe tener proxy en "No proxy"** - Configuración de red

---

## 🎮 **SIGUIENTE PASO: Montar NFS**

Una vez que internet funcione:

```bash
# Montar carpeta de juegos
sudo mount -t nfs [2025:db8:10::2]:/srv/nfs/games /mnt/games

# Verificar
ls /mnt/games
```

---

## 📊 **RESUMEN DE CONFIGURACIÓN:**

| Componente | Valor |
|------------|-------|
| **DNS** | 2025:db8:10::2 |
| **Gateway** | fe80::... (link-local) |
| **Red** | 2025:db8:10::/64 |
| **NAT64** | 64:ff9b::/96 |
| **Proxy** | Ninguno (deshabilitado) |
| **Dominio** | gamecenter.lan |

---

**¿Problemas?** Ejecuta el diagnóstico:

```bash
bash scripts/diagnostics/diagnose-nat64-performance.sh
```
