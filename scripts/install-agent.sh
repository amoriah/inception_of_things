#!/usr/bin/env bash
# Выполнять этот файл с помощью Bash.

set -euo pipefail
# Остановиться при ошибке команды, неизвестной переменной
# или ошибке любой команды в цепочке.

apt-get update
# Обновить список пакетов Debian.

apt-get install -y curl ca-certificates
# Установить инструменты для скачивания по HTTPS.

AGENT_IP="192.168.56.111"
# IP второй VM из вашего Vagrantfile.

INTERFACE=$(ip -o -4 addr show | awk '$4 ~ /^192\.168\.56\.111\// {print $2; exit}')
# Найти сетевой интерфейс с IP Worker.

test -n "$INTERFACE"
# Остановить скрипт, если интерфейс не найден.

test -s /vagrant/.runtime/node-token
# Проверить, что Server уже создал непустой файл token.
# Если файла нет, скрипт остановится: сначала запустите Server.

export INSTALL_K3S_VERSION=$(cat /vagrant/.runtime/k3s-version)
# Прочитать версию Server.
# export передаёт переменную запускаемому далее установщику.

export K3S_URL="https://192.168.56.110:6443"
# Указать адрес Kubernetes Server, к которому подключаться.

install -d -m 700 /etc/rancher/k3s
# Создать защищённую локальную папку конфигурации.
# 700: доступ только у владельца, здесь root.

install -m 600 /vagrant/.runtime/node-token /etc/rancher/k3s/join-token
# Скопировать token из общей папки внутрь Worker.
# 600: читать и изменять этот файл может только root.

export K3S_TOKEN_FILE="/etc/rancher/k3s/join-token"
# Указать установщику, из какого локального файла читать token.

curl -sfL https://get.k3s.io -o /tmp/install-k3s.sh
# Скачать официальный установщик K3s.

# Установить K3s в режиме agent:
# --node-name: имя Worker внутри Kubernetes.
# --node-ip: IP Worker.
# --flannel-iface: интерфейс для сети между нодами.
sh /tmp/install-k3s.sh agent \
  --node-name amoriahteamsw \
  --node-ip "$AGENT_IP" \
  --flannel-iface "$INTERFACE"

echo "K3s agent installation completed."
# Установка завершена; готовность ноды проверяем на Server.