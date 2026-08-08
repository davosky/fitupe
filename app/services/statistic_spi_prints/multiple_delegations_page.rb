module StatisticSpiPrints
  # Pagina "Deleghe Multiple": specchia app/views/statistic_spi/_deleghe_multiple_card
  # e _multiple_delegations_comprensori_card. Niente confronto anno su anno
  # (MultipleDelegationsBreakdown lavora su un solo periodo) quindi niente
  # grafico, solo le due tabelle una sotto l'altra: ci stanno comode in una
  # pagina sola senza bisogno di colonne affiancate.
  class MultipleDelegationsPage
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

    def draw_heading
      @pdf.font("AsapCondensed", style: :bold, size: 16) { @pdf.text heading_title }
      @pdf.move_down 2
      @pdf.font("AsapCondensed", size: 10) { @pdf.text "Tesseramento #{@form.mese} #{@form.anno}", color: "666666" }
      @pdf.move_down 8
      @pdf.stroke_color "CCCCCC"
      @pdf.stroke_horizontal_rule
      @pdf.move_down section_gap
    end

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

    def section_gap = SECTION_GAP_MM * 72 / 25.4
  end
end
