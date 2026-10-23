#!/bin/bash

TOKEN_FILE="/vagrant/confs/node-token"

if [[ ! -s "${TOKEN_FILE}" ]]; then
  echo "ERROR: The shared token file is missing or empty." >&2
  exit 1
fi

curl -sfL https://get.k3s.io | K3S_URL=https://192.168.56.110:6443 K3S_TOKEN_FILE="${TOKEN_FILE}" sh -