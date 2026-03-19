#!/bin/bash

# ============================================================================
# fedora_optimize.sh - Оптимизация Fedora
# Сохранить как fedora_optimize.sh, затем: chmod +x fedora_optimize.sh && ./fedora_optimize.sh
# ============================================================================

set -e  # Останавливаться при ошибках

echo "========================================================"
echo "🚀 НАЧИНАЕМ ОПТИМИЗАЦИЮ FEDORA"
echo "========================================================"

# ============================================================================
# ШАГ 1: ИСПРАВЛЕНИЕ ОШИБКИ openh264
# ============================================================================
echo "▶ ШАГ 1: Исправляем ошибку с пакетом openh264..."
if ! grep -q "exclude=openh264" /etc/dnf/dnf.conf; then
    echo "# Автоматическое исключение проблемного пакета" | sudo tee -a /etc/dnf/dnf.conf
    echo "exclude=openh264" | sudo tee -a /etc/dnf/dnf.conf
    echo "✅ openh264 добавлен в исключения"
else
    echo "✅ openh264 уже в исключениях"
fi

sleep 1

# ============================================================================
# ШАГ 2: УСТАНОВКА RPM FUSION
# ============================================================================
echo ""
echo "▶ ШАГ 2: Устанавливаем репозитории RPM Fusion..."

# Проверяем, не установлены ли уже RPM Fusion репозитории
if ! rpm -q rpmfusion-free-release > /dev/null 2>&1; then
    echo "📦 Устанавливаем RPM Fusion Free..."
    sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
    echo "✅ RPM Fusion Free установлен"
else
    echo "✅ RPM Fusion Free уже установлен"
fi

if ! rpm -q rpmfusion-nonfree-release > /dev/null 2>&1; then
    echo "📦 Устанавливаем RPM Fusion Non-Free..."
    sudo dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    echo "✅ RPM Fusion Non-Free установлен"
else
    echo "✅ RPM Fusion Non-Free уже установлен"
fi

sleep 1

# ============================================================================
# ШАГ 3: УСКОРЕНИЕ DNF/DNF5
# ============================================================================
echo ""
echo "▶ ШАГ 3: Настраиваем ускорение DNF..."

# Проверяем, есть ли уже настройки ускорения
if ! grep -q "fastestmirror=True" /etc/dnf/dnf.conf; then
    echo "⚡ Добавляем настройки ускорения в dnf.conf..."
    sudo tee -a /etc/dnf/dnf.conf > /dev/null << 'EOF'

# ============================================================================
# НАСТРОЙКИ УСКОРЕНИЯ DNF (добавлено скриптом)
# ============================================================================
fastestmirror=True           # Автоматический выбор быстрых зеркал
max_parallel_downloads=10    # Параллельные загрузки (ускоряет в 5-10 раз)
defaultyes=True             # Ответ "Да" по умолчанию
keepcache=True              # Сохранять загруженные пакеты в кэше
deltarpm=True               # Загружать только изменения (экономит трафик)
deltarpm_percentage=70      # Процент изменения для deltarpm
metadata_expire=1h          # Частота обновления метаданных
minrate=1                   # Минимальная скорость загрузки
ip_resolve=4                # Использовать IPv4 (если IPv6 медленный)
timeout=10                  # Таймаут соединения (секунды)
retries=3                   # Количество повторных попыток
EOF
    echo "✅ Настройки ускорения добавлены"
else
    echo "✅ Настройки ускорения уже присутствуют"
fi

sleep 1

# ============================================================================
# ШАГ 4: УСТАНОВКА ПЛАГИНОВ DNF
# ============================================================================
echo ""
echo "▶ ШАГ 4: Устанавливаем плагины DNF..."

# Проверяем и устанавливаем плагины
echo "🔌 Проверяем базовые плагины DNF..."
if ! dnf list installed "dnf-plugins-core" > /dev/null 2>&1; then
    sudo dnf install -y dnf-plugins-core
    echo "✅ Базовые плагины DNF установлены"
else
    echo "✅ Базовые плагины DNF уже установлены"
fi

sleep 1

# ============================================================================
# ШАГ 5: УСТАНОВКА GNOME УТИЛИТ
# ============================================================================
echo ""
echo "▶ ШАГ 5: Устанавливаем GNOME Tweaks и утилиты..."

# Список пакетов для установки
gnome_packages=(
    "gnome-tweaks"          # Основные настройки GNOME
)

for package in "${gnome_packages[@]}"; do
    echo "📦 Проверяем $package..."
    if ! dnf list installed "$package" > /dev/null 2>&1; then
        sudo dnf install -y "$package"
        echo "✅ $package установлен"
    else
        echo "✅ $package уже установлен"
    fi
done

sleep 1

# ============================================================================
# ШАГ 6: УСТАНОВКА ШРИФТОВ ДЛЯ РАЗРАБОТКИ
# ============================================================================
echo ""
echo "▶ ШАГ 6: Устанавливаем шрифты для разработки (Fira Code и JetBrains Mono)..."

# Список шрифтов для установки
fonts_packages=(
    "fira-code-fonts"          # Шрифт Fira Code с лигатурами
    "jetbrains-mono-fonts"     # Шрифт JetBrains Mono
)

for package in "${fonts_packages[@]}"; do
    echo "📦 Проверяем $package..."
    if ! dnf list installed "$package" > /dev/null 2>&1; then
        sudo dnf install -y "$package"
        echo "✅ $package установлен"
    else
        echo "✅ $package уже установлен"
    fi
done

sleep 1

# ============================================================================
# ШАГ 7: ОЧИСТКА КЭША
# ============================================================================
echo ""
echo "▶ ШАГ 7: Очищаем кэш системы..."

echo "🧹 Останавливаем GNOME Software..."
if pgrep -x "gnome-software" > /dev/null; then
    killall gnome-software 2>/dev/null || true
    echo "✅ GNOME Software остановлен"
fi

echo "🧹 Удаляем кэш GNOME Software..."
rm -rf ~/.cache/gnome-software 2>/dev/null || true
echo "✅ Кэш GNOME Software очищен"

echo "🧹 Очищаем кэш DNF..."
sudo dnf clean all
echo "✅ Кэш DNF очищен"

sleep 1

# ============================================================================
# ШАГ 8: УСТАНОВКА МЕНЕДЖЕРА РАСШИРЕНИЙ
# ============================================================================
echo ""
echo "▶ ШАГ 8: Устанавливаем менеджер расширений GNOME..."
echo "========================================================"

flatpak install flathub com.mattjakeman.ExtensionManager -y

sleep 1

# ============================================================================
# ШАГ 9: НАСТРОЙКА ГОРЯЧИХ КЛАВИШ
# ============================================================================
echo ""
echo "▶ ШАГ 9: Настраиваем Alt+Shift для смены языка..."
echo "========================================================"

gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward "['<Alt>Shift_L']"

# ============================================================================
# ШАГ 10: УСТАНОВКА МУЛЬТИМЕДИА КОДЕКОВ
# ============================================================================
echo ""
echo "▶ ШАГ 10: Устанавливаем мультимедиа кодеки..."
echo "========================================================"
sudo dnf group install multimedia -y

# ============================================================================
# ШАГ 11: УСТАНОВКА ТОРРЕНТ-КЛИЕНТА
# ============================================================================
echo ""
echo "▶ ШАГ 11: Устанавливаем qBittorrent..."
echo "========================================================"
sudo dnf install qbittorrent -y

# ============================================================================
# ЗАВЕРШЕНИЕ
# ============================================================================
echo ""
echo "========================================================"
echo "✅ ОПТИМИЗАЦИЯ ЗАВЕРШЕНА!"
echo "========================================================"
echo ""
echo "📋 ЧТО БЫЛО СДЕЛАНО:"
echo "   1. ✅ Исправлена ошибка openh264"
echo "   2. ✅ Установлены RPM Fusion репозитории"
echo "   3. ✅ Настроено ускорение DNF (10x быстрее!)"
echo "   4. ✅ Установлены плагины DNF"
echo "   5. ✅ Установлены GNOME Tweaks и утилиты"
echo "   6. ✅ Установлены шрифты Fira Code и JetBrains Mono для VS Code"
echo "   7. ✅ Очищен системный кэш"
echo "   8. ✅ Установлен менеджер расширений GNOME"
echo "   9. ✅ Настроены горячие клавиши Alt+Shift для смены языка"
echo "   10. ✅ Установлены мультимедиа кодеки"
echo "   11. ✅ Установлен qBittorrent"
echo ""
echo "🎨 ЧТО ДЕЛАТЬ ДАЛЬШЕ:"
echo ""
echo "1. Установите полезные расширения через Extension Manager:"
echo "   - Vitals (мониторинг системы)"
echo "   - Dash to Dock (удобная панель)"
echo "   - Burn my window (красивые эффекты)"
echo "   - Keep pinned apps in AppGrid (Трей)"
echo "   - AppIndicator and KStatusNotifierItem Support"
echo ""
echo "2. В VS Code добавьте в settings.json:"
echo '   {'
echo '       "editor.fontFamily": "JetBrains Mono",'
echo '       "editor.fontLigatures": true'
echo '   }'
echo "   (или используйте 'Fira Code' вместо 'JetBrains Mono')"
echo ""
echo "3. Обновите систему:"
echo "   sudo dnf update -y"
echo ""
echo "4. Драйверы NVIDIA (если нужно):"
echo "   https://github.com/oddmario/NVIDIA-Fedora-Driver-Guide#driver"
echo ""
echo "5. Перезагрузите компьютер:"
echo "   sudo reboot"
echo ""
