#!/bin/bash
cd ~/ansible
source ~/.ansible-venv/bin/activate

cat > /tmp/run-dhcp.yml <<EOF
---
- name: Ejecutar solo rol dhcpv6
  hosts: localhost
  connection: local
  become: true
  roles:
    - role: dhcpv6
EOF

ansible-playbook /tmp/run-dhcp.yml --become --ask-become-pass
rm /tmp/run-dhcp.yml
