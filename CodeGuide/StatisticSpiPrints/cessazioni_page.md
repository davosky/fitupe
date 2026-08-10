# `StatisticSpiPrints::CessazioniPage`

**File:** `app/services/statistic_spi_prints/cessazioni_page.rb`

## Codice completo

```ruby
module StatisticSpiPrints
  # Pagina "Cessazioni": specchia app/views/statistic_spi/_cessazioni_card e
  # _cessazioni_comprensori_card, con l'aggiunta di una torta Cessazioni/Deleghe
  # Confermate per colonna (come ProvvisoriePage, non presente nel mockup ma
  # richiesta da davo dopo). Totale e Comprensori affiancati in colonne per
  # stare in una pagina sola.
  class CessazioniPage
    SECTION_GAP_MM = 8
    COLUMN_GAP_MM = 12
    CHART_HEIGHT_MM = 60
    COMPRENSORI_COLORS = %w[28B62C FF851B FF4136 158CBA 75CAEB].freeze
    ETICHETTE = StatisticSpi::CessazioniBreakdown::ETICHETTE

    def self.draw(...) = new(...).draw

    def initialize(pdf, form:, breakdown_service: StatisticSpi::CessazioniBreakdown)
      @pdf = pdf
      @form = form
      @breakdown_service = breakdown_service
    end

    def draw
      @pdf.fill_color "000000"
      draw_heading
      result = @breakdown_service.call(zoning: @form.zoning, anno: @form.anno, mese: @form.mese)
      if result.comprensori.present?
        draw_two_columns(result)
      else
        draw_totale_column(result, @pdf.bounds.left, @pdf.cursor, @pdf.bounds.width)
      end
    end

    private

    def draw_heading
      @pdf.font("AsapCondensed", style: :bold, size: 16) { @pdf.text heading_title }
      @pdf.move_down 2
      @pdf.font("AsapCondensed", size: 10) { @pdf.text "Tesseramento #{@form.mese} #{@form.anno}", color: "666666" }
      @pdf.move_down 8
      @pdf.stroke_color "CCCCCC"
      @pdf.stroke_horizontal_rule
      @pdf.move_down section_gap
    end

    def heading_title
      return "CGIL Cessazioni SPI – Regionale e Comprensori" if @form.zoning.regionale?

      "CGIL Cessazioni SPI – Comprensorio di #{@form.zoning.descrizione_azzonamento}"
    end

    def draw_two_columns(result)
      top = @pdf.cursor
      left = @pdf.bounds.left

      draw_totale_column(result, left, top, column_width)
      draw_comprensori_column(result, left + column_width + column_gap, top, column_width)
    end

    def draw_totale_column(result, x, top, width)
      @pdf.bounding_box([ x, top ], width: width, height: top) do
        CategoryTable.draw(@pdf, title: result.totale.zoning.descrizione_azzonamento, rows: [ result.totale ],
          etichette: ETICHETTE, total_label: "totale cessazioni")
        @pdf.move_down section_gap
        MotivoCessazionePercentageTable.draw(@pdf, row: result.totale, etichette: ETICHETTE)
        @pdf.move_down section_gap
        draw_totale_chart(result.totale, width)
      end
    end

    def draw_totale_chart(row, width)
      deleghe_confermate = row.deleghe_totale - row.totale
      StatisticPrints::PieChart.draw(
        @pdf, at: [ @pdf.bounds.left, @pdf.cursor ], width: width, height: chart_height,
        labels: [ "Cessazioni", "Deleghe Confermate" ], data: [ row.totale, deleghe_confermate ]
      )
    end

    def draw_comprensori_column(result, x, top, width)
      @pdf.bounding_box([ x, top ], width: width, height: top) do
        CategoryTable.draw(@pdf, title: "Comprensori", rows: result.comprensori, etichette: ETICHETTE,
          total_label: "totale cessazioni")
        @pdf.move_down section_gap
        CategoryPercentageTable.draw(@pdf, title: "Comprensori (%)", rows: result.comprensori, etichette: ETICHETTE)
        @pdf.move_down section_gap
        draw_comprensori_chart(result.comprensori, width)
      end
    end

    def draw_comprensori_chart(comprensori, width)
      percentuali = comprensori.map { |row| comprensorio_percentuale(row) }
      deleghe_confermate_percentuale = 100.0 - percentuali.sum
      labels = comprensori.map { |row| row.zoning.descrizione_azzonamento } + [ "Deleghe Confermate" ]
      data = percentuali + [ deleghe_confermate_percentuale ]

      StatisticPrints::PieChart.draw(
        @pdf, at: [ @pdf.bounds.left, @pdf.cursor ], width: width, height: chart_height, labels: labels, data: data,
        colors: COMPRENSORI_COLORS, label_formatter: ->(value, _fraction) { [ StatisticPrints::NumberFormatting.percent(value) ] }
      )
    end

    def comprensorio_percentuale(row)
      row.deleghe_totale.to_i.zero? ? 0 : (row.totale.to_f / row.deleghe_totale * 100)
    end

    def column_width = (@pdf.bounds.width - column_gap) / 2
    def column_gap = COLUMN_GAP_MM * 72 / 25.4
    def section_gap = SECTION_GAP_MM * 72 / 25.4
    def chart_height = [ @pdf.cursor - 6, CHART_HEIGHT_MM * 72 / 25.4 ].min
  end
end
```

## Sezioni commentate

### Commento di classe

```ruby
# Pagina "Cessazioni": specchia app/views/statistic_spi/_cessazioni_card e
# _cessazioni_comprensori_card, con l'aggiunta di una torta Cessazioni/Deleghe
# Confermate per colonna (come ProvvisoriePage, non presente nel mockup ma
# richiesta da davo dopo). Totale e Comprensori affiancati in colonne per
# stare in una pagina sola.
class CessazioniPage
```

> **IT:** Struttura identica a `TipologieDelegaPage` (stesso fork `draw`, stesso `draw_two_columns`/`draw_totale_column`/`draw_comprensori_column` con `bounding_box` side-by-side sicuro — vedi `CodeGuide/StatisticSpiPrints/tipologie_delega_page.md`, non ripetuto qui). La riga più interessante del commento di classe è però storica, non strutturale: **"non presente nel mockup ma richiesta da davo dopo"**. Il grafico a torta Cessazioni/Deleghe Confermate non faceva parte del disegno originale della pagina — è stato aggiunto in un secondo momento, su richiesta esplicita, dopo che la tabella e le percentuali da sole erano già state considerate complete. È un promemoria per chi legge il codice: l'assenza di un elemento nel mockup iniziale (vedi la memoria di progetto sull'approccio ai mockup PDF) non significa che quell'elemento non finirà comunque nel report — le richieste di davo arrivano spesso in un secondo giro, dopo aver visto il risultato della prima versione.
>
> *EN: Structurally identical to `TipologieDelegaPage` (same `draw` fork, same `draw_two_columns`/`draw_totale_column`/`draw_comprensori_column` with the safe side-by-side `bounding_box` — see `CodeGuide/StatisticSpiPrints/tipologie_delega_page.md`, not repeated here). The most interesting line in the class comment, though, is historical, not structural: **"not present in the mockup but requested by davo afterward"**. The Cessazioni/Deleghe Confermate pie chart wasn't part of the page's original design — it was added later, on explicit request, after the table and percentages alone had already been considered complete. It's a reminder for anyone reading the code: the absence of an element from the initial mockup (see the project memory note on the PDF mockup approach) doesn't mean that element will never make it into the report — davo's requests often arrive in a second pass, after seeing the first version's result.*

### `ETICHETTE`, `COMPRENSORI_COLORS`

```ruby
COMPRENSORI_COLORS = %w[28B62C FF851B FF4136 158CBA 75CAEB].freeze
ETICHETTE = StatisticSpi::CessazioniBreakdown::ETICHETTE
```

> **IT:** `ETICHETTE` importata dal servizio, stesso principio di `TipologieDelegaPage::ETICHETTE`. `COMPRENSORI_COLORS` è invece una costante **locale alla pagina** (non importata da nessun servizio, i servizi non hanno alcuna nozione di colore): cinque colori fissi, uno per comprensorio, usati in `draw_comprensori_chart` per dare a ogni fetta della torta un colore stabile — stessa palette (verde/arancio/rosso/blu/celeste) che ricompare identica in `ProvvisoriePage::COMPRENSORI_COLORS`, non riusata tramite una costante condivisa ma duplicata: cinque colori bastano finché il numero di comprensori resta cinque, ed è lo stesso limite implicito già presente altrove nel dominio (es. `OCCORRENZE = (2..5)` in `MultipleDelegationsBreakdown`).
>
> *EN: `ETICHETTE` imported from the service, same principle as `TipologieDelegaPage::ETICHETTE`. `COMPRENSORI_COLORS`, by contrast, is a constant **local to the page** (not imported from any service — services have no notion of color): five fixed colors, one per comprensorio, used in `draw_comprensori_chart` to give each pie slice a stable color — the same palette (green/orange/red/blue/light blue) reappears identically in `ProvvisoriePage::COMPRENSORI_COLORS`, not shared via a common constant but duplicated: five colors are enough as long as the number of comprensori stays at five, the same implicit limit already present elsewhere in the domain (e.g. `OCCORRENZE = (2..5)` in `MultipleDelegationsBreakdown`).*

### `draw_totale_column`, `draw_totale_chart` — la torta "sottoinsieme"

```ruby
def draw_totale_column(result, x, top, width)
  @pdf.bounding_box([ x, top ], width: width, height: top) do
    CategoryTable.draw(@pdf, title: result.totale.zoning.descrizione_azzonamento, rows: [ result.totale ],
      etichette: ETICHETTE, total_label: "totale cessazioni")
    @pdf.move_down section_gap
    MotivoCessazionePercentageTable.draw(@pdf, row: result.totale, etichette: ETICHETTE)
    @pdf.move_down section_gap
    draw_totale_chart(result.totale, width)
  end
end

def draw_totale_chart(row, width)
  deleghe_confermate = row.deleghe_totale - row.totale
  StatisticPrints::PieChart.draw(
    @pdf, at: [ @pdf.bounds.left, @pdf.cursor ], width: width, height: chart_height,
    labels: [ "Cessazioni", "Deleghe Confermate" ], data: [ row.totale, deleghe_confermate ]
  )
end
```

> **IT:** `total_label: "totale cessazioni"` (passato a `CategoryTable`, che di default userebbe un'etichetta generica "totale") è una piccola ma deliberata precisazione: senza di essa, la riga di totale della tabella non distinguerebbe "totale cessazioni" da un ipotetico "totale deleghe", ambiguità che qui conta perché la pagina mostra entrambi i numeri (vedi `deleghe_totale` nel `Row`). `MotivoCessazionePercentageTable` (non `CategoryPercentageTable`, usata invece nella colonna Comprensori) è una tabella dedicata **solo** alla colonna Totale: prende un singolo `row:` (non un array di `rows:`), coerente col fatto che qui c'è una sola riga di percentuali da mostrare, non una per comprensorio. `draw_totale_chart` è il punto in cui il documento README (`CodeGuide/StatisticSpi/README.md`, sezione "perché CessazioniBreakdown/ProvvisorieBreakdown calcolano le percentuali diversamente") diventa visibile sulla pagina: `deleghe_confermate = row.deleghe_totale - row.totale` è calcolato **qui, nella pagina**, non nel servizio — `CessazioniBreakdown::Row` non ha un campo `deleghe_confermate`, solo `deleghe_totale` (il denominatore) e `totale` (le cessazioni, il numeratore). La torta a due fette (Cessazioni rosso/arancio di default, Deleghe Confermate l'altro colore di `StatisticPrints::PieChart::COLORS`) rende visivamente il fatto che le cessazioni sono un **sottoinsieme minoritario** delle deleghe del periodo, lo stesso concetto che nella tabella si traduce in "le percentuali non sommano al 100%".
>
> *EN: `total_label: "totale cessazioni"` (passed to `CategoryTable`, which would otherwise default to a generic "totale" label) is a small but deliberate clarification: without it, the table's total row wouldn't distinguish "totale cessazioni" from a hypothetical "totale deleghe" — an ambiguity that matters here because the page shows both numbers (see `deleghe_totale` on the `Row`). `MotivoCessazionePercentageTable` (not `CategoryPercentageTable`, used instead in the Comprensori column) is a table dedicated **only** to the Totale column: it takes a single `row:` (not an array of `rows:`), consistent with there being just one row of percentages to show here, not one per comprensorio. `draw_totale_chart` is where the README's point (`CodeGuide/StatisticSpi/README.md`, the "why CessazioniBreakdown/ProvvisorieBreakdown compute percentages differently" section) becomes visible on the page: `deleghe_confermate = row.deleghe_totale - row.totale` is computed **here, in the page**, not in the service — `CessazioniBreakdown::Row` has no `deleghe_confermate` field, only `deleghe_totale` (the denominator) and `totale` (the cessazioni, the numerator). The two-slice pie (Cessazioni in the default red/orange, Deleghe Confermate in the other color from `StatisticPrints::PieChart::COLORS`) visually conveys that cessazioni are a **minority subset** of the period's delegations — the same concept that, in the table, translates to "the percentages don't add up to 100%".*

### `draw_comprensori_chart`, `comprensorio_percentuale` — la torta "percentuali grezze"

```ruby
def draw_comprensori_chart(comprensori, width)
  percentuali = comprensori.map { |row| comprensorio_percentuale(row) }
  deleghe_confermate_percentuale = 100.0 - percentuali.sum
  labels = comprensori.map { |row| row.zoning.descrizione_azzonamento } + [ "Deleghe Confermate" ]
  data = percentuali + [ deleghe_confermate_percentuale ]

  StatisticPrints::PieChart.draw(
    @pdf, at: [ @pdf.bounds.left, @pdf.cursor ], width: width, height: chart_height, labels: labels, data: data,
    colors: COMPRENSORI_COLORS, label_formatter: ->(value, _fraction) { [ StatisticPrints::NumberFormatting.percent(value) ] }
  )
end

def comprensorio_percentuale(row)
  row.deleghe_totale.to_i.zero? ? 0 : (row.totale.to_f / row.deleghe_totale * 100)
end
```

> **IT:** Questa è la torta più insidiosa della cartella da leggere superficialmente, perché **`data` non sono conteggi, sono già percentuali** (0-100), una per comprensorio, più una fetta residua "Deleghe Confermate" che porta la somma esattamente a 100. `StatisticPrints::PieChart` di default (`default_label`, vedi `app/services/statistic_prints/pie_chart.rb`) mostra `[NumberFormatting.count(value), "(#{NumberFormatting.percent(fraction * 100)})"]` — pensato per un grafico le cui fette sono **conteggi**, dove `fraction` (calcolata internamente come `value / data.sum`) è la vera percentuale della fetta. Se questa pagina passasse `data` (già percentuali) al `default_label`, il risultato sarebbe doppiamente sbagliato: primo numero mostrato come "conteggio" (es. "23" invece di "23%"), secondo come una percentuale-della-percentuale ricalcolata su un totale che ora è sempre ~100 invece che sul totale deleghe reale. Il `label_formatter:` esplicito (`->(value, _fraction) { [StatisticPrints::NumberFormatting.percent(value)] }`) bypassa interamente questo calcolo: ignora `fraction` e formatta direttamente `value` come percentuale — la "modalità percentuali grezze" (raw percentages) già usata per i grafici a torta equivalenti a schermo nella pagina Statistiche SPI (vedi la memoria di progetto sulle Statistiche SPI). `comprensorio_percentuale` usa lo stesso schema di guardia sullo zero (`.zero? ? 0 : ...`) visto nei servizi `StatisticSpi::*`, ma restituisce `0` invece di `nil` — coerente con il fatto che un grafico a torta, a differenza di una cella di tabella, non può rappresentare "percentuale non calcolabile" e deve comunque disegnare una fetta (di ampiezza zero) per quel comprensorio.
>
> *EN: This is the trickiest pie chart in the folder to read at a glance, because **`data` isn't counts, it's already percentages** (0-100), one per comprensorio, plus a residual "Deleghe Confermate" slice that brings the sum to exactly 100. `StatisticPrints::PieChart`'s default (`default_label`, see `app/services/statistic_prints/pie_chart.rb`) shows `[NumberFormatting.count(value), "(#{NumberFormatting.percent(fraction * 100)})"]` — designed for a chart whose slices are **counts**, where `fraction` (computed internally as `value / data.sum`) is the slice's true percentage. If this page passed `data` (already percentages) to `default_label`, the result would be doubly wrong: the first number shown as a "count" (e.g. "23" instead of "23%"), the second as a percentage-of-a-percentage recomputed against a total that's now always ~100 instead of the real delegation total. The explicit `label_formatter:` (`->(value, _fraction) { [StatisticPrints::NumberFormatting.percent(value)] }`) bypasses this computation entirely: it ignores `fraction` and formats `value` directly as a percentage — the "raw percentages" mode already used for the equivalent on-screen pie charts in the Statistiche SPI page (see the project's Statistiche SPI memory note). `comprensorio_percentuale` uses the same zero-guard pattern (`.zero? ? 0 : ...`) seen in the `StatisticSpi::*` services, but returns `0` instead of `nil` — consistent with the fact that a pie chart, unlike a table cell, can't represent "percentage not computable" and still has to draw a (zero-width) slice for that comprensorio.*

### `column_width`, `column_gap`, `section_gap`, `chart_height` *(privati)*

> **IT:** Identici, riga per riga, agli omonimi di `TipologieDelegaPage` — vedi `CodeGuide/StatisticSpiPrints/tipologie_delega_page.md`. Solo `CHART_HEIGHT_MM` cambia valore (60 invece di 55), perché la colonna Totale qui contiene tre elementi impilati (tabella + tabella percentuali + torta) invece di due (tabella + grafico), lasciando meno margine per il grafico stesso.
>
> *EN: Identical, line for line, to the same-named methods in `TipologieDelegaPage` — see `CodeGuide/StatisticSpiPrints/tipologie_delega_page.md`. Only `CHART_HEIGHT_MM` changes value (60 instead of 55), because the Totale column here stacks three elements (table + percentage table + pie) instead of two (table + chart), leaving less headroom for the chart itself.*
