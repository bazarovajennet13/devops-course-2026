# Конфигурация виртуальной машины devops-vm

## 1. Параметры машины
- Объём оперативной памяти: 2048 МБ
- Количество ядер процессора: 2
- Объём диска: 25 ГБ (динамически расширяемый VDI)

## 2. Сетевые интерфейсы
| Адаптер | Тип | Адрес | Назначение |
|---|---|---|---|
| Адаптер 1 | NAT | 10.0.2.15/24 | Доступ в интернет |
| Адаптер 2 | Host-only | 192.168.56.101/24 | Доступ с хостовой системы |

## 3. Правило проброса портов
- Порт хоста 2222 → порт гостя 22 (затем SSH перенастроен на 2222 на VM).

## 4. Учётные записи
- `devops` (в группе `sudo`), вход по SSH-ключу.

## 5. Служба SSH
- Порт: 2222.
- Конфигурация: `/etc/ssh/sshd_config.d/99-hardening.conf`.
- `PermitRootLogin no`, `PasswordAuthentication no`, `MaxAuthTries 3`.

## 6. Правила межсетевого экрана (UFW)
- Политика: `deny incoming`, `allow outgoing`.
- Правила: `LIMIT 2222/tcp`, `ALLOW 80/tcp`, `ALLOW 443/tcp`.

## 7. Снимки состояния
- `01-clean-install`, `02-keys-configured`, `03-ssh-hardened`, `04-nginx-https`.

## 8. Веб-сервер
- **Пакет:** `nginx` (установлен через `apt`).
- **Конфигурация ресурса:** `/etc/nginx/sites-available/devops-site` (симлинк в `/etc/nginx/sites-enabled/devops-site`).
- **Стандартный ресурс:** `/etc/nginx/sites-enabled/default` удалён.
- **Каталог ресурса:** `/var/www/devops-site`, владелец `devops:devops`, права `755` для каталогов и `644` для файлов.
- **Сертификат:** `/etc/ssl/certs/devops.crt`, права `644`, владелец `root:root`, срок действия 365 дней.
- **Ключ:** `/etc/ssl/private/devops.key`, права `600`, владелец `root:root`.
- **Команда формирования сертификата:**
  ```bash
  sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/devops.key \
    -out /etc/ssl/certs/devops.crt \
    -subj "/CN=devops.local" \
    -addext "subjectAltName=DNS:devops.local"
  ```
- **Виртуальные хосты:**
  - Порт 80: `return 301 https://$host$request_uri`.
  - Порт 443: `ssl`, `root /var/www/devops-site`.
