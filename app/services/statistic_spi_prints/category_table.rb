module StatisticSpiPrints
  # Tabella conteggi per categoria (etichette generiche, es. tipologia di
  # delega o motivo di cessazione) + totale. Le colonne sono lette da
  # un elenco di etichette passato dal chiamante (es.
  # StatisticSpi::TipologieDelegaBreakdown::ETICHETTE), cosi' restano in sync
  # se un domani cambiano le categorie.
  class CategoryTable
    include StatisticPrints::TableStyle

    def self.draw(...) = new(...).draw

    def initialize(pdf, rows:, etichette:, title: nil, total_label: "totale")
      @pdf = pdf
      @rows = rows
      @etichette = etichette
      @title = title
      @total_label = total_label
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

    def header_row = [ "Azzonamento" ] + @etichette + [ @total_label ]

    def table_data
      [ header_row ] + @rows.map { |row| data_row(row) }
    end

    def data_row(row)
      [ row.zoning.descrizione_azzonamento ] + @etichette.map { |etichetta| StatisticPrints::NumberFormatting.count(row.totali[etichetta]) } +
        [ StatisticPrints::NumberFormatting.count(row.totale) ]
    end

    def column_widths
      width = @pdf.bounds.width
      label_width = width * 0.17
      totale_width = width * 0.12
      etichetta_width = (width - label_width - totale_width) / @etichette.size
      widths = { 0 => label_width, (@etichette.size + 1) => totale_width }
      @etichette.each_index { |index| widths[index + 1] = etichetta_width }
      widths
    end

    def cell_style = super(size: 8, padding: [ 4, 4 ])
  end
end
