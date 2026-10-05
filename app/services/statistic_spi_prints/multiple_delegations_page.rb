module StatisticSpiPrints
  # Pagina "Deleghe Multiple": specchia app/views/statistic_spi/_deleghe_multiple_card
  # e _multiple_delegations_comprensori_card. Niente confronto anno su anno
  # (MultipleDelegationsBreakdown lavora su un solo periodo) quindi niente
  # grafico, solo le due tabelle una sotto l'altra: ci stanno comode in una
  # pagina sola senza bisogno di colonne affiancate.
  class MultipleDelegationsPage
    include StatisticPrints::PageLayout

    SECTION_GAP_MM = 10

    def self.draw(...) = new(...).draw

    def initialize(pdf, form:, breakdown_service: StatisticSpi::MultipleDelegationsBreakdown)
      @pdf = pdf
      @form = form
      @breakdown_service = breakdown_service
    end

    def draw
      @pdf.fill_color "000000"
      draw_heading
      result = @breakdown_service.call(zoning: @form.zoning, anno: @form.anno, mese: @form.mese)
      draw_totale(result)
      draw_comprensori(result) if result.comprensori.present?
    end

    private

    def draw_heading = draw_page_heading(heading_title, subtitle: period_subtitle)

    def heading_title
      return "CGIL Deleghe Multiple SPI – Regionale e Comprensori" if @form.zoning.regionale?

      "CGIL Deleghe Multiple SPI – Comprensorio di #{@form.zoning.descrizione_azzonamento}"
    end

    def draw_totale(result)
      MultipleDelegationsTable.draw(@pdf, title: result.totale.zoning.descrizione_azzonamento, rows: [ result.totale ])
    end

    def draw_comprensori(result)
      @pdf.move_down section_gap
      MultipleDelegationsTable.draw(@pdf, title: "Comprensori", rows: result.comprensori)
    end
  end
end
