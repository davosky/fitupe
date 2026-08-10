# `StatisticPrints::MembershipTypesPage`

**File:** `app/services/statistic_prints/membership_types_page.rb`

## Codice completo

```ruby
module StatisticPrints
  class MembershipTypesPage
    MAX_CHART_HEIGHT_MM = 60
    SECTION_GAP_MM = 6

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

      draw_iscrizione(result)
      draw_delega(result)
    end

    private

    def draw_heading(zoning)
      @pdf.font("AsapCondensed", style: :bold, size: 16) { @pdf.text "Tipologie - #{zoning.descrizione_azzonamento}" }
      @pdf.move_down 8
      @pdf.stroke_color "CCCCCC"
      @pdf.stroke_horizontal_rule
      @pdf.move_down section_gap
    end

    def draw_message(message, color)
      @pdf.font("AsapCondensed", size: 12) { @pdf.text message, color: color }
    end

    def draw_iscrizione(result)
      return if result.tipologie_iscrizione.blank?

      ComparisonTable.draw(
        @pdf, title: "Tipologie Iscrizione", label_header: "Tipologia Iscrizioni", mese: result.mese,
        anno: result.anno, anno_precedente: result.anno_precedente,
        rows: result.tipologie_iscrizione.map { |row| row_for(row) }
      )
      @pdf.move_down section_gap
    end

    def draw_delega(result)
      return if result.tipologie_delega.blank?

      ComparisonTable.draw(
        @pdf, title: "Tipologie Delega", label_header: "Tipologia Delega", mese: result.mese, anno: result.anno,
        anno_precedente: result.anno_precedente, rows: result.tipologie_delega.map { |row| row_for(row) }
      )
      @pdf.move_down section_gap
      draw_chart(result)
    end

    def row_for(row)
      { label: row.tipologia, count_precedente: row.count_precedente, count_anno: row.count_anno,
        diff: row.diff, diff_percent: row.diff_percent }
    end

    def draw_chart(result)
      BarChart.draw(
        @pdf, at: [ @pdf.bounds.left, @pdf.cursor ], width: @pdf.bounds.width, height: chart_height,
        labels: result.tipologie_delega.map(&:tipologia), previous_data: result.tipologie_delega.map(&:count_precedente),
        current_data: result.tipologie_delega.map(&:count_anno), percentages: result.tipologie_delega.map(&:diff_percent),
        previous_label: "#{result.mese} #{result.anno_precedente}", current_label: "#{result.mese} #{result.anno}"
      )
    end

    def chart_height
      [ @pdf.cursor - 6, MAX_CHART_HEIGHT_MM * 72 / 25.4 ].min
    end

    def section_gap = SECTION_GAP_MM * 72 / 25.4
  end
end
```

## Sezioni commentate

### Costanti e `draw`

```ruby
MAX_CHART_HEIGHT_MM = 60
SECTION_GAP_MM = 6
```

```ruby
def draw
  result = @comparison_service.call(zoning: @form.zoning, anno: @form.anno, mese: @form.mese)
  @pdf.fill_color "000000"
  draw_heading(result.zoning)
  return draw_message(result.error, "DC3545") unless result.success?

  draw_iscrizione(result)
  draw_delega(result)
end
```

> **IT:** L'unica pagina del batch con **due sezioni indipendenti impilate verticalmente** invece che una sola sezione, o due sezioni affiancate in colonne. `MAX_CHART_HEIGHT_MM` (60, contro i 90 di `RegionalPage`/`CategoriesPage`/`EmploymentStatusPage`) e `SECTION_GAP_MM` (6, contro 10) sono più piccoli apposta: la pagina deve ospitare due tabelle **più** un grafico nello stesso spazio verticale in cui le altre pagine ospitano una tabella e un grafico soli, quindi ogni elemento deve occupare meno spazio. Le due sezioni (`draw_iscrizione` per `Statistics::MembershipTypeBreakdown`, `draw_delega` per `Statistics::DelegationTypeBreakdown` — entrambi documentati in `CodeGuide/Statistics/`, entrambi confronti anno su anno) sono disegnate in sequenza semplice, senza alcun `bounding_box`: ognuna chiama `ComparisonTable.draw` (che disegna a partire dal cursore corrente e lo avanza naturalmente) seguito da `@pdf.move_down section_gap`. Poiché nessuna delle due usa un `bounding_box` con `height:` esplicita, non si presenta qui il rischio di "cursore azzerato da una `bounding_box` sequenziale" descritto nelle note di progetto — quel rischio riguarda solo pattern con `bounding_box`, non il semplice avanzamento naturale del cursore dopo `ComparisonTable.draw`.
>
> *EN: The only page in the batch with **two independent sections stacked vertically** instead of one single section, or two sections side by side in columns. `MAX_CHART_HEIGHT_MM` (60, versus 90 in `RegionalPage`/`CategoriesPage`/`EmploymentStatusPage`) and `SECTION_GAP_MM` (6, versus 10) are deliberately smaller: the page has to fit two tables **plus** a chart in the same vertical space other pages use for just one table and one chart, so every element needs to take up less room. The two sections (`draw_iscrizione` for `Statistics::MembershipTypeBreakdown`, `draw_delega` for `Statistics::DelegationTypeBreakdown` — both documented in `CodeGuide/Statistics/`, both year-over-year comparisons) are drawn in plain sequence, with no `bounding_box` at all: each calls `ComparisonTable.draw` (which draws from the current cursor and advances it naturally) followed by `@pdf.move_down section_gap`. Since neither uses a `bounding_box` with an explicit `height:`, this page doesn't run into the "cursor zeroed by a sequential `bounding_box`" risk described in the project notes — that risk only applies to `bounding_box` patterns, not to the plain natural cursor advance after `ComparisonTable.draw`.*

### `draw_iscrizione`, `draw_delega` *(privati)*

```ruby
def draw_iscrizione(result)
  return if result.tipologie_iscrizione.blank?

  ComparisonTable.draw(
    @pdf, title: "Tipologie Iscrizione", label_header: "Tipologia Iscrizioni", mese: result.mese,
    anno: result.anno, anno_precedente: result.anno_precedente,
    rows: result.tipologie_iscrizione.map { |row| row_for(row) }
  )
  @pdf.move_down section_gap
end

def draw_delega(result)
  return if result.tipologie_delega.blank?

  ComparisonTable.draw(
    @pdf, title: "Tipologie Delega", label_header: "Tipologia Delega", mese: result.mese, anno: result.anno,
    anno_precedente: result.anno_precedente, rows: result.tipologie_delega.map { |row| row_for(row) }
  )
  @pdf.move_down section_gap
  draw_chart(result)
end
```

> **IT:** Ogni sezione ha il proprio `return if ... .blank?` **indipendente**: se mancano le "Tipologie Iscrizione" ma non le "Tipologie Delega" (o viceversa), la pagina disegna comunque la sezione presente, saltando silenziosamente quella mancante — a differenza di `draw` a livello di pagina, che invece interrompe tutto se `result.error` è presente. Solo `draw_delega` chiama `draw_chart`: `MembershipTypesPage` mostra un grafico **solo** per "Tipologie Delega", non per "Tipologie Iscrizione" — una scelta di design (probabilmente per non appesantire ulteriormente una pagina già densa con due tabelle) che va notata perché non simmetrica: le due sezioni condividono lo stesso componente tabella (`ComparisonTable`) ma non lo stesso componente grafico. Entrambe passano `title:` **e** `label_header:` insieme a `ComparisonTable.draw` (diversamente da `CategoriesPage`, che passa solo `label_header:` senza `title:`): qui serve un titolo di sottosezione visibile ("Tipologie Iscrizione" / "Tipologie Delega") perché la pagina ne contiene due, mentre `CategoriesPage` ha già un titolo di pagina sufficiente.
>
> *EN: Each section has its own **independent** `return if ... .blank?`: if "Tipologie Iscrizione" is missing but "Tipologie Delega" isn't (or vice versa), the page still draws whichever section is present, silently skipping the missing one — unlike page-level `draw`, which aborts everything if `result.error` is present. Only `draw_delega` calls `draw_chart`: `MembershipTypesPage` shows a chart **only** for "Tipologie Delega", not for "Tipologie Iscrizione" — a design choice (likely to avoid overloading an already dense page with two tables) worth flagging because it's asymmetric: the two sections share the same table component (`ComparisonTable`) but not the same chart component. Both pass `title:` **and** `label_header:` to `ComparisonTable.draw` (unlike `CategoriesPage`, which passes only `label_header:` with no `title:`): a visible subsection title ("Tipologie Iscrizione" / "Tipologie Delega") is needed here because the page holds two of them, while `CategoriesPage` already has a sufficient page-level title.*

### `row_for`, `draw_chart`, `chart_height`, `section_gap` *(privati)*

```ruby
def row_for(row)
  { label: row.tipologia, count_precedente: row.count_precedente, count_anno: row.count_anno,
    diff: row.diff, diff_percent: row.diff_percent }
end

def draw_chart(result)
  BarChart.draw(
    @pdf, at: [ @pdf.bounds.left, @pdf.cursor ], width: @pdf.bounds.width, height: chart_height,
    labels: result.tipologie_delega.map(&:tipologia), previous_data: result.tipologie_delega.map(&:count_precedente),
    current_data: result.tipologie_delega.map(&:count_anno), percentages: result.tipologie_delega.map(&:diff_percent),
    previous_label: "#{result.mese} #{result.anno_precedente}", current_label: "#{result.mese} #{result.anno}"
  )
end

def chart_height
  [ @pdf.cursor - 6, MAX_CHART_HEIGHT_MM * 72 / 25.4 ].min
end

def section_gap = SECTION_GAP_MM * 72 / 25.4
```

> **IT:** `row_for` è lo stesso identico contratto `Hash` visto in `RegionalPage`/`CategoriesPage`, riusato qui per **entrambe** le sezioni (`tipologie_iscrizione` e `tipologie_delega` hanno righe con la stessa forma, quindi un solo `row_for` privato basta per tutta la pagina, senza doverlo duplicare per sezione). `draw_chart`/`chart_height` sono anch'essi identici, riga per riga, a `RegionalPage`/`CategoriesPage`: `@pdf.cursor` viene letto immediatamente prima di disegnare, senza `bounding_box` di mezzo, quindi il valore è affidabile — vedi `CodeGuide/StatisticPrints/regional_page.md` per la spiegazione completa della "stretchy height" a piena larghezza.
>
> *EN: `row_for` is the exact same `Hash` contract seen in `RegionalPage`/`CategoriesPage`, reused here for **both** sections (`tipologie_iscrizione` and `tipologie_delega` rows share the same shape, so a single private `row_for` suffices for the whole page, with no need to duplicate it per section). `draw_chart`/`chart_height` are likewise identical, line for line, to `RegionalPage`/`CategoriesPage`: `@pdf.cursor` is read immediately before drawing, with no `bounding_box` in between, so the value is reliable — see `CodeGuide/StatisticPrints/regional_page.md` for the full explanation of the full-width "stretchy height".*
