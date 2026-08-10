# `StatisticSpiPrints::TipologieDelegaPage`

**File:** `app/services/statistic_spi_prints/tipologie_delega_page.rb`

## Codice completo

```ruby
module StatisticSpiPrints
  # Pagina "Tipologie Delega": specchia app/views/statistic_spi/_tipologie_delega_card
  # e _tipologie_delega_comprensori_card. Totale (tabella + grafico a barre) e
  # Comprensori (tabella conteggi + tabella percentuali) affiancati in colonne,
  # come TotalsPage, per stare in una pagina sola.
  class TipologieDelegaPage
    SECTION_GAP_MM = 8
    COLUMN_GAP_MM = 12
    CHART_HEIGHT_MM = 55
    ETICHETTE = StatisticSpi::TipologieDelegaBreakdown::ETICHETTE

    def self.draw(...) = new(...).draw

    def initialize(pdf, form:, breakdown_service: StatisticSpi::TipologieDelegaBreakdown)
      @pdf = pdf
      @form = form
      @breakdown_service = breakdown_service
    end

    def draw
      @pdf.fill_color "000000"
      draw_heading
      result = @breakdown_service.call(zoning: @form.zoning, anno: @form.anno, mese: @form.mese)
      if result.comprensori.present?
        draw_two_columns(result)
      else
        draw_totale_column(result, @pdf.bounds.left, @pdf.cursor, @pdf.bounds.width)
      end
    end

    private

    def draw_heading
      @pdf.font("AsapCondensed", style: :bold, size: 16) { @pdf.text heading_title }
      @pdf.move_down 2
      @pdf.font("AsapCondensed", size: 10) { @pdf.text "Tesseramento #{@form.mese} #{@form.anno}", color: "666666" }
      @pdf.move_down 8
      @pdf.stroke_color "CCCCCC"
      @pdf.stroke_horizontal_rule
      @pdf.move_down section_gap
    end

    def heading_title
      return "CGIL Tipologie Delega SPI – Regionale e Comprensori" if @form.zoning.regionale?

      "CGIL Tipologie Delega SPI – Comprensorio di #{@form.zoning.descrizione_azzonamento}"
    end

    def draw_two_columns(result)
      top = @pdf.cursor
      left = @pdf.bounds.left

      draw_totale_column(result, left, top, column_width)
      draw_comprensori_column(result, left + column_width + column_gap, top, column_width)
    end

    def draw_totale_column(result, x, top, width)
      @pdf.bounding_box([ x, top ], width: width, height: top) do
        CategoryTable.draw(@pdf, title: result.totale.zoning.descrizione_azzonamento, rows: [ result.totale ], etichette: ETICHETTE)
        @pdf.move_down section_gap
        draw_chart(result.totale, width)
      end
    end

    def draw_chart(row, width)
      CategoryBarChart.draw(
        @pdf, at: [ @pdf.bounds.left, @pdf.cursor ], width: width, height: chart_height,
        labels: ETICHETTE, values: ETICHETTE.map { |etichetta| row.totali[etichetta] },
        percentages: ETICHETTE.map { |etichetta| row.percentuali[etichetta] }
      )
    end

    def draw_comprensori_column(result, x, top, width)
      @pdf.bounding_box([ x, top ], width: width, height: top) do
        CategoryTable.draw(@pdf, title: "Comprensori", rows: result.comprensori, etichette: ETICHETTE)
        @pdf.move_down section_gap
        CategoryPercentageTable.draw(@pdf, title: "Comprensori (%)", rows: result.comprensori, etichette: ETICHETTE)
        @pdf.move_down section_gap
        draw_comprensori_chart(result.comprensori, width)
      end
    end

    def draw_comprensori_chart(comprensori, width)
      GroupedCategoryBarChart.draw(
        @pdf, at: [ @pdf.bounds.left, @pdf.cursor ], width: width, height: chart_height,
        labels: comprensori.map { |row| row.zoning.descrizione_azzonamento }, series_labels: ETICHETTE,
        series_values: ETICHETTE.map { |etichetta| comprensori.map { |row| row.percentuali[etichetta] || 0 } }
      )
    end

    def column_width = (@pdf.bounds.width - column_gap) / 2
    def column_gap = COLUMN_GAP_MM * 72 / 25.4
    def section_gap = SECTION_GAP_MM * 72 / 25.4
    def chart_height = [ @pdf.cursor - 6, CHART_HEIGHT_MM * 72 / 25.4 ].min
  end
end
```

## Sezioni commentate

### Commento di classe, `ETICHETTE`

```ruby
# Pagina "Tipologie Delega": specchia app/views/statistic_spi/_tipologie_delega_card
# e _tipologie_delega_comprensori_card. Totale (tabella + grafico a barre) e
# Comprensori (tabella conteggi + tabella percentuali) affiancati in colonne,
# come TotalsPage, per stare in una pagina sola.
class TipologieDelegaPage
  # ...
  ETICHETTE = StatisticSpi::TipologieDelegaBreakdown::ETICHETTE
```

> **IT:** `ETICHETTE` non ridefinisce le cinque etichette (`Ordinaria`, `Concomitante`, `Invalidi Civili`, `BreviManu`, `Altro`): le importa dalla costante del servizio, esattamente come `AgeClassesPage::BANDS = StatisticSpi::AgeBreakdown::BANDS` (vedi più sotto) e come `StatisticSpi::AgeBreakdown` stessa importa `BANDS`/`AGE_EXPR` da `Statistics::AgeBreakdown`. È lo stesso principio applicato al confine servizio→pagina invece che servizio→servizio: l'elenco delle tipologie di delega è definito **una sola volta**, nel servizio, e ogni consumatore (vista ERB a schermo, questa pagina PDF) lo eredita, così un domani un sesto tipo di delega aggiunto in `TipologieDelegaBreakdown::ETICHETTE` compare automaticamente anche qui, senza toccare `TipologieDelegaPage`.
>
> *EN: `ETICHETTE` doesn't redefine the five labels (`Ordinaria`, `Concomitante`, `Invalidi Civili`, `BreviManu`, `Altro`): it imports them from the service's constant, exactly like `AgeClassesPage::BANDS = StatisticSpi::AgeBreakdown::BANDS` (see below) and like `StatisticSpi::AgeBreakdown` itself importing `BANDS`/`AGE_EXPR` from `Statistics::AgeBreakdown`. It's the same principle applied at the service→page boundary instead of service→service: the list of delegation types is defined **exactly once**, in the service, and every consumer (the on-screen ERB view, this PDF page) inherits it, so a future sixth delegation type added to `TipologieDelegaBreakdown::ETICHETTE` automatically shows up here too, with no change to `TipologieDelegaPage`.*

### `draw` — il fork "due colonne o una sola", ripetuto in tre pagine

```ruby
def draw
  @pdf.fill_color "000000"
  draw_heading
  result = @breakdown_service.call(zoning: @form.zoning, anno: @form.anno, mese: @form.mese)
  if result.comprensori.present?
    draw_two_columns(result)
  else
    draw_totale_column(result, @pdf.bounds.left, @pdf.cursor, @pdf.bounds.width)
  end
end
```

> **IT:** Questo `if result.comprensori.present?` è il primo punto della cartella in cui il fork "azzonamento regionale vs comprensorio singolo" non si limita a nascondere una sotto-tabella (come `draw_comprensori_table if ... .present?` in `TotalsPage`/`MultipleDelegationsPage`), ma cambia **il layout della pagina intera**: se ci sono comprensori, `draw_totale_column` occupa solo metà larghezza (`column_width`) e ha accanto `draw_comprensori_column`; se non ci sono (azzonamento scelto già un singolo comprensorio), `draw_totale_column` viene chiamato con `@pdf.bounds.width` intera, riusando lo stesso metodo per un layout a piena larghezza invece di introdurne uno separato. Questo stesso fork ricompare, identico, in `CessazioniPage` e `ProvvisoriePage` — la prima pagina a introdurlo in questa cartella è questa; le altre due la riusano senza modificarla, vedi i rispettivi file per la nota di cross-reference.
>
> *EN: This `if result.comprensori.present?` is the first point in this folder where the "regional zoning vs single comprensorio" fork doesn't just hide a sub-table (like `draw_comprensori_table if ... .present?` in `TotalsPage`/`MultipleDelegationsPage`), but changes **the whole page's layout**: when there are comprensori, `draw_totale_column` occupies only half the width (`column_width`) with `draw_comprensori_column` next to it; when there aren't (the chosen zoning is already a single comprensorio), `draw_totale_column` is called with the full `@pdf.bounds.width`, reusing the same method for a full-width layout instead of introducing a separate one. This same fork reappears, identically, in `CessazioniPage` and `ProvvisoriePage` — this is the first page in the folder to introduce it; the other two reuse it unchanged, see their respective files for the cross-reference note.*

### `draw_totale_column`, `draw_chart` *(privati)*

```ruby
def draw_totale_column(result, x, top, width)
  @pdf.bounding_box([ x, top ], width: width, height: top) do
    CategoryTable.draw(@pdf, title: result.totale.zoning.descrizione_azzonamento, rows: [ result.totale ], etichette: ETICHETTE)
    @pdf.move_down section_gap
    draw_chart(result.totale, width)
  end
end

def draw_chart(row, width)
  CategoryBarChart.draw(
    @pdf, at: [ @pdf.bounds.left, @pdf.cursor ], width: width, height: chart_height,
    labels: ETICHETTE, values: ETICHETTE.map { |etichetta| row.totali[etichetta] },
    percentages: ETICHETTE.map { |etichetta| row.percentuali[etichetta] }
  )
end
```

> **IT:** `bounding_box([x, top], width: width, height: top)` qui è di nuovo l'uso sicuro visto in `TotalsPage#draw_column`: le due colonne (`draw_totale_column`/`draw_comprensori_column`) sono affiancate, chiamate una dopo l'altra da `draw_two_columns` ma su `x` diversi, non impilate — nessun rischio del bug di `AgeClassesPage`. Dentro il box, `CategoryTable` (tabella generica per un `Row` con `totali`/`percentuali` hash, riusata anche da `CessazioniPage`) e `CategoryBarChart` (grafico a barre a singola serie con percentuali) sono chiamati usando `@pdf.cursor`/`@pdf.bounds.left` **relativi al box**: dentro un `bounding_box`, `@pdf.bounds` e `@pdf.cursor` sono automaticamente ridefiniti nel sistema di coordinate locale del box, quindi `draw_chart` non ha bisogno di conoscere `x`/`top` espliciti, a differenza di `AgeClassesPage#draw_chart_section` che lavora **fuori** da un `bounding_box` e per questo deve ricevere `x`/`top` come parametri e usare `draw_text at:`/`at:` assoluti.
>
> *EN: `bounding_box([x, top], width: width, height: top)` here is again the safe usage seen in `TotalsPage#draw_column`: the two columns (`draw_totale_column`/`draw_comprensori_column`) sit side by side, called one after another by `draw_two_columns` but at different `x` values, not stacked — none of `AgeClassesPage`'s bug risk. Inside the box, `CategoryTable` (a generic table for a `Row` with `totali`/`percentuali` hashes, also reused by `CessazioniPage`) and `CategoryBarChart` (a single-series bar chart with percentages) are called using `@pdf.cursor`/`@pdf.bounds.left` **relative to the box**: inside a `bounding_box`, `@pdf.bounds` and `@pdf.cursor` are automatically redefined in the box's local coordinate system, so `draw_chart` doesn't need to know explicit `x`/`top`, unlike `AgeClassesPage#draw_chart_section`, which works **outside** any `bounding_box` and therefore has to receive `x`/`top` as parameters and use absolute `draw_text at:`/`at:`.*

### `draw_comprensori_column`, `draw_comprensori_chart` *(privati)*

```ruby
def draw_comprensori_column(result, x, top, width)
  @pdf.bounding_box([ x, top ], width: width, height: top) do
    CategoryTable.draw(@pdf, title: "Comprensori", rows: result.comprensori, etichette: ETICHETTE)
    @pdf.move_down section_gap
    CategoryPercentageTable.draw(@pdf, title: "Comprensori (%)", rows: result.comprensori, etichette: ETICHETTE)
    @pdf.move_down section_gap
    draw_comprensori_chart(result.comprensori, width)
  end
end

def draw_comprensori_chart(comprensori, width)
  GroupedCategoryBarChart.draw(
    @pdf, at: [ @pdf.bounds.left, @pdf.cursor ], width: width, height: chart_height,
    labels: comprensori.map { |row| row.zoning.descrizione_azzonamento }, series_labels: ETICHETTE,
    series_values: ETICHETTE.map { |etichetta| comprensori.map { |row| row.percentuali[etichetta] || 0 } }
  )
end
```

> **IT:** La colonna Comprensori impila **tre** elementi (non due come la colonna Totale): la tabella dei conteggi assoluti (`CategoryTable`), una tabella dedicata alle sole percentuali (`CategoryPercentageTable` — non necessaria nella colonna Totale, dove le percentuali sono già leggibili accanto ai conteggi nel grafico a barre), e un grafico a barre **raggruppato** (`GroupedCategoryBarChart`, diverso da `CategoryBarChart`: una serie per etichetta invece di un'unica serie, un gruppo di barre per comprensorio). `series_values` è una matrice invertita rispetto a `totali`/`percentuali` di un singolo `Row`: `ETICHETTE.map { |etichetta| comprensori.map { |row| row.percentuali[etichetta] || 0 } }` produce un array-di-array organizzato per **etichetta esterna, comprensorio interno** (serie × punti), la forma richiesta da un grafico a barre raggruppato per confrontare le stesse cinque tipologie tra comprensori diversi. `|| 0` sostituisce un eventuale `nil` (percentuale non calcolabile quando `totale.zero?`, vedi `TipologieDelegaBreakdown#build_row`) con zero: qui, a differenza delle tabelle che possono mostrare una cella vuota per `nil`, un grafico a barre ha bisogno di un valore numerico per disegnare comunque la barra (anche se alta zero), non di un buco nella sequenza.
>
> *EN: The Comprensori column stacks **three** elements (not two like the Totale column): the absolute-count table (`CategoryTable`), a table dedicated to percentages alone (`CategoryPercentageTable` — unnecessary in the Totale column, where percentages are already readable next to counts in the bar chart), and a **grouped** bar chart (`GroupedCategoryBarChart`, different from `CategoryBarChart`: one series per label instead of a single series, one bar group per comprensorio). `series_values` is a matrix transposed relative to a single `Row`'s `totali`/`percentuali`: `ETICHETTE.map { |etichetta| comprensori.map { |row| row.percentuali[etichetta] || 0 } }` produces an array-of-arrays organized as **outer label, inner comprensorio** (series × points), the shape a grouped bar chart needs to compare the same five delegation types across different comprensori. `|| 0` replaces a possible `nil` (an uncomputable percentage when `totale.zero?`, see `TipologieDelegaBreakdown#build_row`) with zero: here, unlike tables that can show an empty cell for `nil`, a bar chart needs a numeric value to still draw the bar (even if zero-height), not a gap in the sequence.*

### `column_width`, `column_gap`, `section_gap`, `chart_height` *(privati)*

> **IT:** Stessa forma delle costanti di layout di `TotalsPage` — vedi `CodeGuide/StatisticSpiPrints/totals_page.md`. `chart_height`, in più rispetto a `TotalsPage`, usa `@pdf.cursor` **dentro** il `bounding_box` (quindi relativo al box, non alla pagina) come base per il calcolo "altezza massima ma non oltre lo spazio rimasto" — la stessa tecnica, applicata al contesto locale del box invece che a `columns_bottom` passato dal chiamante.
>
> *EN: Same shape as `TotalsPage`'s layout constants — see `CodeGuide/StatisticSpiPrints/totals_page.md`. `chart_height`, unlike `TotalsPage`, uses `@pdf.cursor` **inside** the `bounding_box` (so relative to the box, not the page) as the base for the "capped height but never past the remaining space" computation — the same technique, applied to the box's local context instead of a `columns_bottom` passed in by the caller.*
