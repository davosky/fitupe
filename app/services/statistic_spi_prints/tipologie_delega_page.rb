module StatisticSpiPrints
  # Pagina "Tipologie Delega": specchia app/views/statistic_spi/_tipologie_delega_card
  # e _tipologie_delega_comprensori_card. Totale (tabella + grafico a barre) e
  # Comprensori (tabella conteggi + tabella percentuali) affiancati in colonne,
  # come TotalsPage, per stare in una pagina sola.
  class TipologieDelegaPage
    include StatisticPrints::PageLayout

    SECTION_GAP_MM = 8
    COLUMN_GAP_MM = 12
    CHART_HEIGHT_MM = 55
    ETICHETTE = StatisticSpi::TipologieDelegaBreakdown::ETICHETTE

    def self.draw(...) = new(...).draw

    def initialize(pdf, form:, breakdown_service: StatisticSpi::TipologieDelegaBreakdown)
      @pdf = pdf
      @form = form
      @breakdown_service = breakdown_service
    end

    def draw
      @pdf.fill_color "000000"
      draw_heading
      result = @breakdown_service.call(zoning: @form.zoning, anno: @form.anno, mese: @form.mese)
      if result.comprensori.present?
        draw_two_columns(result)
      else
        draw_totale_column(result, @pdf.bounds.left, @pdf.cursor, @pdf.bounds.width)
      end
    end

    private

    def draw_heading = draw_page_heading(heading_title, subtitle: period_subtitle)

    def heading_title
      return "CGIL Tipologie Delega SPI – Regionale e Comprensori" if @form.zoning.regionale?

      "CGIL Tipologie Delega SPI – Comprensorio di #{@form.zoning.descrizione_azzonamento}"
    end

    def draw_two_columns(result)
      top = @pdf.cursor
      left = @pdf.bounds.left

      draw_totale_column(result, left, top, column_width)
      draw_comprensori_column(result, left + column_width + column_gap, top, column_width)
    end

    def draw_totale_column(result, x, top, width)
      @pdf.bounding_box([ x, top ], width: width, height: top) do
        CategoryTable.draw(@pdf, title: result.totale.zoning.descrizione_azzonamento, rows: [ result.totale ], etichette: ETICHETTE)
        @pdf.move_down section_gap
        draw_chart(result.totale, width)
      end
    end

    def draw_chart(row, width)
      CategoryBarChart.draw(
        @pdf, at: [ @pdf.bounds.left, @pdf.cursor ], width: width, height: chart_height,
        labels: ETICHETTE, values: ETICHETTE.map { |etichetta| row.totali[etichetta] },
        percentages: ETICHETTE.map { |etichetta| row.percentuali[etichetta] }
      )
    end

    def draw_comprensori_column(result, x, top, width)
      @pdf.bounding_box([ x, top ], width: width, height: top) do
        CategoryTable.draw(@pdf, title: "Comprensori", rows: result.comprensori, etichette: ETICHETTE)
        @pdf.move_down section_gap
        CategoryPercentageTable.draw(@pdf, title: "Comprensori (%)", rows: result.comprensori, etichette: ETICHETTE)
        @pdf.move_down section_gap
        draw_comprensori_chart(result.comprensori, width)
      end
    end

    def draw_comprensori_chart(comprensori, width)
      GroupedCategoryBarChart.draw(
        @pdf, at: [ @pdf.bounds.left, @pdf.cursor ], width: width, height: chart_height,
        labels: comprensori.map { |row| row.zoning.descrizione_azzonamento }, series_labels: ETICHETTE,
        series_values: ETICHETTE.map { |etichetta| comprensori.map { |row| row.percentuali[etichetta] || 0 } }
      )
    end

    def column_width = (@pdf.bounds.width - column_gap) / 2

    def chart_height = [ @pdf.cursor - 6, mm(CHART_HEIGHT_MM) ].min
  end
end
