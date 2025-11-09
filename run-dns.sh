#!/bin/bash
cd ~/ansible
source ~/.ansible-venv/bin/activate

cat > /tmp/run-dns.yml <<EOF
---
- name: Ejecutar solo rol dns_bind
  hosts: localhost
  connection: local
  become: true
  roles:
    - role: dns_bind
EOF

ansible-playbook /tmp/run-dns.yml --become --ask-become-pass
rm /tmp/run-dns.yml
