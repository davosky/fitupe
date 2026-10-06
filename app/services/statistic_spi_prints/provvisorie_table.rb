module StatisticSpiPrints
  # Tabella per la pagina Provvisorie: a differenza di CategoryTable qui c'e'
  # un solo numero (non un'etichetta per colonna) piu' la sua percentuale sul
  # totale deleghe, a specchio di app/views/statistic_spi/_provvisorie_table.
  class ProvvisorieTable
    include StatisticPrints::TableStyle

    def self.draw(...) = new(...).draw

    def initialize(pdf, rows:, title: nil)
      @pdf = pdf
      @rows = rows
      @title = title
    end

    def draw
      draw_title
      draw_styled_table
    end

    private

    def header_row = [ "Azzonamento", "totale provvisorie", "% sul totale deleghe" ]

    def table_data
      [ header_row ] + @rows.map { |row| data_row(row) }
    end

    def data_row(row)
      [
        row.zoning.descrizione_azzonamento, StatisticPrints::NumberFormatting.count(row.totale),
        StatisticPrints::NumberFormatting.percent(row.percentuale)
      ]
    end

    def column_widths
      width = @pdf.bounds.width
      { 0 => width * 0.4, 1 => width * 0.3, 2 => width * 0.3 }
    end

    def cell_style = super(size: 9)
  end
end
