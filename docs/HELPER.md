# ⚡ GUÍA DE EJECUCIÓN Y SCRIPTS DE APOYO
## Gestión y Despliegue de Sistemas Operativos con Ansible

---

### 📋 INFORMACIÓN DEL PROYECTO

**Curso:** Sistemas Operativos  
**Ciclo:** 6  
**Fecha:** Noviembre 2025

**Autores:**
- Boris Quispe
- Jose Zuñiga

**Docente:**  
Alex Roberto Villegas Cervera

**Repositorio:**  
https://github.com/kyrafka/ansible

---

## 🎯 EJECUCIÓN PRINCIPAL

### EN EL SERVIDOR UBUNTU
```bash
cd ~/ansible
ansible-playbook site.yml --connection=local --become --ask-become-pass
```

---

## 📋 SCRIPTS DE DIAGNÓSTICO Y VERIFICACIÓN

### 🔍 Servidor - Verificar Configuración
```bash
# Mostrar configuración completa del servidor
bash scripts/diagnostics/show-server-config.sh

# Verificar funcionalidad de servicios
bash scripts/diagnostics/test-server-functionality.sh

# Estado rápido de todos los servicios
bash scripts/diagnostics/quick-status.sh

# Verificar que el servidor está listo
bash scripts/diagnostics/check-server-ready.sh

# Verificar servicios individuales
bash scripts/diagnostics/check-services.sh
```

### 🖥️ Cliente Ubuntu Desktop - Verificar Configuración
```bash
# Mostrar usuarios y grupos creados
bash scripts/client/mostrar-usuarios-grupos.sh

# Mostrar particiones configuradas
bash scripts/client/mostrar-particiones.sh

# Verificar permisos de usuarios
bash scripts/diagnostics/check-user-permissions.sh

# Verificar que el cliente está listo
bash scripts/diagnostics/check-client-ready.sh

# Probar conectividad Samba y FTP
bash scripts/client/test-samba-ftp.sh
```

### 🪟 Windows - Verificar Configuración
```bash
# Desde el servidor, probar conexión a Windows
bash scripts/server/test-windows-connection.sh

# Mostrar configuración de Windows
bash scripts/server/mostrar-windows-config.sh
```

```powershell
# Desde Windows, mostrar configuración local
.\scripts\windows\mostrar-configuracion.ps1
```

### 🌐 Conectividad y Red
```bash
# Diagnóstico completo de conectividad
bash scripts/diagnostics/diagnose-connectivity.sh

# Test de conectividad de red
bash scripts/diagnostics/test-network-connectivity.sh

# Verificar DNS
bash scripts/diagnostics/check-dns-now.sh
bash scripts/diagnostics/test-dns-records.sh

# Diagnóstico completo de DNS
bash scripts/diagnostics/diagnose-dns-complete.sh
```

---

## 🛠️ SCRIPTS DE CONFIGURACIÓN Y SETUP

### Servidor
```bash
# Setup completo del servidor (alternativa a Ansible)
bash scripts/server/setup-server.sh

# Configurar Windows remotamente desde el servidor
bash scripts/server/configure-windows.sh

# Crear usuarios en Windows
bash scripts/server/create-windows-users.sh
```

### Cliente Ubuntu Desktop
```bash
# Setup completo del cliente
bash scripts/client/setup-ubuntu-desktop.sh

# Configurar usuarios y temas
bash scripts/client/setup-users-and-themes.sh

# Configurar particiones
bash scripts/client/configurar-particiones.sh

# Optimizar para gaming
bash scripts/client/optimize-gaming.sh
```

### Windows
```powershell
# Configurar WinRM para gestión remota
.\scripts\windows\setup-winrm-simple.bat

# O con PowerShell
.\scripts\windows\setup-winrm-remote.ps1

# Probar Samba y FTP desde Windows
.\scripts\windows\test-samba-ftp.ps1
```

---

## 🚀 SCRIPTS DE EJECUCIÓN MODULAR

### Ejecutar roles individuales
```bash
# Ejecutar un rol específico
bash scripts/run/run-role.sh <nombre_rol>

# Ejemplos:
bash scripts/run/run-role.sh dns
bash scripts/run/run-role.sh dhcp
bash scripts/run/run-role.sh firewall
```

### Ejecutar servicios específicos
```bash
bash scripts/run/run-dns.sh
bash scripts/run/run-dhcp.sh
bash scripts/run/run-firewall.sh
bash scripts/run/run-network.sh
bash scripts/run/run-storage.sh
bash scripts/run/run-services.sh
bash scripts/run/run-users.sh
bash scripts/run/run-web.sh
```

### Validar configuraciones
```bash
bash scripts/run/validate-all.sh
bash scripts/run/validate-dns.sh
bash scripts/run/validate-dhcp.sh
bash scripts/run/validate-firewall.sh
bash scripts/run/validate-network.sh
bash scripts/run/validate-storage.sh
```

---

## 📊 GENERACIÓN DE EVIDENCIAS

```bash
# Generar evidencias completas para la rúbrica
bash scripts/diagnostics/generate-full-evidence.sh
```

---

## 🔧 SETUP INICIAL (Solo primera vez)

```bash
# Configurar entorno de Ansible
bash scripts/setup/setup-ansible-env.sh

# Verificar entorno de Ansible
bash scripts/diagnostics/check-ansible-env.sh

# Habilitar acceso SSH
bash scripts/setup/enable-ssh-access.sh
```

---

## 📝 NOTAS

- **Scripts de fix eliminados**: Todo funciona desde el playbook principal
- **Scripts de VirtualBox eliminados**: Ya no son necesarios
- **Scripts de NAT64 disponibles**: En `scripts/nat64/` si se necesitan en el futuro
- **Todos los scripts son idempotentes**: Se pueden ejecutar múltiples veces sin problemas

---

**Proyecto:** Gestión y Despliegue de Sistemas Operativos  
**Curso:** Sistemas Operativos - Ciclo 6  
**Fecha:** Noviembre 2025  
**Autores:** Boris Quispe, Jose Zuñiga  
**Docente:** Alex Roberto Villegas Cervera
