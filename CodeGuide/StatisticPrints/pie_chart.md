# `StatisticPrints::PieChart`

**File:** `app/services/statistic_prints/pie_chart.rb`

## Codice completo

```ruby
module StatisticPrints
  class PieChart
    COLORS = %w[28B62C FF851B FF4136].freeze
    LEGEND_HEIGHT = 16
    ARC_STEP_DEGREES = 3
    SIZE_RATIO = 0.65
    # Sotto questa ampiezza la fetta e' troppo stretta per contenere
    # l'etichetta al suo interno: esce fuori dal cerchio, collegata da una
    # linea (a specchio delle "callout label" dei grafici a torta).
    SMALL_SLICE_THRESHOLD_DEGREES = 20
    EXTERNAL_LABEL_WIDTH = 70
    EXTERNAL_LABEL_TEXT_COLOR = "333333"
    EXTERNAL_LABEL_LINE_COLOR = "999999"
    LEADER_LENGTH = 12
    # Fette piccole consecutive (tipico caso: piu' comprensori con percentuali
    # minime) avrebbero altrimenti le etichette esterne tutte alla stessa
    # distanza dal cerchio, sovrapposte fra loro: ogni etichetta esterna in
    # piu' si allontana un po' di piu' dalla precedente.
    LEADER_STAGGER_STEP = 11

    def self.draw(...) = new(...).draw

    def initialize(pdf, at:, width:, height:, labels:, data:, colors: COLORS, label_formatter: nil)
      @pdf = pdf
      @at = at
      @width = width
      @height = height
      @labels = labels
      @data = data
      @colors = colors
      @label_formatter = label_formatter || method(:default_label)
      @external_label_count = 0
    end

    def draw
      draw_slices
      draw_legend
    end

    private

    def total = @data.sum.to_f
    def circle_area_height = @height - LEGEND_HEIGHT
    def diameter = [ @width, circle_area_height ].min * SIZE_RATIO
    def radius = diameter / 2.0
    def center = [ @at[0] + (@width / 2.0), @at[1] - (circle_area_height / 2.0) ]

    def draw_slices
      return if total.zero?

      angle = 90.0
      @data.each_index do |index|
        fraction = @data[index] / total
        sweep = fraction * 360.0
        draw_slice(angle, sweep, @colors[index % @colors.length])
        draw_label(angle, sweep, @data[index], fraction) if @data[index].positive?
        angle -= sweep
      end
    end

    def draw_slice(start_deg, sweep_deg, color)
      return if sweep_deg.zero?

      @pdf.fill_color color
      @pdf.fill_polygon(*([ center ] + arc_points(start_deg, sweep_deg)))
    end

    def arc_points(start_deg, sweep_deg)
      steps = [ (sweep_deg / ARC_STEP_DEGREES).ceil, 1 ].max
      (0..steps).map { |step| point_at(start_deg - (sweep_deg * step / steps)) }
    end

    def point_at(deg)
      rad = deg * Math::PI / 180
      [ center[0] + (radius * Math.cos(rad)), center[1] + (radius * Math.sin(rad)) ]
    end

    def draw_label(start_deg, sweep_deg, value, fraction)
      if sweep_deg < SMALL_SLICE_THRESHOLD_DEGREES
        draw_external_label(start_deg, sweep_deg, value, fraction)
      else
        draw_internal_label(start_deg, sweep_deg, value, fraction)
      end
    end

    def draw_internal_label(start_deg, sweep_deg, value, fraction)
      rad = (start_deg - (sweep_deg / 2.0)) * Math::PI / 180
      label_radius = radius * 0.6
      x = center[0] + (label_radius * Math.cos(rad))
      y = center[1] + (label_radius * Math.sin(rad))

      draw_label_lines(@label_formatter.call(value, fraction), x - 30, y, "FFFFFF")
    end

    def draw_external_label(start_deg, sweep_deg, value, fraction)
      mid_rad = (start_deg - (sweep_deg / 2.0)) * Math::PI / 180
      cos = Math.cos(mid_rad)
      sin = Math.sin(mid_rad)
      edge = [ center[0] + (radius * cos), center[1] + (radius * sin) ]
      leader_radius = radius + LEADER_LENGTH + (@external_label_count * LEADER_STAGGER_STEP)
      tip = [ center[0] + (leader_radius * cos), center[1] + (leader_radius * sin) ]
      @external_label_count += 1

      @pdf.stroke_color EXTERNAL_LABEL_LINE_COLOR
      @pdf.line_width 0.5
      @pdf.stroke_line edge, tip

      right_side = cos >= 0
      text_x = right_side ? tip[0] + 2 : tip[0] - 2 - EXTERNAL_LABEL_WIDTH
      draw_label_lines(@label_formatter.call(value, fraction), text_x, tip[1], EXTERNAL_LABEL_TEXT_COLOR,
        align: right_side ? :left : :right, width: EXTERNAL_LABEL_WIDTH)
    end

    def draw_label_lines(lines, x, y, color, align: :center, width: 60)
      @pdf.fill_color color
      @pdf.font("AsapCondensed", style: :bold, size: 8) do
        if lines.size > 1
          @pdf.text_box lines[0], at: [ x, y + 10 ], width: width, align: align
          @pdf.text_box lines[1], at: [ x, y - 2 ], width: width, align: align
        else
          @pdf.text_box lines[0], at: [ x, y + 4 ], width: width, align: align
        end
      end
    end

    def default_label(value, fraction)
      [ NumberFormatting.count(value), "(#{NumberFormatting.percent(fraction * 100)})" ]
    end

    def draw_legend
      x = @at[0] + ((@width - legend_width) / 2)
      y = @at[1] - circle_area_height - 2
      @labels.each_index do |index|
        draw_legend_item(x, y, @colors[index % @colors.length], @labels[index])
        x += legend_item_width(index)
      end
    end

    def draw_legend_item(x, y, color, label)
      @pdf.fill_color color
      @pdf.fill_rectangle [ x, y ], 8, 8
      @pdf.fill_color "333333"
      @pdf.font("AsapCondensed", size: 8) { @pdf.draw_text label, at: [ x + 12, y - 6 ] }
    end

    def legend_item_width(index)
      label_width = nil
      @pdf.font("AsapCondensed", size: 8) { label_width = @pdf.width_of(@labels[index]) }
      12 + label_width + 14
    end

    def legend_width
      @labels.each_index.sum { |index| legend_item_width(index) } - 14
    end
  end
end
```

## Sezioni commentate

### `COLORS`, `SMALL_SLICE_THRESHOLD_DEGREES`, `LEADER_STAGGER_STEP` (costanti commentate)

```ruby
COLORS = %w[28B62C FF851B FF4136].freeze
...
# Sotto questa ampiezza la fetta e' troppo stretta per contenere
# l'etichetta al suo interno: esce fuori dal cerchio, collegata da una
# linea (a specchio delle "callout label" dei grafici a torta).
SMALL_SLICE_THRESHOLD_DEGREES = 20
...
# Fette piccole consecutive (tipico caso: piu' comprensori con percentuali
# minime) avrebbero altrimenti le etichette esterne tutte alla stessa
# distanza dal cerchio, sovrapposte fra loro: ogni etichetta esterna in
# piu' si allontana un po' di piu' dalla precedente.
LEADER_STAGGER_STEP = 11
```

> **IT:** `COLORS` di default è la stessa terna verde/arancio/rosso di `BarChart` (stessi esadecimali `--bs-success/warning/danger` di Lumen), ma qui è un default **sovrascrivibile**, non hardcoded: `colors:` è un parametro di `initialize`. È la prima crepa nell'assunzione "tre fette" — questa classe nasce per grafici a torta a tre voci (es. maschi/femmine/non specificato), ma viene riusata per torte con un numero di fette variabile e sconosciuto a priori (i comprensori di una regione, in `StatisticSpiPrints::ProvvisoriePage`), da cui la necessità sia di un `colors:` esterno sia della logica `SMALL_SLICE_THRESHOLD_DEGREES`/`LEADER_STAGGER_STEP` per gestire fette strette e numerose senza etichette sovrapposte — un problema che non si presenta mai con solo tre fette omogenee.
>
> *EN: The default `COLORS` is the same green/orange/red trio as `BarChart` (same `--bs-success/warning/danger` Lumen hex values), but here it's an **overridable** default, not hardcoded: `colors:` is an `initialize` parameter. That's the first crack in the "three slices" assumption — this class was born for three-item pie charts (e.g. male/female/unspecified), but gets reused for pies with a variable, not-known-upfront slice count (a region's comprensori, in `StatisticSpiPrints::ProvvisoriePage`), hence the need for both an external `colors:` and the `SMALL_SLICE_THRESHOLD_DEGREES`/`LEADER_STAGGER_STEP` logic to handle many narrow slices without overlapping labels — a problem that never arises with just three homogeneous slices.*

### `initialize`

```ruby
def initialize(pdf, at:, width:, height:, labels:, data:, colors: COLORS, label_formatter: nil)
  @pdf = pdf
  @at = at
  @width = width
  @height = height
  @labels = labels
  @data = data
  @colors = colors
  @label_formatter = label_formatter || method(:default_label)
  @external_label_count = 0
end
```

> **IT:** `label_formatter:` è il secondo punto di estensione, oltre a `colors:`, ed è ciò che rende la classe riusabile per casi che non sono affatto "un totale con percentuale": `StatisticSpiPrints::ProvvisoriePage` passa `label_formatter: ->(value, _fraction) { [StatisticPrints::NumberFormatting.percent(value)] }` per una torta i cui "valori" sono già percentuali (non conteggi), dove mostrare sia il valore sia una seconda percentuale calcolata su di esso non avrebbe senso. Il default `method(:default_label)` usa la sintassi `Object#method` per ottenere un oggetto `Method` richiamabile con `.call` esattamente come una lambda passata esplicitamente — permette a `draw_internal_label`/`draw_external_label` di trattare `@label_formatter` in modo uniforme senza controllare se è il default o uno custom.
>
> *EN: `label_formatter:` is the second extension point, alongside `colors:`, and it's what makes this class reusable for cases that aren't a "total with a percentage" at all: `StatisticSpiPrints::ProvvisoriePage` passes `label_formatter: ->(value, _fraction) { [StatisticPrints::NumberFormatting.percent(value)] }` for a pie whose "values" are already percentages (not counts), where showing both the value and a second percentage computed from it wouldn't make sense. The default `method(:default_label)` uses `Object#method` syntax to get a `Method` object callable with `.call` exactly like an explicitly passed lambda — this lets `draw_internal_label`/`draw_external_label` treat `@label_formatter` uniformly without checking whether it's the default or a custom one.*

### `draw_slices`, `draw_slice`, `arc_points`, `point_at`

```ruby
def draw_slices
  return if total.zero?

  angle = 90.0
  @data.each_index do |index|
    fraction = @data[index] / total
    sweep = fraction * 360.0
    draw_slice(angle, sweep, @colors[index % @colors.length])
    draw_label(angle, sweep, @data[index], fraction) if @data[index].positive?
    angle -= sweep
  end
end
```

> **IT:** L'angolo parte da 90° (ore 12, in convenzione matematica standard con 0° a destra e angoli antiorari) e **decresce** (`angle -= sweep`), quindi le fette si susseguono in senso **orario** partendo dall'alto — la stessa convenzione grafica dei grafici a torta di Chart.js lato schermo. `return if total.zero?` evita una divisione per zero in `fraction = @data[index] / total`, lasciando semplicemente il cerchio non disegnato (nessun placeholder, nessun messaggio d'errore): la responsabilità di gestire "nessun dato" con un messaggio testuale è delle pagine chiamanti (es. `NationalityGenderPage#draw_message`), non di questa classe.
>
> *EN: The angle starts at 90° (12 o'clock, in standard mathematical convention with 0° to the right and counter-clockwise angles) and **decreases** (`angle -= sweep`), so slices proceed **clockwise** starting from the top — the same visual convention as the on-screen Chart.js pie charts. `return if total.zero?` avoids a division by zero in `fraction = @data[index] / total`, simply leaving the circle undrawn (no placeholder, no error message): the responsibility for handling "no data" with a text message belongs to the calling pages (e.g. `NationalityGenderPage#draw_message`), not to this class.*

```ruby
def draw_slice(start_deg, sweep_deg, color)
  return if sweep_deg.zero?

  @pdf.fill_color color
  @pdf.fill_polygon(*([ center ] + arc_points(start_deg, sweep_deg)))
end

def arc_points(start_deg, sweep_deg)
  steps = [ (sweep_deg / ARC_STEP_DEGREES).ceil, 1 ].max
  (0..steps).map { |step| point_at(start_deg - (sweep_deg * step / steps)) }
end
```

> **IT:** Prawn non ha un primitivo "arco di cerchio riempito": ogni fetta è approssimata con un poligono, il centro più una sequenza di punti sul bordo del cerchio a passi di circa `ARC_STEP_DEGREES` (3°) l'uno dall'altro. Più piccolo il passo, più liscia la curva ma più punti da calcolare — 3° è stato scelto empiricamente come sufficiente a non far percepire la poligonale a occhio nudo sulla stampa A4, senza appesantire il calcolo. `steps` ha un minimo di 1 (`[..., 1].max`) per evitare un poligono degenere quando `sweep_deg` è più piccolo di `ARC_STEP_DEGREES` (una fetta minuscola composta da una sola frazione di punto percentuale).
>
> *EN: Prawn has no "filled circular arc" primitive: every slice is approximated as a polygon, the center plus a sequence of points along the circle's edge spaced roughly `ARC_STEP_DEGREES` (3°) apart. The smaller the step, the smoother the curve but the more points to compute — 3° was empirically chosen as fine enough that the polygon approximation isn't visible to the eye on an A4 printout, without making the computation heavier. `steps` has a floor of 1 (`[..., 1].max`) to avoid a degenerate polygon when `sweep_deg` is smaller than `ARC_STEP_DEGREES` (a tiny slice made of a fraction of a percentage point).*

### `draw_label`, `draw_internal_label`, `draw_external_label`

```ruby
def draw_label(start_deg, sweep_deg, value, fraction)
  if sweep_deg < SMALL_SLICE_THRESHOLD_DEGREES
    draw_external_label(start_deg, sweep_deg, value, fraction)
  else
    draw_internal_label(start_deg, sweep_deg, value, fraction)
  end
end
```

> **IT:** Il ramo interno/esterno è deciso dall'ampiezza angolare della fetta, non dal suo valore assoluto o dalla sua posizione: una fetta piccola in una torta con poche categorie grandi si comporta esattamente come una fetta piccola in una torta con molte categorie piccole. `draw_internal_label` scrive in bianco al centro della fetta (contrasto garantito perché tutti i colori della palette sono scuri/saturi); `draw_external_label` collega la fetta a un'etichetta fuori dal cerchio con una linea sottile, il pattern "callout label" tipico quando lo spazio interno non basta per il testo.
>
> *EN: The internal/external branch is decided by the slice's angular width, not by its absolute value or position: a small slice in a pie with few large categories behaves exactly like a small slice in a pie with many small ones. `draw_internal_label` writes in white at the slice's center (contrast is guaranteed because every palette color is dark/saturated enough); `draw_external_label` connects the slice to a label outside the circle with a thin line, the typical "callout label" pattern for when there isn't enough room inside for the text.*

```ruby
def draw_external_label(start_deg, sweep_deg, value, fraction)
  ...
  leader_radius = radius + LEADER_LENGTH + (@external_label_count * LEADER_STAGGER_STEP)
  tip = [ center[0] + (leader_radius * cos), center[1] + (leader_radius * sin) ]
  @external_label_count += 1
  ...
  right_side = cos >= 0
  text_x = right_side ? tip[0] + 2 : tip[0] - 2 - EXTERNAL_LABEL_WIDTH
  draw_label_lines(@label_formatter.call(value, fraction), text_x, tip[1], EXTERNAL_LABEL_TEXT_COLOR,
    align: right_side ? :left : :right, width: EXTERNAL_LABEL_WIDTH)
end
```

> **IT:** `@external_label_count` è uno stato mutabile che accumula quante etichette esterne sono già state disegnate, e allontana ogni nuova etichetta esterna un po' di più dal cerchio (`LEADER_STAGGER_STEP` per etichetta): senza questa progressione, più fette piccole consecutive (il caso reale: molti comprensori con percentuali minime nella stessa torta) avrebbero etichette tutte alla stessa distanza dal cerchio, sovrapposte le une sulle altre e illeggibili. `right_side = cos >= 0` decide se il testo va allineato a sinistra (fetta nella metà destra del cerchio, testo scritto verso destra) o a destra (fetta nella metà sinistra, testo scritto verso sinistra) — evita che il testo delle etichette a sinistra del cerchio finisca "capovolto" rispetto al centro, cioè che parta lontano dal cerchio e si avvicini leggendo, invece di allontanarsi.
>
> *EN: `@external_label_count` is mutable state that accumulates how many external labels have already been drawn, and pushes each new external label a bit further from the circle (`LEADER_STAGGER_STEP` per label): without this progression, several consecutive small slices (the real case: many comprensori with tiny percentages in the same pie) would have labels all at the same distance from the circle, overlapping each other and unreadable. `right_side = cos >= 0` decides whether the text aligns left (slice in the circle's right half, text growing rightward) or right (slice in the left half, text growing leftward) — this avoids the left-side labels reading "backwards" relative to the circle, i.e. starting far from the circle and approaching it as you read, instead of moving away.*

### `draw_label_lines`, `default_label`

```ruby
def draw_label_lines(lines, x, y, color, align: :center, width: 60)
  @pdf.fill_color color
  @pdf.font("AsapCondensed", style: :bold, size: 8) do
    if lines.size > 1
      @pdf.text_box lines[0], at: [ x, y + 10 ], width: width, align: align
      @pdf.text_box lines[1], at: [ x, y - 2 ], width: width, align: align
    else
      @pdf.text_box lines[0], at: [ x, y + 4 ], width: width, align: align
    end
  end
end

def default_label(value, fraction)
  [ NumberFormatting.count(value), "(#{NumberFormatting.percent(fraction * 100)})" ]
end
```

> **IT:** `draw_label_lines` accetta sempre un **array** di righe di testo, non una stringa — il contratto implicito di `label_formatter:` (sia il default `default_label` sia quello passato da `ProvvisoriePage`, che restituisce `[testo]`, un array a un solo elemento). Prawn non fa andare a capo automaticamente il testo dentro un `text_box` centrato su due righe con margini precisi come qui servirebbe, quindi le due righe (conteggio e percentuale tra parentesi, nel default) sono disegnate come due `text_box` separati con offset verticali fissi (`y + 10`/`y - 2`), non come un'unica stringa con `\n`. `default_label` è l'unico punto di questo file che richiama `NumberFormatting`, ed è anche l'unico formatter che compone **due** informazioni (valore assoluto e percentuale) invece di una sola — coerente con l'essere il caso "generico", quello per cui la classe è stata scritta prima di essere estesa con `label_formatter:`.
>
> *EN: `draw_label_lines` always accepts an **array** of text lines, not a string — the implicit contract of `label_formatter:` (both the default `default_label` and the one passed by `ProvvisoriePage`, which returns `[text]`, a single-element array). Prawn doesn't auto-wrap text inside a `text_box` centered across two lines with the precise margins needed here, so the two lines (count and percentage in parentheses, in the default) are drawn as two separate `text_box`es with fixed vertical offsets (`y + 10`/`y - 2`), not as one string with `\n`. `default_label` is the only place in this file that calls `NumberFormatting`, and it's also the only formatter that composes **two** pieces of information (absolute value and percentage) instead of one — consistent with being the "generic" case, the one the class was originally written for before being extended with `label_formatter:`.*

### `draw_legend`, `draw_legend_item`, `legend_item_width`, `legend_width`

```ruby
def draw_legend
  x = @at[0] + ((@width - legend_width) / 2)
  y = @at[1] - circle_area_height - 2
  @labels.each_index do |index|
    draw_legend_item(x, y, @colors[index % @colors.length], @labels[index])
    x += legend_item_width(index)
  end
end
```

> **IT:** La legenda è orizzontale e centrata (`x` iniziale calcolato da `legend_width`, la somma delle larghezze di tutti gli elementi), posizionata **sotto** il cerchio (`circle_area_height` esclude già `LEGEND_HEIGHT` dallo spazio riservato al cerchio, si veda `circle_area_height`/`diameter`). Stesso pattern "cursore orizzontale che avanza e ritorna la propria larghezza" di `BarChart#draw_legend_item`, ma qui applicato a un numero di voci potenzialmente elevato (non solo due) — con molte fette la legenda può diventare più larga della pagina; questa classe non gestisce quel caso (nessun a capo automatico della legenda), un limite implicito da tenere presente se in futuro un grafico a torta avesse più di una manciata di categorie con etichette lunghe.
>
> *EN: The legend is horizontal and centered (initial `x` computed from `legend_width`, the sum of every item's width), positioned **below** the circle (`circle_area_height` already excludes `LEGEND_HEIGHT` from the space reserved for the circle, see `circle_area_height`/`diameter`). Same "horizontal cursor that advances and returns its own width" pattern as `BarChart#draw_legend_item`, but applied here to a potentially large number of entries (not just two) — with many slices the legend can grow wider than the page; this class doesn't handle that case (no automatic legend wrapping), an implicit limit worth keeping in mind if a future pie chart ever had more than a handful of long-labeled categories.*
