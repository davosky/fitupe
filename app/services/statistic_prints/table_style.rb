module StatisticPrints
  # Stile condiviso dalle tabelle prawn-table dei due fascicoli: celle con il
  # solo bordo inferiore chiaro, intestazione in grassetto con bordo scuro.
  # Una tabella con corpo o padding diversi ridefinisce cell_style con super.
  module TableStyle
    private

    def draw_title(size: 12)
      return if @title.blank?

      @pdf.font("AsapCondensed", style: :bold, size: size) { @pdf.text @title }
      @pdf.move_down 4
    end

    # Costruisce e disegna la tabella (table_data, column_widths della classe);
    # il blocco riceve la tabella per gli stili aggiuntivi.
    def draw_styled_table(width: @pdf.bounds.width)
      table = @pdf.make_table(table_data, header: true, width: width, cell_style: cell_style,
        column_widths: column_widths)
      style_header(table)
      yield table if block_given?
      table.draw
    end

    def cell_style(size: 10, padding: [ 5, 6 ])
      {
        font: "AsapCondensed", size: size, text_color: "000000", borders: [ :bottom ], border_color: "DDDDDD",
        padding: padding
      }
    end

    def style_header(table)
      table.row(0).font_style = :bold
      table.row(0).borders = [ :bottom ]
      table.row(0).border_color = "666666"
    end
  end
end
