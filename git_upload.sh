#!/bin/bash
# Този скрипт подготвя и качва проекта в GitHub.
set -e

# Проверяваме дали скриптът се изпълнява от root (със sudo)
if [ "$(id -u)" -eq 0 ]; then
   echo "ГРЕШКА: Този скрипт не трябва да се изпълнява със sudo!" >&2
   echo "Моля, изпълни го като твоя потребител: ./git_upload.sh" >&2
   exit 1
fi

# --- КОНФИГУРАЦИЯ ---
GITHUB_URL="https://github.com/clickman43/pxe-boss.git"

# --- ОСНОВНА ЛОГИКА ---
echo ">>> Стъпка 1: Проверка на Git хранилище..."
if [ ! -d ".git" ]; then git init; fi
echo "Git е инициализиран."

echo ">>> Стъпка 2: Създаване на .gitignore файл..."
cat <<'EOF' > .gitignore
venv/
__pycache__/
*.pyc
.env
*.log
configs/settings.json
EOF
echo ".gitignore е създаден."

echo ">>> Стъпка 3: Добавяне и 'commit' на файловете..."
git add .
if ! git diff-index --quiet HEAD; then
    # <<< КЛЮЧОВАТА ПРОМЯНА Е ТУК
    git commit --no-gpg-sign -m "Initial commit or update of PXE-Boss project"
    echo "Промените са 'commit'-нати."
else
    echo "Няма нови промени за 'commit'."
fi

echo ">>> Стъпка 4: Конфигуриране на връзката с GitHub..."
git remote remove origin 2>/dev/null || true
git remote add origin "$GITHUB_URL"
echo "Връзката с GitHub е конфигурирана."

echo ">>> Стъпка 5: Качване на кода..."
git branch -M main
git push -u origin main

echo ""
echo "-------------------------------------------"
echo "✅ УСПЕХ! Проектът е качен в GitHub!"
echo "-------------------------------------------"
