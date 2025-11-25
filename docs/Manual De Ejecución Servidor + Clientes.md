# 🎯 COMANDOS Y SCRIPTS FINALES - EJECUTAR DESDE EL SERVIDOR

## 📋 ÍNDICE
1. [Configurar Servidor](#1-configurar-servidor)
2. [Configurar Windows 11](#2-configurar-windows-11)
3. [Validar Configuraciones](#3-validar-configuraciones)

---

## 1️⃣ CONFIGURAR SERVIDOR

### A. Ejecutar Playbook Principal
```bash
# Configurar todos los servicios del servidor
ansible-playbook site.yml --connection=local --become --ask-become-pass
```

**Servicios que configura:**
- ✅ DNS (BIND9)
- ✅ DHCP IPv6
- ✅ Firewall (UFW + fail2ban)
- ✅ NFS
- ✅ Samba
- ✅ FTP (vsftpd)
- ✅ Usuarios del servidor

---

### B. Verificar Servicios del Servidor
```bash
# Script completo de verificación
bash scripts/diagnostics/show-server-config.sh
```

**O comandos individuales:**
```bash
# DNS
sudo systemctl status bind9

# DHCP
sudo systemctl status isc-dhcp-server6

# Firewall
sudo ufw status verbose

# Samba
sudo systemctl status smbd
sudo smbstatus

# FTP
sudo systemctl status vsftpd

# NFS
sudo systemctl status nfs-server
```

---

## 2️⃣ CONFIGURAR WINDOWS 11

### A. Probar Conexión a Windows
```bash
# Verificar que WinRM funciona
bash scripts/server/test-windows-connection.sh
```

### B. Configurar Windows (Usuarios + Carpetas + Firewall)
```bash
# Ejecutar configuración completa
bash scripts/server/configure-windows.sh
```

**O ejecutar playbook directamente:**
```bash
ansible-playbook -i inventory/windows.ini playbooks/configure-windows.yml
```

**Crea:**
- ✅ Usuario `dev` (contraseña: 123!123)
- ✅ Usuario `cliente` (contraseña: 123!123)
- ✅ Carpeta `C:\Compartido`
- ✅ Carpeta `C:\Dev`
- ✅ Firewall configurado (Ping + Compartir archivos)

---

### C. Verificar Configuración de Windows
```bash
# Ver configuración de Windows desde el servidor
bash scripts/server/mostrar-windows-config.sh
```

---

## 3️⃣ VALIDAR CONFIGURACIONES

### A. Validar Servidor
```bash
# Pruebas de funcionamiento del servidor
bash scripts/diagnostics/test-server-functionality.sh
```

### B. Generar Evidencias Completas
```bash
# Generar todas las evidencias para la rúbrica
bash scripts/diagnostics/generate-full-evidence.sh
```

---

## 📊 RESUMEN DE SCRIPTS POR FUNCIONALIDAD

### 🔧 CONFIGURACIÓN

| Script | Descripción | Configura |
|--------|-------------|-----------|
| `site.yml` | Playbook principal del servidor | Servidor |
| `scripts/server/configure-windows.sh` | Configurar Windows 11 | Windows |
| `playbooks/configure-windows.yml` | Playbook de Windows | Windows |

### ✅ VALIDACIÓN

| Script | Descripción | Valida |
|--------|-------------|--------|
| `scripts/diagnostics/show-server-config.sh` | Mostrar config del servidor | Servidor |
| `scripts/diagnostics/test-server-functionality.sh` | Probar servicios del servidor | Servidor |
| `scripts/server/test-windows-connection.sh` | Probar conexión a Windows | Windows |
| `scripts/server/mostrar-windows-config.sh` | Mostrar config de Windows | Windows |
| `scripts/diagnostics/generate-full-evidence.sh` | Generar evidencias completas | Todo |

### 🧪 PRUEBAS

| Script | Descripción | Prueba |
|--------|-------------|--------|
| `scripts/server/demo-windows-ansible.sh` | Demo de Ansible → Windows | Windows |

---

## 🚀 ORDEN DE EJECUCIÓN RECOMENDADO

### PASO 1: Configurar Servidor
```bash
ansible-playbook site.yml --connection=local --become --ask-become-pass
```

### PASO 2: Verificar Servidor
```bash
bash scripts/diagnostics/show-server-config.sh
```

### PASO 3: Configurar Windows
```bash
bash scripts/server/configure-windows.sh
```

### PASO 4: Verificar Windows
```bash
bash scripts/server/mostrar-windows-config.sh
```

### PASO 5: Generar Evidencias
```bash
bash scripts/diagnostics/generate-full-evidence.sh
```

---

## 📝 NOTAS IMPORTANTES

### ⚠️ Antes de ejecutar:
1. Asegúrate de que Windows tiene WinRM configurado
2. Verifica que el inventario `inventory/windows.ini` tiene la IP correcta de Windows
3. Verifica que `ansible.cfg` existe en la raíz del proyecto

### ✅ Después de ejecutar:
1. Verifica que todos los servicios están activos
2. Prueba la conectividad desde Ubuntu Desktop
3. Toma capturas de pantalla para la rúbrica

---

## 🎯 PARA LA DEMOSTRACIÓN

### Comandos rápidos para mostrar:
```bash
# 1. Servicios del servidor
sudo systemctl status bind9 smbd vsftpd

# 2. Usuarios de Windows
ansible win11 -i inventory/windows.ini -m ansible.windows.win_shell -a "Get-LocalUser | Format-Table Name, Enabled"

# 3. Carpetas de Windows
ansible win11 -i inventory/windows.ini -m ansible.windows.win_shell -a "Get-ChildItem C:\\ | Where-Object {\$_.Name -match 'Compartido|Dev'}"

# 4. Samba funcionando
smbclient -L //2025:db8:10::2 -N

# 5. FTP funcionando
echo "quit" | ftp 2025:db8:10::2
```

---

**¡TODO LISTO PARA DEMOSTRAR NIVEL 4!** 🎉
