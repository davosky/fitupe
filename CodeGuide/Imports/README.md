# Import SinCGIL — come funziona e come è stato pensato

*(English version below / versione in inglese più sotto)*

---

## Parte 1 — Italiano

### Scopo

`app/services/imports/` è la pipeline che carica gli export CSV di SinCGIL (i lavoratori attivi) nel modello `Import`, una riga per iscritto/delega per periodo. È il livello più a monte di tutta l'applicazione: ogni sezione di `Statistics::` e `StatisticPrints::` legge esclusivamente da `Import`, popolato solo da qui.

### La decisione di fondo: schema dinamico, non migration

`Import` non ha uno schema fisso oltre a un piccolo nucleo di colonne "note" (`azzonamento_di_riferimento_id`, `anno_di_riferimento`, `mese_di_riferimento`, i timestamp). Ogni altra colonna nasce **a runtime**, la prima volta che compare nell'intestazione di un CSV caricato — `Imports::SchemaSyncService` esegue `ALTER TABLE ADD COLUMN` durante la richiesta HTTP stessa, non da una migration. La ragione: il formato esatto dell'export SinCGIL non è sotto il controllo del progetto, e può aggiungere colonne senza preavviso. Questa è un'eccezione deliberata all'anti-pattern "niente logica nei migrations" di `CLAUDE.md` — qui la scelta è l'opposto complementare: niente migration affatto per questa parte di schema, perché nessuna migration potrebbe conoscere in anticipo l'insieme completo delle colonne.

### La pipeline in tre passi

1. **`Imports::HeaderNormalizer`** trasforma ogni intestazione CSV grezza in uno snake_case sicuro come nome colonna (`I18n.transliterate` + collasso a `[a-z0-9_]`). Condiviso, non specifico di questa cartella: `ImportSpis::SchemaSyncService`/`ImportSpis::CsvImporterService` e `IntegrationFlcs::AnagrafeCsvParser` lo richiamano tutti come `Imports::HeaderNormalizer.call(...)`.
2. **`Imports::SchemaSyncService`** confronta le intestazioni normalizzate con `Import.column_names`, aggiunge le colonne mancanti (`:date` per quelle elencate in `Import::DATE_COLUMNS`, `:string` per tutte le altre) e invalida la cache degli attributi di ActiveRecord con `reset_column_information` — necessario perché le colonne appena aggiunte devono essere visibili nello **stesso processo**, non solo al prossimo riavvio.
3. **`Imports::CsvImporterService`** carica il file con il comando PostgreSQL `COPY` (via `ActiveRecord::Base.connection.raw_connection`), non `insert_all` — l'unico meccanismo abbastanza veloce per caricare decine di migliaia di righe in una richiesta HTTP sincrona, con un callback `progress:` per aggiornare la UI in tempo reale.

### Decisioni che *non* sono ovvie dal codice

- **Il file caricato usa `;` come separatore, ma il flusso inviato a `COPY` usa `,`**: `CSV.generate_line` produce sempre CSV RFC 4180 standard indipendentemente dal delimitatore del file sorgente — un dettaglio facile da confondere leggendo `copy_line` fuori contesto.
- **`value&.strip.presence` normalizza ogni cella vuota o solo-spazi a `NULL`**, non a stringa vuota — vale per ogni colonna, non solo le date.
- **`parse_date` inghiotte `ArgumentError` deliberatamente**: una data malformata diventa `NULL` silenzioso invece di interrompere l'intero import — una scelta di robustezza specifica per dati esterni non controllati.
- **`Import::IGNORED_COLUMNS` viene sottratta prima del confronto con lo schema esistente**, sia in `SchemaSyncService` sia in `CsvImporterService`'s `build_field_specs` — le colonne ignorate non generano mai un `ALTER TABLE` né finiscono mai in una riga inserita.
- **`FIXED_COLUMNS`, l'ordine di `values` in `copy_line`, e `@columns` in `call` sono accoppiati posizionalmente**: cambiare l'ordine in uno dei tre punti senza aggiornare gli altri produce dati scritti silenziosamente nelle colonne sbagliate, senza errore da parte di `COPY`.

### Dove continuare

`CodeGuide/ImportSpis/README.md` documenta la pipeline gemella per i pensionati SPI, quasi identica riga per riga ma con un tipo di colonna aggiuntivo (`:decimal`, per gli importi in euro) e la gestione della virgola decimale italiana — vale la pena leggerla di seguito per vedere esattamente dove le due pipeline divergono.

---

## Part 2 — English

### Purpose

`app/services/imports/` is the pipeline that loads SinCGIL's CSV exports (active workers) into the `Import` model, one row per member/delegation per period. It's the most upstream layer of the whole application: every `Statistics::`/`StatisticPrints::` section reads exclusively from `Import`, populated only from here.

### The core decision: dynamic schema, not migrations

`Import` has no fixed schema beyond a small core of "known" columns (`azzonamento_di_riferimento_id`, `anno_di_riferimento`, `mese_di_riferimento`, timestamps). Every other column is born **at runtime**, the first time it appears in an uploaded CSV's header — `Imports::SchemaSyncService` runs `ALTER TABLE ADD COLUMN` during the HTTP request itself, not from a migration. The reason: the exact format of the SinCGIL export isn't under the project's control, and can add columns without notice. This is a deliberate exception to `CLAUDE.md`'s "no logic in migrations" anti-pattern — here the choice is the complementary opposite: no migration at all for this part of the schema, because no migration could know the full column set in advance.

### The three-step pipeline

1. **`Imports::HeaderNormalizer`** turns each raw CSV header into a safe snake_case column name (`I18n.transliterate` + collapse to `[a-z0-9_]`). Shared, not specific to this folder: `ImportSpis::SchemaSyncService`/`ImportSpis::CsvImporterService` and `IntegrationFlcs::AnagrafeCsvParser` all call it as `Imports::HeaderNormalizer.call(...)`.
2. **`Imports::SchemaSyncService`** compares normalized headers against `Import.column_names`, adds any missing columns (`:date` for those listed in `Import::DATE_COLUMNS`, `:string` for everything else), and invalidates ActiveRecord's attribute cache with `reset_column_information` — necessary because newly added columns must be visible within the **same process**, not just after the next restart.
3. **`Imports::CsvImporterService`** loads the file using PostgreSQL's `COPY` command (via `ActiveRecord::Base.connection.raw_connection`), not `insert_all` — the one mechanism fast enough to load tens of thousands of rows within a single synchronous HTTP request, with a `progress:` callback to update the UI live.

### Decisions that are *not* obvious from the code

- **The uploaded file uses `;` as its delimiter, but the stream sent to `COPY` uses `,`**: `CSV.generate_line` always produces standard RFC 4180 CSV regardless of the source file's delimiter — an easy detail to confuse when reading `copy_line` out of context.
- **`value&.strip.presence` normalizes every blank or whitespace-only cell to `NULL`**, not an empty string — applies to every column, not just dates.
- **`parse_date` deliberately swallows `ArgumentError`**: a malformed date silently becomes `NULL` instead of aborting the entire import — a robustness choice specific to uncontrolled external data.
- **`Import::IGNORED_COLUMNS` is subtracted before comparing against the existing schema**, both in `SchemaSyncService` and in `CsvImporterService`'s `build_field_specs` — ignored columns never trigger an `ALTER TABLE` and never end up in an inserted row.
- **`FIXED_COLUMNS`, the order of `values` in `copy_line`, and `@columns` in `call` are positionally coupled**: changing the order in one of the three places without updating the others produces data silently written into the wrong columns, with no error from `COPY`.

### Where to continue

`CodeGuide/ImportSpis/README.md` documents the twin pipeline for SPI pensioners, nearly line-for-line identical but with one extra column type (`:decimal`, for euro amounts) and handling of the Italian decimal comma — worth reading next to see exactly where the two pipelines diverge.
