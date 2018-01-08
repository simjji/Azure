#!/bin/bash
az group deployment create --name networkForMongoDBDeployment --resource-group boraNetRg02 \
--template-file 00.mongoNet.json \
--parameters vnet_name=boraVnet01 \
--parameters subnet_name=testSubnet01 \
--parameters publicip_name=boraMongoDBSingleNodeIP \
--parameters dnsPrefix=boraMongodbTest01 \
--parameters nic_name=boraMongodbTestNic01