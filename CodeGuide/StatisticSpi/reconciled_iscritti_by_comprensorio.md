# `StatisticSpi::ReconciledIscrittiByComprensorio`

**File:** `app/services/statistic_spi/reconciled_iscritti_by_comprensorio.rb`

## Codice completo

```ruby
module StatisticSpi
  # Assegna ogni codice_fiscale a UN SOLO comprensorio "primario" (il primo
  # alfabeticamente tra i codice_azzonamento_completo in cui compare), cosi'
  # il totale iscritti per comprensorio resta additivo rispetto al regionale.
  # Necessario per gli SPI (a differenza degli Attivi): uno stesso pensionato
  # puo' avere piu' deleghe in comprensori diversi (reversibilita', invalidita',
  # vedi .ai/Spi/pensionati.md), che altrimenti verrebbe contato una volta per
  # ciascun comprensorio in cui compare, gonfiando la somma rispetto al totale
  # regionale (COUNT DISTINCT codice_fiscale).
  class ReconciledIscrittiByComprensorio
    def self.call(scope) = new(scope).call

    def initialize(scope)
      @scope = scope
    end

    def call
      ActiveRecord::Base.connection.select_all(sql).each_with_object({}) do |row, counts|
        counts[row["comprensorio"]] = row["totale"].to_i
      end
    end

    private

    def sql
      <<~SQL
        WITH base AS (#{@scope.to_sql}),
        comprensorio_primario AS (
          SELECT DISTINCT ON (codice_fiscale)
            codice_fiscale,
            SUBSTRING(codice_azzonamento_completo FROM 1 FOR 2) AS comprensorio
          FROM base
          ORDER BY codice_fiscale, codice_azzonamento_completo
        )
        SELECT comprensorio, COUNT(*) AS totale
        FROM comprensorio_primario
        GROUP BY comprensorio
      SQL
    end
  end
end
```

## Sezioni commentate

### Commento di classe

```ruby
# Assegna ogni codice_fiscale a UN SOLO comprensorio "primario" (il primo
# alfabeticamente tra i codice_azzonamento_completo in cui compare), cosi'
# il totale iscritti per comprensorio resta additivo rispetto al regionale.
# Necessario per gli SPI (a differenza degli Attivi): uno stesso pensionato
# puo' avere piu' deleghe in comprensori diversi (reversibilita', invalidita',
# vedi .ai/Spi/pensionati.md), che altrimenti verrebbe contato una volta per
# ciascun comprensorio in cui compare, gonfiando la somma rispetto al totale
# regionale (COUNT DISTINCT codice_fiscale).
class ReconciledIscrittiByComprensorio
```

> **IT:** Questa è la classe che non ha equivalente nella cartella `Statistics/`, ed è il punto di partenza per capire l'intera sezione SPI: negli Attivi, un iscritto ha *un'unica* riga `Import` per periodo, quindi "conta le righe" e "conta gli iscritti distinti" coincidono. Negli SPI, `ImportSpi` conta **deleghe**, non iscritti: un pensionato con reversibilità e pensione propria genera due righe (vedi `.ai/Spi/pensionati.md`), che possono anche cadere in due comprensori diversi. Senza questa riconciliazione, sommare "iscritti per comprensorio" darebbe un numero maggiore del totale regionale (`COUNT DISTINCT codice_fiscale` sull'intera regione) — un bug silenzioso di sovraconteggio, non un crash, per questo la classe esiste come passaggio esplicito e isolato invece che come dettaglio interno di un solo breakdown.
>
> *EN: This is the one class with no equivalent in the `Statistics/` folder, and it's the starting point for understanding the whole SPI section: for Attivi, a member has exactly *one* `Import` row per period, so "count the rows" and "count distinct members" are the same thing. For SPI, `ImportSpi` counts **delegations**, not members: a pensioner with both a survivor's pension and their own pension generates two rows (see `.ai/Spi/pensionati.md`), which can even fall under two different comprensori. Without this reconciliation, summing "members per comprensorio" would yield a number larger than the regional total (`COUNT DISTINCT codice_fiscale` across the whole region) — a silent over-counting bug, not a crash, which is why this exists as an explicit, isolated step rather than as an internal detail of a single breakdown.*

### `def self.call(scope)` / `initialize`

```ruby
def self.call(scope) = new(scope).call

def initialize(scope)
  @scope = scope
end
```

> **IT:** A differenza di ogni altro servizio SPI (che accetta `zoning:`, `anno:`, `mese:` come keyword argument), questo accetta un **unico argomento posizionale**: uno scope `ActiveRecord::Relation` già risolto. Non chiama `ZoningPeriodScope` internamente — il chiamante (`TotalMembersComparison#count_by_comprensorio`) deve avergli già passato `scope_for(anno)`. Questo lo rende riusabile su qualunque scope `ImportSpi`, non solo su quello del periodo corrente, ma nella pratica ha un solo chiamante.
>
> *EN: Unlike every other SPI service (which accepts `zoning:`, `anno:`, `mese:` as keyword arguments), this one takes a **single positional argument**: an already-resolved `ActiveRecord::Relation` scope. It doesn't call `ZoningPeriodScope` internally — the caller (`TotalMembersComparison#count_by_comprensorio`) must have already passed it `scope_for(anno)`. This makes it reusable against any `ImportSpi` scope, not just the current period's, but in practice it has exactly one caller.*

### `call`

```ruby
def call
  ActiveRecord::Base.connection.select_all(sql).each_with_object({}) do |row, counts|
    counts[row["comprensorio"]] = row["totale"].to_i
  end
end
```

> **IT:** Esegue la query grezza via `ActiveRecord::Base.connection.select_all` (non `ActiveRecord::Base.find_by_sql` né un `.group(...).count`) perché il risultato non mappa a nessun modello — sono righe aggregate `comprensorio`/`totale` prodotte da una CTE, non record `ImportSpi`. Il risultato è un hash semplice `{ "GA" => 120, "GB" => 87, ... }`, la stessa forma restituita da `.group(...).count` altrove nel progetto, così i chiamanti possono trattarlo allo stesso modo (`counts.fetch(comprensorio, 0)`).
>
> *EN: Runs the raw query via `ActiveRecord::Base.connection.select_all` (not `ActiveRecord::Base.find_by_sql`, not a `.group(...).count`) because the result doesn't map to any model — it's aggregated `comprensorio`/`totale` rows produced by a CTE, not `ImportSpi` records. The result is a plain hash, `{ "GA" => 120, "GB" => 87, ... }`, the same shape returned by `.group(...).count` elsewhere in the project, so callers can treat it the same way (`counts.fetch(comprensorio, 0)`).*

### `sql` *(privato)*

```ruby
def sql
  <<~SQL
    WITH base AS (#{@scope.to_sql}),
    comprensorio_primario AS (
      SELECT DISTINCT ON (codice_fiscale)
        codice_fiscale,
        SUBSTRING(codice_azzonamento_completo FROM 1 FOR 2) AS comprensorio
      FROM base
      ORDER BY codice_fiscale, codice_azzonamento_completo
    )
    SELECT comprensorio, COUNT(*) AS totale
    FROM comprensorio_primario
    GROUP BY comprensorio
  SQL
end
```

> **IT:** Il nucleo tecnico di tutta la sezione SPI, riusato (con piccole variazioni) in `AgeBreakdown` e `MultipleDelegationsBreakdown`. Tre passaggi:
>
> 1. `base` materializza lo scope Rails (`@scope.to_sql`) come CTE, così il resto della query può interrogarlo ripetutamente senza rieseguire i filtri `WHERE` di `ZoningPeriodScope`.
> 2. `comprensorio_primario` usa `DISTINCT ON (codice_fiscale)` — un'estensione PostgreSQL (non SQL standard, non disponibile in MySQL/SQLite) — per tenere **una sola riga per codice fiscale**: quella con il `codice_azzonamento_completo` alfabeticamente più piccolo tra tutte le deleghe di quella persona. `ORDER BY codice_fiscale, codice_azzonamento_completo` è obbligatorio con `DISTINCT ON`: Postgres tiene la prima riga di ogni gruppo secondo quell'ordinamento. Il criterio "primo alfabeticamente" è arbitrario ma deterministico — non c'è un concetto di comprensorio "corretto" tra due deleghe della stessa persona, serve solo che la scelta sia stabile e che ogni persona venga assegnata a **esattamente uno** dei comprensori in cui compare.
> 3. Il `GROUP BY comprensorio` finale conta quante persone (non deleghe) sono state assegnate a ciascun comprensorio.
>
> Il risultato: `SUM(totale per comprensorio) == COUNT(DISTINCT codice_fiscale)` sull'intera regione, sempre, per costruzione — è la proprietà che rende "additivo" il totale.
>
> *EN: The technical core of the whole SPI section, reused (with small variations) in `AgeBreakdown` and `MultipleDelegationsBreakdown`. Three steps:
>
> 1. `base` materializes the Rails scope (`@scope.to_sql`) as a CTE, so the rest of the query can query it repeatedly without re-running `ZoningPeriodScope`'s `WHERE` filters.
> 2. `comprensorio_primario` uses `DISTINCT ON (codice_fiscale)` — a PostgreSQL extension (not standard SQL, not available in MySQL/SQLite) — to keep **exactly one row per tax code**: the one with the alphabetically smallest `codice_azzonamento_completo` among that person's delegations. `ORDER BY codice_fiscale, codice_azzonamento_completo` is mandatory with `DISTINCT ON`: Postgres keeps the first row of each group according to that ordering. The "alphabetically first" criterion is arbitrary but deterministic — there's no notion of a "correct" comprensorio between two delegations belonging to the same person, it just needs to be a stable choice that assigns each person to **exactly one** of the comprensori they appear in.
> 3. The final `GROUP BY comprensorio` counts how many people (not delegations) were assigned to each comprensorio.
>
> The result: `SUM(total per comprensorio) == COUNT(DISTINCT codice_fiscale)` across the whole region, always, by construction — that's the property that makes the total "additive".*

### Perché non è stata riusata per `MultipleDelegationsBreakdown` e `AgeBreakdown`

> **IT:** Sia `AgeBreakdown` che `MultipleDelegationsBreakdown` reimplementano una propria variante di `DISTINCT ON (codice_fiscale)` dentro la propria CTE, invece di chiamare questa classe e poi fare un secondo giro di query. Il motivo: entrambi hanno bisogno di **altri dati insieme** al comprensorio primario nella stessa riga (`data_nascita` per `AgeBreakdown`, il conteggio totale delle occorrenze per `MultipleDelegationsBreakdown`), quindi la riconciliazione va fatta come parte della stessa query SQL, non come post-elaborazione su un risultato già aggregato da `ReconciledIscrittiByComprensorio`. Questa classe resta quindi lo strumento giusto solo quando serve *unicamente* il conteggio persone per comprensorio (il caso di `TotalMembersComparison`), non quando serve incrociarlo con un'altra dimensione.
>
> *EN: Both `AgeBreakdown` and `MultipleDelegationsBreakdown` reimplement their own variant of `DISTINCT ON (codice_fiscale)` inside their own CTE, instead of calling this class and then running a second query pass. The reason: both need **other data alongside** the primary comprensorio in the same row (`data_nascita` for `AgeBreakdown`, the total occurrence count for `MultipleDelegationsBreakdown`), so the reconciliation has to happen as part of the same SQL query, not as post-processing on a result already aggregated by `ReconciledIscrittiByComprensorio`. This class therefore remains the right tool only when *just* the person-count-per-comprensorio is needed (the `TotalMembersComparison` case), not when it needs to be crossed with another dimension.*
