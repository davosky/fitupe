# `StatisticSpiPrints::MotivoCessazionePercentageTable`

**File:** `app/services/statistic_spi_prints/motivo_cessazione_percentage_table.rb`

## Codice completo

```ruby
module StatisticSpiPrints
  # Tabella percentuali "trasposta" per un solo azzonamento: una riga per
  # motivo di cessazione invece di una colonna, a specchio di
  # app/views/statistic_spi/_cessazioni_percentage_table (usata solo per il
  # totale; i comprensori restano larghi come CategoryPercentageTable, una
  # colonna per motivo, perche' li' le righe sono gia' gli azzonamenti).
  class MotivoCessazionePercentageTable
    def self.draw(...) = new(...).draw

    def initialize(pdf, row:, etichette:, title: nil)
      @pdf = pdf
      @row = row
      @etichette = etichette
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

      @pdf.font("AsapCondensed", style: :bold, size: 12) { @pdf.text @title }
      @pdf.move_down 4
    end

    def header_row = [ "Motivo Cessazione", "% sul totale deleghe" ]

    def table_data
      [ header_row ] + @etichette.map { |etichetta| data_row(etichetta) }
    end

    def data_row(etichetta)
      [ etichetta, StatisticPrints::NumberFormatting.percent(@row.percentuali[etichetta]) ]
    end

    def column_widths
      width = @pdf.bounds.width
      { 0 => width * 0.65, 1 => width * 0.35 }
    end

    def cell_style
      {
        font: "AsapCondensed", size: 9, text_color: "000000", borders: [ :bottom ], border_color: "DDDDDD",
        padding: [ 4, 6 ]
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

### Commento di classe

```ruby
# Tabella percentuali "trasposta" per un solo azzonamento: una riga per
# motivo di cessazione invece di una colonna, a specchio di
# app/views/statistic_spi/_cessazioni_percentage_table (usata solo per il
# totale; i comprensori restano larghi come CategoryPercentageTable, una
# colonna per motivo, perche' li' le righe sono gia' gli azzonamenti).
class MotivoCessazionePercentageTable
```

> **IT:** Il nome suggerisce una classe specifica per `CessazioniBreakdown`, e lo è nel nome (`MotivoCessazione`) e nell'header fisso (`"Motivo Cessazione", "% sul totale deleghe"`), ma **non** è implementata come sottoclasse o composizione di `CategoryPercentageTable`: è una classe indipendente, verificato leggendo entrambi i file per intero. È una **specializzazione per orientamento**, non per dominio: la vera differenza rispetto a `CategoryPercentageTable` è che qui `@row` è **una** singola riga (parametro `row:`, singolare) mentre `CategoryPercentageTable` prende `rows:` (plurale) — questa tabella trasforma N etichette in N **righe** della tabella (con l'azzonamento fisso, mostrato solo nel `title:` esterno), l'altra trasforma N etichette in N **colonne** per M righe di azzonamento. Con `rows: [singola_riga]` e le etichette come colonne, `CategoryPercentageTable` produrrebbe una tabella larghissima e alta una riga sola — la trasposizione qui è quindi una scelta di leggibilità per il caso "un solo azzonamento", non una necessità di dati diversi.
>
> *EN: The name suggests a class specific to `CessazioniBreakdown`, and it is by name (`MotivoCessazione`) and fixed header (`"Motivo Cessazione", "% sul totale deleghe"`), but it's **not** implemented as a subclass or composition of `CategoryPercentageTable`: it's an independent class, confirmed by reading both files in full. It's a specialization **by orientation**, not by domain: the real difference from `CategoryPercentageTable` is that here `@row` is **one** single row (`row:` parameter, singular) whereas `CategoryPercentageTable` takes `rows:` (plural) — this table turns N labels into N table **rows** (with the zoning shown only once, in the external `title:`), the other turns N labels into N **columns** across M zoning rows. With `rows: [single_row]` and labels as columns, `CategoryPercentageTable` would produce a very wide, one-row-tall table — the transposition here is a readability choice for the "single zoning" case, not a data-shape necessity.*

### Perché non riusare `CategoryPercentageTable` con una riga sola

> **IT:** Tecnicamente `CategoryPercentageTable.draw(@pdf, rows: [result.totale], etichette: ETICHETTE)` avrebbe funzionato senza errori — `CessazioniBreakdown::Row` espone gli stessi campi (`zoning`, `percentuali`) che `CategoryPercentageTable#data_row` si aspetta. La scelta di scrivere una classe apposita invece è puramente di *layout*: 6 etichette come 6 colonne strette (`CategoryPercentageTable`) sono difficili da leggere quando c'è una sola riga di dati, mentre 6 etichette come 6 righe con due colonne larghe (questa classe, `65%`/`35%`) sono più leggibili — coerente con `CategoryTable::column_widths`/`CategoryPercentageTable::column_widths`, dove il numero di colonne cresce con `@etichette.size`: più etichette, più strette le colonne, fino a diventare illeggibili con una singola riga. `CessazioniPage` sceglie quindi la trasposizione **solo** per il totale (una riga) e tiene il layout a colonne (`CategoryPercentageTable`) per i comprensori (più righe, dove la trasposizione produrrebbe l'effetto opposto: pochissime colonne larghissime).
>
> *EN: Technically `CategoryPercentageTable.draw(@pdf, rows: [result.totale], etichette: ETICHETTE)` would have worked without errors — `CessazioniBreakdown::Row` exposes the same fields (`zoning`, `percentuali`) that `CategoryPercentageTable#data_row` expects. The choice to write a dedicated class instead is purely about *layout*: 6 labels as 6 narrow columns (`CategoryPercentageTable`) are hard to read when there's only one row of data, while 6 labels as 6 rows with two wide columns (this class, `65%`/`35%`) read better — consistent with `CategoryTable::column_widths`/`CategoryPercentageTable::column_widths`, where column count grows with `@etichette.size`: more labels, narrower columns, eventually unreadable with a single row. `CessazioniPage` therefore chooses transposition **only** for the total (one row) and keeps the column layout (`CategoryPercentageTable`) for comprensori (multiple rows, where transposition would have the opposite effect: very few, very wide columns).*

### `initialize`, `table_data`, `data_row` *(privati)*

```ruby
def initialize(pdf, row:, etichette:, title: nil)
  @pdf = pdf
  @row = row
  @etichette = etichette
  @title = title
end

def header_row = [ "Motivo Cessazione", "% sul totale deleghe" ]

def table_data
  [ header_row ] + @etichette.map { |etichetta| data_row(etichetta) }
end

def data_row(etichetta)
  [ etichetta, StatisticPrints::NumberFormatting.percent(@row.percentuali[etichetta]) ]
end
```

> **IT:** L'header `"% sul totale deleghe"` (non "% sul totale" generico) fissa nel testo dell'intestazione la stessa nota che nella guida `StatisticSpi::CessazioniBreakdown` è documentata come non ovvia dal codice: le percentuali qui **non sommano al 100%**, perché il denominatore è `deleghe_totale` (tutte le deleghe del periodo), non la somma dei sei motivi di cessazione. Scrivere il denominatore nell'header è l'unico posto in questa classe dove quel fatto viene comunicato all'utente finale del PDF — il codice stesso (`data_row`) si limita a leggere `@row.percentuali[etichetta]`, già calcolata a monte da `CessazioniBreakdown#build_row` con quel denominatore, senza rifare il calcolo. `table_data` itera su `@etichette` (non su `@row.percentuali.keys`), garantendo lo stesso ordine fisso di `CessazioniBreakdown::ETICHETTE` indipendentemente dall'ordine di costruzione dell'hash.
>
> *EN: The header `"% sul totale deleghe"` (not a generic "% of total") bakes into the header text the same fact that `CodeGuide/StatisticSpi/cessazioni_breakdown.md` documents as not obvious from the code: the percentages here **don't add up to 100%**, because the denominator is `deleghe_totale` (all of the period's delegations), not the sum of the six cessation reasons. Writing the denominator into the header is the only place in this class where that fact reaches the PDF's end reader — the code itself (`data_row`) just reads `@row.percentuali[etichetta]`, already computed upstream by `CessazioniBreakdown#build_row` with that denominator, without redoing the math. `table_data` iterates over `@etichette` (not `@row.percentuali.keys`), guaranteeing the same fixed order as `CessazioniBreakdown::ETICHETTE` regardless of the hash's construction order.*

### `column_widths`, `cell_style` *(privati)*

```ruby
def column_widths
  width = @pdf.bounds.width
  { 0 => width * 0.65, 1 => width * 0.35 }
end

def cell_style
  {
    font: "AsapCondensed", size: 9, text_color: "000000", borders: [ :bottom ], border_color: "DDDDDD",
    padding: [ 4, 6 ]
  }
end
```

> **IT:** Due sole colonne con proporzioni fisse (`65%`/`35%`) invece del calcolo dinamico `(width - label_width) / @etichette.size` visto in `CategoryTable`/`CategoryPercentageTable`: qui il numero di colonne è sempre 2 per costruzione (l'orientamento trasposto lo garantisce), quindi non serve dividere per `@etichette.size` — è `@etichette.size` a determinare il numero di **righe**, non di colonne. `cell_style` usa `size: 9` (contro `size: 8` di `CategoryTable`/`CategoryPercentageTable`): con solo due colonne larghe c'è più spazio per un font leggermente più leggibile, mentre le tabelle a N colonne strette devono restare più piccole per non far traboccare il testo delle etichette lunghe (es. "Cessazione Posizione Pensionistica").
>
> *EN: Just two columns with fixed proportions (`65%`/`35%`) instead of the dynamic `(width - label_width) / @etichette.size` calculation seen in `CategoryTable`/`CategoryPercentageTable`: here the column count is always 2 by construction (the transposed orientation guarantees it), so there's no need to divide by `@etichette.size` — `@etichette.size` instead determines the number of **rows**, not columns. `cell_style` uses `size: 9` (vs. `CategoryTable`/`CategoryPercentageTable`'s `size: 8`): with only two wide columns there's more room for a slightly more readable font, while the N-narrow-columns tables need to stay smaller so long label text (e.g. "Cessazione Posizione Pensionistica") doesn't overflow.*
