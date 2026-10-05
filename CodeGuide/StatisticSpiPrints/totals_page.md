# `StatisticSpiPrints::TotalsPage`

**File:** `app/services/statistic_spi_prints/totals_page.rb`

## Codice completo

```ruby
module StatisticSpiPrints
  # Pagina "Totali Iscritti-Deleghe": specchia app/views/statistic_spi/_totale_card
  # e _comprensori_section, ma con le due metriche affiancate in colonne (anziche'
  # impilate come a schermo) per stare in una singola pagina landscape.
  class TotalsPage
    include StatisticPrints::PageLayout

    MAX_CHART_HEIGHT_MM = 75
    SECTION_GAP_MM = 8
    COLUMN_GAP_MM = 10
    METRIC_COLOR = "FF4136"

    def self.draw(...) = new(...).draw

    def initialize(pdf, form:, comparison_service: StatisticSpi::TotalMembersComparison)
      @pdf = pdf
      @form = form
      @comparison_service = comparison_service
    end

    def draw
      result = @comparison_service.call(zoning: @form.zoning, anno: @form.anno, mese: @form.mese)
      @pdf.fill_color "000000"
      draw_heading(result)
      return draw_message(result.error, "DC3545") unless result.success?

      draw_columns(result)
    end

    private

    def draw_heading(result) = draw_page_heading(heading_title(result.zoning), subtitle: period_subtitle)

    def heading_title(zoning)
      return "CGIL Totale Iscritti e Deleghe SPI – Regionale e Comprensori" if zoning.regionale?

      "CGIL Totale Iscritti e Deleghe SPI – Comprensorio di #{zoning.descrizione_azzonamento}"
    end

    def draw_columns(result)
      top = @pdf.cursor
      left = @pdf.bounds.left

      iscritti_bottom = draw_column(left, top, "Iscritti", result, :iscritti_totale, :iscritti_comprensori, "iscritti")
      deleghe_bottom = draw_column(left + column_width + column_gap, top, "Deleghe", result, :deleghe_totale,
        :deleghe_comprensori, "deleghe")

      draw_chart(result, [ iscritti_bottom, deleghe_bottom ].min)
    end

    def draw_column(x, top, title, result, totale_key, comprensori_key, metric_label)
      cursor_after = nil
      @pdf.bounding_box([ x, top ], width: column_width, height: top) do
        draw_metric_title(title)
        totale_row = result.public_send(totale_key)
        StatisticPrints::ComparisonTable.draw(
          @pdf, title: totale_row.zoning.descrizione_azzonamento, mese: result.mese, anno: result.anno,
          anno_precedente: result.anno_precedente, rows: [ row_for(totale_row) ], metric_label: metric_label
        )
        comprensori_rows = result.public_send(comprensori_key)
        draw_comprensori_table(comprensori_rows, result, metric_label) if comprensori_rows.present?
        cursor_after = @pdf.cursor
      end
      cursor_after
    end

    def draw_comprensori_table(rows, result, metric_label)
      @pdf.move_down 8
      StatisticPrints::ComparisonTable.draw(
        @pdf, title: "Comprensori", mese: result.mese, anno: result.anno, anno_precedente: result.anno_precedente,
        rows: rows.map { |row| row_for(row) }, metric_label: metric_label
      )
    end

    def draw_metric_title(title)
      @pdf.font("AsapCondensed", style: :bold, size: 13) { @pdf.text title, color: METRIC_COLOR }
      @pdf.move_down 4
    end

    def row_for(row)
      { label: row.zoning.descrizione_azzonamento, count_precedente: row.count_precedente, count_anno: row.count_anno,
        diff: row.diff, diff_percent: row.diff_percent }
    end

    def draw_chart(result, columns_bottom)
      chart_top = columns_bottom - section_gap
      height = [ chart_top - 6, mm(MAX_CHART_HEIGHT_MM) ].min
      entries = chart_entries(result)

      BarChart.draw(
        @pdf, at: [ @pdf.bounds.left, chart_top ], width: @pdf.bounds.width, height: height,
        labels: entries.map { |iscritti, _| iscritti.zoning.descrizione_azzonamento },
        iscritti_previous: entries.map { |iscritti, _| iscritti.count_precedente },
        iscritti_current: entries.map { |iscritti, _| iscritti.count_anno },
        deleghe_previous: entries.map { |_, deleghe| deleghe.count_precedente },
        deleghe_current: entries.map { |_, deleghe| deleghe.count_anno },
        iscritti_percentages: entries.map { |iscritti, _| iscritti.diff_percent },
        deleghe_percentages: entries.map { |_, deleghe| deleghe.diff_percent },
        previous_label: "#{result.mese} #{result.anno_precedente}", current_label: "#{result.mese} #{result.anno}"
      )
    end

    def chart_entries(result)
      return result.iscritti_comprensori.zip(result.deleghe_comprensori) if result.iscritti_comprensori.present?

      [ [ result.iscritti_totale, result.deleghe_totale ] ]
    end

    def column_width = (@pdf.bounds.width - column_gap) / 2
  end
end
```

## Sezioni commentate

### Commento di classe

```ruby
# Pagina "Totali Iscritti-Deleghe": specchia app/views/statistic_spi/_totale_card
# e _comprensori_section, ma con le due metriche affiancate in colonne (anziche'
# impilate come a schermo) per stare in una singola pagina landscape.
class TotalsPage
```

> **IT:** È la prima delle sei pagine di contenuto elencate in `CONTENT_PAGES` di `ReportPdf` (vedi `app/services/statistic_spi_prints/report_pdf.rb`), quindi vale la pena leggerla per prima: stabilisce il pattern comune a tutte — intestazione con `fill_color` esplicito, titolo che si ramifica su `zoning.regionale?`, corpo che consuma un `Result` prodotto da un servizio `StatisticSpi::*` con lo stesso `zoning:`/`anno:`/`mese:` del form, e nessuna conoscenza diretta di `ImportSpi` o SQL — tutta la logica di dominio resta nel servizio, la pagina si occupa solo di layout Prawn. Rispetto a schermo (`_totale_card` + `_comprensori_section`, impilati verticalmente in una pagina web che scrolla), qui le due metriche **iscritti** e **deleghe** sono affiancate in due colonne, perché una pagina PDF landscape ha una larghezza fissa da sfruttare e nessuno scroll: è la stessa trasformazione "verticale a schermo → orizzontale su carta" documentata per il report non-SPI in `CodeGuide/StatisticPrints/` (se presente), applicata qui al caso con due metriche parallele invece di una sola.
>
> *EN: This is the first of the six content pages listed in `ReportPdf`'s `CONTENT_PAGES` (see `app/services/statistic_spi_prints/report_pdf.rb`), so it's worth reading first: it establishes the pattern shared by all six — a heading with an explicit `fill_color` reset, a title branching on `zoning.regionale?`, a body that consumes a `Result` produced by a `StatisticSpi::*` service with the same `zoning:`/`anno:`/`mese:` as the form, and no direct knowledge of `ImportSpi` or SQL — all domain logic stays in the service, the page only handles Prawn layout. Compared to the screen (`_totale_card` + `_comprensori_section`, stacked vertically in a scrolling web page), the two metrics **iscritti** and **deleghe** here sit side by side in two columns, because a landscape PDF page has a fixed width to make use of and no scrolling: the same "vertical on screen → horizontal on paper" transformation documented for the non-SPI report in `CodeGuide/StatisticPrints/` (if present), applied here to the case of two parallel metrics instead of one.*

### Costanti (`MAX_CHART_HEIGHT_MM`, `SECTION_GAP_MM`, `COLUMN_GAP_MM`, `METRIC_COLOR`)

```ruby
MAX_CHART_HEIGHT_MM = 75
SECTION_GAP_MM = 8
COLUMN_GAP_MM = 10
METRIC_COLOR = "FF4136"
```

> **IT:** Tutte le misure di layout sono costanti in millimetri, convertite in punti PDF (`* 72 / 25.4`, lo stesso calcolo inlineato in `ReportPdf#mm_to_pt`, qui ripetuto localmente in `column_gap`/`section_gap` invece di essere richiamato da lì — nessuna delle sei pagine importa `ReportPdf::mm_to_pt`, ognuna definisce la propria conversione privata; piccola duplicazione accettata per non introdurre un accoppiamento tra le pagine di contenuto e la classe orchestratrice). `METRIC_COLOR` ("FF4136", un rosso) colora il titolo di ogni colonna (`draw_metric_title`) — lo stesso rosso usato altrove nel report come colore "di richiamo" per numeri negativi/import critici (vedi `CodeGuide/StatisticSpi/...` per il resto della palette, e la memoria di progetto sulla palette icone).
>
> *EN: All layout measurements are constants in millimeters, converted to PDF points (`* 72 / 25.4`, the same computation inlined in `ReportPdf#mm_to_pt`, repeated here locally in `column_gap`/`section_gap` instead of being called from there — none of the six pages import `ReportPdf::mm_to_pt`, each defines its own private conversion; a small accepted duplication to avoid coupling the content pages to the orchestrator class). `METRIC_COLOR` ("FF4136", a red) colors each column's title (`draw_metric_title`) — the same red used elsewhere in the report as an "attention" color for negative numbers/critical imports (see `CodeGuide/StatisticSpi/...` for the rest of the palette, and the project's icon-palette memory note).*

### `initialize` — `comparison_service:` iniettabile

```ruby
def initialize(pdf, form:, comparison_service: StatisticSpi::TotalMembersComparison)
  @pdf = pdf
  @form = form
  @comparison_service = comparison_service
end
```

> **IT:** `comparison_service:` ha un default (`StatisticSpi::TotalMembersComparison`) ma può essere sostituito — utile nei test per iniettare un fake senza toccare il database. Da notare però che `ReportPdf#draw_content_pages` chiama sempre `page_class.draw(pdf, form: form)`, **senza mai passare `comparison_service:`**: l'iniezione esiste per testabilità unitaria della classe, non è mai usata in produzione. Lo stesso pattern (parametro di servizio iniettabile ma mai passato da `ReportPdf`) si ritrova identico in ogni altra pagina di questa cartella, sempre con nome `breakdown_service:` invece di `comparison_service:` (perché `TotalsPage` è l'unica delle sei a consumare un `*Comparison`, le altre cinque un `*Breakdown`).
>
> *EN: `comparison_service:` has a default (`StatisticSpi::TotalMembersComparison`) but can be swapped out — useful in tests to inject a fake without touching the database. Note, though, that `ReportPdf#draw_content_pages` always calls `page_class.draw(pdf, form: form)`, **never passing `comparison_service:`**: the injection exists for unit testability of the class, it's never exercised in production. The same pattern (an injectable service parameter that `ReportPdf` never actually passes) shows up identically in every other page in this folder, always named `breakdown_service:` instead of `comparison_service:` (because `TotalsPage` is the only one of the six that consumes a `*Comparison`, the other five consume a `*Breakdown`).*

### `draw`

```ruby
def draw
  result = @comparison_service.call(zoning: @form.zoning, anno: @form.anno, mese: @form.mese)
  @pdf.fill_color "000000"
  draw_heading(result)
  return draw_message(result.error, "DC3545") unless result.success?

  draw_columns(result)
end
```

> **IT:** `@pdf.fill_color "000000"` è la prima istruzione del corpo, prima ancora di disegnare qualunque cosa: Prawn mantiene lo stato del colore di riempimento come stato **globale del documento**, non locale a un blocco o a una pagina — se una pagina precedente (es. `CessazioniPage`, che disegna una torta con colori diversi) lascia `fill_color` impostato su un altro valore, senza questo reset il testo di `TotalsPage` erediterebbe quel colore invece del nero atteso. Tutte e sei le pagine di questa cartella iniziano con lo stesso reset, per lo stesso motivo — un gotcha di Prawn documentato anche in `CodeGuide/StatisticPrints/` per il report non-SPI. Il controllo `unless result.success?` interrompe il rendering **prima** di `draw_columns` quando manca uno dei due anni di confronto (vedi `TotalMembersComparison#call`): la pagina mostra solo il titolo e un messaggio d'errore in rosso, mai una tabella vuota o un grafico senza dati.
>
> *EN: `@pdf.fill_color "000000"` is the first statement in the body, before anything is drawn: Prawn keeps the fill color as **document-wide state**, not scoped to a block or a page — if a previous page (e.g. `CessazioniPage`, which draws a pie chart with different colors) leaves `fill_color` set to something else, without this reset `TotalsPage`'s text would inherit that color instead of the expected black. All six pages in this folder start with the same reset, for the same reason — a Prawn gotcha also documented in `CodeGuide/StatisticPrints/` for the non-SPI report. The `unless result.success?` check stops rendering **before** `draw_columns` when one of the two comparison years is missing (see `TotalMembersComparison#call`): the page shows only the title and a red error message, never an empty table or a chart with no data.*

### `draw_columns`, `draw_column` — bounding box side-by-side, non sequenziale

```ruby
def draw_columns(result)
  top = @pdf.cursor
  left = @pdf.bounds.left

  iscritti_bottom = draw_column(left, top, "Iscritti", result, :iscritti_totale, :iscritti_comprensori, "iscritti")
  deleghe_bottom = draw_column(left + column_width + column_gap, top, "Deleghe", result, :deleghe_totale,
    :deleghe_comprensori, "deleghe")

  draw_chart(result, [ iscritti_bottom, deleghe_bottom ].min)
end

def draw_column(x, top, title, result, totale_key, comprensori_key, metric_label)
  cursor_after = nil
  @pdf.bounding_box([ x, top ], width: column_width, height: top) do
    draw_metric_title(title)
    totale_row = result.public_send(totale_key)
    StatisticPrints::ComparisonTable.draw(
      @pdf, title: totale_row.zoning.descrizione_azzonamento, mese: result.mese, anno: result.anno,
      anno_precedente: result.anno_precedente, rows: [ row_for(totale_row) ], metric_label: metric_label
    )
    comprensori_rows = result.public_send(comprensori_key)
    draw_comprensori_table(comprensori_rows, result, metric_label) if comprensori_rows.present?
    cursor_after = @pdf.cursor
  end
  cursor_after
end
```

> **IT:** Qui `bounding_box([x, top], width: column_width, height: top)` è l'uso **sicuro** di un box con `height:` pari a "tutto lo spazio verso il basso": le due colonne (`Iscritti` a sinistra, `Deleghe` a destra) sono **affiancate**, non impilate in sequenza, quindi il fatto che Prawn faccia atterrare il cursore condiviso del documento a `top - height` alla chiusura di ciascun box non causa problemi — non c'è una terza sezione sotto che erediterebbe quel cursore azzerato, perché subito dopo `draw_columns` chiama `draw_chart` passando esplicitamente `[iscritti_bottom, deleghe_bottom].min` (il valore di ritorno di `cursor_after`, catturato **dentro** il blocco, non letto dal cursore del documento dopo il box) come punto di partenza. Questo è esattamente il contrasto che `AgeClassesPage` (vedi `CodeGuide/StatisticSpiPrints/age_classes_page.md`) documenta in negativo: `bounding_box` con `height:` grande va bene per colonne parallele come queste, **non** per sezioni impilate verticalmente. `public_send(totale_key)`/`public_send(comprensori_key)` è la parte che rende `draw_column` un unico metodo generico invece di due quasi identici (uno per iscritti, uno per deleghe): i nomi dei campi del `Result` (`iscritti_totale`/`iscritti_comprensori` vs `deleghe_totale`/`deleghe_comprensori`, vedi `StatisticSpi::TotalMembersComparison::Result`) sono passati come simboli e risolti dinamicamente.
>
> *EN: Here `bounding_box([x, top], width: column_width, height: top)` is the **safe** use of a box whose `height:` is "all the space downward": the two columns (`Iscritti` on the left, `Deleghe` on the right) sit **side by side**, not stacked in sequence, so the fact that Prawn lands the document's shared cursor at `top - height` when each box closes causes no problem — there's no third section below that would inherit that zeroed-out cursor, because right after `draw_columns` calls `draw_chart`, explicitly passing `[iscritti_bottom, deleghe_bottom].min` (the return value of `cursor_after`, captured **inside** the block, not read from the document cursor after the box) as the starting point. This is exactly the contrast that `AgeClassesPage` (see `CodeGuide/StatisticSpiPrints/age_classes_page.md`) documents in the negative: `bounding_box` with a large `height:` is fine for parallel columns like these, **not** for vertically stacked sections. `public_send(totale_key)`/`public_send(comprensori_key)` is what makes `draw_column` a single generic method instead of two near-identical ones (one for iscritti, one for deleghe): the `Result`'s field names (`iscritti_totale`/`iscritti_comprensori` vs `deleghe_totale`/`deleghe_comprensori`, see `StatisticSpi::TotalMembersComparison::Result`) are passed in as symbols and resolved dynamically.*

### `draw_comprensori_table`, `draw_metric_title`, `row_for` *(privati)*

```ruby
def draw_comprensori_table(rows, result, metric_label)
  @pdf.move_down 8
  StatisticPrints::ComparisonTable.draw(
    @pdf, title: "Comprensori", mese: result.mese, anno: result.anno, anno_precedente: result.anno_precedente,
    rows: rows.map { |row| row_for(row) }, metric_label: metric_label
  )
end

def draw_metric_title(title)
  @pdf.font("AsapCondensed", style: :bold, size: 13) { @pdf.text title, color: METRIC_COLOR }
  @pdf.move_down 4
end

def row_for(row)
  { label: row.zoning.descrizione_azzonamento, count_precedente: row.count_precedente, count_anno: row.count_anno,
    diff: row.diff, diff_percent: row.diff_percent }
end
```

> **IT:** `StatisticPrints::ComparisonTable` (vedi `CodeGuide/StatisticPrints/comparison_table.md` se presente) è riusata **senza modifiche** dal report non-SPI: accetta un array di hash generici (`label`/`count_precedente`/`count_anno`/`diff`/`diff_percent`), non `Row` struct SPI-specifici, quindi `row_for` esiste solo per fare da adattatore tra `StatisticSpi::TotalMembersComparison::Row` e la forma attesa dalla tabella condivisa — la stessa funzione di adattamento che, nella versione non-SPI, è già superflua perché `Statistics::TotalMembersComparison::Row` combacia direttamente. La tabella "Comprensori" viene disegnata solo `if comprensori_rows.present?` (vedi `draw_column` sopra): quando l'azzonamento scelto non è regionale, `iscritti_comprensori`/`deleghe_comprensori` sono `[]` e la colonna mostra solo la riga di totale, senza una sezione "Comprensori" vuota.
>
> *EN: `StatisticPrints::ComparisonTable` (see `CodeGuide/StatisticPrints/comparison_table.md` if present) is reused **unmodified** from the non-SPI report: it accepts an array of generic hashes (`label`/`count_precedente`/`count_anno`/`diff`/`diff_percent`), not SPI-specific `Row` structs, so `row_for` exists purely as an adapter between `StatisticSpi::TotalMembersComparison::Row` and the shape the shared table expects — the same adapter role that, in the non-SPI version, is already unnecessary because `Statistics::TotalMembersComparison::Row` matches directly. The "Comprensori" table is only drawn `if comprensori_rows.present?` (see `draw_column` above): when the chosen zoning isn't regional, `iscritti_comprensori`/`deleghe_comprensori` are `[]` and the column shows only the total row, with no empty "Comprensori" section.*

### `draw_chart`, `chart_entries` *(privati)*

```ruby
def draw_chart(result, columns_bottom)
  chart_top = columns_bottom - section_gap
  height = [ chart_top - 6, mm(MAX_CHART_HEIGHT_MM) ].min
  entries = chart_entries(result)

  BarChart.draw(
    @pdf, at: [ @pdf.bounds.left, chart_top ], width: @pdf.bounds.width, height: height,
    labels: entries.map { |iscritti, _| iscritti.zoning.descrizione_azzonamento },
    iscritti_previous: entries.map { |iscritti, _| iscritti.count_precedente },
    iscritti_current: entries.map { |iscritti, _| iscritti.count_anno },
    deleghe_previous: entries.map { |_, deleghe| deleghe.count_precedente },
    deleghe_current: entries.map { |_, deleghe| deleghe.count_anno },
    iscritti_percentages: entries.map { |iscritti, _| iscritti.diff_percent },
    deleghe_percentages: entries.map { |_, deleghe| deleghe.diff_percent },
    previous_label: "#{result.mese} #{result.anno_precedente}", current_label: "#{result.mese} #{result.anno}"
  )
end

def chart_entries(result)
  return result.iscritti_comprensori.zip(result.deleghe_comprensori) if result.iscritti_comprensori.present?

  [ [ result.iscritti_totale, result.deleghe_totale ] ]
end
```

> **IT:** `BarChart` qui (senza prefisso di modulo, quindi risolto come `StatisticSpiPrints::BarChart`, definito in `app/services/statistic_spi_prints/bar_chart.rb`, non `StatisticPrints::BarChart`) è una classe **specifica** di questa cartella, non riusata dal report Attivi: deve disegnare **quattro** serie per barra di gruppo (iscritti anno precedente/corrente, deleghe anno precedente/corrente) invece delle due della versione Attivi, perché questa è l'unica sezione SPI con due metriche parallele nello stesso grafico. `chart_entries` usa `Array#zip` per accoppiare `iscritti_comprensori[i]` con `deleghe_comprensori[i]` posizionalmente: funziona solo perché entrambi gli array sono generati nello stesso ordine da `TotalMembersComparison#comprensori_rows` (che itera su `Zoning.comprensori_di(@zoning)` una volta per ciascuna metrica, ma con lo stesso `.map` sullo stesso scope ordinato) — un accoppiamento implicito tra due chiamate di servizio separate, non imposto dai tipi. `height = [chart_top - 6, MAX_CHART_HEIGHT_MM * 72 / 25.4].min` è la stessa tecnica di "altezza massima ma mai oltre lo spazio rimasto" vista nelle altre pagine (`chart_height` in `TipologieDelegaPage`/`CessazioniPage`/`ProvvisoriePage`): qui il calcolo usa `columns_bottom` (il minimo tra le due colonne, catturato per valore dal chiamante) come base, non `@pdf.cursor` diretto, perché il cursore del documento dopo due `bounding_box` affiancate non riflette in modo affidabile "il punto più basso raggiunto da entrambe le colonne".
>
> *EN: `BarChart` here (unprefixed, so resolved as `StatisticSpiPrints::BarChart`, defined in `app/services/statistic_spi_prints/bar_chart.rb`, not `StatisticPrints::BarChart`) is a class **specific** to this folder, not reused from the Attivi report: it has to draw **four** series per bar group (iscritti previous/current year, deleghe previous/current year) instead of the two in the Attivi version, because this is the only SPI section with two parallel metrics in the same chart. `chart_entries` uses `Array#zip` to positionally pair `iscritti_comprensori[i]` with `deleghe_comprensori[i]`: this only works because both arrays are generated in the same order by `TotalMembersComparison#comprensori_rows` (which iterates over `Zoning.comprensori_di(@zoning)` once per metric, but with the same `.map` over the same ordered scope) — an implicit coupling between two separate service calls, not enforced by the types. `height = [chart_top - 6, MAX_CHART_HEIGHT_MM * 72 / 25.4].min` is the same "capped height but never past the remaining space" technique seen in the other pages (`chart_height` in `TipologieDelegaPage`/`CessazioniPage`/`ProvvisoriePage`): here the computation uses `columns_bottom` (the minimum of the two columns, captured by value from the caller) as the base, not `@pdf.cursor` directly, because the document cursor after two side-by-side `bounding_box`es doesn't reliably reflect "the lowest point reached by either column".*

### `column_width`, `column_gap`, `section_gap` *(privati)*

```ruby
def column_width = (@pdf.bounds.width - column_gap) / 2
```

> **IT:** Tre metodi a una riga (endless method definition, Ruby 3.0+) che ricompaiono, identici nella forma, in ogni pagina della cartella — solo `chart_height`/`MAX_CHART_HEIGHT_MM` cambiano nome/valore da pagina a pagina. Nessuna memoizzazione (`@pdf.bounds.width` è economico da leggere ogni volta, non una query): a differenza di `counts_by_comprensorio` nei servizi `StatisticSpi::*`, qui non c'è nessun costo da ammortizzare.
>
> *EN: Three one-line methods (endless method definition, Ruby 3.0+) that reappear, identical in shape, in every page in this folder — only `chart_height`/`MAX_CHART_HEIGHT_MM` change name/value from page to page. No memoization (`@pdf.bounds.width` is cheap to read every time, not a query): unlike `counts_by_comprensorio` in the `StatisticSpi::*` services, there's no cost to amortize here.*

> **Nota 2026-10-05 / Note:** dove il testo cita `mm_to_pt` o la conversione `* 72 / 25.4` ripetuta nelle pagine, dal refactor si tratta dell'helper condiviso `mm` di `StatisticPrints::PageLayout` (vedi `CodeGuide/StatisticPrints/page_layout.md`). / Where the text mentions `mm_to_pt` or the `* 72 / 25.4` conversion repeated in pages, since the refactor that is the shared `mm` helper of `StatisticPrints::PageLayout`.
