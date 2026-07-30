module StatisticPrints
  class CategoriesPage
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

    def draw_heading(zoning)
      @pdf.font("AsapCondensed", style: :bold, size: 16) { @pdf.text "Categorie - #{zoning.descrizione_azzonamento}" }
      @pdf.move_down 8
      @pdf.stroke_color "CCCCCC"
      @pdf.stroke_horizontal_rule
      @pdf.move_down 10
    end

    def draw_empty(result)
      message = result.success? ? "Nessuna categoria presente per il periodo selezionato." : result.error
      @pdf.font("AsapCondensed", size: 12) { @pdf.text message, color: "666666" }
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
      [ @pdf.cursor - 6, MAX_CHART_HEIGHT_MM * 72 / 25.4 ].min
    end

    def section_gap = SECTION_GAP_MM * 72 / 25.4
  end
end
