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
      table = @pdf.make_table(table_data, header: true, width: @pdf.bounds.width, cell_style: cell_style,
        column_widths: column_widths)
      style_header(table)
      table.draw
    end

    private

    def draw_title
      return if @title.blank?

      @pdf.font("AsapCondensed", style: :bold, size: 13) { @pdf.text @title }
      @pdf.move_down 4
    end

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
