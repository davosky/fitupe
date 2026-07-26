# `Statistics::CategoryBreakdown`

**File:** `app/services/statistics/category_breakdown.rb`

## Codice completo

```ruby
module Statistics
  # Una riga per ciascuna categoria sindacale presente nell'azzonamento
  # scelto (es. FILCAMS, FILLEA, ...), confrontando anno e anno precedente.
  # Riusa lo stesso fallback sull'azzonamento superiore di ZoningPeriodScope.
  class CategoryBreakdown
    Row = Struct.new(:categoria, :count_anno, :count_precedente, :diff, :diff_percent, keyword_init: true)

    def self.call(...) = new(...).call

    def initialize(zoning:, anno:, anno_precedente:, mese:)
      @zoning = zoning
      @anno = anno
      @anno_precedente = anno_precedente
      @mese = mese
    end

    def call
      categorie_presenti.map { |categoria| build_row(categoria) }
    end

    private

    def categorie_presenti
      (counts_anno.keys + counts_precedente.keys).uniq.sort
    end

    def build_row(categoria)
      count_anno = counts_anno.fetch(categoria, 0)
      count_precedente = counts_precedente.fetch(categoria, 0)
      diff = count_anno - count_precedente
      diff_percent = count_precedente.zero? ? nil : (diff.to_f / count_precedente * 100)

      Row.new(categoria:, count_anno:, count_precedente:, diff:, diff_percent:)
    end

    def counts_anno
      @counts_anno ||= counts_for(@anno)
    end

    def counts_precedente
      @counts_precedente ||= counts_for(@anno_precedente)
    end

    def counts_for(anno)
      scope = ZoningPeriodScope.call(zoning: @zoning, anno:, mese: @mese)
      scope.where.not(categoria_column(scope) => nil).group(categoria_column(scope)).count
    end

    # La categoria sindacale è stata importata sotto nomi di colonna diversi a
    # seconda dell'intestazione esatta dell'export SinCGIL nel tempo
    # ("Categoria Sindacale" vs "Categoria"). Preferisce categoria_sindacale
    # quando lo scope ha davvero dati in quella colonna, altrimenti categoria.
    def categoria_column(scope)
      if Import.column_names.include?("categoria_sindacale") && scope.where.not(categoria_sindacale: nil).exists?
        :categoria_sindacale
      else
        :categoria
      end
    end
  end
end
```

## Sezioni commentate

### Commento di classe

```ruby
# Una riga per ciascuna categoria sindacale presente nell'azzonamento
# scelto (es. FILCAMS, FILLEA, ...), confrontando anno e anno precedente.
# Riusa lo stesso fallback sull'azzonamento superiore di ZoningPeriodScope.
class CategoryBreakdown
```

> **IT:** Prima sezione "vera" del breakdown per categoria costruita nella pagina Statistiche: a differenza di Attivi/Pensionati (che raggruppa in solo due gruppi fissi), qui il numero di righe è dinamico e dipende da quali categorie sindacali sono effettivamente presenti nei dati.
>
> *EN: The first "real" per-category breakdown built into the Statistics page: unlike Attivi/Pensionati (which groups into only two fixed buckets), here the number of rows is dynamic and depends on which union categories are actually present in the data.*

### `Row` (Struct)

```ruby
Row = Struct.new(:categoria, :count_anno, :count_precedente, :diff, :diff_percent, keyword_init: true)
```

> **IT:** Forma "confronto anno su anno": niente campo `percentuale` qui (a differenza dei breakdown a un solo anno) — la tabella e il grafico mostrano solo il conteggio dei due anni e la differenza.
>
> *EN: The "year-over-year comparison" shape: no `percentuale` field here (unlike the single-year breakdowns) — the table and chart only show the two years' counts and the difference.*

### `def self.call(...)` / `initialize`

```ruby
def self.call(...) = new(...).call

def initialize(zoning:, anno:, anno_precedente:, mese:)
  @zoning = zoning
  @anno = anno
  @anno_precedente = anno_precedente
  @mese = mese
end
```

> **IT:** A differenza dei breakdown a un solo anno (es. `GenderBreakdown`), questo servizio riceve esplicitamente `anno_precedente` da `TotalMembersComparison` — non lo calcola da sé.
>
> *EN: Unlike the single-year breakdowns (e.g. `GenderBreakdown`), this service explicitly receives `anno_precedente` from `TotalMembersComparison` — it doesn't compute it on its own.*

### `call`

```ruby
def call
  categorie_presenti.map { |categoria| build_row(categoria) }
end
```

> **IT:** Itera sull'unione delle categorie viste nei due anni, non su un elenco fisso: se una categoria esisteva solo l'anno scorso (ed è sparita quest'anno) o viceversa, compare comunque con conteggio 0 nell'anno mancante.
>
> *EN: Iterates over the union of categories seen across the two years, not a fixed list: if a category existed only last year (and disappeared this year) or vice versa, it still shows up with a 0 count for the missing year.*

### `categorie_presenti` *(privato)*

```ruby
def categorie_presenti
  (counts_anno.keys + counts_precedente.keys).uniq.sort
end
```

> **IT:** Unisce le chiavi (nomi categoria) dei due hash di conteggio, elimina i duplicati e ordina alfabeticamente — questo determina l'ordine delle righe in tabella e delle barre nel grafico.
>
> *EN: Merges the keys (category names) from the two count hashes, removes duplicates, and sorts alphabetically — this determines the row order in the table and the bar order in the chart.*

### `build_row` *(privato)*

```ruby
def build_row(categoria)
  count_anno = counts_anno.fetch(categoria, 0)
  count_precedente = counts_precedente.fetch(categoria, 0)
  diff = count_anno - count_precedente
  diff_percent = count_precedente.zero? ? nil : (diff.to_f / count_precedente * 100)

  Row.new(categoria:, count_anno:, count_precedente:, diff:, diff_percent:)
end
```

> **IT:** `fetch(categoria, 0)` (non `[]`) rende esplicito che una categoria assente in uno dei due hash equivale a zero iscritti quell'anno, non a un errore. `diff_percent` resta `nil` quando l'anno precedente aveva zero iscritti in quella categoria, per evitare una divisione per zero o un fuorviante "+∞%".
>
> *EN: `fetch(categoria, 0)` (not `[]`) makes it explicit that a category missing from either hash means zero members that year, not an error. `diff_percent` stays `nil` when the previous year had zero members in that category, avoiding a division by zero or a misleading "+∞%".*

### `counts_anno`, `counts_precedente`, `counts_for` *(privati)*

```ruby
def counts_anno
  @counts_anno ||= counts_for(@anno)
end

def counts_precedente
  @counts_precedente ||= counts_for(@anno_precedente)
end

def counts_for(anno)
  scope = ZoningPeriodScope.call(zoning: @zoning, anno:, mese: @mese)
  scope.where.not(categoria_column(scope) => nil).group(categoria_column(scope)).count
end
```

> **IT:** `counts_for` esegue **una sola query SQL raggruppata** (`GROUP BY`) per anno, non una query per categoria: `scope.group(...).count` restituisce direttamente un hash `{ "FILCAMS" => 6275, "FILLEA" => 1498, ... }`. I risultati sono memoizzati (`||=`) perché sia `categorie_presenti` sia più chiamate a `build_row` leggono lo stesso hash.
>
> *EN: `counts_for` runs **a single grouped SQL query** (`GROUP BY`) per year, not one query per category: `scope.group(...).count` returns a hash directly (`{ "FILCAMS" => 6275, "FILLEA" => 1498, ... }`). The results are memoized (`||=`) because both `categorie_presenti` and multiple calls to `build_row` read the same hash.*

### `categoria_column` *(privato)*

```ruby
# La categoria sindacale è stata importata sotto nomi di colonna diversi a
# seconda dell'intestazione esatta dell'export SinCGIL nel tempo
# ("Categoria Sindacale" vs "Categoria"). Preferisce categoria_sindacale
# quando lo scope ha davvero dati in quella colonna, altrimenti categoria.
def categoria_column(scope)
  if Import.column_names.include?("categoria_sindacale") && scope.where.not(categoria_sindacale: nil).exists?
    :categoria_sindacale
  else
    :categoria
  end
end
```

> **IT:** Gestisce un problema reale di dati storici: gli export CSV di SinCGIL hanno cambiato nome colonna nel tempo, quindi import più vecchi possono avere solo `categoria` valorizzata mentre import più recenti hanno `categoria_sindacale`. Il controllo `Import.column_names.include?` protegge anche il caso in cui la colonna non esista ancora nello schema (utile durante lo sviluppo/migrazione). Questo stesso metodo, identico, si ritrova in `EmploymentStatusBreakdown` — è uno dei pochi punti di duplicazione deliberata nella cartella, non ancora estratto in un modulo condiviso.
>
> *EN: Handles a real historical-data issue: SinCGIL's CSV exports changed the column name over time, so older imports may only have `categoria` populated while newer ones have `categoria_sindacale`. The `Import.column_names.include?` check also guards against the column not existing yet in the schema (useful during development/migration). This exact same method also appears in `EmploymentStatusBreakdown` — it's one of the few points of deliberate duplication in this folder, not yet extracted into a shared module.*
