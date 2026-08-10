# `StatisticPrints::ProvisionalRevocationsPage`

**File:** `app/services/statistic_prints/provisional_revocations_page.rb`

## Codice completo

```ruby
module StatisticPrints
  class ProvisionalRevocationsPage
    MAX_CHART_HEIGHT_MM = 90
    SECTION_GAP_MM = 10
    COLUMN_GAP_MM = 10
    CHART_COLUMN_RATIO = 2.0 / 3

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
      return draw_message(result.error, "DC3545") unless result.success?
      return draw_message("Nessun dato presente per il periodo selezionato.", "666666") if result.provvisorie_revoche.blank?

      draw_table(result)
      draw_chart_and_percentages(result)
    end

    private

    def draw_heading(zoning)
      @pdf.font("AsapCondensed", style: :bold, size: 16) { @pdf.text "Provvisorie / Revoche - #{zoning.descrizione_azzonamento}" }
      @pdf.move_down 8
      @pdf.stroke_color "CCCCCC"
      @pdf.stroke_horizontal_rule
      @pdf.move_down section_gap
    end

    def draw_message(message, color)
      @pdf.font("AsapCondensed", size: 12) { @pdf.text message, color: color }
    end

    def draw_table(result)
      SingleYearTable.draw(
        @pdf, label_header: "Tipologia", mese: result.mese, anno: result.anno,
        rows: result.provvisorie_revoche.map { |row| row_for(row) }
      )
    end

    def row_for(row)
      { label: row.tipologia, count: row.count, percentuale: row.percentuale }
    end

    def draw_chart_and_percentages(result)
      @pdf.move_down section_gap
      top = @pdf.cursor
      draw_chart(result, top)
      draw_percentages(result, top)
      @pdf.move_down chart_height(top)
    end

    def draw_chart(result, top)
      SingleSeriesBarChart.draw(
        @pdf, at: [ @pdf.bounds.left, top ], width: chart_width, height: chart_height(top),
        labels: result.provvisorie_revoche.map(&:tipologia), data: result.provvisorie_revoche.map(&:count)
      )
    end

    def draw_percentages(result, top)
      PercentageTable.draw(
        @pdf, at: [ @pdf.bounds.left + chart_width + column_gap, top ], width: percentages_width,
        label_header: "Tipologia", rows: result.provvisorie_revoche.map { |row| { label: row.tipologia, percentuale: row.percentuale } }
      )
    end

    def chart_width = (@pdf.bounds.width - column_gap) * CHART_COLUMN_RATIO
    def percentages_width = @pdf.bounds.width - column_gap - chart_width
    def column_gap = COLUMN_GAP_MM * 72 / 25.4

    def chart_height(top) = [ top - @pdf.bounds.bottom - 6, MAX_CHART_HEIGHT_MM * 72 / 25.4 ].min

    def section_gap = SECTION_GAP_MM * 72 / 25.4
  end
end
```

## Sezioni commentate

### `draw`, `draw_chart_and_percentages` e layout a due colonne

```ruby
def draw
  result = @comparison_service.call(zoning: @form.zoning, anno: @form.anno, mese: @form.mese)
  @pdf.fill_color "000000"
  draw_heading(result.zoning)
  return draw_message(result.error, "DC3545") unless result.success?
  return draw_message("Nessun dato presente per il periodo selezionato.", "666666") if result.provvisorie_revoche.blank?

  draw_table(result)
  draw_chart_and_percentages(result)
end
```

> **IT:** Struttura di pagina identica, quasi al carattere, a `EmploymentStatusPage` (`CodeGuide/StatisticPrints/employment_status_page.md`): stesso schema `draw_message` a due esiti (errore rosso / vuoto grigio), stesso layout a due colonne grafico (2/3) + `PercentageTable` (1/3) disegnate a coordinate assolute con `top` catturato una volta e propagato, stesso `chart_height(top)` scritto come `top - @pdf.bounds.bottom - 6` per non dipendere da un `@pdf.cursor` potenzialmente già spostato dai componenti disegnati nel frattempo, stesso `@pdf.move_down chart_height(top)` finale per far avanzare manualmente il cursore condiviso. La differenza sostanziale è semantica, non strutturale: qui `result.provvisorie_revoche` proviene da `Statistics::ProvisionalRevocationBreakdown` (`CodeGuide/Statistics/provisional_revocation_breakdown.md`), un breakdown a **distribuzione sul solo anno corrente** (`label`, `count`, `percentuale` — nessun `count_precedente`/`diff`), non un confronto anno su anno come `EmploymentStatusBreakdown`. Per questo la tabella a sinistra usa `SingleYearTable` invece di `ComparisonTable`, e il grafico usa `SingleSeriesBarChart` (`CodeGuide/StatisticPrints/single_series_bar_chart.md`, una sola serie di barre) invece di `BarChart` (due serie affiancate anno precedente/anno corrente) — la controparte statica del `bar-chart` Stimulus a schermo, non di `comparison-chart` (vedi `CodeGuide/Statistics/README.md`).
>
> *EN: Page structure identical, almost verbatim, to `EmploymentStatusPage` (`CodeGuide/StatisticPrints/employment_status_page.md`): the same two-outcome `draw_message` scheme (red error / grey empty), the same two-column layout of a chart (2/3) + `PercentageTable` (1/3) drawn at absolute coordinates with `top` captured once and threaded through, the same `chart_height(top)` written as `top - @pdf.bounds.bottom - 6` to avoid depending on a `@pdf.cursor` potentially already moved by components drawn in between, the same trailing `@pdf.move_down chart_height(top)` to manually advance the shared cursor. The substantial difference is semantic, not structural: here `result.provvisorie_revoche` comes from `Statistics::ProvisionalRevocationBreakdown` (`CodeGuide/Statistics/provisional_revocation_breakdown.md`), a **current-year-only distribution** breakdown (`label`, `count`, `percentuale` — no `count_precedente`/`diff`), not a year-over-year comparison like `EmploymentStatusBreakdown`. That's why the table on the left uses `SingleYearTable` instead of `ComparisonTable`, and the chart uses `SingleSeriesBarChart` (`CodeGuide/StatisticPrints/single_series_bar_chart.md`, a single bar series) instead of `BarChart` (two side-by-side series, previous/current year) — the static counterpart of the on-screen `bar-chart` Stimulus controller, not of `comparison-chart` (see `CodeGuide/Statistics/README.md`).*

### `row_for`, `draw_percentages` *(privati)*

```ruby
def row_for(row)
  { label: row.tipologia, count: row.count, percentuale: row.percentuale }
end

def draw_percentages(result, top)
  PercentageTable.draw(
    @pdf, at: [ @pdf.bounds.left + chart_width + column_gap, top ], width: percentages_width,
    label_header: "Tipologia", rows: result.provvisorie_revoche.map { |row| { label: row.tipologia, percentuale: row.percentuale } }
  )
end
```

> **IT:** A differenza di `EmploymentStatusPage`, dove `PercentageTable` e `BarChart` leggono due campi percentuale diversi dalla stessa riga (`diff_percent` per il grafico, `percentuale` per la tabella laterale — vedi la nota in `employment_status_page.md`), qui `SingleSeriesBarChart` **non riceve affatto** un parametro percentuali (non c'è un `percentages:` in `draw_chart`): l'unica percentuale mostrata in tutta la pagina è quella di `PercentageTable`, perché non esiste alcun `diff_percent` da cui attingere in un breakdown senza confronto anno su anno. `tipologia` qui vale sempre "Provvisorie" o "Revoche" (le uniche due righe restituite da `ProvisionalRevocationBreakdown#call`).
>
> *EN: Unlike `EmploymentStatusPage`, where `PercentageTable` and `BarChart` read two different percentage fields from the same row (`diff_percent` for the chart, `percentuale` for the side table — see the note in `employment_status_page.md`), here `SingleSeriesBarChart` receives **no** percentages parameter at all (no `percentages:` in `draw_chart`): the only percentage shown on the whole page is `PercentageTable`'s, because there's no `diff_percent` to draw from in a breakdown with no year-over-year comparison. `tipologia` here is always either "Provvisorie" or "Revoche" (the only two rows returned by `ProvisionalRevocationBreakdown#call`).*
