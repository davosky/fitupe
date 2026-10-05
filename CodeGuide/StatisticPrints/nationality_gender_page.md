# `StatisticPrints::NationalityGenderPage`

**File:** `app/services/statistic_prints/nationality_gender_page.rb`

## Codice completo

```ruby
module StatisticPrints
  class NationalityGenderPage
    include PageLayout

    MAX_CHART_HEIGHT_MM = 90
    SECTION_GAP_MM = 6
    COLUMN_GAP_MM = 10
    SESSO_RATIO = 1.0 / 3

    def self.draw(...) = new(...).draw

    def initialize(pdf, form:, comparison_service: Statistics::TotalMembersComparison)
      @pdf = pdf
      @form = form
      @comparison_service = comparison_service
    end

    def draw
      result = @comparison_service.call(zoning: @form.zoning, anno: @form.anno, mese: @form.mese)
      @pdf.fill_color "000000"
      draw_heading(result.zoning)
      return draw_message(result.error, "DC3545") unless result.success?

      draw_columns(result)
    end

    private

    def draw_heading(zoning) = draw_page_heading("Sesso e Nazionalità - #{zoning.descrizione_azzonamento}")

    # Disegna prima le due tabelle (colonne con un numero di righe diverso) e
    # solo dopo i grafici, così i due grafici a torta possono condividere lo
    # stesso top e la stessa altezza e risultare allineati in basso.
    def draw_columns(result)
      top = @pdf.cursor
      left = @pdf.bounds.left

      sesso_bottom = draw_sesso_table(result, left, top)
      nazionalita_bottom = draw_nazionalita_table(result, left + sesso_width + column_gap, top)

      draw_charts(result, left, sesso_bottom, nazionalita_bottom)
    end

    def draw_sesso_table(result, x, top)
      cursor_after = nil
      @pdf.bounding_box([ x, top ], width: sesso_width, height: top) do
        if result.sesso.blank?
          draw_message("Nessun dato di Sesso presente per il periodo selezionato.", "666666")
        else
          SingleYearTable.draw(
            @pdf, title: "Sesso", label_header: "Sesso", mese: result.mese, anno: result.anno,
            rows: result.sesso.map { |row| row_for(row.sesso, row) }
          )
          cursor_after = @pdf.cursor
        end
      end
      cursor_after
    end

    def draw_nazionalita_table(result, x, top)
      cursor_after = nil
      @pdf.bounding_box([ x, top ], width: nazionalita_width, height: top) do
        if result.nazionalita.blank?
          draw_message("Nessun dato di Nazionalità presente per il periodo selezionato.", "666666")
        else
          SingleYearTable.draw(
            @pdf, title: "Nazionalità", label_header: "Nazionalità", mese: result.mese, anno: result.anno,
            rows: result.nazionalita.map { |row| row_for(row.nazionalita, row) }
          )
          cursor_after = @pdf.cursor
        end
      end
      cursor_after
    end

    def row_for(label, row)
      { label: label, count: row.count, percentuale: row.percentuale }
    end

    def draw_charts(result, left, sesso_bottom, nazionalita_bottom)
      return if sesso_bottom.nil? && nazionalita_bottom.nil?

      chart_top = [ sesso_bottom, nazionalita_bottom ].compact.min - section_gap
      height = [ chart_top - 6, mm(MAX_CHART_HEIGHT_MM) ].min

      draw_sesso_chart(result, left, chart_top, height) if sesso_bottom
      draw_nazionalita_chart(result, left, chart_top, height) if nazionalita_bottom
    end

    def draw_sesso_chart(result, left, chart_top, height)
      PieChart.draw(
        @pdf, at: [ left, chart_top ], width: sesso_width, height: height,
        labels: result.sesso.map(&:sesso), data: result.sesso.map(&:count)
      )
    end

    def draw_nazionalita_chart(result, left, chart_top, height)
      PieChart.draw(
        @pdf, at: [ left + sesso_width + column_gap, chart_top ], width: nazionalita_width, height: height,
        labels: result.nazionalita.map(&:nazionalita), data: result.nazionalita.map(&:count)
      )
    end

    def sesso_width = (@pdf.bounds.width - column_gap) * SESSO_RATIO
    def nazionalita_width = @pdf.bounds.width - column_gap - sesso_width
  end
end
```

## Sezioni commentate

### `draw`, `draw_columns` e la strategia generale "tabelle prima, grafici dopo"

```ruby
def draw
  result = @comparison_service.call(zoning: @form.zoning, anno: @form.anno, mese: @form.mese)
  @pdf.fill_color "000000"
  draw_heading(result.zoning)
  return draw_message(result.error, "DC3545") unless result.success?

  draw_columns(result)
end
```

```ruby
# Disegna prima le due tabelle (colonne con un numero di righe diverso) e
# solo dopo i grafici, così i due grafici a torta possono condividere lo
# stesso top e la stessa altezza e risultare allineati in basso.
def draw_columns(result)
  top = @pdf.cursor
  left = @pdf.bounds.left

  sesso_bottom = draw_sesso_table(result, left, top)
  nazionalita_bottom = draw_nazionalita_table(result, left + sesso_width + column_gap, top)

  draw_charts(result, left, sesso_bottom, nazionalita_bottom)
end
```

> **IT:** Questa è la prima pagina del batch (insieme a `WorkStatusAgePage`, che ne è strutturalmente un clone) a comporre **due sezioni Statistics indipendenti affiancate in colonne**, ciascuna con la propria tabella + il proprio grafico. `result.sesso` (`Statistics::GenderBreakdown`) e `result.nazionalita` (`Statistics::NationalityBreakdown`) sono entrambi breakdown "distribuzione a solo anno corrente" (`label`, `count`, `percentuale`, nessun confronto anno su anno) — coerente col fatto che a schermo sono le due sezioni che usano il controller Stimulus `pie-chart` (vedi `CodeGuide/Statistics/README.md`). Il commento in cima a `draw_columns` è la chiave di lettura di tutto il file: **le due tabelle vengono disegnate per intero prima di disegnare qualsiasi grafico**, non tabella-e-grafico-di-Sesso seguiti da tabella-e-grafico-di-Nazionalità. Il motivo è che "Sesso" ha sempre 2 righe mentre "Nazionalità" può averne molte di più: se i grafici fossero disegnati subito dopo la rispettiva tabella, le due torte partirebbero da altezze diverse e risulterebbero disallineate in fondo alla pagina. Disegnando prima entrambe le tabelle e catturando dove ciascuna finisce (`sesso_bottom`, `nazionalita_bottom`), `draw_charts` può calcolare un `chart_top` **condiviso** — il minimo dei due fondi tabella — cosicché entrambe le torte partano dallo stesso punto e abbiano la stessa altezza, allineate visivamente.
>
> *EN: This is the first page in the batch (together with `WorkStatusAgePage`, which is structurally a clone of it) to compose **two independent Statistics sections side by side in columns**, each with its own table + its own chart. `result.sesso` (`Statistics::GenderBreakdown`) and `result.nazionalita` (`Statistics::NationalityBreakdown`) are both "current-year-only distribution" breakdowns (`label`, `count`, `percentuale`, no year-over-year comparison) — consistent with them being the two on-screen sections that use the `pie-chart` Stimulus controller (see `CodeGuide/Statistics/README.md`). The comment atop `draw_columns` is the key to reading the whole file: **both tables are drawn in full before any chart is drawn**, not Sesso-table-then-Sesso-chart followed by Nazionalità-table-then-Nazionalità-chart. The reason is that "Sesso" always has 2 rows while "Nazionalità" can have many more: if the charts were drawn right after their own table, the two pies would start at different heights and end up visually misaligned at the bottom of the page. By drawing both tables first and capturing where each one ends (`sesso_bottom`, `nazionalita_bottom`), `draw_charts` can compute one **shared** `chart_top` — the minimum of the two table bottoms — so both pies start from the same point and share the same height, visually aligned.*

### `draw_sesso_table`, `draw_nazionalita_table` *(privati)* — il `bounding_box` e il perché di `cursor_after`

```ruby
def draw_sesso_table(result, x, top)
  cursor_after = nil
  @pdf.bounding_box([ x, top ], width: sesso_width, height: top) do
    if result.sesso.blank?
      draw_message("Nessun dato di Sesso presente per il periodo selezionato.", "666666")
    else
      SingleYearTable.draw(
        @pdf, title: "Sesso", label_header: "Sesso", mese: result.mese, anno: result.anno,
        rows: result.sesso.map { |row| row_for(row.sesso, row) }
      )
      cursor_after = @pdf.cursor
    end
  end
  cursor_after
end
```

> **IT:** Questo è il punto più delicato della pagina, dove si applica direttamente la nota di progetto sui `bounding_box` "stretchy" senza `height:` esplicita — con una variante: qui `height:` **è** passata esplicitamente, ma con il valore `top` (cioè lo spazio disponibile fino al fondo pagina, dato che `top` è stato catturato da `@pdf.cursor` prima di disegnare qualunque cosa). Un `bounding_box` con un `height:` così grande, ancorato in `[x, top]`, si estende fino in fondo alla pagina (`bounds.bottom`): quando il blocco si chiude, Prawn fa avanzare il cursore del documento fino al **fondo del box**, non fino a dove il contenuto interno si è effettivamente fermato. Per questo `@pdf.cursor`, se letto **dopo** la chiusura del blocco, restituirebbe un valore vicino a zero — sbagliato, perché la tabella "Sesso" occupa in realtà solo una piccola parte in alto del box. La soluzione è catturare `@pdf.cursor` **dentro** il blocco, subito dopo `SingleYearTable.draw`, in una variabile locale (`cursor_after`) definita **fuori** dal blocco così da sopravvivere alla sua chiusura: è l'unico modo per sapere dove il contenuto vero è realmente terminato. Il ramo `if result.sesso.blank?` lascia `cursor_after` a `nil`: se non c'è nulla da disegnare in questa colonna, non c'è nessun "fondo tabella" significativo da restituire, e il chiamante (`draw_charts`) lo tratterà di conseguenza (vedi sotto).
>
> *EN: This is the trickiest spot on the page, where the project note about "stretchy" `bounding_box`es with no explicit `height:` applies directly — with one twist: here `height:` **is** passed explicitly, but with the value `top` (i.e. the space available down to the page bottom, since `top` was captured from `@pdf.cursor` before anything was drawn). A `bounding_box` with such a large `height:`, anchored at `[x, top]`, extends all the way to the bottom of the page (`bounds.bottom`): when the block closes, Prawn advances the document's cursor down to the **bottom of the box**, not to wherever the inner content actually stopped. Because of that, `@pdf.cursor`, if read **after** the block closes, would return a value close to zero — wrong, since the "Sesso" table actually only occupies a small area near the top of the box. The fix is to capture `@pdf.cursor` **inside** the block, right after `SingleYearTable.draw`, into a local variable (`cursor_after`) declared **outside** the block so it survives the block closing: it's the only way to know where the real content actually ended. The `if result.sesso.blank?` branch leaves `cursor_after` as `nil`: if there's nothing to draw in this column, there's no meaningful "table bottom" to return, and the caller (`draw_charts`) treats that accordingly (see below).*

### `row_for` *(privato)*

```ruby
def row_for(label, row)
  { label: label, count: row.count, percentuale: row.percentuale }
end
```

> **IT:** Stesso contratto `Hash` "distribuzione a solo anno corrente" (`label`/`count`/`percentuale`) usato da `WorkStatusAgePage`, `ProvisionalRevocationsPage` (per `PercentageTable`) e da `SingleYearTable` in generale — il contratto gemello, per le sezioni a confronto, di `row_for` in `RegionalPage`/`CategoriesPage`/`MembershipTypesPage`. `label` è passato come primo argomento posizionale (il valore del campo specifico, `row.sesso` o `row.nazionalita`) proprio perché i due `Struct::Row` di partenza hanno nomi di campo diversi (`GenderBreakdown::Row#sesso` vs. `NationalityBreakdown::Row#nazionalita`) ma la stessa forma altrimenti — un solo `row_for` basta per entrambe le colonne.
>
> *EN: The same "current-year-only distribution" `Hash` contract (`label`/`count`/`percentuale`) used by `WorkStatusAgePage`, `ProvisionalRevocationsPage` (for `PercentageTable`), and `SingleYearTable` in general — the twin, for single-year sections, of the `row_for` contract in `RegionalPage`/`CategoriesPage`/`MembershipTypesPage`. `label` is passed as the first positional argument (the specific field's value, `row.sesso` or `row.nazionalita`) precisely because the two source `Struct::Row`s have different field names (`GenderBreakdown::Row#sesso` vs. `NationalityBreakdown::Row#nazionalita`) but are otherwise the same shape — a single `row_for` covers both columns.*

### `draw_charts` *(privato)*

```ruby
def draw_charts(result, left, sesso_bottom, nazionalita_bottom)
  return if sesso_bottom.nil? && nazionalita_bottom.nil?

  chart_top = [ sesso_bottom, nazionalita_bottom ].compact.min - section_gap
  height = [ chart_top - 6, mm(MAX_CHART_HEIGHT_MM) ].min

  draw_sesso_chart(result, left, chart_top, height) if sesso_bottom
  draw_nazionalita_chart(result, left, chart_top, height) if nazionalita_bottom
end
```

> **IT:** `[sesso_bottom, nazionalita_bottom].compact.min` è dove si materializza l'"allineamento in basso" descritto nel commento di `draw_columns`: prendendo il **minimo** (cioè il valore di cursore più basso, quindi la colonna la cui tabella è finita più in alto sulla pagina — ricordando che il cursore misura la distanza dal fondo, quindi "minimo" = "più vicino al fondo" = tabella più lunga) tra i due fondi tabella, il `chart_top` risultante è sicuro per entrambe le colonne: nessuno dei due grafici potrà mai sovrapporsi alla tabella corrispondente, perché parte da un punto uguale o più in basso di dove ciascuna tabella è realmente terminata. `.compact` gestisce il caso in cui una delle due colonne non abbia disegnato nulla (`nil`), scartandolo dal calcolo del minimo. Nota che, a differenza di `EmploymentStatusPage`/`ProvisionalRevocationsPage`, questa pagina **non chiama mai `@pdf.move_down`** dopo aver disegnato i grafici: non ce n'è bisogno, perché sono l'ultimo contenuto della pagina — e perché, comunque, il cursore del documento a questo punto è già stato "corrotto" dalla chiusura dei due `bounding_box` delle tabelle (portato vicino a zero), quindi non sarebbe comunque affidabile riutilizzarlo per posizionare altro sotto ai grafici. È esattamente per questo che l'intero metodo lavora con `chart_top`/`height` calcolati esplicitamente, mai con `@pdf.cursor` letto a questo punto del flusso.
>
> *EN: `[sesso_bottom, nazionalita_bottom].compact.min` is where the "aligned at the bottom" behavior described in `draw_columns`'s comment actually happens: taking the **minimum** (i.e. the lowest cursor value, hence the column whose table ended highest up the page — recall the cursor measures distance from the bottom, so "minimum" = "closest to the bottom" = the longer table) of the two table bottoms, the resulting `chart_top` is safe for both columns: neither chart can ever overlap its corresponding table, since it starts at a point equal to or below where each table actually ended. `.compact` handles the case where one of the two columns drew nothing (`nil`), excluding it from the minimum calculation. Note that, unlike `EmploymentStatusPage`/`ProvisionalRevocationsPage`, this page **never calls `@pdf.move_down`** after drawing the charts: there's no need to, since they're the last content on the page — and, in any case, the document's cursor at this point has already been "corrupted" by the two table `bounding_box`es closing (driven near zero), so it wouldn't be reliable to reuse for positioning anything below the charts anyway. That's exactly why the whole method works with explicitly computed `chart_top`/`height`, never with `@pdf.cursor` read at this point in the flow.*

### `draw_sesso_chart`, `draw_nazionalita_chart`, larghezze e gap *(privati)*

```ruby
def draw_sesso_chart(result, left, chart_top, height)
  PieChart.draw(
    @pdf, at: [ left, chart_top ], width: sesso_width, height: height,
    labels: result.sesso.map(&:sesso), data: result.sesso.map(&:count)
  )
end

def draw_nazionalita_chart(result, left, chart_top, height)
  PieChart.draw(
    @pdf, at: [ left + sesso_width + column_gap, chart_top ], width: nazionalita_width, height: height,
    labels: result.nazionalita.map(&:nazionalita), data: result.nazionalita.map(&:count)
  )
end

def sesso_width = (@pdf.bounds.width - column_gap) * SESSO_RATIO
def nazionalita_width = @pdf.bounds.width - column_gap - sesso_width
```

> **IT:** `PieChart.draw` (`CodeGuide/StatisticPrints/pie_chart.md`) è chiamato con coordinate assolute (`at:`), non dentro un `bounding_box`: a differenza delle tabelle, i grafici non hanno bisogno di far avanzare il cursore del documento (sono l'ultimo elemento di pagina), quindi possono usare lo stesso pattern "coordinate assolute" già visto in `EmploymentStatusPage`. `SESSO_RATIO = 1.0 / 3` riflette il fatto che "Sesso" ha sempre solo 2 categorie (una torta piccola basta) mentre "Nazionalità" può averne diverse di più — è l'analogo, con proporzioni invertite (1/3 invece di 2/3), di `CHART_COLUMN_RATIO` in `EmploymentStatusPage`/`ProvisionalRevocationsPage`, dove però la colonna più larga era il grafico stesso, non la tabella complementare.
>
> *EN: `PieChart.draw` (`CodeGuide/StatisticPrints/pie_chart.md`) is called with absolute coordinates (`at:`), not inside a `bounding_box`: unlike the tables, the charts don't need to advance the document's cursor (they're the last page element), so they can use the same "absolute coordinates" pattern already seen in `EmploymentStatusPage`. `SESSO_RATIO = 1.0 / 3` reflects the fact that "Sesso" always has just 2 categories (a small pie is enough) while "Nazionalità" can have several more — it's the analogue, with inverted proportions (1/3 instead of 2/3), of `CHART_COLUMN_RATIO` in `EmploymentStatusPage`/`ProvisionalRevocationsPage`, where however the wider column was the chart itself, not the complementary table.*
