module StatisticPrints
  # Tabella "per categoria": una riga per categoria e, per ciascun valore
  # (es. FEMMINE, MASCHI, ALTRO), una coppia di colonne conteggio / %.
  class CategoryCrossTable
    LABEL_RATIO = 0.19
    PRIMARY = "158CBA"
    ICON_HEIGHT = 20

    def self.draw(...) = new(...).draw

    def initialize(pdf, rows:, title:, icon:)
      @pdf = pdf
      @rows = rows
      @title = title
      @icon = icon
    end

    def draw
      draw_title
      table = @pdf.make_table(table_data, header: true, width: @pdf.bounds.width, cell_style: cell_style,
        column_widths: column_widths)
      style(table)
      table.draw
    end

    private

    # Icona della sezione (PNG, la stessa della card a video) con il titolo
    # centrato verticalmente al suo fianco.
    def draw_title
      top = @pdf.cursor
      info = @pdf.image @icon.to_s, at: [ 0, top ], height: ICON_HEIGHT
      @pdf.font("AsapCondensed", style: :bold, size: 14) do
        @pdf.text_box @title, at: [ info.scaled_width + 8, top ], height: ICON_HEIGHT, valign: :center
      end
      @pdf.move_down ICON_HEIGHT + 6
    end

    def labels = @rows.first.cells.map(&:label)

    def header_row
      [ "Categoria" ] + labels.map { |label| { content: label, colspan: 2, align: :center } }
    end

    def table_data
      [ header_row ] + @rows.map { |row| [ row.categoria ] + row.cells.flat_map { |cell| cell_pair(cell) } }
    end

    def cell_pair(cell)
      [ NumberFormatting.count(cell.count), NumberFormatting.percent(cell.percentuale) ]
    end

    def column_widths
      width = @pdf.bounds.width
      value_width = width * (1 - LABEL_RATIO) / (labels.size * 2)
      [ width * LABEL_RATIO ] + Array.new(labels.size * 2, value_width)
    end

    def cell_style
      {
        font: "AsapCondensed", size: 10, text_color: "000000", borders: [ :bottom ], border_color: "DDDDDD",
        padding: [ 7, 5 ]
      }
    end

    def style(table)
      table.row(0).font_style = :bold
      table.row(0).text_color = PRIMARY
      table.row(0).border_color = "666666"
      table.columns(1..-1).rows(1..-1).align = :right
      separate_groups(table)
    end

    # Una riga verticale a sinistra di ogni coppia conteggio/% dopo la prima,
    # per staccare visivamente i gruppi (FEMMINE | MASCHI | ALTRO).
    def separate_groups(table)
      (3..labels.size * 2).step(2) { |column| table.column(column).rows(1..-1).borders = [ :bottom, :left ] }
    end
  end
end
