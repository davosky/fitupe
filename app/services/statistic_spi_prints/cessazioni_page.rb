module StatisticSpiPrints
  # Pagina "Cessazioni": specchia app/views/statistic_spi/_cessazioni_card e
  # _cessazioni_comprensori_card, con l'aggiunta di una torta Cessazioni/Deleghe
  # Confermate per colonna (come ProvvisoriePage, non presente nel mockup ma
  # richiesta da davo dopo). Totale e Comprensori affiancati in colonne per
  # stare in una pagina sola.
  class CessazioniPage
    include StatisticPrints::PageLayout

    SECTION_GAP_MM = 8
    COLUMN_GAP_MM = 12
    CHART_HEIGHT_MM = 60
    COMPRENSORI_COLORS = %w[28B62C FF851B FF4136 158CBA 75CAEB].freeze
    ETICHETTE = StatisticSpi::CessazioniBreakdown::ETICHETTE

    def self.draw(...) = new(...).draw

    def initialize(pdf, form:, breakdown_service: StatisticSpi::CessazioniBreakdown)
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
      return "CGIL Cessazioni SPI – Regionale e Comprensori" if @form.zoning.regionale?

      "CGIL Cessazioni SPI – Comprensorio di #{@form.zoning.descrizione_azzonamento}"
    end

    def draw_two_columns(result)
      top = @pdf.cursor
      left = @pdf.bounds.left

      draw_totale_column(result, left, top, column_width)
      draw_comprensori_column(result, left + column_width + column_gap, top, column_width)
    end

    def draw_totale_column(result, x, top, width)
      @pdf.bounding_box([ x, top ], width: width, height: top) do
        CategoryTable.draw(@pdf, title: result.totale.zoning.descrizione_azzonamento, rows: [ result.totale ],
          etichette: ETICHETTE, total_label: "totale cessazioni")
        @pdf.move_down section_gap
        MotivoCessazionePercentageTable.draw(@pdf, row: result.totale, etichette: ETICHETTE)
        @pdf.move_down section_gap
        draw_totale_chart(result.totale, width)
      end
    end

    def draw_totale_chart(row, width)
      deleghe_confermate = row.deleghe_totale - row.totale
      StatisticPrints::PieChart.draw(
        @pdf, at: [ @pdf.bounds.left, @pdf.cursor ], width: width, height: chart_height,
        labels: [ "Cessazioni", "Deleghe Confermate" ], data: [ row.totale, deleghe_confermate ]
      )
    end

    def draw_comprensori_column(result, x, top, width)
      @pdf.bounding_box([ x, top ], width: width, height: top) do
        CategoryTable.draw(@pdf, title: "Comprensori", rows: result.comprensori, etichette: ETICHETTE,
          total_label: "totale cessazioni")
        @pdf.move_down section_gap
        CategoryPercentageTable.draw(@pdf, title: "Comprensori (%)", rows: result.comprensori, etichette: ETICHETTE)
        @pdf.move_down section_gap
        draw_comprensori_chart(result.comprensori, width)
      end
    end

    def draw_comprensori_chart(comprensori, width)
      percentuali = comprensori.map { |row| comprensorio_percentuale(row) }
      deleghe_confermate_percentuale = 100.0 - percentuali.sum
      labels = comprensori.map { |row| row.zoning.descrizione_azzonamento } + [ "Deleghe Confermate" ]
      data = percentuali + [ deleghe_confermate_percentuale ]

      StatisticPrints::PieChart.draw(
        @pdf, at: [ @pdf.bounds.left, @pdf.cursor ], width: width, height: chart_height, labels: labels, data: data,
        colors: COMPRENSORI_COLORS, label_formatter: ->(value, _fraction) { [ StatisticPrints::NumberFormatting.percent(value) ] }
      )
    end

    def comprensorio_percentuale(row)
      row.deleghe_totale.to_i.zero? ? 0 : (row.totale.to_f / row.deleghe_totale * 100)
    end

    def column_width = (@pdf.bounds.width - column_gap) / 2

    def chart_height = [ @pdf.cursor - 6, mm(CHART_HEIGHT_MM) ].min
  end
end
