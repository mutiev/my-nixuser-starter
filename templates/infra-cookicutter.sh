#!/bin/bash

# Каталоги, которые считаем best-practice для домашнего dev/infra каталога
declare -A FOLDERS=(
  ["apps"]="Живые сервисы, отдельные каталоги для каждого (node-red, icecast, autossh и др.)"
  ["scripts"]="Утилиты, стартеры, деплой и вспомогательные скрипты"
  ["build-sources"]="Исходники для сборки (ffmpeg, кастомные бинарники и т.д.)"
  ["bin"]="Твои собранные/скачанные бинарники"
  ["data"]="Базы, дампы, временные файлы"
  ["config"]="Конфиги и .env, шаблоны настроек"
  ["docs"]="Markdown-инструкции, заметки, howto"
  ["logs"]="Логи сервисов"
  ["public"]="Открытая статика (если нужно раздавать через nginx и т.п.)"
  ["locales"]="Файлы переводов (если планируешь мультиязычность)"
  ["legacy"]="Архив старого мусора и бэкапы"
)

declare -A SCRIPTS=(
  ["scripts/restart-all.sh"]="Рестарт всех сервисов"
  ["scripts/backup.sh"]="Бэкап пользовательских данных/сервисов"
  ["scripts/menu.sh"]="Главное меню или entrypoint для быстрого управления"
  ["scripts/build-ffmpeg.sh"]="Скрипт сборки ffmpeg (или другого крупного бинаря)"
)

echo "💡 Cookiecutter инфраструктуры для домашнего пользователя"
echo "Текущий путь: $HOME (можно запускать из любого каталога)"
echo
echo "Проверяю существующие каталоги..."
echo

# Папки
for dir in "${!FOLDERS[@]}"; do
    if [ -d "$dir" ]; then
        echo "✅ [$dir] — уже существует"
    else
        echo "🟡 [$dir] — создать!  (${FOLDERS[$dir]})"
    fi
done

echo
echo "Рекомендуемые шаблоны-скрипты:"
echo

# Скрипты
for script in "${!SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        echo "✅ $script — уже есть"
    else
        echo "🟡 $script — создать (${SCRIPTS[$script]})"
    fi
done

echo
echo "P.S. После создания новых каталогов — положи в каждый README.md, чтобы не забыть для чего он."

# Подсказка
echo
echo "Пример создания: mkdir -p apps scripts build-sources bin data config docs logs public locales legacy"