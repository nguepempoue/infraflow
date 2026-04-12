# InfraFlow — Lancement en moins de 5 minutes

## Prérequis

- Docker (Docker Desktop sur Windows) + Docker Compose v2
- Git

Optionnel (pour Kubernetes/monitoring) :
- kubectl
- minikube
- helm

## Démarrage rapide (Docker Compose)

1) (Optionnel) Variables d’environnement

Copie [`.env.example`](file:///d:/docs/formation-DevOps/projects/infraflow/.env.example) vers `.env` et ajuste si besoin :

- `WEB_PORT` (par défaut 8080)
- `INFRAFLOW_TAG` (par défaut local)

2) Build + run

```bash
docker compose up -d --build
```

3) Vérifier que ça répond

```bash
curl -fsS http://localhost:8080/status
curl -fsS http://localhost:8080/get
```

4) Arrêter

```bash
docker compose down
```

## Démarrage rapide (Kubernetes / minikube)

1) Démarrer minikube et (recommandé) activer metrics-server

```bash
minikube start
minikube addons enable metrics-server
```

2) Déployer InfraFlow

```bash
kubectl apply -f k8s/
kubectl get pods -n infraflow
```

Alternative (recommandée) : utiliser le script de déploiement

```bash
./scripts/deploy.sh
```

3) Accéder au web-service

Option A (minikube) :

```bash
minikube service web-service -n infraflow --url
```

Option B (port-forward) :

```bash
kubectl -n infraflow port-forward svc/web-service 8080:8080
```

Puis :

```bash
curl -fsS http://localhost:8080/status
curl -fsS http://localhost:8080/get
```

## Monitoring (Prometheus/Grafana via Helm)

Si `kube-prometheus-stack` est déjà installé, tu peux accéder à Grafana :

```bash
kubectl -n monitoring port-forward svc/monitoring-grafana 3000:80
```

Mot de passe admin Grafana :

```bash
kubectl -n monitoring get secret monitoring-grafana -o jsonpath="{.data.admin-password}" | base64 -d ; echo
```

Accès :
- Grafana : http://localhost:3000 (user: `admin`)

## CI/CD (GitHub Actions + GHCR)

Le workflow [ci-cd.yml](file:///d:/docs/formation-DevOps/projects/infraflow/.github/workflows/ci-cd.yml) exécute :
- lint-and-test (Hadolint, yamllint, ShellCheck)
- build (build des images + artifacts)
- security-scan (Trivy + reports en artifacts)
- push (push vers GHCR sur `main`)

Vérifier les images publiées (exemple) :

```bash
docker pull ghcr.io/<OWNER>/infraflow-api-service:sha-<GIT_SHA>
docker pull ghcr.io/<OWNER>/infraflow-web-service:sha-<GIT_SHA>
```

## Structure des manifests Kubernetes

- Namespace : [k8s/namespace.yml](file:///d:/docs/formation-DevOps/projects/infraflow/k8s/namespace.yml)
- API :
  - Deployment : [k8s/api-service/deployment.yml](file:///d:/docs/formation-DevOps/projects/infraflow/k8s/api-service/deployment.yml)
  - Service : [k8s/api-service/service.yml](file:///d:/docs/formation-DevOps/projects/infraflow/k8s/api-service/service.yml)
  - HPA : [k8s/api-service/hpa.yml](file:///d:/docs/formation-DevOps/projects/infraflow/k8s/api-service/hpa.yml)
- Web :
  - ConfigMap Nginx : [k8s/web-service/configmap.yml](file:///d:/docs/formation-DevOps/projects/infraflow/k8s/web-service/configmap.yml)
  - Deployment : [k8s/web-service/deployment.yml](file:///d:/docs/formation-DevOps/projects/infraflow/k8s/web-service/deployment.yml)
  - Service : [k8s/web-service/service.yml](file:///d:/docs/formation-DevOps/projects/infraflow/k8s/web-service/service.yml)
- Alerting :
  - PrometheusRule : [k8s/prometheusrule.yml](file:///d:/docs/formation-DevOps/projects/infraflow/k8s/prometheusrule.yml)

## Dépannage

- Web-service ne répond pas en Compose :
  - `docker compose ps` puis `docker compose logs -f web-service`
- Pods bloqués en `ImagePullBackOff` :
  - `kubectl describe pod -n infraflow <pod>`
  - sur minikube : `minikube image ls` / vérifier la connectivité registry
- HPA affiche `TARGETS <unknown>` :
  - `minikube addons enable metrics-server`
  - attendre quelques minutes puis `kubectl get hpa -n infraflow`
