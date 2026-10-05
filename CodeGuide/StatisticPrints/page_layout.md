# `StatisticPrints::PageLayout`

**File:** `app/services/statistic_prints/page_layout.rb`

## Codice completo

```ruby
module StatisticPrints
  # Disegno condiviso dalle pagine dei due fascicoli (Attivi e SPI):
  # conversione mm → punti, spaziature, intestazione di pagina e messaggi.
  # Le spaziature leggono SECTION_GAP_MM / COLUMN_GAP_MM della classe che
  # include il modulo.
  module PageLayout
    private

    def mm(value) = value * 72 / 25.4
    def section_gap = mm(self.class::SECTION_GAP_MM)
    def column_gap = mm(self.class::COLUMN_GAP_MM)
    def period_subtitle = "Tesseramento #{@form.mese} #{@form.anno}"

    # Titolo in grassetto, sottotitolo grigio opzionale e filetto orizzontale.
    def draw_page_heading(title, subtitle: nil, gap: section_gap)
      @pdf.font("AsapCondensed", style: :bold, size: 16) { @pdf.text title }
      draw_page_subtitle(subtitle) if subtitle
      @pdf.move_down 8
      @pdf.stroke_color "CCCCCC"
      @pdf.stroke_horizontal_rule
      @pdf.move_down gap
    end

    def draw_page_subtitle(subtitle)
      @pdf.move_down 2
      @pdf.font("AsapCondensed", size: 10) { @pdf.text subtitle, color: "666666" }
    end

    def draw_message(message, color = "666666")
      @pdf.font("AsapCondensed", size: 12) { @pdf.text message, color: color }
    end
  end
end
```

## Sezioni commentate

### Perché un modulo

```ruby
module PageLayout
  private
```

> **IT:** Nato dal refactor del 2026-10-05 (chiesto da davo dopo l'audit): intestazione di pagina, messaggio "nessun dato"/errore e conversione mm → punti erano copiati identici in circa 15 pagine dei due fascicoli. È un modulo e non una classe base perché le pagine non condividono il costruttore (Attivi: `comparison_service:`, SPI: `breakdown_service:`, legenda: solo `form:`) e `StatisticSpiPrints::LegendPage` eredita già da quella Attivi. Lo includono anche i due `ReportPdf`, solo per `mm`. Il refactor è stato verificato rigenerando 7 PDF reali (305 pagine) prima e dopo: identici pagina per pagina.
>
> *EN: Born from the 2026-10-05 refactor (requested by davo after the audit): page heading, "no data"/error message and mm → points conversion were copied verbatim in about 15 pages of the two booklets. It is a module rather than a base class because the pages do not share a constructor (Attivi: `comparison_service:`, SPI: `breakdown_service:`, legend: `form:` only) and `StatisticSpiPrints::LegendPage` already inherits from the Attivi one. Both `ReportPdf` classes include it too, just for `mm`. The refactor was verified by regenerating 7 real PDFs (305 pages) before and after: identical page by page.*

### `mm`, `section_gap`, `column_gap`

```ruby
def mm(value) = value * 72 / 25.4
def section_gap = mm(self.class::SECTION_GAP_MM)
def column_gap = mm(self.class::COLUMN_GAP_MM)
```

> **IT:** Le costanti restano in millimetri nella singola pagina (ognuna ha i suoi valori) e vengono lette con `self.class::`, così il modulo non impone un valore comune. Una pagina che non definisce `COLUMN_GAP_MM` semplicemente non chiama `column_gap`. I grafici (`AXIS_OVERHANG = 5 * 72 / 25.4`) non includono il modulo: lì la conversione è in una costante di classe, dove un metodo d'istanza non è disponibile.
>
> *EN: Constants stay in millimetres inside each page (each has its own values) and are read through `self.class::`, so the module does not impose a common value. A page that does not define `COLUMN_GAP_MM` simply never calls `column_gap`. The charts (`AXIS_OVERHANG = 5 * 72 / 25.4`) do not include the module: there the conversion lives in a class constant, where an instance method is not available.*

### `draw_page_heading`, `draw_page_subtitle`, `period_subtitle`

```ruby
def draw_page_heading(title, subtitle: nil, gap: section_gap)
```

> **IT:** Le due varianti che esistevano: titolo + filetto (pagine Attivi) e titolo + sottotitolo grigio "Tesseramento mese anno" + filetto (Regionale, Legenda e tutte le pagine SPI). `gap:` esiste perché `CategoriesPage` e `LegendPage` lasciano 10 punti fissi sotto il filetto invece del loro `SECTION_GAP_MM`: valori storici conservati per non spostare nulla nel PDF. Ogni pagina tiene il proprio `draw_heading` di una riga, che dice solo quale titolo usare.
>
> *EN: The two variants that existed: title + rule (Attivi pages) and title + grey "Tesseramento month year" subtitle + rule (Regional, Legend and every SPI page). `gap:` exists because `CategoriesPage` and `LegendPage` leave a fixed 10 points below the rule instead of their `SECTION_GAP_MM`: historical values kept so nothing moves in the PDF. Each page keeps its own one-line `draw_heading`, which only says which title to use.*

### `draw_message`

```ruby
def draw_message(message, color = "666666")
```

> **IT:** Grigio di default per "nessun dato"; le pagine passano `"DC3545"` (rosso danger) per l'errore del servizio di confronto.
>
> *EN: Grey by default for "no data"; pages pass `"DC3545"` (danger red) for the comparison service's error.*
