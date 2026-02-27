#!/bin/bash
# ============================================================
#  MAC MAINTENANCE REPORT — HTML Edition v3
#  Universale, anonimo, focalizzato su HW e software
# ============================================================

export LC_ALL=C
export LANG=C

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_HTML="$HOME/Desktop/mac_report_${TIMESTAMP}.html"

# ============================================================
#  RACCOLTA DATI
# ============================================================

# --- Sistema ---
MAC_MODEL=$(system_profiler SPHardwareDataType 2>/dev/null | awk -F': ' '/Model Name/{print $2}' | xargs)
MAC_CHIP=$(system_profiler SPHardwareDataType 2>/dev/null | awk -F': ' '/Chip/{print $2}' | xargs)
[ -z "$MAC_CHIP" ] && MAC_CHIP=$(system_profiler SPHardwareDataType 2>/dev/null | awk -F': ' '/Processor Name/{print $2}' | xargs)
MAC_MEMORY=$(system_profiler SPHardwareDataType 2>/dev/null | awk -F': ' '/  Memory:/{print $2}' | xargs)
MACOS_VERSION=$(sw_vers -productVersion 2>/dev/null)
MACOS_BUILD=$(sw_vers -buildVersion 2>/dev/null)
MACOS_NAME=$(sw_vers -productName 2>/dev/null)
REPORT_DATE=$(date '+%d/%m/%Y alle %H:%M:%S')
CPU_ARCH=$(uname -m 2>/dev/null)
CPU_CORES=$(sysctl -n hw.logicalcpu 2>/dev/null)
CPU_PHYSICAL=$(sysctl -n hw.physicalcpu 2>/dev/null)
[ "$CPU_ARCH" = "arm64" ] && ARCH_LABEL="Apple Silicon" || ARCH_LABEL="Intel"

# --- Disco ---
DISK_TOTAL=$(df -h / 2>/dev/null | awk 'NR==2{print $2}')
DISK_USED=$(df -h / 2>/dev/null | awk 'NR==2{print $3}')
DISK_FREE=$(df -h / 2>/dev/null | awk 'NR==2{print $4}')
DISK_PCT=$(df / 2>/dev/null | awk 'NR==2{gsub(/%/,"",$5); print $5}')
DISK_PCT=${DISK_PCT:-0}
DISK_DASH=$(awk "BEGIN{printf \"%.1f\", ($DISK_PCT/100)*201.06}")
DISK_COLOR="#4ade80"
[ "$DISK_PCT" -gt 75 ] 2>/dev/null && DISK_COLOR="#fbbf24"
[ "$DISK_PCT" -gt 90 ] 2>/dev/null && DISK_COLOR="#f87171"

# Volumi aggiuntivi montati
VOLUMES_ROWS=""
while IFS= read -r line; do
  [ -z "$line" ] && continue
  VOL_NAME=$(echo "$line" | awk '{$1=$2=$3=$4=$5=$6=""; print $0}' | xargs)
  VOL_SIZE=$(echo "$line" | awk '{print $2}')
  VOL_USED=$(echo "$line" | awk '{print $3}')
  VOL_FREE=$(echo "$line" | awk '{print $4}')
  VOL_PCT=$(echo "$line"  | awk '{print $5}')
  VOLUMES_ROWS="${VOLUMES_ROWS}<tr><td>${VOL_NAME}</td><td class='num'>${VOL_SIZE}</td><td class='num'>${VOL_USED}</td><td class='num'>${VOL_FREE}</td><td class='num'>${VOL_PCT}</td></tr>"
done < <(df -h 2>/dev/null | awk 'NR>1 && $1 ~ /^\/dev\// {print}')

# --- RAM ---
RAM_TOTAL_BYTES=$(sysctl -n hw.memsize 2>/dev/null)
RAM_TOTAL_GB=$(echo "$RAM_TOTAL_BYTES" | awk '{printf "%.0f", $1/1073741824}')
VM_STAT=$(vm_stat 2>/dev/null)
PAGE_SIZE=$(echo "$VM_STAT" | awk '/page size/{print $8}')
[ -z "$PAGE_SIZE" ] && PAGE_SIZE=16384
PAGES_FREE=$(echo "$VM_STAT"  | awk '/Pages free/{gsub(/\./,"",$3); print $3+0}')
PAGES_WIRED=$(echo "$VM_STAT" | awk '/Pages wired/{gsub(/\./,"",$4); print $4+0}')
PAGES_COMP=$(echo "$VM_STAT"  | awk '/Pages occupied by compressor/{gsub(/\./,"",$5); print $5+0}')
ram_mb() { awk "BEGIN{printf \"%.0f\", ($1*$PAGE_SIZE)/1048576}"; }
RAM_FREE_MB=$(ram_mb $PAGES_FREE)
RAM_WIRED_MB=$(ram_mb $PAGES_WIRED)
RAM_COMPRESSED_MB=$(ram_mb $PAGES_COMP)
RAM_TOTAL_MB=$(( RAM_TOTAL_GB * 1024 ))
RAM_USED_MB=$(( RAM_TOTAL_MB - RAM_FREE_MB ))
[ $RAM_USED_MB -lt 0 ] && RAM_USED_MB=0
RAM_USED_PCT=$(awk "BEGIN{printf \"%.0f\", ($RAM_USED_MB/$RAM_TOTAL_MB)*100}")
RAM_DASH=$(awk "BEGIN{printf \"%.1f\", ($RAM_USED_PCT/100)*201.06}")
RAM_WIRED_PCT=$(awk "BEGIN{printf \"%.0f\", ($RAM_WIRED_MB/$RAM_TOTAL_MB)*100}")
RAM_COMP_PCT=$(awk "BEGIN{printf \"%.0f\", ($RAM_COMPRESSED_MB/$RAM_TOTAL_MB)*100}")
RAM_COLOR="#4ade80"
[ "$RAM_USED_PCT" -gt 75 ] 2>/dev/null && RAM_COLOR="#fbbf24"
[ "$RAM_USED_PCT" -gt 90 ] 2>/dev/null && RAM_COLOR="#f87171"

# --- Batteria (solo se presente) ---
BATTERY_INFO=$(system_profiler SPPowerDataType 2>/dev/null)
BATTERY_CYCLE=$(echo "$BATTERY_INFO"    | awk -F': ' '/Cycle Count/{print $2}' | xargs)
BATTERY_CONDITION=$(echo "$BATTERY_INFO"| awk -F': ' '/Condition/{print $2}' | xargs)
BATTERY_CAPACITY=$(echo "$BATTERY_INFO" | awk -F': ' '/Maximum Capacity/{print $2}' | xargs)
BATTERY_CHARGE=$(echo "$BATTERY_INFO"   | awk -F': ' '/State of Charge/{print $2}' | xargs)
[ -z "$BATTERY_CHARGE" ] && BATTERY_CHARGE=$(pmset -g batt 2>/dev/null | grep -o '[0-9]*%' | head -1 | tr -d '%')
BATTERY_PRESENT=false
[ -n "$BATTERY_CYCLE" ] && BATTERY_PRESENT=true
BATTERY_CHARGE_NUM=${BATTERY_CHARGE:-0}
BATTERY_CHARGE_NUM=$(echo "$BATTERY_CHARGE_NUM" | tr -d '%' | awk '{print $1+0}')
[ -z "$BATTERY_CYCLE" ]     && BATTERY_CYCLE="N/A"
[ -z "$BATTERY_CONDITION" ] && BATTERY_CONDITION="N/A"
[ -z "$BATTERY_CAPACITY" ]  && BATTERY_CAPACITY="N/A"
BAT_COLOR="#4ade80"
case "$BATTERY_CONDITION" in
  "Poor"|"Replace Soon"|"Service Battery") BAT_COLOR="#f87171" ;;
  "Fair"|"Replace Now") BAT_COLOR="#fbbf24" ;;
esac
BAT_COND_CLASS="badge-ok"
[ "$BATTERY_CONDITION" != "Normal" ] && [ "$BATTERY_CONDITION" != "N/A" ] && BAT_COND_CLASS="badge-warn"

# Sezione batteria HTML
if $BATTERY_PRESENT; then
  BATTERY_HTML="<div class='card'>
    <div class='card-label'>Batteria</div>
    <div style='display:flex;align-items:baseline;gap:10px;flex-wrap:wrap'>
      <div class='card-value' style='color:${BAT_COLOR}'>${BATTERY_CHARGE_NUM}%</div>
      <span class='badge ${BAT_COND_CLASS}'>${BATTERY_CONDITION}</span>
    </div>
    <div class='card-sub' style='margin-top:8px;'>Cicli: <b style='color:var(--text)'>${BATTERY_CYCLE}</b></div>
    <div class='card-sub'>Capacità massima: <b style='color:var(--text)'>${BATTERY_CAPACITY}</b></div>
    <div class='progress-section' style='margin-top:10px;'>
      <div class='progress-track' style='height:8px;'>
        <div class='progress-fill' style='width:${BATTERY_CHARGE_NUM}%;background:${BAT_COLOR}'></div>
      </div>
    </div>
  </div>"
else
  BATTERY_HTML="<div class='card'>
    <div class='card-label'>Alimentazione</div>
    <div class='card-value' style='font-size:18px;color:var(--text2)'>Desktop Mac</div>
    <div class='card-sub' style='margin-top:6px;'>Nessuna batteria rilevata</div>
  </div>"
fi

# --- GPU ---
GPU_NAME=$(system_profiler SPDisplaysDataType 2>/dev/null | awk -F': ' '/Chipset Model/{print $2}' | head -1 | xargs)
GPU_VRAM=$(system_profiler SPDisplaysDataType 2>/dev/null | awk -F': ' '/VRAM/{print $2}' | head -1 | xargs)
[ -z "$GPU_NAME" ] && GPU_NAME="N/A"
[ -z "$GPU_VRAM" ] && GPU_VRAM="N/A"
# Su Apple Silicon la VRAM è condivisa con la RAM
[ "$CPU_ARCH" = "arm64" ] && GPU_VRAM="Condivisa (Unified Memory)"

# --- Sicurezza ---
FILEVAULT=$(fdesetup status 2>/dev/null | head -1)
FIREWALL_RAW=$(defaults read /Library/Preferences/com.apple.alf globalstate 2>/dev/null)
case "$FIREWALL_RAW" in
  0) FIREWALL_STATUS="Disattivato" ; FW_CLASS="badge-err" ;;
  1) FIREWALL_STATUS="Attivato"    ; FW_CLASS="badge-ok"  ;;
  2) FIREWALL_STATUS="Blocca tutto"; FW_CLASS="badge-ok"  ;;
  *) FIREWALL_STATUS=$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null | head -1)
     FW_CLASS="badge-warn" ;;
esac
GATEKEEPER=$(spctl --status 2>/dev/null | head -1)
SIP=$(csrutil status 2>/dev/null | head -1)
echo "$FILEVAULT"  | grep -qi "On"      && FV_CLASS="badge-ok"  || FV_CLASS="badge-err"
echo "$GATEKEEPER" | grep -qi "enabled" && GK_CLASS="badge-ok"  || GK_CLASS="badge-err"
echo "$SIP"        | grep -qi "enabled" && SIP_CLASS="badge-ok" || SIP_CLASS="badge-err"

# --- Aggiornamenti ---
UPDATES_RAW=$(softwareupdate -l 2>/dev/null)
UPDATES_COUNT=$(echo "$UPDATES_RAW" | grep -c "^\*" 2>/dev/null || echo "0")
UPDATES_COUNT=${UPDATES_COUNT:-0}
if [ "$UPDATES_COUNT" -gt 0 ] 2>/dev/null; then
  UPD_CLASS="badge-warn"; UPD_TEXT="${UPDATES_COUNT} aggiornamenti disponibili"
else
  UPD_CLASS="badge-ok";   UPD_TEXT="Sistema aggiornato"
fi

# ============================================================
#  APP INSTALLATE — con tipo di installazione
# ============================================================

# Raccolta da tutte le sorgenti
declare -A APP_SOURCE  # nome app → sorgente

# 1. App Store
while IFS= read -r path; do
  [ -z "$path" ] && continue
  name=$(basename "$path" .app)
  APP_SOURCE["$name"]="App Store"
done < <(mdfind "kMDItemAppStoreHasReceipt == 1" 2>/dev/null | grep "\.app$")

# 2. Homebrew Cask
if command -v brew &>/dev/null; then
  BREW_INSTALLED=true
  while IFS= read -r cask; do
    [ -z "$cask" ] && continue
    # Trova il nome dell'app associata al cask
    app_path=$(brew info --cask "$cask" 2>/dev/null | grep "\.app" | head -1 | grep -o '/[^)]*\.app' | head -1)
    if [ -n "$app_path" ]; then
      name=$(basename "$app_path" .app)
    else
      name="$cask"
    fi
    APP_SOURCE["$name"]="Homebrew"
  done < <(brew list --cask 2>/dev/null)
  BREW_CASK_COUNT=$(brew list --cask 2>/dev/null | wc -l | xargs)
  BREW_FORMULA_COUNT=$(brew list --formula 2>/dev/null | wc -l | xargs)
  BREW_OUTDATED_COUNT=$(brew outdated 2>/dev/null | grep -c . 2>/dev/null || echo 0)
  [ -z "$(brew outdated 2>/dev/null | xargs)" ] && BREW_OUTDATED_COUNT=0
  BREW_OUT_COLOR="#4ade80"; [ "$BREW_OUTDATED_COUNT" -gt 0 ] 2>/dev/null && BREW_OUT_COLOR="#fbbf24"
else
  BREW_INSTALLED=false
  BREW_CASK_COUNT=0
  BREW_FORMULA_COUNT=0
  BREW_OUTDATED_COUNT=0
fi

# 3. Scansione /Applications — tutto ciò che non è già classificato → Manuale
APP_TABLE_ROWS=""
APP_TOTAL=0
APP_STORE_COUNT=0
APP_BREW_COUNT=0
APP_MANUAL_COUNT=0

while IFS= read -r line; do
  [ -z "$line" ] && continue
  SZ=$(echo "$line" | awk '{print $1}')
  APP_PATH=$(echo "$line" | awk '{$1=""; print $0}' | xargs)
  NAME=$(basename "$APP_PATH" .app)

  SOURCE="${APP_SOURCE[$NAME]}"
  [ -z "$SOURCE" ] && SOURCE="Manuale / Web"

  case "$SOURCE" in
    "App Store")      SRC_CLASS="src-store";  SRC_ICON="🛍️" ; APP_STORE_COUNT=$((APP_STORE_COUNT+1)) ;;
    "Homebrew")       SRC_CLASS="src-brew";   SRC_ICON="🍺" ; APP_BREW_COUNT=$((APP_BREW_COUNT+1)) ;;
    *)                SRC_CLASS="src-manual"; SRC_ICON="🌐" ; APP_MANUAL_COUNT=$((APP_MANUAL_COUNT+1)) ;;
  esac

  APP_TABLE_ROWS="${APP_TABLE_ROWS}<tr>
    <td>${NAME}</td>
    <td><span class='src-badge ${SRC_CLASS}'>${SRC_ICON} ${SOURCE}</span></td>
    <td class='num'>${SZ}</td>
  </tr>"
  APP_TOTAL=$((APP_TOTAL+1))
done < <(du -sh /Applications/*.app ~/Applications/*.app 2>/dev/null | sort -rh)

# --- Homebrew formula (tool CLI) ---
BREW_FORMULA_HTML=""
if $BREW_INSTALLED; then
  for f in $(brew list --formula 2>/dev/null); do
    BREW_FORMULA_HTML="${BREW_FORMULA_HTML}<span class='tag tag-formula'>${f}</span>"
  done
  [ -z "$BREW_FORMULA_HTML" ] && BREW_FORMULA_HTML="<span class='muted'>Nessuna formula installata</span>"

  BREW_OUTDATED_HTML=""
  while IFS= read -r pkg; do
    [ -z "$pkg" ] && continue
    BREW_OUTDATED_HTML="${BREW_OUTDATED_HTML}<span class='tag tag-outdated'>${pkg}</span>"
  done < <(brew outdated 2>/dev/null)
  [ -z "$BREW_OUTDATED_HTML" ] && BREW_OUTDATED_HTML="<span class='muted'>Tutto aggiornato ✓</span>"
fi

# --- Cache & Spazio ---
CACHE_USER=$(du -sh ~/Library/Caches 2>/dev/null | awk '{print $1}'); [ -z "$CACHE_USER" ] && CACHE_USER="N/A"
CACHE_SYS=$(du -sh /Library/Caches 2>/dev/null | awk '{print $1}');   [ -z "$CACHE_SYS" ] && CACHE_SYS="N/A"
LOGS_SIZE=$(du -sh ~/Library/Logs 2>/dev/null | awk '{print $1}');     [ -z "$LOGS_SIZE" ] && LOGS_SIZE="N/A"
DESKTOP_SIZE=$(du -sh ~/Desktop 2>/dev/null | awk '{print $1}');       [ -z "$DESKTOP_SIZE" ] && DESKTOP_SIZE="N/A"
DOWNLOADS_SIZE=$(du -sh ~/Downloads 2>/dev/null | awk '{print $1}');   [ -z "$DOWNLOADS_SIZE" ] && DOWNLOADS_SIZE="N/A"
DOCUMENTS_SIZE=$(du -sh ~/Documents 2>/dev/null | awk '{print $1}');   [ -z "$DOCUMENTS_SIZE" ] && DOCUMENTS_SIZE="N/A"

# Top cartelle home
FOLDER_ROWS=""
while IFS= read -r line; do
  [ -z "$line" ] && continue
  SZ=$(echo "$line" | awk '{print $1}')
  NM=$(basename "$(echo "$line" | awk '{$1=""; print $0}' | xargs)")
  FOLDER_ROWS="${FOLDER_ROWS}<tr><td>${NM}</td><td class='num'>${SZ}</td></tr>"
done < <(du -sh ~/* 2>/dev/null | sort -rh | head -15)

# --- Sezione Homebrew condizionale ---
if $BREW_INSTALLED; then
  BREW_SECTION="
  <div class='kpi-row' style='margin-bottom:20px;'>
    <div class='kpi'><div class='kpi-label'>Cask</div><div class='kpi-val' style='color:#f9a94c'>${BREW_CASK_COUNT}</div><div class='kpi-sub'>App grafiche</div></div>
    <div class='kpi'><div class='kpi-label'>Formula</div><div class='kpi-val' style='color:#4fc4cf'>${BREW_FORMULA_COUNT}</div><div class='kpi-sub'>Tool CLI</div></div>
    <div class='kpi'><div class='kpi-label'>Da aggiornare</div><div class='kpi-val' style='color:${BREW_OUT_COLOR}'>${BREW_OUTDATED_COUNT}</div><div class='kpi-sub'>Pacchetti</div></div>
  </div>
  <div class='card' style='margin-bottom:16px;'>
    <div class='card-label' style='margin-bottom:12px;'>Tool CLI installati (formula)</div>
    <div class='tags-wrap'>${BREW_FORMULA_HTML}</div>
  </div>
  <div class='card'>
    <div class='card-label' style='margin-bottom:12px;'>Pacchetti da aggiornare</div>
    <div class='tags-wrap'>${BREW_OUTDATED_HTML}</div>
  </div>"
else
  BREW_SECTION="<div class='card'><div class='muted'>Homebrew non installato su questo Mac.</div></div>"
fi

# ============================================================
#  SCRITTURA HTML
# ============================================================
cat > "$OUTPUT_HTML" << HTML_END
<!DOCTYPE html>
<html lang="it">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Mac Report — ${MAC_MODEL}</title>
<link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;700&family=Playfair+Display:wght@600;700;800&family=Source+Serif+4:wght@400;600&display=swap" rel="stylesheet">
<style>
:root{
  --bg:#0a0a0f;--bg2:#111118;--bg3:#18181f;--border:#2a2a35;
  --accent:#7c6dfa;--accent2:#4fc4cf;--accent3:#f9a94c;
  --text:#e8e8f0;--text2:#9090a8;
  --green:#4ade80;--yellow:#fbbf24;--red:#f87171;
  --r:14px;
  --mono:'IBM Plex Mono',monospace;
  --sans:'Source Serif 4','Georgia',serif;
  --display:'Playfair Display','Georgia',serif;
}
*{box-sizing:border-box;margin:0;padding:0}
body{background:var(--bg);color:var(--text);font-family:var(--sans);font-size:15px;line-height:1.7;min-height:100vh}

/* HEADER */
.header{background:linear-gradient(135deg,#0d0d15,#12121e 50%,#0a0f1a);border-bottom:1px solid var(--border);padding:44px 40px 36px;position:relative;overflow:hidden}
.header::before{content:'';position:absolute;top:-80px;right:-80px;width:360px;height:360px;background:radial-gradient(circle,rgba(124,109,250,.1),transparent 70%);border-radius:50%}
.header::after{content:'';position:absolute;bottom:-60px;left:15%;width:280px;height:280px;background:radial-gradient(circle,rgba(79,196,207,.07),transparent 70%);border-radius:50%}
.header-inner{max-width:1200px;margin:0 auto;position:relative;z-index:1}
.header-top{display:flex;justify-content:space-between;align-items:flex-start;flex-wrap:wrap;gap:20px}
.mac-label{font-size:10px;font-weight:700;letter-spacing:.2em;text-transform:uppercase;color:var(--accent);margin-bottom:10px;font-family:var(--mono)}
.header h1{font-size:34px;font-weight:800;line-height:1.15;font-family:var(--display)}
.header h1 span{color:var(--accent)}
.header-sub{font-family:var(--mono);font-size:11px;color:var(--text2);margin-top:12px;display:flex;gap:20px;flex-wrap:wrap}
.header-sub b{color:var(--accent2)}
.header-badges{display:flex;flex-direction:column;gap:10px;align-items:flex-end;flex-wrap:wrap}
.chip-pill{display:inline-flex;align-items:center;gap:8px;background:rgba(124,109,250,.1);border:1px solid rgba(124,109,250,.25);border-radius:100px;padding:9px 20px;font-family:var(--mono);font-size:11px;color:var(--text)}

/* LAYOUT */
.main{max-width:1200px;margin:0 auto;padding:36px 40px 64px}
.section-title{font-size:10px;font-weight:700;letter-spacing:.2em;text-transform:uppercase;color:var(--accent2);font-family:var(--mono);margin:44px 0 18px;display:flex;align-items:center;gap:14px}
.section-title::after{content:'';flex:1;height:1px;background:var(--border)}
.grid-4{display:grid;grid-template-columns:repeat(auto-fill,minmax(220px,1fr));gap:14px}
.grid-2{display:grid;grid-template-columns:repeat(auto-fill,minmax(360px,1fr));gap:14px}

/* CARD */
.card{background:var(--bg2);border:1px solid var(--border);border-radius:var(--r);padding:20px 22px;transition:border-color .2s}
.card:hover{border-color:#3a3a4a}
.card-label{font-size:10px;font-weight:700;letter-spacing:.15em;text-transform:uppercase;color:var(--text2);font-family:var(--mono);margin-bottom:10px}
.card-value{font-size:26px;font-weight:700;line-height:1.1;font-family:var(--display)}
.card-sub{font-size:12px;color:var(--text2);margin-top:5px;font-family:var(--mono)}

/* GAUGE */
.gauge-card{display:flex;align-items:center;gap:18px}
.gauge-wrap{position:relative;width:82px;height:82px;flex-shrink:0}
.gauge-wrap svg{transform:rotate(-90deg)}
.gauge-label{position:absolute;top:50%;left:50%;transform:translate(-50%,-50%);font-family:var(--mono);font-size:12px;font-weight:700;text-align:center;line-height:1.2}
.gauge-info{flex:1}
.gauge-info .card-label{margin-bottom:6px}
.gauge-info .card-value{font-size:20px}

/* PROGRESS */
.prog{margin-top:9px}
.prog-label{display:flex;justify-content:space-between;font-size:10px;color:var(--text2);margin-bottom:4px;font-family:var(--mono)}
.prog-track{background:var(--bg3);border-radius:100px;height:5px;overflow:hidden}
.prog-fill{height:100%;border-radius:100px}

/* KPI */
.kpi-row{display:grid;grid-template-columns:repeat(auto-fill,minmax(150px,1fr));gap:12px}
.kpi{background:var(--bg2);border:1px solid var(--border);border-radius:var(--r);padding:16px 18px}
.kpi-label{font-size:10px;font-weight:700;letter-spacing:.15em;text-transform:uppercase;color:var(--text2);font-family:var(--mono);margin-bottom:6px}
.kpi-val{font-size:20px;font-weight:700;font-family:var(--display)}
.kpi-sub{font-size:11px;color:var(--text2);font-family:var(--mono);margin-top:2px}

/* SECURITY */
.sec-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(240px,1fr));gap:10px}
.sec-item{background:var(--bg2);border:1px solid var(--border);border-radius:var(--r);padding:14px 18px;display:flex;justify-content:space-between;align-items:center;gap:12px}
.sec-label{font-size:13px;color:var(--text2);font-family:var(--sans)}

/* BADGES */
.badge{display:inline-block;padding:4px 11px;border-radius:6px;font-size:11px;font-weight:700;font-family:var(--mono);letter-spacing:.04em}
.badge-ok  {background:rgba(74,222,128,.12);color:var(--green);border:1px solid rgba(74,222,128,.25)}
.badge-warn{background:rgba(251,191,36,.12);color:var(--yellow);border:1px solid rgba(251,191,36,.25)}
.badge-err {background:rgba(248,113,113,.12);color:var(--red);border:1px solid rgba(248,113,113,.25)}

/* TABLE */
.table-wrap{background:var(--bg2);border:1px solid var(--border);border-radius:var(--r);overflow:hidden}
.data-table{width:100%;border-collapse:collapse}
.data-table th{text-align:left;font-size:10px;font-weight:700;letter-spacing:.14em;text-transform:uppercase;color:var(--text2);font-family:var(--mono);padding:12px 16px;border-bottom:1px solid var(--border)}
.data-table td{padding:11px 16px;border-bottom:1px solid #16161e;font-size:14px;font-family:var(--sans)}
.data-table tr:last-child td{border-bottom:none}
.data-table tr:hover td{background:rgba(255,255,255,.018)}
.num{font-family:var(--mono);font-size:12px;color:var(--accent3);text-align:right;white-space:nowrap}

/* APP SOURCE BADGES */
.src-badge{display:inline-flex;align-items:center;gap:5px;padding:3px 10px;border-radius:5px;font-size:11px;font-family:var(--mono);font-weight:700;white-space:nowrap}
.src-store {background:rgba(79,196,207,.1);color:#4fc4cf;border:1px solid rgba(79,196,207,.2)}
.src-brew  {background:rgba(249,169,76,.1);color:#f9a94c;border:1px solid rgba(249,169,76,.2)}
.src-manual{background:rgba(144,144,168,.1);color:#9090a8;border:1px solid rgba(144,144,168,.2)}

/* TAGS */
.tags-wrap{display:flex;flex-wrap:wrap;gap:8px}
.tag{background:var(--bg3);border:1px solid var(--border);border-radius:5px;padding:4px 10px;font-size:11px;font-family:var(--mono)}
.tag-formula{border-color:rgba(79,196,207,.3);color:var(--accent2)}
.tag-outdated{border-color:rgba(248,113,113,.3);color:var(--red)}

/* LEGEND */
.legend{display:flex;gap:20px;flex-wrap:wrap;margin-bottom:14px;padding:12px 16px;background:var(--bg2);border:1px solid var(--border);border-radius:var(--r)}
.legend-item{display:flex;align-items:center;gap:8px;font-size:12px;color:var(--text2);font-family:var(--mono)}

.muted{color:var(--text2);font-style:italic;font-size:13px}

/* FOOTER */
.footer{border-top:1px solid var(--border);padding:22px 40px;font-family:var(--mono);font-size:10px;color:var(--text2);text-align:center;letter-spacing:.1em}

@media(max-width:700px){
  .main{padding:20px 16px 40px}
  .header{padding:28px 16px}
  .header h1{font-size:26px}
}
</style>
</head>
<body>

<!-- ===== HEADER ===== -->
<div class="header">
  <div class="header-inner">
    <div class="header-top">
      <div>
        <div class="mac-label">Mac Maintenance Report</div>
        <h1>${MAC_MODEL} <span>/ ${ARCH_LABEL}</span></h1>
        <div class="header-sub">
          <span><b>Sistema</b> ${MACOS_NAME} ${MACOS_VERSION} (${MACOS_BUILD})</span>
          <span><b>Generato</b> ${REPORT_DATE}</span>
        </div>
      </div>
      <div class="header-badges">
        <div class="chip-pill">${MAC_CHIP}</div>
        <div class="chip-pill">${MAC_MEMORY} RAM · ${CPU_CORES} core</div>
        <span class="badge ${UPD_CLASS}">${UPD_TEXT}</span>
      </div>
    </div>
  </div>
</div>

<div class="main">

<!-- ===== HARDWARE ===== -->
<div class="section-title">Hardware</div>
<div class="grid-4">

  <!-- DISCO -->
  <div class="card gauge-card">
    <div class="gauge-wrap">
      <svg width="82" height="82" viewBox="0 0 82 82">
        <circle cx="41" cy="41" r="33" fill="none" stroke="#2a2a35" stroke-width="8"/>
        <circle cx="41" cy="41" r="33" fill="none" stroke="${DISK_COLOR}" stroke-width="8"
          stroke-dasharray="${DISK_DASH} 207.35" stroke-linecap="round"/>
      </svg>
      <div class="gauge-label" style="color:${DISK_COLOR}">${DISK_PCT}%</div>
    </div>
    <div class="gauge-info">
      <div class="card-label">Disco</div>
      <div class="card-value" style="color:${DISK_COLOR}">${DISK_FREE}</div>
      <div class="card-sub">liberi di ${DISK_TOTAL}</div>
      <div class="card-sub">usati: ${DISK_USED}</div>
    </div>
  </div>

  <!-- RAM -->
  <div class="card gauge-card">
    <div class="gauge-wrap">
      <svg width="82" height="82" viewBox="0 0 82 82">
        <circle cx="41" cy="41" r="33" fill="none" stroke="#2a2a35" stroke-width="8"/>
        <circle cx="41" cy="41" r="33" fill="none" stroke="${RAM_COLOR}" stroke-width="8"
          stroke-dasharray="${RAM_DASH} 207.35" stroke-linecap="round"/>
      </svg>
      <div class="gauge-label" style="color:${RAM_COLOR}">${RAM_USED_PCT}%<br><span style="font-size:10px">usata</span></div>
    </div>
    <div class="gauge-info">
      <div class="card-label">RAM</div>
      <div class="card-value" style="color:${RAM_COLOR}">${RAM_TOTAL_GB} GB</div>
      <div class="prog">
        <div class="prog-label"><span>Wired</span><span>${RAM_WIRED_MB} MB</span></div>
        <div class="prog-track"><div class="prog-fill" style="width:${RAM_WIRED_PCT}%;background:#7c6dfa"></div></div>
      </div>
      <div class="prog">
        <div class="prog-label"><span>Compressa</span><span>${RAM_COMPRESSED_MB} MB</span></div>
        <div class="prog-track"><div class="prog-fill" style="width:${RAM_COMP_PCT}%;background:#4fc4cf"></div></div>
      </div>
    </div>
  </div>

  <!-- CPU -->
  <div class="card">
    <div class="card-label">Processore</div>
    <div class="card-value" style="font-size:18px;line-height:1.3">${MAC_CHIP}</div>
    <div class="card-sub" style="margin-top:10px;">${CPU_CORES} core logici · ${CPU_PHYSICAL} fisici</div>
    <div class="card-sub">Architettura: ${CPU_ARCH}</div>
  </div>

  <!-- GPU -->
  <div class="card">
    <div class="card-label">GPU</div>
    <div class="card-value" style="font-size:18px;line-height:1.3">${GPU_NAME}</div>
    <div class="card-sub" style="margin-top:10px;">VRAM: ${GPU_VRAM}</div>
  </div>

  <!-- BATTERIA -->
  ${BATTERY_HTML}

</div>

<!-- Volumi disco -->
<div style="margin-top:14px">
  <div class="table-wrap">
    <table class="data-table">
      <thead><tr><th>Volume</th><th style="text-align:right">Totale</th><th style="text-align:right">Usato</th><th style="text-align:right">Libero</th><th style="text-align:right">% Uso</th></tr></thead>
      <tbody>${VOLUMES_ROWS}</tbody>
    </table>
  </div>
</div>

<!-- ===== SICUREZZA ===== -->
<div class="section-title">Sicurezza</div>
<div class="sec-grid">
  <div class="sec-item"><span class="sec-label">FileVault (cifratura disco)</span><span class="badge ${FV_CLASS}">${FILEVAULT}</span></div>
  <div class="sec-item"><span class="sec-label">Firewall</span><span class="badge ${FW_CLASS}">${FIREWALL_STATUS}</span></div>
  <div class="sec-item"><span class="sec-label">Gatekeeper (verifica app)</span><span class="badge ${GK_CLASS}">${GATEKEEPER}</span></div>
  <div class="sec-item"><span class="sec-label">System Integrity Protection</span><span class="badge ${SIP_CLASS}">${SIP}</span></div>
  <div class="sec-item"><span class="sec-label">Aggiornamenti macOS</span><span class="badge ${UPD_CLASS}">${UPD_TEXT}</span></div>
</div>

<!-- ===== SPAZIO & CACHE ===== -->
<div class="section-title">Spazio &amp; Cache</div>
<div class="grid-4">
  <div class="card"><div class="card-label">Cache Utente</div><div class="card-value" style="color:var(--accent3)">${CACHE_USER}</div><div class="card-sub">~/Library/Caches</div></div>
  <div class="card"><div class="card-label">Cache Sistema</div><div class="card-value" style="color:var(--accent3)">${CACHE_SYS}</div><div class="card-sub">/Library/Caches</div></div>
  <div class="card"><div class="card-label">Log Utente</div><div class="card-value" style="color:var(--text2)">${LOGS_SIZE}</div><div class="card-sub">~/Library/Logs</div></div>
  <div class="card"><div class="card-label">Desktop</div><div class="card-value">${DESKTOP_SIZE}</div></div>
  <div class="card"><div class="card-label">Downloads</div><div class="card-value">${DOWNLOADS_SIZE}</div></div>
  <div class="card"><div class="card-label">Documents</div><div class="card-value">${DOCUMENTS_SIZE}</div></div>
</div>

<div style="margin-top:14px">
  <div class="table-wrap">
    <table class="data-table">
      <thead><tr><th>Cartella Home</th><th style="text-align:right">Dimensione</th></tr></thead>
      <tbody>${FOLDER_ROWS}</tbody>
    </table>
  </div>
</div>

<!-- ===== APP INSTALLATE ===== -->
<div class="section-title">Applicazioni installate (${APP_TOTAL})</div>

<div class="legend">
  <div class="legend-item"><span class="src-badge src-store">🛍️ App Store</span> <span>Installata tramite Mac App Store (aggiornamenti gestiti da Apple)</span></div>
  <div class="legend-item"><span class="src-badge src-brew">🍺 Homebrew</span> <span>Installata via Homebrew Cask (aggiornabile con brew upgrade)</span></div>
  <div class="legend-item"><span class="src-badge src-manual">🌐 Manuale / Web</span> <span>Scaricata manualmente o da sito del produttore</span></div>
</div>

<div class="kpi-row" style="margin-bottom:16px">
  <div class="kpi"><div class="kpi-label">App Store</div><div class="kpi-val" style="color:var(--accent2)">${APP_STORE_COUNT}</div></div>
  <div class="kpi"><div class="kpi-label">Homebrew</div><div class="kpi-val" style="color:var(--accent3)">${APP_BREW_COUNT}</div></div>
  <div class="kpi"><div class="kpi-label">Manuale / Web</div><div class="kpi-val" style="color:var(--text2)">${APP_MANUAL_COUNT}</div></div>
  <div class="kpi"><div class="kpi-label">Totale</div><div class="kpi-val">${APP_TOTAL}</div></div>
</div>

<div class="table-wrap">
  <table class="data-table">
    <thead><tr><th>Applicazione</th><th>Tipo installazione</th><th style="text-align:right">Dimensione</th></tr></thead>
    <tbody>${APP_TABLE_ROWS}</tbody>
  </table>
</div>

<!-- ===== HOMEBREW ===== -->
<div class="section-title">Homebrew</div>
${BREW_SECTION}

</div><!-- /main -->

<div class="footer">
  MAC MAINTENANCE REPORT &nbsp;·&nbsp; ${MAC_MODEL} &nbsp;·&nbsp; ${MACOS_NAME} ${MACOS_VERSION} &nbsp;·&nbsp; ${REPORT_DATE}
</div>
</body>
</html>
HTML_END

echo ""
echo "✅ Report completato!"
echo "📄 Salvato in: $OUTPUT_HTML"
open "$OUTPUT_HTML" 2>/dev/null || true
