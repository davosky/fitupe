# `StatisticPrints::EmploymentStatusPage`

**File:** `app/services/statistic_prints/employment_status_page.rb`

## Codice completo

```ruby
module StatisticPrints
  class EmploymentStatusPage
    include PageLayout

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
      return draw_message("Nessun dato presente per il periodo selezionato.", "666666") if result.attivi_pensionati.blank?

      draw_table(result)
      draw_chart_and_percentages(result)
    end

    private

    def draw_heading(zoning) = draw_page_heading("Attivi / Pensionati - #{zoning.descrizione_azzonamento}")

    def draw_table(result)
      ComparisonTable.draw(
        @pdf, label_header: "Gruppo", mese: result.mese, anno: result.anno,
        anno_precedente: result.anno_precedente, rows: result.attivi_pensionati.map { |row| row_for(row) }
      )
    end

    def row_for(row)
      { label: row.gruppo, count_precedente: row.count_precedente, count_anno: row.count_anno,
        diff: row.diff, diff_percent: row.diff_percent }
    end

    def draw_chart_and_percentages(result)
      @pdf.move_down section_gap
      top = @pdf.cursor
      draw_chart(result, top)
      draw_percentages(result, top)
      @pdf.move_down chart_height(top)
    end

    def draw_chart(result, top)
      BarChart.draw(
        @pdf, at: [ @pdf.bounds.left, top ], width: chart_width, height: chart_height(top),
        labels: result.attivi_pensionati.map(&:gruppo), previous_data: result.attivi_pensionati.map(&:count_precedente),
        current_data: result.attivi_pensionati.map(&:count_anno), percentages: result.attivi_pensionati.map(&:diff_percent),
        previous_label: "#{result.mese} #{result.anno_precedente}", current_label: "#{result.mese} #{result.anno}"
      )
    end

    def draw_percentages(result, top)
      PercentageTable.draw(
        @pdf, at: [ @pdf.bounds.left + chart_width + column_gap, top ], width: percentages_width,
        label_header: "Gruppo", rows: result.attivi_pensionati.map { |row| { label: row.gruppo, percentuale: row.percentuale } }
      )
    end

    def chart_width = (@pdf.bounds.width - column_gap) * CHART_COLUMN_RATIO
    def percentages_width = @pdf.bounds.width - column_gap - chart_width

    def chart_height(top) = [ top - @pdf.bounds.bottom - 6, mm(MAX_CHART_HEIGHT_MM) ].min
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
  return draw_message(result.error, "DC3545") unless result.success?
  return draw_message("Nessun dato presente per il periodo selezionato.", "666666") if result.attivi_pensionati.blank?

  draw_table(result)
  draw_chart_and_percentages(result)
end
```

> **IT:** `result.attivi_pensionati` proviene da `Statistics::EmploymentStatusBreakdown` (`CodeGuide/Statistics/employment_status_breakdown.md`), l'unico breakdown "ibrido" della cartella `Statistics`: ogni `Row` porta **sia** i campi da confronto anno su anno (`count_anno`, `count_precedente`, `diff`, `diff_percent`, usati qui per `ComparisonTable`/`BarChart`) **sia** un campo `percentuale` da distribuzione a solo anno corrente (usato per `PercentageTable`). Questa pagina è quindi l'unica del batch che disegna, dalla stessa riga di dati, sia una tabella/grafico di confronto sia una tabella percentuali — le altre pagine "confronto" (`RegionalPage`, `CategoriesPage`, `MembershipTypesPage`) non hanno colonna percentuali, e le altre pagine "percentuali" (`ProvisionalRevocationsPage`, `NationalityGenderPage`, `WorkStatusAgePage`) non hanno colonna di confronto anno su anno.
>
> *EN: `result.attivi_pensionati` comes from `Statistics::EmploymentStatusBreakdown` (`CodeGuide/Statistics/employment_status_breakdown.md`), the only "hybrid" breakdown in the `Statistics` folder: every `Row` carries **both** the year-over-year comparison fields (`count_anno`, `count_precedente`, `diff`, `diff_percent`, used here for `ComparisonTable`/`BarChart`) **and** a `percentuale` field from the current-year-only distribution shape (used for `PercentageTable`). This page is therefore the only one in the batch that draws, from the very same data row, both a comparison table/chart and a percentage table — the other "comparison" pages (`RegionalPage`, `CategoriesPage`, `MembershipTypesPage`) have no percentage column, and the other "percentage" pages (`ProvisionalRevocationsPage`, `NationalityGenderPage`, `WorkStatusAgePage`) have no year-over-year column.*

### `draw_chart_and_percentages` *(privato)*

```ruby
def draw_chart_and_percentages(result)
  @pdf.move_down section_gap
  top = @pdf.cursor
  draw_chart(result, top)
  draw_percentages(result, top)
  @pdf.move_down chart_height(top)
end
```

> **IT:** Il grafico (colonna sinistra, 2/3 larghezza) e la tabella percentuali (colonna destra, 1/3) sono disegnati **affiancati** allo stesso `top`, ma — a differenza di `NationalityGenderPage`/`WorkStatusAgePage` (`CodeGuide/StatisticPrints/nationality_gender_page.md`) — nessuno dei due usa un `bounding_box`: `BarChart.draw`/`PercentageTable.draw` disegnano a coordinate assolute (`at: [...]`) passate esplicitamente, senza toccare né dipendere dal cursore condiviso della pagina. Per questo, dopo averli disegnati entrambi, il cursore della pagina va avanzato **manualmente** con `@pdf.move_down chart_height(top)`: se questa riga mancasse, il prossimo contenuto (in questo caso nessuno, essendo l'ultimo elemento di pagina, ma il pattern vale in generale) verrebbe disegnato sopra il grafico appena tracciato, perché il cursore non si sarebbe mai spostato.
>
> *EN: The chart (left column, 2/3 width) and the percentage table (right column, 1/3) are drawn **side by side** at the same `top`, but — unlike `NationalityGenderPage`/`WorkStatusAgePage` (`CodeGuide/StatisticPrints/nationality_gender_page.md`) — neither one uses a `bounding_box`: `BarChart.draw`/`PercentageTable.draw` draw at explicit absolute coordinates (`at: [...]`), never touching or depending on the page's shared cursor. Because of that, after drawing both, the page cursor must be advanced **manually** with `@pdf.move_down chart_height(top)`: if this line were missing, the next content (none here, since this is the last page element, but the pattern holds generally) would be drawn on top of the just-drawn chart, because the cursor would never have moved.*

### `draw_chart`, `draw_percentages` *(privati)*

```ruby
def draw_chart(result, top)
  BarChart.draw(
    @pdf, at: [ @pdf.bounds.left, top ], width: chart_width, height: chart_height(top),
    labels: result.attivi_pensionati.map(&:gruppo), previous_data: result.attivi_pensionati.map(&:count_precedente),
    current_data: result.attivi_pensionati.map(&:count_anno), percentages: result.attivi_pensionati.map(&:diff_percent),
    previous_label: "#{result.mese} #{result.anno_precedente}", current_label: "#{result.mese} #{result.anno}"
  )
end

def draw_percentages(result, top)
  PercentageTable.draw(
    @pdf, at: [ @pdf.bounds.left + chart_width + column_gap, top ], width: percentages_width,
    label_header: "Gruppo", rows: result.attivi_pensionati.map { |row| { label: row.gruppo, percentuale: row.percentuale } }
  )
end
```

> **IT:** `PercentageTable` (`CodeGuide/StatisticPrints/percentage_table.md`) è un componente più stretto di `ComparisonTable`/`SingleYearTable`: mostra solo `label` + `percentuale` sul totale iscritti, senza conteggi assoluti — pensato apposta per stare in una colonna da 1/3 pagina accanto a un grafico. `BarChart` qui riceve `percentages: result.attivi_pensionati.map(&:diff_percent)` (la variazione anno su anno, disegnata sopra le barre), **non** `row.percentuale` (che invece alimenta `PercentageTable` a fianco): sono due percentuali semanticamente diverse dalla stessa riga — l'una è "quanto è cambiato rispetto all'anno scorso", l'altra è "che quota rappresenta sul totale iscritti di quest'anno" — ed è per questo che la riga `EmploymentStatusBreakdown::Row` porta entrambi i campi (`diff_percent` e `percentuale`) invece di uno solo.
>
> *EN: `PercentageTable` (`CodeGuide/StatisticPrints/percentage_table.md`) is a narrower component than `ComparisonTable`/`SingleYearTable`: it shows only `label` + `percentuale` of total members, no absolute counts — designed specifically to fit in a 1/3-page column next to a chart. `BarChart` here receives `percentages: result.attivi_pensionati.map(&:diff_percent)` (the year-over-year change, drawn above the bars), **not** `row.percentuale` (which instead feeds the `PercentageTable` alongside it): these are two semantically different percentages from the same row — one is "how much this changed versus last year", the other is "what share of this year's total members this represents" — which is exactly why `EmploymentStatusBreakdown::Row` carries both fields (`diff_percent` and `percentuale`) instead of just one.*

### `chart_width`, `percentages_width`, `column_gap`, `chart_height`, `section_gap` *(privati)*

```ruby
def chart_width = (@pdf.bounds.width - column_gap) * CHART_COLUMN_RATIO
def percentages_width = @pdf.bounds.width - column_gap - chart_width

def chart_height(top) = [ top - @pdf.bounds.bottom - 6, mm(MAX_CHART_HEIGHT_MM) ].min

```

> **IT:** `CHART_COLUMN_RATIO = 2.0 / 3` fissa la spartizione orizzontale: `chart_width` prende i due terzi della larghezza disponibile (meno il gap tra colonne), `percentages_width` prende il resto — lo stesso schema "una costante ratio + due metodi complementari" ricorre in `NationalityGenderPage` (`SESSO_RATIO`) e `ProvisionalRevocationsPage` (stessa `CHART_COLUMN_RATIO`). `chart_height(top)` è scritto come `top - @pdf.bounds.bottom - 6` invece del più diretto `@pdf.cursor - 6` visto in `RegionalPage`/`CategoriesPage`: la differenza non è cosmetica. Qui `chart_height` viene invocato **dopo** che `draw_chart`/`draw_percentages` hanno già disegnato (dentro `draw_chart_and_percentages`, per calcolare di quanto avanzare il cursore), quindi `@pdf.cursor` a quel punto potrebbe non riflettere più in modo affidabile la posizione da cui si era partiti — usare il parametro `top`, catturato una sola volta a inizio metodo, garantisce che l'altezza calcolata sia sempre relativa al punto di partenza reale, indipendentemente da eventuali effetti collaterali dei componenti disegnati nel frattempo.
>
> *EN: `CHART_COLUMN_RATIO = 2.0 / 3` fixes the horizontal split: `chart_width` takes two-thirds of the available width (minus the gap between columns), `percentages_width` takes the rest — the same "one ratio constant plus two complementary methods" scheme recurs in `NationalityGenderPage` (`SESSO_RATIO`) and `ProvisionalRevocationsPage` (the same `CHART_COLUMN_RATIO`). `chart_height(top)` is written as `top - @pdf.bounds.bottom - 6` instead of the more direct `@pdf.cursor - 6` seen in `RegionalPage`/`CategoriesPage`: the difference isn't cosmetic. Here `chart_height` is invoked **after** `draw_chart`/`draw_percentages` have already drawn (inside `draw_chart_and_percentages`, to compute how far to advance the cursor), so `@pdf.cursor` at that point might no longer reliably reflect the position drawing started from — using the `top` parameter, captured once at the start of the method, guarantees the computed height is always relative to the actual starting point, regardless of any side effects from the components drawn in between.*
