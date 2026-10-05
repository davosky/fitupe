# `Statistics::CategoryCrossBreakdown`

**File:** `app/services/statistics/category_cross_breakdown.rb`

## Codice completo

```ruby
module Statistics
  # Una riga per categoria sindacale, con il conteggio e la percentuale (sul
  # totale della categoria) di ciascun valore di un secondo attributo (sesso,
  # nazionalità) nel solo anno corrente. Con altro: true aggiunge la colonna
  # ALTRO, cioè gli iscritti della categoria con un valore diverso da quelli
  # elencati (o assente). Riusa il fallback di ZoningPeriodScope.
  class CategoryCrossBreakdown
    ALTRO = "ALTRO".freeze

    Cell = Struct.new(:label, :count, :percentuale, keyword_init: true)
    Row = Struct.new(:categoria, :cells, keyword_init: true)

    def self.call(...) = new(...).call

    def initialize(zoning:, anno:, mese:, column:, values:, altro: false)
      @zoning = zoning
      @anno = anno
      @mese = mese
      @column = column
      @values = values
      @altro = altro
    end

    def call
      counts.keys.map(&:first).uniq.sort.map { |categoria| build_row(categoria) }
    end

    private

    def build_row(categoria)
      conteggi = @values.transform_values { |valore| counts.fetch([ categoria, valore ], 0) }
      conteggi[ALTRO] = totale_categoria(categoria) - conteggi.values.sum if @altro
      totale = conteggi.values.sum

      Row.new(categoria:, cells: conteggi.map { |label, count| build_cell(label, count, totale) })
    end

    def build_cell(label, count, totale)
      Cell.new(label:, count:, percentuale: totale.zero? ? nil : (count.to_f / totale * 100))
    end

    def totale_categoria(categoria)
      counts.sum { |(cat, _valore), count| cat == categoria ? count : 0 }
    end

    # { [categoria, valore] => conteggio } con una sola query.
    def counts
      categoria = Import.categoria_sql
      @counts ||= ZoningPeriodScope.call(zoning: @zoning, anno: @anno, mese: @mese)
        .where.not(Arel.sql("#{categoria} IS NULL")).group(Arel.sql(categoria), @column).count
    end
  end
end
```

## Sezioni commentate

### Commento di classe e firma

```ruby
def initialize(zoning:, anno:, mese:, column:, values:, altro: false)
```

> **IT:** Un solo servizio per entrambe le sezioni "Genere Per Categoria" e "Nazionalità Per Categoria": cambiano solo la colonna incrociata (`column:`) e la mappa etichetta → valore (`values:`), che sono le stesse costanti `GenderBreakdown::SESSI` e `NationalityBreakdown::NAZIONALITA` delle sezioni "Sesso" e "Nazionalità". Così colonne ed etichette non possono divergere da quelle sezioni, come chiesto da davo ("sono le stesse"). Due classi gemelle sarebbero state identiche tranne due righe.
>
> *EN: A single service for both the "Genere Per Categoria" and "Nazionalità Per Categoria" sections: only the crossed column (`column:`) and the label → value map (`values:`) change, and those are the very same `GenderBreakdown::SESSI` and `NationalityBreakdown::NAZIONALITA` constants used by the "Sesso" and "Nazionalità" sections. Columns and labels therefore cannot drift from those sections, as davo asked ("they are the same"). Two twin classes would have been identical except for two lines.*

### `Cell` / `Row` (Struct)

```ruby
Cell = Struct.new(:label, :count, :percentuale, keyword_init: true)
Row = Struct.new(:categoria, :cells, keyword_init: true)
```

> **IT:** A differenza degli altri breakdown (una riga = un valore), qui una riga è una categoria e contiene una lista di celle: la vista e la tabella PDF iterano `cells` senza sapere se si tratta di sesso o nazionalità, quindi un solo partial (`statistics/_category_cross`) e una sola tabella Prawn (`StatisticPrints::CategoryCrossTable`) servono entrambe le sezioni.
>
> *EN: Unlike the other breakdowns (one row = one value), here a row is a category holding a list of cells: the view and the PDF table iterate `cells` without knowing whether it is gender or nationality, so a single partial (`statistics/_category_cross`) and a single Prawn table (`StatisticPrints::CategoryCrossTable`) serve both sections.*

### `build_row` / `build_cell` / `totale_categoria` *(privati)*

```ruby
def build_row(categoria)
  conteggi = @values.transform_values { |valore| counts.fetch([ categoria, valore ], 0) }
  conteggi[ALTRO] = totale_categoria(categoria) - conteggi.values.sum if @altro
  totale = conteggi.values.sum

  Row.new(categoria:, cells: conteggi.map { |label, count| build_cell(label, count, totale) })
end
```

> **IT:** La percentuale è sul **totale della singola categoria** (le celle di una riga sommano al 100%), non sul totale iscritti: è quello che mostra il mockup di davo (`.ai/schermate/genere_nazionalita.png`). `ALTRO` è calcolato per differenza (totale categoria − valori elencati), quindi raccoglie sia eventuali altri generi sia i valori assenti; è attivo solo per il sesso ("altri generi se presenti"), mentre la nazionalità resta sulle tre colonne della sezione esistente e usa come denominatore la loro somma, esattamente come `NationalityBreakdown`.
>
> *EN: The percentage is over the **single category's total** (a row's cells sum to 100%), not over all members: that is what davo's mockup shows (`.ai/schermate/genere_nazionalita.png`). `ALTRO` is computed by difference (category total − listed values), so it collects both any other gender and missing values; it is enabled only for gender ("other genders if present"), while nationality keeps the three columns of the existing section and uses their sum as denominator, exactly like `NationalityBreakdown`.*

### `counts` *(privato)*

```ruby
def counts
  categoria = Import.categoria_sql
  @counts ||= ZoningPeriodScope.call(zoning: @zoning, anno: @anno, mese: @mese)
    .where.not(Arel.sql("#{categoria} IS NULL")).group(Arel.sql(categoria), @column).count
end
```

> **IT:** Una sola query `GROUP BY categoria, colonna` invece di una per cella (12 categorie × 3 valori). La categoria usa `Import.categoria_sql`, lo stesso `COALESCE(categoria_sindacale, categoria)` di `AnnualCategoryProgression` (vedi `CodeGuide/Statistics/annual_category_progression.md`): nei dati reali la categoria sta in una colonna o nell'altra a seconda del mese di importazione. `Arel.sql` riceve solo una stringa costante, mai input dell'utente.
>
> *EN: A single `GROUP BY category, column` query instead of one per cell (12 categories × 3 values). The category uses `Import.categoria_sql`, the same `COALESCE(categoria_sindacale, categoria)` as `AnnualCategoryProgression` (see `CodeGuide/Statistics/annual_category_progression.md`): in real data the category lives in one column or the other depending on the import month. `Arel.sql` only ever receives a constant string, never user input.*
