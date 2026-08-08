module StatisticSpiPrints
  # Pagina "Classi di Età": specchia il grafico Fasce d'Età di
  # StatisticPrints::WorkStatusAgePage (SingleSeriesBarChart), ma solo il
  # grafico (nessuna tabella, non richiesta). A livello regionale mostra il
  # grafico regionale, prominente, seguito da una riga di grafici piu' piccoli
  # uno per comprensorio; a livello di comprensorio mostra solo il proprio.
  class AgeClassesPage
    SECTION_GAP_MM = 8
    COLUMN_GAP_MM = 10
    TITLE_GAP_PT = 6
    REGIONAL_CHART_HEIGHT_MM = 75
    COMPRENSORIO_CHART_HEIGHT_MM = 55
    SINGLE_CHART_HEIGHT_MM = 130
    BANDS = StatisticSpi::AgeBreakdown::BANDS
    # Etichette brevi per i grafici comprensoriali (regionale escluso): le
    # denominazioni per esteso (GIOVANI, TRENTENNI, ecc.) non ci stanno nella
    # larghezza ridotta delle colonne comprensoriali.
    SHORT_LABELS = {
      "GIOVANI" => "< 30", "TRENTENNI" => "30", "QUARANTENNI" => "40", "CINQUANTENNI" => "50",
      "SESSANTENNI" => "60", "SETTANTENNI" => "70", "OTTANTENNI" => "80", "NOVANTENNI" => "90",
      "HIGHLANDERS" => "> 90"
    }.freeze

    def self.draw(...) = new(...).draw

    def initialize(pdf, form:, breakdown_service: StatisticSpi::AgeBreakdown)
      @pdf = pdf
      @form = form
      @breakdown_service = breakdown_service
    end

    def draw
      @pdf.fill_color "000000"
      draw_heading
      result = @breakdown_service.call(zoning: @form.zoning, anno: @form.anno, mese: @form.mese)
      if result.comprensori.present?
        draw_regional_and_comprensori(result)
      else
        draw_chart_section(result.totale, @pdf.bounds.left, @pdf.bounds.width, mm_to_pt(SINGLE_CHART_HEIGHT_MM),
          title_size: 14, top: @pdf.cursor)
      end
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
      return "CGIL Classi di Età SPI – Regionale e Comprensori" if @form.zoning.regionale?

      "CGIL Classi di Età SPI – Comprensorio di #{@form.zoning.descrizione_azzonamento}"
    end

    # Niente bounding_box qui: un box con height pari a "tutto lo spazio
    # rimasto in pagina" (necessario altrove per non far traboccare tabelle
    # dal numero di righe variabile) fa sempre atterrare il cursore condiviso
    # della pagina a fondo pagina alla chiusura del blocco, a prescindere da
    # quanto contenuto sia stato davvero disegnato dentro. Con due sezioni in
    # sequenza (regionale poi riga comprensori) questo azzererebbe lo spazio
    # disponibile per la seconda. Titolo e grafico vengono quindi posizionati
    # con coordinate assolute, calcolate a partire da altezze note in anticipo.
    def draw_regional_and_comprensori(result)
      top = @pdf.cursor
      regional_height = mm_to_pt(REGIONAL_CHART_HEIGHT_MM)
      draw_chart_section(result.totale, @pdf.bounds.left, @pdf.bounds.width, regional_height, title_size: 14, top: top)

      comprensori_top = top - title_block_height(14) - regional_height - section_gap
      draw_comprensori_row(result.comprensori, comprensori_top)
    end

    def draw_comprensori_row(comprensori, top)
      width = comprensorio_width(comprensori.size)
      comprensori.each_with_index do |row, index|
        x = @pdf.bounds.left + (index * (width + column_gap))
        draw_chart_section(row, x, width, mm_to_pt(COMPRENSORIO_CHART_HEIGHT_MM), title_size: 11, top: top)
      end
    end

    def draw_chart_section(row, x, width, height, title_size:, top:)
      @pdf.font("AsapCondensed", style: :bold, size: title_size) do
        @pdf.draw_text row.zoning.descrizione_azzonamento, at: [ x, top - title_size ]
      end

      chart_top = top - title_block_height(title_size)
      StatisticPrints::SingleSeriesBarChart.draw(
        @pdf, at: [ x, chart_top ], width: width, height: height,
        labels: chart_labels(row.zoning), data: BANDS.map { |fascia, _| row.totali[fascia] },
        percentages: BANDS.map { |fascia, _| row.percentuali[fascia] }
      )
    end

    def chart_labels(zoning)
      return BANDS.map(&:first) if zoning.regionale?

      BANDS.map { |fascia, _| SHORT_LABELS.fetch(fascia) }
    end

    def title_block_height(title_size) = title_size + TITLE_GAP_PT

    def comprensorio_width(count) = ((@pdf.bounds.width - (column_gap * (count - 1))) / count)

    def column_gap = mm_to_pt(COLUMN_GAP_MM)
    def section_gap = mm_to_pt(SECTION_GAP_MM)
    def mm_to_pt(mm) = mm * 72 / 25.4
  end
end
