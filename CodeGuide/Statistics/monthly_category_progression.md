# `Statistics::MonthlyCategoryProgression`

**File:** `app/services/statistics/monthly_category_progression.rb`

## Codice completo

```ruby
module Statistics
  # Per ogni categoria, il mese con la maggiore crescita e quello con il
  # maggiore calo rispetto al mese precedente, nell'anno scelto e nel
  # precedente. Riusa i conteggi (già integrati FILLEA/FLC e con l'anno
  # precedente tagliato allo stesso mese) di AnnualCategoryProgression; il
  # primo confronto possibile è Febbraio su Gennaio.
  class MonthlyCategoryProgression
    Result = Struct.new(:anno, :anno_precedente, :rows, :error) do
      def success? = error.blank?
    end

    Row = Struct.new(:categoria, :anno, :precedente)
    Extremes = Struct.new(:progressione, :regressione)
    Change = Struct.new(:mese, :diff, :diff_percent)

    def self.call(...) = new(...).call

    def initialize(zoning:, anno:)
      @progression = AnnualCategoryProgression.call(zoning:, anno:)
    end

    def call
      return Result.new(error: @progression.error) unless @progression.success?

      precedente = @progression.rows_precedente.index_by(&:categoria)
      rows = @progression.rows_anno.map do |row|
        Row.new(categoria: row.categoria, anno: extremes(row), precedente: extremes(precedente[row.categoria]))
      end
      Result.new(anno: @progression.anno, anno_precedente: @progression.anno_precedente, rows:)
    end

    private

    # Solo variazioni effettive: senza alcun mese in crescita (o in calo) il
    # rispettivo estremo resta nil invece di mostrare un falso "miglior mese".
    def extremes(row)
      changes = changes(row.counts)
      Extremes.new(progressione: changes.select { |c| c.diff.positive? }.max_by(&:diff),
        regressione: changes.select { |c| c.diff.negative? }.min_by(&:diff))
    end

    def changes(counts)
      @progression.mesi.drop(1).zip(counts.each_cons(2)).map do |mese, (prima, dopo)|
        Change.new(mese:, diff: dopo - prima, diff_percent: prima.zero? ? nil : (dopo - prima).to_f / prima * 100)
      end
    end
  end
end
```

## Sezioni commentate

### Commento di classe e `initialize`

```ruby
def initialize(zoning:, anno:)
  @progression = AnnualCategoryProgression.call(zoning:, anno:)
end
```

> **IT:** La pagina Progressione Mensile Categorie (`/statistics/progression_categories_monthly`) non fa query proprie: prende il risultato di `AnnualCategoryProgression` (vedi `annual_category_progression.md`) e ne ricava i mesi estremi. Così eredita gratis tutto quello che lì è già stato deciso e verificato: integrazioni FILLEA/FLC solo sulle rispettive righe, `COALESCE` sulle due colonne categoria, anno precedente tagliato allo stesso mese, stessi errori sui dati mancanti. Le due pagine mostrano quindi sempre numeri coerenti tra loro.
>
> *EN: The Monthly Category Progression page (`/statistics/progression_categories_monthly`) runs no queries of its own: it takes `AnnualCategoryProgression`'s result (see `annual_category_progression.md`) and derives the extreme months from it. That way it inherits for free everything already decided and verified there: FILLEA/FLC integrations only on their own rows, `COALESCE` over the two category columns, the previous year cut at the same month, the same missing-data errors. The two pages therefore always show mutually consistent numbers.*

### `changes`

```ruby
def changes(counts)
  @progression.mesi.drop(1).zip(counts.each_cons(2)).map do |mese, (prima, dopo)|
    Change.new(mese:, diff: dopo - prima, diff_percent: prima.zero? ? nil : (dopo - prima).to_f / prima * 100)
  end
end
```

> **IT:** Progressione e regressione sono la variazione **rispetto al mese precedente**, attribuita al mese di arrivo ("Febbraio" = Febbraio − Gennaio). Gennaio non ha un confronto: Dicembre dell'anno prima spesso non è importato e per l'anno precedente mancherebbe del tutto, quindi il primo confronto è sempre Febbraio. Il mese "migliore" e il "peggiore" si scelgono sulla variazione in iscritti; la % è mostrata accanto (`nil` se il mese di partenza è a zero).
>
> *EN: Progression and regression are the change **versus the previous month**, attributed to the arrival month ("February" = February − January). January has no comparison: the previous December is often not imported and would be missing entirely for the previous year, so the first comparison is always February. The "best" and "worst" months are picked by change in members; the % is shown alongside (`nil` when the starting month is zero).*

### `extremes`

```ruby
def extremes(row)
  changes = changes(row.counts)
  Extremes.new(progressione: changes.select { |c| c.diff.positive? }.max_by(&:diff),
    regressione: changes.select { |c| c.diff.negative? }.min_by(&:diff))
end
```

> **IT:** Si considerano solo variazioni effettive: se una categoria non ha mai perso iscritti nel periodo, la "maggior regressione" resta `nil` (in vista "—") invece di indicare il mese col guadagno più piccolo, che sarebbe fuorviante; lo stesso per la progressione. Nei dati di sviluppo succede per esempio a FLAI e SPI nel 2026. Nota: i buchi nei dati di integrazione (es. FLC Gennaio 2026 o Giugno 2026 per Trieste) si vedono qui come picchi o cali artificiali — sono il riflesso dei dati, non un errore di calcolo.
>
> *EN: Only actual changes count: if a category never lost members in the period, its "largest regression" stays `nil` ("—" in the view) rather than pointing at the month with the smallest gain, which would be misleading; likewise for progression. In development data this happens e.g. to FLAI and SPI in 2026. Note: gaps in integration data (e.g. FLC January 2026 or June 2026 for Trieste) show up here as artificial spikes or drops — a reflection of the data, not a calculation bug.*
