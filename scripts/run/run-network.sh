#!/bin/bash
cd ~/ansible
source ~/.ansible-venv/bin/activate

cat > /tmp/run-network.yml <<EOF
---
- name: Ejecutar solo rol network
  hosts: localhost
  connection: local
  become: true
  roles:
    - role: network
EOF

ansible-playbook /tmp/run-network.yml --become --ask-become-pass
rm /tmp/run-network.yml
