#!/usr/bin/env bash
# Выполнять этот файл с помощью Bash.

set -euo pipefail
# Остановиться при ошибке команды, неизвестной переменной
# или ошибке любой команды в цепочке с символом |.

apt-get update
# Обновить список доступных пакетов Debian.

apt-get install -y curl ca-certificates
# Установить curl для скачивания и сертификаты для HTTPS.
# -y означает: автоматически соглашаться на установку.

SERVER_IP="192.168.56.110"
# IP первой VM из вашего Vagrantfile.

INTERFACE=$(ip -o -4 addr show | awk '$4 ~ /^192\.168\.56\.110\// {print $2; exit}')
# Найти имя интерфейса, которому назначен IP Server.
# Например, результатом может быть enp0s8.

test -n "$INTERFACE"
# Остановить скрипт, если интерфейс с таким IP не найден.

curl -sfL https://get.k3s.io -o /tmp/install-k3s.sh
# Скачать официальный установщик в файл.
# -s: не показывать индикатор скачивания.
# -f: считать HTTP-ошибку ошибкой команды.
# -L: следовать перенаправлениям.
# -o: сохранить результат по указанному пути.

# Установить K3s в режиме server:
# --node-name: имя ноды внутри Kubernetes, в нижнем регистре.
# --node-ip: адрес этой ноды.
# --flannel-iface: интерфейс для сети между нодами.
sh /tmp/install-k3s.sh server \
  --node-name amoriahteams \
  --node-ip "$SERVER_IP" \
  --flannel-iface "$INTERFACE"

until kubectl --request-timeout=5s get --raw="/readyz" >/dev/null 2>&1; do
  # Проверять готовность Kubernetes API.
  # >/dev/null 2>&1 скрывает обычный вывод и сообщения об ошибках.
  echo "Waiting for Kubernetes API..."
  sleep 3
  # Подождать 3 секунды перед следующей проверкой.
done

kubectl wait --for=condition=Ready node/amoriahteams --timeout=180s
# Подождать до 180 секунд, пока Server-нода станет Ready.

mkdir -p /vagrant/.runtime
# Создать папку для передачи данных Worker.
# -p: не считать ошибкой, если папка уже существует.

k3s --version | awk 'NR == 1 {print $3}' > /vagrant/.runtime/k3s-version
# Получить установленную версию K3s и сохранить в файл.
# Worker установит именно эту версию.

cp /var/lib/rancher/k3s/server/node-token /vagrant/.runtime/node-token
# Скопировать ключ подключения в общую папку.

echo "K3s server is ready."
# Сообщить о завершении установки.

kubectl get nodes -o wide
# Показать ноды кластера и их IP.