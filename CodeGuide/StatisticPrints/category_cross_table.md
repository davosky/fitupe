# `StatisticPrints::CategoryCrossTable`

**File:** `app/services/statistic_prints/category_cross_table.rb`

## Codice completo

```ruby
module StatisticPrints
  # Tabella "per categoria": una riga per categoria e, per ciascun valore
  # (es. FEMMINE, MASCHI, ALTRO), una coppia di colonne conteggio / %.
  class CategoryCrossTable
    include TableStyle

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
      draw_styled_table { |table| style(table) }
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

    def cell_style = super(padding: [ 7, 5 ])

    def style(table)
      table.row(0).text_color = PRIMARY
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
```

## Sezioni commentate

### `header_row` / `table_data` *(privati)*

```ruby
def header_row
  [ "Categoria" ] + labels.map { |label| { content: label, colspan: 2, align: :center } }
end
```

> **IT:** Ogni valore (FEMMINE, MASCHI, ...) occupa due colonne fisiche, conteggio e %, sotto un'unica intestazione con `colspan: 2` di prawn-table: stessa resa della tabella a video (`statistics/_category_cross`). Le etichette vengono dalla prima riga, perché tutte le righe di `Statistics::CategoryCrossBreakdown` hanno le stesse celle nello stesso ordine.
>
> *EN: Each value (FEMMINE, MASCHI, ...) spans two physical columns, count and %, under a single `colspan: 2` prawn-table header: the same look as the on-screen table (`statistics/_category_cross`). Labels come from the first row, since every `Statistics::CategoryCrossBreakdown` row has the same cells in the same order.*

### `column_widths` / `cell_style` *(privati)*

```ruby
def column_widths
  width = @pdf.bounds.width
  value_width = width * (1 - LABEL_RATIO) / (labels.size * 2)
  [ width * LABEL_RATIO ] + Array.new(labels.size * 2, value_width)
end
```

> **IT:** Larghezze calcolate dal numero di etichette, così la stessa classe regge 3 valori oggi e un numero diverso domani. Corpo 10 e padding 7 come da mockup di davo (`.ai/schermate/statistiche_genere_nazionalita_per_categoria.png`): 12 righe più alte restano comunque in mezza pagina A4 orizzontale.
>
> *EN: Widths are computed from the number of labels, so the same class handles 3 values today and a different number tomorrow. Font size 10 and padding 7 as in davo's mockup (`.ai/schermate/statistiche_genere_nazionalita_per_categoria.png`): 12 taller rows still fit half a landscape A4 page.*

### `draw_title` *(privato)*

```ruby
def draw_title
  top = @pdf.cursor
  info = @pdf.image @icon.to_s, at: [ 0, top ], height: ICON_HEIGHT
  @pdf.font("AsapCondensed", style: :bold, size: 14) do
    @pdf.text_box @title, at: [ info.scaled_width + 8, top ], height: ICON_HEIGHT, valign: :center
  end
  @pdf.move_down ICON_HEIGHT + 6
end
```

> **IT:** L'icona è un PNG in `app/assets/images/statistic_prints/` esportato dall'SVG della card a video (`inkscape --export-area-drawing --export-height=192`): Prawn non legge SVG e aggiungere `prawn-svg` per due icone non valeva una dipendenza. Senza `--export-area-drawing` l'icona esce minuscola, perché il disegno occupa solo una parte della tela SVG. Se davo ridisegna l'SVG, il PNG va riesportato. Le due icone hanno proporzioni diverse, quindi il titolo parte da `info.scaled_width`, non da un offset fisso.
>
> *EN: The icon is a PNG in `app/assets/images/statistic_prints/` exported from the on-screen card's SVG (`inkscape --export-area-drawing --export-height=192`): Prawn cannot read SVG and adding `prawn-svg` for two icons was not worth a dependency. Without `--export-area-drawing` the icon comes out tiny, because the drawing covers only part of the SVG canvas. If davo redraws the SVG, the PNG must be re-exported. The two icons have different aspect ratios, so the title starts at `info.scaled_width`, not at a fixed offset.*

### `style` / `separate_groups` *(privati)*

```ruby
def separate_groups(table)
  (3..labels.size * 2).step(2) { |column| table.column(column).rows(1..-1).borders = [ :bottom, :left ] }
end
```

> **IT:** Modifica 01 di davo (2026-10-05) per la leggibilità: intestazioni nel blu primary di Lumen (`158CBA`, lo stesso di `SingleSeriesBarChart::PRIMARY`) e una riga verticale a sinistra di ogni coppia conteggio/% dopo la prima. Le colonne fisiche dei conteggi sono 1, 3, 5...: si parte da 3 perché il primo gruppo è già staccato dalla colonna Categoria.
>
> *EN: davo's "Modifica 01" (2026-10-05) for readability: headers in Lumen's primary blue (`158CBA`, the same as `SingleSeriesBarChart::PRIMARY`) and a vertical rule to the left of every count/% pair after the first. The physical count columns are 1, 3, 5...: it starts at 3 because the first group is already set apart by the Categoria column.*

> **Nota 2026-10-06 / Note:** gli snippet delle sezioni commentate possono mostrare il codice precedente: `draw_title` e la costruzione della tabella (`make_table` + `style_header` + `table.draw`) arrivano ora da `StatisticPrints::TableStyle` (`draw_title(size:)`, `draw_styled_table`, vedi `CodeGuide/StatisticPrints/table_style.md`); il "Codice completo" in cima è quello attuale. / Snippets in the commented sections may show the earlier code: `draw_title` and the table build now come from `StatisticPrints::TableStyle`; the "Codice completo" at the top is current.
