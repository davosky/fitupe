# `StatisticPrints::SingleSeriesBarChart`

**File:** `app/services/statistic_prints/single_series_bar_chart.rb`

## Codice completo

```ruby
module StatisticPrints
  class SingleSeriesBarChart
    WARNING = "FF851B"
    DANGER = "FF4136"
    SUCCESS = "28B62C"
    PRIMARY = "158CBA"
    INFO = "75CAEB"
    DARK = "555555"
    PALETTE = [ WARNING, DANGER, SUCCESS, PRIMARY, INFO, DARK ].freeze
    AXIS_COLOR = "999999"
    LABEL_COLOR = "666666"
    LABEL_HEIGHT = 20
    LABEL_GAP = 4
    VALUE_HEIGHT = 12
    MAX_GROUP_WIDTH = 90
    BASELINE_HEIGHT = 2
    AXIS_OVERHANG = 5 * 72 / 25.4

    def self.draw(...) = new(...).draw

    def initialize(pdf, at:, width:, height:, labels:, data:, percentages: nil)
      @pdf = pdf
      @at = at
      @width = width
      @height = height
      @labels = labels
      @data = data
      @percentages = percentages
    end

    def draw
      @labels.each_index { |index| draw_group(index) }
      draw_axis_line
    end

    private

    def plot_top = @at[1] - VALUE_HEIGHT
    def plot_bottom = @at[1] - @height + LABEL_HEIGHT
    def plot_height = plot_top - plot_bottom
    def content_width = [ @width, MAX_GROUP_WIDTH * @labels.size ].min
    def content_x = @at[0] + ((@width - content_width) / 2)
    def group_width = content_width / @labels.size
    def max_value = @data.max.to_f * 1.15

    def draw_group(index)
      x = content_x + (index * group_width)
      bar_width = group_width * 0.6
      draw_bar(x + (group_width * 0.2), bar_width, @data[index], PALETTE[index % PALETTE.length], index)
      draw_label(index)
    end

    def draw_bar(x, width, value, color, index)
      bar_height = max_value.zero? ? 0 : (value.to_f / max_value) * plot_height
      drawn_height = [ bar_height, BASELINE_HEIGHT ].max
      @pdf.fill_color color
      @pdf.fill_rectangle [ x, plot_bottom + drawn_height ], width, drawn_height
      draw_value(x, width, bar_height, index)
    end

    def draw_value(x, width, bar_height, index)
      @pdf.fill_color "333333"
      @pdf.font("AsapCondensed", style: :bold, size: 8) do
        @pdf.text_box value_label(index), at: [ x - 20, plot_bottom + bar_height + VALUE_HEIGHT ], width: width + 40,
          align: :center
      end
    end

    def value_label(index)
      return NumberFormatting.percent(@percentages[index]) || "" if @percentages

      NumberFormatting.count(@data[index])
    end

    def draw_label(index)
      x = content_x + (index * group_width)
      @pdf.fill_color LABEL_COLOR
      @pdf.font("AsapCondensed", style: :italic, size: 7) do
        @pdf.text_box @labels[index], at: [ x, plot_bottom - LABEL_GAP ], width: group_width, align: :center,
          overflow: :shrink_to_fit, min_font_size: 5, single_line: true
      end
    end

    def draw_axis_line
      @pdf.stroke_color AXIS_COLOR
      @pdf.stroke_line [ content_x - AXIS_OVERHANG, plot_bottom ], [ content_x + content_width + AXIS_OVERHANG, plot_bottom ]
    end
  end
end
```

## Sezioni commentate

### Perché esiste una classe separata da `BarChart`

> **IT:** `BarChart` e `SingleSeriesBarChart` non sono due varianti configurabili della stessa classe, sono due classi indipendenti, perché rappresentano due domande statistiche diverse: `BarChart` confronta lo **stesso gruppo** in due periodi (iscritti di un comprensorio ora vs un anno fa — due serie, "previous"/"current", sempre nello stesso colore per serie), mentre `SingleSeriesBarChart` confronta **gruppi diversi** nello stesso periodo (le fasce di età, o le tipologie di provvisoria/revoca, tutte nell'anno corrente — una serie sola, un colore diverso per ciascuna barra). Questa distinzione ricalca esattamente quella lato schermo tra i controller Stimulus `comparison-chart` e `bar-chart`, documentata in `CodeGuide/Statistics/README.md`: stesso confine concettuale, riprodotto lato server per la stampa PDF. Provare a unificarle in una sola classe con un flag `single_series: true/false` avrebbe reso `initialize` (due firme di argomenti incompatibili: `previous_data`/`current_data`/`previous_label`/`current_label` contro `data` semplice) e il calcolo del colore (per-serie vs per-barra) più complicati da leggere di due file separati e brevi.
>
> *EN: `BarChart` and `SingleSeriesBarChart` aren't two configurable variants of the same class, they're two independent classes, because they answer two different statistical questions: `BarChart` compares the **same group** across two periods (a comprensorio's members now vs. a year ago — two series, "previous"/"current", always the same color per series), while `SingleSeriesBarChart` compares **different groups** within the same period (age bands, or provisional/revocation types, all in the current year — a single series, a different color per bar). This split exactly mirrors the on-screen distinction between the `comparison-chart` and `bar-chart` Stimulus controllers, documented in `CodeGuide/Statistics/README.md`: the same conceptual boundary, reproduced server-side for the PDF. Trying to unify them into one class with a `single_series: true/false` flag would have made `initialize` (two incompatible argument shapes: `previous_data`/`current_data`/`previous_label`/`current_label` vs. a plain `data`) and the color logic (per-series vs. per-bar) harder to read than two short, separate files.*

### `PALETTE`

```ruby
WARNING = "FF851B"
DANGER = "FF4136"
SUCCESS = "28B62C"
PRIMARY = "158CBA"
INFO = "75CAEB"
DARK = "555555"
PALETTE = [ WARNING, DANGER, SUCCESS, PRIMARY, INFO, DARK ].freeze
```

> **IT:** Sei colori ciclici (`PALETTE[index % PALETTE.length]`), copiati dai valori compilati `--bs-warning/danger/success/primary/info` di Bootswatch Lumen (`DARK` è l'unico che non mappa 1:1 su una variabile Bootstrap standard, scelto a mano per completare la palette). L'ordine — arancio, rosso, verde, blu, azzurro, grigio scuro — è lo stesso ordine usato lato schermo dal controller Stimulus `bar-chart` (vedi `CodeGuide/Statistics/README.md`), non arbitrario: mantenere lo stesso ordine garantisce che la stessa fascia d'età o la stessa categoria abbia lo stesso colore sia a schermo sia nel PDF stampato, per riconoscibilità visiva tra le due interfacce.
>
> *EN: Six cycling colors (`PALETTE[index % PALETTE.length]`), copied from Bootswatch Lumen's compiled `--bs-warning/danger/success/primary/info` values (`DARK` is the only one with no 1:1 mapping to a standard Bootstrap variable, hand-picked to round out the palette). The order — orange, red, green, blue, light blue, dark gray — is the same order used on screen by the `bar-chart` Stimulus controller (see `CodeGuide/Statistics/README.md`), not arbitrary: keeping the same order guarantees the same age band or category gets the same color both on screen and in the printed PDF, for visual recognizability across the two interfaces.*

### `initialize`, geometria (`plot_top`, `plot_bottom`, `content_width`, `group_width`, `max_value`)

```ruby
def initialize(pdf, at:, width:, height:, labels:, data:, percentages: nil)
  @pdf = pdf
  @at = at
  @width = width
  ...
end

private

def plot_top = @at[1] - VALUE_HEIGHT
def plot_bottom = @at[1] - @height + LABEL_HEIGHT
def plot_height = plot_top - plot_bottom
def content_width = [ @width, MAX_GROUP_WIDTH * @labels.size ].min
def content_x = @at[0] + ((@width - content_width) / 2)
def group_width = content_width / @labels.size
def max_value = @data.max.to_f * 1.15
```

> **IT:** A differenza di `BarChart`, qui `@width` non viene ridotto da un `MAX_WIDTH_RATIO`: non c'è restringimento globale del grafico, perché non c'è la legenda a due voci che in `BarChart` va centrata sopra un'area più stretta. `MAX_GROUP_WIDTH` è molto più piccolo (90pt contro 200pt di `BarChart`): un gruppo qui ha una sola barra invece di due affiancate, quindi serve meno larghezza per restare leggibile. Nessun argomento è opzionale tranne `percentages:` — questa è la stessa classe usata sia per le fasce d'età SPI (`StatisticSpiPrints::AgeClassesPage`, con `percentages:` per mostrare una percentuale sopra ogni barra) sia per le tipologie di provvisoria/revoca Attivi (`ProvisionalRevocationsPage`, senza `percentages:`, mostra il conteggio assoluto).
>
> *EN: Unlike `BarChart`, `@width` isn't shrunk by a `MAX_WIDTH_RATIO` here: there's no global chart narrowing, because there's no two-item legend that in `BarChart` needs to be centered over a narrower area. `MAX_GROUP_WIDTH` is much smaller (90pt vs. `BarChart`'s 200pt): a group here has a single bar instead of two side by side, so it needs less width to stay legible. No argument is optional except `percentages:` — this is the same class used both for SPI age bands (`StatisticSpiPrints::AgeClassesPage`, with `percentages:` to show a percentage above each bar) and for Attivi provisional/revocation types (`ProvisionalRevocationsPage`, without `percentages:`, showing the raw count instead).*

### `draw_group`, `draw_bar`

```ruby
def draw_group(index)
  x = content_x + (index * group_width)
  bar_width = group_width * 0.6
  draw_bar(x + (group_width * 0.2), bar_width, @data[index], PALETTE[index % PALETTE.length], index)
  draw_label(index)
end
```

> **IT:** Una sola barra per gruppo (0.2 di margine su ciascun lato, 0.6 di larghezza), contro le due di `BarChart`: è la differenza strutturale che dà il nome alla classe. Il colore è scelto per **indice della barra**, non per valore o categoria — la stessa fascia d'età ha sempre lo stesso colore indipendentemente da quanti iscritti conta, coerente con `CategoryBarChart`/`GroupedCategoryBarChart` lato SPI che seguono la stessa convenzione.
>
> *EN: A single bar per group (0.2 margin on each side, 0.6 width), versus `BarChart`'s two: it's the structural difference that names the class. Color is chosen by **bar index**, not by value or category — the same age band always gets the same color regardless of how many members it counts, consistent with `CategoryBarChart`/`GroupedCategoryBarChart` on the SPI side, which follow the same convention.*

### `draw_value`, `value_label`

```ruby
def draw_value(x, width, bar_height, index)
  @pdf.fill_color "333333"
  @pdf.font("AsapCondensed", style: :bold, size: 8) do
    @pdf.text_box value_label(index), at: [ x - 20, plot_bottom + bar_height + VALUE_HEIGHT ], width: width + 40,
      align: :center
  end
end

def value_label(index)
  return NumberFormatting.percent(@percentages[index]) || "" if @percentages

  NumberFormatting.count(@data[index])
end
```

> **IT:** `value_label` è il punto in cui `percentages:` cambia comportamento: se presente, l'etichetta sopra la barra mostra una percentuale invece del conteggio assoluto — usato da `StatisticSpiPrints::AgeClassesPage` per mostrare "% sul totale comprensorio" sopra ogni fascia d'età invece del numero di persone, senza dover toccare né questa classe né le sezioni che continuano a passare solo `data:`. `|| ""` copre il caso in cui una singola percentuale sia `nil` (denominatore zero per quel comprensorio): l'etichetta resta vuota invece di mostrare la stringa letterale `"nil"` o sollevare un errore di interpolazione.
>
> *EN: `value_label` is where `percentages:` changes behavior: when present, the label above the bar shows a percentage instead of the raw count — used by `StatisticSpiPrints::AgeClassesPage` to show "% of the comprensorio's total" above each age band instead of the headcount, without having to touch either this class or the sections that keep passing just `data:`. `|| ""` covers the case where a single percentage is `nil` (zero denominator for that comprensorio): the label stays blank instead of showing the literal string `"nil"` or raising an interpolation error.*

### `draw_label`

```ruby
def draw_label(index)
  x = content_x + (index * group_width)
  @pdf.fill_color LABEL_COLOR
  @pdf.font("AsapCondensed", style: :italic, size: 7) do
    @pdf.text_box @labels[index], at: [ x, plot_bottom - LABEL_GAP ], width: group_width, align: :center,
      overflow: :shrink_to_fit, min_font_size: 5, single_line: true
  end
end
```

> **IT:** `overflow: :shrink_to_fit, min_font_size: 5, single_line: true` non compare in `BarChart#draw_label` (che usa `text_box` senza queste opzioni): qui è necessario perché le etichette possono essere molto più numerose e più corte in larghezza disponibile per etichetta (`group_width` con `MAX_GROUP_WIDTH = 90` contro `200` di `BarChart`, e fino a nove fasce d'età affiancate) — un'etichetta come "QUARANTACINQUENNI" a font fisso 7pt in uno spazio da 90pt/9 ≈ 10pt andrebbe sicuramente a capo o fuori bordo senza il ridimensionamento automatico. `single_line: true` impedisce a Prawn di scegliere da sé di andare a capo, forzandolo invece a rimpicciolire il font fino a `min_font_size` pur di stare su una riga.
>
> *EN: `overflow: :shrink_to_fit, min_font_size: 5, single_line: true` doesn't appear in `BarChart#draw_label` (which uses `text_box` without these options): here it's necessary because labels can be far more numerous with much less width available per label (`group_width` with `MAX_GROUP_WIDTH = 90` vs. `BarChart`'s `200`, and up to nine age bands side by side) — a label like "QUARANTACINQUENNI" at a fixed 7pt font in a ~90pt/9 ≈ 10pt space would definitely wrap or overflow without automatic resizing. `single_line: true` stops Prawn from choosing to wrap on its own, forcing it instead to shrink the font down to `min_font_size` to stay on one line.*

### `draw_axis_line`

```ruby
def draw_axis_line
  @pdf.stroke_color AXIS_COLOR
  @pdf.stroke_line [ content_x - AXIS_OVERHANG, plot_bottom ], [ content_x + content_width + AXIS_OVERHANG, plot_bottom ]
end
```

> **IT:** Riga identica a `BarChart#draw_axis_line`, inclusa la ripetizione locale di `AXIS_OVERHANG = 5 * 72 / 25.4`: nessuna delle due classi importa la costante dall'altra, ognuna ha la propria copia. Sintomatico della filosofia generale della cartella (vedi `bar_chart.md`): niente helper condivisi per conversioni mm→pt o costanti geometriche minori, a costo di duplicazione, per mantenere ogni file di chart leggibile in isolamento.
>
> *EN: Line-for-line identical to `BarChart#draw_axis_line`, including the local repetition of `AXIS_OVERHANG = 5 * 72 / 25.4`: neither class imports the constant from the other, each has its own copy. Symptomatic of the folder's general philosophy (see `bar_chart.md`): no shared helpers for mm→pt conversions or minor geometric constants, at the cost of duplication, to keep each chart file readable in isolation.*
