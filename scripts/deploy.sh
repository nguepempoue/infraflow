#!/usr/bin/env bash
set -euo pipefail

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Prerequisite missing: $1" >&2
    exit 127
  }
}

repo_root() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  cd "${script_dir}/.." && pwd
}

ensure_kube_context() {
  kubectl version --request-timeout=5s >/dev/null 2>&1 || {
    echo "kubectl cannot reach the cluster. Check your kubeconfig/context." >&2
    exit 1
  }
}

ensure_namespace() {
  if ! kubectl get namespace infraflow >/dev/null 2>&1; then
    kubectl apply -f k8s/namespace.yml
  fi
}

apply_manifests() {
  kubectl apply -f k8s/
}

wait_for_rollouts() {
  kubectl rollout status deployment/api-service -n infraflow --timeout=180s
  kubectl rollout status deployment/web-service -n infraflow --timeout=180s
}

print_access() {
  echo
  echo "InfraFlow deployed."
  echo
  echo "Service checks:"
  echo "  - web-service status: curl -fsS http://localhost:8080/status"
  echo "  - web-service proxy : curl -fsS http://localhost:8080/get"
  echo

  if command -v minikube >/dev/null 2>&1; then
    local url
    url="$(minikube service web-service -n infraflow --url 2>/dev/null | head -n 1 || true)"
    if [ -n "${url}" ]; then
      echo "web-service URL (minikube): ${url}"
    else
      echo "web-service: kubectl port-forward -n infraflow svc/web-service 8080:8080"
    fi
  else
    echo "web-service: kubectl port-forward -n infraflow svc/web-service 8080:8080"
  fi

  echo
  echo "Grafana (if monitoring is installed):"
  echo "  - kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80"
  echo "  - password: kubectl -n monitoring get secret monitoring-grafana -o jsonpath='{.data.admin-password}' | base64 -d"
}

main() {
  require_command kubectl
  require_command helm
  require_command docker

  local root
  root="$(repo_root)"
  cd "${root}"

  ensure_kube_context
  ensure_namespace
  apply_manifests
  wait_for_rollouts
  print_access
}

main "$@"
