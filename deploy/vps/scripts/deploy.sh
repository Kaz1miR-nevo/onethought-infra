#!/bin/bash
# =============================================================================
# OneThought VPS Deployment Script
# =============================================================================
# Використовується для деплою OneThought на HostIQ VPS
# =============================================================================

set -euo pipefail

# Конфігурація
# NOTE: Updated after repo boundaries cleanup - docker-compose.vps.yml moved to INFRA repo
INFRA_DIR="/opt/onethought-infra"
WEB_DIR="/opt/OneThought"
API_DIR="/opt/onethought-api"
COMPOSE_FILE="${INFRA_DIR}/deploy/docker-compose.vps.yml"
ENV_FILE=".env.production"

# Кольори для виводу
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# =============================================================================
# Функції
# =============================================================================

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_root() {
    if [ "$EUID" -eq 0 ]; then
        log_error "Не запускайте скрипт від root! Використовуйте звичайного користувача з sudo"
        exit 1
    fi
}

check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker не встановлено. Запустіть setup-server.sh"
        exit 1
    fi
    
    if ! docker ps &> /dev/null; then
        log_error "Немає доступу до Docker. Перевірте права доступу або виконайте 'newgrp docker'"
        exit 1
    fi
}

check_env_file() {
    # Check for env file in INFRA deploy directory
    if [ ! -f "${INFRA_DIR}/deploy/env/${ENV_FILE}" ] && [ ! -f "${WEB_DIR}/${ENV_FILE}" ]; then
        log_error "Файл ${ENV_FILE} не знайдено"
        log_info "Створіть файл в ${INFRA_DIR}/deploy/env/ або ${WEB_DIR}/"
        log_info "Використовуйте .env.example як шаблон"
        exit 1
    fi
}

# =============================================================================
# Головна логіка
# =============================================================================

main() {
    log_info "OneThought VPS Deployment Script"
    echo "=========================================="
    
    check_root
    check_docker
    
    cd "${INFRA_DIR}/deploy" || {
        log_error "Не вдалося перейти в ${INFRA_DIR}/deploy"
        exit 1
    }
    
    check_env_file
    
    log_info "Зупинка старих контейнерів..."
    docker compose -f "${COMPOSE_FILE}" down || true
    
    log_info "Очищення старих образів (опціонально)..."
    read -p "Видалити невикористовувані образи Docker? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker image prune -af
    fi
    
    log_info "Побудова нових образів..."
    docker compose -f "${COMPOSE_FILE}" build --no-cache
    
    log_info "Запуск контейнерів..."
    docker compose -f "${COMPOSE_FILE}" up -d
    
    log_info "Очікування готовності сервісів..."
    sleep 10
    
    log_info "Перевірка стану контейнерів..."
    docker compose -f "${COMPOSE_FILE}" ps
    
    log_info "Перевірка health checks..."
    if docker compose -f "${COMPOSE_FILE}" ps | grep -q "unhealthy"; then
        log_warn "Деякі сервіси unhealthy. Перевірте логи:"
        log_warn "docker compose -f ${COMPOSE_FILE} logs"
    else
        log_info "Всі сервіси працюють!"
    fi
    
    log_info "Деплой завершено!"
    echo ""
    log_info "Корисні команди:"
    echo "  Переглянути логи:     docker compose -f ${COMPOSE_FILE} logs -f"
    echo "  Зупинити сервіси:     docker compose -f ${COMPOSE_FILE} down"
    echo "  Перезапустити:        docker compose -f ${COMPOSE_FILE} restart"
    echo "  Статус:               docker compose -f ${COMPOSE_FILE} ps"
}

# Виконання
main "$@"



