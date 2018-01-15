#!/bin/bash

#개인 Vault  그룹 생성
az group create --name jisimVaultRG01 --location koreacentral
az keyvault create --name jisimVault --resource-group jisimVaultRG01
#### az keyvault secret set --vault-name 'jisimVault01' --name 'jisimMysqlRoot'
az keyvault secret set --vault-name 'jisimVault' --name 'jisimPub' --file /Users/jisim/.ssh/jisim_ebay.com.pub

#<pub key 파일위치>
az keyvault secret list --vault-name jisimVault
az keyvault secret show --vault-name jisimVault --name jisimPub


# -------------- Mysql 구성 시작 --------------

# Mysql Network 구성
az group deployment create --name networkForMysqlDeployment --resource-group jisimNetRG01 \
--template-file 00.mysqlNet.json \
--parameters vnet_name=jisimVnet01 \
--parameters subnet_name=testSubnet01 \
--parameters publicip_name=mysqlSingleNodeIP \
--parameters dnsPrefix=jisimmysqltest01 \
--parameters nic_name=mysqlTestNIC01

# Mysql VM 구성
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


# 이후 구성 명령문
1.
52.231.27.126/jisimmysqltest01.koreacentral.cloudapp.azure.com

2.
sudo usermod -G jisim,mysql jisim

3.
[jisim@mysqlTestVM01 mysql]$ cat /etc/my.cnf
[mysqld]
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
#datadir=/data01/mysql-files
#socket=/data01/mysql-files/mysql.sock
user=mysql

4.
mkdir /data01/mysql
chown mysql:mysql /data01/mysql
ln -s /data01/mysql /var/lib/mysql
chown -h mysql:mysql /var/lib/mysql

5.
[root@mysqlTestVM01 data01]# mysqld --initialize
2018-01-14T04:15:22.865678Z 0 [Warning] TIMESTAMP with implicit DEFAULT value is deprecated. Please use --explicit_defaults_for_timestamp server option (see documentation for more details).
2018-01-14T04:15:25.288335Z 0 [Warning] InnoDB: New log files created, LSN=45790
2018-01-14T04:15:25.806588Z 0 [Warning] InnoDB: Creating foreign key constraint system tables.
2018-01-14T04:15:25.973843Z 0 [Warning] No existing UUID has been found, so we assume that this is the first time that this server has been started. Generating a new UUID: 8c1704d3-f8e1-11e7-b0d6-0022480504f3.
2018-01-14T04:15:26.011596Z 0 [Warning] Gtid table is not ready to be used. Table 'mysql.gtid_executed' cannot be opened.
2018-01-14T04:15:29.663857Z 0 [Warning] CA certificate ca.pem is self signed.
2018-01-14T04:15:30.506255Z 1 [Note] A temporary password is generated for root@localhost: jdoGOjIda0,T

6. 
mysqld_safe &

7.
kill -15 xxxxxx

8.
systemctl list-unit-files --type=service
ln -s /usr/local/mysql/support-files/mysql.server /etc/init.d/mysql
#systemctl enable mysql
service mysql start
chkconfig mysql on
chkconfig --list

