# InfraFlow — Analyse du test technique (v1.0)

## Objectif du test

Mettre en place, de bout en bout, une infrastructure locale complète pour un mini-système « microservices » composé de 2 services :

- **api-service** : API REST de test (type httpbin) qui renvoie les requêtes reçues.
- **web-service** : reverse proxy (Nginx) exposé à l’hôte, proxy vers api-service + endpoint/page de statut.

Le test évalue la capacité à prendre en charge tout le cycle **DevOps/SRE** : containerisation, orchestration Docker Compose, déploiement Kubernetes local, CI/CD, monitoring, scripting d’automatisation et bonnes pratiques sécurité (DevSecOps).

## Attendus (ce qui est demandé)

### 1) Containerisation Docker

- **Dockerfile pour chaque service** (optimisé) :
  - base officielle (alpine recommandé)
  - multi-stage si pertinent
  - **process non-root**
  - **.dockerignore** pour exclure l’inutile
- **docker-compose.yml** :
  - 1 commande pour tout démarrer : `docker compose up -d`
  - `depends_on` correctement configuré
  - **réseau Docker personnalisé**
  - variables via fichier `.env` (et fournir un `.env.example`, pas de secrets en dur)
  - **healthchecks** sur chaque service

Vérification attendue côté évaluateur :

- `docker compose ps` : tout est `healthy`/`running`
- `curl http://localhost:8080/get` : HTTP 200 + réponse JSON (ou endpoint équivalent si tu documentes clairement l’URL)

### 2) Pipeline CI/CD GitHub Actions

Workflow : `.github/workflows/ci-cd.yml`

- Triggers : `push` sur `main` + `pull_request`
- 4 jobs requis :
  1. **lint-and-test**
     - hadolint (Dockerfiles)
     - lint YAML
     - shellcheck (scripts Bash)
  2. **build**
     - build des images
     - tag avec le **SHA du commit**
  3. **security-scan**
     - scan vulnérabilités avec Trivy
     - pipeline échoue sur **CRITICAL**
     - rapport produit (artefact)
  4. **push**
     - push Docker Hub ou GHCR
     - uniquement sur `main`

Contraintes sécurité CI :

- credentials en **GitHub Actions Secrets** uniquement (jamais en clair dans le YAML).

### 3) Kubernetes (cluster local)

Cluster local : **minikube** ou **kind** (recommandés).

Manifestes dans `k8s/`, avec :

- namespace dédié : **infraflow**
- **Deployment** pour chaque service
  - **replicas >= 2**
  - **requests/limits** CPU/mémoire
  - **liveness + readiness probes**
  - **pas de tag `:latest`** (utiliser SHA ou version)
  - `securityContext` avec `runAsNonRoot: true`
- **Service**
  - api-service : ClusterIP
  - web-service : NodePort ou LoadBalancer (ou port-forward documenté)
- **ConfigMap** pour la conf Nginx
- **HPA** sur api-service
  - CPU threshold : **70%**

Vérifications attendues :

- `kubectl get pods -n infraflow` : pods Running
- `kubectl get svc -n infraflow` : services présents
- HPA présent et métriques disponibles (souvent via metrics-server sur minikube)

### 4) Monitoring (Prometheus + Grafana via Helm)

Déploiement dans le cluster via Helm (kube-prometheus-stack).

Attendus :

- Prometheus scrappe au moins les métriques Kubernetes de base.
- Grafana accessible (port-forward acceptable).
- Un dashboard affichant CPU et mémoire des pods du namespace **infraflow**.
- Au moins **une alerte** (PrometheusRule) (ex : “pod down > 1 min”).

### 5) Scripting Bash (automatisation)

Créer `scripts/deploy.sh` qui automatise le déploiement complet Kubernetes :

- vérifie les prérequis (kubectl/helm/docker dans PATH)
- crée le namespace si besoin
- applique les manifestes
- attend les rollouts / pods Ready
- affiche les URLs d’accès
- gère les erreurs correctement (exit codes, `set -euo pipefail`)

### 6) Sécurité (DevSecOps)

Attendus minimaux :

- scan Trivy dans la CI (fail sur CRITICAL)
- aucun secret en dur (Dockerfile, YAML, scripts, CI)
- utilisation de secrets GitHub Actions pour credentials
- `runAsNonRoot: true` dans les pods
- hadolint sans CRITICAL

## Structure de repo attendue (livrables)

Le document fournit une structure cible (à respecter au plus proche) :

- `.github/workflows/ci-cd.yml`
- `api-service/Dockerfile`
- `web-service/Dockerfile` + `web-service/nginx.conf`
- `docker-compose.yml` + `.env.example`
- `k8s/` avec namespace + sous-dossiers par service (deploy/service/hpa/configmap)
- `scripts/deploy.sh`
- `README.md` (clair, projet lançable en < 5 min)

## Comment obtenir un “130/130” (stratégie d’exécution)

### A) Construire “local” d’abord (Docker Compose)

1. Choisir des images/services simples :
   - api-service : une image “httpbin-like” (ex : httpbin) pour répondre à `/get`.
   - web-service : Nginx (idéalement une variante unprivileged pour tenir la contrainte non-root).
2. Dockerfiles :
   - copier seulement ce qui est nécessaire
   - utilisateur non-root (et adapter les ports si besoin : privilégier un port non-privilégié en interne, puis exposer 8080 côté hôte)
3. docker-compose.yml :
   - réseau dédié
   - healthchecks fiables (HTTP check)
   - `depends_on` avec condition healthy
   - `web-service` exposé sur `localhost:8080`
4. Vérifier avec les commandes du sujet + `curl`.

### B) Enchaîner CI/CD

1. Job lint-and-test :
   - hadolint (Dockerfiles)
   - shellcheck (scripts)
   - lint YAML (workflow + k8s + compose)
2. Job build :
   - tags : `sha-${{ github.sha }}` (ou format similaire, mais basé sur sha)
   - produire 2 images
3. Job security-scan :
   - scan Trivy
   - produire un rapport en artefact
   - fail sur CRITICAL
4. Job push :
   - seulement sur `main`
   - auth via secrets

### C) Porter sur Kubernetes (minikube/kind)

1. Manifeste namespace + ressources de base.
2. Deployments :
   - 2 replicas
   - probes
   - resources
   - image tag “sha-…”
   - securityContext runAsNonRoot
3. Services :
   - web-service accessible depuis l’hôte via NodePort + commande minikube ou via port-forward documenté
4. HPA :
   - CPU 70%
   - s’assurer que metrics-server est actif (sur minikube c’est souvent un addon)

### D) Ajouter monitoring + alerte

1. Installer kube-prometheus-stack via Helm (namespace monitoring).
2. Rendre Grafana accessible (port-forward).
3. Vérifier dashboard CPU/mémoire pour le namespace infraflow.
4. Ajouter une PrometheusRule (pod down 1 min, ou CPU haut), vérifier qu’elle apparaît.

### E) Script deploy.sh “démo-ready”

- Un seul script pour : vérifier prérequis → déployer infraflow → attendre rollouts → afficher URL(s) + commandes utiles (port-forward/minikube service).

### F) README (5 points “faciles”)

Le cahier de recette vérifie explicitement un README avec :

- Prérequis
- Démarrage rapide (docker-compose + Kubernetes)
- Monitoring
- Structure du projet

## Points d’attention (ce qui fait perdre des points / éliminatoire)

- Docker Compose non fonctionnel.
- Workflow GitHub Actions absent ou incomplet.
- Aucun pod Running en k8s.
- Secrets en dur (fichiers ou workflow).
- Trivy non bloquant sur CRITICAL.
- `:latest` utilisé dans les manifestes.

