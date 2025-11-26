# Rol: windows11

## Descripción
Configura Windows 11 con usuarios, carpetas compartidas y firewall para integración con la red IPv6.

## Requisitos
- Windows 11 con WinRM habilitado
- Conexión IPv6 funcional
- Ansible con colección `ansible.windows` instalada

## Variables
No requiere variables adicionales. Las contraseñas están hardcodeadas (123!123).

## Tareas principales
1. **Crear usuarios**: dev y cliente
2. **Crear carpetas**: C:\Compartido y C:\Dev
3. **Configurar permisos**: Permisos diferenciados por usuario
4. **Configurar firewall**: ICMPv6, compartir archivos, WinRM
5. **Verificar IPv6**: Confirma que DHCP asignó dirección

## Uso
```yaml
- hosts: windows
  roles:
    - windows11
```

O desde el playbook existente:
```bash
ansible-playbook -i inventory/hosts-windows.ini playbooks/configure-windows.yml
```

## Usuarios creados
- **dev**: Desarrollador con control total en C:\Dev
- **cliente**: Usuario estándar con acceso a C:\Compartido

## Carpetas creadas
- **C:\Compartido**: Todos los usuarios pueden modificar
- **C:\Dev**: dev tiene control total, otros solo lectura

## Firewall
- ICMPv6 (ping) habilitado
- Compartir archivos e impresoras habilitado
- WinRM (puerto 5985) habilitado

## Notas
- Las contraseñas son de prueba (123!123)
- En producción, usar variables vault para contraseñas
- WinRM debe estar previamente configurado en Windows
