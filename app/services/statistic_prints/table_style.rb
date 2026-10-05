module StatisticPrints
  # Stile condiviso dalle tabelle prawn-table dei due fascicoli: celle con il
  # solo bordo inferiore chiaro, intestazione in grassetto con bordo scuro.
  # Una tabella con corpo o padding diversi ridefinisce cell_style con super.
  module TableStyle
    private

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
