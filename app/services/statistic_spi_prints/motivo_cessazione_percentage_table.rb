module StatisticSpiPrints
  # Tabella percentuali "trasposta" per un solo azzonamento: una riga per
  # motivo di cessazione invece di una colonna, a specchio di
  # app/views/statistic_spi/_cessazioni_percentage_table (usata solo per il
  # totale; i comprensori restano larghi come CategoryPercentageTable, una
  # colonna per motivo, perche' li' le righe sono gia' gli azzonamenti).
  class MotivoCessazionePercentageTable
    def self.draw(...) = new(...).draw

    def initialize(pdf, row:, etichette:, title: nil)
      @pdf = pdf
      @row = row
      @etichette = etichette
      @title = title
    end

    def draw
      draw_title
      table = @pdf.make_table(table_data, header: true, width: @pdf.bounds.width, cell_style: cell_style,
        column_widths: column_widths)
      style_header(table)
      table.draw
    end

    private

    def draw_title
      return if @title.blank?

      @pdf.font("AsapCondensed", style: :bold, size: 12) { @pdf.text @title }
      @pdf.move_down 4
    end

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

    def cell_style
      {
        font: "AsapCondensed", size: 9, text_color: "000000", borders: [ :bottom ], border_color: "DDDDDD",
        padding: [ 4, 6 ]
      }
    end

    def style_header(table)
      table.row(0).font_style = :bold
      table.row(0).borders = [ :bottom ]
      table.row(0).border_color = "666666"
    end
  end
end
