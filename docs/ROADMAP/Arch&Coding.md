# Architektur- & Coding-Regeln — Audit für migrate.nvim

> Anwendung der Checkliste [`regeln/PRINCIPLES.md`](../../../WKDBooks/Development/wkdbook-Lua/Checklists/regeln/PRINCIPLES.md)
> auf migrate.nvim. Nur die **normativen** Abschnitte (§1–11 + Annotationen/
> Naming/Types) sind hier auditiert; die CPU-/Table-/String-Benchmark-Kapitel
> sind Referenzmaterial ohne Einzel-Check.

> The source checklists (`Arch&Coding-Regeln.md`, `Checklist.md`,
> `Zentrale-Prinzipien.md`) were retired: they were absorbed into the rule
> collection under `WKDBooks/Development/wkdbook-Lua/Checklists/`, which is
> now the canonical one. The links above point there.


Legende: ✅ erfüllt · ⚠️ bewusste Abweichung · ❌ offen · n/a nicht zutreffend

## §1 Sicherheitsprinzipien & Fehlerbehandlung — ✅

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
| Tools via Registry | ✅ | `lua/migrate/registry.lua` — `opt`/`notify`/`hl`/`lsp` sind `M.register()`-Einträge; `config`, `bindings`, `health`, `init.enable_all()`/`disable_all()` iterieren die Registry statt Module namentlich zu verdrahten. Siehe [`docs/FEATURES.md`](../FEATURES.md#pluggable-migration-registry). |
| Keine globalen States | ✅ | Einziger State ist `migrate.config.options` (Singleton-Table), Zugriff nur über `config.get()`. |

## §3 Buffer- & Window-Management — ✅ (Fenster n/a)

- migrate.nvim öffnet selbst **keine** Fenster/Floats — Telescope verwaltet sein eigenes Picker-Fenster. Der UI-State-/`cleanup_all()`-Teil ist daher n/a.
- Buffer: `nvim_buf_is_valid` guardet konsequent vor jeder Mutation (`common/buffer.lua`, `notify/*`, `opt/init.lua`). ✅
- Race Conditions: `notify/refactor/write.lua`'s `write_async` validiert den Buffer erneut in jedem `vim.schedule`-Callback (`if api.nvim_buf_is_valid(bufnr) then …`). ✅

## §4 Methoden, Metatables & Datenmodelle — n/a (bewusst funktional)

migrate.nvim ist **funktional**, nicht OO: keine Metatables, kein `__index`, keine Getter/Setter-Objekte (`migrate.config.get()` ist die einzige Ausnahme und ein einfacher Funktionsaufruf, kein OO-Objekt). Für ein zustandsarmes Migrations-Tool die einfachere, testbarere Wahl. Kein Handlungsbedarf.

## §5 Dokumentation & Annotationen — ✅ (1 bewusste Abweichung)

| Regel | Status | Beleg / Anmerkung |
| --- | --- | --- |
| Datei-Tags `@module/@brief/@description` | ✅ | Jede Quelldatei trägt den Header. |
| Kommentare pro Funktion `@param/@return` | ✅ | Durchgängig. |
| Konsistentes englisches Naming | ✅ | snake_case, englisch. |
| Explizite Typisierungen `@alias/@field` | ✅ | `@types/init.lua` (`UsrCmds.Migrate.Config`, `UsrCmds.Migrate.Keymaps`, `.Notify.Match`) + `common/@types.lua` (`MigrateCommon.*`). |
| Modulverlinkung `@see` | ✅ | `registry.lua` ↔ die vier Migrationsmodule + `bindings.usrcmds`; `init.lua`/`config/DEFAULTS.lua` → `registry`; jedes Migrationsmodul (`opt`/`notify`/`hl`/`lsp`) → `common.command` + `registry`; `bindings.usrcmds`/`health.lua` → `registry`. |
| **`/types`-Ordner pro Subverzeichnis** | ⚠️ | Bewusste Abweichung, jetzt final: nur 2 Typ-Dateien insgesamt (`@types/init.lua` top-level, `common/@types.lua`) statt eines `/types`-Ankers pro Unterverzeichnis. Auch nach dem Zuwachs von 2 auf 4 Migrationsmodule (`hl`, `lsp` kamen dazu) hat kein Subdir eigene, lokale Typen jenseits dessen, was die zwei zentralen Dateien abdecken — ein Ordner pro Subdir wäre reine Formalie ohne zusätzlichen Typinhalt. Nicht mehr als offener Punkt geführt. |
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

## NVIM-Config-spezifisch — ✅

| Punkt | Status | Anmerkung |
| --- | --- | --- |
| `lib.nvim.notify` statt `vim.notify()` | ✅ | Durchgängig in der Kommando-/UI-Schicht. Ausnahme: `bindings/usrcmds.lua`'s Modul-Lade-Fehler nutzt rohes `vim.notify` — bewusst, da an dieser Stelle noch unklar ist, ob `lib.nvim` überhaupt geladen werden konnte. |
| `lib.nvim.map` statt `vim.keymap.set` | ✅ | `bindings/keymaps.lua` nutzt `lib.nvim.map`. |
| `lib.nvim.usercmd` statt `nvim_create_user_command` | ✅ | `common/command.lua` und `notify/init.lua` registrieren Commands über `lib.nvim.usercmd.composer` (seit `8d26139`); kein rohes `nvim_create_user_command` mehr im Code. |
| `lib.*augroup`/`lib.*autocmd` | n/a | migrate.nvim registriert keine Autocmds (siehe `docs/BINDINGS.md`). |
| `lib.cross`/`lib.memo`/`lib.lazy`/`lib.hover_select` | n/a | Kein Cross-Platform-Sonderfall über das bereits Vorhandene hinaus (siehe Cross-Plattform-Review in `docs/ROADMAP/PluginPackagingChecklist.md`); kein Memoization-Bedarf; kein `vim.select`-Einsatz. |

---

## Fazit & Plan

migrate.nvim folgt den Regeln jetzt vollständig. Die vier ursprünglich
offenen Punkte sind nachgezogen:

1. ~~`lib.nvim.usercmd` statt rohem `nvim_create_user_command`~~ (NVIM-Config-spezifisch) → `lib.nvim.usercmd.composer` durchgängig.
2. ~~Kein Tools-Registry-Pattern~~ (§2) → `lua/migrate/registry.lua`, jetzt 4 Module.
3. ~~Kein `@see`~~ (§5) → Querverweise ergänzt.
4. **Kein `/types`-Anker pro Subverzeichnis** (§5) — bleibt eine bewusste Abweichung (siehe §5-Tabelle), kein offener Punkt mehr.

**Bewusste Abweichungen (kein Handlungsbedarf):** kein `safe_call`-Envelope (§1/§7), funktionaler Stil statt Metatables (§4), README englisch (§5, publiziertes Plugin), 2 zentrale `@types`-Dateien statt Pro-Subdir-Anker (§5).
