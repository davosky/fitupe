module StatisticPrints
  class PercentageTable
    def self.draw(...) = new(...).draw

    def initialize(pdf, at:, width:, rows:, label_header: "Gruppo")
      @pdf = pdf
      @at = at
      @width = width
      @rows = rows
      @label_header = label_header
    end

    def draw
      @pdf.bounding_box(@at, width: @width) do
        table = @pdf.make_table(table_data, header: true, width: @width, cell_style: cell_style,
          column_widths: column_widths)
        style_header(table)
        table.draw
      end
    end

    private

    def header_row = [ @label_header, "% sul totale iscritti" ]

    def table_data
      [ header_row ] + @rows.map { |row| [ row[:label], NumberFormatting.percent(row[:percentuale]) ] }
    end

    def column_widths
      { 0 => @width * 0.5, 1 => @width * 0.5 }
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
  end
end
