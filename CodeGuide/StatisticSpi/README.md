# Statistiche SPI — come funzionano e come sono state pensate

*(English version below / versione in inglese più sotto)*

---

## Parte 1 — Italiano

### Scopo

La pagina **Statistiche SPI** (`/statistic_spi`) è l'equivalente, per i pensionati SPI, della pagina Statistiche descritta in `CodeGuide/Statistics/README.md`: prende i dati grezzi importati mese per mese (il modello `ImportSpi`, una riga per **delega**, non per iscritto) e li trasforma in un cruscotto — totali, confronto anno su anno, distribuzione per fascia d'età, tipologia di delega, deleghe multiple, cessazioni, pratiche provvisorie — filtrabile per azzonamento, anno e mese, esattamente come la pagina Statistiche per gli Attivi.

Vale la pena leggere prima `CodeGuide/Statistics/README.md`: questa guida assume familiarità con quel documento e si concentra su **cosa cambia** per gli SPI, non lo ripete da zero.

### La differenza di fondo: `Import` conta iscritti, `ImportSpi` conta deleghe

Questa è la decisione che spiega ogni altra scelta nella cartella `app/services/statistic_spi/`. Per gli Attivi, un iscritto genera **una sola riga** `Import` per periodo: contare le righe e contare gli iscritti distinti è la stessa cosa. Per i pensionati SPI questo non è vero — un pensionato può avere più deleghe attive contemporaneamente (pensione di reversibilità, invalidità civile, o una combinazione: vedi `.ai/Spi/pensionati.md` per la spiegazione completa e i casi reali), quindi `ImportSpi` ha **una riga per delega**, non per persona. La stessa persona può quindi comparire più volte, anche in comprensori diversi.

Questo obbliga ogni sezione della pagina a dichiarare esplicitamente **quale delle due cose sta contando**:

- **Deleghe** (`TipologieDelegaBreakdown`, `CessazioniBreakdown`, `ProvvisorieBreakdown`, e la metà "deleghe" di `TotalMembersComparison`): contano righe `ImportSpi`. Ogni riga è già un'unità additiva — sommare i comprensori dà sempre il totale regionale, nessuna riconciliazione necessaria.
- **Iscritti/persone** (la metà "iscritti" di `TotalMembersComparison`, `AgeBreakdown`, `MultipleDelegationsBreakdown`): contano `codice_fiscale` **distinti**. Qui sommare "persone per comprensorio" calcolate ingenuamente comprensorio per comprensorio **sovraconta**: una persona con deleghe in due comprensori verrebbe contata due volte nella somma dei comprensori pur essendo una sola volta nel totale regionale.

### Il meccanismo di riconciliazione: comprensorio "primario" via `DISTINCT ON`

Il problema del sovraconteggio è risolto sempre nello stesso modo: ogni `codice_fiscale` viene assegnato a **un solo** comprensorio "primario" — il primo alfabeticamente tra i `codice_azzonamento_completo` in cui la persona compare — tramite `SELECT DISTINCT ON (codice_fiscale) ... ORDER BY codice_fiscale, codice_azzonamento_completo`, un'estensione PostgreSQL (non SQL standard). Non c'è un concetto di comprensorio "corretto" tra due deleghe della stessa persona: serve solo che la scelta sia deterministica e che ogni persona finisca in **esattamente uno** dei comprensori in cui appare, così `somma dei comprensori == totale regionale` per costruzione.

```sql
SELECT DISTINCT ON (codice_fiscale)
  codice_fiscale,
  SUBSTRING(codice_azzonamento_completo FROM 1 FOR 2) AS comprensorio
FROM base
ORDER BY codice_fiscale, codice_azzonamento_completo
```

Questo pattern compare in tre punti, ognuno con una variante diversa a seconda di cos'altro serve nella stessa riga:

- `StatisticSpi::ReconciledIscrittiByComprensorio` — la versione "pura", usata quando serve solo il conteggio persone per comprensorio (dentro `TotalMembersComparison`).
- `StatisticSpi::AgeBreakdown` — la stessa riconciliazione, ma con `data_nascita` portata nella stessa riga, perché la fascia d'età va calcolata *dopo* aver ridotto ogni persona a una sola riga (altrimenti la stessa persona verrebbe contata più volte anche nella fascia d'età).
- `StatisticSpi::MultipleDelegationsBreakdown` — il caso più sottile: il comprensorio primario è scelto sulle occorrenze **totali** della persona in tutta la regione, non sulle occorrenze dentro il singolo comprensorio, altrimenti una persona con 3 deleghe (2 in A, 1 in B) rischierebbe di essere spezzata invece di essere contata una sola volta come "tripla" nel suo comprensorio primario.

Le sezioni che contano **deleghe** (`TipologieDelegaBreakdown`, `CessazioniBreakdown`, `ProvvisorieBreakdown`) non hanno bisogno di nessuna di queste CTE: un semplice `GROUP BY` su `SUBSTRING(codice_azzonamento_completo FROM 1 FOR 2)` basta, perché ogni riga è già un'unità additiva.

### La "recipe" delle sezioni SPI

A differenza della pagina Attivi (dove la struttura è "confronto anno su anno" oppure "distribuzione sul solo anno corrente"), ogni sezione SPI ha **sempre** entrambe le viste — totale regionale e ripartizione per comprensorio — nella stessa risposta, perché è così che la pagina è disegnata. Il pattern ricorrente, quasi identico in `AgeBreakdown`, `MultipleDelegationsBreakdown`, `TipologieDelegaBreakdown`, `CessazioniBreakdown`, `ProvvisorieBreakdown`:

1. Uno `Struct Row` per riga (regione o comprensorio) e uno `Struct Result` con due soli campi, `totale` (una `Row`) e `comprensori` (un array di `Row`, vuoto se l'azzonamento scelto non è regionale).
2. `call` si ramifica su `@zoning.regionale?`: se sì, il totale è la **somma** dei comprensori (`merge_counts`), mai una query separata; se no, `comprensori` resta `[]`.
3. Tre metodi privati ripetuti identici in ogni classe — `province_zonings`, `regional_zoning`, `regional_scope` — che risalgono **sempre** all'azzonamento regionale padre (anche quando l'azzonamento scelto è già regionale), perché ogni breakdown ha bisogno dell'intero scope regionale per calcolare sia il totale sia i comprensori in un colpo solo. Questa è una differenza deliberata rispetto a `Statistics::ZoningPeriodScope`, che invece risolve solo l'azzonamento scelto — vedi `CodeGuide/StatisticSpi/zoning_period_scope.md`, ultima sezione.
4. Una query — CTE grezza via `ActiveRecord::Base.connection.select_all` per le sezioni che richiedono riconciliazione o un `CASE` calcolato, oppure un semplice `.group(...).count` di ActiveRecord per le sezioni che contano deleghe senza trasformazioni.

### Un esempio di contrasto: perché `CessazioniBreakdown`/`ProvvisorieBreakdown` calcolano le percentuali diversamente da `TipologieDelegaBreakdown`

Tutte e tre le sezioni contano deleghe (nessuna riconciliazione). Ma:

- `TipologieDelegaBreakdown`: ogni delega finisce sempre in una delle cinque etichette (`ELSE 'Altro'` cattura il resto) — la somma delle etichette **è** il totale deleghe, quindi la percentuale è calcolata sul totale locale.
- `CessazioniBreakdown`/`ProvvisorieBreakdown`: rappresentano un **sottoinsieme** delle deleghe del periodo (una delega può non essere né cessata né provvisoria), quindi la percentuale è calcolata su un denominatore esterno, `deleghe_by_comprensorio` — un `.group(...).count` separato sull'intero `regional_scope`, senza filtro. Le percentuali mostrate in queste due sezioni **non sommano al 100%**, ed è corretto che sia così.

### Decisioni che *non* sono ovvie dal codice

- **`ImportSpi` conta deleghe, non persone.** È la premessa di tutto questo documento, ma non è deducibile guardando un solo file: va capita leggendo `TotalMembersComparison#count_totale` insieme a `#count_by_comprensorio`, dove la stessa metrica (`:iscritti`) usa due meccanismi diversi (`.distinct.count` per il totale, `ReconciledIscrittiByComprensorio` per il dettaglio) proprio per questo motivo.
- **Il comprensorio "primario" è arbitrario ma deterministico** (primo alfabeticamente): non rappresenta "dove vive" o "dove è iscritta" la persona in senso amministrativo, è solo la scelta che rende additiva la somma dei comprensori. Non va mai interpretato come un dato anagrafico.
- **Le fasce d'età (`BANDS`) e l'espressione SQL (`AGE_EXPR`) sono importate da `Statistics::AgeBreakdown`**, non ridefinite — l'unico punto di accoppiamento diretto tra le due cartelle `Statistics`/`StatisticSpi`. Deliberato: la definizione di "cinquantenne" è la stessa per Attivi e Pensionati.
- **Le percentuali di `CessazioniBreakdown`/`ProvvisorieBreakdown` non sommano al 100%** (vedi sopra) — non è un bug, il denominatore è il totale deleghe del periodo, non il totale delle sole cessazioni/provvisorie.
- **`OCCORRENZE = (2..5)`** in `MultipleDelegationsBreakdown` è un limite empirico osservato nei dati reali (vedi `.ai/Spi/pensionati.md`), non un vincolo di dominio garantito — andrebbe rivisto se comparissero persone con più di 5 deleghe.

### Dove continuare

Una nuova sezione SPI a "valore singolo o distribuzione, totale + comprensori" segue lo stesso schema a 4 punti descritto sopra. Le uniche vere decisioni da prendere: la sezione conta deleghe (nessuna riconciliazione, `.group(...).count` semplice o `CASE` statico) o persone (serve la CTE `DISTINCT ON (codice_fiscale)`)? le percentuali vanno calcolate sul totale locale o sul totale deleghe del periodo?

---

## Part 2 — English

### Purpose

The **Statistiche SPI** page (`/statistic_spi`) is the pensioners' (SPI) counterpart to the Statistics page described in `CodeGuide/Statistics/README.md`: it takes the raw data imported month by month (the `ImportSpi` model, one row per **delegation**, not per member) and turns it into a dashboard — totals, year-over-year comparison, breakdowns by age band, delegation type, multiple delegations, cessations, provisional cases — filterable by zoning, year, and month, exactly like the Attivi Statistics page.

It's worth reading `CodeGuide/Statistics/README.md` first: this guide assumes familiarity with that document and focuses on **what's different** for SPI, rather than repeating it from scratch.

### The core difference: `Import` counts members, `ImportSpi` counts delegations

This is the decision that explains every other choice in the `app/services/statistic_spi/` folder. For Attivi, a member generates exactly **one** `Import` row per period: counting rows and counting distinct members is the same thing. For SPI pensioners that's not true — a pensioner can hold multiple delegations at once (a survivor's pension, a civil-disability pension, or a combination: see `.ai/Spi/pensionati.md` for the full explanation and real cases), so `ImportSpi` has **one row per delegation**, not per person. The same person can therefore appear multiple times, even under different comprensori.

This forces every section of the page to explicitly declare **which of the two it's counting**:

- **Delegations** (`TipologieDelegaBreakdown`, `CessazioniBreakdown`, `ProvvisorieBreakdown`, and the "deleghe" half of `TotalMembersComparison`): count `ImportSpi` rows. Every row is already an additive unit — summing the comprensori always yields the regional total, no reconciliation needed.
- **Members/people** (the "iscritti" half of `TotalMembersComparison`, `AgeBreakdown`, `MultipleDelegationsBreakdown`): count **distinct** `codice_fiscale`. Here, naively summing "people per comprensorio" computed comprensorio by comprensorio **over-counts**: a person with delegations in two comprensori would be counted twice across the sum despite counting once in the regional total.

### The reconciliation mechanism: a "primary" comprensorio via `DISTINCT ON`

The over-counting problem is always solved the same way: every `codice_fiscale` is assigned to **exactly one** "primary" comprensorio — the alphabetically first among the `codice_azzonamento_completo` values the person appears under — via `SELECT DISTINCT ON (codice_fiscale) ... ORDER BY codice_fiscale, codice_azzonamento_completo`, a PostgreSQL extension (not standard SQL). There's no notion of a "correct" comprensorio between two of the same person's delegations: it just needs to be a deterministic choice that puts each person in **exactly one** of the comprensori they appear under, so `sum of comprensori == regional total` by construction.

```sql
SELECT DISTINCT ON (codice_fiscale)
  codice_fiscale,
  SUBSTRING(codice_azzonamento_completo FROM 1 FOR 2) AS comprensorio
FROM base
ORDER BY codice_fiscale, codice_azzonamento_completo
```

This pattern appears in three places, each with a different variant depending on what else is needed in the same row:

- `StatisticSpi::ReconciledIscrittiByComprensorio` — the "pure" version, used when only the per-comprensorio person count is needed (inside `TotalMembersComparison`).
- `StatisticSpi::AgeBreakdown` — the same reconciliation, but with `data_nascita` carried in the same row, because the age band must be computed *after* reducing each person to a single row (otherwise the same person would be counted multiple times in the age band too).
- `StatisticSpi::MultipleDelegationsBreakdown` — the most subtle case: the primary comprensorio is chosen based on the person's **total** occurrences across the whole region, not their occurrences within a single comprensorio, otherwise a person with 3 delegations (2 in A, 1 in B) could get split instead of being counted once as "tripla" under their primary comprensorio.

Sections that count **delegations** (`TipologieDelegaBreakdown`, `CessazioniBreakdown`, `ProvvisorieBreakdown`) need none of these CTEs: a plain `GROUP BY` on `SUBSTRING(codice_azzonamento_completo FROM 1 FOR 2)` is enough, because every row is already an additive unit.

### The SPI section "recipe"

Unlike the Attivi page (where the structure is either "year-over-year comparison" or "current-year-only distribution"), every SPI section **always** carries both views — regional total and per-comprensorio breakdown — in the same response, because that's how the page is designed. The recurring pattern, nearly identical across `AgeBreakdown`, `MultipleDelegationsBreakdown`, `TipologieDelegaBreakdown`, `CessazioniBreakdown`, `ProvvisorieBreakdown`:

1. A `Row` struct per row (region or comprensorio) and a `Result` struct with exactly two fields, `totale` (one `Row`) and `comprensori` (an array of `Row`s, empty if the chosen zoning isn't regional).
2. `call` branches on `@zoning.regionale?`: when true, the total is the **sum** of the comprensori (`merge_counts`), never a separate query; when false, `comprensori` stays `[]`.
3. Three private methods repeated identically across every class — `province_zonings`, `regional_zoning`, `regional_scope` — which **always** walk up to the parent regional zoning (even when the chosen zoning is already regional), because every breakdown needs the entire regional scope to compute both the total and the comprensori in one shot. This is a deliberate difference from `Statistics::ZoningPeriodScope`, which instead resolves only the chosen zoning — see `CodeGuide/StatisticSpi/zoning_period_scope.md`'s final section.
4. One query — a raw CTE via `ActiveRecord::Base.connection.select_all` for sections that need reconciliation or a computed `CASE`, or a plain ActiveRecord `.group(...).count` for sections that count delegations with no transformation needed.

### A contrasting example: why `CessazioniBreakdown`/`ProvvisorieBreakdown` compute percentages differently from `TipologieDelegaBreakdown`

All three sections count delegations (no reconciliation). But:

- `TipologieDelegaBreakdown`: every delegation always lands in one of the five labels (`ELSE 'Altro'` catches the rest) — the sum of the labels **is** the delegation total, so the percentage is computed against the local total.
- `CessazioniBreakdown`/`ProvvisorieBreakdown`: they represent a **subset** of the period's delegations (a delegation can be neither cessated nor provisional), so the percentage is computed against an external denominator, `deleghe_by_comprensorio` — a separate `.group(...).count` over the entire `regional_scope`, with no filter. The percentages shown in these two sections **don't add up to 100%**, and that's correct.

### Decisions that are *not* obvious from the code

- **`ImportSpi` counts delegations, not people.** This is the premise of this entire document, but it isn't derivable from looking at a single file: it has to be understood by reading `TotalMembersComparison#count_totale` alongside `#count_by_comprensorio`, where the same metric (`:iscritti`) uses two different mechanisms (`.distinct.count` for the total, `ReconciledIscrittiByComprensorio` for the breakdown) for exactly this reason.
- **The "primary" comprensorio is arbitrary but deterministic** (alphabetically first): it doesn't represent where the person "lives" or is administratively registered, it's just the choice that makes the sum of comprensori additive. It should never be interpreted as a demographic fact.
- **The age bands (`BANDS`) and the SQL expression (`AGE_EXPR`) are imported from `Statistics::AgeBreakdown`**, not redefined — the one point of direct coupling between the `Statistics`/`StatisticSpi` folders. Deliberate: the definition of "fifty-something" is the same for Attivi and Pensionati.
- **`CessazioniBreakdown`/`ProvvisorieBreakdown` percentages don't add up to 100%** (see above) — not a bug, the denominator is the period's total delegations, not just the total cessations/provvisorie.
- **`OCCORRENZE = (2..5)`** in `MultipleDelegationsBreakdown` is an empirical limit observed in real data (see `.ai/Spi/pensionati.md`), not a guaranteed domain constraint — it would need revisiting if people with more than 5 delegations ever showed up.

### Where to continue

A new SPI section ("single value or distribution, total + comprensori") follows the same 4-point scheme described above. The only real decisions to make: does the section count delegations (no reconciliation, plain `.group(...).count` or a static `CASE`) or people (needs the `DISTINCT ON (codice_fiscale)` CTE)? should percentages be computed against the local total or the period's total delegations?
