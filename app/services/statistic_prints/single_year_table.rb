module StatisticPrints
  class SingleYearTable
    include TableStyle

    def self.draw(...) = new(...).draw

    def initialize(pdf, rows:, mese:, anno:, label_header:, title: nil)
      @pdf = pdf
      @rows = rows
      @mese = mese
      @anno = anno
      @label_header = label_header
      @title = title
    end

    def draw
      draw_title
      draw_styled_table
    end

    private

    def draw_title = super(size: 13)

    def header_row = [ @label_header, "#{@mese} #{@anno}", "%" ]

    def table_data
      [ header_row ] + @rows.map { |row| data_row(row) }
    end

    def data_row(row)
      [ row[:label], NumberFormatting.count(row[:count]), NumberFormatting.percent(row[:percentuale]) ]
    end

    def column_widths
      width = @pdf.bounds.width
      { 0 => width * 0.4, 1 => width * 0.3, 2 => width * 0.3 }
    end
  end
end
