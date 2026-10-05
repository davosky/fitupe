# `StatisticPrints::PercentageTable`

**File:** `app/services/statistic_prints/percentage_table.rb`

## Codice completo

```ruby
module StatisticPrints
  class PercentageTable
    include TableStyle

    def self.draw(...) = new(...).draw

    def initialize(pdf, at:, width:, rows:, label_header: "Gruppo")
      @pdf = pdf
      @at = at
      @width = width
      @rows = rows
      @label_header = label_header
    end

    def draw
      @pdf.bounding_box(@at, width: @width) do
        table = @pdf.make_table(table_data, header: true, width: @width, cell_style: cell_style,
          column_widths: column_widths)
        style_header(table)
        table.draw
      end
    end

    private

    def header_row = [ @label_header, "% sul totale iscritti" ]

    def table_data
      [ header_row ] + @rows.map { |row| [ row[:label], NumberFormatting.percent(row[:percentuale]) ] }
    end

    def column_widths
      { 0 => @width * 0.5, 1 => @width * 0.5 }
    end
  end
end
```

## Sezioni commentate

### `initialize` — perché questa, a differenza di `ComparisonTable`/`SingleYearTable`, riceve `at:`/`width:`

```ruby
def initialize(pdf, at:, width:, rows:, label_header: "Gruppo")
```

> **IT:** `PercentageTable` è l'unica delle tre tabelle di questo batch a ricevere `at:`/`width:` espliciti nel costruttore invece di affidarsi implicitamente al cursore e ai bounds correnti (confronta con `ComparisonTable`/`SingleYearTable`, che non hanno `at:`). Il motivo è nel suo unico uso reale: `PercentageTable` non compare mai da sola in una pagina, compare sempre **a fianco** di un grafico a barre a singola serie nella stessa riga orizzontale (`EmploymentStatusPage#draw_chart_and_percentages`, `ProvisionalRevocationsPage#draw_chart_and_percentages`) — il chiamante calcola un `top` condiviso una volta, lo passa sia a `SingleSeriesBarChart` sia a questa classe con `at:` diversi ma stessa `y`, garantendo che le due colonne partano allineate in alto. Se questa classe leggesse il cursore da sé come `ComparisonTable`, disegnare prima il grafico sposterebbe il cursore e la tabella percentuali partirebbe più in basso.
>
> *EN: `PercentageTable` is the only one of this batch's three tables to receive explicit `at:`/`width:` in its constructor instead of implicitly relying on the current cursor and bounds (compare with `ComparisonTable`/`SingleYearTable`, which have no `at:`). The reason lies in its one real use case: `PercentageTable` never appears alone on a page, it always appears **beside** a single-series bar chart on the same horizontal row (`EmploymentStatusPage#draw_chart_and_percentages`, `ProvisionalRevocationsPage#draw_chart_and_percentages`) — the caller computes a shared `top` once and passes it to both `SingleSeriesBarChart` and this class with different `at:` x-coordinates but the same y, guaranteeing the two columns start aligned at the top. If this class read the cursor on its own like `ComparisonTable` does, drawing the chart first would move the cursor and the percentages table would start lower down.*

### `draw` — `bounding_box` come "confine di larghezza", non come trucco per l'allineamento verticale

```ruby
def draw
  @pdf.bounding_box(@at, width: @width) do
    table = @pdf.make_table(table_data, header: true, width: @width, cell_style: cell_style,
      column_widths: column_widths)
    style_header(table)
    table.draw
  end
end
```

> **IT:** Il `bounding_box` qui non ha `height:` esplicito — è "elastico" nel senso documentato per Prawn (l'altezza/il cursore vengono calcolati dal contenuto disegnato, non ancorati al fondo pagina), ma questo è innocuo in questo caso specifico: la tabella è l'unico contenuto del box, non ci sono elementi successivi nello stesso box il cui posizionamento dipenda da un cursore condiviso, e il chiamante non legge il cursore risultante dopo la chiamata a `draw` (a differenza del pattern "cattura il cursore dentro al blocco" visto altrove per box con `height:` esplicita e grande, es. `NationalityGenderPage#draw_sesso_table`). Il `bounding_box` qui serve solo a un obiettivo: forzare `table.draw` a rispettare `@width` come larghezza massima invece di espandersi fino a `@pdf.bounds.width` dell'intera pagina.
>
> *EN: The `bounding_box` here has no explicit `height:` — it's "stretchy" in the sense documented for Prawn (height/cursor are computed from the drawn content, not anchored to the page bottom), but that's harmless in this specific case: the table is the box's only content, there are no subsequent elements in the same box whose placement depends on a shared cursor, and the caller doesn't read the resulting cursor after the `draw` call (unlike the "capture the cursor inside the block" pattern seen elsewhere for boxes with an explicit, large `height:`, e.g. `NationalityGenderPage#draw_sesso_table`). The `bounding_box` here serves a single purpose: forcing `table.draw` to respect `@width` as a maximum width instead of expanding to the full page's `@pdf.bounds.width`.*

### `header_row`, `table_data`

```ruby
def header_row = [ @label_header, "% sul totale iscritti" ]

def table_data
  [ header_row ] + @rows.map { |row| [ row[:label], NumberFormatting.percent(row[:percentuale]) ] }
end
```

> **IT:** L'etichetta di colonna "% sul totale iscritti" è hardcoded, non un parametro — a differenza di `label_header:`, non è mai stata resa configurabile perché ogni chiamante di questa classe (Attivi/Pensionati, Provvisorie/Revoche) mostra sempre una percentuale sul totale iscritti del periodo, mai su un totale diverso. Solo due colonne (etichetta, percentuale): niente conteggio assoluto, perché quando questa tabella è in uso il conteggio assoluto è già visibile nel grafico a barre a fianco (`SingleSeriesBarChart` senza `percentages:`, che mostra il valore assoluto sopra ogni barra) — mostrarlo due volte sarebbe ridondante. Questo è l'esatto opposto della scelta fatta in `StatisticSpiPrints::AgeClassesPage`, dove `SingleSeriesBarChart` riceve `percentages:` (mostra la percentuale sopra le barre) proprio perché lì non c'è una tabella percentuali a fianco che la fornisca già.
>
> *EN: The column label "% sul totale iscritti" is hardcoded, not a parameter — unlike `label_header:`, it was never made configurable because every caller of this class (Attivi/Pensionati, Provvisorie/Revoche) always shows a percentage of the period's total members, never of a different total. Only two columns (label, percentage): no absolute count, because whenever this table is in use the absolute count is already visible in the adjacent bar chart (`SingleSeriesBarChart` without `percentages:`, which shows the absolute value above each bar) — showing it twice would be redundant. This is the exact opposite of the choice made in `StatisticSpiPrints::AgeClassesPage`, where `SingleSeriesBarChart` receives `percentages:` (showing the percentage above the bars) precisely because there's no adjacent percentages table already providing it there.*

### `column_widths`, `cell_style`, `style_header`

```ruby
def column_widths
  { 0 => @width * 0.5, 1 => @width * 0.5 }
end
```

> **IT:** Due colonne di uguale larghezza (50/50): con solo un'etichetta e una percentuale non c'è bisogno di una ripartizione asimmetrica come nelle 5 colonne di `ComparisonTable` (`0.33/0.19/0.19/0.145/0.145`, dove la colonna etichetta è più larga delle colonne numeriche). `cell_style`/`style_header` sono identici, carattere per carattere, alle controparti in `ComparisonTable` e `SingleYearTable` — inclusa la stessa nota sul `text_color: "000000"` esplicito, necessario per lo stesso motivo (`fill_color` è stato globale del documento, non isolato per tabella) descritto in `CodeGuide/StatisticPrints/comparison_table.md`. Nessuna colorazione condizionale riga per riga: questa tabella, a differenza di `ComparisonTable`, non ha un concetto di "buono/cattivo" (una percentuale sul totale non è né positiva né negativa in sé), quindi non ha un equivalente di `style_rows`/`style_cell`.
>
> *EN: Two equal-width columns (50/50): with just a label and a percentage there's no need for the asymmetric split seen in `ComparisonTable`'s 5 columns (`0.33/0.19/0.19/0.145/0.145`, where the label column is wider than the numeric ones). `cell_style`/`style_header` are identical, character for character, to their counterparts in `ComparisonTable` and `SingleYearTable` — including the same note about explicit `text_color: "000000"`, needed for the same reason (`fill_color` is document-wide state, not table-scoped) described in `CodeGuide/StatisticPrints/comparison_table.md`. No conditional per-row coloring: unlike `ComparisonTable`, this table has no "good/bad" concept (a percentage of the total isn't inherently positive or negative), so it has no equivalent of `style_rows`/`style_cell`.*
