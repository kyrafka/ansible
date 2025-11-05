# 📋 CONFIGURACIÓN PARA TEMPLATE BASE

## 🎯 INSTALACIÓN MANUAL INICIAL:

### 1. **Instalación Ubuntu 24.04**
- Idioma: English (más compatible)
- Teclado: US o Spanish (tu preferencia)
- Red: DHCP automático
- Usuario: `labjuegos`
- Password: `123456`
- Hostname: `ubuntu-template`
- Instalar OpenSSH Server: **SÍ**

### 2. **Configuración post-instalación**
```bash
# Actualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar paquetes esenciales
sudo apt install -y \
    curl wget git htop net-tools iputils-ping \
    bind9 bind9utils bind9-doc \
    isc-dhcp-server \
    ufw fail2ban \
    rsyslog logrotate \
    python3 python3-pip \
    vim nano

# Habilitar IPv6
echo 'net.ipv6.conf.all.disable_ipv6 = 0' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv6.conf.default.disable_ipv6 = 0' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv6.conf.lo.disable_ipv6 = 0' | sudo tee -a /etc/sysctl.conf

# Configurar SSH para claves
sudo sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Crear directorio para Ansible
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Habilitar servicios básicos
sudo systemctl enable ssh
sudo systemctl enable bind9
sudo systemctl enable isc-dhcp-server
sudo systemctl enable ufw
sudo systemctl enable fail2ban

# Configurar firewall básico
sudo ufw --force enable
sudo ufw allow ssh
sudo ufw allow 53
sudo ufw allow 547

# Limpiar para template
sudo apt autoremove -y
sudo apt autoclean
history -c
```

### 3. **Preparar para template**
```bash
# Limpiar logs
sudo truncate -s 0 /var/log/*log

# Limpiar cache
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*

# Limpiar historial
history -c
> ~/.bash_history

# Apagar
sudo shutdown -h now
```

## 🎯 DESPUÉS DE APAGAR:

1. **Convertir a template en ESXi**
2. **Yo creo el script de clonado automático**
3. **Script configurará hostname, IP, servicios específicos**

## ✅ VENTAJAS DEL TEMPLATE:

- ⚡ **Creación instantánea** (30 segundos vs 15 minutos)
- 🎯 **100% confiable** (no depende de autoinstall)
- 🔧 **Fácil personalización** por script
- 📦 **Base limpia** y optimizada