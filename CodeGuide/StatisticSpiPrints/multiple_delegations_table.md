# `StatisticSpiPrints::MultipleDelegationsTable`

**File:** `app/services/statistic_spi_prints/multiple_delegations_table.rb`

## Codice completo

```ruby
module StatisticSpiPrints
  # Tabella per la pagina Deleghe Multiple: a differenza di ComparisonTable non
  # confronta due anni (MultipleDelegationsBreakdown lavora su un solo
  # periodo), quindi le colonne sono le occorrenze (Doppia/Tripla/Quadrupla/
  # Quintupla) piu' il totale.
  class MultipleDelegationsTable
    include StatisticPrints::TableStyle

    def self.draw(...) = new(...).draw

    def initialize(pdf, rows:, title: nil)
      @pdf = pdf
      @rows = rows
      @title = title
    end

    def draw
      draw_title
      draw_styled_table
    end

    private

    def draw_title = super(size: 13)

    def header_row = [ "Azzonamento", "Doppia", "Tripla", "Quadrupla", "Quintupla", "totale deleghe multiple" ]

    def table_data
      [ header_row ] + @rows.map { |row| data_row(row) }
    end

    def data_row(row)
      [
        row.zoning.descrizione_azzonamento, StatisticPrints::NumberFormatting.count(row.doppia),
        StatisticPrints::NumberFormatting.count(row.tripla), StatisticPrints::NumberFormatting.count(row.quadrupla),
        StatisticPrints::NumberFormatting.count(row.quintupla), StatisticPrints::NumberFormatting.count(row.totale)
      ]
    end

    def column_widths
      width = @pdf.bounds.width
      { 0 => width * 0.28, 1 => width * 0.13, 2 => width * 0.13, 3 => width * 0.13, 4 => width * 0.13, 5 => width * 0.2 }
    end

    def cell_style = super(size: 11, padding: [ 6, 8 ])
  end
end
```

## Sezioni commentate

### Commento di classe

```ruby
# Tabella per la pagina Deleghe Multiple: a differenza di ComparisonTable non
# confronta due anni (MultipleDelegationsBreakdown lavora su un solo
# periodo), quindi le colonne sono le occorrenze (Doppia/Tripla/Quadrupla/
# Quintupla) piu' il totale.
class MultipleDelegationsTable
```

> **IT:** Non è una tabella generica come `CategoryTable`: le quattro colonne di occorrenza (`Doppia`/`Tripla`/`Quadrupla`/`Quintupla`) e il metodo `data_row` che legge `row.doppia`, `row.tripla`, `row.quadrupla`, `row.quintupla` sono hardcoded sui quattro campi nominati di `StatisticSpi::MultipleDelegationsBreakdown::Row` (`Row = Struct.new(:zoning, :doppia, :tripla, :quadrupla, :quintupla, :totale, ...)`), non su un hash iterabile. È una scelta deliberata coerente col commento di classe di `MultipleDelegationsBreakdown` sulla costante `OCCORRENZE = (2..5)`: quel range è "un limite empirico osservato nei dati reali... andrebbe rivisto se comparissero persone con più di 5 deleghe" (vedi `CodeGuide/StatisticSpi/README.md`, ultima sezione "Decisioni non ovvie"). Se `OCCORRENZE` si estendesse a `(2..6)` un domani, questa tabella andrebbe aggiornata a mano (nuova colonna "Sestupla", nuovo campo letto), a differenza di `CategoryTable`/`CategoryPercentageTable` che si adatterebbero automaticamente a un elenco `etichette:` più lungo passato dal chiamante.
>
> *EN: This isn't a generic table like `CategoryTable`: the four occurrence columns (`Doppia`/`Tripla`/`Quadrupla`/`Quintupla`) and the `data_row` method reading `row.doppia`, `row.tripla`, `row.quadrupla`, `row.quintupla` are hardcoded to the four named fields of `StatisticSpi::MultipleDelegationsBreakdown::Row` (`Row = Struct.new(:zoning, :doppia, :tripla, :quadrupla, :quintupla, :totale, ...)`), not to an iterable hash. This is a deliberate choice consistent with `MultipleDelegationsBreakdown`'s class comment about the `OCCORRENZE = (2..5)` constant: that range is "an empirical limit observed in real data... it would need revisiting if people with more than 5 delegations ever showed up" (see `CodeGuide/StatisticSpi/README.md`'s final "Decisions not obvious from the code" section). If `OCCORRENZE` ever extended to `(2..6)`, this table would need a manual update (a new "Sestupla" column, a new field read), unlike `CategoryTable`/`CategoryPercentageTable`, which would adapt automatically to a longer `etichette:` list passed by the caller.*

### Perché non `CategoryTable`

> **IT:** `MultipleDelegationsBreakdown::Row` non ha un campo `totali` (hash `{etichetta => count}`) come `TipologieDelegaBreakdown::Row`/`CessazioniBreakdown::Row`: ha quattro campi scalari nominati. `CategoryTable#data_row` legge `row.totali[etichetta]`, quindi non funzionerebbe affatto su questa struct senza modificarla — non è una scelta di leggibilità come per `MotivoCessazionePercentageTable` rispetto a `CategoryPercentageTable`, qui è un'incompatibilità di **forma dati** reale: `MultipleDelegationsBreakdown` (vedi `CodeGuide/StatisticSpi/multiple_delegations_breakdown.md`) restituisce direttamente quattro numeri con nomi di dominio (occorrenze 2/3/4/5), non un hash etichetta→count generico come gli altri breakdown SPI a distribuzione.
>
> *EN: `MultipleDelegationsBreakdown::Row` has no `totali` field (a `{etichetta => count}` hash) like `TipologieDelegaBreakdown::Row`/`CessazioniBreakdown::Row` do: it has four named scalar fields instead. `CategoryTable#data_row` reads `row.totali[etichetta]`, so it simply wouldn't work against this struct without modifying it — this isn't a readability choice like `MotivoCessazionePercentageTable` vs. `CategoryPercentageTable`, here it's a genuine **data-shape** mismatch: `MultipleDelegationsBreakdown` (see `CodeGuide/StatisticSpi/multiple_delegations_breakdown.md`) returns four domain-named numbers directly (occurrence counts 2/3/4/5), not a generic label→count hash like the other distribution-style SPI breakdowns.*

### `header_row`, `data_row`, `column_widths` *(privati)*

```ruby
def header_row = [ "Azzonamento", "Doppia", "Tripla", "Quadrupla", "Quintupla", "totale deleghe multiple" ]

def data_row(row)
  [
    row.zoning.descrizione_azzonamento, StatisticPrints::NumberFormatting.count(row.doppia),
    StatisticPrints::NumberFormatting.count(row.tripla), StatisticPrints::NumberFormatting.count(row.quadrupla),
    StatisticPrints::NumberFormatting.count(row.quintupla), StatisticPrints::NumberFormatting.count(row.totale)
  ]
end

def column_widths
  width = @pdf.bounds.width
  { 0 => width * 0.28, 1 => width * 0.13, 2 => width * 0.13, 3 => width * 0.13, 4 => width * 0.13, 5 => width * 0.2 }
end
```

> **IT:** Sei colonne a larghezza fissa in percentuale (`28/13/13/13/13/20`), non calcolate a partire da un array variabile come nelle tabelle generiche — perché qui il numero di colonne è sempre 6, non dipende da nessun parametro passato dal chiamante. `MultipleDelegationsPage` (l'unico chiamante, confermato via `grep -rn "MultipleDelegationsTable\." app/services/statistic_spi_prints/`) usa questa tabella a **piena larghezza pagina** per entrambe le sezioni (totale e comprensori, una sotto l'altra — non affiancate in colonne come nelle altre pagine SPI), perché `MultipleDelegationsBreakdown` non produce un grafico da affiancare (nessun confronto anno su anno, quindi nessun `BarChart`): le due tabelle da sole riempiono comodamente la pagina senza bisogno di un layout a colonne.
>
> *EN: Six fixed-percentage-width columns (`28/13/13/13/13/20`), not computed from a variable-length array like the generic tables — because the column count here is always 6, it doesn't depend on any parameter passed by the caller. `MultipleDelegationsPage` (the only caller, confirmed via `grep -rn "MultipleDelegationsTable\." app/services/statistic_spi_prints/`) uses this table at **full page width** for both sections (total and comprensori, stacked rather than side-by-side columns like the other SPI pages), because `MultipleDelegationsBreakdown` produces no chart to place alongside it (no year-over-year comparison, hence no `BarChart`): the two tables alone comfortably fill the page without needing a column layout.*

> **Nota 2026-10-06 / Note:** gli snippet delle sezioni commentate possono mostrare il codice precedente: `draw_title` e la costruzione della tabella (`make_table` + `style_header` + `table.draw`) arrivano ora da `StatisticPrints::TableStyle` (`draw_title(size:)`, `draw_styled_table`, vedi `CodeGuide/StatisticPrints/table_style.md`); il "Codice completo" in cima è quello attuale. / Snippets in the commented sections may show the earlier code: `draw_title` and the table build now come from `StatisticPrints::TableStyle`; the "Codice completo" at the top is current.
