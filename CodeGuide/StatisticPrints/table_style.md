# `StatisticPrints::TableStyle`

**File:** `app/services/statistic_prints/table_style.rb`

## Codice completo

```ruby
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
```

## Sezioni commentate

### `cell_style`, `style_header`

```ruby
def cell_style(size: 10, padding: [ 5, 6 ])
```

> **IT:** Stesso refactor di `PageLayout` (vedi `page_layout.md`), per le 9 tabelle prawn-table dei due fascicoli: lo stile era identico ovunque tranne corpo e padding. Il default (10, `[5, 6]`) è quello delle tabelle Attivi; una tabella diversa ridefinisce `cell_style` con `super`, ad esempio `def cell_style = super(size: 8, padding: [ 4, 4 ])` nelle tabelle SPI più fitte. `super` funziona perché il metodo arriva da un modulo incluso. `style_header` è uguale per tutte; `CategoryCrossTable` lo chiama e poi aggiunge il blu e i separatori.
>
> *EN: Same refactor as `PageLayout` (see `page_layout.md`), for the 9 prawn-table tables of the two booklets: the style was identical everywhere except font size and padding. The default (10, `[5, 6]`) is the Attivi tables' one; a different table redefines `cell_style` through `super`, e.g. `def cell_style = super(size: 8, padding: [ 4, 4 ])` in the denser SPI tables. `super` works because the method comes from an included module. `style_header` is the same for all; `CategoryCrossTable` calls it and then adds the blue and the separators.*

### `draw_title`, `draw_styled_table`

```ruby
def draw_styled_table(width: @pdf.bounds.width)
```

> **IT:** Aggiunti il 2026-10-06: il titolo sopra la tabella e la sequenza `make_table` → `style_header` → `table.draw` erano copiati identici in 8 tabelle. `draw_title` legge `@title` (non disegna nulla se è vuoto) e ha corpo 12 di default; le tabelle con corpo 13 scrivono `def draw_title = super(size: 13)`, mentre `CategoryCrossTable` lo ridefinisce del tutto (icona + titolo). `draw_styled_table` usa `table_data` e `column_widths` della classe che include il modulo e passa la tabella al blocco per gli stili in più (`ComparisonTable` colora le differenze, `CategoryCrossTable` aggiunge blu e separatori); `PercentageTable` passa `width:` perché disegna dentro un `bounding_box`.
>
> *EN: Added 2026-10-06: the title above the table and the `make_table` → `style_header` → `table.draw` sequence were copied verbatim in 8 tables. `draw_title` reads `@title` (draws nothing when blank), size 12 by default; size-13 tables write `def draw_title = super(size: 13)`, while `CategoryCrossTable` overrides it entirely (icon + title). `draw_styled_table` uses the including class's `table_data` and `column_widths` and yields the table for extra styling; `PercentageTable` passes `width:` because it draws inside a `bounding_box`.*
