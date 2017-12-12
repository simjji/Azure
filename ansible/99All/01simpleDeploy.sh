#!/bin/bash
set -euo pipefail

cd ../02vmWithARM
/bin/bash 00.azuredeploy.sh -g boraVMR01 -n vmWithAnsible -u bochoi -r minschoVaultRG01 -v boraVault -s boraPub -c dummy-init.yaml
cd ../04CommonTasks
/usr/local/bin/ansible-playbook common_tasks.yml

