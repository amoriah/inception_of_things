#!/bin/bash

# curl -sfL https://get.k3s.io | sh -
curl -sfL https://get.k3s.io | \
  INSTALL_K3S_EXEC="--node-ip=192.168.56.110 --advertise-address=192.168.56.110" sh -


kubectl apply -f /vagrant/confs/template.yaml