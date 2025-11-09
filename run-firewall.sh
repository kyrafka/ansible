#!/bin/bash
# Script para ejecutar solo el rol de firewall

cd ~/ansible
source ~/.ansible-venv/bin/activate
ansible-playbook site.yml --connection=local --become --ask-become-pass --tags firewall
