module StatisticPrints
  class ComparisonTable
    DANGER = "FF4136"
    SUCCESS = "28B62C"

    def self.draw(...) = new(...).draw

    def initialize(pdf, title:, rows:, mese:, anno:, anno_precedente:)
      @pdf = pdf
      @title = title
      @rows = rows
      @mese = mese
      @anno = anno
      @anno_precedente = anno_precedente
    end

    def draw
      @pdf.font("AsapCondensed", style: :bold, size: 13) { @pdf.text @title }
      @pdf.move_down 4
      table = @pdf.make_table(table_data, header: true, width: @pdf.bounds.width, cell_style: cell_style,
        column_widths: column_widths)
      style_header(table)
      style_rows(table)
      table.draw
    end

    private

    def header_row
      [ "Azzonamento", "#{@mese} #{@anno_precedente}", "#{@mese} #{@anno}", "iscritti", "%" ]
    end

    def table_data
      [ header_row ] + @rows.map { |row| data_row(row) }
    end

    def data_row(row)
      [
        row[:label], NumberFormatting.count(row[:count_precedente]), NumberFormatting.count(row[:count_anno]),
        NumberFormatting.count(row[:diff]), NumberFormatting.percent(row[:diff_percent])
      ]
    end

    def column_widths
      width = @pdf.bounds.width
      { 0 => width * 0.33, 1 => width * 0.19, 2 => width * 0.19, 3 => width * 0.145, 4 => width * 0.145 }
    end

    def cell_style
      {
        font: "AsapCondensed", size: 10, text_color: "000000", borders: [ :bottom ], border_color: "DDDDDD",
        padding: [ 5, 6 ]
      }
    end

    def style_header(table)
      table.row(0).font_style = :bold
      table.row(0).borders = [ :bottom ]
      table.row(0).border_color = "666666"
    end

    def style_rows(table)
      @rows.each_with_index do |row, index|
        color = row[:diff].negative? ? DANGER : SUCCESS
        (3..4).each { |col| style_cell(table.row(index + 1).column(col), color) }
      end
    end

    def style_cell(cell, color)
      cell.text_color = color
      cell.font_style = :bold
    end
  end
end
