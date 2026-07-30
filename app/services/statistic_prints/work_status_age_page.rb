module StatisticPrints
  class WorkStatusAgePage
    MAX_CHART_HEIGHT_MM = 70
    SECTION_GAP_MM = 5
    COLUMN_GAP_MM = 10

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
