#!/bin/bash

curl -sfL https://get.k3s.io | K3S_URL=https://192.168.56.110:6443 K3S_TOKEN="K10a3999c8cfa2568d7a7401d9a0ca3e09a396d079465313280f1538afe3a514a66::server:0b3042afb59673ac8f5a50192e2a7e6d" sh - # TODO