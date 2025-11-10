# 🏗️ Arquitectura del Proyecto Ansible

## 📍 Escenario de Ejecución

Este proyecto Ansible tiene **DOS modos de operación diferentes**:

### 1️⃣ Configuración del Servidor (localhost)

**Playbooks:** `site.yml`, `site-interactive.yml`

**Dónde se ejecuta:** DENTRO del servidor Ubuntu en ESXi (172.17.25.45)

**Cómo se ejecuta:**
```bash
# Conectarse a la VM por consola de ESXi
# Dentro de la VM:
cd ~/ansible
source ~/.ansible-venv/bin/activate
ansible-playbook site.yml --connection=local --become --ask-become-pass
```

**Por qué `localhost`:**
- El firewall de ESXi bloquea SSH desde el exterior
- Ansible se ejecuta DENTRO de la VM que se va a configurar
- `hosts: localhost` + `connection: local` = "configúrate a ti mismo"

**Qué configura:**
- Red IPv6 en ens34
- DNS (BIND9)
- DHCP IPv6
- Firewall (UFW)
- Storage (NFS)

---

### 2️⃣ Gestión de VMs (inventario remoto)

**Playbooks:** `playbooks/create-*.yml`, `playbooks/configure-*.yml`

**Dónde se ejecuta:** Puede ser desde el PC local O desde el servidor

**Cómo se ejecuta:**
```bash
# Crear VMs en ESXi (usa govc, no SSH)
ansible-playbook playbooks/create-ubuntu-desktop.yml

# Configurar VMs después de crearlas (cuando tengan SSH habilitado)
ansible-playbook playbooks/configure-ubuntu-role.yml -i inventory/hosts.ini
```

**Inventario:** `inventory/hosts.ini`
```ini
[servers]
ubuntu-server ansible_host=172.17.25.45 ansible_user=ubuntu

[ubuntu_desktops]
# VMs que se crearán después
```

---

## ⚠️ Errores Comunes a Evitar

### ❌ Error #1: Confundir localhost con remoto
```yaml
# ❌ MAL: Intentar configurar el servidor desde el PC
hosts: servers  # No funciona, SSH bloqueado
```

```yaml
# ✅ BIEN: Configurar el servidor desde dentro
hosts: localhost
connection: local
```

### ❌ Error #2: Olvidar `become: true`
```yaml
# ❌ MAL: Tareas que necesitan root sin permisos
- name: Instalar paquetes
  apt:
    name: bind9
  # Falla con "Permission denied"
```

```yaml
# ✅ BIEN: Especificar permisos a nivel de play
- name: Configurar servidor
  hosts: localhost
  become: true  # ← Todas las tareas heredan esto
```

### ❌ Error #3: Ejecutar desde el lugar equivocado
```bash
# ❌ MAL: Ejecutar site.yml desde tu PC
# (No funcionará porque usa localhost)
ansible-playbook site.yml

# ✅ BIEN: Ejecutar desde DENTRO del servidor
ssh usuario@172.17.25.45  # (si tuvieras SSH)
# O conectar por consola ESXi
ansible-playbook site.yml --connection=local --become --ask-become-pass
```

---

## 📋 Checklist de Auditoría

Antes de ejecutar un playbook, pregúntate:

1. **¿Dónde estoy ejecutando esto?**
   - En el servidor → Usa `localhost`
   - Desde mi PC → Usa inventario (si SSH funciona)

2. **¿Las tareas necesitan root?**
   - apt, systemd, ufw, iptables → SÍ
   - Asegúrate de tener `become: true`

3. **¿Tengo conectividad?**
   - localhost → Siempre funciona
   - SSH → Verifica con `ansible servers -m ping`

4. **¿El inventario es correcto?**
   - Verifica IPs y usuarios en `inventory/hosts.ini`

---

## 🎯 Resumen

| Tarea | Dónde ejecutar | Playbook | Hosts |
|-------|----------------|----------|-------|
| Configurar servidor | Dentro del servidor | `site.yml` | `localhost` |
| Crear VMs | Servidor o PC | `playbooks/create-*.yml` | `localhost` |
| Configurar VMs | Servidor (cuando SSH funcione) | `playbooks/configure-*.yml` | `ubuntu_desktops` |

**Tu configuración actual es CORRECTA para tu escenario.** ✅
