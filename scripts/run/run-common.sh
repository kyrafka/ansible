#!/bin/bash
cd ~/ansible
source ~/.ansible-venv/bin/activate
ansible-playbook -i localhost, -c local site.yml --become --ask-become-pass --tags common -e "ansible_python_interpreter=/usr/bin/python3" || \
ansible-playbook site.yml --connection=local --become --ask-become-pass -e '{"roles_to_run":["common"]}'
