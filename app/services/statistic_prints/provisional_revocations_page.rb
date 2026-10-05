module StatisticPrints
  class ProvisionalRevocationsPage
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
      return draw_message("Nessun dato presente per il periodo selezionato.", "666666") if result.provvisorie_revoche.blank?

      draw_table(result)
      draw_chart_and_percentages(result)
    end

    private

    def draw_heading(zoning) = draw_page_heading("Provvisorie / Revoche - #{zoning.descrizione_azzonamento}")

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

    def chart_height(top) = [ top - @pdf.bounds.bottom - 6, mm(MAX_CHART_HEIGHT_MM) ].min
  end
end
