# `StatisticPrints::CategoryGenderNationalityPage`

**File:** `app/services/statistic_prints/category_gender_nationality_page.rb`

## Codice completo

```ruby
module StatisticPrints
  # Ultima pagina di contenuto: "Genere Per Categoria" e "Nazionalità Per
  # Categoria" affiancate, solo tabelle (anno corrente), senza grafici.
  class CategoryGenderNationalityPage
    include PageLayout

    SECTION_GAP_MM = 6
    IMAGES_DIR = Rails.root.join("app/assets/images/statistic_prints")
    COLUMN_GAP_MM = 10

    def self.draw(...) = new(...).draw

    def initialize(pdf, form:, comparison_service: Statistics::TotalMembersComparison)
      @pdf = pdf
      @form = form
      @comparison_service = comparison_service
    end

    def draw
      result = @comparison_service.call(zoning: @form.zoning, anno: @form.anno, mese: @form.mese)
      @pdf.fill_color "000000"
      draw_heading(result)
      return draw_message(result.error, "DC3545") unless result.success?

      top = @pdf.cursor
      draw_table("Genere per Categoria", "sesso.png", result.sesso_per_categoria, @pdf.bounds.left, top)
      draw_table("Nazionalità per Categoria", "nazionalita.png", result.nazionalita_per_categoria,
        @pdf.bounds.left + column_width + column_gap, top)
    end

    private

    def draw_heading(result)
      draw_page_heading("Per Categoria: Genere e Nazionalità - #{result.zoning.descrizione_azzonamento} - " \
                        "#{result.mese} #{result.anno}")
    end

    def draw_table(title, icon, rows, x, top)
      @pdf.bounding_box([ x, top ], width: column_width, height: top) do
        if rows.blank?
          draw_message("Nessun dato di #{title} presente per il periodo selezionato.", "666666")
        else
          CategoryCrossTable.draw(@pdf, rows: rows, title: title, icon: IMAGES_DIR.join(icon))
        end
      end
    end

    def column_width = (@pdf.bounds.width - column_gap) / 2.0
  end
end
```

## Sezioni commentate

### Commento di classe

```ruby
class CategoryGenderNationalityPage
```

> **IT:** Ultima voce di `ReportPdf::CONTENT_PAGES` ("sempre in fondo", da specifica). Le due tabelle stanno affiancate su un solo foglio: impilate (2 × 13 righe) non entrerebbero in un A4 orizzontale, e due pagine separate avrebbero raddoppiato le pagine aggiunte a ogni comprensorio. Nessun grafico: il mockup di davo mostra solo la tabella.
>
> *EN: Last entry of `ReportPdf::CONTENT_PAGES` ("always at the bottom", per the spec). The two tables sit side by side on one sheet: stacked (2 × 13 rows) they would not fit a landscape A4, and two separate pages would have doubled the pages added for every comprensorio. No chart: davo's mockup shows the table only.*

### `draw`

```ruby
top = @pdf.cursor
draw_table("Genere per Categoria", "sesso.png", result.sesso_per_categoria, @pdf.bounds.left, top)
draw_table("Nazionalità per Categoria", "nazionalita.png", result.nazionalita_per_categoria,
  @pdf.bounds.left + column_width + column_gap, top)
```

> **IT:** Stesso schema a due colonne di `NationalityGenderPage` (vedi `CodeGuide/StatisticPrints/nationality_gender_page.md`), ma senza grafici sotto: non serve catturare il cursore dentro i `bounding_box`, perché dopo le tabelle non si disegna altro. Con `comparison_service: StatisticWithIntegrations::TotalMembersComparison` i numeri sono gli stessi di Stampa Statistiche: le integrazioni FILLEA/FLC non portano sesso né nazionalità.
>
> *EN: Same two-column layout as `NationalityGenderPage` (see `CodeGuide/StatisticPrints/nationality_gender_page.md`), but with no charts below: there is no need to capture the cursor inside the `bounding_box`es, since nothing is drawn after the tables. With `comparison_service: StatisticWithIntegrations::TotalMembersComparison` the numbers are the same as in Stampa Statistiche: FILLEA/FLC integrations carry neither gender nor nationality.*
