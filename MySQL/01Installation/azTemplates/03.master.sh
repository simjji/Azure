#!/bin/bash
az group create --name boraMysqlRG01 --location koreacentral
az group deployment create --name networkForMysqlDeployment --resource-group boraNetRg02 \
--template-file 00.mysqlNet.json \
--parameters vnet_name=boraVnet01 \
--parameters subnet_name=testSubnet01 \
--parameters publicip_name=mysqlSingleNodeIP \
--parameters dnsPrefix=boramysqltest01 \
--parameters nic_name=mysqlTestNic01


az group deployment create --name createVM --resource-group boraMysqlRG01 --template-file 02.vm.json \
--parameters vm_name=mysqlTestVM01 \
--parameters adminUserId=bora \
--parameters nic_name=mysqlTestNic01

# disk 두 개 만듬
az group deployment create --name createDataDisk --resource-group boraMysqlRG01 --template-file 01.dataDisk.json \
--parameters dataDisk_name=mysqlDataDisk01
az group deployment create --name createDataDisk --resource-group boraMysqlRG01 --template-file 01.dataDisk.json \
--parameters dataDisk_name=mysqlDataDisk02

# data disk attach
az vm disk attach --vm-name mysqlTestVM01 --disk mysqlDataDisk01 --lun 0 --resource-group boraMysqlRG01
az vm disk attach --vm-name mysqlTestVM01 --disk mysqlDataDisk02 --lun 1 --resource-group boraMysqlRG01

#disk lun 확인
az vm show --resource-group boraMysqlRG01 --name mysqlTestVM01 | jq -r .storageProfile.dataDisks
az vm show --resource-group boraMysqlRG01 --name mysqlTestVM01 | jq -r .storageProfile.dataDisks[].lun

#개인 Vault  그룹 생성
az group create --name boraVaultRG01 --location koreacentral
az keyvault create --name boraVault01 --resource-group boraVaultRG01
az keyvault secret set --vault-name 'boraVault01' --name 'boraMysqlRoot'

#<pub key 파일위치>
az keyvault secret list --vault-name boraVault01
az keyvault secret show --vault-name boraVault01 --name boraPub01

