
#!/bin/bash

read -rp "Enter Terraform statefile bucket: " bucket
read -rp "Enter Terraform statefile key: " key

terraform init -backend-config="bucket=$bucket" -backend-config="key=$key" -backend-config='region=eu-west-2'
