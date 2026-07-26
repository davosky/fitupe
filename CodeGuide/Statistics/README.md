# Statistiche — come funzionano e come sono state pensate

*(English version below / versione in inglese più sotto)*

---

## Parte 1 — Italiano

### Scopo

La pagina **Statistiche** (`/statistics`) è il cuore analitico di Fitupe: prende i dati grezzi importati mese per mese da SinCGIL (il modello `Import`, una riga per iscritto) e li trasforma in un cruscotto leggibile — conteggi, confronti anno su anno, distribuzioni per categoria, età, sesso, nazionalità, status lavorativo, ecc. — filtrabile per azzonamento, anno e mese.

Non è una risorsa CRUD: non esiste un modello "Statistica", non ci sono policy Pundit dedicate, non c'è un pannello Administrate. È una singola pagina (`StatisticsController#index`) pensata per ospitare più "sezioni" indipendenti nel tempo, ciascuna con il proprio servizio, la propria card nella vista e — quando serve — il proprio grafico. La voce di menu è visibile a **tutti** gli utenti autenticati (non solo admin/manager), a differenza di Azzonamenti/Importazioni/Integrazioni.

### Il form: azzonamento + anno + mese

Tutto parte da `TotalMembersForm`, un `ActiveModel::Model` (non un `ActiveRecord`, non salva nulla) con tre campi obbligatori: `zoning_id`, `anno` (stringa a 4 cifre), `mese`. Il form usa `method: :get`, quindi ogni ricerca è un normale link condivisibile (`?total_members_form[zoning_id]=4&...`), non una POST.

Se anno o mese mancano dati (per l'anno scelto *o* per l'anno precedente), la pagina non mostra zeri silenziosi: mostra un `alert-warning` esplicito con il nome dell'azzonamento e degli anni mancanti. Questa scelta — fallire in modo visibile invece di mostrare un grafico vuoto e ingannevole — è stata una decisione esplicita fin dall'inizio della fase "statistica".

### `ZoningPeriodScope`: il fallback che rende tutto il resto possibile

Ogni singolo servizio di statistica, senza eccezioni, delega la selezione delle righe `Import` a un unico oggetto: `Statistics::ZoningPeriodScope`. Questo è probabilmente il pezzo più critico dell'intera funzionalità, perché tutto il resto lo presuppone.

Il problema che risolve: un azzonamento **regionale** (es. "G" = FVG, codice a una lettera) spesso non ha importazioni dirette — i dati arrivano invece sotto gli azzonamenti **provinciali/comprensoriali** figli (es. "GA", "GB", ...). `ZoningPeriodScope` prova prima la corrispondenza esatta (`azzonamento_di_riferimento_id`); se non trova nulla, risale all'azzonamento regionale padre e filtra `codice_azzonamento_completo LIKE "<codice>%"`. Il verso inverso — un azzonamento provinciale che eredita dal padre regionale — è lo stesso meccanismo.

```ruby
class ZoningPeriodScope
  def call
    exact_scope = Import.where(azzonamento_di_riferimento_id: @zoning.id, anno_di_riferimento: @anno,
      mese_di_riferimento: @mese)
    return exact_scope if exact_scope.exists?

    regional_scope  # risale al padre e filtra per prefisso di codice_azzonamento_completo
  end
end
```

Questo fallback **non era previsto nella prima versione**: era stato deliberatamente escluso, poi reintrodotto pochi giorni dopo perché i dati reali lo richiedevano. È il tipo di decisione che vale la pena documentare qui, perché non è deducibile dal solo codice attuale.

### La "recipe" delle sezioni: un pattern ripetuto ~10 volte

Ogni sezione della pagina (Comprensori, Categorie, Attivi/Pensionati, Tipologie Iscrizione, Tipologie Delega, Nazionalità, Sesso, Provvisorie/Revoche, Status Lavorativo, Fasce d'Età, ...) segue **esattamente la stessa struttura a 4 livelli**:

1. **Servizio** in `app/services/statistics/<nome>_breakdown.rb` — una classe con `Row = Struct.new(..., keyword_init: true)` e `def self.call(...) = new(...).call`. Esistono due forme ricorrenti:
   - **Confronto anno su anno** (`anno:` + `anno_precedente:`, righe con `diff`/`diff_percent`) — es. `CategoryBreakdown`, `DelegationTypeBreakdown`.
   - **Distribuzione sul solo anno corrente** (solo `anno:`, righe con `percentuale` = quota sul totale iscritti *dello stesso azzonamento/anno/mese*, non un totale globale) — es. `NationalityBreakdown`, `GenderBreakdown`, `WorkStatusBreakdown`, `AgeBreakdown`.

2. **Wiring** in `Statistics::TotalMembersComparison` — il servizio "orchestratore": aggiunge un campo al `Result` (uno `Struct` unico che la vista legge), lo valorizza in `build_result`, e chiama il nuovo servizio da un metodo privato di una riga.

3. **Vista** — ogni sezione è una card indipendente (`.card.border-dark`) dentro `app/views/statistics/_total_iscritti.html.erb`: icona 48×48 + titolo, tabella, e (quando serve) un grafico Chart.js. Tre controller Stimulus coprono tutti i casi:
   - `comparison-chart`: barre a due serie (anno precedente in verde, anno corrente in arancio) con la % di differenza disegnata sopra la barra corrente — per i confronti anno su anno.
   - `bar-chart`: barre a singola serie con palette ciclica a 6 colori (`--bs-warning/danger/success/primary/info/dark`), per le distribuzioni sul solo anno corrente. Le etichette sopra le colonne mostrano di norma il conteggio; un valore opzionale `percentages` (aggiunto per Fasce d'Età) permette di mostrare invece la percentuale, senza toccare le sezioni esistenti.
   - `pie-chart`: torta con etichette valore+percentuale scritte direttamente su ogni fetta — per distribuzioni a 2-3 categorie (Sesso, Nazionalità).

4. **Test** — uno spec per servizio (`spec/services/statistics/<nome>_breakdown_spec.rb`: ordinamento, calcolo percentuali, fallback azzonamento superiore, "ignora altri anni") più un `context` dedicato in `total_members_comparison_spec.rb`.

Questo pattern non è stato progettato a tavolino: è emerso costruendo la prima manciata di sezioni e poi è stato seguito deliberatamente per tutte le successive, proprio per garantire che ogni nuova sezione sia prevedibile sia nel codice che nell'aspetto grafico.

### Un esempio completo: Fasce d'Età

`AgeBreakdown` (l'ultima sezione aggiunta) è un buon esempio di come il pattern venga applicato senza rompere i vincoli del progetto (max 100 righe per classe, max 10 per metodo) quando la logica è leggermente più complessa: raggruppare gli iscritti in 9 fasce d'età calcolate da `data_nascita`.

La decisione tecnica più rilevante qui è stata **fare il calcolo interamente in SQL**, con un'unica query raggruppata (`GROUP BY` su un'espressione `CASE`), invece di caricare ogni iscritto in Ruby e calcolare l'età riga per riga:

```ruby
def band_case_sql
  whens = BANDS.filter_map { |fascia, upper| "WHEN #{AGE_EXPR} < #{upper} THEN '#{fascia}'" if upper }
  "CASE #{whens.join(' ')} ELSE 'HIGHLANDERS' END"
end
```

dove `AGE_EXPR = "EXTRACT(YEAR FROM AGE(data_nascita))"`. Il database fa tutto il lavoro pesante; Ruby riceve già un hash `{ "GIOVANI" => 2448, ... }`. Le fasce (`BANDS`) sono una costante hardcoded — nessun input utente entra nella stringa SQL, quindi nessun rischio di SQL injection nonostante l'uso di `Arel.sql`.

### Decisioni che *non* sono ovvie dal codice

Alcune scelte, se non documentate, verrebbero probabilmente "corrette" per errore da chi legge il codice in futuro:

- **Il denominatore della percentuale** nelle distribuzioni a un solo anno è sempre `scope.count` (il totale iscritti del periodo), *non* la somma dei conteggi delle categorie mostrate. Per questo, se alcuni record hanno il campo di interesse nullo (es. `tipologia_status` mancante), le percentuali visualizzate non sommano necessariamente al 100%. Confermato esplicitamente per Status Lavorativo e mantenuto per tutte le sezioni successive dello stesso tipo, Fasce d'Età inclusa.
- **L'età viene calcolata rispetto alla data odierna** (`AGE(data_nascita)` senza secondo argomento in Postgres equivale a "oggi"), non rispetto al mese/anno del periodo selezionato. La fascia d'età risponde alla domanda "quanti anni ha oggi questo iscritto", non "quanti anni aveva nel periodo X".
- **`--bs-secondary` è quasi invisibile** su sfondo bianco nel tema Bootswatch Lumen (`#f0f0f0`): dove serve un colore neutro ma distinguibile nei grafici a barre si usa `--bs-dark` (`#555`).
- Un contenitore di grafico con `width`/`height` custom dentro una card flessibile (`.card`) va sempre abbinato a `width: 100%` prima di `max-width`, altrimenti gli auto-margin di `mx-auto` in un contesto flex lo restringono alle dimensioni di default del canvas (300×150).

### Dove continuare

Le prossime sezioni (quando richieste) seguono lo stesso identico schema a 4 livelli descritto sopra. L'unica vera decisione da prendere ogni volta è: confronto anno su anno o distribuzione a un solo anno? barra, barra-comparativa o torta? serve una tabella aggiuntiva con la "% sul totale iscritti"?

---

## Part 2 — English

### Purpose

The **Statistics** page (`/statistics`) is Fitupe's analytical core: it takes the raw data imported month by month from SinCGIL (the `Import` model, one row per member) and turns it into a readable dashboard — counts, year-over-year comparisons, breakdowns by category, age, gender, nationality, employment status, etc. — filterable by zoning, year, and month.

It is not a CRUD resource: there is no "Statistic" model, no dedicated Pundit policy, no Administrate panel. It's a single page (`StatisticsController#index`) designed to host multiple independent "sections" over time, each with its own service, its own card in the view, and — when needed — its own chart. The nav entry is visible to **all** authenticated users (not just admins/managers), unlike Zonings/Imports/Integrations.

### The form: zoning + year + month

Everything starts from `TotalMembersForm`, an `ActiveModel::Model` (not an `ActiveRecord`, it persists nothing) with three required fields: `zoning_id`, `anno` (a 4-digit string), `mese`. The form uses `method: :get`, so every search is a plain shareable link (`?total_members_form[zoning_id]=4&...`), not a POST.

If either the chosen year or the prior year is missing data, the page doesn't silently show zeros: it shows an explicit `alert-warning` naming the zoning and the missing years. This choice — failing visibly instead of rendering an empty, misleading chart — was a deliberate decision from the very start of the "statistics" phase.

### `ZoningPeriodScope`: the fallback that makes everything else possible

Every single statistics service, without exception, delegates the selection of `Import` rows to one object: `Statistics::ZoningPeriodScope`. This is arguably the single most critical piece of the whole feature, because everything else assumes it.

The problem it solves: a **regional** zoning (e.g. "G" = FVG, a single-letter code) often has no direct imports — the data instead arrives under its **provincial/comprensorio** child zonings (e.g. "GA", "GB", ...). `ZoningPeriodScope` first tries the exact match (`azzonamento_di_riferimento_id`); if nothing is found, it walks up to the parent regional zoning and filters by `codice_azzonamento_completo LIKE "<codice>%"`. The reverse direction — a provincial zoning inheriting from its regional parent — uses the same mechanism.

```ruby
class ZoningPeriodScope
  def call
    exact_scope = Import.where(azzonamento_di_riferimento_id: @zoning.id, anno_di_riferimento: @anno,
      mese_di_riferimento: @mese)
    return exact_scope if exact_scope.exists?

    regional_scope  # walk up to the parent and filter by codice_azzonamento_completo prefix
  end
end
```

This fallback was **not part of the first version**: it was deliberately left out, then reintroduced a few days later because real data required it. That's the kind of decision worth documenting here, since it isn't derivable from the current code alone.

### The section "recipe": a pattern repeated ~10 times

Every section of the page (Comprensori, Categorie, Attivi/Pensionati, Tipologie Iscrizione, Tipologie Delega, Nazionalità, Sesso, Provvisorie/Revoche, Status Lavorativo, Fasce d'Età, ...) follows **exactly the same 4-layer structure**:

1. **Service** in `app/services/statistics/<name>_breakdown.rb` — a class with `Row = Struct.new(..., keyword_init: true)` and `def self.call(...) = new(...).call`. Two recurring shapes exist:
   - **Year-over-year comparison** (`anno:` + `anno_precedente:`, rows with `diff`/`diff_percent`) — e.g. `CategoryBreakdown`, `DelegationTypeBreakdown`.
   - **Current-year-only distribution** (`anno:` only, rows with `percentuale` = share of the total members *for that same zoning/year/month*, not a global total) — e.g. `NationalityBreakdown`, `GenderBreakdown`, `WorkStatusBreakdown`, `AgeBreakdown`.

2. **Wiring** in `Statistics::TotalMembersComparison` — the orchestrator service: it adds a field to `Result` (one shared `Struct` the view reads), populates it in `build_result`, and calls the new service from a one-line private method.

3. **View** — each section is an independent card (`.card.border-dark`) inside `app/views/statistics/_total_iscritti.html.erb`: a 48×48 icon + title, a table, and (when needed) a Chart.js chart. Three Stimulus controllers cover every case:
   - `comparison-chart`: two-series bars (previous year in green, current year in orange) with the % difference drawn above the current-year bar — for year-over-year comparisons.
   - `bar-chart`: single-series bars with a cycling 6-color palette (`--bs-warning/danger/success/primary/info/dark`), for current-year-only distributions. The labels above the columns normally show the count; an optional `percentages` value (added for Fasce d'Età) lets a section show the percentage instead, without touching existing sections.
   - `pie-chart`: a pie with value+percentage labels drawn directly on each slice — for 2-3 category distributions (Gender, Nationality).

4. **Tests** — one spec per service (`spec/services/statistics/<name>_breakdown_spec.rb`: ordering, percentage math, higher-zoning fallback, "ignores other years") plus a dedicated `context` in `total_members_comparison_spec.rb`.

This pattern wasn't designed upfront: it emerged while building the first handful of sections, and was then deliberately followed for every later one, specifically to keep each new section predictable both in code and in appearance.

### A full example: Age Bands (Fasce d'Età)

`AgeBreakdown` (the most recently added section) is a good example of applying the pattern without breaking the project's constraints (max 100 lines per class, max 10 per method) when the logic is slightly more involved: grouping members into 9 age bands computed from `data_nascita`.

The key technical decision here was to **do the computation entirely in SQL**, as a single grouped query (`GROUP BY` on a `CASE` expression), instead of loading every member into Ruby and computing age row by row:

```ruby
def band_case_sql
  whens = BANDS.filter_map { |fascia, upper| "WHEN #{AGE_EXPR} < #{upper} THEN '#{fascia}'" if upper }
  "CASE #{whens.join(' ')} ELSE 'HIGHLANDERS' END"
end
```

where `AGE_EXPR = "EXTRACT(YEAR FROM AGE(data_nascita))"`. The database does all the heavy lifting; Ruby receives an already-grouped hash (`{ "GIOVANI" => 2448, ... }`). The bands (`BANDS`) are a hardcoded constant — no user input ever reaches the SQL string, so there's no injection risk despite the use of `Arel.sql`.

### Decisions that are *not* obvious from the code

Some choices, if left undocumented, would likely get "corrected" by mistake by a future reader:

- **The percentage denominator** in single-year distributions is always `scope.count` (the total members for the period), *not* the sum of the displayed categories' counts. Because of this, if some records have a null value in the field of interest (e.g. missing `tipologia_status`), the displayed percentages don't necessarily add up to 100%. This was explicitly confirmed for Employment Status and kept consistent for every later section of the same shape, Age Bands included.
- **Age is computed relative to today's date** (`AGE(data_nascita)` with no second argument in Postgres means "today"), not relative to the selected period's month/year. The age band answers "how old is this member today," not "how old were they during period X."
- **`--bs-secondary` is nearly invisible** on a white background in the Bootswatch Lumen theme (`#f0f0f0`): wherever a neutral-but-distinguishable bar color is needed, `--bs-dark` (`#555`) is used instead.
- A chart container with a custom `width`/`height` inside a flex card (`.card`) must always pair `width: 100%` with `max-width`, otherwise `mx-auto`'s flex auto-margins shrink it down to Chart.js's default canvas size (300×150).

### Where to continue

Future sections (when requested) follow the exact same 4-layer scheme described above. The only real decision to make each time is: year-over-year comparison or single-year distribution? bar, comparison-bar, or pie chart? does it need an extra "% of total members" table?
