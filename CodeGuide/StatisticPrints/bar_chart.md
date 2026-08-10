# `StatisticPrints::BarChart`

**File:** `app/services/statistic_prints/bar_chart.rb`

## Codice completo

```ruby
module StatisticPrints
  class BarChart
    SUCCESS = "28B62C"
    WARNING = "FF851B"
    DANGER = "FF4136"
    AXIS_COLOR = "999999"
    LABEL_COLOR = "666666"
    LEGEND_HEIGHT = 16
    LEGEND_ITEM_GAP = 16
    LABEL_HEIGHT = 20
    LABEL_GAP = 4
    PERCENT_HEIGHT = 14
    MAX_GROUP_WIDTH = 200
    MAX_WIDTH_RATIO = 0.7
    BASELINE_HEIGHT = 2
    AXIS_OVERHANG = 5 * 72 / 25.4

    def self.draw(...) = new(...).draw

    def initialize(pdf, at:, width:, height:, labels:, previous_data:, current_data:, percentages:,
      previous_label:, current_label:)
      @pdf = pdf
      @width = width * MAX_WIDTH_RATIO
      @at = [ at[0] + ((width - @width) / 2), at[1] ]
      @height = height
      @labels = labels
      @previous_data = previous_data
      @current_data = current_data
      @percentages = percentages
      @previous_label = previous_label
      @current_label = current_label
    end

    def draw
      draw_legend
      @labels.each_index { |index| draw_group(index) }
      draw_axis_line
    end

    private

    def plot_top = @at[1] - LEGEND_HEIGHT - PERCENT_HEIGHT
    def plot_bottom = @at[1] - @height + LABEL_HEIGHT
    def plot_height = plot_top - plot_bottom
    def content_width = [ @width, MAX_GROUP_WIDTH * @labels.size ].min
    def content_x = @at[0] + ((@width - content_width) / 2)
    def group_width = content_width / @labels.size
    def max_value = [ @previous_data.max, @current_data.max ].max.to_f * 1.15

    def draw_legend
      x = draw_legend_item(@at[0], SUCCESS, @previous_label)
      draw_legend_item(x, WARNING, @current_label)
    end

    def draw_legend_item(x, color, label)
      @pdf.fill_color color
      @pdf.fill_rectangle [ x, @at[1] ], 10, 10
      @pdf.fill_color "333333"
      label_width = 0
      @pdf.font("AsapCondensed", size: 9) do
        label_width = @pdf.width_of(label)
        @pdf.draw_text label, at: [ x + 14, @at[1] - 8 ]
      end
      x + 14 + label_width + LEGEND_ITEM_GAP
    end

    def draw_axis_line
      @pdf.stroke_color AXIS_COLOR
      @pdf.stroke_line [ content_x - AXIS_OVERHANG, plot_bottom ], [ content_x + content_width + AXIS_OVERHANG, plot_bottom ]
    end

    def draw_group(index)
      x = content_x + (index * group_width)
      bar_width = group_width * 0.32
      draw_bar(x + (group_width * 0.12), bar_width, @previous_data[index], SUCCESS)
      draw_bar(x + (group_width * 0.52), bar_width, @current_data[index], WARNING, percentage: @percentages[index])
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
      @pdf.font("AsapCondensed", style: :bold, size: 9) do
        @pdf.text_box "#{sign}#{NumberFormatting.percent(percentage)}",
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

### Costanti colore

```ruby
SUCCESS = "28B62C"
WARNING = "FF851B"
DANGER = "FF4136"
AXIS_COLOR = "999999"
LABEL_COLOR = "666666"
```

> **IT:** Prawn non ha accesso a CSS o variabili SCSS: ogni colore va scritto come esadecimale letterale. `SUCCESS`/`WARNING`/`DANGER` non sono scelti a occhio, sono copiati dai valori **compilati** del tema Bootswatch Lumen (`app/assets/builds/application.css`: `--bs-success: #28b62c`, `--bs-warning: #ff851b`, `--bs-danger: #ff4136`) e non dai default SCSS di Bootstrap — Lumen li sovrascrive, quindi prendere i default di Bootstrap avrebbe dato colori diversi da quelli visti a schermo nella pagina Statistiche (che usa Chart.js con le stesse variabili CSS). Se il tema Bootswatch venisse cambiato in futuro, questi tre esadecimali andrebbero risincronizzati a mano: non c'è alcun collegamento automatico tra il CSS compilato e queste costanti Ruby.
>
> *EN: Prawn has no access to CSS or SCSS variables: every color has to be written as a literal hex value. `SUCCESS`/`WARNING`/`DANGER` weren't picked by eye — they're copied from the **compiled** Bootswatch Lumen theme values (`app/assets/builds/application.css`: `--bs-success: #28b62c`, `--bs-warning: #ff851b`, `--bs-danger: #ff4136`), not from Bootstrap's own SCSS defaults — Lumen overrides them, so using Bootstrap's defaults would have produced colors different from what's shown on screen in the Statistics page (which uses Chart.js with the same CSS variables). If the Bootswatch theme were ever changed, these three hex constants would need to be resynced by hand: there's no automatic link between the compiled CSS and these Ruby constants.*

### `MAX_GROUP_WIDTH`, `MAX_WIDTH_RATIO`, `AXIS_OVERHANG`

```ruby
MAX_GROUP_WIDTH = 200
MAX_WIDTH_RATIO = 0.7
AXIS_OVERHANG = 5 * 72 / 25.4
```

> **IT:** `AXIS_OVERHANG` è l'unico punto di conversione mm→pt dentro questo file (`5mm * 72 / 25.4`), scritto inline invece che tramite un helper condiviso — come ogni altro file della cartella `statistic_prints`/`statistic_spi_prints`, questa conversione non è mai centralizzata in un modulo comune, è ripetuta punto per punto dove serve. `MAX_WIDTH_RATIO` (70%) e `MAX_GROUP_WIDTH` (200pt per coppia di barre) lavorano insieme per evitare due estetiche opposte indesiderate: barre larghissime e rade quando c'è un solo comprensorio nel grafico, o barre strette e ammassate quando ce ne sono molti — il grafico si restringe (`@width = width * MAX_WIDTH_RATIO`, centrato nello spazio originale) e ogni gruppo satura a `MAX_GROUP_WIDTH` invece di espandersi linearmente con lo spazio disponibile.
>
> *EN: `AXIS_OVERHANG` is the only mm→pt conversion point in this file (`5mm * 72 / 25.4`), written inline rather than through a shared helper — like every other file in the `statistic_prints`/`statistic_spi_prints` folders, this conversion is never centralized in a common module, it's repeated wherever it's needed. `MAX_WIDTH_RATIO` (70%) and `MAX_GROUP_WIDTH` (200pt per bar pair) work together to avoid two unwanted opposite aesthetics: very wide, sparse bars when the chart has only one comprensorio, or narrow, crammed bars when it has many — the chart shrinks (`@width = width * MAX_WIDTH_RATIO`, centered within the original space) and each group caps at `MAX_GROUP_WIDTH` instead of expanding linearly with the available space.*

### `initialize`

```ruby
def initialize(pdf, at:, width:, height:, labels:, previous_data:, current_data:, percentages:,
  previous_label:, current_label:)
  @pdf = pdf
  @width = width * MAX_WIDTH_RATIO
  @at = [ at[0] + ((width - @width) / 2), at[1] ]
  @height = height
  ...
```

> **IT:** `at:`, `width:` e `height:` sono argomenti obbligatori, mai letti da `@pdf.bounds`/`@pdf.cursor` internamente: la geometria del grafico è sempre decisa dal chiamante (una pagina come `RegionalPage` o `EmploymentStatusPage`), non da questa classe. È la conseguenza diretta del fatto che `pdf.bounding_box` senza `height:` esplicito è "elastico" (calcola l'altezza dal cursore corrente, non dal fondo pagina): se `BarChart` leggesse `@pdf.cursor` da sé, due colonne affiancate con contenuti di altezza diversa sopra di loro (es. tabella + grafico a fianco di una tabella percentuali più corta, vedi `EmploymentStatusPage#draw_chart_and_percentages`) finirebbero disallineate in verticale. Passare `at:`/`height:` espliciti permette al chiamante di calcolare un `top` condiviso una volta sola e usarlo per entrambe le colonne.
>
> *EN: `at:`, `width:`, and `height:` are required arguments, never read from `@pdf.bounds`/`@pdf.cursor` internally: the chart's geometry is always decided by the caller (a page like `RegionalPage` or `EmploymentStatusPage`), never by this class. This is the direct consequence of `pdf.bounding_box` without an explicit `height:` being "stretchy" (it computes height from the current cursor, not from the page bottom): if `BarChart` read `@pdf.cursor` itself, two side-by-side columns with content of different heights above them (e.g. a table plus a chart next to a shorter percentages table, see `EmploymentStatusPage#draw_chart_and_percentages`) would end up misaligned vertically. Passing explicit `at:`/`height:` lets the caller compute a shared `top` once and use it for both columns.*

### `draw`, i metodi di layout (`plot_top`, `plot_bottom`, `plot_height`, `content_width`, `content_x`, `group_width`, `max_value`)

```ruby
def draw
  draw_legend
  @labels.each_index { |index| draw_group(index) }
  draw_axis_line
end

private

def plot_top = @at[1] - LEGEND_HEIGHT - PERCENT_HEIGHT
def plot_bottom = @at[1] - @height + LABEL_HEIGHT
def plot_height = plot_top - plot_bottom
def content_width = [ @width, MAX_GROUP_WIDTH * @labels.size ].min
def content_x = @at[0] + ((@width - content_width) / 2)
def group_width = content_width / @labels.size
def max_value = [ @previous_data.max, @current_data.max ].max.to_f * 1.15
```

> **IT:** Tutte le coordinate sono derivate, ricalcolate a ogni chiamata invece che memoizzate in `initialize` — un file piccolo, ricalcolare non ha costo percepibile, e tenere la logica in metodi a una riga (endless methods) la rende leggibile come una serie di formule piuttosto che come stato mutabile. `max_value` moltiplica per `1.15` per lasciare un margine sopra la barra più alta: senza quel margine l'etichetta della percentuale (disegnata sopra la barra corrente, si veda `draw_percentage`) rischierebbe di uscire dal riquadro del grafico quando la barra tocca il bordo superiore del plot.
>
> *EN: Every coordinate is derived, recomputed on each call rather than memoized in `initialize` — the file is small, recomputation has no perceptible cost, and keeping the logic in one-line (endless) methods makes it read like a series of formulas rather than mutable state. `max_value` multiplies by `1.15` to leave headroom above the tallest bar: without that margin, the percentage label (drawn above the current-year bar, see `draw_percentage`) would risk spilling outside the chart's box when a bar reaches the top of the plot area.*

### `draw_legend`, `draw_legend_item`

```ruby
def draw_legend
  x = draw_legend_item(@at[0], SUCCESS, @previous_label)
  draw_legend_item(x, WARNING, @current_label)
end

def draw_legend_item(x, color, label)
  @pdf.fill_color color
  @pdf.fill_rectangle [ x, @at[1] ], 10, 10
  @pdf.fill_color "333333"
  ...
  x + 14 + label_width + LEGEND_ITEM_GAP
end
```

> **IT:** `draw_legend_item` restituisce la coordinata `x` dopo cui posizionare l'elemento successivo, invece di ricevere due `x` fissi calcolati in anticipo: la larghezza dell'etichetta "Tesseramento Ottobre 2025" dipende dal testo effettivo (mese e anno cambiano a ogni report), quindi va misurata con `@pdf.width_of` **dopo** aver impostato il font, non stimata a priori. Questo pattern a "cursore orizzontale che ritorna la propria posizione finale" ricorre identico in `PieChart#draw_legend`/`#legend_item_width`.
>
> *EN: `draw_legend_item` returns the `x` coordinate after which to place the next element, instead of receiving two fixed `x`s computed upfront: the width of a label like "Tesseramento Ottobre 2025" depends on the actual text (month and year change on every report), so it has to be measured with `@pdf.width_of` **after** the font is set, not guessed ahead of time. This "horizontal cursor that returns its own end position" pattern recurs identically in `PieChart#draw_legend`/`#legend_item_width`.*

### `draw_axis_line`

```ruby
def draw_axis_line
  @pdf.stroke_color AXIS_COLOR
  @pdf.stroke_line [ content_x - AXIS_OVERHANG, plot_bottom ], [ content_x + content_width + AXIS_OVERHANG, plot_bottom ]
end
```

> **IT:** L'asse è disegnato **per ultimo**, dopo tutte le barre — non perché l'ordine di disegno cambi il risultato visivo (l'asse è una linea sottile che non copre nulla), ma per coerenza con `draw`: la sequenza legenda → barre → asse rispecchia l'ordine di lettura dall'alto verso il basso del grafico finito. `AXIS_OVERHANG` fa sporgere la linea oltre il primo e l'ultimo gruppo di barre, un dettaglio puramente estetico mutuato dalle convenzioni dei grafici Chart.js a schermo.
>
> *EN: The axis is drawn **last**, after all the bars — not because draw order changes the visual result (the axis is a thin line that covers nothing), but for consistency with `draw`: the legend → bars → axis sequence mirrors the finished chart's top-to-bottom reading order. `AXIS_OVERHANG` makes the line extend past the first and last bar groups, a purely aesthetic detail borrowed from the on-screen Chart.js conventions.*

### `draw_group`, `draw_bar`, `draw_percentage`, `draw_label`

```ruby
def draw_group(index)
  x = content_x + (index * group_width)
  bar_width = group_width * 0.32
  draw_bar(x + (group_width * 0.12), bar_width, @previous_data[index], SUCCESS)
  draw_bar(x + (group_width * 0.52), bar_width, @current_data[index], WARNING, percentage: @percentages[index])
  draw_label(index)
end

def draw_bar(x, width, value, color, percentage: nil)
  bar_height = max_value.zero? ? 0 : (value.to_f / max_value) * plot_height
  drawn_height = [ bar_height, BASELINE_HEIGHT ].max
  @pdf.fill_color color
  @pdf.fill_rectangle [ x, plot_bottom + drawn_height ], width, drawn_height
  draw_percentage(x, width, bar_height, percentage) if percentage
end
```

> **IT:** `draw_bar` disegna sempre due barre per gruppo (0.12 e 0.52 di `group_width`, entrambe larghe 0.32): questo è il "two-series" del nome file, il confronto anno su anno che dà il nome anche al controller Stimulus gemello `comparison-chart` lato schermo (vedi `CodeGuide/Statistics/README.md`). `drawn_height = [bar_height, BASELINE_HEIGHT].max` garantisce che anche un valore a zero produca una barra visibile di 2pt invece di sparire del tutto: senza questo minimo, un comprensorio con zero iscritti in un anno risulterebbe indistinguibile da un comprensorio assente dal grafico. Solo la barra "corrente" (arancione) riceve `percentage:` — la percentuale di variazione ha senso solo rispetto all'anno precedente, non ha un equivalente per la barra verde stessa.
>
> *EN: `draw_bar` always draws two bars per group (at 0.12 and 0.52 of `group_width`, both 0.32 wide): this is the "two-series" comparison from the file's name, the year-over-year comparison that also names the sibling on-screen Stimulus controller `comparison-chart` (see `CodeGuide/Statistics/README.md`). `drawn_height = [bar_height, BASELINE_HEIGHT].max` guarantees that even a zero value produces a visible 2pt bar instead of vanishing entirely: without this floor, a comprensorio with zero members in a given year would be indistinguishable from a comprensorio missing from the chart altogether. Only the "current" (orange) bar receives `percentage:` — the change percentage only makes sense relative to the previous year, it has no equivalent for the green bar itself.*

```ruby
def draw_percentage(x, width, bar_height, percentage)
  color = percentage.negative? ? DANGER : SUCCESS
  sign = percentage.positive? ? "+" : ""
  ...
end
```

> **IT:** Il colore della percentuale dipende dal segno della variazione (rosso se negativa, verde altrimenti — zero è trattato come "non negativo", quindi verde), indipendentemente dal colore della barra a cui è associata (sempre arancione, `WARNING`): sono due codifiche colore separate e non correlate, una per "quale anno" (verde/arancio) e una per "la variazione è buona o cattiva" (verde/rosso). Il segno `+` è aggiunto esplicitamente per i valori positivi perché `NumberFormatting.percent` non lo fa da solo (restituisce `"12,34%"`, non `"+12,34%"`), mentre per i negativi il segno meno è già incluso nel numero formattato.
>
> *EN: The percentage's color depends on the sign of the change (red if negative, green otherwise — zero counts as "not negative," hence green), independently of the color of the bar it's attached to (always orange, `WARNING`): these are two separate, unrelated color codings, one for "which year" (green/orange) and one for "is the change good or bad" (green/red). The `+` sign is added explicitly for positive values because `NumberFormatting.percent` doesn't add it on its own (it returns `"12.34%"`, not `"+12.34%"`), while for negative values the minus sign is already part of the formatted number.*
