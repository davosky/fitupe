module StatisticSpiPrints
  # Tabella per la pagina Deleghe Multiple: a differenza di ComparisonTable non
  # confronta due anni (MultipleDelegationsBreakdown lavora su un solo
  # periodo), quindi le colonne sono le occorrenze (Doppia/Tripla/Quadrupla/
  # Quintupla) piu' il totale.
  class MultipleDelegationsTable
    include StatisticPrints::TableStyle

    def self.draw(...) = new(...).draw

    def initialize(pdf, rows:, title: nil)
      @pdf = pdf
      @rows = rows
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

    def header_row = [ "Azzonamento", "Doppia", "Tripla", "Quadrupla", "Quintupla", "totale deleghe multiple" ]

    def table_data
      [ header_row ] + @rows.map { |row| data_row(row) }
    end

    def data_row(row)
      [
        row.zoning.descrizione_azzonamento, StatisticPrints::NumberFormatting.count(row.doppia),
        StatisticPrints::NumberFormatting.count(row.tripla), StatisticPrints::NumberFormatting.count(row.quadrupla),
        StatisticPrints::NumberFormatting.count(row.quintupla), StatisticPrints::NumberFormatting.count(row.totale)
      ]
    end

    def column_widths
      width = @pdf.bounds.width
      { 0 => width * 0.28, 1 => width * 0.13, 2 => width * 0.13, 3 => width * 0.13, 4 => width * 0.13, 5 => width * 0.2 }
    end

    def cell_style = super(size: 11, padding: [ 6, 8 ])
  end
end
