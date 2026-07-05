# Architektur- & Coding-Regeln — Audit für migrate.nvim

> Anwendung der Checkliste [Arch&Coding-Regeln](file:///E:/repos/Notes/MyNotes/Checklists/Lua/Arch&Coding-Regeln.md)
> auf migrate.nvim. Nur die **normativen** Abschnitte (§1–11 + Annotationen/
> Naming/Types) sind hier auditiert; die CPU-/Table-/String-Benchmark-Kapitel
> sind Referenzmaterial ohne Einzel-Check.

Legende: ✅ erfüllt · ⚠️ bewusste Abweichung · ❌ offen · n/a nicht zutreffend

## §1 Sicherheitsprinzipien & Fehlerbehandlung — ✅ (2 offene Punkte)

| Regel | Status | Beleg / Anmerkung |
| --- | --- | --- |
| `pcall` bevorzugt | ✅ | Alle Buffer-Mutationen laufen unter `pcall` (`buffer.replace_lines`, `refactor.apply.apply_match`, `refactor.write.*`, `usrcmds.setup`'s `require`-Guards). |
| Type Guards & Literal Checks | ⚠️ | Buffer-Handles werden konsequent mit `nvim_buf_is_valid` geprüft (14 Stellen). Feinere Argument-Guards (z. B. `picker.show(matches, opts)` prüft `opts.*`-Felder nicht) fehlen an internen, nicht user-exponierten Schnittstellen — niedriges Risiko, da nur intern aufgerufen. |
| Explizite Rückgaben | ✅ | `buffer.lua`/`write.lua` geben `boolean`(, `string|nil` err) zurück; kein stilles Verschlucken. |
| Kein `notify()` in Low-Level | ✅ | `parser/*`, `refactor/apply.lua`, `refactor/cleanup.lua`, `refactor/import.lua` notifyen nicht; nur die Kommando-/UI-Schicht (`opt/init.lua`, `notify/init.lua`, `common/command.lua`, `common/picker.lua`, `health.lua`, `bindings/usrcmds.lua`) tut es. |
| `safe_call`-Wrapper `{ok,result,err}` | ⚠️ | Nicht verwendet — direktes `pcall`/`(ok, err)`-Tupel reicht für den synchronen Scope. |
| Strukturierte Fehlertypen | ⚠️ | Keine eigenen Error-Typen; Fehler sind Strings (`write.lua`'s `err`-Message). Für den Scope ausreichend. |
| `@error`/`@raises` Tags | n/a | Keine raising API (alles gibt `ok, err` zurück oder ist idempotent). |
| Private Funktionen lokal | ✅ | Interne Helfer (`migrate_line_text`-Alias, `check_import`, `find_first_code_line`, `to_common_matches`, …) sind `local function`. |
| Argumente typisiert übergeben | ✅ | Durchgängige `@param`-Annotationen. |

## §2 Modularisierung & Strukturprinzipien — ✅

| Regel | Status | Beleg |
| --- | --- | --- |
| Modul = eine Verantwortung | ✅ | `opt/migrator` (Regex-Rewrite), `notify/parser/*` (Erkennung), `notify/refactor/*` (Anwendung: import/cleanup/apply/write), `common/*` (geteilte Command-/Picker-/Buffer-Infrastruktur), `bindings/*` (usrcmds/keymaps/which-key). |
| Reine Funktionen bevorzugen | ✅ | `opt.migrator.migrate_line`, `notify.parser.patterns.*`, `notify.parser.migrator.*`, `notify.parser.extractor.*` sind seiteneffektfrei (siehe `docs/TESTS/`). |
| Lokale statt globale Funktionen | ✅ | Keine globalen Funktionen; interne Helfer sind `local`. |
| Entwurfsmuster wenn sinnvoll | ✅ | „Strategy"-artige Trennung Scan/Apply/Picker über `MigrateCommon.CommandOpts` (`common/command.lua`); Facade in `init.lua`. |
| Tools via Registry | ❌ | Kein zentrales Registry-Pattern — `opt`/`notify` sind namentlich in `bindings/usrcmds.lua` verdrahtet. Für 2 Module ohne spürbaren Mehrwert; bei einem 3. Migrationsmodul lohnt sich ein `migrate.registry`. Vorgemerkt in `docs/ROADMAP.md` ("Pluggable migration modules"). |
| Keine globalen States | ✅ | Einziger State ist `migrate.config.options` (Singleton-Table), Zugriff nur über `config.get()`. |

## §3 Buffer- & Window-Management — ✅ (Fenster n/a)

- migrate.nvim öffnet selbst **keine** Fenster/Floats — Telescope verwaltet sein eigenes Picker-Fenster. Der UI-State-/`cleanup_all()`-Teil ist daher n/a.
- Buffer: `nvim_buf_is_valid` guardet konsequent vor jeder Mutation (`common/buffer.lua`, `notify/*`, `opt/init.lua`). ✅
- Race Conditions: `notify/refactor/write.lua`'s `write_async` validiert den Buffer erneut in jedem `vim.schedule`-Callback (`if api.nvim_buf_is_valid(bufnr) then …`). ✅

## §4 Methoden, Metatables & Datenmodelle — n/a (bewusst funktional)

migrate.nvim ist **funktional**, nicht OO: keine Metatables, kein `__index`, keine Getter/Setter-Objekte (`migrate.config.get()` ist die einzige Ausnahme und ein einfacher Funktionsaufruf, kein OO-Objekt). Für ein zustandsarmes Migrations-Tool die einfachere, testbarere Wahl. Kein Handlungsbedarf.

## §5 Dokumentation & Annotationen — ✅ (2 offene/bewusste Punkte)

| Regel | Status | Beleg / Anmerkung |
| --- | --- | --- |
| Datei-Tags `@module/@brief/@description` | ✅ | Jede Quelldatei trägt den Header. |
| Kommentare pro Funktion `@param/@return` | ✅ | Durchgängig. |
| Konsistentes englisches Naming | ✅ | snake_case, englisch. |
| Explizite Typisierungen `@alias/@field` | ✅ | `@types/init.lua` (`UsrCmds.Migrate.Config`, `UsrCmds.Migrate.Keymaps`, `.Notify.Match`) + `common/@types.lua` (`MigrateCommon.*`). |
| Modulverlinkung `@see` | ❌ | Kein einziges `@see` im Code. Niedrige Priorität — die Modul-Struktur ist klein genug, dass Cross-Referenzen bisher nicht vermisst wurden. |
| **`/types`-Ordner pro Subverzeichnis** | ⚠️ | Nur 2 Typ-Dateien insgesamt (`@types/init.lua` top-level, `common/@types.lua`) statt eines `/types`-Ankers pro Unterverzeichnis (`opt/`, `notify/`, `notify/parser/`, `notify/refactor/`, `bindings/`, `config/` haben keinen eigenen `/types`-Ordner). Bewusst vereinfacht — deutlich weniger Module als z. B. cascade.nvim, zwei zentrale Dateien decken alles ab. Bei weiterem Wachstum (§2: neues Migrationsmodul) nachziehen. |
| **README deutsch + `doc/*.txt` englisch** | ⚠️ | Diese Regel gilt für **`nvim/config`-Module**. migrate.nvim ist ein **veröffentlichtes Standalone-Plugin** → README **englisch** (wie bei allen `StefanBartl/*.nvim`-Repos). Bewusst abweichend. |

## §6 Testbarkeit & Lesbarkeit — ✅

| Regel | Status | Beleg |
| --- | --- | --- |
| Klein & fokussiert (SRP) | ✅ | siehe §2. |
| Klarheit vor Kürze | ✅ | Sprechende Namen, Kommentare an nicht-offensichtlichen Stellen (z. B. `notify/init.lua`'s `PLUGIN_ROOT`-Exclusion). |
| Testbarkeit durch Design | ✅ | `opt.migrator` wurde eigens aus `opt/init.lua` extrahiert, um ohne `lib.nvim`/`telescope.nvim` testbar zu sein (siehe `docs/TESTS/README.md`). |
| Separater Test-Entry | ✅ | `docs/TESTS/run.lua` + `harness.lua` + 2 Specs (`opt_migrator_spec`, `notify_parser_spec`). |
| Snapshot/Restore | n/a | Kein langlebiger State zum Snapshotten. |

## §7 Fehlerbehandlung & Validierung — ⚠️ (wie §1)

`safe_call`/strukturierte Fehlertypen bewusst nicht verwendet — `pcall` + `(ok, err)`-Tupel decken den Scope ab.

## §8 Performance & Speicher — ✅

| Regel | Status | Beleg |
| --- | --- | --- |
| Debounced/gesammelte Writes | ✅ | `notify/refactor/write.lua`'s `batch_write` sammelt alle Datei-Schreibvorgänge eines `cwd`-Laufs und führt sie gebündelt (sync oder async) aus. |
| Lokale Variablen | ✅ | Module cachen `api`/`fn`/`str_fmt` top-of-file (`opt/init.lua`, `common/*`). |
| Memoization | n/a | Regex-Patterns sind literal in den Funktionen, keine Kompilierungskosten wie bei Treesitter-Queries — nichts zu memoisieren. |
| String-Concat in Loops vermeiden | ✅ | Multiline-Migration (`notify/parser/migrator.migrate_multiline`) nutzt `table.concat(lines, " ")`, kein `s .. s` im Loop. |
| Weak-Tables / GC-Steuerung | n/a | Keine langlebigen/großen Caches. |

## §9–§11 Cache / Weak Tables / Spezialfälle — n/a

Kein persistenter Cache, keine Dual-Representation, keine FIFO/History-Strukturen.

## Import-Reihung & Alias-Regeln — ✅

- Requires folgen der vorgegebenen Reihung (Kern/Config → Feature-Module → Bindings), z. B. `opt/init.lua`: `common.command` → `common.picker` → `common.buffer` → `opt.migrator` → `lib.nvim.notify`.
- Lokale Aliase für heiße Pfade: nicht nötig (kein Hot-Loop über viele Iterationen; Migrationen laufen auf explizite Kommandos, nicht pro Tastendruck).

## NVIM-Config-spezifisch — ⚠️ (1 offener Punkt)

| Punkt | Status | Anmerkung |
| --- | --- | --- |
| `lib.nvim.notify` statt `vim.notify()` | ✅ | Durchgängig in der Kommando-/UI-Schicht. Ausnahme: `bindings/usrcmds.lua`'s Modul-Lade-Fehler nutzt rohes `vim.notify` — bewusst, da an dieser Stelle noch unklar ist, ob `lib.nvim` überhaupt geladen werden konnte. |
| `lib.nvim.map` statt `vim.keymap.set` | ✅ | `bindings/keymaps.lua` nutzt `lib.nvim.map`. |
| `lib.nvim.usercmd` statt `nvim_create_user_command` | ❌ | `common/command.lua` und `notify/init.lua` registrieren Commands direkt über `vim.api.nvim_create_user_command`, nicht über `lib.nvim.usercmd` (das u. a. automatisches `pcall`-Wrapping der Callback-Funktion böte). Offener Punkt, siehe Fazit. |
| `lib.*augroup`/`lib.*autocmd` | n/a | migrate.nvim registriert keine Autocmds (siehe `docs/BINDINGS.md`). |
| `lib.cross`/`lib.memo`/`lib.lazy`/`lib.hover_select` | n/a | Kein Cross-Platform-Sonderfall über das bereits Vorhandene hinaus (siehe Cross-Plattform-Review in `docs/ROADMAP/PluginPackagingChecklist.md`); kein Memoization-Bedarf; kein `vim.select`-Einsatz. |

---

## Fazit & Plan

migrate.nvim folgt den Regeln überwiegend. **Offene, niedrigpriore Punkte:**

1. **`lib.nvim.usercmd` statt rohem `nvim_create_user_command`** (NVIM-Config-spezifisch) — würde automatisches Error-Wrapping der Callbacks bringen; echter, aber risikoarmer Nacharbeits-Punkt (kein Verhaltensunterschied für den User, nur robustere Fehlerbehandlung bei Bugs im Callback selbst).
2. **Kein Tools-Registry-Pattern** (§2) — bei einem 3. Migrationsmodul sinnvoll, für aktuell 2 (`opt`, `notify`) kein Mehrwert.
3. **Kein `@see`** (§5) — bei der aktuellen Modulgröße nicht vermisst.
4. **Kein `/types`-Anker pro Subverzeichnis** (§5) — bewusst vereinfacht auf 2 zentrale Typ-Dateien.

**Bewusste Abweichungen (kein Handlungsbedarf):** kein `safe_call`-Envelope (§1/§7), funktionaler Stil statt Metatables (§4), README englisch (§5, publiziertes Plugin).
