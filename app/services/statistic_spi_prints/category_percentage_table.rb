module StatisticSpiPrints
  # Come CategoryTable ma con le percentuali invece dei conteggi, niente
  # colonna "totale".
  class CategoryPercentageTable
    def self.draw(...) = new(...).draw

    def initialize(pdf, rows:, etichette:, title: nil)
      @pdf = pdf
      @rows = rows
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

    def header_row = [ "Azzonamento" ] + @etichette

    def table_data
      [ header_row ] + @rows.map { |row| data_row(row) }
    end

    def data_row(row)
      [ row.zoning.descrizione_azzonamento ] +
        @etichette.map { |etichetta| StatisticPrints::NumberFormatting.percent(row.percentuali[etichetta]) }
    end

    def column_widths
      width = @pdf.bounds.width
      label_width = width * 0.2
      etichetta_width = (width - label_width) / @etichette.size
      widths = { 0 => label_width }
      @etichette.each_index { |index| widths[index + 1] = etichetta_width }
      widths
    end

    def cell_style
      {
        font: "AsapCondensed", size: 8, text_color: "000000", borders: [ :bottom ], border_color: "DDDDDD",
        padding: [ 4, 4 ]
      }
    end

    def style_header(table)
      table.row(0).font_style = :bold
      table.row(0).borders = [ :bottom ]
      table.row(0).border_color = "666666"
    end
  end
end
