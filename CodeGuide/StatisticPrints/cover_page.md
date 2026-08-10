# `StatisticPrints::CoverPage`

**File:** `app/services/statistic_prints/cover_page.rb`

## Codice completo

```ruby
module StatisticPrints
  class CoverPage
    BACKGROUND_IMAGE = Rails.root.join("app/assets/images/statistic_prints/cover_background.png")

    # Fraction-based box (relative to the background image) where the blank
    # space for the dynamic period text sits, below the "Statistiche" headline.
    PERIOD_BOX = { left: 0.5675, top: 0.4662, width: 0.4141, height: 0.0772 }.freeze

    def self.draw(...) = new(...).draw

    def initialize(pdf, form:)
      @pdf = pdf
      @form = form
    end

    def draw
      draw_background
      draw_period
    end

    private

    def draw_background
      @pdf.image BACKGROUND_IMAGE.to_s, at: [ 0, @pdf.bounds.top ], width: @pdf.bounds.width, height: @pdf.bounds.height
    end

    def draw_period
      @pdf.fill_color "FFFFFF"
      @pdf.font("AsapCondensed", size: 26) do
        @pdf.text_box "#{@form.mese} #{@form.anno}", **period_box, align: :left
      end
    end

    def period_box
      width = @pdf.bounds.width
      height = @pdf.bounds.height
      {
        at: [ PERIOD_BOX[:left] * width, height - (PERIOD_BOX[:top] * height) ],
        width: PERIOD_BOX[:width] * width, height: PERIOD_BOX[:height] * height
      }
    end
  end
end
```

## Sezioni commentate

### `BACKGROUND_IMAGE`, `PERIOD_BOX`

```ruby
BACKGROUND_IMAGE = Rails.root.join("app/assets/images/statistic_prints/cover_background.png")

# Fraction-based box (relative to the background image) where the blank
# space for the dynamic period text sits, below the "Statistiche" headline.
PERIOD_BOX = { left: 0.5675, top: 0.4662, width: 0.4141, height: 0.0772 }.freeze
```

> **IT:** Questa classe segue il pattern descritto nella memoria di progetto per i mockup PDF statici: davo fornisce un PNG ad alta risoluzione con l'intera grafica di copertina (logo, titolo "Statistiche", decorazioni) già disegnata, e Prawn si limita a sovrapporre il testo dinamico (il periodo) sopra un riquadro vuoto lasciato apposta nel PNG — non è una ricostruzione vettoriale della grafica in Prawn. `PERIOD_BOX` codifica quel riquadro come **frazioni** (0–1) delle dimensioni dell'immagine, non come punti assoluti: questa è la scelta che rende la posizione del testo indipendente dalla risoluzione del PNG e dalle dimensioni fisiche della pagina — se un giorno lo sfondo cambiasse dimensione in pixel, le frazioni misurate a occhio sull'immagine originale (con un editor grafico) restano valide senza ricalcoli, perché vengono moltiplicate per `@pdf.bounds.width/height` al momento del disegno, non hardcodate in mm o pt come nel resto della cartella.
>
> *EN: This class follows the pattern described in the project memory for static PDF mockups: davo supplies a high-resolution PNG with the entire cover artwork already drawn (logo, "Statistiche" headline, decorations), and Prawn just overlays the dynamic text (the period) on top of a blank box left on purpose in the PNG — it's not a vector reconstruction of the artwork in Prawn. `PERIOD_BOX` encodes that box as **fractions** (0–1) of the image dimensions, not absolute points: this is the choice that makes the text position independent of the PNG's resolution and the page's physical dimensions — if the background were ever resized in pixels, the fractions measured by eye on the original image (with a graphics editor) stay valid with no recalculation, because they're multiplied by `@pdf.bounds.width/height` at draw time instead of being hardcoded in mm or pt like the rest of the folder.*

### `draw`, `draw_background`

```ruby
def draw
  draw_background
  draw_period
end

def draw_background
  @pdf.image BACKGROUND_IMAGE.to_s, at: [ 0, @pdf.bounds.top ], width: @pdf.bounds.width, height: @pdf.bounds.height
end
```

> **IT:** `CoverPage` non chiama mai `pdf.canvas` da sola: è `StatisticPrints::ReportPdf#call` a invocarla dentro `pdf.canvas { CoverPage.draw(pdf, form: @form) }` (vedi `report_pdf.md`). Il full-bleed è quindi responsabilità del chiamante, non di questa classe — `draw_background` si limita a leggere `@pdf.bounds`, che dentro `canvas` corrisponde già all'intera pagina fisica A4 invece che all'area dentro il margine di 15mm configurato in `ReportPdf`. Questo disaccoppiamento (canvas deciso fuori, dimensioni lette dentro) è ciò che permette a `draw_period`/`period_box` di usare `@pdf.bounds.width/height` senza doversi preoccupare di sapere se sono dentro un canvas o no.
>
> *EN: `CoverPage` never calls `pdf.canvas` itself: it's `StatisticPrints::ReportPdf#call` that invokes it inside `pdf.canvas { CoverPage.draw(pdf, form: @form) }` (see `report_pdf.md`). Full-bleed is therefore the caller's responsibility, not this class's — `draw_background` simply reads `@pdf.bounds`, which inside `canvas` already corresponds to the entire physical A4 page rather than the area inside `ReportPdf`'s configured 15mm margin. This decoupling (canvas decided outside, dimensions read inside) is what lets `draw_period`/`period_box` use `@pdf.bounds.width/height` without needing to know whether they're inside a canvas or not.*

### `draw_period`

```ruby
def draw_period
  @pdf.fill_color "FFFFFF"
  @pdf.font("AsapCondensed", size: 26) do
    @pdf.text_box "#{@form.mese} #{@form.anno}", **period_box, align: :left
  end
end
```

> **IT:** Questa è l'origine del gotcha di `fill_color` documentato nella memoria di progetto e richiamato in `report_pdf.md`: `CoverPage` è la **prima** pagina disegnata nel documento, ed è l'unica di tutta la cartella `StatisticPrints` a impostare `fill_color` su bianco (`"FFFFFF"`) invece che nero. Poiché `fill_color` in Prawn è stato globale al documento e non scoped al blocco `pdf.canvas` né alla pagina, ogni pagina disegnata dopo (`LegendPage`, `ZoningDividerPage`, tutte le `CONTENT_PAGES`) deve iniziare il proprio `draw` con un `@pdf.fill_color "000000"` esplicito, altrimenti il loro testo — pensato per essere nero su sfondo bianco — erediterebbe silenziosamente il bianco lasciato qui e diventerebbe invisibile.
>
> *EN: This is the origin of the `fill_color` gotcha documented in project memory and referenced in `report_pdf.md`: `CoverPage` is the **first** page drawn in the document, and the only one in the whole `StatisticPrints` folder that sets `fill_color` to white (`"FFFFFF"`) instead of black. Because `fill_color` in Prawn has always been global to the document, not scoped to the `pdf.canvas` block nor to the page, every page drawn afterward (`LegendPage`, `ZoningDividerPage`, all the `CONTENT_PAGES`) must start its own `draw` with an explicit `@pdf.fill_color "000000"` — otherwise their text, meant to be black on a white background, would silently inherit the white left here and become invisible.*

### `period_box`

```ruby
def period_box
  width = @pdf.bounds.width
  height = @pdf.bounds.height
  {
    at: [ PERIOD_BOX[:left] * width, height - (PERIOD_BOX[:top] * height) ],
    width: PERIOD_BOX[:width] * width, height: PERIOD_BOX[:height] * height
  }
end
```

> **IT:** La riga `height - (PERIOD_BOX[:top] * height)` non è ridondante: converte una frazione "distanza dall'alto" (il modo naturale in cui si misura un riquadro guardando un'immagine in un editor grafico, dove l'origine è in alto a sinistra) nella coordinata `y` che Prawn si aspetta per `at:`, dove l'origine è in **basso** a sinistra della pagina. Senza questa inversione, il testo del periodo comparirebbe specchiato verticalmente rispetto a dove dovrebbe stare rispetto allo sfondo. `PERIOD_BOX[:left]`/`[:width]` invece non hanno bisogno di alcuna inversione, perché l'asse orizzontale ha la stessa direzione sia nell'editor grafico sia nel sistema di coordinate di Prawn.
>
> *EN: The line `height - (PERIOD_BOX[:top] * height)` isn't redundant: it converts a "distance from the top" fraction (the natural way to measure a box while looking at an image in a graphics editor, whose origin is top-left) into the `y` coordinate Prawn expects for `at:`, whose origin is at the **bottom**-left of the page. Without this inversion, the period text would appear vertically mirrored relative to where it should sit against the background. `PERIOD_BOX[:left]`/`[:width]`, on the other hand, need no inversion, because the horizontal axis points the same way in both the graphics editor and Prawn's coordinate system.*
