# `StatisticPrints::CategoriesPage`

**File:** `app/services/statistic_prints/categories_page.rb`

## Codice completo

```ruby
module StatisticPrints
  class CategoriesPage
    include PageLayout

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
      draw_heading(result.zoning)
      return draw_empty(result) if result.categorie.blank?

      draw_table(result)
      draw_chart(result)
    end

    private

    def draw_heading(zoning) = draw_page_heading("Categorie - #{zoning.descrizione_azzonamento}", gap: 10)

    def draw_empty(result)
      message = result.success? ? "Nessuna categoria presente per il periodo selezionato." : result.error
      draw_message(message)
    end

    def draw_table(result)
      ComparisonTable.draw(
        @pdf, label_header: "Categoria", mese: result.mese, anno: result.anno,
        anno_precedente: result.anno_precedente, rows: result.categorie.map { |row| row_for(row) }
      )
    end

    def row_for(row)
      { label: row.categoria, count_precedente: row.count_precedente, count_anno: row.count_anno,
        diff: row.diff, diff_percent: row.diff_percent }
    end

    def draw_chart(result)
      @pdf.move_down section_gap
      BarChart.draw(
        @pdf, at: [ @pdf.bounds.left, @pdf.cursor ], width: @pdf.bounds.width, height: chart_height,
        labels: result.categorie.map(&:categoria), previous_data: result.categorie.map(&:count_precedente),
        current_data: result.categorie.map(&:count_anno), percentages: result.categorie.map(&:diff_percent),
        previous_label: "#{result.mese} #{result.anno_precedente}", current_label: "#{result.mese} #{result.anno}"
      )
    end

    def chart_height
      [ @pdf.cursor - 6, mm(MAX_CHART_HEIGHT_MM) ].min
    end
  end
end
```

## Sezioni commentate

### `draw`

```ruby
def draw
  result = @comparison_service.call(zoning: @form.zoning, anno: @form.anno, mese: @form.mese)
  @pdf.fill_color "000000"
  draw_heading(result.zoning)
  return draw_empty(result) if result.categorie.blank?

  draw_table(result)
  draw_chart(result)
end
```

> **IT:** Struttura identica a `RegionalPage` (stesso `fill_color` reset, stesso wiring verso `Statistics::TotalMembersComparison`, stessa coppia tabella+`BarChart` — vedi `CodeGuide/StatisticPrints/regional_page.md` per la spiegazione completa del pattern). La differenza sta in **dove** avviene il controllo di uscita anticipata: qui `draw_heading` viene chiamato **sempre**, prima di sapere se ci sono dati o un errore, perché "Categorie - #{zoning}" resta un titolo di pagina sensato anche quando `result.categorie` è vuoto o `result.error` è presente — a differenza di `RegionalPage`, dove un errore salta anche il titolo. `result.categorie` proviene da `CategoryBreakdown` (documentato in `CodeGuide/Statistics/category_breakdown.md`), il servizio "confronto anno su anno" con una riga per ogni categoria sindacale effettivamente presente nei dati (`FILCAMS`, `FILLEA`, ...).
>
> *EN: Structurally identical to `RegionalPage` (same `fill_color` reset, same wiring to `Statistics::TotalMembersComparison`, same table+`BarChart` pairing — see `CodeGuide/StatisticPrints/regional_page.md` for the full pattern explanation). The difference is **where** the early-exit check happens: here `draw_heading` is called **unconditionally**, before knowing whether there's data or an error, because "Categorie - #{zoning}" remains a sensible page title even when `result.categorie` is empty or `result.error` is set — unlike `RegionalPage`, where an error skips the title too. `result.categorie` comes from `CategoryBreakdown` (documented in `CodeGuide/Statistics/category_breakdown.md`), the "year-over-year comparison" service with one row per union category actually present in the data (`FILCAMS`, `FILLEA`, ...).*

### `draw_empty` *(privato)*

```ruby
def draw_empty(result)
  message = result.success? ? "Nessuna categoria presente per il periodo selezionato." : result.error
  @pdf.font("AsapCondensed", size: 12) { @pdf.text message, color: "666666" }
end
```

> **IT:** A differenza di `draw_error` in `RegionalPage` (che gestisce **solo** il caso `!result.success?`, sempre in rosso `DC3545`), `draw_empty` gestisce **due** casi distinti con un unico messaggio grigio (`666666`, non rosso): dati mancanti per il periodo (`!result.success?`, stesso messaggio di errore di `TotalMembersComparison`) *oppure* periodo valido ma senza nessuna categoria censita (`result.categorie.blank?` con `result.success?` vero). Distinguere questi due casi è necessario perché `CategoryBreakdown` può restituire legittimamente un array vuoto (nessuna riga `Import` ha una categoria valorizzata) anche quando il periodo stesso esiste — un caso diverso dal "non ci sono dati per questo periodo" di `TotalMembersComparison`. Il colore grigio invece di rosso comunica visivamente che non si tratta di un errore bloccante ma solo di "niente da mostrare qui".
>
> *EN: Unlike `draw_error` in `RegionalPage` (which handles **only** the `!result.success?` case, always in red `DC3545`), `draw_empty` handles **two** distinct cases with a single grey (`666666`, not red) message: missing data for the period (`!result.success?`, the same error message from `TotalMembersComparison`) *or* a valid period with no categories recorded at all (`result.categorie.blank?` while `result.success?` is true). Distinguishing these two cases is necessary because `CategoryBreakdown` can legitimately return an empty array (no `Import` row has a category set) even when the period itself exists — a different case from `TotalMembersComparison`'s "no data for this period". The grey color instead of red visually communicates that this isn't a blocking error, just "nothing to show here".*

> **Nota 2026-10-05 / Note:** lo snippet qui sopra mostra il codice precedente al refactor: intestazione, messaggi, spaziature e conversione mm → punti arrivano ora da `StatisticPrints::PageLayout` (vedi `CodeGuide/StatisticPrints/page_layout.md`); il "Codice completo" in cima è quello attuale. / The snippet above shows the pre-refactor code: heading, messages, gaps and mm → points conversion now come from `StatisticPrints::PageLayout`; the "Codice completo" at the top is current.

### `draw_table`, `row_for` *(privati)*

```ruby
def draw_table(result)
  ComparisonTable.draw(
    @pdf, label_header: "Categoria", mese: result.mese, anno: result.anno,
    anno_precedente: result.anno_precedente, rows: result.categorie.map { |row| row_for(row) }
  )
end

def row_for(row)
  { label: row.categoria, count_precedente: row.count_precedente, count_anno: row.count_anno,
    diff: row.diff, diff_percent: row.diff_percent }
end
```

> **IT:** Stesso contratto `Hash` (`label`/`count_precedente`/`count_anno`/`diff`/`diff_percent`) verso `ComparisonTable` visto in `RegionalPage#row_for`, ma qui con più righe (una per categoria) invece di una singola riga per azzonamento, e passando `label_header: "Categoria"` invece di `title:` — `ComparisonTable` supporta entrambe le modalità (titolo di sezione vs. intestazione di colonna), a seconda che la tabella rappresenti un solo soggetto o una lista.
>
> *EN: The same `Hash` contract (`label`/`count_precedente`/`count_anno`/`diff`/`diff_percent`) toward `ComparisonTable` seen in `RegionalPage#row_for`, but here with multiple rows (one per category) instead of a single per-zoning row, and passing `label_header: "Categoria"` instead of `title:` — `ComparisonTable` supports both modes (section title vs. column header), depending on whether the table represents a single subject or a list.*

### `draw_chart`, `chart_height`, `section_gap` *(privati)*

```ruby
def draw_chart(result)
  @pdf.move_down section_gap
  BarChart.draw(
    @pdf, at: [ @pdf.bounds.left, @pdf.cursor ], width: @pdf.bounds.width, height: chart_height,
    labels: result.categorie.map(&:categoria), previous_data: result.categorie.map(&:count_precedente),
    current_data: result.categorie.map(&:count_anno), percentages: result.categorie.map(&:diff_percent),
    previous_label: "#{result.mese} #{result.anno_precedente}", current_label: "#{result.mese} #{result.anno}"
  )
end

def chart_height
  [ @pdf.cursor - 6, mm(MAX_CHART_HEIGHT_MM) ].min
end

```

> **IT:** Identico, riga per riga (stessi valori mm, stessa formula di `chart_height`), a `RegionalPage#draw_chart`/`#chart_height`/`#section_gap` — vedi `CodeGuide/StatisticPrints/regional_page.md` per la spiegazione della "stretchy height" a larghezza intera pagina. L'unica differenza è la fonte dei dati (`result.categorie` invece di `entries` costruito ad-hoc): qui il numero di barre nel grafico dipende dal numero di categorie effettivamente presenti nei dati, che può variare da azzonamento ad azzonamento.
>
> *EN: Identical, line for line (same mm values, same `chart_height` formula), to `RegionalPage#draw_chart`/`#chart_height`/`#section_gap` — see `CodeGuide/StatisticPrints/regional_page.md` for the explanation of the full-page-width "stretchy height". The only difference is the data source (`result.categorie` instead of an ad-hoc `entries` array): here the number of bars in the chart depends on how many categories are actually present in the data, which can vary from one zoning to another.*
