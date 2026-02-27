#!/bin/bash
# ============================================================
#  MAC MAINTENANCE REPORT — HTML Edition
#  Compatibile con qualsiasi Mac (Intel & Apple Silicon)
#  Genera una pagina web con grafici e informazioni di sistema
# ============================================================

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_HTML="$HOME/Desktop/mac_report_${TIMESTAMP}.html"

# ============================================================
#  RACCOLTA DATI
# ============================================================

# --- Sistema ---
MAC_MODEL=$(system_profiler SPHardwareDataType 2>/dev/null | awk -F': ' '/Model Name/{print $2}' | xargs)
MAC_IDENTIFIER=$(system_profiler SPHardwareDataType 2>/dev/null | awk -F': ' '/Model Identifier/{print $2}' | xargs)
MAC_CHIP=$(system_profiler SPHardwareDataType 2>/dev/null | awk -F': ' '/Chip/{print $2}' | xargs)
[ -z "$MAC_CHIP" ] && MAC_CHIP=$(system_profiler SPHardwareDataType 2>/dev/null | awk -F': ' '/Processor Name/{print $2}' | xargs)
MAC_MEMORY=$(system_profiler SPHardwareDataType 2>/dev/null | awk -F': ' '/Memory/{print $2}' | xargs)
MAC_SERIAL=$(system_profiler SPHardwareDataType 2>/dev/null | awk -F': ' '/Serial Number/{print $2}' | xargs)
MACOS_VERSION=$(sw_vers -productVersion 2>/dev/null)
MACOS_BUILD=$(sw_vers -buildVersion 2>/dev/null)
MACOS_NAME=$(sw_vers -productName 2>/dev/null)
UPTIME_RAW=$(uptime 2>/dev/null)
HOSTNAME=$(hostname -s 2>/dev/null)
CURRENT_USER=$(whoami)
REPORT_DATE=$(date '+%d/%m/%Y alle %H:%M:%S')

# --- CPU & Architettura ---
CPU_ARCH=$(uname -m 2>/dev/null)
CPU_CORES=$(sysctl -n hw.logicalcpu 2>/dev/null)
CPU_PHYSICAL=$(sysctl -n hw.physicalcpu 2>/dev/null)

# --- Disco ---
DISK_TOTAL=$(df -h / 2>/dev/null | awk 'NR==2{print $2}')
DISK_USED=$(df -h / 2>/dev/null | awk 'NR==2{print $3}')
DISK_FREE=$(df -h / 2>/dev/null | awk 'NR==2{print $4}')
DISK_PCT=$(df / 2>/dev/null | awk 'NR==2{gsub(/%/,"",$5); print $5}')
DISK_PCT_NUM=${DISK_PCT:-0}

# --- Memoria RAM ---
RAM_TOTAL_BYTES=$(sysctl -n hw.memsize 2>/dev/null)
RAM_TOTAL_GB=$(echo "$RAM_TOTAL_BYTES" | awk '{printf "%.0f", $1/1073741824}')
# Pressione memoria tramite vm_stat
VM_STAT=$(vm_stat 2>/dev/null)
PAGE_SIZE=$(vm_stat 2>/dev/null | awk '/page size/{print $8}')
[ -z "$PAGE_SIZE" ] && PAGE_SIZE=16384
PAGES_FREE=$(echo "$VM_STAT" | awk '/Pages free/{gsub(/\./,"",$3); print $3}')
PAGES_ACTIVE=$(echo "$VM_STAT" | awk '/Pages active/{gsub(/\./,"",$3); print $3}')
PAGES_INACTIVE=$(echo "$VM_STAT" | awk '/Pages inactive/{gsub(/\./,"",$3); print $3}')
PAGES_WIRED=$(echo "$VM_STAT" | awk '/Pages wired/{gsub(/\./,"",$4); print $4}')
PAGES_COMPRESSED=$(echo "$VM_STAT" | awk '/Pages occupied by compressor/{gsub(/\./,"",$5); print $5}')
[ -z "$PAGES_FREE" ] && PAGES_FREE=0
[ -z "$PAGES_ACTIVE" ] && PAGES_ACTIVE=0
[ -z "$PAGES_INACTIVE" ] && PAGES_INACTIVE=0
[ -z "$PAGES_WIRED" ] && PAGES_WIRED=0
[ -z "$PAGES_COMPRESSED" ] && PAGES_COMPRESSED=0

ram_mb() { echo "$1 $PAGE_SIZE" | awk '{printf "%.0f", ($1*$2)/1048576}'; }
RAM_FREE_MB=$(ram_mb "$PAGES_FREE")
RAM_ACTIVE_MB=$(ram_mb "$PAGES_ACTIVE")
RAM_INACTIVE_MB=$(ram_mb "$PAGES_INACTIVE")
RAM_WIRED_MB=$(ram_mb "$PAGES_WIRED")
RAM_COMPRESSED_MB=$(ram_mb "$PAGES_COMPRESSED")
RAM_USED_MB=$(( RAM_TOTAL_GB * 1024 - RAM_FREE_MB ))
RAM_USED_PCT=$(echo "$RAM_USED_MB $RAM_TOTAL_GB" | awk '{printf "%.0f", ($1/($2*1024))*100}')

# --- Batteria ---
BATTERY_INFO=$(system_profiler SPPowerDataType 2>/dev/null)
BATTERY_CYCLE=$(echo "$BATTERY_INFO" | awk -F': ' '/Cycle Count/{print $2}' | xargs)
BATTERY_CONDITION=$(echo "$BATTERY_INFO" | awk -F': ' '/Condition/{print $2}' | xargs)
BATTERY_CAPACITY=$(echo "$BATTERY_INFO" | awk -F': ' '/Maximum Capacity/{print $2}' | xargs)
BATTERY_CHARGE=$(echo "$BATTERY_INFO" | awk -F': ' '/State of Charge/{print $2}' | xargs)
BATTERY_CHARGING=$(echo "$BATTERY_INFO" | grep -i "Charging" | head -1 | awk -F': ' '{print $2}' | xargs)
[ -z "$BATTERY_CHARGE" ] && BATTERY_CHARGE=$(pmset -g batt 2>/dev/null | grep -o '[0-9]*%' | head -1 | tr -d '%')
[ -z "$BATTERY_CHARGE" ] && BATTERY_CHARGE="N/A"
[ -z "$BATTERY_CYCLE" ] && BATTERY_CYCLE="N/A"
[ -z "$BATTERY_CONDITION" ] && BATTERY_CONDITION="N/A"
[ -z "$BATTERY_CAPACITY" ] && BATTERY_CAPACITY="N/A"

# --- Aggiornamenti macOS ---
UPDATES_RAW=$(softwareupdate -l 2>/dev/null)
UPDATES_COUNT=$(echo "$UPDATES_RAW" | grep -c "^\*" 2>/dev/null || echo "0")
[ "$UPDATES_COUNT" -lt 0 ] 2>/dev/null && UPDATES_COUNT=0

# --- Sicurezza ---
FILEVAULT=$(fdesetup status 2>/dev/null | head -1)
FIREWALL=$(defaults read /Library/Preferences/com.apple.alf globalstate 2>/dev/null)
case "$FIREWALL" in
  0) FIREWALL_STATUS="Disattivato" ;;
  1) FIREWALL_STATUS="Attivato" ;;
  2) FIREWALL_STATUS="Blocca tutto" ;;
  *) FIREWALL_STATUS=$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null | head -1) ;;
esac
GATEKEEPER=$(spctl --status 2>/dev/null | head -1)
SIP=$(csrutil status 2>/dev/null | head -1)

# --- App installate ---
APP_LIST=$(du -sh /Applications/*.app ~/Applications/*.app 2>/dev/null | sort -rh | head -30)
APP_STORE=$(mdfind "kMDItemAppStoreHasReceipt == 1" 2>/dev/null | grep "\.app$" | xargs -I{} basename {} .app | sort)
APP_STORE_COUNT=$(echo "$APP_STORE" | grep -c . 2>/dev/null || echo "0")

# --- Homebrew ---
if command -v brew &>/dev/null; then
  BREW_INSTALLED=true
  BREW_CASKS=$(brew list --cask 2>/dev/null | tr '\n' ' ')
  BREW_FORMULAS=$(brew list --formula 2>/dev/null | tr '\n' ' ')
  BREW_CASK_COUNT=$(brew list --cask 2>/dev/null | wc -l | xargs)
  BREW_FORMULA_COUNT=$(brew list --formula 2>/dev/null | wc -l | xargs)
  BREW_OUTDATED=$(brew outdated 2>/dev/null)
  BREW_OUTDATED_COUNT=$(echo "$BREW_OUTDATED" | grep -c . 2>/dev/null || echo "0")
  [ -z "$(echo $BREW_OUTDATED | xargs)" ] && BREW_OUTDATED_COUNT=0
else
  BREW_INSTALLED=false
  BREW_CASK_COUNT=0
  BREW_FORMULA_COUNT=0
  BREW_OUTDATED_COUNT=0
  BREW_CASKS="Homebrew non installato"
  BREW_FORMULAS=""
  BREW_OUTDATED=""
fi

# --- Modelli AI ---
OLLAMA_SIZE=$(du -sh ~/.ollama 2>/dev/null | awk '{print $1}')
[ -z "$OLLAMA_SIZE" ] && OLLAMA_SIZE="Non trovato"
OLLAMA_MODELS=$(ollama list 2>/dev/null | tail -n +2)
[ -z "$OLLAMA_MODELS" ] && OLLAMA_MODELS="Ollama non attivo o non installato"
LMS_SIZE=$(du -sh ~/.cache/lm-studio 2>/dev/null | awk '{print $1}')
[ -z "$LMS_SIZE" ] && LMS_SIZE="Non trovato"

# --- Docker ---
if command -v docker &>/dev/null; then
  DOCKER_INSTALLED=true
  DOCKER_DF=$(docker system df 2>/dev/null || echo "Docker non in esecuzione")
  DOCKER_IMAGES=$(docker images 2>/dev/null | tail -n +2 | wc -l | xargs)
  DOCKER_CONTAINERS=$(docker ps -a 2>/dev/null | tail -n +2 | wc -l | xargs)
  DOCKER_RUNNING=$(docker ps 2>/dev/null | tail -n +2 | wc -l | xargs)
else
  DOCKER_INSTALLED=false
  DOCKER_IMAGES=0
  DOCKER_CONTAINERS=0
  DOCKER_RUNNING=0
  DOCKER_DF="Docker non installato"
fi

# --- Cache ---
CACHE_USER=$(du -sh ~/Library/Caches 2>/dev/null | awk '{print $1}')
CACHE_SYSTEM=$(du -sh /Library/Caches 2>/dev/null | awk '{print $1}')
LOGS_SIZE=$(du -sh ~/Library/Logs 2>/dev/null | awk '{print $1}')
TMP_SIZE=$(du -sh /tmp 2>/dev/null | awk '{print $1}')
[ -z "$CACHE_USER" ] && CACHE_USER="N/A"
[ -z "$CACHE_SYSTEM" ] && CACHE_SYSTEM="N/A"
[ -z "$LOGS_SIZE" ] && LOGS_SIZE="N/A"
[ -z "$TMP_SIZE" ] && TMP_SIZE="N/A"

# --- Top cartelle home ---
TOP_FOLDERS=$(du -sh ~/* 2>/dev/null | sort -rh | head -12)
DESKTOP_SIZE=$(du -sh ~/Desktop 2>/dev/null | awk '{print $1}')
DOWNLOADS_SIZE=$(du -sh ~/Downloads 2>/dev/null | awk '{print $1}')
DOCUMENTS_SIZE=$(du -sh ~/Documents 2>/dev/null | awk '{print $1}')
[ -z "$DESKTOP_SIZE" ] && DESKTOP_SIZE="N/A"
[ -z "$DOWNLOADS_SIZE" ] && DOWNLOADS_SIZE="N/A"
[ -z "$DOCUMENTS_SIZE" ] && DOCUMENTS_SIZE="N/A"

# --- Processi top CPU ---
TOP_CPU=$(ps aux 2>/dev/null | sort -rk3 | head -11 | tail -10 | awk '{printf "%s|%.1f|%.1f\n", $11, $3, $4}')
# --- Processi top RAM ---
TOP_MEM=$(ps aux 2>/dev/null | sort -rk4 | head -11 | tail -10 | awk '{printf "%s|%.1f|%.1f\n", $11, $4, $3}')

# --- Rete ---
WIFI_SSID=$(/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I 2>/dev/null | awk -F': ' '/ SSID/{print $2}' | xargs)
[ -z "$WIFI_SSID" ] && WIFI_SSID=$(networksetup -getairportnetwork en0 2>/dev/null | awk -F': ' '{print $2}' | xargs)
[ -z "$WIFI_SSID" ] && WIFI_SSID="Non disponibile"
IP_LOCAL=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null)
[ -z "$IP_LOCAL" ] && IP_LOCAL="Non disponibile"

# --- Login Items / LaunchAgents ---
LAUNCH_AGENTS_USER=$(ls ~/Library/LaunchAgents/ 2>/dev/null | wc -l | xargs)
LAUNCH_AGENTS_SYS=$(ls /Library/LaunchAgents/ 2>/dev/null | wc -l | xargs)
LAUNCH_DAEMONS=$(ls /Library/LaunchDaemons/ 2>/dev/null | wc -l | xargs)

# ============================================================
#  GENERAZIONE HTML
# ============================================================

# Helper per HTML-escape
esc() { echo "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'; }

# Determina colore batteria
BAT_COLOR="#4ade80"
if [ "$BATTERY_CONDITION" = "Poor" ] || [ "$BATTERY_CONDITION" = "Replace Soon" ] || [ "$BATTERY_CONDITION" = "Service Battery" ]; then
  BAT_COLOR="#f87171"
elif [ "$BATTERY_CONDITION" = "Fair" ] || [ "$BATTERY_CONDITION" = "Replace Now" ]; then
  BAT_COLOR="#fbbf24"
fi

# Determina colore disco
DISK_COLOR="#4ade80"
[ "$DISK_PCT_NUM" -gt 80 ] && DISK_COLOR="#fbbf24"
[ "$DISK_PCT_NUM" -gt 90 ] && DISK_COLOR="#f87171"

# Determina colore RAM
RAM_COLOR="#4ade80"
[ "$RAM_USED_PCT" -gt 80 ] && RAM_COLOR="#fbbf24"
[ "$RAM_USED_PCT" -gt 90 ] && RAM_COLOR="#f87171"

# Genera righe tabella app
APP_TABLE_ROWS=""
while IFS= read -r line; do
  [ -z "$line" ] && continue
  SIZE=$(echo "$line" | awk '{print $1}')
  PATH_RAW=$(echo "$line" | awk '{$1=""; print $0}' | xargs)
  NAME=$(basename "$PATH_RAW" .app)
  APP_TABLE_ROWS="${APP_TABLE_ROWS}<tr><td>$(esc "$NAME")</td><td class='size-cell'>$SIZE</td></tr>"
done <<< "$APP_LIST"

# Genera righe top CPU
CPU_TABLE_ROWS=""
while IFS= read -r line; do
  [ -z "$line" ] && continue
  PROC=$(echo "$line" | cut -d'|' -f1 | xargs | sed 's|.*/||')
  CPU_V=$(echo "$line" | cut -d'|' -f2)
  MEM_V=$(echo "$line" | cut -d'|' -f3)
  CPU_W=$(echo "$CPU_V" | awk '{v=$1*2; if(v>100)v=100; print v}')
  CPU_TABLE_ROWS="${CPU_TABLE_ROWS}<tr><td>$(esc "$PROC")</td><td><div class='bar-wrap'><div class='bar cpu-bar' style='width:${CPU_W}%'></div></div></td><td class='pct-cell'>${CPU_V}%</td><td class='pct-cell'>${MEM_V}%</td></tr>"
done <<< "$TOP_CPU"

# Genera righe top MEM
MEM_TABLE_ROWS=""
while IFS= read -r line; do
  [ -z "$line" ] && continue
  PROC=$(echo "$line" | cut -d'|' -f1 | xargs | sed 's|.*/||')
  MEM_V=$(echo "$line" | cut -d'|' -f2)
  CPU_V=$(echo "$line" | cut -d'|' -f3)
  MEM_W=$(echo "$MEM_V" | awk '{v=$1*5; if(v>100)v=100; print v}')
  MEM_TABLE_ROWS="${MEM_TABLE_ROWS}<tr><td>$(esc "$PROC")</td><td><div class='bar-wrap'><div class='bar mem-bar' style='width:${MEM_W}%'></div></div></td><td class='pct-cell'>${MEM_V}%</td><td class='pct-cell'>${CPU_V}%</td></tr>"
done <<< "$TOP_MEM"

# App Store list
APP_STORE_HTML=""
while IFS= read -r app; do
  [ -z "$app" ] && continue
  APP_STORE_HTML="${APP_STORE_HTML}<span class='tag'>$(esc "$app")</span>"
done <<< "$APP_STORE"
[ -z "$APP_STORE_HTML" ] && APP_STORE_HTML="<span class='muted'>Nessuna app trovata</span>"

# Homebrew tags
BREW_CASK_HTML=""
for c in $BREW_CASKS; do
  BREW_CASK_HTML="${BREW_CASK_HTML}<span class='tag tag-brew'>$(esc "$c")</span>"
done
[ -z "$BREW_CASK_HTML" ] && BREW_CASK_HTML="<span class='muted'>Nessun cask</span>"

BREW_FORMULA_HTML=""
for f in $BREW_FORMULAS; do
  BREW_FORMULA_HTML="${BREW_FORMULA_HTML}<span class='tag tag-formula'>$(esc "$f")</span>"
done
[ -z "$BREW_FORMULA_HTML" ] && BREW_FORMULA_HTML="<span class='muted'>Nessuna formula</span>"

# Top folders rows
FOLDER_ROWS=""
while IFS= read -r line; do
  [ -z "$line" ] && continue
  SIZE=$(echo "$line" | awk '{print $1}')
  FPATH=$(echo "$line" | awk '{$1=""; print $0}' | xargs)
  NAME=$(basename "$FPATH")
  FOLDER_ROWS="${FOLDER_ROWS}<tr><td>$(esc "$NAME")</td><td class='size-cell'>$SIZE</td></tr>"
done <<< "$TOP_FOLDERS"

# Security badge helper
sec_badge() {
  local text="$1"
  local ok_pattern="$2"
  local warn_pattern="$3"
  if echo "$text" | grep -qi "$ok_pattern"; then
    echo "<span class='badge badge-ok'>$(esc "$text")</span>"
  elif [ -n "$warn_pattern" ] && echo "$text" | grep -qi "$warn_pattern"; then
    echo "<span class='badge badge-warn'>$(esc "$text")</span>"
  else
    echo "<span class='badge badge-err'>$(esc "$text")</span>"
  fi
}

FILEVAULT_BADGE=$(sec_badge "$FILEVAULT" "On" "Off")
FIREWALL_BADGE=$(sec_badge "$FIREWALL_STATUS" "Attivato\|Blocca" "")
GATEKEEPER_BADGE=$(sec_badge "$GATEKEEPER" "enabled\|assessments enabled" "")
SIP_BADGE=$(sec_badge "$SIP" "enabled" "")

# Updates badge
if [ "$UPDATES_COUNT" -gt 0 ]; then
  UPDATES_BADGE="<span class='badge badge-warn'>${UPDATES_COUNT} aggiornamenti disponibili</span>"
else
  UPDATES_BADGE="<span class='badge badge-ok'>Sistema aggiornato</span>"
fi

# ============================================================
cat > "$OUTPUT_HTML" << HTMLEOF
<!DOCTYPE html>
<html lang="it">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Mac Report — ${HOSTNAME}</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Space+Mono:wght@400;700&family=Syne:wght@400;600;700;800&display=swap" rel="stylesheet">
<style>
  :root {
    --bg: #0a0a0f;
    --bg2: #111118;
    --bg3: #18181f;
    --border: #2a2a35;
    --accent: #7c6dfa;
    --accent2: #4fc4cf;
    --accent3: #f9a94c;
    --text: #e8e8f0;
    --text2: #9090a8;
    --green: #4ade80;
    --yellow: #fbbf24;
    --red: #f87171;
    --card-r: 14px;
    --mono: 'Space Mono', monospace;
    --sans: 'Syne', sans-serif;
  }

  * { box-sizing: border-box; margin: 0; padding: 0; }

  body {
    background: var(--bg);
    color: var(--text);
    font-family: var(--sans);
    font-size: 15px;
    line-height: 1.6;
    min-height: 100vh;
  }

  /* HEADER */
  .header {
    background: linear-gradient(135deg, #0d0d15 0%, #12121e 50%, #0a0f1a 100%);
    border-bottom: 1px solid var(--border);
    padding: 40px 40px 32px;
    position: relative;
    overflow: hidden;
  }
  .header::before {
    content: '';
    position: absolute; top: -60px; right: -60px;
    width: 300px; height: 300px;
    background: radial-gradient(circle, rgba(124,109,250,0.12) 0%, transparent 70%);
    border-radius: 50%;
  }
  .header::after {
    content: '';
    position: absolute; bottom: -40px; left: 20%;
    width: 200px; height: 200px;
    background: radial-gradient(circle, rgba(79,196,207,0.08) 0%, transparent 70%);
    border-radius: 50%;
  }
  .header-inner { max-width: 1200px; margin: 0 auto; position: relative; z-index:1; }
  .header-top { display: flex; justify-content: space-between; align-items: flex-start; flex-wrap: wrap; gap: 16px; }
  .mac-name {
    font-size: 13px; font-weight: 700; letter-spacing: 0.12em;
    text-transform: uppercase; color: var(--accent); margin-bottom: 6px;
    font-family: var(--mono);
  }
  .header h1 {
    font-size: 32px; font-weight: 800; letter-spacing: -0.02em;
    color: var(--text); line-height: 1.1;
  }
  .header h1 span { color: var(--accent); }
  .report-meta {
    font-family: var(--mono); font-size: 12px; color: var(--text2);
    margin-top: 10px; display: flex; gap: 24px; flex-wrap: wrap;
  }
  .report-meta b { color: var(--accent2); }
  .chip-badge {
    display: inline-flex; align-items: center; gap: 8px;
    background: var(--bg3); border: 1px solid var(--border);
    border-radius: 100px; padding: 8px 18px;
    font-family: var(--mono); font-size: 12px; color: var(--text);
    white-space: nowrap;
  }
  .chip-badge::before { content: '⬡'; color: var(--accent); font-size: 14px; }

  /* LAYOUT */
  .main { max-width: 1200px; margin: 0 auto; padding: 32px 40px 60px; }

  /* SECTION HEADER */
  .section-title {
    font-size: 11px; font-weight: 700; letter-spacing: 0.14em;
    text-transform: uppercase; color: var(--accent2);
    font-family: var(--mono); margin: 40px 0 16px;
    display: flex; align-items: center; gap: 12px;
  }
  .section-title::after {
    content: ''; flex: 1; height: 1px; background: var(--border);
  }

  /* CARDS */
  .cards-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(240px, 1fr)); gap: 16px; }
  .cards-grid-3 { display: grid; grid-template-columns: repeat(auto-fill, minmax(340px, 1fr)); gap: 16px; }
  .card {
    background: var(--bg2); border: 1px solid var(--border);
    border-radius: var(--card-r); padding: 20px 22px;
    transition: border-color .2s;
  }
  .card:hover { border-color: #3a3a4a; }
  .card-label {
    font-size: 11px; font-weight: 700; letter-spacing: 0.1em;
    text-transform: uppercase; color: var(--text2);
    font-family: var(--mono); margin-bottom: 8px;
  }
  .card-value {
    font-size: 28px; font-weight: 800; color: var(--text);
    line-height: 1.1;
  }
  .card-sub { font-size: 12px; color: var(--text2); margin-top: 4px; font-family: var(--mono); }

  /* GAUGE — cerchio SVG */
  .gauge-card { display: flex; align-items: center; gap: 20px; }
  .gauge-wrap { position: relative; width: 80px; height: 80px; flex-shrink: 0; }
  .gauge-wrap svg { transform: rotate(-90deg); }
  .gauge-label {
    position: absolute; top: 50%; left: 50%; transform: translate(-50%,-50%);
    font-family: var(--mono); font-size: 14px; font-weight: 700; color: var(--text);
    text-align: center; white-space: nowrap;
  }
  .gauge-info { flex: 1; }
  .gauge-info .card-label { margin-bottom: 6px; }
  .gauge-info .card-value { font-size: 22px; }

  /* PROGRESS BAR */
  .progress-section { margin-top: 12px; }
  .progress-label { display: flex; justify-content: space-between; font-size: 12px; color: var(--text2); margin-bottom: 5px; font-family: var(--mono); }
  .progress-track { background: var(--bg3); border-radius: 100px; height: 7px; overflow: hidden; }
  .progress-fill { height: 100%; border-radius: 100px; transition: width .8s ease; }

  /* TABLE */
  .data-table { width: 100%; border-collapse: collapse; }
  .data-table th {
    text-align: left; font-size: 11px; font-weight: 700;
    letter-spacing: 0.1em; text-transform: uppercase;
    color: var(--text2); font-family: var(--mono);
    padding: 0 12px 10px; border-bottom: 1px solid var(--border);
  }
  .data-table td { padding: 10px 12px; border-bottom: 1px solid #1a1a22; font-size: 14px; }
  .data-table tr:last-child td { border-bottom: none; }
  .data-table tr:hover td { background: rgba(255,255,255,0.02); }
  .size-cell { font-family: var(--mono); color: var(--accent3); text-align: right; font-size: 13px; }
  .pct-cell { font-family: var(--mono); font-size: 13px; text-align: right; }

  /* BAR */
  .bar-wrap { background: var(--bg3); border-radius: 100px; height: 6px; min-width: 80px; }
  .bar { height: 100%; border-radius: 100px; }
  .cpu-bar { background: linear-gradient(90deg, var(--accent), #a78bfa); }
  .mem-bar { background: linear-gradient(90deg, var(--accent2), #22d3ee); }

  /* TAGS */
  .tags-wrap { display: flex; flex-wrap: wrap; gap: 8px; }
  .tag {
    background: var(--bg3); border: 1px solid var(--border);
    border-radius: 6px; padding: 4px 10px;
    font-size: 12px; font-family: var(--mono); color: var(--text);
  }
  .tag-brew { border-color: rgba(249,169,76,0.3); color: var(--accent3); }
  .tag-formula { border-color: rgba(79,196,207,0.3); color: var(--accent2); }

  /* BADGES */
  .badge {
    display: inline-block; padding: 4px 12px; border-radius: 6px;
    font-size: 12px; font-weight: 700; font-family: var(--mono);
    letter-spacing: 0.05em;
  }
  .badge-ok { background: rgba(74,222,128,0.12); color: var(--green); border: 1px solid rgba(74,222,128,0.25); }
  .badge-warn { background: rgba(251,191,36,0.12); color: var(--yellow); border: 1px solid rgba(251,191,36,0.25); }
  .badge-err { background: rgba(248,113,113,0.12); color: var(--red); border: 1px solid rgba(248,113,113,0.25); }

  /* SECURITY GRID */
  .security-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(260px, 1fr)); gap: 12px; }
  .security-item {
    background: var(--bg2); border: 1px solid var(--border);
    border-radius: var(--card-r); padding: 16px 18px;
    display: flex; justify-content: space-between; align-items: center; gap: 12px;
  }
  .security-item .label { font-size: 13px; color: var(--text2); }

  /* KPIS ROW */
  .kpi-row { display: grid; grid-template-columns: repeat(auto-fill, minmax(180px, 1fr)); gap: 12px; margin-bottom: 0; }
  .kpi { background: var(--bg2); border: 1px solid var(--border); border-radius: var(--card-r); padding: 16px 18px; }
  .kpi .kpi-label { font-size: 11px; font-weight: 700; letter-spacing: 0.1em; text-transform: uppercase; color: var(--text2); font-family: var(--mono); margin-bottom: 6px; }
  .kpi .kpi-val { font-size: 22px; font-weight: 800; }
  .kpi .kpi-sub { font-size: 11px; color: var(--text2); font-family: var(--mono); margin-top: 2px; }

  /* MUTED */
  .muted { color: var(--text2); font-style: italic; font-size: 13px; }
  
  /* MONOSPACE BLOCK */
  .mono-block {
    background: var(--bg3); border: 1px solid var(--border); border-radius: 8px;
    padding: 16px; font-family: var(--mono); font-size: 12px;
    color: var(--text2); white-space: pre-wrap; word-break: break-word;
    line-height: 1.7; max-height: 300px; overflow-y: auto;
  }

  /* FOOTER */
  .footer {
    border-top: 1px solid var(--border); padding: 24px 40px;
    font-family: var(--mono); font-size: 11px; color: var(--text2);
    text-align: center; letter-spacing: 0.08em;
  }

  @media (max-width: 700px) {
    .main { padding: 20px 16px 40px; }
    .header { padding: 24px 16px; }
    .header h1 { font-size: 24px; }
  }
</style>
</head>
<body>

<div class="header">
  <div class="header-inner">
    <div class="header-top">
      <div>
        <div class="mac-name">${HOSTNAME} · ${CURRENT_USER}</div>
        <h1>Mac <span>Report</span></h1>
        <div class="report-meta">
          <span><b>Data</b> ${REPORT_DATE}</span>
          <span><b>OS</b> ${MACOS_NAME} ${MACOS_VERSION} (${MACOS_BUILD})</span>
          <span><b>Arch</b> ${CPU_ARCH}</span>
        </div>
      </div>
      <div style="display:flex;flex-direction:column;gap:10px;align-items:flex-end;flex-wrap:wrap">
        <div class="chip-badge">${MAC_CHIP}</div>
        <div class="chip-badge" style="font-size:11px">${MAC_MEMORY} RAM · ${CPU_CORES} core logici</div>
        ${UPDATES_BADGE}
      </div>
    </div>
  </div>
</div>

<div class="main">

  <!-- ======= RISORSE DI SISTEMA ======= -->
  <div class="section-title">Risorse di sistema</div>
  <div class="cards-grid">

    <!-- DISCO -->
    <div class="card gauge-card">
      <div class="gauge-wrap">
        <svg width="80" height="80" viewBox="0 0 80 80">
          <circle cx="40" cy="40" r="32" fill="none" stroke="#2a2a35" stroke-width="8"/>
          <circle cx="40" cy="40" r="32" fill="none" stroke="${DISK_COLOR}" stroke-width="8"
            stroke-dasharray="$(echo "$DISK_PCT_NUM" | awk '{printf "%.1f", ($1/100)*201.06}'} 201.06"
            stroke-linecap="round"/>
        </svg>
        <div class="gauge-label">${DISK_PCT}%</div>
      </div>
      <div class="gauge-info">
        <div class="card-label">Disco</div>
        <div class="card-value" style="color:${DISK_COLOR}">${DISK_FREE}</div>
        <div class="card-sub">liberi di ${DISK_TOTAL}</div>
        <div class="card-sub">usati ${DISK_USED}</div>
      </div>
    </div>

    <!-- RAM -->
    <div class="card gauge-card">
      <div class="gauge-wrap">
        <svg width="80" height="80" viewBox="0 0 80 80">
          <circle cx="40" cy="40" r="32" fill="none" stroke="#2a2a35" stroke-width="8"/>
          <circle cx="40" cy="40" r="32" fill="none" stroke="${RAM_COLOR}" stroke-width="8"
            stroke-dasharray="$(echo "$RAM_USED_PCT" | awk '{printf "%.1f", ($1/100)*201.06}'} 201.06"
            stroke-linecap="round"/>
        </svg>
        <div class="gauge-label">${RAM_USED_PCT}%</div>
      </div>
      <div class="gauge-info">
        <div class="card-label">RAM</div>
        <div class="card-value" style="color:${RAM_COLOR}">${RAM_TOTAL_GB} GB</div>
        <div class="card-sub">usata ~${RAM_USED_MB} MB</div>
        <div class="progress-section">
          <div class="progress-label"><span>Wired</span><span>${RAM_WIRED_MB} MB</span></div>
          <div class="progress-track"><div class="progress-fill" style="width:$(echo "$RAM_WIRED_MB $RAM_TOTAL_GB" | awk '{printf "%.0f", ($1/($2*1024))*100}')%; background:#7c6dfa;"></div></div>
        </div>
        <div class="progress-section">
          <div class="progress-label"><span>Compressa</span><span>${RAM_COMPRESSED_MB} MB</span></div>
          <div class="progress-track"><div class="progress-fill" style="width:$(echo "$RAM_COMPRESSED_MB $RAM_TOTAL_GB" | awk '{printf "%.0f", ($1/($2*1024))*100}')%; background:#4fc4cf;"></div></div>
        </div>
      </div>
    </div>

    <!-- BATTERIA -->
    <div class="card">
      <div class="card-label">Batteria</div>
      <div style="display:flex;align-items:baseline;gap:10px;">
        <div class="card-value" style="color:${BAT_COLOR}">${BATTERY_CHARGE}%</div>
        <span class="badge $([ "$BATTERY_CONDITION" = "Normal" ] && echo "badge-ok" || echo "badge-warn")">${BATTERY_CONDITION}</span>
      </div>
      <div class="card-sub" style="margin-top:8px;">Cicli: <b style="color:var(--text)">${BATTERY_CYCLE}</b></div>
      <div class="card-sub">Capacità massima: <b style="color:var(--text)">${BATTERY_CAPACITY}</b></div>
      <div class="progress-section" style="margin-top:10px;">
        <div class="progress-track" style="height:9px;">
          <div class="progress-fill" style="width:$(echo "$BATTERY_CHARGE" | awk '{v=$1+0; if(v>100)v=100; if(v<0)v=0; print v}')%; background:${BAT_COLOR};"></div>
        </div>
      </div>
    </div>

    <!-- CPU INFO -->
    <div class="card">
      <div class="card-label">CPU</div>
      <div class="card-value">${CPU_CORES}</div>
      <div class="card-sub">core logici (${CPU_PHYSICAL} fisici)</div>
      <div class="card-sub" style="margin-top:8px;">$(esc "$MAC_IDENTIFIER")</div>
      <div class="card-sub">S/N: $(esc "$MAC_SERIAL")</div>
    </div>

  </div>

  <!-- ======= UPTIME & RETE ======= -->
  <div class="section-title">Uptime & Rete</div>
  <div class="kpi-row">
    <div class="kpi"><div class="kpi-label">Uptime</div><div class="kpi-val" style="font-size:15px;color:var(--accent2)">$(echo "$UPTIME_RAW" | awk -F'up' '{print $2}' | awk -F',' '{print $1}' | xargs)</div></div>
    <div class="kpi"><div class="kpi-label">IP Locale</div><div class="kpi-val" style="font-size:16px;color:var(--accent)">${IP_LOCAL}</div></div>
    <div class="kpi"><div class="kpi-label">Wi-Fi SSID</div><div class="kpi-val" style="font-size:16px;color:var(--accent3)">${WIFI_SSID}</div></div>
    <div class="kpi"><div class="kpi-label">Login Items</div><div class="kpi-val" style="color:var(--text2)">${LAUNCH_AGENTS_USER}</div><div class="kpi-sub">user agents</div></div>
    <div class="kpi"><div class="kpi-label">LaunchAgents</div><div class="kpi-val" style="color:var(--text2)">${LAUNCH_AGENTS_SYS}</div><div class="kpi-sub">di sistema</div></div>
    <div class="kpi"><div class="kpi-label">LaunchDaemons</div><div class="kpi-val" style="color:var(--text2)">${LAUNCH_DAEMONS}</div><div class="kpi-sub">di sistema</div></div>
  </div>

  <!-- ======= SICUREZZA ======= -->
  <div class="section-title">Sicurezza</div>
  <div class="security-grid">
    <div class="security-item"><span class="label">FileVault</span>${FILEVAULT_BADGE}</div>
    <div class="security-item"><span class="label">Firewall</span>${FIREWALL_BADGE}</div>
    <div class="security-item"><span class="label">Gatekeeper</span>${GATEKEEPER_BADGE}</div>
    <div class="security-item"><span class="label">SIP</span>${SIP_BADGE}</div>
    <div class="security-item"><span class="label">Aggiornamenti</span>${UPDATES_BADGE}</div>
  </div>

  <!-- ======= SPAZIO & CACHE ======= -->
  <div class="section-title">Spazio & Cache</div>
  <div class="cards-grid">
    <div class="card"><div class="card-label">Cache Utente</div><div class="card-value" style="font-size:26px;color:var(--accent3)">${CACHE_USER}</div><div class="card-sub">~/Library/Caches</div></div>
    <div class="card"><div class="card-label">Cache Sistema</div><div class="card-value" style="font-size:26px;color:var(--accent3)">${CACHE_SYSTEM}</div><div class="card-sub">/Library/Caches</div></div>
    <div class="card"><div class="card-label">Log Utente</div><div class="card-value" style="font-size:26px;color:var(--text2)">${LOGS_SIZE}</div><div class="card-sub">~/Library/Logs</div></div>
    <div class="card"><div class="card-label">File Temporanei</div><div class="card-value" style="font-size:26px;color:var(--text2)">${TMP_SIZE}</div><div class="card-sub">/tmp</div></div>
    <div class="card"><div class="card-label">Desktop</div><div class="card-value" style="font-size:26px;color:var(--text)">${DESKTOP_SIZE}</div></div>
    <div class="card"><div class="card-label">Downloads</div><div class="card-value" style="font-size:26px;color:var(--text)">${DOWNLOADS_SIZE}</div></div>
    <div class="card"><div class="card-label">Documents</div><div class="card-value" style="font-size:26px;color:var(--text)">${DOCUMENTS_SIZE}</div></div>
  </div>

  <!-- ======= TOP CARTELLE ======= -->
  <div class="section-title">Cartelle più pesanti in Home</div>
  <div class="card" style="padding:0;overflow:hidden;">
    <table class="data-table">
      <thead><tr><th>Cartella</th><th style="text-align:right">Dimensione</th></tr></thead>
      <tbody>${FOLDER_ROWS}</tbody>
    </table>
  </div>

  <!-- ======= PROCESSI ======= -->
  <div class="section-title">Processi attivi</div>
  <div class="cards-grid-3">
    <div class="card" style="padding:0;overflow:hidden;">
      <div style="padding:16px 16px 10px;font-size:11px;font-weight:700;letter-spacing:.1em;text-transform:uppercase;color:var(--text2);font-family:var(--mono);">Top CPU</div>
      <table class="data-table">
        <thead><tr><th>Processo</th><th>CPU</th><th style="text-align:right">%CPU</th><th style="text-align:right">%MEM</th></tr></thead>
        <tbody>${CPU_TABLE_ROWS}</tbody>
      </table>
    </div>
    <div class="card" style="padding:0;overflow:hidden;">
      <div style="padding:16px 16px 10px;font-size:11px;font-weight:700;letter-spacing:.1em;text-transform:uppercase;color:var(--text2);font-family:var(--mono);">Top RAM</div>
      <table class="data-table">
        <thead><tr><th>Processo</th><th>RAM</th><th style="text-align:right">%MEM</th><th style="text-align:right">%CPU</th></tr></thead>
        <tbody>${MEM_TABLE_ROWS}</tbody>
      </table>
    </div>
  </div>

  <!-- ======= APP ======= -->
  <div class="section-title">Applicazioni installate</div>
  <div class="cards-grid-3">
    <div class="card" style="padding:0;overflow:hidden;">
      <div style="padding:16px 16px 10px;font-size:11px;font-weight:700;letter-spacing:.1em;text-transform:uppercase;color:var(--text2);font-family:var(--mono);">Top per dimensione</div>
      <table class="data-table">
        <thead><tr><th>App</th><th style="text-align:right">Dim.</th></tr></thead>
        <tbody>${APP_TABLE_ROWS}</tbody>
      </table>
    </div>
    <div class="card">
      <div class="card-label" style="margin-bottom:14px;">Mac App Store (${APP_STORE_COUNT})</div>
      <div class="tags-wrap">${APP_STORE_HTML}</div>
    </div>
  </div>

  <!-- ======= HOMEBREW ======= -->
  <div class="section-title">Homebrew</div>
  $(if $BREW_INSTALLED; then echo "
  <div class=\"kpi-row\" style=\"margin-bottom:16px;\">
    <div class=\"kpi\"><div class=\"kpi-label\">Cask</div><div class=\"kpi-val\" style=\"color:var(--accent3)\">${BREW_CASK_COUNT}</div><div class=\"kpi-sub\">app grafiche</div></div>
    <div class=\"kpi\"><div class=\"kpi-label\">Formula</div><div class=\"kpi-val\" style=\"color:var(--accent2)\">${BREW_FORMULA_COUNT}</div><div class=\"kpi-sub\">tool CLI</div></div>
    <div class=\"kpi\"><div class=\"kpi-label\">Da aggiornare</div><div class=\"kpi-val\" style=\"color:$([ "$BREW_OUTDATED_COUNT" -gt 0 ] && echo "var(--yellow)" || echo "var(--green)")\">${BREW_OUTDATED_COUNT}</div></div>
  </div>
  <div class=\"cards-grid-3\">
    <div class=\"card\"><div class=\"card-label\" style=\"margin-bottom:12px;\">Cask installati</div><div class=\"tags-wrap\">${BREW_CASK_HTML}</div></div>
    <div class=\"card\"><div class=\"card-label\" style=\"margin-bottom:12px;\">Formula installate</div><div class=\"tags-wrap\">${BREW_FORMULA_HTML}</div></div>
  </div>
  "; else echo "<div class=\"card\"><div class=\"card-label\">Homebrew</div><div class=\"muted\">Homebrew non installato su questo Mac.</div></div>"; fi)

  <!-- ======= AI MODELS ======= -->
  <div class="section-title">Modelli AI locali</div>
  <div class="cards-grid">
    <div class="card">
      <div class="card-label">Ollama</div>
      <div class="card-value" style="font-size:22px;color:var(--accent)">${OLLAMA_SIZE}</div>
      <div class="card-sub" style="margin-top:10px;">$(esc "$OLLAMA_MODELS" | sed 's/^/<span class="tag" style="display:inline-block;margin:2px 2px">/; s/$/<\/span>/' | head -10 | tr '\n' ' ')</div>
    </div>
    <div class="card">
      <div class="card-label">LM Studio</div>
      <div class="card-value" style="font-size:22px;color:var(--accent2)">${LMS_SIZE}</div>
      <div class="card-sub">~/.cache/lm-studio</div>
    </div>
  </div>

  <!-- ======= DOCKER ======= -->
  <div class="section-title">Docker</div>
  $(if $DOCKER_INSTALLED; then echo "
  <div class=\"kpi-row\" style=\"margin-bottom:16px;\">
    <div class=\"kpi\"><div class=\"kpi-label\">Immagini</div><div class=\"kpi-val\" style=\"color:var(--accent3)\">${DOCKER_IMAGES}</div></div>
    <div class=\"kpi\"><div class=\"kpi-label\">Container totali</div><div class=\"kpi-val\">${DOCKER_CONTAINERS}</div></div>
    <div class=\"kpi\"><div class=\"kpi-label\">In esecuzione</div><div class=\"kpi-val\" style=\"color:var(--green)\">${DOCKER_RUNNING}</div></div>
  </div>
  <div class=\"card\"><div class=\"card-label\" style=\"margin-bottom:10px;\">Docker system df</div><div class=\"mono-block\">$(esc "$DOCKER_DF")</div></div>
  "; else echo "<div class=\"card\"><div class=\"card-label\">Docker</div><div class=\"muted\">Docker non installato su questo Mac.</div></div>"; fi)

</div><!-- /main -->

<div class="footer">
  MAC MAINTENANCE REPORT · Generato il ${REPORT_DATE} · ${HOSTNAME}
</div>

</body>
</html>
HTMLEOF

echo ""
echo "✅ Report HTML completato!"
echo "📄 Apri nel browser: $OUTPUT_HTML"
open "$OUTPUT_HTML" 2>/dev/null || echo "   (apri manualmente il file)"
