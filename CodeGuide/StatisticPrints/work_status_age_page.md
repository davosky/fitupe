# `StatisticPrints::WorkStatusAgePage`

**File:** `app/services/statistic_prints/work_status_age_page.rb`

## Codice completo

```ruby
module StatisticPrints
  class WorkStatusAgePage
    MAX_CHART_HEIGHT_MM = 70
    SECTION_GAP_MM = 5
    COLUMN_GAP_MM = 10

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

      draw_columns(result)
    end

    private

    def draw_heading(zoning)
      @pdf.font("AsapCondensed", style: :bold, size: 16) do
        @pdf.text "Status Lavorativo e Fasce d'Età - #{zoning.descrizione_azzonamento}"
      end
      @pdf.move_down 8
      @pdf.stroke_color "CCCCCC"
      @pdf.stroke_horizontal_rule
      @pdf.move_down section_gap
    end

    def draw_message(message, color)
      @pdf.font("AsapCondensed", size: 12) { @pdf.text message, color: color }
    end

    # Disegna prima le due tabelle (colonne di larghezza diversa a seconda del numero
    # di righe) e solo dopo i grafici, così i due grafici possono condividere lo
    # stesso top e la stessa altezza e risultare allineati in basso.
    def draw_columns(result)
      top = @pdf.cursor
      left = @pdf.bounds.left

      status_bottom = draw_status_table(result, left, top)
      eta_bottom = draw_eta_table(result, left + column_width + column_gap, top)

      draw_charts(result, left, status_bottom, eta_bottom)
    end

    def draw_status_table(result, x, top)
      cursor_after = nil
      @pdf.bounding_box([ x, top ], width: column_width, height: top) do
        if result.status_lavorativo.blank?
          draw_message("Nessun dato di Status Lavorativo presente per il periodo selezionato.", "666666")
        else
          SingleYearTable.draw(
            @pdf, title: "Status Lavorativo", label_header: "Tipologia Status", mese: result.mese, anno: result.anno,
            rows: result.status_lavorativo.map { |row| row_for(row.tipologia_status, row) }
          )
          cursor_after = @pdf.cursor
        end
      end
      cursor_after
    end

    def draw_eta_table(result, x, top)
      cursor_after = nil
      @pdf.bounding_box([ x, top ], width: column_width, height: top) do
        if result.fasce_eta.blank?
          draw_message("Nessun dato di Fasce d'Età presente per il periodo selezionato.", "666666")
        else
          SingleYearTable.draw(
            @pdf, title: "Fasce d'Età", label_header: "Fascia d'Età", mese: result.mese, anno: result.anno,
            rows: result.fasce_eta.map { |row| row_for(row.fascia, row) }
          )
          cursor_after = @pdf.cursor
        end
      end
      cursor_after
    end

    def row_for(label, row)
      { label: label, count: row.count, percentuale: row.percentuale }
    end

    def draw_charts(result, left, status_bottom, eta_bottom)
      return if status_bottom.nil? && eta_bottom.nil?

      chart_top = [ status_bottom, eta_bottom ].compact.min - section_gap
      height = [ chart_top - 6, MAX_CHART_HEIGHT_MM * 72 / 25.4 ].min

      draw_status_chart(result, left, chart_top, height) if status_bottom
      draw_eta_chart(result, left, chart_top, height) if eta_bottom
    end

    def draw_status_chart(result, left, chart_top, height)
      SingleSeriesBarChart.draw(
        @pdf, at: [ left, chart_top ], width: column_width, height: height,
        labels: result.status_lavorativo.map(&:tipologia_status), data: result.status_lavorativo.map(&:count)
      )
    end

    def draw_eta_chart(result, left, chart_top, height)
      SingleSeriesBarChart.draw(
        @pdf, at: [ left + column_width + column_gap, chart_top ], width: column_width, height: height,
        labels: result.fasce_eta.map(&:fascia), data: result.fasce_eta.map(&:count),
        percentages: result.fasce_eta.map(&:percentuale)
      )
    end

    def column_width = (@pdf.bounds.width - column_gap) / 2.0
    def column_gap = COLUMN_GAP_MM * 72 / 25.4
    def section_gap = SECTION_GAP_MM * 72 / 25.4
  end
end
```

## Sezioni commentate

### Struttura generale

> **IT:** `WorkStatusAgePage` è, metodo per metodo, lo stesso identico scheletro di `NationalityGenderPage` (`CodeGuide/StatisticPrints/nationality_gender_page.md`, da leggere prima di questo file per la spiegazione completa): `draw_columns` disegna prima le due tabelle dentro `bounding_box([x, top], height: top)` catturando ciascun fondo reale in una variabile locale (`cursor_after`) letta **dentro** il blocco — mai dopo la sua chiusura, per lo stesso identico motivo spiegato in `nationality_gender_page.md` (un `bounding_box` con `height: top` ancorato in cima forza il cursore del documento verso il fondo pagina alla chiusura, indipendentemente da quanto contenuto è stato realmente disegnato) — poi `draw_charts` calcola un `chart_top`/`height` condivisi dal minimo dei due fondi e disegna entrambi i grafici a coordinate assolute, senza mai fare un `@pdf.move_down` finale (i grafici sono l'ultimo contenuto della pagina). Le uniche differenze reali sono: colonne di **uguale** larghezza (`column_width = (bounds.width - column_gap) / 2.0`, un 50/50 invece del rapporto asimmetrico `SESSO_RATIO` 1/3–2/3), le due tabelle sono `SingleSeriesBarChart` invece di `PieChart` (barre invece di torte — coerente col fatto che sia `WorkStatusBreakdown` sia `AgeBreakdown` sono le due sezioni che a schermo usano il controller Stimulus `bar-chart`, non `pie-chart`; vedi `CodeGuide/Statistics/README.md`), e i valori mm (`MAX_CHART_HEIGHT_MM = 70`, `SECTION_GAP_MM = 5`) sono leggermente più contenuti perché "Fasce d'Età" ha sempre 9 righe fisse (vedi `CodeGuide/Statistics/age_breakdown.md`), più delle 2 di "Sesso", quindi la colonna destra è mediamente più alta di quella di `NationalityGenderPage` e richiede più margine di sicurezza verticale.
>
> *EN: `WorkStatusAgePage` is, method for method, the exact same skeleton as `NationalityGenderPage` (`CodeGuide/StatisticPrints/nationality_gender_page.md`, read before this file for the full explanation): `draw_columns` draws both tables first inside a `bounding_box([x, top], height: top)`, capturing each real bottom into a local variable (`cursor_after`) read **inside** the block — never after it closes, for the exact same reason explained in `nationality_gender_page.md` (a `bounding_box` with `height: top` anchored at the top forces the document's cursor down to the page bottom on close, regardless of how much content was actually drawn) — then `draw_charts` computes a shared `chart_top`/`height` from the minimum of the two bottoms and draws both charts at absolute coordinates, never doing a final `@pdf.move_down` (the charts are the last content on the page). The only real differences are: **equal**-width columns (`column_width = (bounds.width - column_gap) / 2.0`, a 50/50 split instead of `SESSO_RATIO`'s asymmetric 1/3–2/3), the two charts are `SingleSeriesBarChart` instead of `PieChart` (bars instead of pies — consistent with both `WorkStatusBreakdown` and `AgeBreakdown` being the two on-screen sections using the `bar-chart` Stimulus controller, not `pie-chart`; see `CodeGuide/Statistics/README.md`), and the mm values (`MAX_CHART_HEIGHT_MM = 70`, `SECTION_GAP_MM = 5`) are slightly tighter because "Fasce d'Età" always has 9 fixed rows (see `CodeGuide/Statistics/age_breakdown.md`), more than "Sesso"'s 2, so the right column tends to run taller than in `NationalityGenderPage` and needs a bit more vertical safety margin.*

### `draw_eta_chart` e il parametro `percentages:`

```ruby
def draw_eta_chart(result, left, chart_top, height)
  SingleSeriesBarChart.draw(
    @pdf, at: [ left + column_width + column_gap, chart_top ], width: column_width, height: height,
    labels: result.fasce_eta.map(&:fascia), data: result.fasce_eta.map(&:count),
    percentages: result.fasce_eta.map(&:percentuale)
  )
end
```

> **IT:** L'unico dettaglio realmente specifico di questa pagina: `draw_eta_chart` passa `percentages: result.fasce_eta.map(&:percentuale)` a `SingleSeriesBarChart`, mentre `draw_status_chart` (per Status Lavorativo, subito sopra nel file) non lo fa. Questo rispecchia esattamente la stessa opzione, documentata in `CodeGuide/Statistics/README.md`, del controller Stimulus `bar-chart` a schermo: un valore `percentages` opzionale — aggiunto appositamente per Fasce d'Età — che permette di mostrare la percentuale sopra ogni colonna invece del conteggio assoluto, senza dover toccare le sezioni preesistenti che non lo passano. `SingleSeriesBarChart` (`CodeGuide/StatisticPrints/single_series_bar_chart.md`) replica lato Prawn la stessa interfaccia opzionale.
>
> *EN: The one genuinely page-specific detail: `draw_eta_chart` passes `percentages: result.fasce_eta.map(&:percentuale)` to `SingleSeriesBarChart`, while `draw_status_chart` (for Status Lavorativo, right above it in the file) does not. This mirrors exactly the same option, documented in `CodeGuide/Statistics/README.md`, of the on-screen `bar-chart` Stimulus controller: an optional `percentages` value — added specifically for Age Bands — that lets each column show its percentage instead of its absolute count, without needing to touch pre-existing sections that don't pass it. `SingleSeriesBarChart` (`CodeGuide/StatisticPrints/single_series_bar_chart.md`) mirrors the same optional interface on the Prawn side.*
