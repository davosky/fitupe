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
