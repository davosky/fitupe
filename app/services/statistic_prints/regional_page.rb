module StatisticPrints
  class RegionalPage
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
      return draw_error(result.error) unless result.success?

      draw_heading(result)
      draw_regional_table(result)
      if result.comprensori.present?
        draw_comprensori(result)
      else
        draw_single_chart(result)
      end
    end

    private

    def draw_error(message)
      @pdf.font("AsapCondensed", size: 14) { @pdf.text message, color: "DC3545" }
    end

    def draw_heading(result)
      @pdf.font("AsapCondensed", style: :bold, size: 16) { @pdf.text heading_title(result.zoning) }
      @pdf.move_down 2
      @pdf.font("AsapCondensed", size: 10) { @pdf.text "Tesseramento #{result.mese} #{result.anno}", color: "666666" }
      @pdf.move_down 8
      @pdf.stroke_color "CCCCCC"
      @pdf.stroke_horizontal_rule
      @pdf.move_down section_gap
    end

    def heading_title(zoning)
      return "CGIL Totale Iscritti – Regionale e Comprensori" if zoning.regionale?

      "CGIL Totale Iscritti – Comprensorio di #{zoning.descrizione_azzonamento}"
    end

    def draw_regional_table(result)
      ComparisonTable.draw(
        @pdf, title: result.zoning.descrizione_azzonamento, mese: result.mese, anno: result.anno,
        anno_precedente: result.anno_precedente, rows: [ row_for(result.zoning, result) ]
      )
    end

    def row_for(zoning, row)
      { label: zoning.descrizione_azzonamento, count_precedente: row.count_precedente, count_anno: row.count_anno,
        diff: row.diff, diff_percent: row.diff_percent }
    end

    def draw_comprensori(result)
      @pdf.move_down 12
      ComparisonTable.draw(
        @pdf, title: "Comprensori", mese: result.mese, anno: result.anno, anno_precedente: result.anno_precedente,
        rows: result.comprensori.map { |c| row_for(c.zoning, c) }
      )
      @pdf.move_down section_gap
      draw_chart(result, result.comprensori.map { |c| [ c.zoning, c ] })
    end

    def draw_single_chart(result)
      @pdf.move_down section_gap
      draw_chart(result, [ [ result.zoning, result ] ])
    end

    def draw_chart(result, entries)
      BarChart.draw(
        @pdf, at: [ @pdf.bounds.left, @pdf.cursor ], width: @pdf.bounds.width, height: chart_height,
        labels: entries.map { |zoning, _| zoning.descrizione_azzonamento },
        previous_data: entries.map { |_, row| row.count_precedente }, current_data: entries.map { |_, row| row.count_anno },
        percentages: entries.map { |_, row| row.diff_percent },
        previous_label: "#{result.mese} #{result.anno_precedente}", current_label: "#{result.mese} #{result.anno}"
      )
    end

    def chart_height
      [ @pdf.cursor - 6, MAX_CHART_HEIGHT_MM * 72 / 25.4 ].min
    end

    def section_gap = SECTION_GAP_MM * 72 / 25.4
  end
end
