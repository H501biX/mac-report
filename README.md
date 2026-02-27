# 🖥️ mac-report

> **Maintenance report visuale per macOS** — genera una dashboard HTML interattiva con grafici, metriche di sistema e analisi completa del tuo Mac, direttamente da terminale.

![macOS](https://img.shields.io/badge/macOS-12%2B-000000?style=flat-square&logo=apple&logoColor=white)
![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white)
![Intel + Apple Silicon](https://img.shields.io/badge/Arch-Intel%20%7C%20Apple%20Silicon-7c6dfa?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)
![Zero dipendenze](https://img.shields.io/badge/Dipendenze-Zero-4ade80?style=flat-square)

---

## 📸 Preview

```
╔══════════════════════════════════════════════════════════╗
║  Mac Report Dashboard — Dark UI con grafici e metriche  ║
║  Disco · RAM · Batteria · Sicurezza · Processi · App    ║
╚══════════════════════════════════════════════════════════╝
```

Il report si apre automaticamente nel browser dopo l'esecuzione.

---

## ✨ Cosa include

### 🔵 Risorse di sistema
- **Disco** — gauge circolare SVG con % utilizzo e spazio libero/usato. Colore dinamico (verde → giallo → rosso).
- **RAM** — utilizzo percentuale con dettaglio Wired, Inactive e Compressed memory.
- **Batteria** — percentuale di carica, cicli, condizione e capacità massima.
- **CPU** — core logici e fisici, architettura, seriale.

### 🟢 Sicurezza
Badge colorati per lo stato di:
- **FileVault** (cifratura disco)
- **Firewall**
- **Gatekeeper** (verifica app)
- **SIP** — System Integrity Protection
- **Aggiornamenti** macOS disponibili

### 🟡 Spazio & Cache
- Cache utente (`~/Library/Caches`)
- Cache sistema (`/Library/Caches`)
- Log utente, file temporanei `/tmp`
- Dimensione di Desktop, Downloads, Documents
- Top 12 cartelle più pesanti in home

### 🟣 Processi attivi
- Top 10 per **CPU** con barra proporzionale
- Top 10 per **RAM** con barra proporzionale

### 🔴 App & Software
- App in `/Applications` ordinate per dimensione
- App installate dal **Mac App Store**
- **Homebrew**: cask, formula, pacchetti da aggiornare
- Modelli **AI locali**: Ollama e LM Studio
- **Docker**: immagini, container, stato

### 🌐 Rete & Sistema
- Uptime, IP locale, SSID Wi-Fi
- LaunchAgents e LaunchDaemons attivi

---

## 🚀 Installazione & uso

### Metodo rapido (una riga)
```bash
curl -O https://raw.githubusercontent.com/TUO_USERNAME/mac-report/main/mac_report.sh && chmod +x mac_report.sh && ./mac_report.sh
```
> Sostituisci `TUO_USERNAME` con il tuo username GitHub dopo aver fatto il push.

### Manuale
```bash
# 1. Clona la repo
git clone https://github.com/TUO_USERNAME/mac-report.git
cd mac-report

# 2. Rendi eseguibile
chmod +x mac_report.sh

# 3. Esegui
./mac_report.sh
```

Il report HTML viene salvato sul **Desktop** con nome `mac_report_YYYYMMDD_HHMMSS.html` e si apre automaticamente nel browser predefinito.

---

## 🔧 Compatibilità

| Configurazione | Supporto |
|---|---|
| Apple Silicon (M1, M2, M3, M4…) | ✅ Completo |
| Intel (Core i5, i7, i9…) | ✅ Completo |
| macOS 12 Monterey | ✅ |
| macOS 13 Ventura | ✅ |
| macOS 14 Sonoma | ✅ |
| macOS 15 Sequoia | ✅ |
| Homebrew (opzionale) | ✅ Rilevato automaticamente |
| Docker (opzionale) | ✅ Rilevato automaticamente |
| Ollama / LM Studio (opzionale) | ✅ Rilevato automaticamente |

---

## 📦 Requisiti

**Nessuna dipendenza esterna.** Lo script usa esclusivamente strumenti nativi macOS:

- `bash` (pre-installato)
- `system_profiler`, `sw_vers`, `vm_stat`, `pmset`
- `df`, `du`, `ps`, `uptime`
- `fdesetup`, `spctl`, `csrutil`, `softwareupdate`
- `mdfind`, `sfltool`

Le sezioni Homebrew, Docker, Ollama e LM Studio vengono incluse **solo se i tool sono presenti** sul sistema.

---

## 🔒 Privacy & sicurezza

- Lo script **non invia nessun dato** in rete.
- Il report HTML è un file **locale** sul tuo Desktop.
- Nessun account, nessun login, nessun telemetry.
- Il codice sorgente è completamente leggibile e verificabile.

---

## 🗂️ Struttura repo

```
mac-report/
├── mac_report.sh       # Script principale
├── README.md           # Questa pagina
├── LICENSE             # Licenza MIT
└── .gitignore          # Esclude i report generati
```

---

## 🤝 Contribuire

Pull request, issue e suggerimenti sono benvenuti!

1. Fork della repo
2. Crea un branch (`git checkout -b feature/nuova-sezione`)
3. Commit (`git commit -m 'Aggiunge sezione X'`)
4. Push (`git push origin feature/nuova-sezione`)
5. Apri una Pull Request

---

## 📄 Licenza

Distribuito sotto licenza **MIT**. Vedi [`LICENSE`](LICENSE) per i dettagli.

---

<div align="center">
  Fatto con ☕ e terminale — per chi vuole sapere davvero cosa gira sul proprio Mac.
</div>
