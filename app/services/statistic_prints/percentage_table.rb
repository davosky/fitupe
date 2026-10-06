module StatisticPrints
  class PercentageTable
    include TableStyle

    def self.draw(...) = new(...).draw

    def initialize(pdf, at:, width:, rows:, label_header: "Gruppo")
      @pdf = pdf
      @at = at
      @width = width
      @rows = rows
      @label_header = label_header
    end

    def draw
      @pdf.bounding_box(@at, width: @width) { draw_styled_table(width: @width) }
    end

    private

    def header_row = [ @label_header, "% sul totale iscritti" ]

    def table_data
      [ header_row ] + @rows.map { |row| [ row[:label], NumberFormatting.percent(row[:percentuale]) ] }
    end

    def column_widths
      { 0 => @width * 0.5, 1 => @width * 0.5 }
    end
  end
end
