# `StatisticSpiPrints::ProvvisorieTable`

**File:** `app/services/statistic_spi_prints/provvisorie_table.rb`

## Codice completo

```ruby
module StatisticSpiPrints
  # Tabella per la pagina Provvisorie: a differenza di CategoryTable qui c'e'
  # un solo numero (non un'etichetta per colonna) piu' la sua percentuale sul
  # totale deleghe, a specchio di app/views/statistic_spi/_provvisorie_table.
  class ProvvisorieTable
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

    def header_row = [ "Azzonamento", "totale provvisorie", "% sul totale deleghe" ]

    def table_data
      [ header_row ] + @rows.map { |row| data_row(row) }
    end

    def data_row(row)
      [
        row.zoning.descrizione_azzonamento, StatisticPrints::NumberFormatting.count(row.totale),
        StatisticPrints::NumberFormatting.percent(row.percentuale)
      ]
    end

    def column_widths
      width = @pdf.bounds.width
      { 0 => width * 0.4, 1 => width * 0.3, 2 => width * 0.3 }
    end

    def cell_style = super(size: 9)
  end
end
```

## Sezioni commentate

### Commento di classe

```ruby
# Tabella per la pagina Provvisorie: a differenza di CategoryTable qui c'e'
# un solo numero (non un'etichetta per colonna) piu' la sua percentuale sul
# totale deleghe, a specchio di app/views/statistic_spi/_provvisorie_table.
class ProvvisorieTable
```

> **IT:** La più semplice delle tabelle della cartella: `StatisticSpi::ProvvisorieBreakdown::Row` (`Row = Struct.new(:zoning, :totale, :deleghe_totale, :percentuale, ...)`) ha un solo valore da mostrare per riga (`totale`, il conteggio di pratiche provvisorie) più la sua percentuale — non c'è nessuna scomposizione per etichetta/categoria come in `TipologieDelegaBreakdown`/`CessazioniBreakdown`, quindi non serve nessuna delle astrazioni "un'etichetta per colonna" di `CategoryTable`/`CategoryPercentageTable`. Tre sole colonne fisse, sempre le stesse, indipendenti da qualsiasi parametro esterno: la firma più vicina, nella cartella, è quella di `MultipleDelegationsTable` (colonne hardcoded sui campi della struct), non quella delle tabelle generiche a etichette.
>
> *EN: The simplest table in this folder: `StatisticSpi::ProvvisorieBreakdown::Row` (`Row = Struct.new(:zoning, :totale, :deleghe_totale, :percentuale, ...)`) has just one value to show per row (`totale`, the provisional-case count) plus its percentage — there's no breakdown by label/category like in `TipologieDelegaBreakdown`/`CessazioniBreakdown`, so none of `CategoryTable`/`CategoryPercentageTable`'s "one label per column" machinery is needed. Just three fixed columns, always the same, independent of any external parameter: the closest sibling in this folder is `MultipleDelegationsTable` (columns hardcoded to struct fields), not the generic label-driven tables.*

### `header_row`, `data_row` — lo stesso `% sul totale deleghe` di `CessazioniBreakdown`

```ruby
def header_row = [ "Azzonamento", "totale provvisorie", "% sul totale deleghe" ]

def data_row(row)
  [
    row.zoning.descrizione_azzonamento, StatisticPrints::NumberFormatting.count(row.totale),
    StatisticPrints::NumberFormatting.percent(row.percentuale)
  ]
end
```

> **IT:** L'header `"% sul totale deleghe"` è, testualmente, identico a quello usato in `MotivoCessazionePercentageTable`, e per lo stesso motivo di fondo: `ProvvisorieBreakdown` calcola `percentuale` dividendo per `deleghe_totale` (tutte le deleghe del periodo), esattamente come `CessazioniBreakdown` — vedi `CodeGuide/StatisticSpi/README.md`, sezione "Un esempio di contrasto": le provvisorie, come le cessazioni, sono un **sottoinsieme** delle deleghe del periodo (una delega può non essere provvisoria), quindi il denominatore è esterno al conteggio locale. A differenza però di `CessazioniBreakdown`, `ProvvisorieBreakdown::Row` ha un solo campo `percentuale` (singolare, non `percentuali` plurale/hash) perché non c'è scomposizione per motivo — "provvisoria" è un flag booleano (`provvisoria: "SI"`), non una categoria tra tante.
>
> *EN: The header `"% sul totale deleghe"` is, word for word, identical to the one used in `MotivoCessazionePercentageTable`, and for the same underlying reason: `ProvvisorieBreakdown` computes `percentuale` by dividing by `deleghe_totale` (all of the period's delegations), exactly like `CessazioniBreakdown` does — see `CodeGuide/StatisticSpi/README.md`'s "A contrasting example" section: provisional cases, like cessazioni, are a **subset** of the period's delegations (a delegation may not be provisional), so the denominator sits outside the local count. Unlike `CessazioniBreakdown`, though, `ProvvisorieBreakdown::Row` has a single `percentuale` field (singular, not a plural/hash `percentuali`) because there's no breakdown by reason — "provvisoria" is a boolean flag (`provvisoria: "SI"`), not one category among several.*

### `column_widths`, `cell_style` *(privati)*

```ruby
def column_widths
  width = @pdf.bounds.width
  { 0 => width * 0.4, 1 => width * 0.3, 2 => width * 0.3 }
end

def cell_style
  {
    font: "AsapCondensed", size: 9, text_color: "000000", borders: [ :bottom ], border_color: "DDDDDD",
    padding: [ 5, 6 ]
  }
end
```

> **IT:** `40%/30%/30%` fisse: la colonna etichetta-azzonamento è leggermente più larga qui (`40%`) che in `CategoryTable` (`17%`) o `MotivoCessazionePercentageTable` (`65%` ma lì è il "motivo", non l'azzonamento) perché con solo tre colonne totali c'è margine per darle più respiro senza schiacciare le altre due. `ProvvisoriePage` (unico chiamante, confermato via `grep -rn "ProvvisorieTable\." app/services/statistic_spi_prints/`) usa questa tabella dentro una colonna di metà pagina (come `TipologieDelegaPage`/`CessazioniPage`, non a piena larghezza come `MultipleDelegationsTable`), seguita da una `StatisticPrints::PieChart` — un'altra conferma di riuso cross-modulo: `ProvvisoriePage`/`CessazioniPage` disegnano entrambe una torta "Provvisorie/Cessazioni vs. Deleghe Confermate" con la classe `StatisticPrints::PieChart` esistente, non una versione SPI dedicata, perché una torta a 2-3 fette non ha bisogno di nessuna delle differenze di forma dati che hanno giustificato `BarChart`/`CategoryBarChart`/`GroupedCategoryBarChart` come classi separate.
>
> *EN: Fixed `40%/30%/30%`: the zoning-label column is slightly wider here (`40%`) than in `CategoryTable` (`17%`) or `MotivoCessazionePercentageTable` (`65%`, but there it's the "reason," not the zoning) because with only three total columns there's room to give it more breathing space without cramping the other two. `ProvvisoriePage` (the only caller, confirmed via `grep -rn "ProvvisorieTable\." app/services/statistic_spi_prints/`) uses this table inside a half-page column (like `TipologieDelegaPage`/`CessazioniPage`, not full-width like `MultipleDelegationsTable`), followed by a `StatisticPrints::PieChart` — another confirmed cross-module reuse: `ProvvisoriePage`/`CessazioniPage` both draw a "Provvisorie/Cessazioni vs. Deleghe Confermate" pie using the existing `StatisticPrints::PieChart` class, not a dedicated SPI version, because a 2-3-slice pie needs none of the data-shape differences that justified `BarChart`/`CategoryBarChart`/`GroupedCategoryBarChart` as separate classes.*

> **Nota 2026-10-05 / Note:** lo snippet qui sopra mostra il codice precedente al refactor: `cell_style` e `style_header` arrivano ora da `StatisticPrints::TableStyle` (vedi `CodeGuide/StatisticPrints/table_style.md`); il "Codice completo" in cima è quello attuale. / The snippet above shows the pre-refactor code: `cell_style` and `style_header` now come from `StatisticPrints::TableStyle`; the "Codice completo" at the top is current.

> **Nota 2026-10-06 / Note:** gli snippet delle sezioni commentate possono mostrare il codice precedente: `draw_title` e la costruzione della tabella (`make_table` + `style_header` + `table.draw`) arrivano ora da `StatisticPrints::TableStyle` (`draw_title(size:)`, `draw_styled_table`, vedi `CodeGuide/StatisticPrints/table_style.md`); il "Codice completo" in cima è quello attuale. / Snippets in the commented sections may show the earlier code: `draw_title` and the table build now come from `StatisticPrints::TableStyle`; the "Codice completo" at the top is current.
