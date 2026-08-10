# Import SinCGIL SPI — come funziona e come è stato pensato

*(English version below / versione in inglese più sotto)*

---

## Parte 1 — Italiano

### Scopo

`app/services/import_spis/` è la pipeline gemella di `app/services/imports/` (vedi `CodeGuide/Imports/README.md`, da leggere prima di questa) per l'export CSV di SinCGIL relativo ai pensionati SPI, caricato nel modello `ImportSpi`. Stessa architettura, stesso schema dinamico costruito a runtime, stesso uso di `COPY` — questa guida si concentra solo su **cosa cambia**.

### L'unica differenza reale: gli importi in euro

L'export Attivi ha solo due tipi di colonna (`:date`/`:string`); l'export SPI ne ha **tre**, perché include importi in euro (quota associativa, importo delega). Questo si propaga in due punti paralleli:

- `ImportSpis::SchemaSyncService#column_type` sceglie `:date`/`:decimal`/`:string` per l'`ALTER TABLE`, guidato da `ImportSpi::DATE_COLUMNS`/`ImportSpi::DECIMAL_COLUMNS`.
- `ImportSpis::CsvImporterService#column_kind` fa la stessa classificazione a livello di riga, per decidere come formattare ogni valore prima di passarlo a `COPY`.

L'unico codice davvero nuovo è `parse_decimal`: SinCGIL esporta i decimali con la virgola italiana (`"10,17"`), che va convertita al punto prima che PostgreSQL possa interpretarla come `:decimal` durante un `COPY`. A differenza di `parse_date` (che inghiotte un formato invalido e produce `NULL`), un decimale malformato non gestito qui farebbe fallire l'intero `COPY` con un errore PostgreSQL — un'asimmetria non documentata altrove.

### Cosa resta condiviso, non duplicato

`Imports::HeaderNormalizer` non ha una copia SPI: sia `ImportSpis::SchemaSyncService` sia `ImportSpis::CsvImporterService` lo richiamano direttamente come `Imports::HeaderNormalizer.call(...)` — un solo punto di manutenzione per la normalizzazione delle intestazioni, condiviso tra le due pipeline nonostante vivano in moduli separati.

### Decisioni che *non* sono ovvie dal codice

- **`value.tr(",", ".")` non gestisce separatori delle migliaia**: se l'export SinCGIL includesse `"1.234,56"`, la conversione produrrebbe un valore che PostgreSQL rifiuterebbe.
- **Decimali malformati fanno fallire l'intero import**, date malformate no — la stessa filosofia "tollera dati esterni sporchi" applicata in modo incoerente tra i due tipi, perché nessun caso reale di decimale malformato è mai comparso nei dati.
- **Tutto il resto della classe (`FIXED_COLUMNS`, doppio delimitatore `;`/`,`, throttling del progresso, transazione) è identico riga per riga alla versione Attivi** — vedi `CodeGuide/Imports/csv_importer_service.md`.

---

## Part 2 — English

### Purpose

`app/services/import_spis/` is the twin pipeline to `app/services/imports/` (see `CodeGuide/Imports/README.md`, worth reading first) for SinCGIL's CSV export covering SPI pensioners, loaded into the `ImportSpi` model. Same architecture, same runtime-built dynamic schema, same use of `COPY` — this guide focuses only on **what's different**.

### The one real difference: euro amounts

The Attivi export has only two column types (`:date`/`:string`); the SPI export has **three**, because it includes euro amounts (membership dues, delegation amount). This propagates through two parallel spots:

- `ImportSpis::SchemaSyncService#column_type` picks `:date`/`:decimal`/`:string` for the `ALTER TABLE`, driven by `ImportSpi::DATE_COLUMNS`/`ImportSpi::DECIMAL_COLUMNS`.
- `ImportSpis::CsvImporterService#column_kind` does the same classification at the row level, to decide how to format each value before passing it to `COPY`.

The only genuinely new code is `parse_decimal`: SinCGIL exports decimals with the Italian comma (`"10,17"`), which needs converting to a period before PostgreSQL can interpret it as `:decimal` during a `COPY`. Unlike `parse_date` (which swallows an invalid format and produces `NULL`), a malformed decimal not handled here would fail the entire `COPY` with a PostgreSQL error — an asymmetry not documented anywhere else.

### What stays shared, not duplicated

`Imports::HeaderNormalizer` has no SPI copy: both `ImportSpis::SchemaSyncService` and `ImportSpis::CsvImporterService` call it directly as `Imports::HeaderNormalizer.call(...)` — a single maintenance point for header normalization, shared across both pipelines despite living in separate modules.

### Decisions that are *not* obvious from the code

- **`value.tr(",", ".")` doesn't handle thousands separators**: if the SinCGIL export ever included `"1.234,56"`, the conversion would produce a value PostgreSQL would reject.
- **Malformed decimals fail the entire import**, malformed dates don't — the same "tolerate dirty external data" philosophy applied inconsistently across the two types, because no real malformed-decimal case has ever shown up in the data.
- **Everything else in the class (`FIXED_COLUMNS`, dual `;`/`,` delimiter, progress throttling, transaction) is identical line for line to the Attivi version** — see `CodeGuide/Imports/csv_importer_service.md`.
