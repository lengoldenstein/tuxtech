#!/bin/sh
#date
#ansible-playbook tuxtech-main.yml --tags provision --limit foreman1.tuxtech.com 
date
ansible-playbook tuxtech-main.yml --tags provision --limit idm1.tuxtech.com 
date
ansible-playbook tuxtech-main.yml --tags provision --limit idm2.tuxtech.com 
date
ansible-playbook tuxtech-main.yml --tags provision --limit web
date
