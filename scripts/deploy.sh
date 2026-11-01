#!/usr/bin/env bash
# Доставка статического ресурса на devops-vm
# Использование: scripts/deploy.sh [--dry-run]

set -euo pipefail

REMOTE="devops"
REMOTE_DIR="/var/www/devops-site"
SITE_URL="https://devops.local"
CA_CERT="${HOME}/devops.crt"
REPO_ROOT="$(git rev-parse --show-toplevel)"
LOCAL_DIR="${REPO_ROOT}/site/"

# 1. Разбор аргумента --dry-run
DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=1
elif [[ -n "${1:-}" ]]; then
    echo "Неизвестный аргумент: $1" >&2
    echo "Использование: $0 [--dry-run]" >&2
    exit 2
fi

# 2. Проверки по требованиям 4 и 5
if [[ ! -f "${LOCAL_DIR}/index.html" ]]; then
    echo "Ошибка: ${LOCAL_DIR}/index.html не найден" >&2
    exit 1
fi

if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "Ошибка: в репозитории есть незафиксированные изменения" >&2
    git status --short
    exit 1
fi

# 3. Синхронизация каталога ${LOCAL_DIR} на ${REMOTE}:${REMOTE_DIR}
RSYNC_ARGS=(-avz --delete --chmod=D755,F644)
if [[ "$DRY_RUN" == "1" ]]; then
    RSYNC_ARGS+=(--dry-run)
    rsync "${RSYNC_ARGS[@]}" "${LOCAL_DIR}" "${REMOTE}:${REMOTE_DIR}/"
    echo "Dry-run: изменения не применены"
    exit 0
fi

rsync "${RSYNC_ARGS[@]}" "${LOCAL_DIR}" "${REMOTE}:${REMOTE_DIR}/"

# 4. Проверка доступности ${SITE_URL} и завершение с корректным кодом возврата
if ! curl -fsS --cacert "${CA_CERT}" -o /dev/null "${SITE_URL}/"; then
    echo "Ошибка: ${SITE_URL}/ недоступен" >&2
    exit 1
fi

echo "Деплой успешен: $(git rev-parse --short HEAD)"
exit 0
