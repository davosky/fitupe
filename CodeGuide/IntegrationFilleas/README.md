# Integrazione Cassa Edile (FILLEA) — come funziona e come è stata pensata

*(English version below / versione in inglese più sotto)*

---

## Parte 1 — Italiano

### Scopo

`IntegrationFilleasController` + il modello `IntegrationFillea` gestiscono il **caricamento dati** dell'integrazione Cassa Edile: un CRUD manuale con cui un operatore inserisce, una volta all'inizio dell'anno, il totale iscritti Cassa Edile per provincia (`subscribers_ce`). Nessun file da caricare, nessun servizio dedicato in `app/services/` — a differenza di ogni altra area del progetto documentata finora, qui **non esiste** una cartella di servizi: tutta la logica sta nel controller REST standard e nelle validazioni del modello.

Da non confondere con `StatisticWithIntegrations::FilleaCorrection` (cartella diversa, vedi `CodeGuide/StatisticWithIntegrations/README.md`): quella **legge** `subscribers_ce` già salvato e lo applica alle statistiche; questa coppia controller+model è l'unico punto che lo **scrive**.

### Perché non c'è un controller di upload, a differenza di FLC

Il contrasto più istruttivo è con l'integrazione FLC gemella (`CodeGuide/IntegrationFlcs/README.md`): `IntegrationFlcsController` (CRUD manuale, quasi identico a questo) **coesiste** con `IntegrationFlcUploadsController`, che avvolge `IntegrationFlcs::ComparisonService` per popolare `subscribers_af` automaticamente da un estratto CSV Anagrafe. FILLEA non ha, e non ha mai avuto, un equivalente. La ragione è nei dati: Cassa Edile fornisce un singolo numero aggregato per provincia/anno, non un elenco di codici fiscali — non c'è nulla da confrontare a livello di singolo iscritto come invece serve per FLC (che deve sapere *quali* codici fiscali mancano da SinCGIL, non solo un totale).

### Il modello: sette righe, tutta la logica di dominio

`IntegrationFillea` non ha callback (coerente con l'anti-pattern esplicitamente vietato in `CLAUDE.md`), solo tre validazioni: `year` come stringa a 4 cifre (coerente con `anno_di_riferimento` in `Import`/`ImportSpi` — l'anno è trattato come testo ovunque nel progetto, mai come intero), `subscribers_ce` come intero `>= 0` (zero è un dato legittimo, non un placeholder — la distinzione "nessun dato" è fatta sull'esistenza del record, non sul valore), e l'unicità `year` scoped su `zoning_id` — il vincolo che rende sicuro ogni `find_by`/`exists?` in `FilleaCorrection`.

### Decisioni che *non* sono ovvie dal codice

- **`greater_than_or_equal_to: 0`, non `greater_than: 0`**: zero iscritti è un valore valido, non un errore.
- **Nessun controller di upload per FILLEA**: una scelta strutturale legata alla natura del dato (un totale aggregato), non un'omissione.
- **`year` è una stringa, non un intero**, coerentemente con ogni altro punto del progetto dove l'anno viene confrontato o usato come chiave.

---

## Part 2 — English

### Purpose

`IntegrationFilleasController` + the `IntegrationFillea` model handle the **data-loading** side of the Cassa Edile integration: a manual CRUD an operator uses, once at the start of each year, to enter the Cassa Edile member total per province (`subscribers_ce`). No file to upload, no dedicated `app/services/` folder — unlike every other area of the project documented so far, no service folder exists here at all: all the logic lives in the standard REST controller and the model's validations.

Not to be confused with `StatisticWithIntegrations::FilleaCorrection` (a different folder, see `CodeGuide/StatisticWithIntegrations/README.md`): that one **reads** the already-saved `subscribers_ce` and applies it to the statistics; this controller+model pair is the only place that **writes** it.

### Why there's no upload controller, unlike FLC

The most instructive contrast is with the twin FLC integration (`CodeGuide/IntegrationFlcs/README.md`): `IntegrationFlcsController` (a manual CRUD, almost identical to this one) **coexists** with `IntegrationFlcUploadsController`, which wraps `IntegrationFlcs::ComparisonService` to auto-populate `subscribers_af` from an Anagrafe CSV extract. FILLEA has, and has never had, an equivalent. The reason is in the data: Cassa Edile provides a single aggregate number per province/year, not a list of codici fiscali — there's nothing to compare at the individual-member level the way FLC needs (which must know *which* codici fiscali are missing from SinCGIL, not just a total).

### The model: seven lines, all the domain logic

`IntegrationFillea` has no callbacks (consistent with the anti-pattern explicitly forbidden in `CLAUDE.md`), just three validations: `year` as a 4-digit string (consistent with `anno_di_riferimento` in `Import`/`ImportSpi` — the year is treated as text everywhere in the project, never an integer), `subscribers_ce` as an integer `>= 0` (zero is legitimate data, not a placeholder — the "no data" distinction is made on record existence, not field value), and `year` uniqueness scoped to `zoning_id` — the constraint that makes every `find_by`/`exists?` in `FilleaCorrection` safe.

### Decisions that are *not* obvious from the code

- **`greater_than_or_equal_to: 0`, not `greater_than: 0`**: zero members is a valid value, not an error.
- **No upload controller for FILLEA**: a structural choice tied to the nature of the data (an aggregate total), not an omission.
- **`year` is a string, not an integer**, consistent with every other place in the project where the year is compared or used as a lookup key.
