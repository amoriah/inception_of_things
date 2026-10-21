#!/bin/bash

curl -sfL https://get.k3s.io | sh -

kubectl apply -f /vagrant/confs/Deployment.yaml