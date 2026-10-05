# `StatisticPrints::SingleYearTable`

**File:** `app/services/statistic_prints/single_year_table.rb`

## Codice completo

```ruby
module StatisticPrints
  class SingleYearTable
    include TableStyle

    def self.draw(...) = new(...).draw

    def initialize(pdf, rows:, mese:, anno:, label_header:, title: nil)
      @pdf = pdf
      @rows = rows
      @mese = mese
      @anno = anno
      @label_header = label_header
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

      @pdf.font("AsapCondensed", style: :bold, size: 13) { @pdf.text @title }
      @pdf.move_down 4
    end

    def header_row = [ @label_header, "#{@mese} #{@anno}", "%" ]

    def table_data
      [ header_row ] + @rows.map { |row| data_row(row) }
    end

    def data_row(row)
      [ row[:label], NumberFormatting.count(row[:count]), NumberFormatting.percent(row[:percentuale]) ]
    end

    def column_widths
      width = @pdf.bounds.width
      { 0 => width * 0.4, 1 => width * 0.3, 2 => width * 0.3 }
    end
  end
end
```

## Sezioni commentate

### Perché non ha equivalente lato `StatisticSpiPrints`

> **IT:** A differenza di `ComparisonTable` (riusata da `StatisticSpiPrints::TotalsPage`/`MultipleDelegationsTable`), `PieChart`, `SingleSeriesBarChart` e `NumberFormatting`, questa classe non compare in nessun file sotto `app/services/statistic_spi_prints/` — né riusata direttamente né reimplementata con un proprio equivalente. La ragione è nella sua premessa: `SingleYearTable` esiste per dati che vivono solo nell'anno corrente, senza uno storico anno su anno (Sesso, Nazionalità, Fasce di età/anzianità Attivi). Ogni sezione della pagina SPI, invece, o mostra sempre un confronto anno su anno (`TotalMembersComparison`, dove `ComparisonTable` basta) oppure è già coperta da una tabella su misura con colonne diverse da "etichetta/conteggio/percentuale" (`MultipleDelegationsTable` con le sue colonne Doppia/Tripla/Quadrupla/Quintupla, `ProvvisorieTable`, `CategoryTable`) — nessuna sezione SPI ha per ora la forma esatta "una riga, un conteggio, una percentuale, un solo anno" che questa classe serve.
>
> *EN: Unlike `ComparisonTable` (reused by `StatisticSpiPrints::TotalsPage`/`MultipleDelegationsTable`), `PieChart`, `SingleSeriesBarChart`, and `NumberFormatting`, this class appears in no file under `app/services/statistic_spi_prints/` — neither reused directly nor reimplemented with its own equivalent. The reason lies in its premise: `SingleYearTable` exists for data that only lives in the current year, with no year-over-year history (Sesso, Nazionalità, Attivi's age/seniority bands). Every SPI page section, by contrast, either always shows a year-over-year comparison (`TotalMembersComparison`, where `ComparisonTable` suffices) or is already covered by a purpose-built table with different columns than "label/count/percentage" (`MultipleDelegationsTable` with its Doppia/Tripla/Quadrupla/Quintupla columns, `ProvvisorieTable`, `CategoryTable`) — no SPI section currently has the exact "one row, one count, one percentage, a single year" shape this class serves.*

### `initialize` — `label_header:` obbligatorio, non un default come nelle sorelle

```ruby
def initialize(pdf, rows:, mese:, anno:, label_header:, title: nil)
```

> **IT:** In `ComparisonTable` e `PercentageTable`, `label_header:` ha un default (`"Azzonamento"`, `"Gruppo"`); qui è **obbligatorio**, senza valore predefinito. Non è una svista: i tre chiamanti reali di questa classe (`WorkStatusAgePage`, `NationalityGenderPage` per Sesso e per Nazionalità, `ProvisionalRevocationsPage`) hanno intestazioni di colonna semanticamente diverse ("Sesso", "Nazionalità", "Tipologia") senza un caso comune dominante che giustifichi un default — a differenza di `ComparisonTable`, dove "Azzonamento" copre la maggioranza dei chiamanti e `label_header:` è l'eccezione.
>
> *EN: In `ComparisonTable` and `PercentageTable`, `label_header:` has a default (`"Azzonamento"`, `"Gruppo"`); here it's **required**, with no default value. It's not an oversight: this class's three real callers (`WorkStatusAgePage`, `NationalityGenderPage` for both Sesso and Nazionalità, `ProvisionalRevocationsPage`) have semantically different column headers ("Sesso", "Nazionalità", "Tipologia") with no dominant common case to justify a default — unlike `ComparisonTable`, where "Azzonamento" covers most callers and `label_header:` is the exception.*

### `draw`, l'assenza di `at:`/`width:` e il pattern di allineamento in `NationalityGenderPage`

```ruby
def draw
  draw_title
  table = @pdf.make_table(table_data, header: true, width: @pdf.bounds.width, cell_style: cell_style,
    column_widths: column_widths)
  style_header(table)
  table.draw
end
```

> **IT:** Come `ComparisonTable`, questa classe non riceve `at:`/`width:`: disegna dal cursore corrente, larga quanto `@pdf.bounds.width`. Questo è ciò che permette a `NationalityGenderPage#draw_columns` un pattern di allineamento non banale: per affiancare due tabelle Sesso/Nazionalità di altezza diversa (righe in numero diverso) e poi disegnare due grafici a torta allineati in basso, la pagina avvolge **ogni chiamata** a `SingleYearTable.draw` in un proprio `@pdf.bounding_box([x, top], width: colonna_width, height: top)` — un `height:` esplicito e deliberatamente enorme (pari a `top`, la distanza dal cursore corrente al fondo pagina), che rende il box "non elastico" nel senso di non rischiare mai di sconfinare, ma con un effetto collaterale: dopo che il blocco si chiude, il cursore principale del documento avanza fino al **fondo** di quel box enorme, non fino a dove la tabella è realmente finita. Per questo `draw_sesso_table`/`draw_nazionalita_table` catturano `cursor_after = @pdf.cursor` **dentro** al blocco, prima che si chiuda, e lo restituiscono esplicitamente — è l'unico modo per sapere dove la tabella è realmente terminata e poter allineare i due grafici a torta successivi sullo stesso `top` (`[sesso_bottom, nazionalita_bottom].compact.min`).
>
> *EN: Like `ComparisonTable`, this class receives no `at:`/`width:`: it draws from the current cursor, as wide as `@pdf.bounds.width`. This is what enables a non-trivial alignment pattern in `NationalityGenderPage#draw_columns`: to place two Sesso/Nazionalità tables of different height (different row counts) side by side and then draw two pie charts aligned at the bottom, the page wraps **each call** to `SingleYearTable.draw` in its own `@pdf.bounding_box([x, top], width: column_width, height: top)` — an explicit, deliberately huge `height:` (equal to `top`, the distance from the current cursor to the page bottom), which makes the box "non-stretchy" in the sense of never risking overflow, but with a side effect: once the block closes, the document's main cursor advances all the way to the **bottom** of that huge box, not to wherever the table actually ended. That's why `draw_sesso_table`/`draw_nazionalita_table` capture `cursor_after = @pdf.cursor` **inside** the block, before it closes, and return it explicitly — it's the only way to know where the table actually ended and to align the two subsequent pie charts on the same `top` (`[sesso_bottom, nazionalita_bottom].compact.min`).*

### `header_row`, `data_row`, `column_widths`, `cell_style`, `style_header`

```ruby
def header_row = [ @label_header, "#{@mese} #{@anno}", "%" ]

def data_row(row)
  [ row[:label], NumberFormatting.count(row[:count]), NumberFormatting.percent(row[:percentuale]) ]
end

def column_widths
  width = @pdf.bounds.width
  { 0 => width * 0.4, 1 => width * 0.3, 2 => width * 0.3 }
end
```

> **IT:** Header a 3 colonne (etichetta, conteggio dell'unico anno, percentuale) contro le 5 di `ComparisonTable`: manca ogni riferimento all'anno precedente, coerentemente con l'assenza di `anno_precedente:` tra gli argomenti di `initialize` — questa classe non potrebbe calcolare un confronto anche volendo, l'informazione semplicemente non le arriva mai. `column_widths` (0.4/0.3/0.3) è più equilibrato di quello di `ComparisonTable` (0.33/0.19/0.19/0.145/0.145): con solo tre colonne invece di cinque, non serve comprimere le colonne numeriche quanto in una tabella a 5 colonne. `cell_style` e `style_header` sono, ancora una volta, identici carattere per carattere alle altre due tabelle — la stessa nota su `text_color: "000000"` esplicito (immunità dallo stato globale di `fill_color`) vale identica qui, vedi `CodeGuide/StatisticPrints/comparison_table.md`.
>
> *EN: A 3-column header (label, single-year count, percentage) versus `ComparisonTable`'s 5: there's no reference to a previous year at all, consistent with the absence of `anno_precedente:` among `initialize`'s arguments — this class couldn't compute a comparison even if it wanted to, the information simply never reaches it. `column_widths` (0.4/0.3/0.3) is more balanced than `ComparisonTable`'s (0.33/0.19/0.19/0.145/0.145): with only three columns instead of five, there's no need to compress the numeric columns as much as in a 5-column table. `cell_style` and `style_header` are, once again, character-for-character identical to the other two tables — the same note about explicit `text_color: "000000"` (immunity from `fill_color`'s document-wide state) applies here unchanged, see `CodeGuide/StatisticPrints/comparison_table.md`.*
