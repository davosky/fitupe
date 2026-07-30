module StatisticPrints
  class EmploymentStatusPage
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

    def draw_heading(zoning)
      @pdf.font("AsapCondensed", style: :bold, size: 16) { @pdf.text "Attivi / Pensionati - #{zoning.descrizione_azzonamento}" }
      @pdf.move_down 8
      @pdf.stroke_color "CCCCCC"
      @pdf.stroke_horizontal_rule
      @pdf.move_down section_gap
    end

    def draw_message(message, color)
      @pdf.font("AsapCondensed", size: 12) { @pdf.text message, color: color }
    end

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
    def column_gap = COLUMN_GAP_MM * 72 / 25.4

    def chart_height(top) = [ top - @pdf.bounds.bottom - 6, MAX_CHART_HEIGHT_MM * 72 / 25.4 ].min

    def section_gap = SECTION_GAP_MM * 72 / 25.4
  end
end
