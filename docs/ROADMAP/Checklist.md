# Lua/Neovim Master-Checklist — Audit für migrate.nvim

> Anwendung der [Checklist](file:///E:/repos/Notes/MyNotes/Checklists/Lua/Checklist.md)
> auf migrate.nvim. Die umfangreichen Kapitel zu **Sortier-/Such-Algorithmen,
> Datenstrukturen (Bäume/Heaps/Filter/Tries) und Bit-Operationen** sind für ein
> zeilenbasiertes Migrations-Plugin **n/a** (siehe Ende). Fokus hier:
> Schnell-Check, PR-Review, Coding-Checkliste, Anti-Patterns, Struktur.

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
| Testbarkeit (pure functions) | 🟡 | ✅ | `opt.migrator`, `notify.parser.*` sind rein; `docs/TESTS/`-Suite deckt sie ab. |
| Import-Reihenfolge | 🟢 | ✅ | Kern/Config → Feature-Module → Bindings (z. B. `opt/init.lua`: common.* → opt.migrator → lib.nvim.notify). |

### Bonuspunkt: `lib`-Modul nutzen — ⚠️ (teilweise)

`lib.nvim.notify` (Kommando-/UI-Schicht) und `lib.nvim.map` (optionale
Keymaps) werden genutzt — als **harte**, nicht soft, Dependency (siehe
`health.lua`). **Nicht genutzt:** `lib.nvim.usercmd` — beide User-Commands
(`:MigrateOpt`, `:MigrateNotify`) registrieren direkt über
`vim.api.nvim_create_user_command` statt über den `lib.nvim.usercmd`-Wrapper,
der automatisches `pcall`-Wrapping der Callbacks böte. Echter, aber
risikoarmer offener Punkt (siehe [Arch&Coding.md](Arch&Coding.md)).
`lib.cross`/`memo`/`lazy` (Top-Level): migrate.nvim braucht sie nicht (schon
cross-platform durch Pfadnormalisierung; kein Memoization-Bedarf); `lib.lua.lazy`
(submodule-lazy-require) wird in `notify/init.lua` tatsächlich genutzt.

## PR-Review-Checkliste

### 1. Sicherheit & Fehlerbehandlung — ✅ / ⚠️
- pcall/Guards/explizite Rückgaben/kein Low-Level-notify: ✅
- `safe_call`-Envelope + strukturierte Fehlertypen: ⚠️ bewusst nicht — `(ok, err)`-Tupel/`pcall` reicht für den synchronen Scope.

### 2. Modularität & Struktur — ✅ / ⚠️
- SRP ✅, keine Globals ✅, reine Funktionen ✅ (Parser/Migrator), interne Helfer lokal ✅.
- Tools/Registry: ⚠️ kein zentrales Registry-Pattern — `opt`/`notify` sind namentlich in `bindings/usrcmds.lua` verdrahtet. Für 2 Module kein Mehrwert; vorgemerkt in `docs/ROADMAP.md` falls ein 3. Migrationsmodul dazukommt.
- `/config`-Ordner mit `DEFAULTS.lua`: ✅ (`config/{init,DEFAULTS}.lua`).

### 3. Buffer-/Window-Management — ✅ (Fenster n/a)
- Handle-zuerst-binden + `nvim_buf_is_valid` vor jedem Zugriff ✅.
- Race Conditions / Defer-Revalidierung: ✅ — `refactor/write.lua`'s `write_async` prüft den Buffer in jedem `vim.schedule`-Callback erneut.

### 4. UI-State-Management — n/a
Kein eigener UI-State (Telescope verwaltet Picker-Fenster und -Zustand selbst).

### 5. Dokumentation & Annotationen — ✅ / ⚠️
Kopf-Tags ✅, Funktions-Tags ✅, Aliase/Felder in `@types` ✅. `/config`-Eintrag im
PR-Review-Kapitel selbst schon oben unter Punkt 2 bestätigt. Kein `@see`
irgendwo im Code (⚠️, niedrige Priorität bei der aktuellen Modulgröße).

### 6. Testbarkeit und Lesbarkeit — ✅
DI: Config wird als `opts` durchgereicht, kein Hard-Wiring ✅. Pure Functions ✅
(extra für Testbarkeit aus `opt/init.lua` extrahiert). Test-Entry `docs/TESTS/run.lua` ✅.

### 7. Tooling — ⚠️ (1 offener Punkt)
- Lua LS: `.luarc.json` vorhanden (`diagnostics.globals=vim`, `workspace.library`) ✅.
- Formatter/Linter im CI: ❌ kein `.github/workflows/ci.yml`/`.luacheckrc` — `stylua` wird manuell ausgeführt, keine CI-Automatisierung. Vorgemerkt in `docs/ROADMAP.md` ("CI").

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

## Import- & Dateistruktur-Check — ⚠️
Import-Reihenfolge ✅, Datei-Header ✅. Projektweiter `@types`-Ordner: ⚠️ nur 2
zentrale Typ-Dateien statt eines `/types`-Ankers pro Subverzeichnis (siehe
[Arch&Coding.md](Arch&Coding.md) §5) — bewusst vereinfacht bei der aktuellen
Modulanzahl.

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
| Modularität | SRP, keine Globals, funktional; kein Registry (2 Module) | bei 3. Modul: Registry erwägen |
| Neovim-API | Buffer-Guards + Re-Validierung in async Callbacks | keine |
| Performance | gebündelte/async Writes, keine Hot-Loops | keine |
| Doku/Annotation | vollständig, aber kein `@see`, nur 2 `@types`-Dateien | niedrige Prio: bei Wachstum nachziehen |
| Tests | `docs/TESTS/` Suite grün (2 Specs) | mehr Randfälle (String-Literal-Notify, Multiline-Aliase — siehe `docs/ROADMAP.md`) |
| Tooling/CI | kein CI-Workflow | `.github/workflows/ci.yml` (stylua/luacheck/headless Tests) nachziehen |
| checkhealth-Modul? | ✅ `:checkhealth migrate` (Deps/Config/which-key) | keine |

---

## Fazit & Plan

migrate.nvim erfüllt die Master-Checklist in den meisten für ein
zeilenbasiertes Migrations-Plugin relevanten Punkten. **Offene Punkte**
(alle niedrige Priorität, in `docs/ROADMAP.md` nachverfolgt):

1. **Kein CI-Workflow** (§7 Tooling) — `stylua --check` + `luacheck` +
   headless `docs/TESTS/run.lua`, analog zu anderen `StefanBartl/*.nvim`-Repos.
2. **`lib.nvim.usercmd` nicht genutzt** — rohes `nvim_create_user_command`
   statt des Wrappers mit automatischem Callback-`pcall`.
3. **Kein Registry-Pattern** für Migrationsmodule (aktuell nur 2: `opt`, `notify`).
4. **Kein `@see`**, nur 2 zentrale `@types`-Dateien statt Pro-Subdir-Anker.

**Bewusste Abweichungen (kein Handlungsbedarf):** kein `safe_call`-Envelope,
funktionaler Stil statt Metatables, README englisch (publiziertes Plugin,
kein Config-Modul).

## Literatur und Referenzen

- [Arch&Coding.md](./Arch&Coding.md) · [Zentral-Prinzipien.md](./Zentral-Prinzipien.md) · [NEOTREE_FEATURES.md](./NEOTREE_FEATURES.md)
- Quell-Checklisten: `E:/repos/Notes/MyNotes/Checklists/Lua/`
