#!/bin/bash
# ============================================================
#  MAC MAINTENANCE REPORT — HTML Edition v2
#  Compatibile con qualsiasi Mac (Intel & Apple Silicon)
# ============================================================

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_HTML="$HOME/Desktop/mac_report_${TIMESTAMP}.html"

# ============================================================
#  RACCOLTA DATI — tutto pre-calcolato, niente $() nell'HTML
# ============================================================

MAC_MODEL=$(system_profiler SPHardwareDataType 2>/dev/null | awk -F': ' '/Model Name/{print $2}' | xargs)
MAC_IDENTIFIER=$(system_profiler SPHardwareDataType 2>/dev/null | awk -F': ' '/Model Identifier/{print $2}' | xargs)
MAC_CHIP=$(system_profiler SPHardwareDataType 2>/dev/null | awk -F': ' '/Chip/{print $2}' | xargs)
[ -z "$MAC_CHIP" ] && MAC_CHIP=$(system_profiler SPHardwareDataType 2>/dev/null | awk -F': ' '/Processor Name/{print $2}' | xargs)
MAC_MEMORY=$(system_profiler SPHardwareDataType 2>/dev/null | awk -F': ' '/Memory/{print $2}' | xargs)
MAC_SERIAL=$(system_profiler SPHardwareDataType 2>/dev/null | awk -F': ' '/Serial Number/{print $2}' | xargs)
MACOS_VERSION=$(sw_vers -productVersion 2>/dev/null)
MACOS_BUILD=$(sw_vers -buildVersion 2>/dev/null)
MACOS_NAME=$(sw_vers -productName 2>/dev/null)
UPTIME_STR=$(uptime 2>/dev/null | awk -F'up' '{print $2}' | awk -F',' '{print $1}' | xargs)
HOSTNAME_STR=$(hostname -s 2>/dev/null)
CURRENT_USER=$(whoami)
REPORT_DATE=$(date '+%d/%m/%Y alle %H:%M:%S')
CPU_ARCH=$(uname -m 2>/dev/null)
CPU_CORES=$(sysctl -n hw.logicalcpu 2>/dev/null)
CPU_PHYSICAL=$(sysctl -n hw.physicalcpu 2>/dev/null)

# --- Disco ---
DISK_TOTAL=$(df -h / 2>/dev/null | awk 'NR==2{print $2}')
DISK_USED=$(df -h / 2>/dev/null | awk 'NR==2{print $3}')
DISK_FREE=$(df -h / 2>/dev/null | awk 'NR==2{print $4}')
DISK_PCT=$(df / 2>/dev/null | awk 'NR==2{gsub(/%/,"",$5); print $5}')
DISK_PCT=${DISK_PCT:-0}
DISK_DASH=$(awk "BEGIN{printf \"%.1f\", ($DISK_PCT/100)*201.06}")

# --- RAM ---
RAM_TOTAL_BYTES=$(sysctl -n hw.memsize 2>/dev/null)
RAM_TOTAL_GB=$(echo "$RAM_TOTAL_BYTES" | awk '{printf "%.0f", $1/1073741824}')
VM_STAT=$(vm_stat 2>/dev/null)
PAGE_SIZE=$(echo "$VM_STAT" | awk '/page size/{print $8}')
[ -z "$PAGE_SIZE" ] && PAGE_SIZE=16384
PAGES_FREE=$(echo "$VM_STAT"    | awk '/Pages free/{gsub(/\./,"",$3); print $3+0}')
PAGES_ACTIVE=$(echo "$VM_STAT"  | awk '/Pages active/{gsub(/\./,"",$3); print $3+0}')
PAGES_WIRED=$(echo "$VM_STAT"   | awk '/Pages wired/{gsub(/\./,"",$4); print $4+0}')
PAGES_COMP=$(echo "$VM_STAT"    | awk '/Pages occupied by compressor/{gsub(/\./,"",$5); print $5+0}')

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

# --- Batteria ---
BATTERY_INFO=$(system_profiler SPPowerDataType 2>/dev/null)
BATTERY_CYCLE=$(echo "$BATTERY_INFO"    | awk -F': ' '/Cycle Count/{print $2}' | xargs)
BATTERY_CONDITION=$(echo "$BATTERY_INFO"| awk -F': ' '/Condition/{print $2}' | xargs)
BATTERY_CAPACITY=$(echo "$BATTERY_INFO" | awk -F': ' '/Maximum Capacity/{print $2}' | xargs)
BATTERY_CHARGE=$(echo "$BATTERY_INFO"   | awk -F': ' '/State of Charge/{print $2}' | xargs)
[ -z "$BATTERY_CHARGE" ] && BATTERY_CHARGE=$(pmset -g batt 2>/dev/null | grep -o '[0-9]*%' | head -1 | tr -d '%')
[ -z "$BATTERY_CHARGE" ] && BATTERY_CHARGE=0
BATTERY_CHARGE_NUM=$(echo "$BATTERY_CHARGE" | tr -d '%' | awk '{print $1+0}')
[ -z "$BATTERY_CYCLE" ]     && BATTERY_CYCLE="N/A"
[ -z "$BATTERY_CONDITION" ] && BATTERY_CONDITION="N/A"
[ -z "$BATTERY_CAPACITY" ]  && BATTERY_CAPACITY="N/A"

# Colori dinamici
DISK_COLOR="#4ade80"
[ "$DISK_PCT" -gt 80 ] 2>/dev/null && DISK_COLOR="#fbbf24"
[ "$DISK_PCT" -gt 90 ] 2>/dev/null && DISK_COLOR="#f87171"
RAM_COLOR="#4ade80"
[ "$RAM_USED_PCT" -gt 80 ] 2>/dev/null && RAM_COLOR="#fbbf24"
[ "$RAM_USED_PCT" -gt 90 ] 2>/dev/null && RAM_COLOR="#f87171"
BAT_COLOR="#4ade80"
case "$BATTERY_CONDITION" in
  "Poor"|"Replace Soon"|"Service Battery") BAT_COLOR="#f87171" ;;
  "Fair"|"Replace Now") BAT_COLOR="#fbbf24" ;;
esac
BAT_COND_CLASS="badge-ok"
[ "$BATTERY_CONDITION" != "Normal" ] && BAT_COND_CLASS="badge-warn"

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
echo "$FILEVAULT"   | grep -qi "On"      && FV_CLASS="badge-ok"  || FV_CLASS="badge-err"
echo "$GATEKEEPER"  | grep -qi "enabled" && GK_CLASS="badge-ok"  || GK_CLASS="badge-err"
echo "$SIP"         | grep -qi "enabled" && SIP_CLASS="badge-ok" || SIP_CLASS="badge-err"

# --- Aggiornamenti ---
UPDATES_RAW=$(softwareupdate -l 2>/dev/null)
UPDATES_COUNT=$(echo "$UPDATES_RAW" | grep -c "^\*" 2>/dev/null || echo "0")
UPDATES_COUNT=${UPDATES_COUNT:-0}
if [ "$UPDATES_COUNT" -gt 0 ] 2>/dev/null; then
  UPD_CLASS="badge-warn"; UPD_TEXT="${UPDATES_COUNT} aggiornamenti disponibili"
else
  UPD_CLASS="badge-ok";   UPD_TEXT="Sistema aggiornato"
fi

# --- App ---
APP_TABLE_ROWS=""
while IFS= read -r line; do
  [ -z "$line" ] && continue
  SZ=$(echo "$line" | awk '{print $1}')
  NM=$(basename "$(echo "$line" | awk '{$1=""; print $0}' | xargs)" .app)
  APP_TABLE_ROWS="${APP_TABLE_ROWS}<tr><td>${NM}</td><td class='size-cell'>${SZ}</td></tr>"
done < <(du -sh /Applications/*.app ~/Applications/*.app 2>/dev/null | sort -rh | head -30)

APP_STORE_HTML=""
APP_STORE_COUNT=0
while IFS= read -r app; do
  [ -z "$app" ] && continue
  APP_STORE_HTML="${APP_STORE_HTML}<span class='tag'>$(basename "$app" .app)</span>"
  APP_STORE_COUNT=$(( APP_STORE_COUNT + 1 ))
done < <(mdfind "kMDItemAppStoreHasReceipt == 1" 2>/dev/null | grep "\.app$" | sort)
[ -z "$APP_STORE_HTML" ] && APP_STORE_HTML="<span class='muted'>Nessuna app trovata</span>"

# --- Homebrew ---
BREW_SECTION=""
if command -v brew &>/dev/null; then
  BREW_CASK_COUNT=$(brew list --cask 2>/dev/null | wc -l | xargs)
  BREW_FORMULA_COUNT=$(brew list --formula 2>/dev/null | wc -l | xargs)
  BREW_OUTDATED_COUNT=$(brew outdated 2>/dev/null | grep -c . || echo 0)
  BREW_OUT_COLOR="#4ade80"; [ "$BREW_OUTDATED_COUNT" -gt 0 ] 2>/dev/null && BREW_OUT_COLOR="#fbbf24"
  BREW_CASK_HTML=""; for c in $(brew list --cask 2>/dev/null); do BREW_CASK_HTML="${BREW_CASK_HTML}<span class='tag tag-brew'>${c}</span>"; done
  [ -z "$BREW_CASK_HTML" ] && BREW_CASK_HTML="<span class='muted'>Nessun cask</span>"
  BREW_FORMULA_HTML=""; for f in $(brew list --formula 2>/dev/null); do BREW_FORMULA_HTML="${BREW_FORMULA_HTML}<span class='tag tag-formula'>${f}</span>"; done
  [ -z "$BREW_FORMULA_HTML" ] && BREW_FORMULA_HTML="<span class='muted'>Nessuna formula</span>"
  BREW_SECTION="<div class='kpi-row' style='margin-bottom:16px;'>
    <div class='kpi'><div class='kpi-label'>Cask</div><div class='kpi-val' style='color:#f9a94c'>${BREW_CASK_COUNT}</div><div class='kpi-sub'>app grafiche</div></div>
    <div class='kpi'><div class='kpi-label'>Formula</div><div class='kpi-val' style='color:#4fc4cf'>${BREW_FORMULA_COUNT}</div><div class='kpi-sub'>tool CLI</div></div>
    <div class='kpi'><div class='kpi-label'>Da aggiornare</div><div class='kpi-val' style='color:${BREW_OUT_COLOR}'>${BREW_OUTDATED_COUNT}</div></div>
  </div>
  <div class='cards-grid-3'>
    <div class='card'><div class='card-label' style='margin-bottom:12px;'>Cask installati</div><div class='tags-wrap'>${BREW_CASK_HTML}</div></div>
    <div class='card'><div class='card-label' style='margin-bottom:12px;'>Formula installate</div><div class='tags-wrap'>${BREW_FORMULA_HTML}</div></div>
  </div>"
else
  BREW_SECTION="<div class='card'><div class='card-label'>Homebrew</div><div class='muted'>Homebrew non installato su questo Mac.</div></div>"
fi

# --- AI Models ---
OLLAMA_SIZE=$(du -sh ~/.ollama 2>/dev/null | awk '{print $1}'); [ -z "$OLLAMA_SIZE" ] && OLLAMA_SIZE="Non trovato"
OLLAMA_TAGS=""
while IFS= read -r m; do
  [ -z "$m" ] && continue
  OLLAMA_TAGS="${OLLAMA_TAGS}<span class='tag' style='margin:2px'>${m}</span>"
done < <(ollama list 2>/dev/null | tail -n +2 | awk '{print $1}')
[ -z "$OLLAMA_TAGS" ] && OLLAMA_TAGS="<span class='muted'>Ollama non attivo o non installato</span>"
LMS_SIZE=$(du -sh ~/.cache/lm-studio 2>/dev/null | awk '{print $1}'); [ -z "$LMS_SIZE" ] && LMS_SIZE="Non trovato"

# --- Docker ---
DOCKER_SECTION=""
if command -v docker &>/dev/null; then
  DOCKER_IMAGES=$(docker images 2>/dev/null | tail -n +2 | wc -l | xargs)
  DOCKER_CONTAINERS=$(docker ps -a 2>/dev/null | tail -n +2 | wc -l | xargs)
  DOCKER_RUNNING=$(docker ps 2>/dev/null | tail -n +2 | wc -l | xargs)
  DOCKER_DF_ESC=$(docker system df 2>/dev/null | sed 's/</\&lt;/g; s/>/\&gt;/g' || echo "Docker non in esecuzione")
  DOCKER_SECTION="<div class='kpi-row' style='margin-bottom:16px;'>
    <div class='kpi'><div class='kpi-label'>Immagini</div><div class='kpi-val' style='color:#f9a94c'>${DOCKER_IMAGES}</div></div>
    <div class='kpi'><div class='kpi-label'>Container totali</div><div class='kpi-val'>${DOCKER_CONTAINERS}</div></div>
    <div class='kpi'><div class='kpi-label'>In esecuzione</div><div class='kpi-val' style='color:#4ade80'>${DOCKER_RUNNING}</div></div>
  </div>
  <div class='card'><div class='card-label' style='margin-bottom:10px;'>Docker system df</div><div class='mono-block'>${DOCKER_DF_ESC}</div></div>"
else
  DOCKER_SECTION="<div class='card'><div class='card-label'>Docker</div><div class='muted'>Docker non installato su questo Mac.</div></div>"
fi

# --- Cache & Spazio ---
CACHE_USER=$(du -sh ~/Library/Caches 2>/dev/null | awk '{print $1}'); [ -z "$CACHE_USER" ] && CACHE_USER="N/A"
CACHE_SYS=$(du -sh /Library/Caches 2>/dev/null | awk '{print $1}'); [ -z "$CACHE_SYS" ] && CACHE_SYS="N/A"
LOGS_SIZE=$(du -sh ~/Library/Logs 2>/dev/null | awk '{print $1}'); [ -z "$LOGS_SIZE" ] && LOGS_SIZE="N/A"
TMP_SIZE=$(du -sh /tmp 2>/dev/null | awk '{print $1}'); [ -z "$TMP_SIZE" ] && TMP_SIZE="N/A"
DESKTOP_SIZE=$(du -sh ~/Desktop 2>/dev/null | awk '{print $1}'); [ -z "$DESKTOP_SIZE" ] && DESKTOP_SIZE="N/A"
DOWNLOADS_SIZE=$(du -sh ~/Downloads 2>/dev/null | awk '{print $1}'); [ -z "$DOWNLOADS_SIZE" ] && DOWNLOADS_SIZE="N/A"
DOCUMENTS_SIZE=$(du -sh ~/Documents 2>/dev/null | awk '{print $1}'); [ -z "$DOCUMENTS_SIZE" ] && DOCUMENTS_SIZE="N/A"

# --- Top cartelle home ---
FOLDER_ROWS=""
while IFS= read -r line; do
  [ -z "$line" ] && continue
  SZ=$(echo "$line" | awk '{print $1}')
  NM=$(basename "$(echo "$line" | awk '{$1=""; print $0}' | xargs)")
  FOLDER_ROWS="${FOLDER_ROWS}<tr><td>${NM}</td><td class='size-cell'>${SZ}</td></tr>"
done < <(du -sh ~/* 2>/dev/null | sort -rh | head -12)

# --- Processi ---
CPU_TABLE_ROWS=""
while IFS= read -r line; do
  [ -z "$line" ] && continue
  PROC=$(echo "$line" | cut -d'|' -f1 | sed 's|.*/||')
  CPU_V=$(echo "$line" | cut -d'|' -f2)
  MEM_V=$(echo "$line" | cut -d'|' -f3)
  CPU_W=$(awk "BEGIN{v=$CPU_V*2; if(v>100)v=100; printf \"%.0f\",v}")
  CPU_TABLE_ROWS="${CPU_TABLE_ROWS}<tr><td>${PROC}</td><td><div class='bar-wrap'><div class='bar cpu-bar' style='width:${CPU_W}%'></div></div></td><td class='pct-cell'>${CPU_V}%</td><td class='pct-cell'>${MEM_V}%</td></tr>"
done < <(ps aux 2>/dev/null | sort -rk3 | head -11 | tail -10 | awk '{printf "%s|%.1f|%.1f\n", $11, $3, $4}')

MEM_TABLE_ROWS=""
while IFS= read -r line; do
  [ -z "$line" ] && continue
  PROC=$(echo "$line" | cut -d'|' -f1 | sed 's|.*/||')
  MEM_V=$(echo "$line" | cut -d'|' -f2)
  CPU_V=$(echo "$line" | cut -d'|' -f3)
  MEM_W=$(awk "BEGIN{v=$MEM_V*5; if(v>100)v=100; printf \"%.0f\",v}")
  MEM_TABLE_ROWS="${MEM_TABLE_ROWS}<tr><td>${PROC}</td><td><div class='bar-wrap'><div class='bar mem-bar' style='width:${MEM_W}%'></div></div></td><td class='pct-cell'>${MEM_V}%</td><td class='pct-cell'>${CPU_V}%</td></tr>"
done < <(ps aux 2>/dev/null | sort -rk4 | head -11 | tail -10 | awk '{printf "%s|%.1f|%.1f\n", $11, $4, $3}')

# --- Rete ---
WIFI_SSID=$(/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I 2>/dev/null | awk -F': ' '/ SSID/{print $2}' | xargs)
[ -z "$WIFI_SSID" ] && WIFI_SSID=$(networksetup -getairportnetwork en0 2>/dev/null | awk -F': ' '{print $2}' | xargs)
[ -z "$WIFI_SSID" ] && WIFI_SSID="Non disponibile"
IP_LOCAL=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null)
[ -z "$IP_LOCAL" ] && IP_LOCAL="Non disponibile"
LAUNCH_AGENTS_USER=$(ls ~/Library/LaunchAgents/ 2>/dev/null | wc -l | xargs)
LAUNCH_AGENTS_SYS=$(ls /Library/LaunchAgents/ 2>/dev/null | wc -l | xargs)
LAUNCH_DAEMONS=$(ls /Library/LaunchDaemons/ 2>/dev/null | wc -l | xargs)

# ============================================================
#  SCRITTURA HTML — tutto pre-interpolato, niente $() inline
# ============================================================
cat > "$OUTPUT_HTML" << HTML_END
<!DOCTYPE html>
<html lang="it">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Mac Report — ${HOSTNAME_STR}</title>
<link href="https://fonts.googleapis.com/css2?family=Space+Mono:wght@400;700&family=Syne:wght@400;600;700;800&display=swap" rel="stylesheet">
<style>
:root{--bg:#0a0a0f;--bg2:#111118;--bg3:#18181f;--border:#2a2a35;--accent:#7c6dfa;--accent2:#4fc4cf;--accent3:#f9a94c;--text:#e8e8f0;--text2:#9090a8;--green:#4ade80;--yellow:#fbbf24;--red:#f87171;--r:14px;--mono:'Space Mono',monospace;--sans:'Syne',sans-serif}
*{box-sizing:border-box;margin:0;padding:0}
body{background:var(--bg);color:var(--text);font-family:var(--sans);font-size:15px;line-height:1.6;min-height:100vh}
.header{background:linear-gradient(135deg,#0d0d15,#12121e 50%,#0a0f1a);border-bottom:1px solid var(--border);padding:40px 40px 32px;position:relative;overflow:hidden}
.header::before{content:'';position:absolute;top:-60px;right:-60px;width:300px;height:300px;background:radial-gradient(circle,rgba(124,109,250,.12),transparent 70%);border-radius:50%}
.header::after{content:'';position:absolute;bottom:-40px;left:20%;width:200px;height:200px;background:radial-gradient(circle,rgba(79,196,207,.08),transparent 70%);border-radius:50%}
.header-inner{max-width:1200px;margin:0 auto;position:relative;z-index:1}
.header-top{display:flex;justify-content:space-between;align-items:flex-start;flex-wrap:wrap;gap:16px}
.mac-name{font-size:13px;font-weight:700;letter-spacing:.12em;text-transform:uppercase;color:var(--accent);margin-bottom:6px;font-family:var(--mono)}
.header h1{font-size:32px;font-weight:800;letter-spacing:-.02em;line-height:1.1}
.header h1 span{color:var(--accent)}
.report-meta{font-family:var(--mono);font-size:12px;color:var(--text2);margin-top:10px;display:flex;gap:24px;flex-wrap:wrap}
.report-meta b{color:var(--accent2)}
.chip-badge{display:inline-flex;align-items:center;gap:8px;background:var(--bg3);border:1px solid var(--border);border-radius:100px;padding:8px 18px;font-family:var(--mono);font-size:12px;white-space:nowrap}
.chip-badge::before{content:'⬡';color:var(--accent);font-size:14px}
.main{max-width:1200px;margin:0 auto;padding:32px 40px 60px}
.section-title{font-size:11px;font-weight:700;letter-spacing:.14em;text-transform:uppercase;color:var(--accent2);font-family:var(--mono);margin:40px 0 16px;display:flex;align-items:center;gap:12px}
.section-title::after{content:'';flex:1;height:1px;background:var(--border)}
.cards-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(240px,1fr));gap:16px}
.cards-grid-3{display:grid;grid-template-columns:repeat(auto-fill,minmax(340px,1fr));gap:16px}
.card{background:var(--bg2);border:1px solid var(--border);border-radius:var(--r);padding:20px 22px;transition:border-color .2s}
.card:hover{border-color:#3a3a4a}
.card-label{font-size:11px;font-weight:700;letter-spacing:.1em;text-transform:uppercase;color:var(--text2);font-family:var(--mono);margin-bottom:8px}
.card-value{font-size:28px;font-weight:800;line-height:1.1}
.card-sub{font-size:12px;color:var(--text2);margin-top:4px;font-family:var(--mono)}
.gauge-card{display:flex;align-items:center;gap:20px}
.gauge-wrap{position:relative;width:80px;height:80px;flex-shrink:0}
.gauge-wrap svg{transform:rotate(-90deg)}
.gauge-label{position:absolute;top:50%;left:50%;transform:translate(-50%,-50%);font-family:var(--mono);font-size:13px;font-weight:700;text-align:center}
.gauge-info{flex:1}
.gauge-info .card-label{margin-bottom:6px}
.gauge-info .card-value{font-size:22px}
.progress-section{margin-top:10px}
.progress-label{display:flex;justify-content:space-between;font-size:11px;color:var(--text2);margin-bottom:4px;font-family:var(--mono)}
.progress-track{background:var(--bg3);border-radius:100px;height:6px;overflow:hidden}
.progress-fill{height:100%;border-radius:100px}
.data-table{width:100%;border-collapse:collapse}
.data-table th{text-align:left;font-size:11px;font-weight:700;letter-spacing:.1em;text-transform:uppercase;color:var(--text2);font-family:var(--mono);padding:0 12px 10px;border-bottom:1px solid var(--border)}
.data-table td{padding:10px 12px;border-bottom:1px solid #1a1a22;font-size:14px}
.data-table tr:last-child td{border-bottom:none}
.data-table tr:hover td{background:rgba(255,255,255,.02)}
.size-cell{font-family:var(--mono);color:var(--accent3);text-align:right;font-size:13px}
.pct-cell{font-family:var(--mono);font-size:13px;text-align:right}
.bar-wrap{background:var(--bg3);border-radius:100px;height:6px;min-width:80px}
.bar{height:100%;border-radius:100px}
.cpu-bar{background:linear-gradient(90deg,var(--accent),#a78bfa)}
.mem-bar{background:linear-gradient(90deg,var(--accent2),#22d3ee)}
.tags-wrap{display:flex;flex-wrap:wrap;gap:8px}
.tag{background:var(--bg3);border:1px solid var(--border);border-radius:6px;padding:4px 10px;font-size:12px;font-family:var(--mono)}
.tag-brew{border-color:rgba(249,169,76,.3);color:var(--accent3)}
.tag-formula{border-color:rgba(79,196,207,.3);color:var(--accent2)}
.badge{display:inline-block;padding:4px 12px;border-radius:6px;font-size:12px;font-weight:700;font-family:var(--mono);letter-spacing:.05em}
.badge-ok{background:rgba(74,222,128,.12);color:var(--green);border:1px solid rgba(74,222,128,.25)}
.badge-warn{background:rgba(251,191,36,.12);color:var(--yellow);border:1px solid rgba(251,191,36,.25)}
.badge-err{background:rgba(248,113,113,.12);color:var(--red);border:1px solid rgba(248,113,113,.25)}
.security-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(260px,1fr));gap:12px}
.security-item{background:var(--bg2);border:1px solid var(--border);border-radius:var(--r);padding:16px 18px;display:flex;justify-content:space-between;align-items:center;gap:12px}
.security-item .label{font-size:13px;color:var(--text2)}
.kpi-row{display:grid;grid-template-columns:repeat(auto-fill,minmax(160px,1fr));gap:12px}
.kpi{background:var(--bg2);border:1px solid var(--border);border-radius:var(--r);padding:16px 18px}
.kpi-label{font-size:11px;font-weight:700;letter-spacing:.1em;text-transform:uppercase;color:var(--text2);font-family:var(--mono);margin-bottom:6px}
.kpi-val{font-size:22px;font-weight:800}
.kpi-sub{font-size:11px;color:var(--text2);font-family:var(--mono);margin-top:2px}
.muted{color:var(--text2);font-style:italic;font-size:13px}
.mono-block{background:var(--bg3);border:1px solid var(--border);border-radius:8px;padding:16px;font-family:var(--mono);font-size:12px;color:var(--text2);white-space:pre-wrap;word-break:break-word;line-height:1.7;max-height:300px;overflow-y:auto}
.footer{border-top:1px solid var(--border);padding:24px 40px;font-family:var(--mono);font-size:11px;color:var(--text2);text-align:center;letter-spacing:.08em}
@media(max-width:700px){.main{padding:20px 16px 40px}.header{padding:24px 16px}.header h1{font-size:24px}}
</style>
</head>
<body>

<div class="header">
  <div class="header-inner">
    <div class="header-top">
      <div>
        <div class="mac-name">${HOSTNAME_STR} · ${CURRENT_USER}</div>
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
        <span class="badge ${UPD_CLASS}">${UPD_TEXT}</span>
      </div>
    </div>
  </div>
</div>

<div class="main">

<div class="section-title">Risorse di sistema</div>
<div class="cards-grid">

  <div class="card gauge-card">
    <div class="gauge-wrap">
      <svg width="80" height="80" viewBox="0 0 80 80">
        <circle cx="40" cy="40" r="32" fill="none" stroke="#2a2a35" stroke-width="8"/>
        <circle cx="40" cy="40" r="32" fill="none" stroke="${DISK_COLOR}" stroke-width="8"
          stroke-dasharray="${DISK_DASH} 201.06" stroke-linecap="round"/>
      </svg>
      <div class="gauge-label" style="color:${DISK_COLOR}">${DISK_PCT}%</div>
    </div>
    <div class="gauge-info">
      <div class="card-label">Disco</div>
      <div class="card-value" style="color:${DISK_COLOR}">${DISK_FREE}</div>
      <div class="card-sub">liberi di ${DISK_TOTAL}</div>
      <div class="card-sub">usati ${DISK_USED}</div>
    </div>
  </div>

  <div class="card gauge-card">
    <div class="gauge-wrap">
      <svg width="80" height="80" viewBox="0 0 80 80">
        <circle cx="40" cy="40" r="32" fill="none" stroke="#2a2a35" stroke-width="8"/>
        <circle cx="40" cy="40" r="32" fill="none" stroke="${RAM_COLOR}" stroke-width="8"
          stroke-dasharray="${RAM_DASH} 201.06" stroke-linecap="round"/>
      </svg>
      <div class="gauge-label" style="color:${RAM_COLOR}">${RAM_USED_PCT}%</div>
    </div>
    <div class="gauge-info">
      <div class="card-label">RAM</div>
      <div class="card-value" style="color:${RAM_COLOR}">${RAM_TOTAL_GB} GB</div>
      <div class="card-sub">usata ~${RAM_USED_MB} MB</div>
      <div class="progress-section">
        <div class="progress-label"><span>Wired</span><span>${RAM_WIRED_MB} MB</span></div>
        <div class="progress-track"><div class="progress-fill" style="width:${RAM_WIRED_PCT}%;background:#7c6dfa"></div></div>
      </div>
      <div class="progress-section">
        <div class="progress-label"><span>Compressa</span><span>${RAM_COMPRESSED_MB} MB</span></div>
        <div class="progress-track"><div class="progress-fill" style="width:${RAM_COMP_PCT}%;background:#4fc4cf"></div></div>
      </div>
    </div>
  </div>

  <div class="card">
    <div class="card-label">Batteria</div>
    <div style="display:flex;align-items:baseline;gap:10px;flex-wrap:wrap">
      <div class="card-value" style="color:${BAT_COLOR}">${BATTERY_CHARGE_NUM}%</div>
      <span class="badge ${BAT_COND_CLASS}">${BATTERY_CONDITION}</span>
    </div>
    <div class="card-sub" style="margin-top:8px;">Cicli: <b style="color:var(--text)">${BATTERY_CYCLE}</b></div>
    <div class="card-sub">Capacità massima: <b style="color:var(--text)">${BATTERY_CAPACITY}</b></div>
    <div class="progress-section" style="margin-top:10px;">
      <div class="progress-track" style="height:8px;">
        <div class="progress-fill" style="width:${BATTERY_CHARGE_NUM}%;background:${BAT_COLOR}"></div>
      </div>
    </div>
  </div>

  <div class="card">
    <div class="card-label">CPU</div>
    <div class="card-value">${CPU_CORES}</div>
    <div class="card-sub">core logici (${CPU_PHYSICAL} fisici)</div>
    <div class="card-sub" style="margin-top:8px;">${MAC_IDENTIFIER}</div>
    <div class="card-sub">S/N: ${MAC_SERIAL}</div>
  </div>

</div>

<div class="section-title">Uptime &amp; Rete</div>
<div class="kpi-row">
  <div class="kpi"><div class="kpi-label">Uptime</div><div class="kpi-val" style="font-size:15px;color:var(--accent2)">${UPTIME_STR}</div></div>
  <div class="kpi"><div class="kpi-label">IP Locale</div><div class="kpi-val" style="font-size:16px;color:var(--accent)">${IP_LOCAL}</div></div>
  <div class="kpi"><div class="kpi-label">Wi-Fi SSID</div><div class="kpi-val" style="font-size:16px;color:var(--accent3)">${WIFI_SSID}</div></div>
  <div class="kpi"><div class="kpi-label">User Agents</div><div class="kpi-val" style="color:var(--text2)">${LAUNCH_AGENTS_USER}</div><div class="kpi-sub">LaunchAgents utente</div></div>
  <div class="kpi"><div class="kpi-label">Sys Agents</div><div class="kpi-val" style="color:var(--text2)">${LAUNCH_AGENTS_SYS}</div><div class="kpi-sub">LaunchAgents sistema</div></div>
  <div class="kpi"><div class="kpi-label">Daemons</div><div class="kpi-val" style="color:var(--text2)">${LAUNCH_DAEMONS}</div><div class="kpi-sub">LaunchDaemons</div></div>
</div>

<div class="section-title">Sicurezza</div>
<div class="security-grid">
  <div class="security-item"><span class="label">FileVault</span><span class="badge ${FV_CLASS}">${FILEVAULT}</span></div>
  <div class="security-item"><span class="label">Firewall</span><span class="badge ${FW_CLASS}">${FIREWALL_STATUS}</span></div>
  <div class="security-item"><span class="label">Gatekeeper</span><span class="badge ${GK_CLASS}">${GATEKEEPER}</span></div>
  <div class="security-item"><span class="label">SIP</span><span class="badge ${SIP_CLASS}">${SIP}</span></div>
  <div class="security-item"><span class="label">Aggiornamenti</span><span class="badge ${UPD_CLASS}">${UPD_TEXT}</span></div>
</div>

<div class="section-title">Spazio &amp; Cache</div>
<div class="cards-grid">
  <div class="card"><div class="card-label">Cache Utente</div><div class="card-value" style="font-size:26px;color:var(--accent3)">${CACHE_USER}</div><div class="card-sub">~/Library/Caches</div></div>
  <div class="card"><div class="card-label">Cache Sistema</div><div class="card-value" style="font-size:26px;color:var(--accent3)">${CACHE_SYS}</div><div class="card-sub">/Library/Caches</div></div>
  <div class="card"><div class="card-label">Log Utente</div><div class="card-value" style="font-size:26px;color:var(--text2)">${LOGS_SIZE}</div><div class="card-sub">~/Library/Logs</div></div>
  <div class="card"><div class="card-label">Temp /tmp</div><div class="card-value" style="font-size:26px;color:var(--text2)">${TMP_SIZE}</div><div class="card-sub">/tmp</div></div>
  <div class="card"><div class="card-label">Desktop</div><div class="card-value" style="font-size:26px">${DESKTOP_SIZE}</div></div>
  <div class="card"><div class="card-label">Downloads</div><div class="card-value" style="font-size:26px">${DOWNLOADS_SIZE}</div></div>
  <div class="card"><div class="card-label">Documents</div><div class="card-value" style="font-size:26px">${DOCUMENTS_SIZE}</div></div>
</div>

<div class="section-title">Cartelle più pesanti in Home</div>
<div class="card" style="padding:0;overflow:hidden">
  <table class="data-table">
    <thead><tr><th>Cartella</th><th style="text-align:right">Dimensione</th></tr></thead>
    <tbody>${FOLDER_ROWS}</tbody>
  </table>
</div>

<div class="section-title">Processi attivi</div>
<div class="cards-grid-3">
  <div class="card" style="padding:0;overflow:hidden">
    <div style="padding:16px 16px 10px;font-size:11px;font-weight:700;letter-spacing:.1em;text-transform:uppercase;color:var(--text2);font-family:var(--mono)">Top CPU</div>
    <table class="data-table">
      <thead><tr><th>Processo</th><th>Uso</th><th style="text-align:right">%CPU</th><th style="text-align:right">%MEM</th></tr></thead>
      <tbody>${CPU_TABLE_ROWS}</tbody>
    </table>
  </div>
  <div class="card" style="padding:0;overflow:hidden">
    <div style="padding:16px 16px 10px;font-size:11px;font-weight:700;letter-spacing:.1em;text-transform:uppercase;color:var(--text2);font-family:var(--mono)">Top RAM</div>
    <table class="data-table">
      <thead><tr><th>Processo</th><th>Uso</th><th style="text-align:right">%MEM</th><th style="text-align:right">%CPU</th></tr></thead>
      <tbody>${MEM_TABLE_ROWS}</tbody>
    </table>
  </div>
</div>

<div class="section-title">Applicazioni installate</div>
<div class="cards-grid-3">
  <div class="card" style="padding:0;overflow:hidden">
    <div style="padding:16px 16px 10px;font-size:11px;font-weight:700;letter-spacing:.1em;text-transform:uppercase;color:var(--text2);font-family:var(--mono)">Top per dimensione</div>
    <table class="data-table">
      <thead><tr><th>App</th><th style="text-align:right">Dim.</th></tr></thead>
      <tbody>${APP_TABLE_ROWS}</tbody>
    </table>
  </div>
  <div class="card">
    <div class="card-label" style="margin-bottom:14px">Mac App Store (${APP_STORE_COUNT})</div>
    <div class="tags-wrap">${APP_STORE_HTML}</div>
  </div>
</div>

<div class="section-title">Homebrew</div>
${BREW_SECTION}

<div class="section-title">Modelli AI locali</div>
<div class="cards-grid">
  <div class="card">
    <div class="card-label">Ollama</div>
    <div class="card-value" style="font-size:22px;color:var(--accent)">${OLLAMA_SIZE}</div>
    <div style="margin-top:10px;display:flex;flex-wrap:wrap;gap:6px">${OLLAMA_TAGS}</div>
  </div>
  <div class="card">
    <div class="card-label">LM Studio</div>
    <div class="card-value" style="font-size:22px;color:var(--accent2)">${LMS_SIZE}</div>
    <div class="card-sub">~/.cache/lm-studio</div>
  </div>
</div>

<div class="section-title">Docker</div>
${DOCKER_SECTION}

</div>

<div class="footer">
  MAC MAINTENANCE REPORT &nbsp;·&nbsp; ${REPORT_DATE} &nbsp;·&nbsp; ${HOSTNAME_STR}
</div>
</body>
</html>
HTML_END

echo ""
echo "✅ Report HTML completato!"
echo "📄 Apri nel browser: $OUTPUT_HTML"
open "$OUTPUT_HTML" 2>/dev/null || true
