module StatisticPrints
  class ComparisonTable
    include TableStyle

    DANGER = "FF4136"
    SUCCESS = "28B62C"

    def self.draw(...) = new(...).draw

    def initialize(pdf, rows:, mese:, anno:, anno_precedente:, title: nil, label_header: "Azzonamento",
      metric_label: "iscritti")
      @pdf = pdf
      @title = title
      @rows = rows
      @mese = mese
      @anno = anno
      @anno_precedente = anno_precedente
      @label_header = label_header
      @metric_label = metric_label
    end

    def draw
      draw_title
      draw_styled_table { |table| style_rows(table) }
    end

    private

    def draw_title = super(size: 13)

    def header_row
      [ @label_header, "#{@mese} #{@anno_precedente}", "#{@mese} #{@anno}", @metric_label, "%" ]
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
