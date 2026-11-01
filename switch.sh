#!/bin/bash
# WM Switcher — aynı anda yalnızca bir tiling pencere yöneticisi çalıştırır.
#
#   switch.sh <id|none>   diğerlerini kapat, seçileni başlat, seçimi kaydet
#   switch.sh restore     kayıtlı seçimi başlat (login'de uygulama çağırır)
#   switch.sh status      kayıtlı seçim + çalışanlar
#
# WM listesi: wms.conf (aynı klasör)

set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
CONF="$DIR/wms.conf"
STATE_DIR="$HOME/.config/wm-switcher"
STATE="$STATE_DIR/current"
LOCK="$STATE_DIR/.lock"
QUIT_WAIT=3   # normal quit sonrası beklenecek saniye

mkdir -p "$STATE_DIR"

ids=() ; bids=() ; apps=()
while IFS='|' read -r id name bid app cfg letter; do
    [[ -z "$id" || "$id" == \#* ]] && continue
    ids+=("$id"); bids+=("$bid"); apps+=("$app")
done < "$CONF"

LOG="$STATE_DIR/switch.log"
log() {
    echo "[wm-switcher] $*" >&2
    echo "$(date '+%F %T') $*" >> "$LOG"
}

index_of() {
    local i
    for i in "${!ids[@]}"; do [[ "${ids[$i]}" == "$1" ]] && { echo "$i"; return 0; }; done
    return 1
}

pids_of() { pgrep -f "^${apps[$1]}/Contents/MacOS/"; }
is_running() { pids_of "$1" >/dev/null; }

stop_wm() {
    local i=$1 t
    is_running "$i" || return 0
    log "${ids[$i]} kapatılıyor"
    osascript -e "with timeout of $QUIT_WAIT seconds" \
              -e "tell application id \"${bids[$i]}\" to quit" \
              -e "end timeout" >/dev/null 2>&1 &
    for ((t = 0; t < QUIT_WAIT * 4; t++)); do
        is_running "$i" || return 0
        sleep 0.25
    done
    log "${ids[$i]} kapanmadı, TERM"
    pkill -TERM -f "^${apps[$i]}/Contents/MacOS/"
    for ((t = 0; t < 4; t++)); do
        is_running "$i" || return 0
        sleep 0.25
    done
    log "${ids[$i]} hâlâ açık, KILL"
    pkill -KILL -f "^${apps[$i]}/Contents/MacOS/"
}

switch_to() {
    local target="$1" t i
    if [[ "$target" != none ]]; then
        t=$(index_of "$target") || { log "bilinmeyen WM: $target"; exit 2; }
        [[ -d "${apps[$t]}" ]] || { log "$target kurulu değil (${apps[$t]})"; exit 3; }
    fi

    # Aynı WM zaten açık ve tek başına çalışıyorsa hiçbir şey yapma
    local others=0
    for i in "${!ids[@]}"; do
        [[ "${ids[$i]}" == "$target" ]] && continue
        is_running "$i" && others=1
    done
    if [[ $others -eq 0 ]] && { [[ "$target" == none ]] || is_running "$t"; }; then
        echo "$target" > "$STATE"
        log "$target zaten aktif"
        return 0
    fi

    for i in "${!ids[@]}"; do
        [[ "${ids[$i]}" == "$target" ]] || stop_wm "$i"
    done

    if [[ "$target" != none ]] && ! is_running "$t"; then
        log "$target başlatılıyor"
        open -g -a "${apps[$t]}" || { log "$target açılamadı"; exit 4; }
    fi
    echo "$target" > "$STATE"
}

cmd="${1:-}"
case "$cmd" in
    status)
        echo "kayıtlı: $(cat "$STATE" 2>/dev/null || echo none)"
        for i in "${!ids[@]}"; do
            if is_running "$i"; then echo "çalışıyor: ${ids[$i]}"; fi
        done
        exit 0 ;;
    restore) cmd="$(cat "$STATE" 2>/dev/null || echo none)" ;;
    "" | -h | --help)
        echo "kullanım: $(basename "$0") <$(IFS='|'; echo "${ids[*]}")|none|restore|status>" >&2
        exit 1 ;;
esac

# Aynı anda iki geçiş çalışmasın (çift tıklama vb.)
if ! mkdir "$LOCK" 2>/dev/null; then
    # 30 sn'den eski kilit kalmışsa temizle
    if (( $(date +%s) - $(stat -f %m "$LOCK" 2>/dev/null || echo 0) > 30 )); then
        rmdir "$LOCK"; mkdir "$LOCK"
    else
        log "başka bir geçiş sürüyor"; exit 5
    fi
fi
trap 'rmdir "$LOCK" 2>/dev/null' EXIT

# Log dosyası büyümesin
[[ -f "$LOG" ]] && (( $(wc -l < "$LOG") > 500 )) && tail -200 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"

log "istek: $cmd"
switch_to "$cmd"
