# Zentrale Prinzipien — Audit für migrate.nvim

> Anwendung der Checkliste [Zentrale-Prinzipien](file:///E:/repos/Notes/MyNotes/Checklists/Lua/Zentrale-Prinzipien.md)
> auf migrate.nvim. Pro Prinzip: Status + Belege im Code.

Legende: ✅ erfüllt · ⚠️ teilweise / bewusst abgewogen · ❌ offen

## Vorbemerkung: `lib`-Nutzung

Anders als bei einem rein optionalen (soft-dependency) Plugin ist `lib.nvim`
für migrate.nvim eine **harte** Abhängigkeit (siehe `health.lua`: "lib.nvim
not found (required)"). `lib.nvim.notify` wird durchgängig in der
Kommando-/UI-Schicht genutzt, `lib.nvim.map` in den optionalen Keymaps,
`lib.nvim.usercmd.composer` für sämtliche Commands (siehe
[Arch&Coding.md](Arch&Coding.md)). `lib.cross`/`memo`/`lazy`/`hover_select`
sind n/a bzw. durch eigene, einfachere Lösungen abgedeckt (siehe unten).

## 1. Events bündeln, Logik entkoppeln — ✅ (trivial)

migrate.nvim registriert **keine Autocmds** (siehe `docs/BINDINGS.md`) — nur
zwei User-Commands (`:MigrateOpt`, `:MigrateNotify`). Es gibt also keine
Mehrfachbindung an Events, die entkoppelt werden müsste.

## 2. Eigene Logik lazy laden — ✅

- `migrate.bindings.usrcmds.setup(cfg)` requiret `migrate.opt`/`migrate.notify`
  nur, wenn `cfg.opt`/`cfg.notify` aktiv sind (per `pcall(require, ...)`), und
  nur beim `setup()`-Aufruf selbst — nicht beim reinen Laden des Top-Level-Moduls.
- `migrate.notify` requiret seine eigenen Untermodule (`picker`, `buffer_ops`,
  `parser`, `refactor`) über `lib.lua.lazy`, statt sie sofort einzubinden.
- Empfohlene Installation ist `cmd = { "MigrateOpt", "MigrateNotify" }`
  (siehe README) — das eigentliche Scannen/Parsen passiert ohnehin erst bei
  explizitem Kommando-Aufruf, nie beim Start.

## 3. Kontext statt Mehrfach-API-Zugriffe — ✅ (kein dediziertes Context-Objekt nötig)

- Jede Scan-Funktion (`opt.init.scan_range/scan_buffer`, `notify.init.scan_range/scan_buffer`)
  ruft `nvim_buf_get_lines` **genau einmal** pro Aufruf ab und arbeitet danach
  rein auf dem zurückgegebenen Array — keine wiederholten `nvim_buf_get_*`-
  Abfragen für dieselbe Information.
- Ein explizites `Context`-Objekt (wie z. B. bei cascade.nvim) gibt es nicht;
  bei nur zwei simplen Parametern (`bufnr`, Zeilenbereich) pro Aufruf wäre das
  zusätzliche Indirektion ohne Nutzen.

## 4. Autocommand-Gruppen sauber nutzen — n/a

Keine Autocmds registriert (siehe Punkt 1) — nichts zu gruppieren.

## 5. Event oder Command? — ✅ (vorbildlich)

migrate.nvim ist **vollständig kommandogetrieben**: `:MigrateOpt`/`:MigrateNotify`
mit line/range/`%`/`cwd`-Modi. Es gibt keinerlei automatische Ausführung bei
Buffer-Wechsel oder Edit — Migration ist immer eine bewusste Nutzeraktion.
Genau das Prinzip verlangt.

## 6. Treesitter notwendig oder nicht? — ✅

**Kein Treesitter.** Reine Lua-Patterns (`notify/parser/patterns.lua`) plus
Klammernzählung für Mehrzeiler (`notify/parser/extractor.find_call_end`,
`notify/parser/migrator.migrate_multiline`). Das ist keine nachträgliche
Optimierung, sondern eine **bewusste Korrektur**: eine frühere
Treesitter-basierte Implementierung hatte Offset-Korruption bei Mehrfach-
Replacements und String-Slicing-Kollisionen (Treesitters exklusive
`end_col` vs. Luas 1-basiertes String-Indexing) — dokumentiert in
[`docs/Regex-statt-TS.md`](../Regex-statt-TS.md). Der Zeilen-Scan-Ansatz ist
hier also die **robustere**, nicht nur die einfachere Wahl.

## 7. Cache vorhanden und explizit? — n/a

Kein Cache — und bewusst keiner nötig: `notify.init.apply_matches` scannt den
Buffer **unmittelbar vor dem Anwenden erneut** (`parser.scan_buffer(bufnr)`
als `fresh_matches`), statt die ursprünglichen Scan-Ergebnisse
wiederzuverwenden. Das verhindert veraltete Zeilen-Offsets, falls sich der
Buffer zwischen Scan und Apply geändert hat (z. B. durch den Telescope-Picker-
Workflow). Ein Cache wäre hier kontraproduktiv, nicht nur unnötig.

## 8. Allokationen im Hot-Path vermeiden — n/a

migrate.nvim hat **keinen Hot-Path**: nichts läuft bei `CursorMoved`,
`TextChanged` o. ä. — jede Allokation (Match-Tabellen, Picker-Entries)
passiert nur bei explizitem Kommando-Aufruf. Tabellen-Allokationen pro Scan
sind hier unproblematisch.

## 9. Debugbarkeit eingeplant? — ✅

- `:checkhealth migrate` zeigt Modul-/Dependency-/Config-Status inkl.
  which-key-Erkennung.
- Die Testsuite (`docs/TESTS/`) erlaubt isoliertes Testen der reinen
  Parser-/Migrator-Funktionen.
- **Dedizierter Debug-Schalter** — `setup({ debug = true })` +
  `lua/migrate/common/debug.lua` tracen den scan → picker → apply → write
  Pfad über `lib.nvim.notify`'s `.debug()`-Level (siehe
  [`docs/FEATURES.md`](../FEATURES.md#debug-tracing)).

## 10. Laufzeit wichtiger als Startup? — ✅

Kein Code läuft bei `CursorMoved`/`TextChanged`/`BufEnter` — migrate.nvim
tut buchstäblich nichts, bis ein Kommando aufgerufen wird.

---

## Fazit

migrate.nvim erfüllt die zentralen Prinzipien vollständig — die
Kommando-getriebene, Event-freie Architektur entspricht dem Idealbild der
Checkliste besonders gut (Punkte 1, 4, 5, 8, 10 sind praktisch geschenkt,
weil es keine Autocmds/Hot-Paths gibt). Der einzige zuvor offene Punkt, der
Debug-Schalter (Prinzip 9), ist mit `setup({ debug = true })` +
`lua/migrate/common/debug.lua` umgesetzt. Keine offenen Punkte mehr.
