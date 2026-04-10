# InfraFlow — Technologies / outils à connaître pour réussir le test

Cette liste correspond aux éléments explicitement évalués (Docker/CI/K8s/Monitoring/Bash/Sécurité) + les outils pratiques qui permettent de livrer “propre”.

## Containerisation & runtime

- **Docker**
  - images, layers, cache, tags (dont tag basé sur SHA)
  - Dockerfile best practices : base légère, multi-stage, non-root, .dockerignore
  - healthcheck Docker (commande, interval, retries)
- **Docker Compose**
  - services, networks, depends_on + conditions
  - ports (exposition à l’hôte), volumes
  - fichiers `.env` (et `.env.example`), variables d’environnement (pas de secrets en dur)
- **Nginx**
  - reverse proxy (proxy_pass), upstream, headers
  - configuration via fichier `nginx.conf` et injection via ConfigMap (Kubernetes)
  - endpoint / page de statut (selon implémentation)

## CI/CD (GitHub Actions)

- **GitHub Actions**
  - workflow YAML, triggers `push`/`pull_request`
  - jobs/steps, `needs`, `if` conditionnel (push seulement sur main)
  - gestion des secrets : `secrets.*`, `GITHUB_TOKEN`, secrets DockerHub/GHCR
  - artefacts (publier un rapport Trivy)
- **Registry d’images**
  - **GHCR** (GitHub Container Registry) ou **Docker Hub**
  - login dans GitHub Actions, push/pull, permissions

## Qualité / Lint infra (dans la CI)

- **Hadolint** (lint Dockerfile)
  - erreurs CRITICAL/ERROR et comment les corriger (USER non-root, pinning, etc.)
- **ShellCheck** (lint Bash)
  - quoting, set -euo pipefail, erreurs classiques, robustesse
- **Lint YAML**
  - yamllint (ou équivalent), indentation, clés, schéma

## Sécurité / DevSecOps

- **Trivy**
  - scan images (exit-code sur CRITICAL)
  - production d’un rapport (table, JSON, SARIF selon workflow)
- **Gestion des secrets**
  - GitHub Actions Secrets
  - (optionnel) Kubernetes Secrets (si tu ajoutes des credentials plus tard)
- **Moindre privilège**
  - conteneurs non-root
  - Kubernetes `securityContext` : `runAsNonRoot: true` (et champs associés si besoin)

## Kubernetes (cluster local)

- **kubectl**
  - apply/get/describe/logs
  - namespaces
  - rollout status / wait (attendre Ready)
  - port-forward
- **minikube** ou **kind**
  - créer/manager un cluster local
  - exposer un service (minikube service --url) ou port-forward
- Objets Kubernetes évalués
  - **Namespace** (infraflow)
  - **Deployment** (replicas>=2, strategy)
  - **Service** (ClusterIP, NodePort/LoadBalancer)
  - **ConfigMap** (injecter conf Nginx)
  - **Probes** (readiness/liveness)
  - **Resources** (requests/limits)
  - **HorizontalPodAutoscaler (HPA)** (CPU 70%)
- **Metrics Server**
  - indispensable pour que le HPA CPU fonctionne (addon minikube fréquent)

## Packaging / déploiement monitoring

- **Helm**
  - repo add/update/install
  - namespaces (monitoring)
  - overrides via values (si tu personnalises)
- **kube-prometheus-stack**
  - composants : Prometheus, Grafana, Alertmanager
  - accès local via port-forward
- **Grafana**
  - navigation dashboards, variables, filtres namespace
  - dashboard CPU/mémoire des pods du namespace infraflow
- **Prometheus**
  - targets, queries de base (PromQL)
  - **PrometheusRule** (définir une alerte “pod down > 1 min” par ex.)

## Scripting Bash (automatisation)

- **Bash**
  - shebang `#!/usr/bin/env bash`
  - `set -euo pipefail`
  - fonctions, parsing d’arguments simple, messages d’erreur
  - check prereqs (`command -v kubectl`, etc.)
  - codes de sortie cohérents

## Outils pratiques (utile pour être “pro” et aller vite)

- **curl** : tester endpoints HTTP
- **jq** : lire/filtrer JSON (utile pour validations rapides)
- **make** (optionnel) : raccourcis de commandes (si tu le fais, documente bien)

