# 📋 Patrón de Mensajes para Playbooks Ansible

## 🎯 Objetivo

Hacer que los playbooks sean claros sobre:
- **SKIPPED**: Por qué se saltó y si es normal
- **CHANGED**: Qué cambió y por qué
- **OK**: Confirmar que todo está bien

## 📝 Patrones Recomendados

### 1. Verificaciones (stat, command con changed_when: false)

```yaml
- name: "🔍 Verificar si existe archivo X"
  stat:
    path: /ruta/al/archivo
  register: archivo_existe
  changed_when: false  # ← IMPORTANTE: Solo verifica, no cambia nada

- name: "📊 Estado del archivo"
  debug:
    msg: |
      {% if archivo_existe.stat.exists %}
      ✅ Archivo encontrado: /ruta/al/archivo
      → Tamaño: {{ archivo_existe.stat.size }} bytes
      → Última modificación: {{ archivo_existe.stat.mtime }}
      {% else %}
      ⚠️  Archivo NO encontrado: /ruta/al/archivo
      → Esto es NORMAL en primera instalación
      → Se creará en el siguiente paso
      {% endif %}
```

### 2. Tareas Condicionales (when)

```yaml
- name: "🔧 Copiar archivo de configuración"
  copy:
    src: /origen/config
    dest: /destino/config
  when: archivo_existe.stat.exists
  register: copia_resultado

- name: "📊 Resultado de copia"
  debug:
    msg: |
      {% if copia_resultado.changed %}
      ✅ CHANGED: Archivo copiado exitosamente
      → Motivo: Primera instalación o archivo actualizado
      → Acción: Se aplicará nueva configuración
      {% elif copia_resultado.skipped is defined %}
      ⏭️  SKIPPED: Copia omitida
      → Motivo: Archivo origen no existe
      → Esto es NORMAL si [explicar por qué]
      {% else %}
      ✅ OK: Archivo ya estaba actualizado
      → No se necesitaron cambios
      {% endif %}
  when: copia_resultado is defined
```

### 3. Instalación de Paquetes

```yaml
- name: "📦 Instalar paquete X"
  apt:
    name: paquete-x
    state: present
  register: instalacion_resultado

- name: "📊 Resultado de instalación"
  debug:
    msg: |
      {% if instalacion_resultado.changed %}
      ✅ CHANGED: Paquete instalado/actualizado
      → Paquete: paquete-x
      → Versión: {{ instalacion_resultado.stdout | default('N/A') }}
      → Acción: Nueva instalación o actualización aplicada
      {% else %}
      ✅ OK: Paquete ya estaba instalado
      → Versión actual es la correcta
      → No se necesitaron cambios
      {% endif %}
```

### 4. Servicios (systemd)

```yaml
- name: "🔄 Reiniciar servicio X"
  systemd:
    name: servicio-x
    state: restarted
  register: servicio_resultado

- name: "📊 Estado del servicio"
  debug:
    msg: |
      {% if servicio_resultado.changed %}
      ✅ CHANGED: Servicio reiniciado
      → Servicio: servicio-x
      → Motivo: Aplicar cambios de configuración
      → Estado: {{ servicio_resultado.status.ActiveState | default('activo') }}
      {% else %}
      ✅ OK: Servicio ya estaba en el estado correcto
      → No se necesitó reiniciar
      {% endif %}
```

### 5. Comandos que Siempre Cambian

```yaml
- name: "🔄 Recargar configuración"
  command: rndc reload
  register: recarga_resultado
  changed_when: true  # ← Siempre marca como changed
  failed_when: recarga_resultado.rc != 0

- name: "📊 Resultado de recarga"
  debug:
    msg: |
      ✅ CHANGED: Configuración recargada
      → Comando: rndc reload
      → Motivo: Aplicar cambios en zonas DNS
      → Salida: {{ recarga_resultado.stdout }}
```

### 6. Tareas Opcionales

```yaml
- name: "🔍 Verificar si UFW está instalado"
  command: which ufw
  register: ufw_check
  failed_when: false
  changed_when: false

- name: "🛡️  Configurar firewall (UFW)"
  ufw:
    rule: allow
    port: 53
  when: ufw_check.rc == 0
  register: firewall_resultado

- name: "📊 Estado del firewall"
  debug:
    msg: |
      {% if ufw_check.rc != 0 %}
      ⏭️  SKIPPED: Configuración de UFW omitida
      → Motivo: UFW no está instalado
      → Esto es NORMAL si usas otro firewall
      → Acción: Configura el firewall manualmente
      {% elif firewall_resultado.changed %}
      ✅ CHANGED: Regla de firewall agregada
      → Puerto: 53 (DNS)
      → Protocolo: TCP/UDP
      {% else %}
      ✅ OK: Regla de firewall ya existía
      → No se necesitaron cambios
      {% endif %}
```

## 🎨 Emojis Recomendados

- `🔍` - Verificación/Búsqueda
- `📊` - Resultado/Estado
- `✅` - Éxito/OK
- `⚠️` - Advertencia (pero normal)
- `❌` - Error
- `⏭️` - Skipped
- `🔧` - Configuración
- `📦` - Instalación
- `🔄` - Reinicio/Recarga
- `🛡️` - Firewall/Seguridad
- `🔑` - Claves/Autenticación
- `🌐` - Red/DNS
- `💾` - Almacenamiento
- `⏸️` - Pausa/Espera

## 📋 Checklist para Cada Tarea

- [ ] ¿Tiene `changed_when: false` si solo verifica?
- [ ] ¿Tiene `register:` para capturar el resultado?
- [ ] ¿Tiene un `debug:` después explicando el resultado?
- [ ] ¿Explica por qué se saltó (SKIPPED)?
- [ ] ¿Explica qué cambió (CHANGED)?
- [ ] ¿Confirma que está OK si no cambió nada?

## 🚫 Evitar

```yaml
# ❌ MAL: No explica nada
- name: "Copiar archivo"
  copy:
    src: file
    dest: /etc/file
  when: condition

# ✅ BIEN: Explica todo
- name: "📋 Copiar archivo de configuración"
  copy:
    src: file
    dest: /etc/file
  when: condition
  register: resultado

- name: "📊 Resultado de copia"
  debug:
    msg: |
      {% if resultado.changed %}
      ✅ CHANGED: Archivo copiado
      → Motivo: [explicar]
      {% elif resultado.skipped is defined %}
      ⏭️  SKIPPED: [explicar por qué es normal]
      {% else %}
      ✅ OK: Ya estaba actualizado
      {% endif %}
  when: resultado is defined
```

## 🎯 Ejemplo Completo

```yaml
---
# Configurar servicio X

- name: "🔍 Verificar si servicio X está instalado"
  command: which servicio-x
  register: servicio_instalado
  failed_when: false
  changed_when: false

- name: "📊 Estado de instalación"
  debug:
    msg: |
      {% if servicio_instalado.rc == 0 %}
      ✅ Servicio X encontrado: {{ servicio_instalado.stdout }}
      {% else %}
      ⚠️  Servicio X NO instalado
      → Se instalará en el siguiente paso
      {% endif %}

- name: "📦 Instalar servicio X"
  apt:
    name: servicio-x
    state: present
  when: servicio_instalado.rc != 0
  register: instalacion

- name: "📊 Resultado de instalación"
  debug:
    msg: |
      {% if instalacion.changed %}
      ✅ CHANGED: Servicio X instalado
      → Primera instalación completada
      {% elif instalacion.skipped is defined %}
      ⏭️  SKIPPED: Instalación omitida
      → Motivo: Servicio ya estaba instalado
      → Esto es NORMAL en re-ejecuciones
      {% else %}
      ✅ OK: Servicio ya instalado
      {% endif %}
  when: instalacion is defined

- name: "🔧 Configurar servicio X"
  template:
    src: config.j2
    dest: /etc/servicio-x/config
  register: configuracion
  notify: restart servicio-x

- name: "📊 Resultado de configuración"
  debug:
    msg: |
      {% if configuracion.changed %}
      ✅ CHANGED: Configuración actualizada
      → Archivo: /etc/servicio-x/config
      → Acción: Servicio se reiniciará automáticamente
      {% else %}
      ✅ OK: Configuración ya estaba actualizada
      → No se necesitó reiniciar el servicio
      {% endif %}
```

## 🔄 Aplicar a Roles Existentes

Para actualizar roles existentes:

1. Buscar tareas con `when:`
2. Agregar `register:` si no lo tiene
3. Agregar `debug:` después explicando el resultado
4. Agregar `changed_when: false` a verificaciones
5. Usar emojis para claridad visual

## ════════════════════════════════════════════════════════════════
