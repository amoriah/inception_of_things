#!/usr/bin/env bash
# Shebang: запустить скрипт через bash, найденный в PATH (переносимее, чем /bin/bash).

# set -euo pipefail
# Строгий режим:
# -e          — остановить скрипт при первой ошибке (ненулевой код команды);
# -u          — ошибка при обращении к необъявленной переменной;
# -o pipefail — код конвейера (a | b) равен коду упавшей команды, а не только последней.

ARCH="$(dpkg --print-architecture)"
# Определяем архитектуру пакетов Debian (amd64 или arm64) и сохраняем в ARCH.
# Она нужна для репозитория Docker и для скачивания нужного бинарника kubectl.
# для мака

sudo apt-get update
# Обновляем списки пакетов из репозиториев, чтобы ставить свежие версии.

# sudo apt-get install -y ca-certificates curl gnupg
# Ставим базовые пакеты:
# ca-certificates — корневые сертификаты для HTTPS;
# curl            — скачивание файлов по URL;
# gnupg           — работа с GPG-ключами репозиториев.
# -y — не спрашивать подтверждение.

# if ! command -v docker >/dev/null 2>&1; then
if ! command -v docker ; then
# Если команды docker нет (Docker не установлен), выполняем блок до fi.
# >/dev/null 2>&1 скрывает вывод: нам важен только код возврата.

  # sudo install -m 0755 -d /etc/apt/keyrings
  # # Создаём каталог для ключей apt с правами 755 (если уже есть — ничего не делает).

  # sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
  # # Скачиваем официальный GPG-ключ Docker в файл docker.asc.
  # # -f — ошибка при HTTP-ошибках, -s — тихий режим, -S — показывать ошибки,
  # # -L — следовать редиректам, -o — путь сохранения файла.

  # sudo chmod a+r /etc/apt/keyrings/docker.asc
  # # Разрешаем всем читать ключ, чтобы apt мог проверять подписи пакетов.

  # echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "${VERSION_CODENAME}") stable" \
  #   | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  # # Формируем строку репозитория Docker и записываем её в файл docker.list:
  # # arch=${ARCH}    — архитектура пакетов;
  # # signed-by=...   — ключ, которым проверяются пакеты;
  # # $(. /etc/os-release && echo "${VERSION_CODENAME}") — кодовое имя Debian (например, bookworm);
  # # stable          — канал выпуска.
  # # sudo tee нужен, потому что перенаправление > выполняется без прав root;
  # # >/dev/null скрывает дублирующий вывод в терминал.

  # sudo apt-get update
  # # Снова обновляем списки пакетов, чтобы apt увидел новый репозиторий Docker.
  # Add Docker's official GPG key:
sudo apt update
sudo apt install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update

  sudo apt-get install -y docker-ce docker-ce-cli containerd.io
  # Ставим Docker: docker-ce — демон, docker-ce-cli — консольный клиент,
  # containerd.io — низкоуровневый контейнерный рантайм.

fi
# Конец блока if.

sudo systemctl enable --now docker
# enable — запускать Docker при загрузке системы; --now — запустить прямо сейчас.

sudo usermod -aG docker "${USER}"
# Добавляем текущего пользователя в группу docker (-aG — добавить, не удаляя из других групп),
# чтобы работать с docker без sudo. Применится после нового входа в систему.

if ! command -v kubectl >/dev/null 2>&1; then
# Если kubectl не установлен — выполняем блок.

  curl -fsSL -o /tmp/kubectl "https://dl.k8s.io/release/v1.35.5/bin/linux/${ARCH}/kubectl"
  # Скачиваем бинарник kubectl версии v1.35.5 под нашу архитектуру во временный файл /tmp/kubectl.

  sudo install -m 0755 /tmp/kubectl /usr/local/bin/kubectl
  # Копируем файл в /usr/local/bin и делаем его исполняемым (права 755),
  # чтобы команда kubectl была доступна из любого места.

fi
# Конец блока if.

if ! command -v k3d >/dev/null 2>&1; then
# Если k3d не установлен — выполняем блок.

  curl -fsSL https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
  # Скачиваем официальный установочный скрипт k3d и сразу передаём его в bash на выполнение.
  # Удобно, но вы запускаете чужой код без проверки — используйте только доверенные источники.

fi
# Конец блока if.