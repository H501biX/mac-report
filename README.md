# 🖥️ mac-report

> 🇮🇹 **Maintenance report visuale per macOS** — genera una dashboard HTML interattiva con grafici, metriche di sistema e analisi completa del tuo Mac, direttamente da terminale.
>
> 🇬🇧 **Visual maintenance report for macOS** — generates an interactive HTML dashboard with charts, system metrics and a full analysis of your Mac, straight from the terminal.

![macOS](https://img.shields.io/badge/macOS-12%2B-000000?style=flat-square&logo=apple&logoColor=white)
![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white)
![Intel + Apple Silicon](https://img.shields.io/badge/Arch-Intel%20%7C%20Apple%20Silicon-7c6dfa?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)
![Dependencies](https://img.shields.io/badge/Dependencies-Zero-4ade80?style=flat-square)

---

## 📸 Preview

```
╔══════════════════════════════════════════════════════════╗
║  Mac Report Dashboard — Dark UI con grafici e metriche  ║
║  Disco · RAM · Batteria · Sicurezza · Processi · App    ║
╚══════════════════════════════════════════════════════════╝
```

🇮🇹 Il report si apre automaticamente nel browser dopo l'esecuzione.
🇬🇧 The report opens automatically in your browser after running.

---

## ✨ Cosa include / What's included

### 🔵 Risorse di sistema / System Resources

🇮🇹
- **Disco** — gauge circolare SVG con % utilizzo e spazio libero/usato. Colore dinamico (verde → giallo → rosso).
- **RAM** — utilizzo percentuale con dettaglio Wired, Inactive e Compressed memory.
- **Batteria** — percentuale di carica, cicli, condizione e capacità massima.
- **CPU** — core logici e fisici, architettura, numero seriale.

🇬🇧
- **Disk** — SVG circular gauge showing usage % and free/used space. Dynamic color coding (green → yellow → red).
- **RAM** — percentage usage with breakdown of Wired, Inactive and Compressed memory.
- **Battery** — charge level, cycle count, condition and maximum capacity.
- **CPU** — logical and physical cores, architecture, serial number.

---

### 🟢 Sicurezza / Security

🇮🇹 Badge colorati per lo stato di:
🇬🇧 Colored badges for the status of:

- **FileVault** — 🇮🇹 cifratura disco / 🇬🇧 disk encryption
- **Firewall**
- **Gatekeeper** — 🇮🇹 verifica app / 🇬🇧 app verification
- **SIP** — System Integrity Protection
- 🇮🇹 **Aggiornamenti** macOS disponibili / 🇬🇧 Available macOS **updates**

---

### 🟡 Spazio & Cache / Storage & Cache

🇮🇹
- Cache utente (`~/Library/Caches`) e di sistema (`/Library/Caches`)
- Log utente, file temporanei `/tmp`
- Dimensione di Desktop, Downloads, Documents
- Top 12 cartelle più pesanti in home

🇬🇧
- User cache (`~/Library/Caches`) and system cache (`/Library/Caches`)
- User logs, temporary files `/tmp`
- Size of Desktop, Downloads, Documents
- Top 12 heaviest folders in home directory

---

### 🟣 Processi attivi / Active Processes

- 🇮🇹 Top 10 per **CPU** con barra proporzionale / 🇬🇧 Top 10 by **CPU** with proportional bar
- 🇮🇹 Top 10 per **RAM** con barra proporzionale / 🇬🇧 Top 10 by **RAM** with proportional bar

---

### 🔴 App & Software

🇮🇹
- App in `/Applications` ordinate per dimensione
- App installate dal **Mac App Store**
- **Homebrew**: cask, formula, pacchetti da aggiornare
- Modelli **AI locali**: Ollama e LM Studio
- **Docker**: immagini, container, stato

🇬🇧
- Apps in `/Applications` sorted by size
- Apps installed from the **Mac App Store**
- **Homebrew**: casks, formulae, outdated packages
- Local **AI models**: Ollama and LM Studio
- **Docker**: images, containers, running status

---

### 🌐 Rete & Sistema / Network & System

- 🇮🇹 Uptime, IP locale, SSID Wi-Fi / 🇬🇧 Uptime, local IP, Wi-Fi SSID
- 🇮🇹 LaunchAgents e LaunchDaemons attivi / 🇬🇧 Active LaunchAgents and LaunchDaemons

---

## 🚀 Installazione & uso / Installation & Usage

### 🇮🇹 Metodo rapido (una riga) / 🇬🇧 Quick method (one line)

```bash
curl -O https://raw.githubusercontent.com/H501biX/mac-report/main/mac_report.sh && chmod +x mac_report.sh && ./mac_report.sh
```

### 🇮🇹 Manuale / 🇬🇧 Manual

```bash
# 🇮🇹 1. Clona la repo / 🇬🇧 Clone the repo
git clone https://github.com/H501biX/mac-report.git
cd mac-report

# 🇮🇹 2. Rendi eseguibile / 🇬🇧 Make executable
chmod +x mac_report.sh

# 🇮🇹 3. Esegui / 🇬🇧 Run
./mac_report.sh
```

🇮🇹 Il report HTML viene salvato sul **Desktop** con nome `mac_report_YYYYMMDD_HHMMSS.html` e si apre automaticamente nel browser predefinito.

🇬🇧 The HTML report is saved to your **Desktop** as `mac_report_YYYYMMDD_HHMMSS.html` and opens automatically in your default browser.

---

## 🔧 Compatibilità / Compatibility

| Configurazione / Configuration | Supporto / Support |
|---|---|
| Apple Silicon (M1, M2, M3, M4…) | ✅ Full |
| Intel (Core i5, i7, i9…) | ✅ Full |
| macOS 12 Monterey | ✅ |
| macOS 13 Ventura | ✅ |
| macOS 14 Sonoma | ✅ |
| macOS 15 Sequoia | ✅ |
| Homebrew (opzionale / optional) | ✅ 🇮🇹 Rilevato automaticamente / 🇬🇧 Auto-detected |
| Docker (opzionale / optional) | ✅ 🇮🇹 Rilevato automaticamente / 🇬🇧 Auto-detected |
| Ollama / LM Studio (opzionale / optional) | ✅ 🇮🇹 Rilevato automaticamente / 🇬🇧 Auto-detected |

---

## 📦 Requisiti / Requirements

🇮🇹 **Nessuna dipendenza esterna.** Lo script usa esclusivamente strumenti nativi macOS.

🇬🇧 **No external dependencies.** The script uses only native macOS tools.

- `bash` (pre-installed)
- `system_profiler`, `sw_vers`, `vm_stat`, `pmset`
- `df`, `du`, `ps`, `uptime`
- `fdesetup`, `spctl`, `csrutil`, `softwareupdate`
- `mdfind`, `sfltool`

🇮🇹 Le sezioni Homebrew, Docker, Ollama e LM Studio vengono incluse **solo se i tool sono presenti** sul sistema.

🇬🇧 The Homebrew, Docker, Ollama and LM Studio sections are included **only if those tools are installed** on your system.

---

## 🔒 Privacy & sicurezza / Privacy & Security

🇮🇹
- Lo script **non invia nessun dato** in rete.
- Il report HTML è un file **locale** sul tuo Desktop.
- Nessun account, nessun login, nessun telemetry.
- Il codice sorgente è completamente leggibile e verificabile.

🇬🇧
- The script **sends no data** over the network.
- The HTML report is a **local file** on your Desktop.
- No accounts, no login, no telemetry.
- The source code is fully readable and auditable.

---

## 🗂️ Struttura repo / Repository Structure

```
mac-report/
├── mac_report.sh       # 🇮🇹 Script principale / 🇬🇧 Main script
├── README.md           # 🇮🇹 Questa pagina / 🇬🇧 This page
├── LICENSE             # MIT License
└── .gitignore          # 🇮🇹 Esclude i report generati / 🇬🇧 Excludes generated reports
```

---

## 🤝 Contribuire / Contributing

🇮🇹 Pull request, issue e suggerimenti sono benvenuti!

🇬🇧 Pull requests, issues and suggestions are welcome!

1. 🇮🇹 Fork della repo / 🇬🇧 Fork the repo
2. 🇮🇹 Crea un branch / 🇬🇧 Create a branch — `git checkout -b feature/new-section`
3. 🇮🇹 Fai commit / 🇬🇧 Commit your changes — `git commit -m 'Add section X'`
4. Push — `git push origin feature/new-section`
5. 🇮🇹 Apri una Pull Request / 🇬🇧 Open a Pull Request

---

## 📄 Licenza / License

🇮🇹 Distribuito sotto licenza **MIT**. Vedi [`LICENSE`](LICENSE) per i dettagli.

🇬🇧 Distributed under the **MIT** License. See [`LICENSE`](LICENSE) for details.

---

<div align="center">
  🇮🇹 Fatto con ☕ e terminale — per chi vuole sapere davvero cosa gira sul proprio Mac.<br>
  🇬🇧 Made with ☕ and terminal — for those who really want to know what's running on their Mac.
</div>
