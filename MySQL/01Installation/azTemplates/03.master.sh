#!/bin/bash

az group deployment create --name networkForMysqlDeployment --resource-group jisimNetRG01 \
--template-file 00.mysqlNet.json \
--parameters vnet_name=jisimVnet01 \
--parameters subnet_name=testSubnet01 \
--parameters publicip_name=mysqlSingleNodeIP \
--parameters dnsPrefix=jisimmysqltest01 \
--parameters nic_name=mysqlTestNIC01

az group create --name jisimMysqlRG01 --location koreacentral
az group deployment create --name createVM --resource-group jisimMysqlRG01 --template-file 02.vm.json \
--parameters vm_name=mysqlTestVM01 \
--parameters adminUserId=jisim \
--parameters nic_name=mysqlTestNIC01

# disk 두 개 만듬
az group deployment create --name createDataDisk --resource-group jisimMysqlRG01 --template-file 01.dataDisk.json \
--parameters dataDisk_name=mysqlDataDisk01
az group deployment create --name createDataDisk --resource-group jisimMysqlRG01 --template-file 01.dataDisk.json \
--parameters dataDisk_name=mysqlDataDisk02

# data disk attach
az vm disk attach --vm-name mysqlTestVM01 --disk mysqlDataDisk01 --lun 0 --resource-group jisimMysqlRG01
az vm disk attach --vm-name mysqlTestVM01 --disk mysqlDataDisk02 --lun 1 --resource-group jisimMysqlRG01

#disk lun 확인
az vm show --resource-group jisimMysqlRG01 --name mysqlTestVM01 | jq -r .storageProfile.dataDisks
az vm show --resource-group jisimMysqlRG01 --name mysqlTestVM01 | jq -r .storageProfile.dataDisks[].lun


# Disk 준비 (fdisk를 사용하여 서버에서 디스크 준비)
(echo n; echo p; echo 1; echo ; echo ; echo w) | sudo fdisk /dev/sdc
sudo mkfs -t ext4 /dev/sdc1
sudo mkdir /data01 && sudo mount /dev/sdc1 /data01
#df -h 로 확인
# 다시 부팅 후 드라이브가 다시 탑재되도록 하려면 /etc/fstab 파일에 추가해야 합니다. 이렇게 하려면 blkid 유틸리티를 사용하여 디스크의 UUID를 가져옵니다.
sudo -i blkid
vi /etc/fstab
#UUID=33333333-3b3b-3c3c-3d3d-3e3e3e3e3e3e   /data01  ext4    defaults   1  2


#개인 Vault  그룹 생성
az group create --name jisimVaultRG01 --location koreacentral
az keyvault create --name jisimVault --resource-group jisimVaultRG01
#### az keyvault secret set --vault-name 'jisimVault01' --name 'jisimMysqlRoot'
az keyvault secret set --vault-name 'jisimVault' --name 'jisimPub' --file /Users/jisim/.ssh/jisim_ebay.com.pub

#<pub key 파일위치>
az keyvault secret list --vault-name jisimVault
az keyvault secret show --vault-name jisimVault --name jisimPub


