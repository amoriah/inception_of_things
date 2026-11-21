#!/usr/bin/env bash
# Устанавливает Docker, kubectl и k3d на Debian. Запускать от обычного пользователя (нужен sudo).
set -euo pipefail

ARCH="$(dpkg --print-architecture)"   # amd64 или arm64

echo ">> Базовые пакеты"
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl gnupg

echo ">> Docker"
if ! command -v docker >/dev/null 2>&1; then
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc
  echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "${VERSION_CODENAME}") stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt-get update -y
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io
fi
sudo systemctl enable --now docker
sudo usermod -aG docker "${USER}"

echo ">> kubectl"
if ! command -v kubectl >/dev/null 2>&1; then
  # Версия kubectl должна совпадать с K3s, который создаёт k3d (допустима разница в 1 минорную),
  # иначе kubectl предупреждает о version skew. Узнать версию K3s: `k3d version`.
  KVER="v1.35.5"
  curl -fsSL -o /tmp/kubectl "https://dl.k8s.io/release/${KVER}/bin/linux/${ARCH}/kubectl"
  sudo install -m 0755 /tmp/kubectl /usr/local/bin/kubectl
fi

echo ">> k3d"
if ! command -v k3d >/dev/null 2>&1; then
  curl -fsSL https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi

echo ">> Готово. Версии:"
docker --version
kubectl version --client
k3d version
echo "Перезайдите в сессию (или выполните 'newgrp docker'), чтобы docker работал без sudo."
