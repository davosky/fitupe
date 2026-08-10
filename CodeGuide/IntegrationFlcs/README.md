# Integrazione Anagrafe FLC — come funziona e come è stata pensata

*(English version below / versione in inglese più sotto)*

---

## Parte 1 — Italiano

### Scopo

`app/services/integration_flcs/` è il passo di **caricamento e confronto dati** dell'integrazione FLC/Anagrafe: l'utente carica un estratto CSV dell'Anagrafe FLC (un archivio esterno, non SinCGIL), e questa cartella lo confronta con i dati SinCGIL già importati per lo stesso azzonamento/anno/mese, salvando il numero di codici fiscali presenti in Anagrafe ma assenti da SinCGIL come `IntegrationFlc#subscribers_af`.

Da non confondere con `StatisticWithIntegrations::FlcCorrection` (cartella diversa, nome simile): quella legge `subscribers_af` già salvato e lo applica alle statistiche; questa cartella è il solo punto che lo **scrive**. Le due comunicano esclusivamente tramite il record `IntegrationFlc`, mai direttamente. Vedi `CodeGuide/StatisticWithIntegrations/README.md` per il meccanismo di ricalibrazione a valle.

### Le due classi

- **`AnagrafeCsvParser`** parsifica il file caricato in un `Set` di codici fiscali. A differenza delle pipeline SinCGIL (`Imports`/`ImportSpis`), qui il formato del file **non è noto in anticipo**: il delimitatore (`;` o `,`) è rilevato contando le occorrenze nella prima riga, l'intestazione del codice fiscale è cercata per contenuto normalizzato (non per posizione fissa), e un BOM UTF-8 iniziale viene rimosso esplicitamente — tutte difese contro un formato di export esterno mai fissato da un campione di riferimento definitivo.
- **`ComparisonService`** orchestra il confronto: verifica che SinCGIL abbia già dati per lo stesso periodo (altrimenti fallisce visibilmente, stesso principio di `Statistics::TotalMembersComparison`), calcola la differenza insiemistica tra i codici fiscali Anagrafe e quelli SinCGIL, e salva il risultato con `find_or_initialize_by` + `save!` — l'upload è idempotente, ricaricare lo stesso estratto aggiorna il record invece di duplicarlo.

### Decisioni che *non* sono ovvie dal codice

- **Il fallback regionale/provinciale va nel verso opposto** rispetto a `Statistics::ZoningPeriodScope`/`StatisticSpi::ZoningPeriodScope`: qui non si "risale al padre se il figlio è vuoto", si interrogano **entrambi contemporaneamente** (`candidate_zoning_ids`) perché un operatore potrebbe aver caricato l'export SinCGIL a livello regionale anche quando il confronto FLC in corso è per una singola provincia.
- **`categoria_column` sceglie dinamicamente tra `categoria_sindacale` e `categoria`**: conseguenza diretta dello schema dinamico di `Import` (vedi `CodeGuide/Imports/README.md`) — il nome della colonna con la sigla federazione è cambiato nel tempo tra gli export SinCGIL, ed entrambe le colonne possono coesistere per periodi diversi.
- **Il BOM UTF-8 viene rimosso esplicitamente solo qui**, mai nelle pipeline SinCGIL — perché solo l'Anagrafe FLC, tra le fonti dati del progetto, ha mostrato in pratica quel problema.
- **`Result#success?` controlla `error.nil?`, non `error.blank?`** come in quasi tutti gli altri `Result` del progetto — un'incoerenza stilistica minore, senza conseguenze pratiche qui ma da non copiare ciecamente altrove.

---

## Part 2 — English

### Purpose

`app/services/integration_flcs/` is the **data-loading and comparison** step of the FLC/Anagrafe integration: the user uploads a CSV extract from Anagrafe FLC (an external archive, not SinCGIL), and this folder compares it against the SinCGIL data already imported for the same zoning/year/month, saving the count of codici fiscali present in Anagrafe but missing from SinCGIL as `IntegrationFlc#subscribers_af`.

Not to be confused with `StatisticWithIntegrations::FlcCorrection` (a different folder, a similar name): that one reads the already-saved `subscribers_af` and applies it to the statistics; this folder is the only place that **writes** it. The two communicate solely through the `IntegrationFlc` record, never directly. See `CodeGuide/StatisticWithIntegrations/README.md` for the downstream recalibration mechanism.

### The two classes

- **`AnagrafeCsvParser`** parses the uploaded file into a `Set` of codici fiscali. Unlike the SinCGIL pipelines (`Imports`/`ImportSpis`), the file format here **isn't known in advance**: the delimiter (`;` or `,`) is detected by counting occurrences in the first line, the codice fiscale header is looked up by normalized content (not a fixed position), and a leading UTF-8 BOM is explicitly stripped — all defenses against an external export format never pinned down by a definitive reference sample.
- **`ComparisonService`** orchestrates the comparison: it verifies SinCGIL already has data for the same period (otherwise it fails visibly, the same principle as `Statistics::TotalMembersComparison`), computes the set difference between the Anagrafe and SinCGIL codici fiscali, and saves the result via `find_or_initialize_by` + `save!` — the upload is idempotent, re-uploading the same extract updates the record instead of duplicating it.

### Decisions that are *not* obvious from the code

- **The regional/provincial fallback runs in the opposite direction** from `Statistics::ZoningPeriodScope`/`StatisticSpi::ZoningPeriodScope`: instead of "walk up to the parent if the child is empty," it queries **both at once** (`candidate_zoning_ids`), because an operator may have loaded the SinCGIL export at the regional level even when the current FLC comparison targets a single province.
- **`categoria_column` dynamically picks between `categoria_sindacale` and `categoria`**: a direct consequence of `Import`'s dynamic schema (see `CodeGuide/Imports/README.md`) — the column name holding the federation code has changed over time across SinCGIL exports, and both columns can coexist for different periods.
- **The UTF-8 BOM is explicitly stripped only here**, never in the SinCGIL pipelines — because Anagrafe FLC is the only data source in the project that has actually shown that problem in practice.
- **`Result#success?` checks `error.nil?`, not `error.blank?`** like almost every other `Result` in the project — a minor stylistic inconsistency, with no practical consequence here but not one to blindly copy elsewhere.
