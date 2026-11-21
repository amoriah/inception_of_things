#!/bin/bash

curl -sfL https://get.k3s.io | sh -s - server --node-ip "$IP" --write-kubeconfig-mode 644

while [ ! -f /var/lib/rancher/k3s/server/node-token ]; do
  sleep 1
done

cp /var/lib/rancher/k3s/server/node-token /vagrant/confs/node-token

echo "alias k='k3s kubectl'" >> /home/vagrant/.bashrc
