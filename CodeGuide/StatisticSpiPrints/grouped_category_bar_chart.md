# `StatisticSpiPrints::GroupedCategoryBarChart`

**File:** `app/services/statistic_spi_prints/grouped_category_bar_chart.rb`

## Codice completo

```ruby
module StatisticSpiPrints
  # Grafico a barre raggruppate per comprensorio, una serie colorata per
  # tipologia di delega (stessa palette di CategoryBarChart), a specchio di
  # grouped_bar_chart_controller.js lato schermo. A differenza di CategoryBarChart
  # (una sola serie) qui serve anche la legenda per distinguere le tipologie.
  class GroupedCategoryBarChart
    COLORS = CategoryBarChart::COLORS
    AXIS_COLOR = "999999"
    LABEL_COLOR = "666666"
    LEGEND_ROW_HEIGHT = 12
    LEGEND_ITEM_GAP = 10
    LABEL_HEIGHT = 18
    LABEL_GAP = 4
    PERCENT_HEIGHT = 10
    BASELINE_HEIGHT = 1
    BAR_WIDTH_RATIO = 0.15
    AXIS_OVERHANG = 4 * 72 / 25.4

    def self.draw(...) = new(...).draw

    def initialize(pdf, at:, width:, height:, labels:, series_labels:, series_values:)
      @pdf = pdf
      @at = at
      @width = width
      @height = height
      @labels = labels
      @series_labels = series_labels
      @series_values = series_values
    end

    def draw
      legend_rows = pack_legend_rows
      draw_legend(legend_rows)
      @labels.each_index { |index| draw_group(index, legend_rows.size) }
      draw_axis_line
    end

    private

    def plot_top(legend_row_count) = @at[1] - (legend_row_count * LEGEND_ROW_HEIGHT) - PERCENT_HEIGHT
    def plot_bottom = @at[1] - @height + LABEL_HEIGHT
    def plot_height(legend_row_count) = plot_top(legend_row_count) - plot_bottom
    def group_width = @width / @labels.size
    def max_value = [ @series_values.flatten.max.to_f, 1 ].max * 1.15

    def pack_legend_rows
      rows = [ [] ]
      x = 0
      @series_labels.each_index do |index|
        item_width = legend_item_width(index)
        if x + item_width > @width && rows.last.any?
          rows << []
          x = 0
        end
        rows.last << index
        x += item_width + LEGEND_ITEM_GAP
      end
      rows
    end

    def legend_item_width(index)
      label_width = nil
      @pdf.font("AsapCondensed", size: 8) { label_width = @pdf.width_of(@series_labels[index]) }
      10 + label_width + 6
    end

    def draw_legend(rows)
      rows.each_index do |row_index|
        x = @at[0]
        y = @at[1] - (row_index * LEGEND_ROW_HEIGHT)
        rows[row_index].each do |index|
          x = draw_legend_item(x, y, index)
        end
      end
    end

    def draw_legend_item(x, y, index)
      @pdf.fill_color COLORS[index % COLORS.length]
      @pdf.fill_rectangle [ x, y ], 8, 8
      @pdf.fill_color "333333"
      label_width = 0
      @pdf.font("AsapCondensed", size: 8) do
        label_width = @pdf.width_of(@series_labels[index])
        @pdf.draw_text @series_labels[index], at: [ x + 10, y - 6 ]
      end
      x + 10 + label_width + 6 + LEGEND_ITEM_GAP
    end

    def draw_axis_line
      @pdf.stroke_color AXIS_COLOR
      @pdf.stroke_line [ @at[0] - AXIS_OVERHANG, plot_bottom ], [ @at[0] + @width + AXIS_OVERHANG, plot_bottom ]
    end

    def draw_group(index, legend_row_count)
      x = @at[0] + (index * group_width)
      bar_width = group_width * BAR_WIDTH_RATIO
      slot_width = group_width / @series_labels.size
      @series_labels.each_index { |series_index| draw_bar(x, slot_width, series_index, index, bar_width, legend_row_count) }
      draw_label(x, index)
    end

    def draw_bar(group_x, slot_width, series_index, group_index, bar_width, legend_row_count)
      value = @series_values[series_index][group_index]
      x = group_x + (series_index * slot_width) + ((slot_width - bar_width) / 2)
      bar_height = max_value.zero? ? 0 : (value.to_f / max_value) * plot_height(legend_row_count)
      drawn_height = value.to_f.positive? ? [ bar_height, BASELINE_HEIGHT ].max : 0

      @pdf.fill_color COLORS[series_index % COLORS.length]
      @pdf.fill_rectangle [ x, plot_bottom + drawn_height ], bar_width, drawn_height
      draw_percentage(x, bar_width, drawn_height, value)
    end

    def draw_percentage(x, width, bar_height, value)
      return unless value.to_f.positive?

      @pdf.fill_color "333333"
      @pdf.font("AsapCondensed", style: :bold, size: 6) do
        @pdf.text_box StatisticPrints::NumberFormatting.percent(value),
          at: [ x - 10, plot_bottom + bar_height + PERCENT_HEIGHT ], width: width + 20, align: :center
      end
    end

    def draw_label(x, index)
      @pdf.fill_color LABEL_COLOR
      @pdf.font("AsapCondensed", style: :italic, size: 8) do
        @pdf.text_box @labels[index], at: [ x, plot_bottom - LABEL_GAP ], width: group_width, align: :center
      end
    end
  end
end
```

## Sezioni commentate

### Commento di classe

```ruby
# Grafico a barre raggruppate per comprensorio, una serie colorata per
# tipologia di delega (stessa palette di CategoryBarChart), a specchio di
# grouped_bar_chart_controller.js lato schermo. A differenza di CategoryBarChart
# (una sola serie) qui serve anche la legenda per distinguere le tipologie.
class GroupedCategoryBarChart
```

> **IT:** Il terzo e ultimo grafico a barre della cartella, usato in un solo punto (`TipologieDelegaPage#draw_comprensori_chart`). Dove `BarChart` raggruppa 4 serie **per periodo** (anno precedente/corrente x due metriche) e `CategoryBarChart` disegna 5 barre **per categoria** senza raggruppamento (un solo comprensorio/regione), questa terza forma raggruppa N serie (le 5 etichette di `TipologieDelegaBreakdown`) **per comprensorio**: ogni gruppo sull'asse x è un comprensorio, e dentro ogni gruppo ci sono le 5 barre delle tipologie. È la stessa relazione "singola serie vs. raggruppata per entità" che passa da `Statistics::AgeBreakdown` (grafico a schermo, una sola distribuzione) a un ipotetico confronto multi-comprensorio — qui risolta lato Prawn con una classe dedicata invece di generalizzare `CategoryBarChart` con un parametro opzionale di raggruppamento.
>
> *EN: The third and final bar chart in this folder, used in exactly one place (`TipologieDelegaPage#draw_comprensori_chart`). Where `BarChart` groups 4 series **per period** (previous/current year x two metrics) and `CategoryBarChart` draws 5 bars **per category** with no grouping (a single comprensorio/region), this third shape groups N series (the 5 `TipologieDelegaBreakdown` labels) **per comprensorio**: each group on the x-axis is a comprensorio, and inside each group are the 5 delegation-type bars. It's the same "single series vs. grouped by entity" relationship that goes from `Statistics::AgeBreakdown` (screen-side chart, one distribution) to a hypothetical multi-comprensorio comparison — here resolved on the Prawn side with a dedicated class instead of generalizing `CategoryBarChart` with an optional grouping parameter.*

### `COLORS` (costante) — riuso confermato

```ruby
COLORS = CategoryBarChart::COLORS
```

> **IT:** A differenza di `CategoryBarChart`, che duplica i 5 colori invece di importarli da `StatisticPrints::SingleSeriesBarChart`, questa classe **importa** direttamente da `CategoryBarChart` (stesso pattern di `StatisticSpi::AgeBreakdown::BANDS = Statistics::AgeBreakdown::BANDS`, ma qui interno alla cartella `statistic_spi_prints`): garantisce che la stessa tipologia di delega abbia sempre lo stesso colore sia nel grafico "totale" (`CategoryBarChart`, una barra per etichetta) sia in quello "per comprensorio" (`GroupedCategoryBarChart`, un colore per serie) nella stessa pagina — un utente che guarda entrambi i grafici affiancati in `TipologieDelegaPage` deve poter associare il colore alla categoria senza dover leggere due legende diverse.
>
> *EN: Unlike `CategoryBarChart`, which duplicates the 5 colors instead of importing them from `StatisticPrints::SingleSeriesBarChart`, this class **imports** directly from `CategoryBarChart` (the same pattern as `StatisticSpi::AgeBreakdown::BANDS = Statistics::AgeBreakdown::BANDS`, but here internal to the `statistic_spi_prints` folder): it guarantees the same delegation type always gets the same color both in the "total" chart (`CategoryBarChart`, one bar per label) and the "per comprensorio" one (`GroupedCategoryBarChart`, one color per series) on the same page — a user looking at both charts side by side in `TipologieDelegaPage` needs to be able to map color to category without reading two different legends.*

### `initialize`, `draw`

```ruby
def initialize(pdf, at:, width:, height:, labels:, series_labels:, series_values:)
  # ...
end

def draw
  legend_rows = pack_legend_rows
  draw_legend(legend_rows)
  @labels.each_index { |index| draw_group(index, legend_rows.size) }
  draw_axis_line
end
```

> **IT:** `series_values` è una matrice `serie x gruppi` (`[ETICHETTE.size][comprensori.size]`, vedi il chiamante: `ETICHETTE.map { |etichetta| comprensori.map { |row| row.percentuali[etichetta] || 0 } }`) — l'ordine degli indici è invertito rispetto a `labels`/`@labels` (che indicizza i comprensori). `draw` calcola `legend_rows` **prima** di disegnare i gruppi e passa `legend_rows.size` a `draw_group`: il numero di righe che la legenda occupa dipende dal numero di etichette e dalla larghezza disponibile (vedi `pack_legend_rows`), e quel numero determina `plot_top`/`plot_height` — quindi l'altezza del grafico non è nota finché la legenda non è stata "impacchettata", quindi la sequenza di chiamate non può essere invertita.
>
> *EN: `series_values` is a `series x groups` matrix (`[ETICHETTE.size][comprensori.size]`, see the caller: `ETICHETTE.map { |etichetta| comprensori.map { |row| row.percentuali[etichetta] || 0 } }`) — the index order is inverted relative to `labels`/`@labels` (which indexes comprensori). `draw` computes `legend_rows` **before** drawing the groups and passes `legend_rows.size` into `draw_group`: how many rows the legend takes depends on the number of labels and the available width (see `pack_legend_rows`), and that number determines `plot_top`/`plot_height` — so the chart's plottable height isn't known until the legend has been "packed," which is why the call sequence can't be reversed.*

### `pack_legend_rows`, `legend_item_width` *(privati)*

```ruby
def pack_legend_rows
  rows = [ [] ]
  x = 0
  @series_labels.each_index do |index|
    item_width = legend_item_width(index)
    if x + item_width > @width && rows.last.any?
      rows << []
      x = 0
    end
    rows.last << index
    x += item_width + LEGEND_ITEM_GAP
  end
  rows
end
```

> **IT:** L'unico "line wrapping" manuale della cartella: le altre legende (`BarChart`, `TotalsPage`-side) hanno un numero fisso di voci e righe (2 o 4, sempre note), ma qui `@series_labels` è `TipologieDelegaBreakdown::ETICHETTE` — attualmente 5 voci, ma la funzione è scritta per adattarsi se ne comparisse una sesta o settima senza dover ricalcolare a mano quante righe servono. `rows.last.any?` nella condizione evita di aprire una nuova riga se la riga corrente è ancora vuota (altrimenti una singola etichetta più larga della pagina intera creerebbe un ciclo infinito di righe vuote... in realtà no, aprirebbe comunque una riga con quella sola etichetta, ma senza il controllo l'etichetta troppo larga per `@width` forzerebbe comunque il wrap subito, lasciando `rows.last` vuoto e poi popolato — il controllo garantisce che ogni riga abbia **almeno una** voce anche quando quella voce da sola eccede `@width`, evitando righe vuote in mezzo alla legenda).
>
> *EN: The folder's only manual "line wrapping": the other legends (`BarChart`, `TotalsPage`-side) have a fixed, always-known number of items and rows (2 or 4), but here `@series_labels` is `TipologieDelegaBreakdown::ETICHETTE` — currently 5 entries, but the method is written to adapt if a sixth or seventh ever appeared, without manually recomputing how many rows are needed. `rows.last.any?` in the condition avoids opening a new row when the current one is still empty (otherwise a single label wider than the whole page could leave `rows.last` empty before being populated) — the check guarantees every row has **at least one** entry even when that one entry alone exceeds `@width`, avoiding empty rows in the middle of the legend.*

### `draw_legend`, `draw_legend_item` *(privati)*

```ruby
def draw_legend(rows)
  rows.each_index do |row_index|
    x = @at[0]
    y = @at[1] - (row_index * LEGEND_ROW_HEIGHT)
    rows[row_index].each do |index|
      x = draw_legend_item(x, y, index)
    end
  end
end
```

> **IT:** Stesso pattern di ritorno-e-incatenamento visto in `BarChart#draw_legend_item`, applicato qui a un numero variabile di righe (da `pack_legend_rows`) invece che a due righe fisse. `rows[row_index]` contiene **indici** in `@series_labels`/`COLORS`, non le etichette stesse: `draw_legend_item(x, y, index)` risolve colore ed etichetta dall'indice, così l'ordine delle voci nella legenda coincide sempre con l'ordine delle serie disegnate (`draw_group` itera `@series_labels.each_index` nello stesso ordine).
>
> *EN: The same return-and-chain pattern seen in `BarChart#draw_legend_item`, applied here to a variable number of rows (from `pack_legend_rows`) instead of two fixed ones. `rows[row_index]` holds **indices** into `@series_labels`/`COLORS`, not the labels themselves: `draw_legend_item(x, y, index)` resolves color and label from the index, so the legend's entry order always matches the drawn series order (`draw_group` iterates `@series_labels.each_index` in the same order).*

### `draw_group`, `draw_bar`, `draw_percentage`, `draw_label` *(privati)*

```ruby
def draw_group(index, legend_row_count)
  x = @at[0] + (index * group_width)
  bar_width = group_width * BAR_WIDTH_RATIO
  slot_width = group_width / @series_labels.size
  @series_labels.each_index { |series_index| draw_bar(x, slot_width, series_index, index, bar_width, legend_row_count) }
  draw_label(x, index)
end

def draw_bar(group_x, slot_width, series_index, group_index, bar_width, legend_row_count)
  value = @series_values[series_index][group_index]
  # ...
  drawn_height = value.to_f.positive? ? [ bar_height, BASELINE_HEIGHT ].max : 0
  # ...
end
```

> **IT:** `BAR_WIDTH_RATIO = 0.15` (contro `0.5` di `CategoryBarChart`) è molto più stretto perché qui ogni "slot" di comprensorio deve contenere N barre affiancate (una per tipologia), non una sola — con 5 tipologie e più comprensori lo spazio orizzontale per singola barra è già ridotto in partenza. Nota la differenza cruciale con `draw_bar` di `CategoryBarChart`: qui `drawn_height` è `0` (non `BASELINE_HEIGHT`) quando `value` non è positivo, cioè **niente barra fantasma** per i valori a zero — con decine di celle nella matrice comprensorio×tipologia, disegnare comunque 1-2pt per ogni cella a zero avrebbe prodotto un grafico visivamente "sporco" di barre minuscole; `draw_percentage` applica lo stesso `return unless value.to_f.positive?`, quindi le celle a zero non mostrano nemmeno l'etichetta di percentuale — coerente con la scelta di non disegnarle affatto.
>
> *EN: `BAR_WIDTH_RATIO = 0.15` (vs. `CategoryBarChart`'s `0.5`) is much narrower because here every comprensorio "slot" must hold N side-by-side bars (one per delegation type), not just one — with 5 types and multiple comprensori, the horizontal space per individual bar is already tight to begin with. Note the crucial difference from `CategoryBarChart`'s `draw_bar`: here `drawn_height` is `0` (not `BASELINE_HEIGHT`) when `value` isn't positive, i.e. **no ghost bar** for zero values — with dozens of cells in the comprensorio×type matrix, still drawing 1-2pt for every zero cell would have produced a visually "noisy" chart full of tiny bars; `draw_percentage` applies the same `return unless value.to_f.positive?`, so zero cells don't even show a percentage label either — consistent with the choice not to draw them at all.*
