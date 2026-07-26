# `Statistics::EmploymentStatusBreakdown`

**File:** `app/services/statistics/employment_status_breakdown.rb`

## Codice completo

```ruby
module Statistics
  # Confronta il totale degli iscritti "Attivi" (tutte le categorie tranne
  # SPI) con quello dei "Pensionati" (categoria SPI), anno su anno. Riusa lo
  # stesso fallback sull'azzonamento superiore di ZoningPeriodScope.
  class EmploymentStatusBreakdown
    SPI = "SPI".freeze

    Row = Struct.new(:gruppo, :count_anno, :count_precedente, :diff, :diff_percent, :percentuale, keyword_init: true)

    def self.call(...) = new(...).call

    def initialize(zoning:, anno:, anno_precedente:, mese:)
      @zoning = zoning
      @anno = anno
      @anno_precedente = anno_precedente
      @mese = mese
    end

    def call
      [ build_row("Attivi", :attivi), build_row("Pensionati", :pensionati) ]
    end

    private

    def build_row(gruppo, kind)
      count_anno = count_for(@anno, kind)
      count_precedente = count_for(@anno_precedente, kind)
      diff = count_anno - count_precedente
      diff_percent = count_precedente.zero? ? nil : (diff.to_f / count_precedente * 100)
      percentuale = totale_anno.zero? ? nil : (count_anno.to_f / totale_anno * 100)

      Row.new(gruppo:, count_anno:, count_precedente:, diff:, diff_percent:, percentuale:)
    end

    def count_for(anno, kind)
      scope = ZoningPeriodScope.call(zoning: @zoning, anno:, mese: @mese)
      pensionati = scope.where(categoria_column(scope) => SPI).count
      kind == :pensionati ? pensionati : scope.count - pensionati
    end

    def totale_anno
      @totale_anno ||= ZoningPeriodScope.call(zoning: @zoning, anno: @anno, mese: @mese).count
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
# Confronta il totale degli iscritti "Attivi" (tutte le categorie tranne
# SPI) con quello dei "Pensionati" (categoria SPI), anno su anno. Riusa lo
# stesso fallback sull'azzonamento superiore di ZoningPeriodScope.
class EmploymentStatusBreakdown
```

> **IT:** Un breakdown "totale meno uno": invece di raggruppare per un campo con N valori possibili, divide gli iscritti in due soli gruppi complementari usando una sola categoria speciale (SPI = pensionati) come spartiacque. Lo stesso schema si ritrova, quasi identico, in `MembershipTypeBreakdown` (Delega vs BreviManu).
>
> *EN: A "total minus one" breakdown: instead of grouping by a field with N possible values, it splits members into just two complementary groups using one special category (SPI = pensioners) as the dividing line. The same shape appears, almost identically, in `MembershipTypeBreakdown` (Delega vs BreviManu).*

### `SPI` (costante)

```ruby
SPI = "SPI".freeze
```

> **IT:** Il valore esatto della colonna categoria che identifica un pensionato nei dati SinCGIL. Estratto in costante per non ripetere la stringa magica e per rendere il confronto (`scope.where(categoria_column(scope) => SPI)`) autoesplicativo.
>
> *EN: The exact category-column value that identifies a pensioner in the SinCGIL data. Extracted into a constant to avoid repeating the magic string and to make the comparison (`scope.where(categoria_column(scope) => SPI)`) self-explanatory.*

### `Row` (Struct)

```ruby
Row = Struct.new(:gruppo, :count_anno, :count_precedente, :diff, :diff_percent, :percentuale, keyword_init: true)
```

> **IT:** L'unico breakdown "ibrido" della cartella: ha sia i campi del confronto anno su anno (`diff`, `diff_percent`) sia il campo `percentuale` tipico dei breakdown a un solo anno. Questo perché la sezione mostra in vista sia il grafico comparativo anno su anno sia una tabella con la "% sul totale iscritti" a fianco.
>
> *EN: The only "hybrid" breakdown in this folder: it has both the year-over-year comparison fields (`diff`, `diff_percent`) and the `percentuale` field typical of single-year breakdowns. That's because the view shows both the year-over-year comparison chart and a table with "% of total members" next to it.*

### `call`

```ruby
def call
  [ build_row("Attivi", :attivi), build_row("Pensionati", :pensionati) ]
end
```

> **IT:** Sempre esattamente due righe, in quest'ordine fisso — a differenza di `CategoryBreakdown` o `WorkStatusBreakdown` dove il numero di righe dipende dai dati. `:attivi`/`:pensionati` sono simboli usati solo internamente da `build_row`/`count_for` per scegliere quale ramo calcolare.
>
> *EN: Always exactly two rows, in this fixed order — unlike `CategoryBreakdown` or `WorkStatusBreakdown`, where the row count depends on the data. `:attivi`/`:pensionati` are symbols used only internally by `build_row`/`count_for` to pick which branch to compute.*

### `build_row` *(privato)*

```ruby
def build_row(gruppo, kind)
  count_anno = count_for(@anno, kind)
  count_precedente = count_for(@anno_precedente, kind)
  diff = count_anno - count_precedente
  diff_percent = count_precedente.zero? ? nil : (diff.to_f / count_precedente * 100)
  percentuale = totale_anno.zero? ? nil : (count_anno.to_f / totale_anno * 100)

  Row.new(gruppo:, count_anno:, count_precedente:, diff:, diff_percent:, percentuale:)
end
```

> **IT:** `percentuale` è calcolata solo sull'anno corrente (`count_anno` su `totale_anno`), mai sull'anno precedente — coerente con il fatto che la tabella "% sul totale iscritti" nella vista mostra un solo anno.
>
> *EN: `percentuale` is computed only for the current year (`count_anno` over `totale_anno`), never for the previous year — consistent with the "% of total members" table in the view showing only one year.*

### `count_for` *(privato)*

```ruby
def count_for(anno, kind)
  scope = ZoningPeriodScope.call(zoning: @zoning, anno:, mese: @mese)
  pensionati = scope.where(categoria_column(scope) => SPI).count
  kind == :pensionati ? pensionati : scope.count - pensionati
end
```

> **IT:** Non esiste una query diretta per "Attivi": il conteggio degli attivi è sempre `totale - pensionati`. Questo garantisce che Attivi + Pensionati sommino sempre esattamente al totale iscritti del periodo, per costruzione, senza bisogno di verificarlo a parte.
>
> *EN: There's no direct query for "Attivi": the active-members count is always `total - pensioners`. This guarantees that Attivi + Pensionati always sum exactly to the period's total membership, by construction, without needing a separate check.*

### `totale_anno` *(privato)*

```ruby
def totale_anno
  @totale_anno ||= ZoningPeriodScope.call(zoning: @zoning, anno: @anno, mese: @mese).count
end
```

> **IT:** Nota bene: è calcolato **solo** per `@anno` (l'anno corrente), non parametrizzato per anno come `count_for` — coerente con `percentuale` che riguarda solo l'anno corrente.
>
> *EN: Note: it's computed **only** for `@anno` (the current year), not parameterized by year like `count_for` — consistent with `percentuale`, which only concerns the current year.*

### `categoria_column` *(privato)*

```ruby
def categoria_column(scope)
  if Import.column_names.include?("categoria_sindacale") && scope.where.not(categoria_sindacale: nil).exists?
    :categoria_sindacale
  else
    :categoria
  end
end
```

> **IT:** Identico a `CategoryBreakdown#categoria_column` — vedi la spiegazione lì per il perché esiste (cambio di nome colonna negli export SinCGIL nel tempo). Duplicato qui invece che condiviso: è uno dei punti dove il progetto ha scelto la ripetizione a una piccola astrazione condivisa.
>
> *EN: Identical to `CategoryBreakdown#categoria_column` — see the explanation there for why it exists (the SinCGIL export's column name changing over time). Duplicated here rather than shared: this is one of the points where the project chose repetition over a small shared abstraction.*
