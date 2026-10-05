# `StatisticPrints::ComparisonTable`

**File:** `app/services/statistic_prints/comparison_table.rb`

## Codice completo

```ruby
module StatisticPrints
  class ComparisonTable
    include TableStyle

    DANGER = "FF4136"
    SUCCESS = "28B62C"

    def self.draw(...) = new(...).draw

    def initialize(pdf, rows:, mese:, anno:, anno_precedente:, title: nil, label_header: "Azzonamento",
      metric_label: "iscritti")
      @pdf = pdf
      @title = title
      @rows = rows
      @mese = mese
      @anno = anno
      @anno_precedente = anno_precedente
      @label_header = label_header
      @metric_label = metric_label
    end

    def draw
      draw_title
      table = @pdf.make_table(table_data, header: true, width: @pdf.bounds.width, cell_style: cell_style,
        column_widths: column_widths)
      style_header(table)
      style_rows(table)
      table.draw
    end

    private

    def draw_title
      return if @title.blank?

      @pdf.font("AsapCondensed", style: :bold, size: 13) { @pdf.text @title }
      @pdf.move_down 4
    end

    def header_row
      [ @label_header, "#{@mese} #{@anno_precedente}", "#{@mese} #{@anno}", @metric_label, "%" ]
    end

    def table_data
      [ header_row ] + @rows.map { |row| data_row(row) }
    end

    def data_row(row)
      [
        row[:label], NumberFormatting.count(row[:count_precedente]), NumberFormatting.count(row[:count_anno]),
        NumberFormatting.count(row[:diff]), NumberFormatting.percent(row[:diff_percent])
      ]
    end

    def column_widths
      width = @pdf.bounds.width
      { 0 => width * 0.33, 1 => width * 0.19, 2 => width * 0.19, 3 => width * 0.145, 4 => width * 0.145 }
    end

    def style_rows(table)
      @rows.each_with_index do |row, index|
        color = row[:diff].negative? ? DANGER : SUCCESS
        (3..4).each { |col| style_cell(table.row(index + 1).column(col), color) }
      end
    end

    def style_cell(cell, color)
      cell.text_color = color
      cell.font_style = :bold
    end
  end
end
```

## Sezioni commentate

### Le tre tabelle della cartella: quale usare quando

> **IT:** `statistic_prints` ha tre classi tabella molto simili nella forma (`draw_title` opzionale + `make_table` + stile header + colori righe), ma con contratti diversi che riflettono tre forme di dato diverse: `ComparisonTable` mostra un confronto anno su anno per riga (`count_precedente`/`count_anno`/`diff`/`diff_percent`, 5 colonne, colorata in verde/rosso in base al segno di `diff`) — usata da `RegionalPage`, `CategoriesPage`, `EmploymentStatusPage`, `MembershipTypesPage`. `PercentageTable` mostra una percentuale sul totale per riga (`percentuale`, 2 colonne, nessuna colorazione condizionale) — usata quando accanto a un grafico a barre a singola serie serve solo la % di ciascuna categoria, non un confronto temporale (`EmploymentStatusPage`, `ProvisionalRevocationsPage`). `SingleYearTable` mostra un conteggio semplice per riga (`count`/`percentuale`, 3 colonne, nessun confronto, nessuna colorazione) — usata per dati che esistono solo nell'anno corrente, senza uno storico da confrontare (`WorkStatusAgePage`, `NationalityGenderPage`). La domanda per scegliere quale usare in una nuova pagina: il dato ha uno storico anno su anno da mostrare (`ComparisonTable`), oppure è un'istantanea del periodo corrente — con (`SingleYearTable`) o senza (`PercentageTable`, quando il conteggio assoluto è già visibile nel grafico affiancato) il conteggio assoluto?
>
> *EN: `statistic_prints` has three table classes that are very similar in shape (an optional `draw_title` + `make_table` + header styling + row coloring), but with different contracts reflecting three different data shapes: `ComparisonTable` shows a year-over-year comparison per row (`count_precedente`/`count_anno`/`diff`/`diff_percent`, 5 columns, colored green/red by the sign of `diff`) — used by `RegionalPage`, `CategoriesPage`, `EmploymentStatusPage`, `MembershipTypesPage`. `PercentageTable` shows a percentage of the total per row (`percentuale`, 2 columns, no conditional coloring) — used when, next to a single-series bar chart, only each category's % is needed, not a time comparison (`EmploymentStatusPage`, `ProvisionalRevocationsPage`). `SingleYearTable` shows a plain count per row (`count`/`percentuale`, 3 columns, no comparison, no coloring) — used for data that only exists for the current year, with no history to compare against (`WorkStatusAgePage`, `NationalityGenderPage`). The question to pick which to use in a new page: does the data have year-over-year history to show (`ComparisonTable`), or is it a snapshot of the current period — with (`SingleYearTable`) or without (`PercentageTable`, when the absolute count is already visible in an adjacent chart) the absolute count?*

### `initialize` — `label_header:` e `metric_label:` come punti di estensione

```ruby
def initialize(pdf, rows:, mese:, anno:, anno_precedente:, title: nil, label_header: "Azzonamento",
  metric_label: "iscritti")
```

> **IT:** `label_header:` e `metric_label:` hanno un default pensato per il caso più comune della pagina Attivi (una riga per azzonamento, la metrica è sempre "iscritti"), ma sono entrambi sovrascrivibili — `EmploymentStatusPage` passa `label_header: "Gruppo"` perché lì le righe sono "Attivi"/"Pensionati", non azzonamenti. È proprio `metric_label:` che rende possibile il riuso cross-modulo da `StatisticSpiPrints::TotalsPage`, che chiama questa stessa classe due volte nella stessa pagina passando `metric_label: "iscritti"` e `metric_label: "deleghe"` per due colonne affiancate — senza `metric_label:` configurabile, la classe avrebbe dovuto essere duplicata o modificata per accogliere la distinzione SPI "iscritti vs deleghe" (vedi `CodeGuide/StatisticSpi/README.md` per il perché quella distinzione esiste).
>
> *EN: `label_header:` and `metric_label:` default to the most common Attivi-page case (one row per zoning, the metric is always "iscritti"), but both are overridable — `EmploymentStatusPage` passes `label_header: "Gruppo"` because there the rows are "Attivi"/"Pensionati", not zonings. It's `metric_label:` specifically that makes cross-module reuse from `StatisticSpiPrints::TotalsPage` possible: it calls this same class twice on the same page, passing `metric_label: "iscritti"` and `metric_label: "deleghe"` for two side-by-side columns — without a configurable `metric_label:`, the class would have had to be duplicated or modified to accommodate the SPI "iscritti vs deleghe" distinction (see `CodeGuide/StatisticSpi/README.md` for why that distinction exists).*

### `draw`, l'assenza di `at:`

```ruby
def draw
  draw_title
  table = @pdf.make_table(table_data, header: true, width: @pdf.bounds.width, cell_style: cell_style,
    column_widths: column_widths)
  style_header(table)
  style_rows(table)
  table.draw
end
```

> **IT:** A differenza dei grafici (`BarChart`, `PieChart`, `SingleSeriesBarChart`), questa classe **non** riceve `at:`: disegna sempre a partire dal cursore corrente (`table.draw` internamente usa `@pdf.cursor`) e usa `@pdf.bounds.width` come larghezza, mai un `width:` passato esplicitamente. Questo funziona per il caso più comune (tabella a piena larghezza, sequenziale nel flusso della pagina), ma quando un chiamante ha bisogno di posizionarla in una colonna stretta (es. `StatisticSpiPrints::TotalsPage`, due colonne affiancate iscritti/deleghe) deve avvolgerla in un `@pdf.bounding_box([x, top], width: column_width, height: top)` — è il `bounding_box` del chiamante a restringere `@pdf.bounds.width`, non un parametro di questa classe. `table.draw` con `header: true` e nessun controllo esplicito di spazio residuo può anche spingere la tabella oltre il fondo pagina, spezzandola automaticamente su una nuova pagina con l'intestazione ripetuta — comportamento nativo di `prawn-table`, mai disattivato in questo file.
>
> *EN: Unlike the charts (`BarChart`, `PieChart`, `SingleSeriesBarChart`), this class does **not** receive `at:`: it always draws starting from the current cursor (`table.draw` internally uses `@pdf.cursor`) and uses `@pdf.bounds.width` as its width, never an explicitly passed `width:`. This works for the common case (a full-width table, sequential in the page's flow), but when a caller needs to place it in a narrow column (e.g. `StatisticSpiPrints::TotalsPage`, two side-by-side "iscritti"/"deleghe" columns) it has to wrap it in a `@pdf.bounding_box([x, top], width: column_width, height: top)` — it's the caller's `bounding_box` that narrows `@pdf.bounds.width`, not a parameter of this class. `table.draw` with `header: true` and no explicit remaining-space check can also push the table past the page bottom, automatically splitting it onto a new page with the header repeated — native `prawn-table` behavior, never disabled in this file.*

### `data_row`, `NumberFormatting`

```ruby
def data_row(row)
  [
    row[:label], NumberFormatting.count(row[:count_precedente]), NumberFormatting.count(row[:count_anno]),
    NumberFormatting.count(row[:diff]), NumberFormatting.percent(row[:diff_percent])
  ]
end
```

> **IT:** `row` è un semplice `Hash` con chiavi simboliche (`:label`, `:count_precedente`, ecc.), non uno `Struct` o un oggetto tipizzato — un contratto informale che ogni pagina chiamante deve rispettare costruendo l'hash a mano (si veda `RegionalPage#row_for`, `EmploymentStatusPage#row_for`), tipicamente mappando un risultato di `Statistics::TotalMembersComparison` o equivalente SPI in questa forma. Nessuna validazione delle chiavi qui: se una pagina passa un hash con una chiave mancante o sbagliata, l'errore emerge solo a runtime (tipicamente un `NoMethodError` su `nil` dentro `NumberFormatting.count`), non prima.
>
> *EN: `row` is a plain `Hash` with symbol keys (`:label`, `:count_precedente`, etc.), not a `Struct` or a typed object — an informal contract every calling page must honor by hand-building the hash (see `RegionalPage#row_for`, `EmploymentStatusPage#row_for`), typically mapping a `Statistics::TotalMembersComparison` result or its SPI equivalent into this shape. No key validation happens here: if a page passes a hash with a missing or misspelled key, the error only surfaces at runtime (typically a `NoMethodError` on `nil` inside `NumberFormatting.count`), not before.*

### `cell_style`

```ruby
def cell_style
  {
    font: "AsapCondensed", size: 10, text_color: "000000", borders: [ :bottom ], border_color: "DDDDDD",
    padding: [ 5, 6 ]
  }
end
```

> **IT:** `text_color: "000000"` è impostato esplicitamente qui, non lasciato all'ambiente `fill_color` correntemente attivo sul documento — una precauzione necessaria perché `fill_color` in Prawn è uno stato globale del documento, non scoperto per blocco o per pagina: se la pagina precedente avesse lasciato un `fill_color` chiaro (es. un banner scuro con testo bianco), `Prawn::Table` senza `text_color` esplicito erediterebbe quello stato e renderebbe il testo della tabella illeggibile su sfondo bianco. Impostare `text_color` dentro `cell_style` rende la tabella immune allo stato di `fill_color` lasciato da qualunque cosa sia stata disegnata prima — coerente con la stessa precauzione (`@pdf.fill_color "000000"` a inizio `draw`) presa esplicitamente da ogni pagina di contenuto (`RegionalPage`, `EmploymentStatusPage`, ecc.) prima di chiamare questa classe.
>
> *EN: `text_color: "000000"` is set explicitly here, not left to whatever `fill_color` is currently active on the document — a necessary precaution because `fill_color` in Prawn is document-wide state, not scoped per block or per page: if the previous page had left a light `fill_color` set (e.g. a dark banner with white text), `Prawn::Table` without an explicit `text_color` would inherit that state and render the table's text unreadable on a white background. Setting `text_color` inside `cell_style` makes the table immune to whatever `fill_color` state was left behind by anything drawn earlier — consistent with the same precaution (`@pdf.fill_color "000000"` at the start of `draw`) taken explicitly by every content page (`RegionalPage`, `EmploymentStatusPage`, etc.) before calling this class.*

> **Nota 2026-10-05 / Note:** lo snippet qui sopra mostra il codice precedente al refactor: `cell_style` e `style_header` arrivano ora da `StatisticPrints::TableStyle` (vedi `CodeGuide/StatisticPrints/table_style.md`); il "Codice completo" in cima è quello attuale. / The snippet above shows the pre-refactor code: `cell_style` and `style_header` now come from `StatisticPrints::TableStyle`; the "Codice completo" at the top is current.

### `style_header`, `style_rows`, `style_cell`

```ruby
def style_rows(table)
  @rows.each_with_index do |row, index|
    color = row[:diff].negative? ? DANGER : SUCCESS
    (3..4).each { |col| style_cell(table.row(index + 1).column(col), color) }
  end
end
```

> **IT:** Lo stile è applicato **dopo** la creazione della tabella (`table = @pdf.make_table(...)`, poi `table.row(...)`), non dentro `cell_style` passato a `make_table`: `cell_style` è uniforme per tutte le celle, mentre il colore di `diff`/`diff_percent` (colonne 3 e 4, indicizzate da 0) dipende dal segno per ogni singola riga, quindi va calcolato e applicato riga per riga dopo che la tabella esiste già come oggetto `Prawn::Table`. `index + 1` compensa la riga di intestazione (indice 0): la riga `i` di `@rows` corrisponde sempre alla riga `i + 1` della tabella disegnata. Stesso identico schema di colorazione condizionale (verde se non negativo, rosso se negativo) usato in `BarChart#draw_percentage` — le due classi non condividono codice, ma condividono la stessa convenzione visiva applicata in due media diversi (barra vs tabella) della stessa pagina.
>
> *EN: Styling is applied **after** the table is created (`table = @pdf.make_table(...)`, then `table.row(...)`), not inside the `cell_style` passed to `make_table`: `cell_style` is uniform across all cells, while the `diff`/`diff_percent` color (columns 3 and 4, 0-indexed) depends on the sign per individual row, so it has to be computed and applied row by row after the table already exists as a `Prawn::Table` object. `index + 1` compensates for the header row (index 0): row `i` of `@rows` always corresponds to row `i + 1` of the drawn table. The exact same conditional-coloring scheme (green if non-negative, red if negative) is used in `BarChart#draw_percentage` — the two classes share no code, but they share the same visual convention applied across two different media (bar vs. table) on the same page.*
