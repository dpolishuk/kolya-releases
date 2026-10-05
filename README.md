# Коля — готовая программа для дежурного инженера

Версия: v0.1.0-rc.9
Исходный коммит сборки: 7a9af0e782fb8128366ca16a3b54965794497b3b

Этот репозиторий содержит только дистрибутив. Исходники приложения,
инфраструктурные контракты и доступы оператора остаются приватными.

## Установка

Используйте обычного пользователя, без sudo, на Linux или macOS, amd64 или
arm64. Нужны curl и sha256sum (Linux) либо shasum (macOS). Go, Git и вход в
GitHub не требуются.

```sh
curl -q --fail --silent --show-error --location --proto '=https' --proto-redir '=https' --tlsv1.2 --connect-timeout 10 --max-time 60 https://github.com/dpolishuk/kolya-releases/releases/download/v0.1.0-rc.9/install.sh | sh
```

Скрипт фиксирует один релиз и SHA256 четырёх программ, проверяет скачанные
байты и запускает русский мастер. Изменённый файл не выполняется. Команда
выше работает и для prerelease; GitHub `latest/download` исключает prerelease.

Программа устанавливается в `~/.kolya/bin/kolya-agent`. Для другого места
передайте `--root /абсолютный/приватный/каталог`, для простого текстового
интерфейса — `--plain`. Без управляющего терминала установка завершается
успешно и печатает точную команду продолжения. Чтобы отложить настройку явно:

```sh
curl -q --fail --silent --show-error --location --proto '=https' --proto-redir '=https' --tlsv1.2 --connect-timeout 10 --max-time 60 https://github.com/dpolishuk/kolya-releases/releases/download/v0.1.0-rc.9/install.sh | sh -s -- --no-onboard
"$HOME/.kolya/bin/kolya-agent" version
"$HOME/.kolya/bin/kolya-agent" setup --root "$HOME/.kolya" --plain
```

Необязательная команда `~/.local/bin/kolya` создаётся только в безопасном
свободном месте; чужая команда сохраняется. Настройки shell не меняются.
Используйте полный путь из примеров, если каталог не входит в PATH.

## Подготовить данные и пройти мастер

Текущая строгая схема требует все перечисленные входные данные, даже если
отдельный сборщик пока не используется. Получите их от оператора заранее:

- **Приватные контракты**: полный локальный каталог политики и inventory.
  В публичном дистрибутиве его нет; мастер не создаёт фиктивные контракты.
- **LLM**: выбранный провайдер, способ доступа API/план, регион, ключ и
  модель. Поддерживаются восемь семейств и свой OpenAI-совместимый API;
  полные инструкции и адреса приведены ниже. Отдельный CA провайдера
  необязателен при системном доверии.
- **Grafana**: HTTPS адрес без дополнительного пути, например
  `https://grafana.example:443`, organisation ID и service account token.
  Нужен локальный доверенный CA в PEM, даже если сертификат известен системе.
- **MCP**: доверенный исполняемый `mcp-grafana` и рабочий каталог. Мастер может
  скачать поддерживаемый официальный v1.2.0 с закреплённой SHA256. CA и MCP
  хешируются автоматически. Каталоги и файлы должны принадлежать вам, без
  символических ссылок и небезопасных прав.
- **VictoriaLogs**: UID datasource в Grafana; поле обязательно в конфиге,
  даже когда получение логов выключено.
- **GitLab**: HTTPS API, например `https://gitlab.example/api/v4`, и read-only
  token. Мастер добавляет `/api/v4`. При собственном CA укажите его PEM.
- Режим проактивности, область алертов и настройки уведомлений о здоровье.

Мастер скрывает ввод токенов и сохраняет их в отдельных файлах `0600`.
Можно выбрать уже подготовленный файл секрета. Не вставляйте токены в
аргументы, unit/plist, Git или переписку. Перед записью мастер показывает
итог без значений секретов и запрашивает подтверждение.

Повторный `setup` позволяет выбрать раздел: неизменённые endpoints, ссылки
на секреты, фильтры проактивности и health сохраняются. Отмена и ошибки не
заменяют рабочую конфигурацию. Мастер не открывает и не мигрирует SQLite.

## Провайдеры и выбор модели

Коля поддерживает OpenRouter, Z.ai, Moonshot/Kimi, OpenAI, Anthropic,
MiniMax, DeepSeek, Qwen/Alibaba и другой OpenAI-совместимый API. Сначала
выберите способ оплаты: обычный API или отдельный Coding/Token Plan.
Ключ, регион и адрес должны относиться к одному способу доступа. Коля
не переключает план на платный API при ошибке или исчерпании квоты.

## Изменить только LLM

Для существующей валидной конфигурации:

```sh
"$HOME/.kolya/bin/kolya-agent" model --root "$HOME/.kolya" --plain
"$HOME/.kolya/bin/kolya-agent" check-config --config "$HOME/.kolya/config.yaml"
"$HOME/.kolya/bin/kolya-agent" preflight --config "$HOME/.kolya/config.yaml"
"$HOME/.kolya/bin/kolya-agent" service restart --root "$HOME/.kolya"
```

`model` спрашивает только провайдера и модель. Grafana, GitLab, Telegram,
фильтры алертов, health, services, features, memory и пути базы сохраняются.
Команда не открывает SQLite и не запускает службу. После успешного сохранения
появится `SETUP_SAVED`; restart нужен уже работающей службе, чтобы прочитать
новые настройки. Foreground `watch` остановите Ctrl-C и запустите заново.

Другой корень или отдельный конфиг задаются явно; они не меняют PATH:

```sh
"$HOME/.kolya/bin/kolya-agent" model --root "/absolute/kolya-root" --config "/absolute/kolya-root/config.yaml" --plain
"$HOME/.kolya/bin/kolya-agent" model --help
"$HOME/.kolya/bin/kolya-agent" setup --help
```

Если конфигурации ещё нет или она повреждена, `model` печатает
`SETUP_EXISTING_CONFIG_INVALID` и точную команду полного мастера:

```sh
"$HOME/.kolya/bin/kolya-agent" setup --root "$HOME/.kolya" --plain
```

Полный `setup` также позволяет выбрать раздел LLM в уже настроенной установке.
При редактировании v1 мастер сохраняет результат в v2 и печатает путь точной
резервной копии старого файла. Отмена до сохранения оставляет конфиг прежним.
При сохранении без изменений комментарии и байты не переписываются. Без
управляющего терминала команда печатает продолжение; откройте Terminal/iTerm
или SSH с TTY. Ctrl-C/Ctrl-D отменяют ввод и восстанавливают терминал.

## Что выбрать в мастере

1. **Провайдер LLM**. Kimi Code и Moonshot / Kimi API — разные пункты.
2. **Доступ и оплата**: API либо именованный план. Префикс ключа не выбирает
   оплату автоматически.
3. **Регион выдачи ключа**: глобальный, Китай, а для Qwen API ещё США.
4. **HTTPS адрес API**: проверьте предложенный базовый URL; можно указать
   свой точный адрес. Дополнительный CA необязателен.
5. **Ключ**: оставить текущую ссылку, защищённый файл `0600`, скрытый ввод
   или браузер OpenRouter. При смене провайдера/способа доступа/адреса мастер
   просит новый источник ключа вместо переноса прежнего секрета.
6. **Модель**: оставить текущую, выбрать офлайн подсказку, ввести ID вручную
   либо явно запросить каталог через GET, где он поддерживается.
7. Проверьте протокол, профиль, способ доступа, URL, модель и пути в обзоре;
   подтвердите сохранение. Значения секретов в обзор не попадают.

Офлайн подсказки не обращаются в сеть и не доказывают доступность модели
для вашего аккаунта. Онлайн каталог — только выбранный вами GET, без
генерации. При отказе каталога остаются подсказки и ручной ввод. Для Qwen
и custom каталог не предлагается: неподдерживаемый `/models` не вызывается.
Мастер не делает платный тестовый запрос к модели.

## Адреса и примеры моделей

Проверено по официальным страницам 5 октября 2026 года. Это примеры из
офлайн каталога, а не обещание доступности или срока жизни модели.
`global` у Qwen API означает Сингапур. URL записывается без завершающего `/`.

| Провайдер / профиль | Доступ | Глобальный базовый URL | Китай / США | Пример ID |
| --- | --- | --- | --- | --- |
| OpenRouter / `openrouter` | `api`, ключ или браузер | `https://openrouter.ai/api/v1` | тот же адрес | `openai/gpt-5.4-mini`, `~openai/gpt-latest` |
| Z.ai / `zai` | `api` | `https://api.z.ai/api/paas/v4` | CN: `https://open.bigmodel.cn/api/paas/v4` | `glm-5.3`, `glm-5.3-flash` |
| Z.ai / `zai` | `coding_plan` | `https://api.z.ai/api/coding/paas/v4` | CN: `https://open.bigmodel.cn/api/coding/paas/v4` | `glm-5.3` |
| Moonshot / `moonshot` | `api` | `https://api.moonshot.ai/v1` | CN: `https://api.moonshot.cn/v1` | `kimi-k3`, `kimi-k2.7-code` |
| Kimi Code / `kimi` | `coding_plan` | `https://api.kimi.ai/coding/v1` | CN: `https://api.kimi.com/coding/v1` | `kimi-for-coding`, `k3-256k`, `k3` |
| OpenAI / `openai` | `api` | `https://api.openai.com/v1` | — | `gpt-5.4-mini`, `gpt-6.1-sol` |
| Anthropic / `anthropic` | `api` | `https://api.anthropic.com/v1` | — | `claude-sonnet-5-5`, `claude-opus-5-5` |
| MiniMax / `minimax` | `api` или `coding_plan` | `https://api.minimax.io/v1` | CN: `https://api.minimax.cn/v1` | `MiniMax-M3`, `MiniMax-M2.7` |
| DeepSeek / `deepseek` | `api` | `https://api.deepseek.com/v1` | тот же адрес | `deepseek-flash`, `deepseek-v4-pro` |
| Qwen / `qwen` | `api` | `https://dashscope-intl.aliyuncs.com/compatible-mode/v1` | CN: `https://dashscope.aliyuncs.com/compatible-mode/v1`; US: `https://dashscope-us.aliyuncs.com/compatible-mode/v1` | `qwen-plus`, `qwen3.8-max` |
| Qwen / `qwen` | `coding_plan` | `https://coding-intl.dashscope.aliyuncs.com/v1` | CN: `https://coding.dashscope.aliyuncs.com/v1` | `qwen3.7-plus` |
| Другой / `custom` | `api` | точный HTTPS URL провайдера | по его документации | полный ID вручную |

Источники адресов и ключей: [OpenRouter](https://openrouter.ai/docs/quickstart),
[Z.ai API](https://docs.z.ai/guides/develop/http/introduction),
[Z.ai CN](https://docs.bigmodel.cn/cn/guide/develop/http/introduction),
[Z.ai CN Coding](https://docs.bigmodel.cn/cn/coding-plan/quick-start),
[Moonshot API](https://platform.kimi.ai/docs/api/overview),
[Kimi регионы](https://www.kimi.com/code/docs/en/kimi-code/faq.html),
[OpenAI Responses](https://developers.openai.com/api/docs/guides/text),
[Anthropic API](https://platform.claude.com/docs/en/api/overview),
[MiniMax API](https://platform.minimax.io/docs/api-reference/text-chat-openai),
[MiniMax CN](https://platform.minimax.cn/docs/api-reference/text-openai-api),
[DeepSeek](https://api-docs.deepseek.com/),
[Qwen регионы и планы](https://help.aliyun.com/en/model-studio/base-url).

Для API создайте ключ в API-консоли выбранной платформы и включите её
оплату/лимит расходов. У OpenAI это API project key, у Anthropic — ключ
Console, у Moonshot — ключ платформы API, у Qwen — региональный ключ Model
Studio. Подписка на пользовательский чат не заменяет такой ключ.
Региональные ключи Moonshot/Qwen и ключи разных платформ не взаимозаменяемы.
Qwen допускает выделенный URL рабочего пространства из своей документации;
точный путь сохранится. Custom требует совместимый Chat Completions API,
ключ и модель с поддержкой нужных инструментов.

## Z.ai GLM Coding Plan

1. Войдите на выбранную платформу Z.ai/智谱 и оформите GLM Coding Plan.
   Для Individual создайте ключ в **Individual Coding Plan → Plan Overview**;
   для Team возьмите **Team Coding Plan → My Plan**. Team Plan Key нельзя
   заменить обычным API-ключом.
2. Выполните `model`, выберите **Z.ai / 智谱 → GLM Coding Plan** и регион
   аккаунта. Проверьте `/api/coding/paas/v4`, а не обычный `/api/paas/v4`.
3. Введите ключ скрыто или выберите файл `0600`, затем `glm-5.3` или
   `glm-5.3-flash`. Подтвердите сохранение и выполните локальные проверки.

[Официальный quickstart](https://docs.z.ai/devpack/quick-start) описывает ключи
и отдельный адрес плана. [Usage Policy](https://docs.z.ai/devpack/usage-policy)
разрешает план только поддерживаемым продуктам. Коля не заявлен как
одобренный продукт: для фоновых расследований получите разрешение провайдера
или явно настройте API. Наличие пресета само по себе такого разрешения не даёт.

## Kimi Code

1. В Kimi Code Console проверьте членство и создайте membership API key
   `sk-kimi-…`. Это ключ Kimi Code, а не Moonshot API.
2. Выполните `model`, выберите **Kimi Code → Членство Kimi Code**, затем
   глобальный `api.kimi.ai` либо китайский `api.kimi.com` согласно аккаунту.
3. Введите membership key скрыто/через файл. Выберите `kimi-for-coding`;
   `k3`/`k3-256k` и highspeed доступны по уровню членства. Нужен ID без
   добавленного префикса: `k3-256k`, а не `kimi-k3-256k`.
4. Проверьте `/coding/v1` и подтвердите сохранение.

[Официальная инструкция](https://www.kimi.com/code/docs/en/third-party-tools/hermes.html)
указывает источник ключа и уровни доступа: у новых Go-планов может не быть
coding quota. [Правила Kimi Code](https://www.kimi.com/code/docs/en/kimi-code/community-guidelines.html)
ограничивают членство личной интерактивной работой и запрещают фоновую
автоматизацию/подмену клиента. Для автономного `watch` требуется отдельное
разрешение; обычный **Moonshot / Kimi API** — отдельный выбор с API-оплатой.

## MiniMax Coding / Token / M Plan

1. Откройте MiniMax нужного региона. В **Account / Token Plan** проверьте
   назначенный seat плана или Credits и получите **Subscription Key**
   `sk-cp-…`. Ключ может существовать ещё до назначения ресурсов.
2. Выполните `model`, выберите **MiniMax → Coding / Token / M Plan**, затем
   регион. URL совпадает с API: global `https://api.minimax.io/v1`,
   CN `https://api.minimax.cn/v1`; способ доступа и ключ различаются.
3. Введите Subscription Key скрыто/через файл, выберите `MiniMax-M3` или
   другую модель, доступную именно вашему плану; подтвердите сохранение.

[Token Plan](https://platform.minimax.io/docs/token-plan/intro) заменил прежний
Coding Plan и отделяет Subscription Key от PAYG API Key.
[Подключение других инструментов](https://platform.minimax.io/docs/token-plan/other-tools)
описывает этот OpenAI-совместимый путь. M Plan и preview-модели имеют свои
права доступа; имя плана не гарантирует все модели. Проверьте ресурсы своего
аккаунта. Коля не подменяет Subscription Key ключом PAYG. При этом MiniMax
может использовать назначенные этому же ключу купленные Credits после
исчерпания квоты — это правило аккаунта провайдера, а не переключение Коли.

## Qwen: API и Alibaba Coding Plan

API: создайте региональный ключ в Model Studio и выберите **Qwen / Alibaba
Model Studio → API**, регион и ручной/офлайн ID. Coding Plan: используйте
отдельный ключ `sk-sp-…`, режим **Alibaba Coding Plan** и адрес `coding…`.
Для плана отдельный US-пресет не предлагается. Model Studio не поддерживает
GET `/models`: модель сверяйте с кабинетом.
[Официальные адреса](https://help.aliyun.com/en/model-studio/base-url) ограничивают
Coding/Token Plan интерактивным программированием и исключают backend-сервисы.
Фоновый Коля требует отдельного разрешения; API остаётся самостоятельным
способом доступа. [Настройка плана](https://help.aliyun.com/en/model-studio/coding-plan).

## OpenRouter через браузер

Выберите **OpenRouter → API → вход через браузер**. Мастер напечатает
официальный HTTPS адрес OpenRouter. Откройте его, войдите и подтвердите
создание ключа; вставьте показанный одноразовый код в скрытое поле терминала.
Это [официальный S256 PKCE](https://openrouter.ai/docs/guides/overview/auth/oauth):
мобильный/удалённый браузер подходит, локальный callback-сервер не нужен.
Код истекает через десять минут; при ошибке выберите новый вход либо свой
API-ключ. Ctrl-C отменяет ввод. Ключ сохраняется в защищённый файл после
подтверждения конфигурации; авторизация не вызывает генерацию.

Полученный ключ использует **баланс OpenRouter**, как обычный API-ключ.
Подписки ChatGPT/Claude этим входом не подключаются. Для модели можно
ввести полный slug `openai/gpt-5.4-mini`, разрешённый провайдером вариант
с двоеточием (`vendor/model:free`) или семейный псевдоним
`~openai/gpt-latest`/`~anthropic/claude-sonnet-latest`.
Псевдонимы `~…` допустимы только при явном `profile: "openrouter"` в v2;
обычные ID с `:free` не требуют такого расширения грамматики.
[Документация моделей](https://openrouter.ai/docs/guides/overview/models),
[псевдонимы](https://openrouter.ai/docs/quickstart).

## OpenAI и Anthropic

В мастере **OpenAI API** использует настоящий протокол Responses:
`type: "openai_responses"`, `profile: "openai"`, `access: "api"`.
**Anthropic / Claude API** использует Messages:
`type: "anthropic"`, `profile: "anthropic"`, `access: "api"`.
Создайте API-ключ в соответствующей API-консоли, введите его скрыто и
выберите доступную модель. API имеет отдельную оплату.

Вход по потребительской подписке **ChatGPT или Claude в Коле не реализован**.
[Sign in with ChatGPT](https://developers.openai.com/siwc/quickstart) требует
подходящего статуса интеграции; допуск Коли как private client не подтверждён.
[Anthropic Agent SDK](https://code.claude.com/docs/en/agent-sdk/overview) требует
одобрения стороннего продукта для claude.ai login.
[Подписка Claude и API](https://support.claude.com/en/articles/9876003-i-have-a-paid-claude-subscription-pro-max-team-or-enterprise-plans-why-do-i-have-to-pay-separately-to-use-the-claude-api-and-console)
оплачиваются отдельно. Для будущего consumer login нужны разрешение владельца
проекта и допускающий его провайдер. Не используйте токены/credential files
Codex или Claude Code вместо API-ключа Коли.

## Протокол, путь и совместимость YAML

| `provider.type` | Какой суффикс добавляет Коля | Пример полного URL запроса |
| --- | --- | --- |
| `openai_compatible` | `/chat/completions` | `https://api.z.ai/api/coding/paas/v4/chat/completions` |
| `openai_responses` | `/responses` | `https://api.openai.com/v1/responses` |
| `anthropic` | `/messages` | `https://api.anthropic.com/v1/messages` |

Вводите **базовый URL**, без суффикса операции. Указанный путь сохраняется;
мастер добавляет `/v1` только адресу без пути и удаляет завершающий `/`.
Не добавляйте `/v1` к уже полному Z.ai пути. YAML сам URL не переписывает.
Требуется HTTPS DNS-имя, порт 443 либо без порта, без credentials/query/fragment,
кодированных, пустых или `.`/`..` сегментов. Для собственного шлюза можно
явно заменить адрес, сохранив выбранный протокол.

v1 остаётся совместимым: только `openai_compatible`, без `profile`/`access`.
В v2 эти два поля необязательны для старых API-конфигов. Именованный профиль
должен соответствовать протоколу из таблицы пресетов; план требует
`access: "coding_plan"` и подходящий профиль. Поля `region` нет: регион
выражен в сохранённом `base_url`. Неизвестные/повторяющиеся ключи отвергаются.
Существующий v2 конфиг с собственным URL и без профиля сохраняет
свой протокол Responses/Messages при `model`. Для нового шлюза Responses/Messages
выберите OpenAI/Anthropic и явно задайте его URL, либо вручную укажите
соответствующий `type` в v2 без профиля. Пункт custom мастера создаёт
Chat Completions подключение.

## Полный YAML v2 для ручной настройки

Основной путь — `setup`; ниже полный пример для нового файла. Он выбирает
MiniMax Subscription Key и `observe`: алерты наблюдаются без вызова модели.
Приватный каталог контрактов заранее передаёт оператор; дистрибутив не
содержит и не создаёт их. Замените `/absolute/kolya-root`,
`/absolute/operator-contracts`, домены Grafana/GitLab, org ID и datasource UID.
Затем замените оба `<SHA256_…>` настоящими хешами доверенных CA/MCP.

```yaml
# Полный YAML v2: MiniMax Subscription Key, наблюдение без вызова модели.
# Замените /absolute/kolya-root, /absolute/operator-contracts, адреса/UID и оба SHA256.
# Ключ вводится через setup/model или хранится отдельно в файле 0600.
# Доступность MiniMax-M3 зависит от ресурсов аккаунта.
schema_version: 2
environment: "production"

state:
  database_file: "/absolute/kolya-root/db/first-test.db"
  backup_directory: "/absolute/kolya-root/backup"

contracts:
  directory: "/absolute/operator-contracts"

provider:
  type: "openai_compatible"
  profile: "minimax"
  access: "coding_plan"
  base_url: "https://api.minimax.io/v1"
  model: "MiniMax-M3"
  token_file: "/absolute/kolya-root/secrets/provider.token"

grafana:
  url: "https://grafana.example.com:443"
  org_id: 1
  token_file: "/absolute/kolya-root/secrets/grafana.token"
  ca_file: "/absolute/kolya-root/pki/grafana.pem"
  ca_sha256: "<SHA256_GRAFANA_CA>"
  mcp:
    executable_file: "/absolute/kolya-root/bin/mcp-grafana"
    executable_sha256: "<SHA256_MCP_BINARY>"
    working_directory: "/absolute/kolya-root/mcp-work"

victorialogs:
  transport: "grafana_proxy"
  datasource_uid: "your_victorialogs_uid"

alerts:
  source: "grafana_polling"
  poll_interval: "60s"

releases:
  retention: "720h"
  incident_window:
    before: "2h"
    after: "15m"
  gitlab:
    api_url: "https://gitlab.example.com/api/v4"
    token_file: "/absolute/kolya-root/secrets/gitlab.token"
    discovery: "all_token_visible"
    include_archived: false
    environment_tiers:
      - "production"
    poll_interval: "60s"
  grafana_annotations:
    connection: "grafana"
    payload_schema: "kolya.release.v1"
    required_tags:
      - "kolya-release-v1"
      - "deployment"
      - "production"
    require_services: true

runtime:
  config_reload: false
  output:
    format: "jsonl"
    publication: "stdout_at_least_once"

telegram:
  enabled: false

features:
  memory:
    mode: "OFF"
  repository_access:
    mode: "OFF"
  log_queries:
    mode: "OFF"
  strategy_adaptation:
    mode: "OFF"
  runbook_proposals:
    mode: "OFF"

# Локальное состояние здоровья; Telegram отключён.
health:
  enabled: true
  failure_threshold: 3
  source_max_age: "3m"
  heartbeat_max_age: "90s"
  delivery_max_age: "5m"
  notifications: off
  telegram_topic_id: 0

proactivity:
  mode: observe
  scope: all
  include_suppressed: false
  min_firing_for: "30s"
  max_snapshot_age: "2m"
  max_attempts: 3
  max_concurrent: 1
```

SHA256 — первая колонка, ровно 64 строчных hex-символа. На Linux:

```sh
sha256sum "/absolute/kolya-root/pki/grafana.pem"
sha256sum "/absolute/kolya-root/bin/mcp-grafana"
```

На macOS:

```sh
shasum -a 256 "/absolute/kolya-root/pki/grafana.pem"
shasum -a 256 "/absolute/kolya-root/bin/mcp-grafana"
```

Пути в YAML — реальные абсолютные физические пути, без `~`, `$HOME`, `${…}`
и symlink; подстановки переменных в YAML нет. Сохраняйте config и отдельные
непустые файлы ключей с правами `0600` своего пользователя, приватные
каталоги с `0700`; токены не вставляются в YAML/аргументы/unit/plist/Git.
Вместо ручного ввода в файл используйте скрытый ввод в `setup`/`model`.
Другую модель/провайдера удобнее выбрать `model` после подготовки этого
валидного конфига; не заменяйте существующий рабочий файл всем шаблоном.

Собственный CA задаётся парой `ca_file`/`ca_sha256` в provider;
без неё используются системные CA. При повторном выборе тех же провайдера,
доступа и URL сохраняются ссылка на ключ, модель и закреплённый CA.
Enter у существующего CA оставляет его, `-` явно удаляет. Изменённые байты
по прежнему пути дают `HASH_MISMATCH`; хеш не обновляется молча перед GET
каталога. После независимой проверки нового артефакта явно разрешите
обновление SHA256 в разделе подключений полного `setup` или укажите новый
проверенный файл.

## Проверки и диагностика

```sh
"$HOME/.kolya/bin/kolya-agent" check-config --config "$HOME/.kolya/config.yaml"
"$HOME/.kolya/bin/kolya-agent" preflight --config "$HOME/.kolya/config.yaml"
"$HOME/.kolya/bin/kolya-agent" probe --config "$HOME/.kolya/config.yaml"
```

`CONFIG_VALID` подтверждает схему без чтения ключей/CA и без сети;
`PREFLIGHT_OK` — локальные файлы, владельца, права и хеши. `probe` делает
read-only запросы **Grafana/GitLab**, не проверяет LLM, модель или MCP.
Telegram проверяется отдельным `telegram probe`. GET списка моделей проверяет
только этот API-каталог; он не доказывает разрешение/успех генерации.
Локальные TLS-тесты — `LOCAL_SYNTHETIC`. Подключение реального провайдера
и полный цикл реального алерта остаются операторским `LIVE_TEST`.

| Ситуация | Что проверить |
| --- | --- |
| `SETUP_EXISTING_CONFIG_INVALID` | Путь к config; сначала полный `setup`. Не заменяйте повреждённый рабочий файл шаблоном вслепую. |
| `CONFIG_VALUE_INVALID` | Протокол/profile/access, базовый URL, абсолютные пути, оба SHA256; v1 не принимает новые поля. |
| `PREFLIGHT_BLOCKED`, `MISSING`, `INVALID` | Файлы, владельца, `0600`, приватные каталоги, CA/MCP. SQLite не создавайте для этой проверки. |
| `HASH_MISMATCH` | Независимо проверить заменённый CA/MCP и явно разрешить новую фиксацию хеша. |
| Каталог недоступен, 401/403 | API или плановый ключ, регион, квота/seat и доступ к модели; затем офлайн/ручной ID. Для Qwen отсутствие `/models` ожидаемо. |
| `MODEL_AUTH_REJECTED`, `MODEL_REQUEST_REJECTED` | Ключ нужного доступа/региона, model ID, URL и протокол. Коля не включает API-оплату в ответ на ошибку. |
| После `SETUP_SAVED` работает прежняя модель | Выполнить `service restart --root …` либо перезапустить foreground `watch`. |

Передавайте для диагностики команду, exit code и фиксированный код ошибки,
без содержимого токенов, одноразовых кодов или внешних credential stores.

## Telegram

Telegram необязателен и является каналом уведомлений: сообщения `/start`
или вопросы в группе не запускают расследование.

1. Откройте в Telegram официальный `@BotFather`, выполните `/newbot`, задайте
   имя/username. Выданный token — секрет; сохраните его у себя.
2. Подготовьте тестовую supergroup и включите **Темы / Topics**. Обычный
   личный чат или канал не подходит.
3. Добавьте бота администратором с правом **Управление темами / Manage Topics**
   и возможностью отправлять сообщения. Темы инцидентов агент создаст сам.
4. Получите у администратора **numeric chat ID всей группы**, обычно вида
   `-100…`. Это не username бота и не ID отдельной темы; мастер сам его не
   определяет. Не передавайте token посторонним ботам для поиска ID.
5. Запустите `setup`, выберите Telegram, включите его, введите token скрыто
   или выберите файл, затем укажите chat ID и подтвердите сохранение.

```sh
"$HOME/.kolya/bin/kolya-agent" setup --root "$HOME/.kolya"
"$HOME/.kolya/bin/kolya-agent" telegram probe --config "$HOME/.kolya/config.yaml"
"$HOME/.kolya/bin/kolya-agent" telegram status --config "$HOME/.kolya/config.yaml"
```

Нужен прямой HTTPS доступ к `api.telegram.org:443`. Probe проверяет доступ
и права, но не доказывает доставку реального расследования. После успешных
проверок запустите агент, дождитесь подходящего реального алерта и проверьте
новую тему, ход расследования и итог. Для изменений работающего процесса
нужен явный `service restart` или перезапуск foreground watch.

## Проверки и запуск в фоне

```sh
"$HOME/.kolya/bin/kolya-agent" check-config --config "$HOME/.kolya/config.yaml"
"$HOME/.kolya/bin/kolya-agent" preflight --config "$HOME/.kolya/config.yaml"
"$HOME/.kolya/bin/kolya-agent" probe --config "$HOME/.kolya/config.yaml"
```

`check-config` проверяет YAML, `preflight` — локальные файлы/права/хеши,
`probe` — read-only Grafana/GitLab, без проверки модели или MCP. `service status` проверяет состояние
процесса. Только наблюдаемый оператором полный цикл реального алерта даёт
основание заявлять LIVE_TEST. Ни одна локальная проверка не заменяет этот цикл.

После сохранения мастер предлагает установку и запуск службы, только
регистрацию либо работу на переднем плане/позже. Для уже работающей службы
перезапуск спрашивается отдельно. В режиме `manual` служба watch не нужна;
используйте ручное `investigate` с подготовленным файлом события.

```sh
"$HOME/.kolya/bin/kolya-agent" service install --root "$HOME/.kolya" --work-dir "$HOME"
"$HOME/.kolya/bin/kolya-agent" service start --root "$HOME/.kolya"
"$HOME/.kolya/bin/kolya-agent" service status --root "$HOME/.kolya"
"$HOME/.kolya/bin/kolya-agent" service restart --root "$HOME/.kolya"
"$HOME/.kolya/bin/kolya-agent" service stop --root "$HOME/.kolya"
"$HOME/.kolya/bin/kolya-agent" service uninstall --root "$HOME/.kolya"
```

`install` регистрирует службу без немедленного старта. Linux использует
systemd user, macOS — LaunchAgent. Автозапуск вступит в силу при следующем
входе пользователя. Linux требует доступный пользовательский менеджер;
для работы после выхода нужна отдельно согласованная политика linger.
Установщик не использует sudo и не меняет linger. macOS требует GUI-сессию;
спящий ноутбук не обрабатывает алерты. При отсутствии менеджера используйте:

```sh
"$HOME/.kolya/bin/kolya-agent" watch --config "$HOME/.kolya/config.yaml"
```

Linux-журнал: `journalctl --user -u kolya-agent.service -f`.
macOS: `~/.kolya/logs/service.stdout.log` и `service.stderr.log`.
`uninstall` сохраняет конфиг, токены, базу и программу. Статусы: код 0 —
процесс работает, 3 — остановлен, 4 — менеджер недоступен, 5 — не установлен.
Сбой регистрации/запуска не удаляет сохранённый конфиг: проверьте preflight,
пользовательский менеджер и повторите нужную команду.

## Обновление и восстановление

Повторите installer нужного релиза. Конфиг и база сохраняются; те же байты
программы не заменяются. Обновление сохраняет точный старый бинарник как
`ROOT/bin/kolya-agent.previous-<random>` и печатает его путь. Старая служба
продолжает прежний процесс до явного `service restart`.

Для отката остановите службу и запустите **напечатанный предыдущий бинарник**
с `install --root /абсолютный/корень --no-onboard`. Проверьте version и preflight,
затем явно запустите службу. Храните backup, пока новая версия не проверена.
Не перемещайте активную SQLite-базу ради отката программы.

Мастер печатает backup конфигурации при замене. Отменённые/некорректные правки
сохраняют прежний файл. Ошибка финального шага службы не отменяет сохранение
конфига. При ошибке прав/ссылок используйте приватный каталог своего
пользователя, без ослабления проверок. На macOS нужны фактические абсолютные
пути без ссылок, например `/private/tmp`, если выбран временный каталог.

`install --help`, `setup --help` и `service --help` показывают флаги без изменений.
Авторские права и лицензии зависимостей: `THIRD_PARTY_NOTICES.txt`.
