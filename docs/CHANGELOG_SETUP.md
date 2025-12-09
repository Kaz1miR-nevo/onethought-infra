# Infrastructure Setup Changelog

---

## 🔍 Stage/Prod Separation Audit (December 2024)

### ✅ Перевірено та підтверджено

| Компонент | Stage | Prod | Статус |
|-----------|-------|------|--------|
| **EKS Cluster** | `onethought-stage-eks` | `onethought-prod-eks` | ✅ Різні |
| **VPC CIDR** | `10.0.0.0/16` | `10.1.0.0/16` | ✅ Різні |
| **ECR Repository** | `onethought-stage-frontend` | `onethought-prod-frontend` | ✅ Різні |
| **AWS Secrets** | `onethought-stage/app-secrets` | `onethought-prod/app-secrets` | ✅ Різні |
| **Domain** | `stage.onethought.app` | `onethought.app` | ✅ Різні |
| **IAM Role (GitHub)** | `onethought-stage-github-actions` | `onethought-prod-github-actions` | ✅ Різні |
| **Terraform Workspace** | `stage` | `prod` | ✅ Різні |
| **Helm Values** | `values.stage.yaml` | `values.prod.yaml` | ✅ Різні |
| **Log Level** | `debug` | `info` | ✅ Різні |
| **Replicas** | 2 | 3 | ✅ Різні |
| **WAF** | Вимкнено | Увімкнено | ✅ Різні |

### 📁 Файли, що були оновлені під час аудиту

| Файл | Зміни |
|------|-------|
| `infra/README.md` | Додано детальну секцію "Stage vs Prod Separation" |
| `infra/terraform/README.md` | Оновлено документацію про workspaces та state management |
| `infra/CHANGELOG_SETUP.md` | Додано результати аудиту |

### 📁 Файли, що не потребували змін (вже правильно налаштовані)

- ✅ `infra/terraform/environments/stage.tfvars`
- ✅ `infra/terraform/environments/prod.tfvars`
- ✅ `infra/terraform/main.tf` (використовує `${project_name}-${environment}`)
- ✅ `infra/terraform/modules/secrets/main.tf`
- ✅ `infra/helm/onethought/values.stage.yaml`
- ✅ `infra/helm/onethought/values.prod.yaml`
- ✅ `.github/workflows/deploy-stage.yml`
- ✅ `.github/workflows/deploy-prod.yml`

### ⚠️ Рекомендації

1. **Увімкнути S3 backend для Terraform** - для production потрібен remote state
2. **Налаштувати GitHub Environments** - `production` має вимагати approval
3. **Заповнити секрети** - реальні значення в AWS Secrets Manager

---

## Що було створено/змінено

### 📁 Нові файли в основному репо

#### Health Check Endpoint
- `app/api/health/route.ts` - Новий endpoint для Kubernetes probes

#### GitHub Actions Workflows
- `.github/workflows/deploy-stage.yml` - Деплой на stage при push в main
- `.github/workflows/deploy-prod.yml` - Деплой на production при release
- `.github/workflows/tests.yml` - Тести при PR та push

#### Next.js Config
- `next.config.mjs` - Додано `output: 'standalone'` для Docker builds

### 📁 Файли в `infra/`

#### Terraform (`terraform/`)
- Повний AWS stack: VPC, EKS, ECR, ALB Controller, KMS, Secrets Manager, WAF
- Окремі tfvars для stage та prod
- Модулі для всіх компонентів

#### Helm Chart (`helm/onethought/`)
- Deployment для frontend
- Services, Ingress, HPA, PDB
- NetworkPolicies для безпеки
- ServiceMonitor для Prometheus
- values.yaml, values.stage.yaml, values.prod.yaml

#### Kubernetes Monitoring (`k8s/monitoring/`)
- ClusterSecretStore для AWS Secrets Manager
- Grafana dashboard для OneThought

#### Docker (`docker/`)
- Multi-stage Dockerfile для Next.js standalone
- .dockerignore

#### Scripts (`scripts/`)
- `deploy-stage.sh` - Деплой на stage
- `deploy-prod.sh` - Деплой на production
- `kubectl-port-forward-app.sh` - Тестування через port-forward
- `kubectl-port-forward-grafana.sh` - Доступ до Grafana
- `install-monitoring.sh` - Встановлення Prometheus/Grafana/Loki
- `check-cluster-health.sh` - Перевірка здоров'я кластера
- `aws-auth.sh` - Налаштування AWS CLI
- `rollback.sh` - Відкат деплою

#### Documentation (`docs/`)
- DEPLOYMENT_GUIDE.md - Повний гайд по деплою
- LOCAL_DEVELOPMENT.md - Локальний development
- SECURITY_CHECKLIST.md - Чекліст безпеки
- TROUBLESHOOTING.md - Вирішення проблем
- HEALTH_CHECKLIST.md - Чекліст перед production

---

## Як задеплоїти Stage з нуля

### 1. Підготовка AWS

```bash
# Налаштувати AWS CLI
aws configure

# Перейти в terraform
cd infra/terraform
```

### 2. Terraform

```bash
# Ініціалізація
terraform init

# Створити workspace
terraform workspace new stage

# Застосувати
terraform apply -var-file=environments/stage.tfvars
```

### 3. Налаштування kubectl

```bash
aws eks update-kubeconfig --name onethought-stage-eks --region eu-central-1
kubectl cluster-info
```

### 4. Секрети

```bash
# Заповнити секрети в AWS Secrets Manager
aws secretsmanager update-secret \
  --secret-id onethought-stage/app-secrets \
  --secret-string '{
    "SUPABASE_URL": "https://your-project.supabase.co",
    "SUPABASE_ANON_KEY": "your-key",
    "SUPABASE_SERVICE_KEY": "your-service-key"
  }'
```

### 5. Встановити моніторинг

```bash
cd ../scripts
chmod +x *.sh
./install-monitoring.sh stage
```

### 6. Білд Docker image

```bash
cd ../..  # Корінь репо

# Логін в ECR
aws ecr get-login-password --region eu-central-1 | \
  docker login --username AWS --password-stdin \
  YOUR_ACCOUNT_ID.dkr.ecr.eu-central-1.amazonaws.com

# Білд
docker build -t onethought:latest \
  --build-arg NEXT_PUBLIC_APP_ENV=stage \
  -f infra/docker/Dockerfile .

# Пуш
docker tag onethought:latest YOUR_ACCOUNT_ID.dkr.ecr.eu-central-1.amazonaws.com/onethought-stage-frontend:latest
docker push YOUR_ACCOUNT_ID.dkr.ecr.eu-central-1.amazonaws.com/onethought-stage-frontend:latest
```

### 7. Деплой

```bash
cd infra/scripts
./deploy-stage.sh
```

### 8. Тест через port-forward

```bash
./kubectl-port-forward-app.sh
# Відкрити http://localhost:3000
```

---

## Як перенести зміни зі Stage на Production

### 1. Підготовка

```bash
# Переконатися що stage працює
kubectl get pods -n onethought
curl http://localhost:3000/api/health  # через port-forward
```

### 2. Створити Release

1. Перейти на GitHub → Releases
2. Create new release
3. Tag: `v1.0.0` (semantic versioning)
4. Опис змін
5. Publish

### 3. Автоматичний деплой

GitHub Actions автоматично:
1. Збере новий Docker image
2. Запитає approval (якщо налаштовано)
3. Задеплоїть на production

### 4. Моніторинг

```bash
# Перейти на prod cluster
aws eks update-kubeconfig --name onethought-prod-eks --region eu-central-1

# Перевірити
kubectl get pods -n onethought
./kubectl-port-forward-grafana.sh
```

---

## Branch Mapping

| Branch | Environment | Trigger |
|--------|-------------|---------|
| `main` | Stage | Push → auto-deploy |
| `release` | Production | Push → deploy with approval |
| GitHub Release | Production | Publish → deploy with approval |

---

## Локальний Development

Нічого не змінилось для локальної розробки:

```bash
npm install
npm run dev
# Відкрити http://localhost:3000
```

Kubernetes/Terraform/Helm потрібні тільки для деплою.

---

## Безпека

### ✅ Що налаштовано:
- AWS OIDC для GitHub Actions (без статичних ключів)
- Secrets в AWS Secrets Manager
- WAF для production
- Network Policies в K8s
- HTTPS через ALB + ACM
- Non-root containers

### ⚠️ Що потрібно зробити вручну:
- [ ] Заповнити реальні секрети в AWS Secrets Manager
- [ ] Створити SSL сертифікат в ACM
- [ ] Налаштувати DNS записи
- [ ] Додати reviewers для production environment в GitHub

---

*Останнє оновлення: December 2024*

