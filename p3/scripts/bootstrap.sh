#!/usr/bin/env bash
# Создаёт k3d-кластер, namespace argocd и dev, ставит Argo CD и применяет Application.
set -euo pipefail

CLUSTER="iot"
CONFS_DIR="$(cd "$(dirname "$0")/../confs" && pwd)"

if grep -q 'CHANGE_ME' "${CONFS_DIR}/argocd-application.yaml"; then
  echo "В ${CONFS_DIR}/argocd-application.yaml не заполнен repoURL (CHANGE_ME)" >&2
  exit 1
fi

echo ">> Кластер k3d '${CLUSTER}' (порт приложения 8888 пробрасывается на хост)"
if k3d cluster list "${CLUSTER}" >/dev/null 2>&1; then
  echo "   уже существует, пропускаю"
else
  k3d cluster create "${CLUSTER}" -p "8888:8888@loadbalancer"
fi
kubectl wait --for=condition=Ready node --all --timeout=180s

echo ">> Namespace argocd и dev"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace dev    --dry-run=client -o yaml | kubectl apply -f -

echo ">> Argo CD"
# --server-side: некоторые CRD Argo CD слишком большие для обычного apply
kubectl apply -n argocd --server-side --force-conflicts \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait -n argocd --for=condition=Available deployment --all --timeout=300s

echo ">> Application (Argo CD начнёт следить за GitHub)"
kubectl apply -f "${CONFS_DIR}/argocd-application.yaml"

echo ">> Готово"
kubectl get ns
kubectl get pods -n argocd
echo
echo "Пароль admin для Argo CD:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
echo "Интерфейс:  kubectl port-forward --address 0.0.0.0 svc/argocd-server -n argocd 8080:443"
echo "            затем https://<IP VM>:8080 (логин admin)"
