module StatisticSpiPrints
  # Tabella percentuali "trasposta" per un solo azzonamento: una riga per
  # motivo di cessazione invece di una colonna, a specchio di
  # app/views/statistic_spi/_cessazioni_percentage_table (usata solo per il
  # totale; i comprensori restano larghi come CategoryPercentageTable, una
  # colonna per motivo, perche' li' le righe sono gia' gli azzonamenti).
  class MotivoCessazionePercentageTable
    include StatisticPrints::TableStyle

    def self.draw(...) = new(...).draw

    def initialize(pdf, row:, etichette:, title: nil)
      @pdf = pdf
      @row = row
      @etichette = etichette
      @title = title
    end

    def draw
      draw_title
      draw_styled_table
    end

    private

    def header_row = [ "Motivo Cessazione", "% sul totale deleghe" ]

    def table_data
      [ header_row ] + @etichette.map { |etichetta| data_row(etichetta) }
    end

    def data_row(etichetta)
      [ etichetta, StatisticPrints::NumberFormatting.percent(@row.percentuali[etichetta]) ]
    end

    def column_widths
      width = @pdf.bounds.width
      { 0 => width * 0.65, 1 => width * 0.35 }
    end

    def cell_style = super(size: 9, padding: [ 4, 6 ])
  end
end
