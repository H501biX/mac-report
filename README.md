# 🖥️ mac-report

> 🇮🇹 **Maintenance report visuale per macOS** — genera una dashboard HTML con hardware, app installate e stato del sistema, direttamente da terminale. Nessun dato personale, nessuna dipendenza esterna.
>
> 🇬🇧 **Visual maintenance report for macOS** — generates an HTML dashboard with hardware specs, installed apps and system status, straight from the terminal. No personal data, no external dependencies.

![macOS](https://img.shields.io/badge/macOS-12%2B-000000?style=flat-square&logo=apple&logoColor=white)
![Shell](https://img.shields.io/badge/Shell-Bash%203.x%2B-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white)
![Intel + Apple Silicon](https://img.shields.io/badge/Arch-Intel%20%7C%20Apple%20Silicon-7c6dfa?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)
![Dependencies](https://img.shields.io/badge/Dependencies-Zero-4ade80?style=flat-square)

---

## 📸 Preview

```
╔══════════════════════════════════════════════════════════════╗
║            MacBook Air 15" M3 / Apple Silicon                ║
║  ──────────────────────────────────────────────────────────  ║
║       Hardware · Sicurezza · Spazio · App installate         ║
║  Tipo installazione: 🛍️ App Store · 🍺 Homebrew · 🌐 Web      ║
╚══════════════════════════════════════════════════════════════╝
```

🇮🇹 Il report si apre automaticamente nel browser dopo l'esecuzione.  
🇬🇧 The report opens automatically in your browser after running.

---

## ✨ Cosa include / What's included

### 🔵 Hardware

🇮🇹
- **Disco** — gauge circolare con % utilizzo, spazio libero/usato e tabella di tutti i volumi montati
- **RAM** — utilizzo totale con dettaglio Wired e Compressed memory
- **CPU** — chip, core logici e fisici, architettura (Intel / Apple Silicon)
- **GPU** — modello e VRAM (su Apple Silicon: Unified Memory)
- **Batteria** — cicli, condizione e capacità massima *(solo su portatili)*

🇬🇧
- **Disk** — circular gauge with usage %, free/used space and a table of all mounted volumes
- **RAM** — total usage with Wired and Compressed memory breakdown
- **CPU** — chip, logical and physical cores, architecture (Intel / Apple Silicon)
- **GPU** — model and VRAM (on Apple Silicon: Unified Memory)
- **Battery** — cycle count, condition and maximum capacity *(laptops only)*

---

### 🟢 Sicurezza / Security

🇮🇹 Badge colorati (verde/giallo/rosso) per lo stato di:
🇬🇧 Color-coded badges (green/yellow/red) for the status of:

- **FileVault** — 🇮🇹 cifratura disco / 🇬🇧 disk encryption
- **Firewall**
- **Gatekeeper** — 🇮🇹 verifica app / 🇬🇧 app verification
- **SIP** — System Integrity Protection
- 🇮🇹 **Aggiornamenti** macOS / 🇬🇧 macOS **Updates**

---

### 🟡 Spazio & Cache / Storage & Cache

🇮🇹 Dimensione di Cache utente, Cache sistema, Log, Desktop, Downloads, Documents, e top 15 cartelle più pesanti in home.

🇬🇧 Size of user cache, system cache, logs, Desktop, Downloads, Documents, and top 15 heaviest folders in home directory.

---

### 🔴 App installate con tipo di installazione / Installed apps with install type

🇮🇹 Ogni app viene classificata automaticamente con un badge che indica come è stata installata:

🇬🇧 Every app is automatically classified with a badge indicating how it was installed:

| Badge | 🇮🇹 Significato | 🇬🇧 Meaning |
|---|---|---|
| 🛍️ **App Store** | 🇮🇹 Installata da Mac App Store, aggiornata da Apple | 🇬🇧 Installed from Mac App Store, updated by Apple |
| 🍺 **Homebrew** | 🇮🇹 Installata via Homebrew Cask, aggiornabile con `brew upgrade` | 🇬🇧 Installed via Homebrew Cask, updatable with `brew upgrade` |
| 🌐 **Manuale / Web** | 🇮🇹 Scaricata dal sito del produttore o installata manualmente | 🇬🇧 Downloaded from the developer's website or installed manually |

🇮🇹 La tabella mostra tutte le app ordinate per dimensione con un riepilogo numerico per tipo.  
🇬🇧 The table shows all apps sorted by size with a numeric summary per type.

---

### 🟣 Homebrew *(se installato / if installed)*

🇮🇹 Mostra cask, formula CLI installate e pacchetti da aggiornare. La sezione appare **solo se Homebrew è presente** sul sistema.

🇬🇧 Shows installed casks, CLI formulae and outdated packages. The section appears **only if Homebrew is installed** on the system.

---

## 🚀 Installazione & uso / Installation & Usage

### 🇮🇹 Metodo rapido (una riga) / 🇬🇧 Quick method (one line)

```bash
curl -O https://raw.githubusercontent.com/H501biX/mac-report/main/mac_report.sh && chmod +x mac_report.sh && ./mac_report.sh
```

### 🇮🇹 Manuale / 🇬🇧 Manual

```bash
# Clone
git clone https://github.com/H501biX/mac-report.git
cd mac-report

# Make executable
chmod +x mac_report.sh

# Run
./mac_report.sh
```

🇮🇹 Il report HTML viene salvato sul **Desktop** come `mac_report_YYYYMMDD_HHMMSS.html` e si apre automaticamente nel browser.

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
| Bash 3.x (default macOS) | ✅ 🇮🇹 Compatibile / 🇬🇧 Compatible |
| Homebrew *(opzionale / optional)* | ✅ 🇮🇹 Rilevato automaticamente / 🇬🇧 Auto-detected |
| Mac desktop (senza batteria) | ✅ 🇮🇹 Sezione batteria nascosta / 🇬🇧 Battery section hidden |

---

## 📦 Requisiti / Requirements

🇮🇹 **Nessuna dipendenza esterna.** Lo script usa esclusivamente strumenti nativi macOS, compatibile con bash 3.x (la versione pre-installata su tutti i Mac).

🇬🇧 **No external dependencies.** The script uses only native macOS tools, compatible with bash 3.x (the version pre-installed on all Macs).

- `bash` 3.x+ (pre-installed)
- `system_profiler`, `sw_vers`, `vm_stat`, `pmset`
- `df`, `du`, `mdfind`, `softwareupdate`
- `fdesetup`, `spctl`, `csrutil`

---

## 🔒 Privacy / Privacy

🇮🇹
- ✅ Nessun numero seriale o dato identificativo personale
- ✅ Nessun dato inviato in rete — il report è un file locale
- ✅ Nessun processo in tempo reale monitorato
- ✅ Nessun account, login o telemetry
- ✅ Codice sorgente completamente leggibile e verificabile

🇬🇧
- ✅ No serial number or personal identifying data
- ✅ No data sent over the network — the report is a local file
- ✅ No real-time process monitoring
- ✅ No accounts, login or telemetry
- ✅ Source code fully readable and auditable

---

## 🗂️ Struttura repo / Repository Structure

```
mac-report/
├── mac_report.sh   # 🇮🇹 Script principale / 🇬🇧 Main script
├── README.md       # 🇮🇹 Questa pagina / 🇬🇧 This page
├── LICENSE         # MIT License
└── .gitignore      # 🇮🇹 Esclude i report generati / 🇬🇧 Excludes generated reports
```

---

## 🤝 Contribuire / Contributing

🇮🇹 Pull request, issue e suggerimenti sono benvenuti!  
🇬🇧 Pull requests, issues and suggestions are welcome!

1. Fork the repo
2. `git checkout -b feature/my-improvement`
3. `git commit -m 'Add: my improvement'`
4. `git push origin feature/my-improvement`
5. 🇮🇹 Apri una Pull Request / 🇬🇧 Open a Pull Request

---

## 📄 Licenza / License

🇮🇹 Distribuito sotto licenza **MIT**. Vedi [`LICENSE`](LICENSE) per i dettagli.  
🇬🇧 Distributed under the **MIT** License. See [`LICENSE`](LICENSE) for details.

---

<div align="center">
  🇮🇹 Fatto con ☕ e terminale — per sapere davvero cosa c'è sul tuo Mac.<br>
  🇬🇧 Made with ☕ and terminal — to truly know what's on your Mac.
</div>
