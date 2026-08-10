# `StatisticSpiPrints::CategoryPercentageTable`

**File:** `app/services/statistic_spi_prints/category_percentage_table.rb`

## Codice completo

```ruby
module StatisticSpiPrints
  # Come CategoryTable ma con le percentuali invece dei conteggi, niente
  # colonna "totale".
  class CategoryPercentageTable
    def self.draw(...) = new(...).draw

    def initialize(pdf, rows:, etichette:, title: nil)
      @pdf = pdf
      @rows = rows
      @etichette = etichette
      @title = title
    end

    def draw
      draw_title
      table = @pdf.make_table(table_data, header: true, width: @pdf.bounds.width, cell_style: cell_style,
        column_widths: column_widths)
      style_header(table)
      table.draw
    end

    private

    def draw_title
      return if @title.blank?

      @pdf.font("AsapCondensed", style: :bold, size: 12) { @pdf.text @title }
      @pdf.move_down 4
    end

    def header_row = [ "Azzonamento" ] + @etichette

    def table_data
      [ header_row ] + @rows.map { |row| data_row(row) }
    end

    def data_row(row)
      [ row.zoning.descrizione_azzonamento ] +
        @etichette.map { |etichetta| StatisticPrints::NumberFormatting.percent(row.percentuali[etichetta]) }
    end

    def column_widths
      width = @pdf.bounds.width
      label_width = width * 0.2
      etichetta_width = (width - label_width) / @etichette.size
      widths = { 0 => label_width }
      @etichette.each_index { |index| widths[index + 1] = etichetta_width }
      widths
    end

    def cell_style
      {
        font: "AsapCondensed", size: 8, text_color: "000000", borders: [ :bottom ], border_color: "DDDDDD",
        padding: [ 4, 4 ]
      }
    end

    def style_header(table)
      table.row(0).font_style = :bold
      table.row(0).borders = [ :bottom ]
      table.row(0).border_color = "666666"
    end
  end
end
```

## Sezioni commentate

### Commento di classe

```ruby
# Come CategoryTable ma con le percentuali invece dei conteggi, niente
# colonna "totale".
class CategoryPercentageTable
```

> **IT:** Strutturalmente è `CategoryTable` con due sole differenze: legge `row.percentuali[etichetta]` invece di `row.totali[etichetta]` e formatta con `NumberFormatting.percent` invece di `.count`, e non ha colonna "totale" (le percentuali di riga non hanno un "totale" sensato da mostrare — sommano al 100% per `TipologieDelegaBreakdown`, ma non per `CessazioniBreakdown`, vedi sotto). È una classe **separata**, non `CategoryTable` con un flag `percentuali: true/false`: la duplicazione (stesso scheletro `draw`/`draw_title`/`style_header`, quasi identico) è stata scelta invece di un parametro condizionale — coerente con lo stile del progetto di preferire classi piccole e dedicate a un singolo scopo piuttosto che una classe più generica con rami interni.
>
> *EN: Structurally this is `CategoryTable` with exactly two differences: it reads `row.percentuali[etichetta]` instead of `row.totali[etichetta]` and formats with `NumberFormatting.percent` instead of `.count`, and it has no "totale" column (row percentages don't have a sensible "total" to show — they add up to 100% for `TipologieDelegaBreakdown`, but not for `CessazioniBreakdown`, see below). It's a **separate** class, not `CategoryTable` with a `percentuali: true/false` flag: the duplication (same `draw`/`draw_title`/`style_header` skeleton, nearly identical) was chosen over a conditional parameter — consistent with the project's style of preferring small, single-purpose classes over one more generic class with internal branches.*

### Uso confermato: solo comprensori, mai il totale

> **IT:** `grep -rn "CategoryPercentageTable\." app/services/statistic_spi_prints/` mostra due soli chiamanti, entrambi identici nella forma: `TipologieDelegaPage#draw_comprensori_column` e `CessazioniPage#draw_comprensori_column`, sempre con `title: "Comprensori (%)"`. **Nessuna** delle due pagine la usa per la riga "totale": `TipologieDelegaPage` non mostra affatto una tabella percentuali per il totale (la percentuale di ogni etichetta è già visibile come label sopra ogni barra in `CategoryBarChart`, ridondante mostrarla anche in tabella), mentre `CessazioniPage` usa `MotivoCessazionePercentageTable` per il totale — una tabella diversa, non questa classe con `rows: [result.totale]`. La ragione: con una sola riga, una tabella "una colonna per etichetta" (questa classe) sarebbe molto più larga che alta e sprecherebbe spazio orizzontale prezioso in una pagina a due colonne; `MotivoCessazionePercentageTable` trasposta (una riga per etichetta) usa meglio lo spazio verticale disponibile sotto la tabella dei conteggi.
>
> *EN: `grep -rn "CategoryPercentageTable\." app/services/statistic_spi_prints/` shows exactly two callers, both identical in shape: `TipologieDelegaPage#draw_comprensori_column` and `CessazioniPage#draw_comprensori_column`, always with `title: "Comprensori (%)"`. **Neither** page uses it for the "totale" row: `TipologieDelegaPage` doesn't show a percentage table for the total at all (each label's percentage is already visible as a label above each bar in `CategoryBarChart`, redundant to also show it in a table), while `CessazioniPage` uses `MotivoCessazionePercentageTable` for the total — a different table, not this class with `rows: [result.totale]`. The reason: with a single row, a "one column per label" table (this class) would be much wider than tall and would waste precious horizontal space on a two-column page; `MotivoCessazionePercentageTable`'s transposed layout (one row per label) makes better use of the vertical space available below the counts table.*

### `data_row`, `column_widths` *(privati)*

```ruby
def data_row(row)
  [ row.zoning.descrizione_azzonamento ] +
    @etichette.map { |etichetta| StatisticPrints::NumberFormatting.percent(row.percentuali[etichetta]) }
end

def column_widths
  width = @pdf.bounds.width
  label_width = width * 0.2
  etichetta_width = (width - label_width) / @etichette.size
  widths = { 0 => label_width }
  @etichette.each_index { |index| widths[index + 1] = etichetta_width }
  widths
end
```

> **IT:** `NumberFormatting.percent` restituisce `nil` se il valore è `nil` (vedi `StatisticPrints::NumberFormatting.percent`), e `nil` passato a `prawn-table` come contenuto di cella viene reso come cella vuota — questo è il modo in cui una `percentuali[etichetta] => nil` (comprensorio senza deleghe del periodo, `totale.zero?` nei breakdown SPI) diventa una cella vuota invece di un `"0.00%"` fuorviante o di un errore. `column_widths` usa `20%` fisso per la colonna etichetta (contro il `17%` di `CategoryTable`): non c'è colonna "totale" da cui sottrarre, quindi la percentuale libera rimanente è leggermente diversa e ridistribuita tra le sole colonne etichetta.
>
> *EN: `NumberFormatting.percent` returns `nil` when the value is `nil` (see `StatisticPrints::NumberFormatting.percent`), and `nil` passed to `prawn-table` as cell content renders as an empty cell — this is how a `percentuali[etichetta] => nil` (a comprensorio with no delegations for the period, `totale.zero?` in the SPI breakdowns) becomes an empty cell instead of a misleading `"0.00%"` or an error. `column_widths` uses a fixed `20%` for the label column (vs. `CategoryTable`'s `17%`): there's no "totale" column to subtract from, so the remaining free percentage is slightly different and redistributed only across the label columns.*
