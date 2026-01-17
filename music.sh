#!/bin/bash

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERR]${NC} $1"; }

# ===============================
# ROOT CHECK
# ===============================
if [[ $EUID -eq 0 ]]; then
  error "Не запускай скрипт от root"
  exit 1
fi

# ===============================
# ENSURE MPD RUNNING
# ===============================
ensure_mpd() {
  # Останавливаем все старые MPD
  pkill mpd 2>/dev/null || true

  # Создаём FIFO заново
  if [ -p /tmp/mpd.fifo ]; then
      rm /tmp/mpd.fifo
  fi
  mkfifo /tmp/mpd.fifo
  info "FIFO /tmp/mpd.fifo создан"

  # Запускаем MPD с конфигом
  mpd ~/.config/mpd/mpd.conf
  sleep 1
}


# ===============================
# MENU
# ===============================
menu() {
  clear
  echo "================================="
  echo " 🎵 MPD + NCMPCPP MUSIC SYSTEM"
  echo "================================="
  echo "1) Установить"
  echo "2) Удалить"
  echo "3) Добавить ВСЮ музыку в плейлист"
  echo "4) Очистить плейлист"
  echo "5) Выход"
  echo "================================="
  read -rp "Выбери пункт: " choice

  case "$choice" in
    1) install ;;
    2) uninstall ;;
    3) add_all ;;
    4) clear_playlist ;;
    5) exit 0 ;;
    *) error "Неизвестная команда"; sleep 1; menu ;;
  esac
}

# ===============================
# INSTALL
# ===============================
install() {
  info "Обновляю репозитории..."
  sudo dnf makecache -y

  info "Устанавливаю пакеты..."
  sudo dnf install -y \
    mpd \
    ncmpcpp \
    mpc \
    pulseaudio-utils

  info "Создаю директории..."
  mkdir -p ~/Music
  mkdir -p ~/.config/mpd/playlists
  mkdir -p ~/.config/ncmpcpp
  mkdir -p ~/.local/bin

  # ===============================
  # MPD CONFIG с FIFO визуализатором
  # ===============================
  cat > ~/.config/mpd/mpd.conf << 'EOF'
music_directory "~/Music"
playlist_directory "~/.config/mpd/playlists"
db_file "~/.config/mpd/database"
log_file "~/.config/mpd/log"
pid_file "~/.config/mpd/pid"
state_file "~/.config/mpd/state"

bind_to_address "127.0.0.1"
port "6600"

# Нормальный PulseAudio output
audio_output {
    type "pulse"
    name "PulseAudio"
    mixer_type "software"
}

# FIFO output для ncmpcpp визуализатора
audio_output {
    type        "fifo"
    name        "my_fifo"
    path        "/tmp/mpd.fifo"
    format      "44100:16:2"
}
EOF

  # ===============================
  # NCMPCPP CONFIG с визуализатором
  # ===============================
  cat > ~/.config/ncmpcpp/config << 'EOF'
mpd_host = 127.0.0.1
mpd_port = 6600
mpd_music_dir = ~/Music

colors_enabled = yes

visualizer_data_source = "/tmp/mpd.fifo"
visualizer_output_name = "my_fifo"
visualizer_in_stereo = "yes"
visualizer_type = spectrum
visualizer_look = "+|"

header_visibility = no
statusbar_visibility = no
titles_visibility = no

cyclic_scrolling = yes
centered_cursor = yes
autocenter_mode = yes
EOF

  # ===============================
  # MUSIC CLI
  # ===============================
  cat > ~/.local/bin/music << 'EOF'
#!/bin/bash

show_help() {
  echo "🎵 music — управление MPD"
  echo ""
  echo "Команды:"
  echo "  play | pause | toggle | stop"
  echo "  next | prev"
  echo "  update | status"
  echo "  ncmpcpp"
}

case "$1" in
  ""|help|--help|-h) show_help ;;
  play) mpc play ;;
  pause) mpc pause ;;
  toggle) mpc toggle ;;
  stop) mpc stop ;;
  next) mpc next ;;
  prev) mpc prev ;;
  update) mpc update ;;
  status) mpc status ;;
  ncmpcpp) ncmpcpp ;;
  *) show_help ;;
esac
EOF
  chmod +x ~/.local/bin/music

  # ===============================
  # INITIALIZE PLAYLIST
  # ===============================
  ensure_mpd
  mpc update
  mpc clear
  mpc add /

  success "Установка завершена. Весь каталог ~/Music добавлен в плейлист."
  read -rp "Нажми Enter для возврата в меню..."
  menu
}

# ===============================
# ADD ALL MUSIC
# ===============================
add_all() {
  ensure_mpd
  info "Обновляю базу и добавляю всю музыку..."
  mpc update
  mpc clear
  mpc add /
  success "Вся музыка добавлена в плейлист"
  read -rp "Enter — назад в меню"
  menu
}

# ===============================
# CLEAR PLAYLIST
# ===============================
clear_playlist() {
  ensure_mpd
  warn "Очищаю плейлист..."
  mpc clear
  success "Плейлист очищен"
  read -rp "Enter — назад в меню"
  menu
}

# ===============================
# UNINSTALL
# ===============================
uninstall() {
  warn "Удаляю MPD и ncmpcpp..."
  pkill mpd 2>/dev/null || true

  sudo dnf remove -y mpd ncmpcpp mpc pulseaudio-utils

  rm -rf ~/.config/mpd
  rm -rf ~/.config/ncmpcpp
  rm -f ~/.local/bin/music

  success "Удалено. Папка ~/Music сохранена."
  read -rp "Enter — назад в меню"
  menu
}

menu
