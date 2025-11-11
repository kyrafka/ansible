# 📋 Guía de Instalación de Ubuntu Desktop (Cliente)

Esta guía te indica **exactamente** qué configurar cuando instales Ubuntu Desktop en una VM cliente.

---

## 🖥️ Paso 1: Crear la VM (desde WSL)

```bash
bash scripts/vms/create-vm-interactive.sh
```

O directamente:
```bash
ansible-playbook playbooks/create-ubuntu-desktop.yml
```

**Te preguntará:**
- Nombre de la VM (ej: ubuntu-cliente01)
- Rol: admin / auditor / cliente

Esto crea la VM vacía con la ISO montada.

---

## 💿 Paso 2: Instalar Ubuntu Desktop (desde consola ESXi)

### 1. Conectarte a la consola de la VM
- Abre vCenter/ESXi
- Busca tu VM (ej: ubuntu-cliente01)
- Abre la consola
- La VM arrancará desde la ISO de Ubuntu Desktop

### 2. Instalación de Ubuntu Desktop

**Idioma:**
- Selecciona: Español (o tu preferencia)

**Actualizaciones:**
- Selecciona: Instalar Ubuntu

**Distribución del teclado:**
- Selecciona: Spanish (o tu preferencia)

**Conexión a Internet:**
- Selecciona: No conectar ahora (configuraremos IPv6 después)

**Aplicaciones:**
- Selecciona: Instalación normal

**Tipo de instalación:**
- Selecciona: Borrar disco e instalar Ubuntu
- Confirmar

### 3. ⚠️ CONFIGURACIÓN DE USUARIO (IMPORTANTE)

**Ejemplo para rol admin (como en tu caso):**
```
Su nombre: Administrador
El nombre del equipo: admin-ubuntu
Elija un nombre de usuario: administrador
Elija una contraseña: 123456
Confirme su contraseña: 123456
```

**✅ MARCAR:** "Solicitar mi contraseña para acceder"
**❌ NO marcar:** "Utilizar Active Directory"

**Configuraciones por rol:**

**🔑 Admin:**
- Su nombre: `Administrador`
- Nombre del equipo: `admin-ubuntu`
- Usuario: `administrador`
- Contraseña: `123456` (o la que prefieras)
- Disco: 50GB

**📊 Auditor:**
- Su nombre: `Auditor`
- Nombre del equipo: `auditor-ubuntu`
- Usuario: `auditor`
- Contraseña: `123456`
- Disco: 30GB

**🎮 Cliente/Gaming:**
- Su nombre: `Gamer`
- Nombre del equipo: `gaming-ubuntu`
- Usuario: `gamer`
- Contraseña: `123456`
- Disco: 40GB

### 4. Instalación
- Espera a que termine (10-15 minutos)
- Cuando termine, selecciona **Reiniciar ahora**
- Quita la ISO si te lo pide

---

## 🌐 Paso 3: Configurar red IPv6 (desde el Desktop)

### 1. Iniciar sesión
- Usuario: el que creaste
- Contraseña: la que elegiste

### 2. Abrir configuración de red
```
Settings → Network → Wired → ⚙️ (engranaje)
```

### 3. Configurar IPv6

**Pestaña IPv6:**
- **Method:** Automatic (DHCP)
- El servidor DHCP asignará automáticamente:
  - IP: 2025:db8:10::XX
  - Gateway: 2025:db8:10::1
  - DNS: 2025:db8:10::2

**Pestaña IPv4:**
- **Method:** Disabled (desactivar IPv4)

**Guardar y aplicar**

**Nota:** Si prefieres IP fija, usa Manual y configura:
- Address: `2025:db8:10::XX/64`
- Gateway: `2025:db8:10::1`
- DNS: `2025:db8:10::2`

### 4. Verificar conectividad
```bash
# Abrir terminal (Ctrl+Alt+T)
ip -6 addr show

# Debe mostrar tu IP asignada por DHCP: 2025:db8:10::XX/64

# Anotar la IP que te asignó el DHCP (la necesitarás para el inventario)

# Probar ping al servidor
ping6 -c 3 2025:db8:10::2

# Probar DNS
ping6 -c 3 gamecenter.local
```

---

## 📝 Paso 4: Agregar al inventario (desde el servidor)

**Primero, anota la IP que DHCP asignó a tu VM:**
```bash
# En el Desktop, ejecuta:
ip -6 addr show | grep "inet6 2025"
# Ejemplo: 2025:db8:10::15/64
```

En el servidor Ubuntu, edita `inventory/hosts.ini`:

```bash
sudo nano ~/ansible-gestion-despliegue/inventory/hosts.ini
```

Agrega tu VM con la IP que DHCP le asignó:

```ini
[ubuntu_desktops]
ubuntu-cliente01 ansible_host=2025:db8:10::15 vm_role=cliente
ubuntu-admin01 ansible_host=2025:db8:10::16 vm_role=admin
ubuntu-auditor01 ansible_host=2025:db8:10::17 vm_role=auditor
```

Guarda (Ctrl+O, Enter, Ctrl+X)

---

## ⚙️ Paso 5: Configurar el rol (desde el servidor)

```bash
cd ~/ansible-gestion-despliegue
bash scripts/vms/configure-ubuntu-desktop.sh
```

Esto:
- Lista las VMs en el inventario
- Te pide el nombre de la VM
- Configura permisos según el rol
- Instala paquetes necesarios
- Configura restricciones

---

## 📋 Resumen de configuraciones por rol

### 🔑 Admin
- **Usuario:** admin
- **IP ejemplo:** 2025:db8:10::21
- **Permisos:** Acceso total, puede SSH al servidor
- **Recursos:** 2 CPU, 4GB RAM, 50GB disco

### 📊 Auditor
- **Usuario:** auditor
- **IP ejemplo:** 2025:db8:10::22
- **Permisos:** Solo lectura de logs, NO puede SSH
- **Recursos:** 2 CPU, 3GB RAM, 30GB disco

### 🎮 Cliente
- **Usuario:** cliente
- **IP ejemplo:** 2025:db8:10::20
- **Permisos:** Solo juegos, NO puede SSH
- **Recursos:** 2 CPU, 4GB RAM, 40GB disco

---

## 🔧 Troubleshooting

### No tengo red IPv6
```bash
# Verificar interfaces
ip link show

# Verificar configuración
ip -6 addr show

# Reiniciar red
sudo systemctl restart NetworkManager
```

### No puedo hacer ping al servidor
```bash
# Verificar que el servidor esté encendido
ping6 2025:db8:10::2

# Verificar gateway
ip -6 route show

# Verificar DNS
cat /etc/resolv.conf
```

### La VM no aparece en el inventario
- Verifica que agregaste la VM en `inventory/hosts.ini`
- Verifica que la IP sea correcta
- Verifica que el servidor pueda hacer ping a la VM

---

## 🎯 Siguiente paso

Una vez configurado el Desktop:

1. **Probar acceso a juegos** (si es cliente)
2. **Probar acceso a logs** (si es auditor)
3. **Probar SSH al servidor** (si es admin)

Todo según el rol configurado. 🎮
