# `Statistics::AgeBreakdown`

**File:** `app/services/statistics/age_breakdown.rb`

## Codice completo

```ruby
module Statistics
  # Distribuzione degli iscritti per fascia d'età (calcolata da data_nascita
  # rispetto alla data odierna) nell'anno corrente, senza confronto con
  # l'anno precedente. Riusa lo stesso fallback sull'azzonamento superiore di
  # ZoningPeriodScope. Le fasce sono calcolate con un'unica query SQL
  # raggruppata (CASE + GROUP BY), senza caricare i singoli iscritti in Ruby.
  class AgeBreakdown
    BANDS = [
      [ "GIOVANI", 30 ],
      [ "TRENTENNI", 40 ],
      [ "QUARANTENNI", 50 ],
      [ "CINQUANTENNI", 60 ],
      [ "SESSANTENNI", 70 ],
      [ "SETTANTENNI", 80 ],
      [ "OTTANTENNI", 90 ],
      [ "NOVANTENNI", 100 ],
      [ "HIGHLANDERS", nil ]
    ].freeze

    AGE_EXPR = "EXTRACT(YEAR FROM AGE(data_nascita))".freeze

    Row = Struct.new(:fascia, :count, :percentuale, keyword_init: true)

    def self.call(...) = new(...).call

    def initialize(zoning:, anno:, mese:)
      @zoning = zoning
      @anno = anno
      @mese = mese
    end

    def call
      BANDS.map { |fascia, _| build_row(fascia) }
    end

    private

    def build_row(fascia)
      count = counts.fetch(fascia, 0)
      percentuale = totale.zero? ? nil : (count.to_f / totale * 100)

      Row.new(fascia:, count:, percentuale:)
    end

    def counts
      @counts ||= scope.where.not(data_nascita: nil).group(Arel.sql(band_case_sql)).count
    end

    def totale
      @totale ||= scope.count
    end

    def scope
      @scope ||= ZoningPeriodScope.call(zoning: @zoning, anno: @anno, mese: @mese)
    end

    def band_case_sql
      whens = BANDS.filter_map { |fascia, upper| "WHEN #{AGE_EXPR} < #{upper} THEN '#{fascia}'" if upper }
      "CASE #{whens.join(' ')} ELSE 'HIGHLANDERS' END"
    end
  end
end
```

## Sezioni commentate

### Commento di classe

```ruby
# Distribuzione degli iscritti per fascia d'età (calcolata da data_nascita
# rispetto alla data odierna) nell'anno corrente, senza confronto con
# l'anno precedente. Riusa lo stesso fallback sull'azzonamento superiore di
# ZoningPeriodScope. Le fasce sono calcolate con un'unica query SQL
# raggruppata (CASE + GROUP BY), senza caricare i singoli iscritti in Ruby.
class AgeBreakdown
```

> **IT:** L'ultima sezione aggiunta alla pagina Statistiche, e l'unica che richiede una trasformazione non banale del dato (da una data di nascita a una fascia d'età) prima di poterlo raggruppare. La decisione tecnica centrale è stata fare **tutto il calcolo in SQL**, con un'unica query raggruppata, invece di caricare ogni iscritto in Ruby e calcolare l'età riga per riga — un requisito esplicito di ottimizzazione delle query. L'età è calcolata rispetto **a oggi**, non rispetto al mese/anno del periodo selezionato: risponde a "quanti anni ha oggi questo iscritto", non "quanti anni aveva nel periodo X".
>
> *EN: The most recently added section on the Statistics page, and the only one that requires a non-trivial data transformation (from a birth date to an age band) before it can be grouped. The central technical decision was to do **the entire computation in SQL**, as a single grouped query, instead of loading every member into Ruby and computing age row by row — an explicit query-optimization requirement. Age is computed relative **to today**, not to the selected period's month/year: it answers "how old is this member today," not "how old were they during period X."*

### `BANDS` (costante)

```ruby
BANDS = [
  [ "GIOVANI", 30 ],
  [ "TRENTENNI", 40 ],
  [ "QUARANTENNI", 50 ],
  [ "CINQUANTENNI", 60 ],
  [ "SESSANTENNI", 70 ],
  [ "SETTANTENNI", 80 ],
  [ "OTTANTENNI", 90 ],
  [ "NOVANTENNI", 100 ],
  [ "HIGHLANDERS", nil ]
].freeze
```

> **IT:** Ogni coppia è `[etichetta, limite_superiore_esclusivo]`: "GIOVANI" copre età < 30, "TRENTENNI" copre 30 ≤ età < 40, e così via, fino a "HIGHLANDERS" che non ha limite superiore (`nil`) e copre età ≥ 100. È l'unica fonte di verità sia per l'ordine di visualizzazione (usato in `call`) sia per la logica di raggruppamento SQL (usato in `band_case_sql`) — cambiare i confini delle fasce richiede di modificare solo questo array.
>
> *EN: Each pair is `[label, exclusive_upper_bound]`: "GIOVANI" covers age < 30, "TRENTENNI" covers 30 ≤ age < 40, and so on, up to "HIGHLANDERS", which has no upper bound (`nil`) and covers age ≥ 100. It's the single source of truth both for the display order (used in `call`) and for the SQL grouping logic (used in `band_case_sql`) — changing the band boundaries only requires editing this array.*

### `AGE_EXPR` (costante)

```ruby
AGE_EXPR = "EXTRACT(YEAR FROM AGE(data_nascita))".freeze
```

> **IT:** L'espressione SQL (dialetto PostgreSQL) che calcola l'età in anni interi compiuti a partire da `data_nascita`. `AGE(data_nascita)` senza secondo argomento equivale, in Postgres, a `AGE(CURRENT_DATE, data_nascita)`: la data di riferimento è quindi sempre "oggi", indipendentemente dal mese/anno scelto nel form.
>
> *EN: The SQL expression (PostgreSQL dialect) that computes the age in full completed years from `data_nascita`. `AGE(data_nascita)` with no second argument is, in Postgres, equivalent to `AGE(CURRENT_DATE, data_nascita)`: the reference date is therefore always "today", regardless of the month/year chosen in the form.*

### `Row` (Struct)

```ruby
Row = Struct.new(:fascia, :count, :percentuale, keyword_init: true)
```

> **IT:** Forma "distribuzione a un solo anno" standard, identica nella struttura a `WorkStatusBreakdown::Row` — solo il nome del primo campo cambia (`fascia` invece di `tipologia_status`).
>
> *EN: The standard "single-year distribution" shape, structurally identical to `WorkStatusBreakdown::Row` — only the first field's name differs (`fascia` instead of `tipologia_status`).*

### `call`

```ruby
def call
  BANDS.map { |fascia, _| build_row(fascia) }
end
```

> **IT:** Itera su `BANDS` (non su `counts.keys`), quindi tutte e nove le fasce compaiono sempre nella tabella e nel grafico, **nell'ordine crescente d'età**, anche quelle con zero iscritti — a differenza di `WorkStatusBreakdown`, dove compaiono solo le categorie effettivamente presenti nei dati.
>
> *EN: Iterates over `BANDS` (not over `counts.keys`), so all nine bands always appear in the table and chart, **in ascending age order**, even those with zero members — unlike `WorkStatusBreakdown`, where only the categories actually present in the data show up.*

### `build_row` *(privato)*

```ruby
def build_row(fascia)
  count = counts.fetch(fascia, 0)
  percentuale = totale.zero? ? nil : (count.to_f / totale * 100)

  Row.new(fascia:, count:, percentuale:)
end
```

> **IT:** `counts.fetch(fascia, 0)` gestisce il caso in cui una fascia non compaia affatto nel risultato della query raggruppata (es. nessun iscritto ultracentenario): viene mostrata comunque, con conteggio 0, invece di sparire dalla tabella.
>
> *EN: `counts.fetch(fascia, 0)` handles the case where a band doesn't appear at all in the grouped query's result (e.g. no member is over 100 years old): it's still shown, with a count of 0, instead of disappearing from the table.*

### `counts` *(privato)*

```ruby
def counts
  @counts ||= scope.where.not(data_nascita: nil).group(Arel.sql(band_case_sql)).count
end
```

> **IT:** Il punto centrale della classe. `scope.where.not(data_nascita: nil)` esclude i record senza data di nascita (che restano comunque conteggiati in `totale`, come per `tipologia_status` in `WorkStatusBreakdown`). `.group(Arel.sql(band_case_sql))` raggruppa non su una colonna semplice ma sull'espressione SQL `CASE` costruita da `band_case_sql`: il database calcola la fascia di ciascun record e la usa direttamente come chiave di raggruppamento, restituendo un hash già pronto (`{ "GIOVANI" => 2448, ... }`) — **una sola query**, nessun record `Import` caricato individualmente in memoria Ruby. `Arel.sql(...)` è necessario perché Rails, per proteggersi da SQL injection, per default tratta le stringhe passate a `.group` come identificatori da quotare (es. nomi di colonna), non come espressioni SQL grezze da eseguire così come sono.
>
> *EN: The class's central point. `scope.where.not(data_nascita: nil)` excludes records with no birth date (which are still counted in `totale`, just as `tipologia_status` is in `WorkStatusBreakdown`). `.group(Arel.sql(band_case_sql))` groups not by a plain column but by the SQL `CASE` expression built in `band_case_sql`: the database computes each record's band and uses it directly as the grouping key, returning an already-ready hash (`{ "GIOVANI" => 2448, ... }`) — **a single query**, no `Import` record individually loaded into Ruby memory. `Arel.sql(...)` is required because Rails, to protect against SQL injection, by default treats strings passed to `.group` as identifiers to be quoted (e.g. column names), not as raw SQL expressions to execute as-is.*

### `totale` *(privato)*

```ruby
def totale
  @totale ||= scope.count
end
```

> **IT:** Stesso pattern di `WorkStatusBreakdown#totale`: il denominatore è **tutti** gli iscritti del periodo (`scope.count`), non la somma delle nove fasce mostrate. Se alcuni iscritti non hanno `data_nascita` valorizzata, le percentuali visualizzate non sommeranno esattamente al 100%.
>
> *EN: The same pattern as `WorkStatusBreakdown#totale`: the denominator is **every** member of the period (`scope.count`), not the sum of the nine displayed bands. If some members have no `data_nascita` set, the displayed percentages won't add up to exactly 100%.*

### `scope` *(privato)*

```ruby
def scope
  @scope ||= ZoningPeriodScope.call(zoning: @zoning, anno: @anno, mese: @mese)
end
```

> **IT:** Identico, riga per riga, al metodo `scope` di ogni altro breakdown della cartella: passa sempre attraverso `ZoningPeriodScope`, mai una query `Import` diretta.
>
> *EN: Identical, line for line, to the `scope` method in every other breakdown in this folder: it always goes through `ZoningPeriodScope`, never a direct `Import` query.*

### `band_case_sql` *(privato)*

```ruby
def band_case_sql
  whens = BANDS.filter_map { |fascia, upper| "WHEN #{AGE_EXPR} < #{upper} THEN '#{fascia}'" if upper }
  "CASE #{whens.join(' ')} ELSE 'HIGHLANDERS' END"
end
```

> **IT:** Costruisce dinamicamente la stringa SQL `CASE WHEN ... THEN ... ELSE 'HIGHLANDERS' END` a partire da `BANDS`. `filter_map` scarta automaticamente l'ultima coppia (`["HIGHLANDERS", nil]`, dove `upper` è `nil`) dal blocco `WHEN`, perché quella fascia è già coperta dal ramo `ELSE` finale — è per questo che "HIGHLANDERS" è hardcoded nell'`ELSE` invece di essere generato dal loop. **Nota di sicurezza:** anche se questa stringa viene costruita per interpolazione e passata via `Arel.sql` (che bypassa l'escaping automatico di Rails), non c'è rischio di SQL injection perché `BANDS` è una costante interamente hardcoded nel codice sorgente — nessun input proveniente dall'utente (form, parametri HTTP) entra mai in questa stringa.
>
> *EN: Dynamically builds the SQL string `CASE WHEN ... THEN ... ELSE 'HIGHLANDERS' END` from `BANDS`. `filter_map` automatically drops the last pair (`["HIGHLANDERS", nil]`, where `upper` is `nil`) from the `WHEN` clauses, because that band is already covered by the final `ELSE` branch — which is why "HIGHLANDERS" is hardcoded in the `ELSE` instead of being generated by the loop. **Security note:** even though this string is built via interpolation and passed through `Arel.sql` (which bypasses Rails' automatic escaping), there's no SQL injection risk because `BANDS` is a constant entirely hardcoded in the source code — no user-supplied input (form, HTTP params) ever reaches this string.*
