# `StatisticPrints::RegionalPage`

**File:** `app/services/statistic_prints/regional_page.rb`

## Codice completo

```ruby
module StatisticPrints
  class RegionalPage
    MAX_CHART_HEIGHT_MM = 90
    SECTION_GAP_MM = 10

    def self.draw(...) = new(...).draw

    def initialize(pdf, form:, comparison_service: Statistics::TotalMembersComparison)
      @pdf = pdf
      @form = form
      @comparison_service = comparison_service
    end

    def draw
      result = @comparison_service.call(zoning: @form.zoning, anno: @form.anno, mese: @form.mese)
      @pdf.fill_color "000000"
      return draw_error(result.error) unless result.success?

      draw_heading(result)
      draw_regional_table(result)
      if result.comprensori.present?
        draw_comprensori(result)
      else
        draw_single_chart(result)
      end
    end

    private

    def draw_error(message)
      @pdf.font("AsapCondensed", size: 14) { @pdf.text message, color: "DC3545" }
    end

    def draw_heading(result)
      @pdf.font("AsapCondensed", style: :bold, size: 16) { @pdf.text heading_title(result.zoning) }
      @pdf.move_down 2
      @pdf.font("AsapCondensed", size: 10) { @pdf.text "Tesseramento #{result.mese} #{result.anno}", color: "666666" }
      @pdf.move_down 8
      @pdf.stroke_color "CCCCCC"
      @pdf.stroke_horizontal_rule
      @pdf.move_down section_gap
    end

    def heading_title(zoning)
      return "CGIL Totale Iscritti – Regionale e Comprensori" if zoning.regionale?

      "CGIL Totale Iscritti – Comprensorio di #{zoning.descrizione_azzonamento}"
    end

    def draw_regional_table(result)
      ComparisonTable.draw(
        @pdf, title: result.zoning.descrizione_azzonamento, mese: result.mese, anno: result.anno,
        anno_precedente: result.anno_precedente, rows: [ row_for(result.zoning, result) ]
      )
    end

    def row_for(zoning, row)
      { label: zoning.descrizione_azzonamento, count_precedente: row.count_precedente, count_anno: row.count_anno,
        diff: row.diff, diff_percent: row.diff_percent }
    end

    def draw_comprensori(result)
      @pdf.move_down 12
      ComparisonTable.draw(
        @pdf, title: "Comprensori", mese: result.mese, anno: result.anno, anno_precedente: result.anno_precedente,
        rows: result.comprensori.map { |c| row_for(c.zoning, c) }
      )
      @pdf.move_down section_gap
      draw_chart(result, result.comprensori.map { |c| [ c.zoning, c ] })
    end

    def draw_single_chart(result)
      @pdf.move_down section_gap
      draw_chart(result, [ [ result.zoning, result ] ])
    end

    def draw_chart(result, entries)
      BarChart.draw(
        @pdf, at: [ @pdf.bounds.left, @pdf.cursor ], width: @pdf.bounds.width, height: chart_height,
        labels: entries.map { |zoning, _| zoning.descrizione_azzonamento },
        previous_data: entries.map { |_, row| row.count_precedente }, current_data: entries.map { |_, row| row.count_anno },
        percentages: entries.map { |_, row| row.diff_percent },
        previous_label: "#{result.mese} #{result.anno_precedente}", current_label: "#{result.mese} #{result.anno}"
      )
    end

    def chart_height
      [ @pdf.cursor - 6, MAX_CHART_HEIGHT_MM * 72 / 25.4 ].min
    end

    def section_gap = SECTION_GAP_MM * 72 / 25.4
  end
end
```

## Sezioni commentate

### Costanti (`MAX_CHART_HEIGHT_MM`, `SECTION_GAP_MM`)

```ruby
MAX_CHART_HEIGHT_MM = 90
SECTION_GAP_MM = 10
```

> **IT:** Ogni pagina di `StatisticPrints` definisce le proprie costanti mm locali invece di condividerle da un'unica classe base — non esiste una `BasePage` in questa cartella. È una scelta deliberata: ogni pagina ha un layout diverso (una tabella e un grafico qui, due colonne altrove) e i valori mm sono stati calibrati pagina per pagina guardando il PDF renderizzato, non derivati da una formula comune. La conversione mm→pt (`* 72 / 25.4`) è anch'essa reimplementata in ciascun file, mai estratta in un helper condiviso — coerente con il resto della cartella `StatisticPrints`.
>
> *EN: Every page in `StatisticPrints` defines its own local mm constants instead of sharing them from a common base class — there is no `BasePage` in this folder. This is deliberate: every page has a different layout (one table and one chart here, two columns elsewhere), and the mm values were each hand-tuned by looking at the rendered PDF, not derived from a shared formula. The mm→pt conversion (`* 72 / 25.4`) is likewise reimplemented in every file, never extracted into a shared helper — consistent with the rest of the `StatisticPrints` folder.*

### `self.draw` / `initialize`

```ruby
def self.draw(...) = new(...).draw

def initialize(pdf, form:, comparison_service: Statistics::TotalMembersComparison)
  @pdf = pdf
  @form = form
  @comparison_service = comparison_service
end
```

> **IT:** Tutte e sette le pagine di questo batch condividono la stessa firma: `draw(pdf, form:, comparison_service: ...)`, chiamata da `ReportPdf#draw_content_pages` come `page_class.draw(pdf, form: form, comparison_service: @comparison_service)`. Il `pdf` è passato come primo argomento posizionale (non keyword) perché è l'oggetto Prawn su cui *disegnare*, non un dato del dominio; `form`/`comparison_service` sono keyword perché sono l'input logico della pagina. L'iniezione di `comparison_service` (con un default) è quello che rende testabile ogni pagina senza dover popolare `Import` reali nei test — si passa un doppio che risponde a `.call` con un `Result` fittizio.
>
> *EN: All seven pages in this batch share the exact same signature: `draw(pdf, form:, comparison_service: ...)`, called from `ReportPdf#draw_content_pages` as `page_class.draw(pdf, form: form, comparison_service: @comparison_service)`. `pdf` is passed as the first positional argument (not a keyword) because it's the Prawn object being *drawn on*, not domain data; `form`/`comparison_service` are keywords because they're the page's logical input. Injecting `comparison_service` (with a default) is what makes each page testable without seeding real `Import` rows — a test double that responds to `.call` with a fake `Result` can be passed instead.*

### `draw`

```ruby
def draw
  result = @comparison_service.call(zoning: @form.zoning, anno: @form.anno, mese: @form.mese)
  @pdf.fill_color "000000"
  return draw_error(result.error) unless result.success?

  draw_heading(result)
  draw_regional_table(result)
  if result.comprensori.present?
    draw_comprensori(result)
  else
    draw_single_chart(result)
  end
end
```

> **IT:** `@pdf.fill_color "000000"` viene chiamato **prima** di qualsiasi contenuto, subito dopo aver calcolato `result` — mai omesso, in nessuna delle sette pagine di questo batch. `fill_color` in Prawn è uno stato globale del documento, non scoped al blocco o alla pagina corrente: senza questo reset, il testo di questa pagina erediterebbe il colore impostato dall'ultima cosa disegnata sulla pagina precedente (es. testo bianco su banner scuro nella `ZoningDividerPage` o nella `CoverPage`), risultando invisibile su sfondo bianco. Questa stessa pagina riusa il servizio `Statistics::TotalMembersComparison` — lo stesso identico servizio, con lo stesso `Result`, documentato in `CodeGuide/Statistics/total_members_comparison.md` — per ottenere i dati: la pagina PDF non fa **nessun** calcolo proprio sui numeri, solo disegno. Il ramo `if result.comprensori.present?` è la stessa logica di `TotalMembersComparison#comprensori`: se l'azzonamento scelto è regionale, `comprensori` contiene una riga per provincia e la pagina disegna la tabella comprensori + un grafico multi-barra; se è già un azzonamento provinciale, `comprensori` è `[]` e la pagina disegna solo il grafico a una singola barra.
>
> *EN: `@pdf.fill_color "000000"` is called **before** any content, right after computing `result` — never omitted, in any of the seven pages in this batch. `fill_color` in Prawn is document-wide state, not scoped to the current block or page: without this reset, this page's text would inherit whatever color was last set by the previous page's drawing (e.g. white text on a dark banner in `ZoningDividerPage` or `CoverPage`), rendering invisibly on a white background. This page reuses the `Statistics::TotalMembersComparison` service — the exact same service, with the exact same `Result`, documented in `CodeGuide/Statistics/total_members_comparison.md` — to get its data: the PDF page does **no** number-crunching of its own, only drawing. The `if result.comprensori.present?` branch mirrors `TotalMembersComparison#comprensori`'s own logic: if the chosen zoning is regional, `comprensori` holds one row per province and the page draws the comprensori table plus a multi-bar chart; if it's already a provincial zoning, `comprensori` is `[]` and the page draws just the single-bar chart.*

### `draw_error` *(privato)*

```ruby
def draw_error(message)
  @pdf.font("AsapCondensed", size: 14) { @pdf.text message, color: "DC3545" }
end
```

> **IT:** `RegionalPage` è l'unica pagina del batch il cui `draw` interrompe l'esecuzione **prima** di disegnare anche solo l'intestazione quando `result.error` è presente (`return draw_error(...) unless result.success?` viene prima di `draw_heading`). Le altre sei pagine disegnano sempre l'intestazione (`draw_heading`) e solo *dopo* controllano l'errore — perché essendo `RegionalPage` la prima pagina di contenuto dopo il divisorio di azzonamento, se manca il dato per l'intero periodo non ha senso nemmeno intestare la pagina: l'intero fascicolo per quell'azzonamento sarà comunque vuoto di dati (`missing_data_result` di `TotalMembersComparison` produce lo stesso identico errore per ogni sezione). `DC3545` è il rosso standard di Bootstrap `danger`, usato coerentemente per gli errori in tutto il batch.
>
> *EN: `RegionalPage` is the only page in the batch whose `draw` bails out **before** drawing even the heading when `result.error` is present (`return draw_error(...) unless result.success?` comes before `draw_heading`). The other six pages always draw the heading (`draw_heading`) and only check the error *afterward* — because since `RegionalPage` is the first content page after the zoning divider, if data is missing for the whole period there's no point titling the page at all: the entire booklet for that zoning will be data-empty regardless (`TotalMembersComparison`'s `missing_data_result` produces the exact same error for every section). `DC3545` is Bootstrap's standard `danger` red, used consistently for errors across the whole batch.*

### `draw_heading` / `heading_title` *(privati)*

```ruby
def draw_heading(result)
  @pdf.font("AsapCondensed", style: :bold, size: 16) { @pdf.text heading_title(result.zoning) }
  @pdf.move_down 2
  @pdf.font("AsapCondensed", size: 10) { @pdf.text "Tesseramento #{result.mese} #{result.anno}", color: "666666" }
  @pdf.move_down 8
  @pdf.stroke_color "CCCCCC"
  @pdf.stroke_horizontal_rule
  @pdf.move_down section_gap
end

def heading_title(zoning)
  return "CGIL Totale Iscritti – Regionale e Comprensori" if zoning.regionale?

  "CGIL Totale Iscritti – Comprensorio di #{zoning.descrizione_azzonamento}"
end
```

> **IT:** Titolo (grassetto 16pt) + sottotitolo periodo (10pt grigio `666666`) + riga divisoria grigio chiaro (`CCCCCC`) + spaziatura: questo identico blocco a 4 elementi si ripete, con solo il titolo diverso, in tutte le altre sei pagine (`draw_heading` di `CategoriesPage`, `EmploymentStatusPage`, ecc. — nessuna di esse ripete però il sottotitolo "Tesseramento", che è specifico solo di questa pagina). `heading_title` è l'unico punto di tutto il batch dove una pagina cambia il proprio titolo in base a `zoning.regionale?` — le altre sei pagine hanno sempre lo stesso titolo (con solo `descrizione_azzonamento` interpolato), perché il loro contenuto interno (tabella/e + grafico/i) è già sufficiente a rappresentare sia il caso regionale sia quello comprensoriale senza bisogno di un titolo diverso.
>
> *EN: Title (bold 16pt) + period subtitle (10pt grey `666666`) + light-grey divider rule (`CCCCCC`) + spacing: this exact 4-element block repeats, with only the title differing, across all six other pages (`draw_heading` in `CategoriesPage`, `EmploymentStatusPage`, etc. — though none of them repeat the "Tesseramento" subtitle, which is specific to this page). `heading_title` is the only place in the whole batch where a page changes its own title based on `zoning.regionale?` — the other six pages always use the same title (with only `descrizione_azzonamento` interpolated), because their inner content (table(s) + chart(s)) already represents both the regional and the comprensorio case without needing a different heading.*

### `draw_regional_table` / `row_for` *(privati)*

```ruby
def draw_regional_table(result)
  ComparisonTable.draw(
    @pdf, title: result.zoning.descrizione_azzonamento, mese: result.mese, anno: result.anno,
    anno_precedente: result.anno_precedente, rows: [ row_for(result.zoning, result) ]
  )
end

def row_for(zoning, row)
  { label: zoning.descrizione_azzonamento, count_precedente: row.count_precedente, count_anno: row.count_anno,
    diff: row.diff, diff_percent: row.diff_percent }
end
```

> **IT:** `ComparisonTable` (documentata separatamente in `CodeGuide/StatisticPrints/comparison_table.md`) è il componente tabellare condiviso per tutte le sezioni "confronto anno su anno" del batch — qui riceve un array con una **sola** riga, perché a livello di azzonamento scelto esiste un solo totale da confrontare. `row_for` traduce lo `Struct` `Row` di `TotalMembersComparison` (`zoning:`, `count_anno:`, ecc. — vedi `CodeGuide/Statistics/total_members_comparison.md`) in un semplice `Hash` con chiavi `label`/`count_precedente`/`count_anno`/`diff`/`diff_percent`: è il "contratto" che tutte le tabelle/grafici di confronto del batch si aspettano, indipendentemente dal servizio `*Breakdown` di origine. Questo disaccoppiamento (Struct del servizio → Hash generico) è ciò che permette a `ComparisonTable`/`BarChart` di essere completamente ignari di quale sezione statistica li stia chiamando.
>
> *EN: `ComparisonTable` (documented separately in `CodeGuide/StatisticPrints/comparison_table.md`) is the shared table component for every "year-over-year comparison" section in the batch — here it receives an array with just **one** row, because at the level of the chosen zoning there's only one total to compare. `row_for` translates `TotalMembersComparison`'s `Row` struct (`zoning:`, `count_anno:`, etc. — see `CodeGuide/Statistics/total_members_comparison.md`) into a plain `Hash` with `label`/`count_precedente`/`count_anno`/`diff`/`diff_percent` keys: this is the "contract" every comparison table/chart in the batch expects, regardless of which `*Breakdown` service the data originated from. This decoupling (service Struct → generic Hash) is what lets `ComparisonTable`/`BarChart` stay completely unaware of which statistics section is calling them.*

### `draw_comprensori` / `draw_single_chart` *(privati)*

```ruby
def draw_comprensori(result)
  @pdf.move_down 12
  ComparisonTable.draw(
    @pdf, title: "Comprensori", mese: result.mese, anno: result.anno, anno_precedente: result.anno_precedente,
    rows: result.comprensori.map { |c| row_for(c.zoning, c) }
  )
  @pdf.move_down section_gap
  draw_chart(result, result.comprensori.map { |c| [ c.zoning, c ] })
end

def draw_single_chart(result)
  @pdf.move_down section_gap
  draw_chart(result, [ [ result.zoning, result ] ])
end
```

> **IT:** I due rami del `if` in `draw` convergono sullo stesso `draw_chart`, ma costruiscono `entries` in modo diverso: `draw_comprensori` passa una coppia `[zoning, row]` per ciascun comprensorio (grafico multi-barra, un gruppo di barre per provincia), `draw_single_chart` passa un array con una singola coppia `[result.zoning, result]` — riusando `result` stesso come "riga", perché `Result` ha già tutti i campi (`count_anno`, `count_precedente`, `diff`, `diff_percent`) che una `Row` avrebbe. Questo è possibile solo perché `Statistics::TotalMembersComparison::Result` e `Row` condividono gli stessi nomi di campo per i conteggi — non è un caso, è il motivo per cui `row_for` funziona indifferentemente su un `Row` o (qui) su un `Result`.
>
> *EN: The two branches of the `if` in `draw` converge on the same `draw_chart`, but build `entries` differently: `draw_comprensori` passes one `[zoning, row]` pair per comprensorio (a multi-bar chart, one bar group per province), `draw_single_chart` passes a single-pair array `[result.zoning, result]` — reusing `result` itself as the "row", since `Result` already carries every field (`count_anno`, `count_precedente`, `diff`, `diff_percent`) a `Row` would. This only works because `Statistics::TotalMembersComparison::Result` and `Row` share the same count field names — that's not a coincidence, it's exactly why `row_for` works interchangeably on a `Row` or (here) on a `Result`.*

### `draw_chart` *(privato)*

```ruby
def draw_chart(result, entries)
  BarChart.draw(
    @pdf, at: [ @pdf.bounds.left, @pdf.cursor ], width: @pdf.bounds.width, height: chart_height,
    labels: entries.map { |zoning, _| zoning.descrizione_azzonamento },
    previous_data: entries.map { |_, row| row.count_precedente }, current_data: entries.map { |_, row| row.count_anno },
    percentages: entries.map { |_, row| row.diff_percent },
    previous_label: "#{result.mese} #{result.anno_precedente}", current_label: "#{result.mese} #{result.anno}"
  )
end
```

> **IT:** `BarChart` (documentato in `CodeGuide/StatisticPrints/bar_chart.md`) è la controparte statica, disegnata con Prawn, del controller Stimulus `comparison-chart` usato a schermo per le stesse sezioni "confronto anno su anno" (vedi `CodeGuide/Statistics/README.md`): stesse due serie (anno precedente/anno corrente), stessa percentuale di differenza mostrata sopra la barra corrente. `at: [@pdf.bounds.left, @pdf.cursor]` disegna a **larghezza intera pagina** partendo dalla posizione corrente del cursore: non c'è nessun `bounding_box` qui, il grafico è l'ultimo elemento della pagina, quindi non serve calcolare né propagare una posizione finale del cursore per contenuto successivo.
>
> *EN: `BarChart` (documented in `CodeGuide/StatisticPrints/bar_chart.md`) is the static, Prawn-drawn counterpart of the `comparison-chart` Stimulus controller used on screen for the same "year-over-year comparison" sections (see `CodeGuide/Statistics/README.md`): same two series (previous year/current year), same difference percentage drawn above the current-year bar. `at: [@pdf.bounds.left, @pdf.cursor]` draws at **full page width** starting from the cursor's current position: there's no `bounding_box` here, the chart is the last element on the page, so there's no need to compute or propagate a final cursor position for subsequent content.*

### `chart_height`, `section_gap` *(privati)*

```ruby
def chart_height
  [ @pdf.cursor - 6, MAX_CHART_HEIGHT_MM * 72 / 25.4 ].min
end

def section_gap = SECTION_GAP_MM * 72 / 25.4
```

> **IT:** `chart_height` è la "stretchy height" del grafico: `@pdf.cursor` restituisce lo spazio verticale rimasto fino al fondo del bounding box corrente (la pagina), quindi `@pdf.cursor - 6` è "tutto lo spazio restante meno un piccolo margine di sicurezza". Il `.min` con `MAX_CHART_HEIGHT_MM` impedisce al grafico di diventare eccessivamente alto quando la tabella sopra è corta (es. un solo azzonamento provinciale senza comprensori, dove il grafico occuperebbe altrimenti quasi tutta la pagina). Poiché questa lettura di `@pdf.cursor` avviene **subito prima** di disegnare il grafico — senza altre chiamate Prawn nel mezzo che potrebbero spostarlo — è sicura: non è lo stesso schema fragile della "stretchy `bounding_box` senza `height:`" descritto nelle note di progetto, perché qui non viene aperto nessun `bounding_box`, solo letto il cursore.
>
> *EN: `chart_height` is the chart's "stretchy height": `@pdf.cursor` returns the vertical space remaining down to the bottom of the current bounding box (the page), so `@pdf.cursor - 6` is "all remaining space minus a small safety margin". The `.min` against `MAX_CHART_HEIGHT_MM` stops the chart from growing excessively tall when the table above it is short (e.g. a single provincial zoning with no comprensori, where the chart would otherwise take up nearly the whole page). Because this read of `@pdf.cursor` happens **immediately before** drawing the chart — with no other Prawn calls in between that could move it — it's safe: it isn't the same fragile pattern as a "stretchy `bounding_box` with no `height:`" from the project notes, because no `bounding_box` is opened here at all, only the cursor is read.*
