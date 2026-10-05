# `StatisticSpiPrints::CategoryTable`

**File:** `app/services/statistic_spi_prints/category_table.rb`

## Codice completo

```ruby
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
```

## Sezioni commentate

### Commento di classe

```ruby
# Tabella conteggi per categoria (etichette generiche, es. tipologia di
# delega o motivo di cessazione) + totale. Le colonne sono lette da
# un elenco di etichette passato dal chiamante (es.
# StatisticSpi::TipologieDelegaBreakdown::ETICHETTE), cosi' restano in sync
# se un domani cambiano le categorie.
class CategoryTable
    def self.draw(...) = new(...).draw
```

> **IT:** L'unica tabella generica della cartella (le altre — `MultipleDelegationsTable`, `ProvvisorieTable`, `MotivoCessazionePercentageTable` — hanno colonne hardcoded per la loro forma dati specifica). Usata in due pagine, `TipologieDelegaPage` e `CessazioniPage` (confermato via `grep -rn "CategoryTable\." app/services/statistic_spi_prints/`), entrambe per **sia** la riga "totale" sia le righe "comprensori" — a differenza di `CategoryPercentageTable`/`MotivoCessazionePercentageTable`, che si dividono il lavoro (una per il totale, una per i comprensori). `@etichette` non è mai hardcoded qui dentro: viene sempre da una costante esterna (`TipologieDelegaBreakdown::ETICHETTE` o `CessazioniBreakdown::ETICHETTE`), che è anche l'ordine delle colonne — la tabella non ha idea del dominio, si limita a iterare quello che riceve.
>
> *EN: The only generic table in this folder (the others — `MultipleDelegationsTable`, `ProvvisorieTable`, `MotivoCessazionePercentageTable` — have columns hardcoded to their specific data shape). Used in two pages, `TipologieDelegaPage` and `CessazioniPage` (confirmed via `grep -rn "CategoryTable\." app/services/statistic_spi_prints/`), for **both** the "totale" row and the "comprensori" rows — unlike `CategoryPercentageTable`/`MotivoCessazionePercentageTable`, which split the work (one for the total, one for comprensori). `@etichette` is never hardcoded here: it always comes from an external constant (`TipologieDelegaBreakdown::ETICHETTE` or `CessazioniBreakdown::ETICHETTE`), which also defines column order — the table has no domain knowledge of its own, it just iterates whatever it's handed.*

### `initialize`, `draw`

```ruby
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
```

> **IT:** `total_label:` di default è `"totale"` ma `CessazioniPage` lo sovrascrive a `"totale cessazioni"` — l'unico parametro configurabile che non è puro dato, serve a rendere l'intestazione dell'ultima colonna leggibile senza dover ripetere "cessazioni" per ogni etichetta. `@pdf.make_table` (non `@pdf.table`) crea l'oggetto tabella senza disegnarlo subito: serve la gemma separata `prawn-table` (non inclusa in Prawn core), e il motivo per usare `make_table` invece di `table` è poter chiamare `style_header(table)` per modificare `table.row(0)` **prima** di `table.draw` — con `@pdf.table` la tabella verrebbe disegnata immediatamente, senza possibilità di post-elaborare lo stile dell'header.
>
> *EN: `total_label:` defaults to `"totale"` but `CessazioniPage` overrides it to `"totale cessazioni"` — the one configurable parameter that isn't pure data, it exists to keep the last column's header readable without repeating "cessazioni" for every label. `@pdf.make_table` (not `@pdf.table`) builds the table object without drawing it immediately: it requires the separate `prawn-table` gem (not part of Prawn core), and the reason to use `make_table` over `table` is being able to call `style_header(table)` to modify `table.row(0)` **before** `table.draw` — with `@pdf.table`, the table would be drawn right away, with no chance to post-process the header's style.*

### `header_row`, `table_data`, `data_row` *(privati)*

```ruby
def header_row = [ "Azzonamento" ] + @etichette + [ @total_label ]

def table_data
  [ header_row ] + @rows.map { |row| data_row(row) }
end

def data_row(row)
  [ row.zoning.descrizione_azzonamento ] + @etichette.map { |etichetta| StatisticPrints::NumberFormatting.count(row.totali[etichetta]) } +
    [ StatisticPrints::NumberFormatting.count(row.totale) ]
end
```

> **IT:** `data_row` legge `row.totali[etichetta]` — un hash, non un metodo per etichetta — quindi qualsiasi `Row` struct (di `TipologieDelegaBreakdown` o `CessazioniBreakdown`) va bene finché espone `zoning`, `totali` (hash `{etichetta => count}`) e `totale`: il contratto è strutturale (duck typing), non nominale. `@etichette.map { |etichetta| row.totali[etichetta] }` itera nell'ordine di `@etichette`, non nell'ordine delle chiavi dell'hash `totali` — se `totali` fosse costruito in un ordine diverso (poco probabile dato che entrambi i breakdown lo costruiscono con `ETICHETTE.index_with { ... }`), l'ordine delle colonne resterebbe comunque quello di `@etichette`.
>
> *EN: `data_row` reads `row.totali[etichetta]` — a hash, not a per-label method — so any `Row` struct (from `TipologieDelegaBreakdown` or `CessazioniBreakdown`) works as long as it exposes `zoning`, `totali` (a `{etichetta => count}` hash), and `totale`: the contract is structural (duck typing), not nominal. `@etichette.map { |etichetta| row.totali[etichetta] }` iterates in `@etichette`'s order, not the `totali` hash's key order — if `totali` were built in a different order (unlikely, since both breakdowns build it with `ETICHETTE.index_with { ... }`), column order would still follow `@etichette`.*

### `column_widths`, `cell_style`, `style_header` *(privati)*

```ruby
def column_widths
  width = @pdf.bounds.width
  label_width = width * 0.17
  totale_width = width * 0.12
  etichetta_width = (width - label_width - totale_width) / @etichette.size
  widths = { 0 => label_width, (@etichette.size + 1) => totale_width }
  @etichette.each_index { |index| widths[index + 1] = etichetta_width }
  widths
end

def cell_style
  {
    font: "AsapCondensed", size: 8, text_color: "000000", borders: [ :bottom ], border_color: "DDDDDD",
    padding: [ 4, 4 ]
  }
end
```

> **IT:** `column_widths` calcola le larghezze in percentuale di `@pdf.bounds.width` (17%/12% fissi per etichetta-riga e totale, il resto diviso equamente tra `@etichette.size` colonne) invece di larghezze fisse in punti: la tabella si adatta sia alla larghezza piena pagina (`draw_totale_column`/`draw_comprensori_column` la chiamano dentro una `bounding_box` di metà pagina in landscape) sia a un numero variabile di etichette (5 per `TipologieDelegaBreakdown`, 6 per `CessazioniBreakdown`) senza dover essere parametrizzata esplicitamente sulla larghezza. `cell_style` imposta esplicitamente `text_color: "000000"`: senza questo, `prawn-table` erediterebbe il colore di riempimento correntemente attivo su `@pdf` (`fill_color` è stato persino impostato a un altro colore da un chiamante poco prima nello stesso documento — vedi la nota di sicurezza in `CodeGuide/StatisticPrints`) — omettere `text_color` avrebbe reso il testo della tabella dipendente dall'ultimo `fill_color` lasciato attivo da qualunque cosa sia stata disegnata prima, un bug silente e difficile da notare in anteprima ma non in stampa a colori.
>
> *EN: `column_widths` computes widths as percentages of `@pdf.bounds.width` (fixed 17%/12% for the label and total columns, the rest split evenly across `@etichette.size` columns) instead of fixed point widths: the table adapts both to full-page vs. half-page width (`draw_totale_column`/`draw_comprensori_column` call it inside a half-page-wide `bounding_box` in landscape) and to a variable number of labels (5 for `TipologieDelegaBreakdown`, 6 for `CessazioniBreakdown`) without needing to be explicitly parameterized on width. `cell_style` explicitly sets `text_color: "000000"`: without this, `prawn-table` would inherit whatever fill color is currently active on `@pdf` (`fill_color` is document-wide state, possibly left set to something else by a caller just before, elsewhere in the same document) — omitting `text_color` would make the table's text depend on the last `fill_color` left active by whatever was drawn previously, a silent bug easy to miss on screen but not in a color print.*

> **Nota 2026-10-05 / Note:** lo snippet qui sopra mostra il codice precedente al refactor: `cell_style` e `style_header` arrivano ora da `StatisticPrints::TableStyle` (vedi `CodeGuide/StatisticPrints/table_style.md`); il "Codice completo" in cima è quello attuale. / The snippet above shows the pre-refactor code: `cell_style` and `style_header` now come from `StatisticPrints::TableStyle`; the "Codice completo" at the top is current.
