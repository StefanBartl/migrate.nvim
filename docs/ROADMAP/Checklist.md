# Checklist – Nvim Plugins & Config (migrate.nvim audit)

Copy of the personal master checklist
(`nvim/docs/ROADMAP/personal/MATERIALS/CHECKLIST.md`), applied to
`migrate.nvim`. Checked items are done; notes explain deviations.

---

## 1. Module & Plugins durchgehen

- [x] **CHEATSHEETS** schreiben:
    - [x] Repo hat eine eigene `/docs/BINDINGS.md` mit:
      - [x] allen Keymaps (none by default; the optional, user-configurable ones are documented)
      - [x] allen Usrcmds
      - [x] allen Autocmds (none exist — documented as such)
- [x] alle Keymaps müssen
  - [x] vom user einfach modifizierbar / deaktiviert werden können (`config.keymaps = false` by default, or `{ opt = ..., notify = ... }`)
  - [x] eine which-key implementierung haben (`lua/migrate/bindings/which_key.lua` — soft dependency; individual `desc`s are picked up by which-key automatically, no fixed prefix to register as a group)
- [x] Die meisten Features (sinnvoll) default aktiv stellen — `opt` and `notify` both default to `true`; only the ideal-spec `opts = {}` install form applies here (no `dir = vim.env...`, no license refs)
- [x] `/docs/ROADMAP.md` erstellt
- [x] `README.md` überprüft:
  - [x] Badges & ASCII implementiert
  - [x] Englisch (README + doc/migrate.txt)
  - [x] Kurzer `>` Absatz nach der ascii-art, verlinkt zu `recommender.nvim`

---

## 2. README & Doc-Spec anpassen

- [x] `README.md` && `/doc/**.txt` an Spec angepasst:
  - [x] Installationsweise für lazy.nvim / packer.nvim / vim-plug dokumentiert
  - [x] `cmd = {...}` (lazy) **oder** `lazy = false` explizit angegeben
  - [x] Kein `dir = vim.env...` in den READMEs
  - [x] Keine Lizenzverweise

---

## 3. Tests

- [x] `docs/TESTS/**` geschrieben — covers `migrate.opt.migrator` (extracted for
  testability) and `migrate.notify.parser.*`. `migrate.opt`/`migrate.notify`/
  `migrate.common.*` hard-require `lib.nvim`/`telescope.nvim` and stay out of
  the headless suite (documented in `docs/TESTS/README.md`).

---

## 4. Healthchecks & Config-Struktur

- [x] `:checkhealth migrate` unterstützt (pre-existing; extended to report
  config + which-key status)
  - [x] `/config`-Ordner mit `config/DEFAULTS.lua` + `config/init.lua` angelegt
  - [x] `lib.nvim` als (required) Dependency genutzt (`lib.nvim.notify`, `lib.nvim.map`)
  - [ ] Prüfen: Sind alle Plugins `lazy`? — N/A hier: das betrifft die
    konsumierende nvim-Config, nicht dieses Repo selbst.
  - [x] `/bindings`-Ordner angelegt mit `usrcmds`, `keymaps`, `which_key`
        (kein separates `autocmds.lua` — migrate.nvim definiert keine
        Autocmds; eine leere Datei nur für Formkonsistenz wurde bewusst
        weggelassen, siehe `docs/BINDINGS.md`)
  - [ ] `docs/TESTS/**` in `:checkhealth` ausführen — bewusst weggelassen
    (nicht state of the art, siehe cascade.nvim-Präzedenzfall)

---

## 5. Cross-Plattform

- [x] Auf Cross-Plattform abgeklopft: Pfadnormalisierung (`\` -> `/`) in
  `notify/init.lua`, `rg` via argv-Liste (kein Shell-String) in `opt/init.lua`,
  Datei-I/O über `vim.uv`/`vim.fn`. Keine Änderungen nötig.

---

## 6. Defaults-Struktur

- [x] `config/init.lua` && `config/DEFAULTS.lua` angelegt

---

## 7. User-seitige Konfigurierbarkeit

- [x] `config/init.lua` & `config/DEFAULTS.lua` für pluginseitige Defaults angelegt
- [x] Konfigurierbare Optionen: `opt`, `notify`, `keymaps` (mit `opt`/`notify` Sub-Keys)
- [x] Jeder Key hat einen Typ (`@types/init.lua`: `UsrCmds.Migrate.Config`, `UsrCmds.Migrate.Keymaps`)
- [x] Abgeklopft: keine weiteren sinnvollen User-Optionen offen (die
  eigentliche Migrations-Logik — Patterns/Level-Mappings — ist bewusst nicht
  konfigurierbar, siehe `docs/Regex-statt-TS.md`)

---

## 9. Which-Key

- [x] Mappings unterstützen `which-key` (siehe Punkt 1)

---

## 10. Git

- [x] Alles committen (siehe Commit-Message im Log)
- [x] Branch ist bereits `main`
