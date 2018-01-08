#!/bin/bash
# mongodb VM Group를 만든다.
az group create --name boraMongoDBRG01 --location koreacentral

# mongodb VM을 위한 NIC 만든다.
# dns는 대문자가 안 된다.
az group deployment create --name networkForMongoDBDeployment --resource-group boraNetRg02 \
--template-file 00.mongoNet.json \
--parameters vnet_name=boraVnet01 \
--parameters subnet_name=testSubnet01 \
--parameters publicip_name=boraMongoDBSingleNodeIP \
--parameters dnsPrefix=boramongo01 \
--parameters nic_name=boraMongodbNic01


az group deployment create --name createVM --resource-group boraMongoDBRG01 --template-file 02.vm.json \
--parameters vm_name=boraMongoTestVM01 \
--parameters adminUserId=bochoi \
--parameters nic_name=boraMongodbNic01 \
#--parameters dataDisk_name01=mongodbDataDisk01 \
#--parameters dataDisk_name02=mongodbDataDisk02

# disk 두 개 만듬
az group deployment create --name createDataDisk --resource-group boraMongoDBRG01 --template-file 01.dataDisk.json \
--parameters dataDisk_name=mongodbDataDisk01
az group deployment create --name createDataDisk --resource-group boraMongoDBRG01 --template-file 01.dataDisk.json \
--parameters dataDisk_name=mongodbDataDisk02

# data disk attach
az vm disk attach --vm-name boraMongoTestVM01 --disk mongodbDataDisk01 --lun 0 --resource-group boraMongoDBRG01
az vm disk attach --vm-name boraMongoTestVM01 --disk mongodbDataDisk02 --lun 1 --resource-group boraMongoDBRG01

#disk lun 확인
az vm show --resource-group boraMongoDBRG01 --name boraMongoTestVM01 | jq -r .storageProfile.dataDisks
az vm show --resource-group boraMongoDBRG01 --name boraMongoTestVM01 | jq -r .storageProfile.dataDisks[].lun