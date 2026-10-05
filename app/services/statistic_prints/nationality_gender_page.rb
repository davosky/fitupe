module StatisticPrints
  class NationalityGenderPage
    include PageLayout

    MAX_CHART_HEIGHT_MM = 90
    SECTION_GAP_MM = 6
    COLUMN_GAP_MM = 10
    SESSO_RATIO = 1.0 / 3

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

    def draw_heading(zoning) = draw_page_heading("Sesso e Nazionalità - #{zoning.descrizione_azzonamento}")

    # Disegna prima le due tabelle (colonne con un numero di righe diverso) e
    # solo dopo i grafici, così i due grafici a torta possono condividere lo
    # stesso top e la stessa altezza e risultare allineati in basso.
    def draw_columns(result)
      top = @pdf.cursor
      left = @pdf.bounds.left

      sesso_bottom = draw_sesso_table(result, left, top)
      nazionalita_bottom = draw_nazionalita_table(result, left + sesso_width + column_gap, top)

      draw_charts(result, left, sesso_bottom, nazionalita_bottom)
    end

    def draw_sesso_table(result, x, top)
      cursor_after = nil
      @pdf.bounding_box([ x, top ], width: sesso_width, height: top) do
        if result.sesso.blank?
          draw_message("Nessun dato di Sesso presente per il periodo selezionato.", "666666")
        else
          SingleYearTable.draw(
            @pdf, title: "Sesso", label_header: "Sesso", mese: result.mese, anno: result.anno,
            rows: result.sesso.map { |row| row_for(row.sesso, row) }
          )
          cursor_after = @pdf.cursor
        end
      end
      cursor_after
    end

    def draw_nazionalita_table(result, x, top)
      cursor_after = nil
      @pdf.bounding_box([ x, top ], width: nazionalita_width, height: top) do
        if result.nazionalita.blank?
          draw_message("Nessun dato di Nazionalità presente per il periodo selezionato.", "666666")
        else
          SingleYearTable.draw(
            @pdf, title: "Nazionalità", label_header: "Nazionalità", mese: result.mese, anno: result.anno,
            rows: result.nazionalita.map { |row| row_for(row.nazionalita, row) }
          )
          cursor_after = @pdf.cursor
        end
      end
      cursor_after
    end

    def row_for(label, row)
      { label: label, count: row.count, percentuale: row.percentuale }
    end

    def draw_charts(result, left, sesso_bottom, nazionalita_bottom)
      return if sesso_bottom.nil? && nazionalita_bottom.nil?

      chart_top = [ sesso_bottom, nazionalita_bottom ].compact.min - section_gap
      height = [ chart_top - 6, mm(MAX_CHART_HEIGHT_MM) ].min

      draw_sesso_chart(result, left, chart_top, height) if sesso_bottom
      draw_nazionalita_chart(result, left, chart_top, height) if nazionalita_bottom
    end

    def draw_sesso_chart(result, left, chart_top, height)
      PieChart.draw(
        @pdf, at: [ left, chart_top ], width: sesso_width, height: height,
        labels: result.sesso.map(&:sesso), data: result.sesso.map(&:count)
      )
    end

    def draw_nazionalita_chart(result, left, chart_top, height)
      PieChart.draw(
        @pdf, at: [ left + sesso_width + column_gap, chart_top ], width: nazionalita_width, height: height,
        labels: result.nazionalita.map(&:nazionalita), data: result.nazionalita.map(&:count)
      )
    end

    def sesso_width = (@pdf.bounds.width - column_gap) * SESSO_RATIO
    def nazionalita_width = @pdf.bounds.width - column_gap - sesso_width
  end
end
