# `StatisticSpiPrints::CategoryBarChart`

**File:** `app/services/statistic_spi_prints/category_bar_chart.rb`

## Codice completo

```ruby
module StatisticSpiPrints
  # Grafico a barre a singola serie per tipologia di delega, colori fissi per
  # categoria a specchio della palette Bootstrap usata in bar_chart_controller.js
  # (warning/danger/success/primary/info), in ordine con
  # StatisticSpi::TipologieDelegaBreakdown::ETICHETTE.
  class CategoryBarChart
    COLORS = %w[FF851B FF4136 28B62C 158CBA 75CAEB].freeze
    AXIS_COLOR = "999999"
    LABEL_COLOR = "666666"
    LABEL_HEIGHT = 24
    LABEL_GAP = 4
    PERCENT_HEIGHT = 12
    BASELINE_HEIGHT = 2
    BAR_WIDTH_RATIO = 0.5
    AXIS_OVERHANG = 5 * 72 / 25.4

    def self.draw(...) = new(...).draw

    def initialize(pdf, at:, width:, height:, labels:, values:, percentages:)
      @pdf = pdf
      @at = at
      @width = width
      @height = height
      @labels = labels
      @values = values
      @percentages = percentages
    end

    def draw
      @labels.each_index { |index| draw_bar(index) }
      draw_axis_line
    end

    private

    def plot_top = @at[1] - PERCENT_HEIGHT
    def plot_bottom = @at[1] - @height + LABEL_HEIGHT
    def plot_height = plot_top - plot_bottom
    def group_width = @width / @labels.size
    def max_value = [ @values.max.to_f, 1 ].max * 1.15

    def draw_axis_line
      @pdf.stroke_color AXIS_COLOR
      @pdf.stroke_line [ @at[0] - AXIS_OVERHANG, plot_bottom ], [ @at[0] + @width + AXIS_OVERHANG, plot_bottom ]
    end

    def draw_bar(index)
      x = @at[0] + (index * group_width)
      bar_width = group_width * BAR_WIDTH_RATIO
      bar_x = x + ((group_width - bar_width) / 2)
      bar_height = max_value.zero? ? 0 : (@values[index].to_f / max_value) * plot_height
      drawn_height = [ bar_height, BASELINE_HEIGHT ].max

      @pdf.fill_color COLORS[index % COLORS.length]
      @pdf.fill_rectangle [ bar_x, plot_bottom + drawn_height ], bar_width, drawn_height
      draw_percentage(bar_x, bar_width, drawn_height, @percentages[index])
      draw_label(x, index)
    end

    def draw_percentage(x, width, bar_height, percentage)
      return if percentage.nil?

      @pdf.fill_color "333333"
      @pdf.font("AsapCondensed", style: :bold, size: 8) do
        @pdf.text_box StatisticPrints::NumberFormatting.percent(percentage),
          at: [ x - 15, plot_bottom + bar_height + PERCENT_HEIGHT ], width: width + 30, align: :center
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
# Grafico a barre a singola serie per tipologia di delega, colori fissi per
# categoria a specchio della palette Bootstrap usata in bar_chart_controller.js
# (warning/danger/success/primary/info), in ordine con
# StatisticSpi::TipologieDelegaBreakdown::ETICHETTE.
class CategoryBarChart
```

> **IT:** Usato in un solo punto (`TipologieDelegaPage#draw_chart`, confermato via `grep -rn "CategoryBarChart" app/services/statistic_spi_prints/`) per disegnare le 5 barre del **totale** regionale/comprensorio scelto: una barra per etichetta di `StatisticSpi::TipologieDelegaBreakdown::ETICHETTE` (Ordinaria/Concomitante/Invalidi Civili/BreviManu/Altro), non una serie temporale o un confronto — a differenza di `BarChart` e di `StatisticPrints::BarChart`, qui non c'è nessun "anno precedente vs corrente": ogni barra è semplicemente una categoria diversa nello stesso periodo. La distribuzione **per comprensorio** della stessa metrica usa invece `GroupedCategoryBarChart`, non questa classe: le due sono complementari nella stessa pagina, non alternative.
>
> *EN: Used in exactly one place (`TipologieDelegaPage#draw_chart`, confirmed via `grep -rn "CategoryBarChart" app/services/statistic_spi_prints/`) to draw the 5 bars of the chosen regional/comprensorio **total**: one bar per label from `StatisticSpi::TipologieDelegaBreakdown::ETICHETTE` (Ordinaria/Concomitante/Invalidi Civili/BreviManu/Altro), not a time series or a comparison — unlike `BarChart` and `StatisticPrints::BarChart`, there's no "previous vs. current year" here: each bar is simply a different category within the same period. The **per-comprensorio** distribution of the same metric instead uses `GroupedCategoryBarChart`, not this class: the two are complementary within the same page, not alternatives.*

### `COLORS` (costante)

```ruby
COLORS = %w[FF851B FF4136 28B62C 158CBA 75CAEB].freeze
```

> **IT:** Sono, byte per byte, gli stessi 5 colori (nello stesso ordine: warning/danger/success/primary/info) della `PALETTE` di `StatisticPrints::SingleSeriesBarChart` (senza il sesto colore `DARK`), ma **duplicati** qui come array separato, non importati (`COLORS = StatisticPrints::SingleSeriesBarChart::PALETTE.first(5)` avrebbe funzionato altrettanto bene, ma non è la scelta fatta). Vedi la nota su `GroupedCategoryBarChart::COLORS`, che invece *importa* da questa classe (`COLORS = CategoryBarChart::COLORS`) — la stessa disciplina di riuso non è stata applicata al confine con `StatisticPrints`, solo all'interno di `statistic_spi_prints`. `COLORS[index % COLORS.length]` (il modulo) protegge da un `IndexError` se un domani `ETICHETTE` crescesse oltre 5 voci, riciclando i colori invece di sollevare un'eccezione — silenzioso ma non corretto (due categorie diverse finirebbero con lo stesso colore).
>
> *EN: These are, byte for byte, the same 5 colors (in the same order: warning/danger/success/primary/info) as `StatisticPrints::SingleSeriesBarChart`'s `PALETTE` (minus the sixth color, `DARK`), but **duplicated** here as a separate array rather than imported (`COLORS = StatisticPrints::SingleSeriesBarChart::PALETTE.first(5)` would have worked just as well, but that's not the choice made). See the note on `GroupedCategoryBarChart::COLORS`, which instead *imports* from this class (`COLORS = CategoryBarChart::COLORS`) — the same reuse discipline wasn't applied across the `StatisticPrints` boundary, only within `statistic_spi_prints`. `COLORS[index % COLORS.length]` (the modulo) guards against an `IndexError` if `ETICHETTE` ever grew past 5 entries, recycling colors instead of raising — silent but not correct (two different categories would end up with the same color).*

### Perché non `StatisticPrints::SingleSeriesBarChart`

> **IT:** `StatisticPrints::SingleSeriesBarChart` (usato da `AgeClassesPage` per le fasce d'età) sembrerebbe coprire lo stesso caso — una serie, colori per categoria — ma la sua `value_label` è **alternativa**: mostra o il conteggio (`NumberFormatting.count`) o, se `percentages:` è passato, la percentuale al suo posto (`return NumberFormatting.percent(...) if @percentages`), mai entrambi. `CategoryBarChart` invece li vuole **contemporaneamente**: l'altezza della barra codifica il valore assoluto (`@values`) e l'etichetta sopra la barra mostra sempre la percentuale (`@percentages`), le due cose vengono passate come parametri separati e obbligatori (non uno opzionale che sostituisce l'altro). Questo è il motivo concreto per cui `TipologieDelegaPage` non riusa `SingleSeriesBarChart`: la doppia codifica valore+percentuale non è rappresentabile con l'API di quella classe senza modificarla.
>
> *EN: `StatisticPrints::SingleSeriesBarChart` (used by `AgeClassesPage` for age bands) looks like it should cover the same case — one series, per-category colors — but its `value_label` is **either/or**: it shows either the count (`NumberFormatting.count`) or, if `percentages:` is passed, the percentage instead (`return NumberFormatting.percent(...) if @percentages`), never both. `CategoryBarChart` instead wants both **at the same time**: bar height encodes the absolute value (`@values`) while the label above the bar always shows the percentage (`@percentages`) — the two are passed as separate, mandatory parameters, not one optional argument replacing the other. This is the concrete reason `TipologieDelegaPage` doesn't reuse `SingleSeriesBarChart`: the dual value+percentage encoding isn't representable through that class's API without modifying it.*

### `initialize`, `draw`, geometria del plot *(privati)*

```ruby
def initialize(pdf, at:, width:, height:, labels:, values:, percentages:)
  # ...
end

def draw
  @labels.each_index { |index| draw_bar(index) }
  draw_axis_line
end

private

def plot_top = @at[1] - PERCENT_HEIGHT
def plot_bottom = @at[1] - @height + LABEL_HEIGHT
def plot_height = plot_top - plot_bottom
def group_width = @width / @labels.size
def max_value = [ @values.max.to_f, 1 ].max * 1.15
```

> **IT:** A differenza di `BarChart`/`StatisticPrints::BarChart`, questa classe non ha `draw_legend` (niente stato da spiegare — le etichette dei colori sono già scritte sotto ogni barra da `draw_label`, non serve una legenda separata) né restringe `@width` a una percentuale del contenitore (niente `MAX_WIDTH_RATIO`): con 5 categorie fisse è raro che il grafico debba occupare meno dello spazio disponibile. `max_value = [@values.max.to_f, 1].max * 1.15` protegge dalla divisione per zero quando **tutte** le 5 etichette hanno conteggio zero (caso raro ma possibile per un comprensorio piccolo in un mese senza deleghe di una tipologia): senza il `[.., 1].max`, `@values.max` sarebbe `0` e ogni barra avrebbe comunque `bar_height` zero per via del guard `max_value.zero? ? 0 : ...` in `draw_bar` — la protezione è quindi ridondante con quel guard ma resa esplicita comunque, coerente con lo stile difensivo del resto della cartella.
>
> *EN: Unlike `BarChart`/`StatisticPrints::BarChart`, this class has no `draw_legend` (nothing to explain — the color labels are already written under each bar by `draw_label`, no separate legend is needed) and doesn't shrink `@width` to a fraction of its container (no `MAX_WIDTH_RATIO`): with 5 fixed categories it's rare for the chart to need less than the available space. `max_value = [@values.max.to_f, 1].max * 1.15` guards against division by zero when **all** 5 labels have a zero count (rare but possible for a small comprensorio in a month with no delegations of some type): without the `[.., 1].max`, `@values.max` would be `0` and every bar would still get `bar_height` zero anyway thanks to the `max_value.zero? ? 0 : ...` guard in `draw_bar` — the protection is therefore redundant with that guard but made explicit regardless, consistent with the rest of the folder's defensive style.*

### `draw_bar`, `draw_percentage`, `draw_label` *(privati)*

```ruby
def draw_bar(index)
  x = @at[0] + (index * group_width)
  bar_width = group_width * BAR_WIDTH_RATIO
  bar_x = x + ((group_width - bar_width) / 2)
  bar_height = max_value.zero? ? 0 : (@values[index].to_f / max_value) * plot_height
  drawn_height = [ bar_height, BASELINE_HEIGHT ].max

  @pdf.fill_color COLORS[index % COLORS.length]
  @pdf.fill_rectangle [ bar_x, plot_bottom + drawn_height ], bar_width, drawn_height
  draw_percentage(bar_x, bar_width, drawn_height, @percentages[index])
  draw_label(x, index)
end
```

> **IT:** `drawn_height = [bar_height, BASELINE_HEIGHT].max` disegna sempre una barra visibile di almeno 2pt anche per un valore reale di 0 — una "barra fantasma" che marca comunque la posizione della categoria sull'asse, invece di lasciare uno spazio vuoto indistinguibile da un gap di layout. `draw_percentage` riceve `drawn_height`, non `bar_height`: l'etichetta della percentuale è quindi posizionata rispetto all'altezza *disegnata* (minimo 2pt), non a quella "vera" (che potrebbe essere 0) — un dettaglio che evita che l'etichetta di una categoria a zero finisca incollata all'asse invece che leggermente sopra di esso.
>
> *EN: `drawn_height = [bar_height, BASELINE_HEIGHT].max` always draws a visible bar of at least 2pt even for a real value of 0 — a "ghost bar" that still marks the category's position on the axis, instead of leaving an empty space indistinguishable from a layout gap. `draw_percentage` receives `drawn_height`, not `bar_height`: the percentage label is therefore positioned relative to the *drawn* height (minimum 2pt), not the "real" one (which could be 0) — a detail that keeps a zero-category's label from ending up glued to the axis instead of slightly above it.*
