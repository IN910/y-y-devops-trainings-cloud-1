#!/bin/bash
echo "[yandex_ig_vms]" > $WORK_DIR/ansible/hosts.txt
terraform output -state="$WORK_DIR/terraform/terraform.tfstate" vms | tr -d '[],"' | tr -s " " "\n"| sed '/^$/d' >> $WORK_DIR/ansible/hosts.txt
