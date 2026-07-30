module StatisticPrints
  class MembershipTypesPage
    MAX_CHART_HEIGHT_MM = 60
    SECTION_GAP_MM = 6

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

      draw_iscrizione(result)
      draw_delega(result)
    end

    private

    def draw_heading(zoning)
      @pdf.font("AsapCondensed", style: :bold, size: 16) { @pdf.text "Tipologie - #{zoning.descrizione_azzonamento}" }
      @pdf.move_down 8
      @pdf.stroke_color "CCCCCC"
      @pdf.stroke_horizontal_rule
      @pdf.move_down section_gap
    end

    def draw_message(message, color)
      @pdf.font("AsapCondensed", size: 12) { @pdf.text message, color: color }
    end

    def draw_iscrizione(result)
      return if result.tipologie_iscrizione.blank?

      ComparisonTable.draw(
        @pdf, title: "Tipologie Iscrizione", label_header: "Tipologia Iscrizioni", mese: result.mese,
        anno: result.anno, anno_precedente: result.anno_precedente,
        rows: result.tipologie_iscrizione.map { |row| row_for(row) }
      )
      @pdf.move_down section_gap
    end

    def draw_delega(result)
      return if result.tipologie_delega.blank?

      ComparisonTable.draw(
        @pdf, title: "Tipologie Delega", label_header: "Tipologia Delega", mese: result.mese, anno: result.anno,
        anno_precedente: result.anno_precedente, rows: result.tipologie_delega.map { |row| row_for(row) }
      )
      @pdf.move_down section_gap
      draw_chart(result)
    end

    def row_for(row)
      { label: row.tipologia, count_precedente: row.count_precedente, count_anno: row.count_anno,
        diff: row.diff, diff_percent: row.diff_percent }
    end

    def draw_chart(result)
      BarChart.draw(
        @pdf, at: [ @pdf.bounds.left, @pdf.cursor ], width: @pdf.bounds.width, height: chart_height,
        labels: result.tipologie_delega.map(&:tipologia), previous_data: result.tipologie_delega.map(&:count_precedente),
        current_data: result.tipologie_delega.map(&:count_anno), percentages: result.tipologie_delega.map(&:diff_percent),
        previous_label: "#{result.mese} #{result.anno_precedente}", current_label: "#{result.mese} #{result.anno}"
      )
    end

    def chart_height
      [ @pdf.cursor - 6, MAX_CHART_HEIGHT_MM * 72 / 25.4 ].min
    end

    def section_gap = SECTION_GAP_MM * 72 / 25.4
  end
end
