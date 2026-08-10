# `StatisticSpiPrints::BarChart`

**File:** `app/services/statistic_spi_prints/bar_chart.rb`

## Codice completo

```ruby
module StatisticSpiPrints
  # Come StatisticPrints::BarChart ma con 4 serie (Iscritti/Deleghe x anno
  # precedente/corrente) raggruppate per comprensorio nello stesso grafico,
  # a specchio di spi_comparison_chart_controller.js lato schermo.
  class BarChart
    ISCRITTI_PREVIOUS = "28B62C"
    ISCRITTI_CURRENT = "FF851B"
    DELEGHE_PREVIOUS = "75CAEB"
    DELEGHE_CURRENT = "FF4136"
    SUCCESS = "28B62C"
    DANGER = "FF4136"
    AXIS_COLOR = "999999"
    LABEL_COLOR = "666666"
    LEGEND_HEIGHT = 16
    LEGEND_ITEM_GAP = 12
    LEGEND_ROW_GAP = 14
    LABEL_HEIGHT = 20
    LABEL_GAP = 4
    PERCENT_HEIGHT = 12
    MAX_GROUP_WIDTH = 220
    MAX_WIDTH_RATIO = 0.9
    BASELINE_HEIGHT = 2
    AXIS_OVERHANG = 5 * 72 / 25.4

    def self.draw(...) = new(...).draw

    def initialize(pdf, at:, width:, height:, labels:, iscritti_previous:, iscritti_current:, deleghe_previous:,
      deleghe_current:, iscritti_percentages:, deleghe_percentages:, previous_label:, current_label:)
      @pdf = pdf
      @width = width * MAX_WIDTH_RATIO
      @at = [ at[0] + ((width - @width) / 2), at[1] ]
      @height = height
      @labels = labels
      @iscritti_previous = iscritti_previous
      @iscritti_current = iscritti_current
      @deleghe_previous = deleghe_previous
      @deleghe_current = deleghe_current
      @iscritti_percentages = iscritti_percentages
      @deleghe_percentages = deleghe_percentages
      @previous_label = previous_label
      @current_label = current_label
    end

    def draw
      draw_legend
      @labels.each_index { |index| draw_group(index) }
      draw_axis_line
    end

    private

    def plot_top = @at[1] - (LEGEND_HEIGHT * 2) - LEGEND_ROW_GAP - PERCENT_HEIGHT
    def plot_bottom = @at[1] - @height + LABEL_HEIGHT
    def plot_height = plot_top - plot_bottom
    def content_width = [ @width, MAX_GROUP_WIDTH * @labels.size ].min
    def content_x = @at[0] + ((@width - content_width) / 2)
    def group_width = content_width / @labels.size
    def all_values = @iscritti_previous + @iscritti_current + @deleghe_previous + @deleghe_current
    def max_value = all_values.max.to_f * 1.15

    def draw_legend
      row1_y = @at[1]
      row2_y = @at[1] - LEGEND_ROW_GAP
      x = draw_legend_item(@at[0], ISCRITTI_PREVIOUS, "Iscritti #{@previous_label}", row1_y)
      draw_legend_item(x, ISCRITTI_CURRENT, "Iscritti #{@current_label}", row1_y)
      x = draw_legend_item(@at[0], DELEGHE_PREVIOUS, "Deleghe #{@previous_label}", row2_y)
      draw_legend_item(x, DELEGHE_CURRENT, "Deleghe #{@current_label}", row2_y)
    end

    def draw_legend_item(x, color, label, y)
      @pdf.fill_color color
      @pdf.fill_rectangle [ x, y ], 9, 9
      @pdf.fill_color "333333"
      label_width = 0
      @pdf.font("AsapCondensed", size: 8) do
        label_width = @pdf.width_of(label)
        @pdf.draw_text label, at: [ x + 12, y - 7 ]
      end
      x + 12 + label_width + LEGEND_ITEM_GAP
    end

    def draw_axis_line
      @pdf.stroke_color AXIS_COLOR
      @pdf.stroke_line [ content_x - AXIS_OVERHANG, plot_bottom ], [ content_x + content_width + AXIS_OVERHANG, plot_bottom ]
    end

    def draw_group(index)
      x = content_x + (index * group_width)
      bar_width = group_width * 0.19
      draw_bar(x + (group_width * 0.06), bar_width, @iscritti_previous[index], ISCRITTI_PREVIOUS)
      draw_bar(x + (group_width * 0.28), bar_width, @iscritti_current[index], ISCRITTI_CURRENT,
        percentage: @iscritti_percentages[index])
      draw_bar(x + (group_width * 0.53), bar_width, @deleghe_previous[index], DELEGHE_PREVIOUS)
      draw_bar(x + (group_width * 0.75), bar_width, @deleghe_current[index], DELEGHE_CURRENT,
        percentage: @deleghe_percentages[index])
      draw_label(index)
    end

    def draw_bar(x, width, value, color, percentage: nil)
      bar_height = max_value.zero? ? 0 : (value.to_f / max_value) * plot_height
      drawn_height = [ bar_height, BASELINE_HEIGHT ].max
      @pdf.fill_color color
      @pdf.fill_rectangle [ x, plot_bottom + drawn_height ], width, drawn_height
      draw_percentage(x, width, bar_height, percentage) if percentage
    end

    def draw_percentage(x, width, bar_height, percentage)
      color = percentage.negative? ? DANGER : SUCCESS
      sign = percentage.positive? ? "+" : ""
      @pdf.fill_color color
      @pdf.font("AsapCondensed", style: :bold, size: 7) do
        @pdf.text_box "#{sign}#{StatisticPrints::NumberFormatting.percent(percentage)}",
          at: [ x - 20, plot_bottom + bar_height + PERCENT_HEIGHT ], width: width + 40, align: :center
      end
    end

    def draw_label(index)
      x = content_x + (index * group_width)
      @pdf.fill_color LABEL_COLOR
      @pdf.font("AsapCondensed", style: :italic, size: 9) do
        @pdf.text_box @labels[index], at: [ x, plot_bottom - LABEL_GAP ], width: group_width, align: :center
      end
    end
  end
end
```

## Sezioni commentate

### Commento di classe

```ruby
# Come StatisticPrints::BarChart ma con 4 serie (Iscritti/Deleghe x anno
# precedente/corrente) raggruppate per comprensorio nello stesso grafico,
# a specchio di spi_comparison_chart_controller.js lato schermo.
class BarChart
```

> **IT:** Questa classe **non chiama** `StatisticPrints::BarChart` né la eredita: è una reimplementazione parallela e indipendente, verificato con `grep -rn "BarChart" app/services/statistic_spi_prints/` — l'unico chiamante è `TotalsPage`. La ragione è nella forma dei dati, non nello stile grafico: `StatisticPrints::BarChart` disegna 2 barre per gruppo (una metrica, anno precedente/corrente), questa ne disegna 4 (due metriche — Iscritti e Deleghe — ciascuna con anno precedente/corrente), perché `TotalsPage` deve mostrare in un colpo solo il confronto anno su anno di **entrambe** le metriche SPI per ogni comprensorio (coerente con `StatisticSpi::TotalMembersComparison`, che restituisce sempre le due metà `iscritti_*`/`deleghe_*` nello stesso `Result`, vedi `CodeGuide/StatisticSpi/total_members_comparison.md`). Aggiungere una terza metrica a `TotalsPage` richiederebbe di riscrivere questa classe da zero (o generalizzarla a N serie), non di passarle un parametro in più.
>
> *EN: This class does **not** call `StatisticPrints::BarChart`, nor does it inherit from it: it's an independent, parallel reimplementation — confirmed via `grep -rn "BarChart" app/services/statistic_spi_prints/`, whose only caller is `TotalsPage`. The reason is the data shape, not the visual style: `StatisticPrints::BarChart` draws 2 bars per group (one metric, previous/current year), this one draws 4 (two metrics — Iscritti and Deleghe — each with previous/current year), because `TotalsPage` needs to show the year-over-year comparison of **both** SPI metrics per comprensorio in one chart (consistent with `StatisticSpi::TotalMembersComparison`, which always returns both `iscritti_*`/`deleghe_*` halves in the same `Result`, see `CodeGuide/StatisticSpi/total_members_comparison.md`). Adding a third metric to `TotalsPage` would mean rewriting this class from scratch (or generalizing it to N series), not passing one extra parameter.*

### Costanti colore e layout

```ruby
ISCRITTI_PREVIOUS = "28B62C"
ISCRITTI_CURRENT = "FF851B"
DELEGHE_PREVIOUS = "75CAEB"
DELEGHE_CURRENT = "FF4136"
SUCCESS = "28B62C"
DANGER = "FF4136"
# ...
LEGEND_HEIGHT = 16
LEGEND_ITEM_GAP = 12
LEGEND_ROW_GAP = 14
MAX_GROUP_WIDTH = 220
MAX_WIDTH_RATIO = 0.9
AXIS_OVERHANG = 5 * 72 / 25.4
```

> **IT:** `SUCCESS`/`DANGER` duplicano deliberatamente i valori esadecimali di `ISCRITTI_PREVIOUS`/`DELEGHE_CURRENT` (stesso colore, nome diverso): sono usati in un contesto diverso, `draw_percentage`, dove il colore codifica il segno della variazione (verde se positiva, rosso se negativa) e non l'identità della serie — tenerli separati evita che un domani un cambio del colore "Iscritti anno precedente" faccia cambiare per errore anche il colore delle percentuali negative. `MAX_GROUP_WIDTH` (220 contro 200 di `StatisticPrints::BarChart`) e `MAX_WIDTH_RATIO` (0.9 contro 0.7) sono più larghi perché ogni gruppo qui contiene 4 barre invece di 2: la larghezza minima per stare leggibili è maggiore. `AXIS_OVERHANG` usa la stessa espressione inline `mm * 72 / 25.4` vista in tutta la cartella `statistic_spi_prints` (a differenza di `ReportPdf#mm_to_pt`, qui non c'è un metodo dedicato: ogni file la reimplementa localmente dove serve).
>
> *EN: `SUCCESS`/`DANGER` deliberately duplicate the hex values of `ISCRITTI_PREVIOUS`/`DELEGHE_CURRENT` (same color, different name): they're used in a different context, `draw_percentage`, where the color encodes the sign of the change (green if positive, red if negative), not series identity — keeping them separate means a future change to the "Iscritti previous year" color won't accidentally also change the negative-percentage color. `MAX_GROUP_WIDTH` (220 vs. `StatisticPrints::BarChart`'s 200) and `MAX_WIDTH_RATIO` (0.9 vs. 0.7) are wider because each group here holds 4 bars instead of 2: the minimum width to stay legible is larger. `AXIS_OVERHANG` uses the same inline `mm * 72 / 25.4` expression seen throughout the `statistic_spi_prints` folder (unlike `ReportPdf#mm_to_pt`, there's no shared helper here: every file reimplements it locally where needed).*

### `initialize`

```ruby
def initialize(pdf, at:, width:, height:, labels:, iscritti_previous:, iscritti_current:, deleghe_previous:,
  deleghe_current:, iscritti_percentages:, deleghe_percentages:, previous_label:, current_label:)
  @pdf = pdf
  @width = width * MAX_WIDTH_RATIO
  @at = [ at[0] + ((width - @width) / 2), at[1] ]
  @height = height
  # ...
end
```

> **IT:** `at:`, `width:`, `height:` sono passati esplicitamente dal chiamante (`TotalsPage#draw_chart`), non letti da `@pdf.bounds`/`@pdf.cursor` — lo stesso pattern descritto nella guida del progetto per `bounding_box` stretchy: `TotalsPage` disegna prima le due colonne "Iscritti"/"Deleghe" (altezza variabile a seconda di quante righe di comprensori ci sono), calcola il `cursor` più basso tra le due (`[iscritti_bottom, deleghe_bottom].min`), e solo a quel punto invoca questo grafico con un `chart_top` allineato. Se il grafico leggesse `@pdf.cursor` da solo, erediterebbe la posizione della bounding box in cui viene chiamato (l'ultima colonna disegnata), non il minimo tra le due — disallineando il grafico rispetto a una delle due tabelle sopra di esso. `@width`/`@at` vengono ricalcolati subito per centrare il grafico (già ridotto al 90% con `MAX_WIDTH_RATIO`) nello spazio ricevuto.
>
> *EN: `at:`, `width:`, `height:` are passed explicitly by the caller (`TotalsPage#draw_chart`), not read from `@pdf.bounds`/`@pdf.cursor` — the same pattern the project's stretchy-`bounding_box` note describes: `TotalsPage` first draws the two "Iscritti"/"Deleghe" columns (variable height depending on how many comprensori rows there are), computes the lower of the two cursors (`[iscritti_bottom, deleghe_bottom].min`), and only then invokes this chart with an aligned `chart_top`. If the chart read `@pdf.cursor` on its own, it would inherit the position of whichever bounding box it's called inside (the last column drawn), not the minimum of the two — misaligning the chart against one of the two tables above it. `@width`/`@at` are immediately recomputed to center the chart (already shrunk to 90% via `MAX_WIDTH_RATIO`) within the space it was given.*

### `draw`, geometria del plot *(privati)*

```ruby
def draw
  draw_legend
  @labels.each_index { |index| draw_group(index) }
  draw_axis_line
end

private

def plot_top = @at[1] - (LEGEND_HEIGHT * 2) - LEGEND_ROW_GAP - PERCENT_HEIGHT
def plot_bottom = @at[1] - @height + LABEL_HEIGHT
def plot_height = plot_top - plot_bottom
def content_width = [ @width, MAX_GROUP_WIDTH * @labels.size ].min
def content_x = @at[0] + ((@width - content_width) / 2)
def group_width = content_width / @labels.size
def all_values = @iscritti_previous + @iscritti_current + @deleghe_previous + @deleghe_current
def max_value = all_values.max.to_f * 1.15
```

> **IT:** `plot_top` sottrae `LEGEND_HEIGHT * 2` invece di `LEGEND_HEIGHT` come in `StatisticPrints::BarChart`: la legenda qui occupa due righe (Iscritti sopra, Deleghe sotto — 4 voci non stanno affiancate in una riga sola senza sforare la larghezza tipica di una colonna), quindi serve riservare il doppio dello spazio verticale più `LEGEND_ROW_GAP` tra le due righe. `max_value` è calcolato su `all_values`, l'unione di tutte e 4 le serie: le barre di Iscritti e Deleghe condividono la **stessa** scala verticale nello stesso grafico, anche se le due metriche hanno ordini di grandezza spesso diversi (più deleghe che iscritti, per via delle deleghe multiple) — è una scelta deliberata per rendere confrontabile a colpo d'occhio la variazione anno su anno di entrambe le metriche sullo stesso asse, al costo di barre "Iscritti" visivamente più basse quando "Deleghe" domina la scala.
>
> *EN: `plot_top` subtracts `LEGEND_HEIGHT * 2` instead of `LEGEND_HEIGHT` as in `StatisticPrints::BarChart`: the legend here spans two rows (Iscritti on top, Deleghe below — 4 entries don't fit side by side in one row without overflowing a typical column's width), so double the vertical space plus `LEGEND_ROW_GAP` between the rows must be reserved. `max_value` is computed over `all_values`, the union of all 4 series: Iscritti and Deleghe bars share the **same** vertical scale in the same chart, even though the two metrics often have different orders of magnitude (more delegations than members, due to multiple delegations) — a deliberate choice to make the year-over-year change of both metrics comparable at a glance on the same axis, at the cost of visually shorter "Iscritti" bars when "Deleghe" dominates the scale.*

### `draw_legend`, `draw_legend_item` *(privati)*

```ruby
def draw_legend
  row1_y = @at[1]
  row2_y = @at[1] - LEGEND_ROW_GAP
  x = draw_legend_item(@at[0], ISCRITTI_PREVIOUS, "Iscritti #{@previous_label}", row1_y)
  draw_legend_item(x, ISCRITTI_CURRENT, "Iscritti #{@current_label}", row1_y)
  x = draw_legend_item(@at[0], DELEGHE_PREVIOUS, "Deleghe #{@previous_label}", row2_y)
  draw_legend_item(x, DELEGHE_CURRENT, "Deleghe #{@current_label}", row2_y)
end
```

> **IT:** Ogni riga di legenda riparte da `@at[0]` (non continua dalla `x` finale della riga precedente): le due righe sono indipendenti orizzontalmente, solo `y` cambia. `draw_legend_item` restituisce la `x` finale dopo l'ultima voce disegnata proprio per incatenare le chiamate sulla stessa riga (`x = draw_legend_item(...)`) senza dover ricalcolare `width_of` due volte — lo stesso trucco di ritorno-per-incatenamento visto in `GroupedCategoryBarChart#draw_legend_item`.
>
> *EN: Each legend row restarts from `@at[0]` (it doesn't continue from the previous row's final `x`): the two rows are horizontally independent, only `y` changes. `draw_legend_item` returns the final `x` after the last drawn item precisely so calls on the same row can be chained (`x = draw_legend_item(...)`) without recomputing `width_of` twice — the same return-to-chain trick seen in `GroupedCategoryBarChart#draw_legend_item`.*

### `draw_group`, `draw_bar`, `draw_percentage`, `draw_label` *(privati)*

```ruby
def draw_group(index)
  x = content_x + (index * group_width)
  bar_width = group_width * 0.19
  draw_bar(x + (group_width * 0.06), bar_width, @iscritti_previous[index], ISCRITTI_PREVIOUS)
  draw_bar(x + (group_width * 0.28), bar_width, @iscritti_current[index], ISCRITTI_CURRENT,
    percentage: @iscritti_percentages[index])
  draw_bar(x + (group_width * 0.53), bar_width, @deleghe_previous[index], DELEGHE_PREVIOUS)
  draw_bar(x + (group_width * 0.75), bar_width, @deleghe_current[index], DELEGHE_CURRENT,
    percentage: @deleghe_percentages[index])
  draw_label(index)
end
```

> **IT:** I quattro offset (`0.06, 0.28, 0.53, 0.75`) sono costanti magiche calcolate a mano per ottenere due coppie di barre visivamente raggruppate (Iscritti a sinistra, Deleghe a destra) con un piccolo respiro tra le coppie e uno più piccolo dentro la coppia — non derivano da una formula esplicita nel codice. `bar_width = group_width * 0.19` con 4 barre da 0.19 più i margini lascia lo spazio per il "salto" visivo tra le due coppie. Solo le barre "current" (`ISCRITTI_CURRENT`, `DELEGHE_CURRENT`) ricevono `percentage:`, quindi solo loro mostrano l'etichetta di variazione sopra la barra (`draw_bar`/`draw_percentage` sono identici, riga per riga, alla versione di `StatisticPrints::BarChart` — l'unica differenza è che qui vengono chiamati 4 volte per gruppo invece di 2).
>
> *EN: The four offsets (`0.06, 0.28, 0.53, 0.75`) are hand-tuned magic constants to produce two visually grouped bar pairs (Iscritti on the left, Deleghe on the right) with a small gap between the pairs and a smaller one within each pair — they don't derive from an explicit formula in the code. `bar_width = group_width * 0.19` with 4 bars at 0.19 plus margins leaves room for the visual "jump" between the two pairs. Only the "current" bars (`ISCRITTI_CURRENT`, `DELEGHE_CURRENT`) receive `percentage:`, so only they show the change label above the bar (`draw_bar`/`draw_percentage` are identical, line for line, to `StatisticPrints::BarChart`'s version — the only difference is they're called 4 times per group here instead of 2).*
