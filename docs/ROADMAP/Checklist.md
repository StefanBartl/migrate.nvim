# Lua/Neovim Master-Checklist — Audit für migrate.nvim

> Anwendung der [`regeln/`](../../../WKDBooks/Development/wkdbook-Lua/Checklists/regeln/)
> auf migrate.nvim. Die umfangreichen Kapitel zu **Sortier-/Such-Algorithmen,
> Datenstrukturen (Bäume/Heaps/Filter/Tries) und Bit-Operationen** sind für ein
> zeilenbasiertes Migrations-Plugin **n/a** (siehe Ende). Fokus hier:
> Schnell-Check, PR-Review, Coding-Checkliste, Anti-Patterns, Struktur.

> The source checklists (`Arch&Coding-Regeln.md`, `Checklist.md`,
> `Zentrale-Prinzipien.md`) were retired: they were absorbed into the rule
> collection under `WKDBooks/Development/wkdbook-Lua/Checklists/`, which is
> now the canonical one. The links above point there.


Legende: ✅ · ⚠️ bewusste Abweichung/offen · n/a

## Schnell-Check (10 Punkte, vor jedem Merge)

| Prüfschritt | Prio | Status | Beleg |
| --- | --- | --- | --- |
| Fehlerbehandlung (pcall, keine stillen Fehler) | 🔴 | ✅ | `pcall` um alle Buffer-/Datei-Mutationen (`buffer.lua`, `refactor/write.lua`, `refactor/apply.lua`). |
| Type Guards (type/nil vor API) | 🔴 | ⚠️ | Buffer-Handles konsequent via `nvim_buf_is_valid` geprüft; feinere Feld-Guards an rein internen Schnittstellen (`picker.show(matches, opts)`) fehlen — niedriges Risiko. |
| Buffer/Window validieren | 🔴 | ✅ | 14 Stellen mit `nvim_buf_is_valid`; keine eigenen Fenster (Telescope verwaltet seins). |
| Keine globalen States | 🔴 | ✅ | Einziger State: `migrate.config.options`-Singleton, nur via `config.get()`. |
| Single Responsibility | 🔴 | ✅ | `opt.migrator` (Rewrite), `notify.parser.*` (Erkennung), `notify.refactor.*` (Anwendung), `common.*` (geteilte Infrastruktur), `bindings.*`. |
| UI-Cleanup | 🟡 | n/a | Kein eigenes UI/Fenster zu bereinigen (Telescope-Picker). |
| Performance-Hotspots (concat/reserve) | 🟡 | ✅ | `table.concat` bei Multiline-Migration; gebündelte `batch_write` statt Einzel-Writes. |
| Annotationen vollständig | 🟡 | ✅ | `@module/@brief/@description` + `@param/@return`; Aliase in `@types/init.lua` + `common/@types.lua`. |
| Testbarkeit (pure functions) | 🟡 | ✅ | `opt.migrator`, `notify.parser.*` sind rein; `TESTS/`-Suite deckt sie ab. |
| Import-Reihenfolge | 🟢 | ✅ | Kern/Config → Feature-Module → Bindings (z. B. `opt/init.lua`: common.* → opt.migrator → lib.nvim.notify). |

### Bonuspunkt: `lib`-Modul nutzen — ✅

`lib.nvim.notify` (Kommando-/UI-Schicht) und `lib.nvim.bindings.keymap` (optionale
Keymaps) werden genutzt — als **harte**, nicht soft, Dependency (siehe
`health.lua`). `lib.nvim.bindings.usercmd.composer` wird seit
`8d26139` (`refactor(usrcmds): migrate :MigrateOpt/:MigrateNotify to
lib.nvim.bindings.usercmd.composer`) für alle Commands genutzt (`common/command.lua`,
`notify/init.lua`) — kein rohes `nvim_create_user_command` mehr im Code.
`lib.cross`/`memo`/`lazy` (Top-Level): migrate.nvim braucht sie nicht (schon
cross-platform durch Pfadnormalisierung; kein Memoization-Bedarf); `lib.lua.lazy`
(submodule-lazy-require) wird in `notify/init.lua` tatsächlich genutzt.

## PR-Review-Checkliste

### 1. Sicherheit & Fehlerbehandlung — ✅ / ⚠️
- pcall/Guards/explizite Rückgaben/kein Low-Level-notify: ✅
- `safe_call`-Envelope + strukturierte Fehlertypen: ⚠️ bewusst nicht — `(ok, err)`-Tupel/`pcall` reicht für den synchronen Scope.

### 2. Modularität & Struktur — ✅
- SRP ✅, keine Globals ✅, reine Funktionen ✅ (Parser/Migrator), interne Helfer lokal ✅.
- Tools/Registry: ✅ `lua/migrate/registry.lua` (seit `b6aa043`) — alle vier
  Module (`opt`/`notify`/`hl`/`lsp`) sind `M.register()`-Einträge; `config`,
  `bindings`, `health` und `init.enable_all()`/`disable_all()` iterieren die
  Registry statt Module namentlich zu verdrahten. Dokumentiert in
  [`docs/FEATURES.md`](../FEATURES.md#pluggable-migration-registry).
- `/config`-Ordner mit `DEFAULTS.lua`: ✅ (`config/{init,DEFAULTS}.lua`).

### 3. Buffer-/Window-Management — ✅ (Fenster n/a)
- Handle-zuerst-binden + `nvim_buf_is_valid` vor jedem Zugriff ✅.
- Race Conditions / Defer-Revalidierung: ✅ — `refactor/write.lua`'s `write_async` prüft den Buffer in jedem `vim.schedule`-Callback erneut.

### 4. UI-State-Management — n/a
Kein eigener UI-State (Telescope verwaltet Picker-Fenster und -Zustand selbst).

### 5. Dokumentation & Annotationen — ✅
Kopf-Tags ✅, Funktions-Tags ✅, Aliase/Felder in `@types` ✅. `/config`-Eintrag im
PR-Review-Kapitel selbst schon oben unter Punkt 2 bestätigt. `@see`-Querverweise
zwischen `registry`/`init`/`config.DEFAULTS`/`common.command` und den vier
Migrationsmodulen (`opt`/`notify`/`hl`/`lsp`) sowie `bindings.usrcmds`/`health`
ergänzt.

### 6. Testbarkeit und Lesbarkeit — ✅
DI: Config wird als `opts` durchgereicht, kein Hard-Wiring ✅. Pure Functions ✅
(extra für Testbarkeit aus `opt/init.lua` extrahiert). Test-Entry `TESTS/run.lua` ✅.

### 7. Tooling — ✅
- Lua LS: `.luarc.json` vorhanden (`diagnostics.globals=vim`, `workspace.library`) ✅.
- Formatter/Linter im CI: ✅ `.github/workflows/ci.yml` (seit `a1189a4`) läuft
  `stylua --check`, `luacheck` und den headless `TESTS/run.lua`-Suite auf
  jedem Push/PR gegen `main`. Badge im README.

## Coding-Checkliste

- **A. Strings & Tabellen** — ✅ kein Concat im Loop (`table.concat` bei Multiline-Migration). Inline-Reserve/`t[i]` nicht nötig (keine großen, vorab-bekannten Arrays).
- **B. Performance-Quickwins** — ✅ Async-Write via `vim.uv`/`vim.loop` (`refactor/write.write_async`) für `cwd`-Batch-Writes; Memoization n/a (keine teuren Wiederholungsberechnungen).
- **C. Neovim-API sicher** — ✅ Guards durchgängig; Deferred Calls revalidieren (siehe oben).
- **D. State-/Datenmodelle** — Getter via `config.get()`; Metatables/FIFO n/a (funktionaler Stil).
- **E. GC bewusst steuern** — n/a (keine großen Objekte/Coroutinen).
- **F. Lazy-Loading** — ✅ empfohlene Installation `cmd = {...}`; `bindings.usrcmds.setup` requiret `opt`/`notify` nur bei aktivierter Config; `notify/init.lua` nutzt `lib.lua.lazy` für seine Submodule.

## Anti-Pattern-Check — ✅
Kein globaler State ✅, keine API ohne Guards (bis auf die o. g. Feinheiten) ✅,
kein String-Concat im Loop ✅, keine Closures im Hot-Loop (kein Hot-Loop
vorhanden) ✅, keine Flut kleiner Temp-Tabellen ✅.

## Import- & Dateistruktur-Check — ✅ (1 bewusste Abweichung)
Import-Reihenfolge ✅, Datei-Header ✅. Projektweiter `@types`-Ordner: ⚠️
bewusste Abweichung — nur 2 zentrale Typ-Dateien (`@types/init.lua`,
`common/@types.lua`) statt eines `/types`-Ankers pro Subverzeichnis (siehe
[Arch&Coding.md](Arch&Coding.md) §5). Auch nach dem Zuwachs auf vier
Migrationsmodule (`opt`/`notify`/`hl`/`lsp`) hat keines eigene, subdir-lokale
Typen jenseits dessen, was die zwei zentralen Dateien schon abdecken — ein
`/types`-Ordner pro Subdir wäre reine Formalie ohne zusätzlichen Typinhalt.
Endgültig als Abweichung übernommen, nicht mehr als offener Punkt geführt.

## Performance-Spickzettel — ✅ / n/a
Gebündelte Writes (`batch_write`) ✅; async I/O via `vim.uv` ✅. Weak-Caches,
Debounce: n/a für den synchronen, kommandogetriebenen Scope (kein
wiederholtes Schreiben desselben Buffers in kurzer Zeit).

## Sort / Datenstrukturen / Bit-Ops — n/a
migrate.nvim implementiert **keine** eigenen Bäume, Heaps, Filter, Tries,
Sortier- oder Bit-Trick-Algorithmen. Die einzige "Datenstruktur"-Arbeit ist
Klammernzählung zur Multiline-Erkennung (`extractor.find_call_end`) — ein
simpler Zähler, kein Datenstruktur-Kapitel-relevanter Algorithmus.

## Reviewer-Notizen

| Bereich | Beobachtung | Empfehlung |
| --- | --- | --- |
| Sicherheit | pcall + Guards durchgängig, keine stillen Fehler | keine |
| Modularität | SRP, keine Globals, funktional; `migrate.registry` für alle 4 Module | keine |
| Neovim-API | Buffer-Guards + Re-Validierung in async Callbacks | keine |
| Performance | gebündelte/async Writes, keine Hot-Loops | keine |
| Doku/Annotation | `@see`-Querverweise ergänzt; 2 `@types`-Dateien bleiben bewusste Abweichung | keine |
| Tests | `TESTS/` Suite grün (4 Specs: opt/notify/hl/lsp) | mehr Randfälle weiterhin denkbar (String-Literal-Notify, Multiline-Aliase) |
| Tooling/CI | `.github/workflows/ci.yml` (stylua/luacheck/headless Tests) | keine |
| checkhealth-Modul? | ✅ `:checkhealth migrate` (Deps/Config/which-key) | keine |

---

## Fazit & Plan

migrate.nvim erfüllt die Master-Checklist inzwischen vollständig. Die vier
ursprünglich offenen Punkte sind alle nachgezogen:

1. ~~Kein CI-Workflow~~ → `.github/workflows/ci.yml` (`a1189a4`).
2. ~~`lib.nvim.bindings.usercmd` nicht genutzt~~ → `lib.nvim.bindings.usercmd.composer`
   durchgängig (`8d26139`).
3. ~~Kein Registry-Pattern~~ → `lua/migrate/registry.lua` (`b6aa043`), inzwischen
   4 Module (`opt`/`notify`/`hl`/`lsp`).
4. ~~Kein `@see`~~ → Querverweise ergänzt. Die 2 zentralen `@types`-Dateien
   (statt Pro-Subdir-Anker) bleiben eine bewusste, dokumentierte Abweichung —
   siehe Import- & Dateistruktur-Check oben.

**Bewusste Abweichungen (kein Handlungsbedarf):** kein `safe_call`-Envelope,
funktionaler Stil statt Metatables, README englisch (publiziertes Plugin,
kein Config-Modul), 2 zentrale `@types`-Dateien statt Pro-Subdir-Anker.

## Literatur und Referenzen

- [Arch&Coding.md](./Arch&Coding.md) · [Zentral-Prinzipien.md](./Zentral-Prinzipien.md)
- Quell-Checklisten: `../../../WKDBooks/Development/wkdbook-Lua/Checklists/`
