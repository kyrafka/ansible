# 📁 Scripts del Proyecto Ansible IPv6

## 🚀 Scripts Principales

### **Gestión de VMs**
- **`vm-manager.sh`** - 🎮 **Gestor interactivo completo**
  - Menú principal para gestionar VMs
  - Crear, encender, apagar, eliminar VMs
  - Detectar recursos disponibles
  
- **`create-vm-auto.sh`** - ⚡ **Creación automática rápida**
  - Crea VM sin preguntas (testing rápido)
  - Usa credenciales del vault
  - Nombre único automático
  
- **`create-vm-vault.sh`** - 🔐 **Creación con vault cifrado**
  - Usa ansible-vault correctamente
  - Más seguro para producción
  - Pide password del vault

### **Despliegue de Servicios**
- **`deploy-to-server.sh`** - 🌐 **Configurar servicios IPv6**
  - Despliega DNS, DHCP, Firewall
  - Configura red IPv6 2025:db8:10::/64
  - Ejecuta roles de Ansible

## 🧪 Scripts de Testing

### **Validación de Ansible**
- **`test-ansible-syntax.sh`** - ✅ **Verificar sintaxis**
  - Valida playbooks y roles
  - Detecta errores de YAML
  
- **`test-jinja-templates.sh`** - 📝 **Probar templates**
  - Genera templates Jinja2
  - Verifica configuraciones dinámicas

### **Testing de Servicios**
- **`test-service-configs.sh`** - ⚙️ **Probar configuraciones**
  - Valida configs de DNS, DHCP, etc.
  - Testing local sin servidor
  
- **`test-logging-local.sh`** - 📊 **Probar logging**
  - Verifica rsyslog y logrotate
  - Testing de monitoreo

- **`test-security-local.sh`** - 🔒 **Probar seguridad**
  - Valida firewall y fail2ban
  - Testing de configuraciones de seguridad

### **Testing de Red**
- **`test-network-connectivity.sh`** - 🌐 **Probar conectividad**
  - Verifica conexiones IPv6
  - Testing de red

- **`test-ssh-ubpc.sh`** - 🔑 **Probar SSH**
  - Valida conexiones SSH
  - Testing de acceso remoto

## 🔧 Utilidades

### **Gestión de Vault**
- **`run-with-vault.sh`** - 🔓 **Ejecutar con vault**
  - Ejecuta comandos con credenciales cifradas
  - Manejo seguro de passwords
  
- **`secure-vault.sh`** - 🔐 **Cifrar vault**
  - Cifra/descifra archivos vault
  - Gestión de credenciales

### **Configuración del Sistema**
- **`security-hardening.sh`** - 🛡️ **Hardening de seguridad**
  - Configuraciones de seguridad adicionales
  - Optimizaciones del sistema

- **`setup-wsl2.ps1`** - 🪟 **Setup WSL2**
  - Configuración inicial de WSL2
  - Instalación de dependencias

### **Verificación**
- **`verificar-proyecto.sh`** - 🔍 **Verificar proyecto**
  - Valida estructura completa
  - Detecta archivos faltantes
  
- **`verificar-particiones.sh`** - 💾 **Verificar particiones**
  - Valida configuración de storage
  - Verifica LVM y particiones

## 📋 Uso Recomendado

### **Para Development/Testing:**
```bash
# Crear VM rápida para testing
./scripts/create-vm-auto.sh

# Probar configuraciones localmente
./scripts/test-service-configs.sh
./scripts/test-jinja-templates.sh
```

### **Para Producción:**
```bash
# Gestión completa interactiva
./scripts/vm-manager.sh

# O creación segura con vault
./scripts/create-vm-vault.sh

# Desplegar servicios
./scripts/deploy-to-server.sh
```

### **Para Validación:**
```bash
# Verificar todo el proyecto
./scripts/verificar-proyecto.sh

# Probar sintaxis de Ansible
./scripts/test-ansible-syntax.sh
```

## 🎯 Scripts por Caso de Uso

| Caso de Uso | Script Recomendado |
|-------------|-------------------|
| **Testing rápido** | `create-vm-auto.sh` |
| **Gestión completa** | `vm-manager.sh` |
| **Producción segura** | `create-vm-vault.sh` |
| **Validar código** | `test-ansible-syntax.sh` |
| **Probar templates** | `test-jinja-templates.sh` |
| **Configurar servicios** | `deploy-to-server.sh` |