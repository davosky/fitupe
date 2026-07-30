module StatisticPrints
  class NationalityGenderPage
    MAX_CHART_HEIGHT_MM = 90
    SECTION_GAP_MM = 6
    COLUMN_GAP_MM = 10
    SESSO_RATIO = 1.0 / 3

    def self.draw(...) = new(...).draw

    def initialize(pdf, form:)
      @pdf = pdf
      @form = form
    end

    def draw
      result = Statistics::TotalMembersComparison.call(zoning: @form.zoning, anno: @form.anno, mese: @form.mese)
      @pdf.fill_color "000000"
      draw_heading(result.zoning)
      return draw_message(result.error, "DC3545") unless result.success?

      draw_columns(result)
    end

    private

    def draw_heading(zoning)
      @pdf.font("AsapCondensed", style: :bold, size: 16) { @pdf.text "Sesso e Nazionalità - #{zoning.descrizione_azzonamento}" }
      @pdf.move_down 8
      @pdf.stroke_color "CCCCCC"
      @pdf.stroke_horizontal_rule
      @pdf.move_down section_gap
    end

    def draw_message(message, color)
      @pdf.font("AsapCondensed", size: 12) { @pdf.text message, color: color }
    end

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
      height = [ chart_top - 6, MAX_CHART_HEIGHT_MM * 72 / 25.4 ].min

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
    def column_gap = COLUMN_GAP_MM * 72 / 25.4

    def section_gap = SECTION_GAP_MM * 72 / 25.4
  end
end
