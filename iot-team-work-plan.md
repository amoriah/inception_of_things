# Inception of Things — подробный план командной работы

Этот документ — практический маршрут для двух frontend-разработчиков, которые выполняют проект **Inception of Things (IoT)** на двух личных компьютерах и начинают без DevOps-опыта.

Главная цель проекта: не «настроить сервер вручную один раз», а создать **файлы конфигурации и скрипты**, которые воспроизводимо поднимают нужное окружение. Во время защиты проверяют именно содержимое Git-репозитория и то, что оно действительно работает.

---

## 1. Что вы строите — в одном взгляде

Проект состоит из трёх обязательных независимых частей:

```text
p1 — два виртуальных Linux-компьютера + маленький Kubernetes-кластер
p2 — одна виртуальная машина + три приложения + маршрутизация по домену
p3 — Docker + K3d + Argo CD + автоматический деплой из GitHub
```

Итоговая картина:

```text
Part 1
Ваш компьютер
├── VM <login>S  (192.168.56.110) — K3s server
└── VM <login>SW (192.168.56.111) — K3s agent

Part 2
Ваш компьютер
└── VM <login>S (192.168.56.110)
    └── K3s
        └── Ingress
            ├── app1.com → app1
            ├── app2.com → app2 (3 копии)
            └── любой другой Host → app3

Part 3
Виртуальная машина
└── Docker
    └── K3d / Kubernetes-кластер
        ├── namespace argocd → Argo CD
        └── namespace dev → приложение

Public GitHub repo
└── Kubernetes YAML приложения
    └── изменение image v1 → v2
        └── Argo CD сам обновляет приложение в dev
```

## 2. Аналогии с frontend-разработкой

Если ты понимаешь React, тебе знаком принцип «описать желаемый результат, а не вручную менять DOM»:

```tsx
<Button disabled={isLoading}>Save</Button>
```

React сам синхронизирует DOM с тем, что ты описал.

Kubernetes работает похожим образом:

```yaml
spec:
  replicas: 3
```

Это означает: «Я хочу, чтобы работали три одинаковые копии приложения». Kubernetes сам создаёт и поддерживает три Pod’а. Если один упадёт, он постарается восстановить нужное количество.

Полезная аналогия:

| DevOps/Kubernetes термин | Простое значение | Условная frontend-аналогия |
|---|---|---|
| VM | Виртуальный Linux-компьютер внутри вашего компьютера | Изолированное рабочее окружение с полноценной ОС |
| Vagrantfile | Файл, описывающий виртуальные машины | `package.json`/скрипт, который создаёт dev environment |
| Docker image | Упаковка приложения и окружения | Build приложения + runtime в одном переносимом артефакте |
| Container | Запущенный Docker image | Изолированно запущенный процесс приложения |
| Kubernetes / K3s | Система управления контейнерами | Оркестратор приложений: запускает, перезапускает, масштабирует |
| Node | Машина в Kubernetes-кластере | Один сервер в инфраструктуре |
| Pod | Минимальная единица запуска в Kubernetes | Один живой экземпляр приложения |
| Deployment | Описание образа и числа копий Pod’ов | Desired state приложения |
| Service | Стабильное имя/адрес перед Pod’ами | Внутренний endpoint/load balancer |
| Ingress | HTTP-маршрутизатор к Service | Nginx reverse proxy с правилами по домену |
| Namespace | Логическая зона ресурсов в одном кластере | Scope вроде `dev`, `staging`, `infra` |
| Argo CD | Следит за Git и применяет YAML в Kubernetes | Автоматический deploy после изменения Git |
| GitOps | Git — источник правды для инфраструктуры | Меняем конфигурацию через commit, не вручную на сервере |

---

## 3. Где хранить работу

Создайте **два GitHub-репозитория**.

### 3.1. Основной репозиторий сдачи

В нём хранится вся работа, которую вы сдаёте:

```text
Название, например:
iot-<your-login>
```

Доступ можно сделать private, если школа не требует public repository. Добавьте друг друга как collaborators с правами записи.

Структура в конце должна быть такой:

```text
iot-<your-login>/
├── README.md
├── .gitignore
├── PROJECT_STATUS.md
├── p1/
│   ├── Vagrantfile
│   ├── scripts/
│   │   ├── install-server.sh
│   │   └── install-agent.sh
│   └── confs/
│       └── README.md
├── p2/
│   ├── Vagrantfile
│   ├── scripts/
│   │   └── install-k3s.sh
│   └── confs/
│       ├── app1.yaml
│       ├── app2.yaml
│       ├── app3.yaml
│       └── ingress.yaml
└── p3/
    ├── scripts/
    │   ├── install-tools.sh
    │   └── bootstrap.sh
    └── confs/
        ├── argocd-install.yaml
        └── argocd-application.yaml
```

Требования задания: папки `p1`, `p2`, `p3` должны находиться в корне репозитория. Скрипты должны лежать в `scripts/`, конфигурации — в `confs/`.

### 3.2. Публичный GitOps-репозиторий для p3

Для третьей части создайте второй отдельный репозиторий:

```text
iot-gitops-<your-login>
```

Он **должен быть public**, потому что Argo CD будет забирать из него манифесты приложения. В названии должен быть логин хотя бы одного участника команды.

Структура:

```text
iot-gitops-<your-login>/
├── README.md
└── manifests/
    ├── deployment.yaml
    └── service.yaml
```

Важное разделение ответственности:

```text
Основной repo:
«Как поднять кластер, поставить Argo CD и настроить его»

GitOps repo:
«Какое приложение и в какой версии должно работать в кластере»
```

Не храните node token K3s, kubeconfig, `.vagrant/`, временные Docker-файлы и большие бинарные артефакты в Git.

### 3.3. `.gitignore`

Создайте в корне основного репозитория файл `.gitignore`:

```gitignore
# Vagrant
.vagrant/

# Kubernetes credentials and generated configs
kubeconfig
*.kubeconfig
*.token

# Environment / OS
.env
.DS_Store
Thumbs.db

# Editor
.idea/
.vscode/

# Logs and temporary files
*.log
*.tmp
```

Не добавляйте в `.gitignore` собственные `.yaml`, `.sh`, `Vagrantfile`, `README.md`: это и есть ваша сдаваемая работа.

---

## 4. Как работать параллельно

### 4.1. Главное правило

Не отправляйте друг другу ZIP-архивы, папки через мессенджер или «последнюю версию проекта». Единственная актуальная версия должна быть в GitHub.

Рабочий цикл:

```text
создать задачу → создать ветку → внести изменения → локально проверить
→ push ветки → Pull Request → второй человек проверяет
→ merge в main → оба получают свежий main
```

### 4.2. Подготовка Git один раз

Обе на своих компьютерах:

```bash
git clone git@github.com:<owner>/iot-<your-login>.git
cd iot-<your-login>
git config user.name "Ваше Имя"
git config user.email "ваш-email@example.com"
```

Настройте SSH-key для GitHub. Это нужно, чтобы `git push` не спрашивал пароль каждый раз.

Перед началом любой новой задачи:

```bash
git switch main
git pull origin main
```

### 4.3. Ветки

Не работайте постоянно напрямую в `main`. Используйте отдельные ветки под задачи:

```text
feat/p1-vagrant-network
feat/p1-k3s-server-agent
feat/p2-applications
feat/p2-ingress-routing
feat/p3-install-tools
feat/p3-argocd-gitops
docs/defense-guide
fix/p2-default-backend
```

Пример полного цикла:

```bash
git switch main
git pull origin main

git switch -c feat/p2-ingress-routing
# редактируете файлы

git status
git add p2/confs/ingress.yaml
git commit -m "feat(p2): route hosts through ingress"
git push -u origin feat/p2-ingress-routing
```

После `push` откройте Pull Request на GitHub. Второй участник читает изменения, задаёт вопросы, проверяет локально или запускает команды. Затем PR вливается в `main`.

### 4.4. Как не получать конфликты

1. У каждой задачи есть один основной автор.
2. Два человека не редактируют один и тот же файл одновременно.
3. Перед изменением общих файлов (`README.md`, `.gitignore`, `Vagrantfile`, `PROJECT_STATUS.md`) напишите друг другу.
4. Делайте небольшие коммиты, а не один огромный «final changes».
5. После merge всегда обновляйте свою локальную ветку `main` через `git pull`.

Хорошие сообщения коммитов:

```text
feat(p1): create server and worker virtual machines
feat(p1): join k3s agent to server
feat(p2): deploy three web applications
feat(p2): add host-based ingress routing
feat(p3): install docker k3d and kubectl
feat(p3): configure argocd application auto-sync
docs: add clean setup and defense guide
fix(p2): configure app3 as default backend
```

Плохие:

```text
fix
final
changes
asd
```

### 4.5. Что делать, если есть конфликт Git

Конфликт — не катастрофа. Он означает, что Git не знает, чью правку одного участка файла оставить.

Безопасный алгоритм:

```bash
git status
# читаете файлы с <<<<<<<, =======, >>>>>>>
# вручную оставляете правильный объединённый текст

git add <исправленный-файл>
git commit
git push
```

Но лучший способ — не лечить конфликт, а не создавать его: заранее распределять владение файлами.

---

## 5. Распределение работы на двоих

Назовём участников условно:

```text
Участник A — ты
Участник B — подруга
```

Это не означает, что A знает только свой код, а B — только свой. В конце обе должны уметь объяснить весь проект. Но у каждого блока должен быть владелец.

| Блок | Основной автор | Второй участник | Результат |
|---|---|---|---|
| Репозитории, базовая структура, `.gitignore` | A | B review | Два GitHub repo и правильные папки |
| Общий README и чек-лист | A | B дополняет | Понятные команды запуска и проверки |
| p1: Vagrant + сеть из двух VM | B | A тестирует | Server и Worker с нужными IP |
| p1: K3s server/agent join | B | A повторяет чистый запуск | Две Kubernetes-ноды в `Ready` |
| p2: три простых web-приложения | A | B проверяет | app1, app2, app3 в K3s |
| p2: Service, Ingress, default backend | A | B повторяет curl-тесты | Host routing и 3 replicas app2 |
| p3: Docker, K3d, kubectl installation | B | A тестирует на чистом окружении | Установочный скрипт |
| p3: Argo CD и namespace | B | A review | `argocd` и `dev` namespace |
| p3: public GitOps repo и манифесты | A | B review | Deployment + Service с image v1 |
| p3: Argo CD Application auto-sync | B + A вместе | Оба тестируют | Git commit автоматически меняет версию |
| Финальная репетиция защиты | Оба | Оба | Повторяемое решение и уверенное объяснение |

### Почему такое деление удобно

- Ты можешь взять p2: там есть web-приложения, HTTP, домены, проксирование, YAML с образом/портом — это ближе к frontend и привычному web-миру.
- Подруга может взять p1/p3 bootstrap: VM, установка программ, Docker, K3d и K3s.
- Самые важные интеграции обязательно делайте вдвоём: p1 server/agent, p2 Ingress и p3 GitOps update.

Если уровень DevOps у вас одинаковый (нулевой), первые несколько часов p1 лучше делать параллельно в звонке с демонстрацией экрана: вы обе быстрее поймёте базовую лексику и разберётесь с Vagrant/VirtualBox.

---

## 6. Подготовка окружений на двух компьютерах

### 6.1. Что каждая устанавливает на свой основной компьютер

Минимальный набор для p1/p2:

```text
Git
GitHub account
Vagrant
VirtualBox (или другой одинаковый provider)
Терминал: Windows Terminal / PowerShell, macOS Terminal, Linux terminal
Редактор: VS Code или привычный IDE
```

Для p3 понадобится виртуальная Linux-машина, внутри которой будут Docker и K3d. Установочный скрипт p3 должен поставить нужные инструменты в этой VM.

### 6.2. Договоритесь об одинаковом стеке

До начала зафиксируйте в README:

```text
Provider: VirtualBox
Guest OS: Ubuntu LTS или Debian stable
Vagrant box: <точное название>
Main branch: main
GitHub organization/owner: <кто создал>
Team login used in hostnames/repositories: <login>
```

Это не требование PDF, но сильно снижает шанс, что один Vagrantfile работает только на компьютере одного участника.

### 6.3. Важное ограничение ресурсов

В задании рекомендуется минимум ресурсов: около 1 CPU и 512–1024 MB RAM на VM. Не пытайтесь сразу выделить «на всякий случай» 8 GB и 8 CPU. Сначала сделайте минимальную конфигурацию, которая стабильно работает.

Но для p3 Docker + K3d + Argo CD могут требовать больше ресурсов, чем p1/p2. Если на ноутбуке возникают проблемы, временно увеличьте память именно для VM p3 и запишите это в README как ограничение/требование к демонстрации.

---

## 7. Этап 0 — создать рабочее пространство

**Цель:** обе могут клонировать проект, запускать базовые команды Git и видеть одинаковую структуру.

### Шаги

1. Выберите, чей GitHub-аккаунт создаёт основной репозиторий, либо создайте GitHub Organization.
2. Создайте основной репозиторий `iot-<login>`.
3. Добавьте второго участника в collaborators.
4. Создайте public repository `iot-gitops-<login>`.
5. В названии GitOps repo включите логин одного члена команды.
6. Обе клонируйте основной repository.
7. Создайте ветку `chore/bootstrap-repository`.
8. Добавьте структуру папок, `.gitignore`, `README.md`, `PROJECT_STATUS.md`.
9. Создайте Pull Request, сделайте review вдвоём и merge.
10. Обе выполните `git pull origin main`.

### Начальный `PROJECT_STATUS.md`

```markdown
# IoT status

## Environment
- [ ] A: Git, Vagrant, VirtualBox installed
- [ ] B: Git, Vagrant, VirtualBox installed
- [ ] Both: repository cloned and GitHub SSH works

## p1
- [ ] Vagrantfile creates two VM
- [ ] Static IPs work
- [ ] K3s server is installed
- [ ] K3s agent joins server
- [ ] Test: two nodes are Ready

## p2
- [ ] One VM with K3s server
- [ ] app1 works
- [ ] app2 has 3 replicas
- [ ] app3 works
- [ ] Ingress routes host names correctly

## p3
- [ ] Installation script works
- [ ] K3d cluster starts
- [ ] Argo CD runs in argocd namespace
- [ ] dev namespace exists
- [ ] GitOps app v1 is deployed
- [ ] Git push v1 → v2 updates application automatically

## Final
- [ ] Clean run on A computer
- [ ] Clean run on B computer
- [ ] Defense rehearsal completed
```

---

## 8. Этап 1 — выполнить p1: две VM и K3s-кластер

### Простая цель

Создать две виртуальные Linux-машины:

```text
<login>S  — IP 192.168.56.110 — K3s server
<login>SW — IP 192.168.56.111 — K3s agent
```

Потом проверить, что Kubernetes на server видит обе машины:

```bash
sudo kubectl get nodes -o wide
```

Ожидаемая идея результата:

```text
NAME         STATUS   ROLE
<login>S     Ready    control-plane
<login>SW    Ready    worker
```

### Файлы p1

```text
p1/
├── Vagrantfile
├── scripts/
│   ├── install-server.sh
│   └── install-agent.sh
└── confs/
    └── README.md
```

### Задачи подруги — основной автор p1

1. Создать ветку `feat/p1-vagrant-network`.
2. Написать `p1/Vagrantfile`.
3. Описать две VM с нужными именами, hostname и статическими IP.
4. Выделить каждой 1 CPU и 512–1024 MB RAM.
5. Добавить provisioning scripts.
6. Проверить:

```bash
cd p1
vagrant up
vagrant status
vagrant ssh <login>S
ip a
```

7. Сделать commit, push, Pull Request.

### Твои задачи — проверка p1 network

После PR или после merge:

1. Перейти на ветку автора либо получить `main`.
2. На своём компьютере выполнить:

```bash
cd p1
vagrant destroy -f
vagrant up
vagrant status
```

3. Подключиться к обеим VM:

```bash
vagrant ssh <login>S
vagrant ssh <login>SW
```

4. Проверить адреса:

```bash
ip a
```

5. Убедиться, что видны `192.168.56.110` и `192.168.56.111` на нужных VM.
6. Написать результат в PR: что работает или какие ошибки есть.

### Что делает K3s server script

`install-server.sh` должен:

1. Установить K3s в server mode.
2. Дождаться запуска службы K3s.
3. Обеспечить доступность `kubectl`.
4. Получить join token из файла K3s.
5. Передать token worker-машине воспроизводимым способом.

### Что делает K3s agent script

`install-agent.sh` должен:

1. Дождаться доступности server по `192.168.56.110`.
2. Получить token, подготовленный server script.
3. Установить K3s в agent mode.
4. Подключиться к Kubernetes API server.

Идея подключения:

```text
agent знает:
- адрес server: https://192.168.56.110:6443
- token: секрет, который server создал после установки
```

Не нужно сразу глубоко понимать token. Достаточно понимать, что это пароль/ключ, который доказывает server, что worker разрешено присоединиться к кластеру.

### Проверки p1

На server VM:

```bash
sudo kubectl get nodes -o wide
sudo kubectl get pods -A
sudo systemctl status k3s
```

На worker VM:

```bash
sudo systemctl status k3s-agent
```

### Definition of Done для p1

p1 готова, только когда:

- `vagrant destroy -f && vagrant up` создаёт обе VM с нуля.
- Обе VM получают заданные IP.
- Можно зайти через `vagrant ssh` без ручного ввода пароля.
- Server и agent подняты автоматически.
- `kubectl get nodes` показывает **две** ноды `Ready`.
- Это проверено на обоих личных компьютерах.

Не переходите к p2, пока этот пункт не стабилен.

---

## 9. Этап 2 — выполнить p2: три приложения и Ingress

### Простая цель

Создать одну VM с K3s server и запустить три web-приложения.

Проверки должны выглядеть так:

```bash
curl -H 'Host: app1.com' http://192.168.56.110/
# ответ app1

curl -H 'Host: app2.com' http://192.168.56.110/
# ответ app2

curl -H 'Host: unknown.example' http://192.168.56.110/
# ответ app3
```

У app2 обязательно должны быть три копии:

```bash
sudo kubectl get pods -l app=app2
```

### Простая архитектура

```text
Клиент / браузер / curl
          |
          | Host: app1.com, app2.com или иной
          v
Ingress Controller (обычно Traefik, который есть в K3s)
          |
          +-- app1.com ----> Service app1 ----> Pod app1
          |
          +-- app2.com ----> Service app2 ----> Pod app2 × 3
          |
          +-- everything else -> Service app3 -> Pod app3
```

### Файлы p2

```text
p2/
├── Vagrantfile
├── scripts/
│   └── install-k3s.sh
└── confs/
    ├── app1.yaml
    ├── app2.yaml
    ├── app3.yaml
    └── ingress.yaml
```

В одном `app1.yaml` допустимо хранить сразу Deployment и Service, разделив их строкой `---`. Так меньше файлов и проще выполнять `kubectl apply -f confs/`.

### Что такое три YAML-уровня

Для каждого приложения нужно два ресурса:

```text
Deployment: «Запусти образ. Поддерживай нужное количество Pod'ов»
Service:    «Дай этим Pod'ам постоянное имя внутри кластера»
```

Для всех приложений нужен один ресурс:

```text
Ingress: «По HTTP Host отправляй запрос в подходящий Service»
```

У app2 в Deployment:

```yaml
spec:
  replicas: 3
```

Очень важно, чтобы label из Deployment и selector из Service совпадали:

```yaml
# Deployment
metadata:
  labels:
    app: app2

# Service
spec:
  selector:
    app: app2
```

Если они разные, Service не найдёт Pod’ы. Это очень распространённая ошибка.

### Твои задачи — основной автор p2

1. Создать ветку `feat/p2-applications`.
2. Создать `p2/Vagrantfile` для одной VM с IP `192.168.56.110`.
3. Добавить `p2/scripts/install-k3s.sh`.
4. Подготовить три минимальных приложения.
5. Для начала сделать так, чтобы каждое приложение отвечало уникальным текстом.
6. Описать Deployment и Service для app1, app2, app3.
7. Для app2 указать `replicas: 3`.
8. Проверить:

```bash
sudo kubectl apply -f /vagrant/confs/
sudo kubectl get deploy
sudo kubectl get pods
sudo kubectl get svc
```

9. Сделать отдельную ветку/PR `feat/p2-ingress-routing` либо продолжить текущую небольшими коммитами.
10. Добавить `ingress.yaml` с правилами:

```text
app1.com → app1
app2.com → app2
default backend → app3
```

11. Проверить curl-команды.
12. Создать Pull Request.

### Задачи подруги — тестирование p2

После merge или на PR-ветке:

1. Запустить p2 у себя с нуля:

```bash
cd p2
vagrant destroy -f
vagrant up
```

2. Убедиться, что приложение и K3s реально стартуют, а не «просто YAML лежат в репозитории».
3. Проверить Kubernetes:

```bash
vagrant ssh <login>S
sudo kubectl get deployments
sudo kubectl get pods -o wide
sudo kubectl get svc
sudo kubectl get ingress
sudo kubectl describe ingress
```

4. На host-компьютере выполнить:

```bash
curl -H 'Host: app1.com' http://192.168.56.110/
curl -H 'Host: app2.com' http://192.168.56.110/
curl -H 'Host: anything.example' http://192.168.56.110/
```

5. Проверить именно три реплики app2:

```bash
sudo kubectl get pods -l app=app2
```

6. Проверить, что все Pod’ы в статусе `Running`.
7. Если что-то не работает — приложить к PR вывод конкретной команды, не фразу «не работает».

### Definition of Done для p2

p2 готова, когда:

- Одна VM с IP `192.168.56.110` создаётся Vagrant.
- K3s server стартует автоматически.
- Запущены app1, app2, app3.
- У app2 ровно 3 Ready Pod’а.
- `Host: app1.com` ведёт в app1.
- `Host: app2.com` ведёт в app2.
- Любой другой host ведёт в app3.
- Это делается Kubernetes Ingress, а не внешним Nginx, который вы настроили вручную.
- Конфигурацию Ingress можно показать командой `kubectl get ingress` и `kubectl describe ingress`.
- Чистый запуск проверен на обоих компьютерах.

---

## 10. Этап 3 — выполнить p3: K3d, Argo CD и GitOps

### Простая цель

Сделать автоматический сценарий:

```text
GitHub deployment.yaml содержит image v1
             ↓
Argo CD видит YAML и разворачивает v1 в Kubernetes
             ↓
вы меняете v1 на v2 и делаете git push
             ↓
Argo CD сам замечает изменение
             ↓
Kubernetes обновляет Pod
             ↓
curl показывает v2
```

### Почему это отдельная часть

В p1/p2 K3s устанавливается прямо в VM как Linux service.

В p3 другая схема:

```text
VM
└── Docker
    └── K3d
        └── K3s nodes как Docker-контейнеры
```

K3d — удобная программа, которая быстро запускает K3s-кластер в Docker.

### Что нужно в кластере

```text
namespace argocd
└── Argo CD

namespace dev
└── ваше приложение
```

### Самый простой вариант приложения

Используйте готовый образ из задания:

```text
wil42/playground:v1
wil42/playground:v2
```

Преимущества:

- не нужно писать приложение;
- не нужно писать Dockerfile;
- не нужно создавать Docker Hub repository;
- две версии уже существуют;
- приложение отвечает на порту `8888` и показывает текущую версию.

Собственное приложение — опциональное усложнение. Для первой успешной сдачи не нужно.

### Файлы основного репозитория

```text
p3/
├── scripts/
│   ├── install-tools.sh
│   └── bootstrap.sh
└── confs/
    ├── argocd-install.yaml
    └── argocd-application.yaml
```

Возможное разделение:

```text
install-tools.sh:
- установить Docker
- установить kubectl
- установить k3d
- при необходимости установить argocd CLI

bootstrap.sh:
- создать k3d cluster
- создать namespace argocd и dev
- установить Argo CD
- применить Argo CD Application
- дождаться готовности ключевых Pod'ов
```

### Файлы public GitOps repo

```text
manifests/
├── deployment.yaml
└── service.yaml
```

`deployment.yaml` сначала содержит:

```yaml
image: wil42/playground:v1
```

Потом во время демонстрации вы меняете только тег:

```yaml
image: wil42/playground:v2
```

### Задачи подруги — bootstrap p3

1. Создать ветку `feat/p3-install-tools`.
2. Подготовить скрипт, который устанавливает Docker, K3d и `kubectl` на Linux VM.
3. Запустить скрипт на чистой VM и проверить:

```bash
docker --version
k3d version
kubectl version --client
```

4. Создать K3d cluster.
5. Проверить:

```bash
kubectl get nodes
```

6. Создать namespace:

```bash
kubectl create namespace argocd
kubectl create namespace dev
```

7. Установить Argo CD в `argocd`.
8. Проверить:

```bash
kubectl get pods -n argocd
kubectl get namespaces
```

9. Отправить PR.

### Твои задачи — GitOps repository

1. Создать public `iot-gitops-<login>` repository.
2. Добавить `manifests/deployment.yaml` и `manifests/service.yaml`.
3. В Deployment указать:

```text
namespace: dev
image: wil42/playground:v1
containerPort: 8888
```

4. Создать Service, который направляет порт 8888 к Pod’ам приложения.
5. Закоммитить и запушить в `main` GitOps repository.
6. Передать подруге точный URL репозитория и путь, например:

```text
repoURL: https://github.com/<owner>/iot-gitops-<login>.git
path: manifests
targetRevision: main
```

7. После настройки Argo CD проверить, что приложение появилось в `dev`:

```bash
kubectl get pods -n dev
kubectl get svc -n dev
```

### Совместная задача — Argo CD Application

Argo CD Application — это Kubernetes YAML, который говорит Argo CD:

```text
- откуда брать манифесты: public GitHub repo;
- какую ветку смотреть: main;
- в какой каталог смотреть: manifests;
- куда применять: namespace dev;
- синхронизировать автоматически.
```

Вместе проверьте, что в `argocd-application.yaml` совпадают:

```text
URL GitHub repo
название ветки
путь к manifests
namespace dev
```

Даже одна опечатка в URL/ветке/пути означает, что Argo CD не найдёт манифесты.

### Демонстрация v1 → v2

До защиты держите `main` GitOps repository на `v1`.

Проверка v1:

```bash
curl http://localhost:8888/
```

Затем в GitOps repo:

```bash
sed -i 's/wil42\/playground:v1/wil42\/playground:v2/g' manifests/deployment.yaml
git add manifests/deployment.yaml
git commit -m "deploy: switch playground to v2"
git push origin main
```

После push **не применяйте Deployment вручную через `kubectl apply`**. Иначе вы не покажете GitOps. Подождите, пока Argo CD увидит commit и применит изменение.

Проверки:

```bash
kubectl get pods -n dev
curl http://localhost:8888/
```

Ожидается ответ с версией `v2`.

### Definition of Done для p3

p3 готова, когда:

- На VM есть Docker, K3d и `kubectl`; их можно поставить вашим скриптом.
- K3d cluster создаётся.
- Существуют namespace `argocd` и `dev`.
- Argo CD работает в `argocd`.
- Есть public GitHub repo с логином участника в названии.
- Argo CD отслеживает GitOps repo и автоматически разворачивает приложение в `dev`.
- Начальная версия приложения — `v1`.
- Изменение GitHub YAML на `v2` и `git push` автоматически обновляют приложение.
- `curl http://localhost:8888/` подтверждает `v2`.
- Это протестировано с чистого состояния или хотя бы после удаления и повторного создания K3d-кластера.

---

## 11. Как проверять работу друг друга

### Правило «работает у обеих»

Каждая часть считается завершённой только тогда, когда:

```text
Автор поднял её у себя
Второй участник скачал код из GitHub
Второй участник выполнил чистый запуск у себя
Получил ожидаемый результат
```

Не принимайте фразу «у меня работает» как финальную проверку.

### Чистый запуск p1

```bash
cd p1
vagrant destroy -f
vagrant up
vagrant ssh <login>S
sudo kubectl get nodes -o wide
```

### Чистый запуск p2

```bash
cd p2
vagrant destroy -f
vagrant up
curl -H 'Host: app1.com' http://192.168.56.110/
curl -H 'Host: app2.com' http://192.168.56.110/
curl -H 'Host: unknown.example' http://192.168.56.110/
```

### Чистый запуск p3

```bash
k3d cluster delete iot
# запустить ваши p3 install/bootstrap scripts
kubectl get ns
kubectl get pods -n argocd
kubectl get pods -n dev
curl http://localhost:8888/
```

Названия кластеров и команд должны быть записаны в вашем README, чтобы не гадать на защите.

### Что прикладывать в Pull Request

В описание PR автор добавляет:

```markdown
## Что изменено
- Добавлены deployment/service для app1, app2, app3
- У app2 указано replicas: 3
- Добавлен host-based Ingress с app3 default backend

## Как проверить
1. `cd p2 && vagrant up`
2. `curl -H 'Host: app1.com' http://192.168.56.110/`
3. `curl -H 'Host: app2.com' http://192.168.56.110/`
4. `curl -H 'Host: unknown.example' http://192.168.56.110/`

## Ожидаемо
- app1 / app2 / app3 соответственно
- три running Pod у app2
```

Это превращает review в конкретную проверку, а не в «выглядит нормально».

---

## 12. План по времени

Распределите календарь по состояниям, а не по надежде «сделаем за вечер». Ниже — реалистичная последовательность; продолжительность зависит от вашего расписания и от того, насколько спокойно запускаются VM.

| Этап | Цель | Рекомендуемый фокус |
|---|---|---|
| 0 | GitHub, Git, Vagrant, VirtualBox, папки | 1 совместная сессия |
| 1 | p1: две VM с IP | сначала добиться сети |
| 2 | p1: K3s server + agent | закончить только после 2 Ready nodes |
| 3 | p2: 3 приложения без Ingress | сначала Deployment/Service |
| 4 | p2: Ingress и host routing | затем routing и 3 replicas |
| 5 | p3: VM + Docker + K3d | сначала инструменты и cluster |
| 6 | p3: Argo CD + GitOps repo | сначала v1 |
| 7 | p3: v1 → v2 | затем auto-sync demo |
| 8 | Документация и две репетиции | чистый запуск на обоих ПК |

Не начинайте bonus, пока все чек-листы mandatory не пройдены на двух компьютерах. Бонус с GitLab сложный и оценивается только при полностью работающей обязательной части.

---

## 13. Сценарий защиты

Подготовьте отдельный раздел в `README.md` — «Defense script». На защите не ищите команды в истории терминала.

### Демонстрация p1

Участник B:

```bash
cd p1
vagrant up
vagrant ssh <login>S
sudo kubectl get nodes -o wide
```

Объяснение:

```text
Первая VM — K3s server/control plane.
Вторая — K3s agent/worker.
Server создаёт и управляет кластером, agent присоединяется к нему.
Две ноды Ready доказывают, что кластер собран.
```

### Демонстрация p2

Участник A:

```bash
cd p2
vagrant up
curl -H 'Host: app1.com' http://192.168.56.110/
curl -H 'Host: app2.com' http://192.168.56.110/
curl -H 'Host: anything.example' http://192.168.56.110/
```

Внутри VM:

```bash
sudo kubectl get pods
sudo kubectl get pods -l app=app2
sudo kubectl get ingress
sudo kubectl describe ingress
```

Объяснение:

```text
Deployment поддерживает Pod'ы.
Service даёт стабильное имя и выбирает Pod'ы через labels.
Ingress маршрутизирует HTTP по заголовку Host.
У app2 три replicas, поэтому запущено три одинаковых Pod'а.
```

### Демонстрация p3

Участник B:

```bash
# запуск bootstrap
kubectl get ns
kubectl get pods -n argocd
kubectl get pods -n dev
curl http://localhost:8888/
```

Участник A в public GitOps repo:

```bash
# поменять v1 на v2
git add manifests/deployment.yaml
git commit -m "deploy: switch to v2"
git push origin main
```

После синхронизации:

```bash
kubectl get pods -n dev
curl http://localhost:8888/
```

Объяснение:

```text
В GitOps repo находится желаемое состояние приложения.
Argo CD следит за main branch этого repo.
После git push Argo CD видит новый image tag и сам приводит Kubernetes к версии v2.
Мы не применяли deployment вручную, поэтому это GitOps, а не ручной deploy.
```

---

## 14. Что должна уметь объяснить каждая

На защите любая из вас должна простыми словами ответить на вопросы:

1. **Что такое K3s?** Облегчённая Kubernetes-дистрибуция.
2. **Чем K3s отличается от K3d?** K3s — сам Kubernetes; K3d запускает K3s-кластер внутри Docker-контейнеров.
3. **Что такое server и agent в p1?** Server управляет кластером; agent — worker-node, подключённая к server.
4. **Что такое Pod?** Минимальная запускаемая единица Kubernetes, обычно с контейнером приложения.
5. **Что делает Deployment?** Поддерживает заданное число Pod’ов с нужным Docker image.
6. **Что делает Service?** Находит Pod’ы по labels и предоставляет стабильную внутреннюю точку доступа.
7. **Что делает Ingress?** Маршрутизирует входящий HTTP-трафик к Service по Host/path.
8. **Почему у app2 три Pod’а?** Потому что в Deployment задано `replicas: 3`.
9. **Что такое namespace?** Логическое разделение ресурсов внутри одного Kubernetes-кластера.
10. **Что такое Argo CD?** GitOps-инструмент: отслеживает Git и применяет описанное там состояние в Kubernetes.
11. **Почему в p3 не нужно делать `kubectl apply` после изменения версии?** Это должен сделать Argo CD автоматически после Git push.
12. **Почему GitOps repo public?** Так Argo CD может читать манифесты без настройки закрытого доступа; задание также требует public GitHub repository.

---

## 15. Частые проблемы и правильная реакция

| Симптом | Частая причина | Первый шаг диагностики |
|---|---|---|
| `vagrant up` не создаёт VM | VirtualBox/provider не установлен или несовместим | `vagrant status`, проверить VirtualBox |
| Нет нужного IP | Ошибка сети в Vagrantfile | В VM: `ip a` |
| Worker не появляется в `kubectl get nodes` | Нет token, неверный server URL, server ещё не готов | Проверить `systemctl status k3s-agent`, server IP и token flow |
| Pod `Pending` | Не хватает ресурсов или проблема scheduler | `kubectl describe pod <name>` |
| Pod `CrashLoopBackOff` | Контейнер падает | `kubectl logs <pod>` |
| Ingress не ведёт к app | Service selector не совпадает с Pod label; неверный порт | `kubectl get endpoints`, `kubectl describe ingress` |
| app2 не имеет 3 Pod | Нет `replicas: 3` или Pod падают | `kubectl get deploy`, `kubectl get pods -l app=app2` |
| Argo CD не видит repo | URL, branch или path ошибочны | Проверить `argocd-application.yaml` и Argo UI/status |
| Argo CD не обновляет v2 | Нет auto-sync или change не запушен в отслеживаемую ветку | Проверить Git commit, branch `main`, sync policy |
| Порт 8888 не открывается | Нет корректного expose/port mapping в K3d | Проверить Service и параметры создания K3d cluster |

Правило диагностики: не меняйте сразу пять файлов «наугад». Сначала соберите факт одной командой: `kubectl get`, затем `kubectl describe`, затем `kubectl logs`.

---

## 16. Финальный чек-лист

### Репозитории и командная работа

- [ ] Есть основной repository с `p1`, `p2`, `p3` в корне.
- [ ] Есть public GitOps repository для p3.
- [ ] В названии GitOps repository есть логин участника команды.
- [ ] У обеих есть доступ к обоим repository.
- [ ] `.gitignore` не пропускает `.vagrant/`, secrets и временные файлы.
- [ ] Есть README с командами запуска и проверки.
- [ ] Каждая часть проверена вторым человеком на другом компьютере.

### p1

- [ ] Две VM создаются через Vagrant.
- [ ] Их hostname/имена соответствуют `<login>S` и `<login>SW`.
- [ ] Server имеет IP `192.168.56.110`.
- [ ] Worker имеет IP `192.168.56.111`.
- [ ] SSH работает без ручного пароля.
- [ ] K3s server работает на первой VM.
- [ ] K3s agent подключён на второй VM.
- [ ] `kubectl get nodes` показывает две `Ready` ноды.

### p2

- [ ] Одна VM с K3s server поднимается через Vagrant.
- [ ] Три приложения запущены в Kubernetes.
- [ ] app1 открывается для `Host: app1.com`.
- [ ] app2 открывается для `Host: app2.com`.
- [ ] app3 работает как default backend.
- [ ] app2 имеет 3 replicas.
- [ ] Ingress показывается через `kubectl get ingress`.

### p3

- [ ] Скрипт ставит Docker, K3d и `kubectl` на VM.
- [ ] K3d cluster создаётся.
- [ ] Namespace `argocd` существует.
- [ ] Namespace `dev` существует.
- [ ] Argo CD работает в `argocd`.
- [ ] GitOps application развёрнута в `dev`.
- [ ] Исходно работает версия `v1`.
- [ ] Изменение `v1 → v2`, commit и push автоматически обновляют приложение.
- [ ] Проверка HTTP подтверждает `v2`.

### Перед защитой

- [ ] Проведены две полные репетиции: на компьютере A и на компьютере B.
- [ ] Ключевые команды собраны в README, а не в shell history.
- [ ] Обе способны объяснить p1, p2 и p3.
- [ ] Обе знают, какие файлы отвечают за каждый результат.
- [ ] Mandatory часть работает стабильно; bonus не начат до этого момента.

---

## 17. Главное правило проекта

Успех — это не «оно работало у одного человека вчера». Успех выглядит так:

```text
Код и конфигурации лежат в GitHub
        ↓
вторая участница клонирует свежий main
        ↓
поднимает окружение с нуля по README
        ↓
получает ожидаемый результат
        ↓
обе могут объяснить, почему он работает
```

Идите строго по порядку: сначала p1, затем p2, затем p3. Не начинайте GitLab bonus, пока обязательные части не воспроизводятся на обоих компьютерах.
