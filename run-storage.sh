#!/bin/bash
cd ~/ansible
source ~/.ansible-venv/bin/activate

cat > /tmp/run-storage.yml <<EOF
---
- name: Ejecutar solo rol storage
  hosts: localhost
  connection: local
  become: true
  roles:
    - role: storage
EOF

ansible-playbook /tmp/run-storage.yml --become --ask-become-pass
rm /tmp/run-storage.yml
