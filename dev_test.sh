#!/bin/bash

useradd centos
chown centos:centos /root/DCV_Installer.sh
mv /root/DCV_Installer.sh /home/centos/

cat << EOF | sudo tee /etc/sudoers
centos  ALL=(ALL)       NOPASSWD: ALL
EOF

cd /home/centos/
su centos
