# `StatisticSpiPrints::CoverPage`

**File:** `app/services/statistic_spi_prints/cover_page.rb`

## Codice completo

```ruby
module StatisticSpiPrints
  class CoverPage
    BACKGROUND_IMAGE = Rails.root.join("app/assets/images/statistic_prints/cover_background_spi.png")

    # Fraction-based boxes (relative to the background image) where the blank
    # spaces for the dynamic azzonamento/mese/anno text sit.
    ZONING_BOX = { left: 0.8164, top: 0.1411, width: 0.1240, height: 0.0290 }.freeze
    MONTH_BOX = { left: 0.8073, top: 0.2540, width: 0.0892, height: 0.0423 }.freeze
    YEAR_BOX = { left: 0.8965, top: 0.2540, width: 0.0656, height: 0.0423 }.freeze

    def self.draw(...) = new(...).draw

    def initialize(pdf, form:)
      @pdf = pdf
      @form = form
    end

    def draw
      draw_background
      draw_zoning
      draw_month
      draw_year
    end

    private

    def draw_background
      @pdf.image BACKGROUND_IMAGE.to_s, at: [ 0, @pdf.bounds.top ], width: @pdf.bounds.width, height: @pdf.bounds.height
    end

    def draw_zoning
      @pdf.fill_color "FFFFFF"
      @pdf.font("AsapCondensed", size: 13) do
        @pdf.text_box @form.zoning.descrizione_azzonamento, **fractional_box(ZONING_BOX), align: :left
      end
    end

    def draw_month
      @pdf.fill_color "FFFFFF"
      @pdf.font("AsapCondensed", size: 20) do
        @pdf.text_box @form.mese, **fractional_box(MONTH_BOX), align: :center
      end
    end

    def draw_year
      @pdf.fill_color "FFFFFF"
      @pdf.font("AsapCondensed", size: 20) do
        @pdf.text_box @form.anno, **fractional_box(YEAR_BOX), align: :center
      end
    end

    def fractional_box(box)
      width = @pdf.bounds.width
      height = @pdf.bounds.height
      {
        at: [ box[:left] * width, height - (box[:top] * height) ],
        width: box[:width] * width, height: box[:height] * height
      }
    end
  end
end
```

## Sezioni commentate

### `BACKGROUND_IMAGE`

```ruby
BACKGROUND_IMAGE = Rails.root.join("app/assets/images/statistic_prints/cover_background_spi.png")
```

> **IT:** L'unico asset diverso rispetto a `StatisticPrints::CoverPage`: un PNG dedicato (`cover_background_spi.png`), non lo stesso file dell'Attivi con testo diverso sovrapposto. Vive però nella **stessa cartella** `app/assets/images/statistic_prints/` dell'immagine Attivi, non in una sottocartella `_spi` separata — la convenzione di naming (suffisso `_spi` sul nome file) basta a distinguerle senza bisogno di un albero di cartelle parallelo. Lo stesso pattern si ripete per `backcover_background_spi.png` (vedi `back_cover_page.md`) e `logo-cgil-spi.png` (vedi `zoning_divider_page.md`).
>
> *EN: The one asset that actually differs from `StatisticPrints::CoverPage`: a dedicated PNG (`cover_background_spi.png`), not the same file as Attivi with different text overlaid. It lives in the **same** `app/assets/images/statistic_prints/` folder as the Attivi image though, not a separate `_spi` subfolder — the naming convention (`_spi` filename suffix) is enough to tell them apart without a parallel folder tree. The same pattern repeats for `backcover_background_spi.png` (see `back_cover_page.md`) and `logo-cgil-spi.png` (see `zoning_divider_page.md`).*

### `ZONING_BOX`, `MONTH_BOX`, `YEAR_BOX`

```ruby
# Fraction-based boxes (relative to the background image) where the blank
# spaces for the dynamic azzonamento/mese/anno text sit.
ZONING_BOX = { left: 0.8164, top: 0.1411, width: 0.1240, height: 0.0290 }.freeze
MONTH_BOX = { left: 0.8073, top: 0.2540, width: 0.0892, height: 0.0423 }.freeze
YEAR_BOX = { left: 0.8965, top: 0.2540, width: 0.0656, height: 0.0423 }.freeze
```

> **IT:** Questa è la vera differenza strutturale rispetto a `StatisticPrints::CoverPage`, non solo di immagine: la copertina Attivi ha **un solo** box frazionario (`PERIOD_BOX`, per il testo `"#{mese} #{anno}"` come stringa unica), la copertina SPI ne ha **tre**, distinti e disegnati separatamente (`draw_zoning`, `draw_month`, `draw_year`) perché il mockup grafico dell'artwork SPI (fornito da Davo come PNG ad alta risoluzione, non ricostruito vettorialmente in Prawn — vedi `feedback_fitupe_pdf_mockup_approach.md`) riserva tre spazi vuoti separati nel design, non uno solo, e include anche l'azzonamento (assente nella copertina Attivi, dove compaiono solo mese e anno). Le coordinate sono frazioni (0–1) delle dimensioni del PNG di sfondo, misurate a mano sul mockup — da ritoccare se l'artwork cambia, non calcolabili da altre costanti.
>
> *EN: This is the real structural difference from `StatisticPrints::CoverPage`, not just the image: the Attivi cover has **one** fractional box (`PERIOD_BOX`, for the `"#{mese} #{anno}"` text as a single string), the SPI cover has **three**, distinct and drawn separately (`draw_zoning`, `draw_month`, `draw_year`) because the SPI artwork mockup (supplied by Davo as a high-resolution PNG, not vector-reconstructed in Prawn — see `feedback_fitupe_pdf_mockup_approach.md`) reserves three separate blank spaces in the design, not one, and also includes the zoning label (absent on the Attivi cover, where only month and year appear). The coordinates are fractions (0–1) of the background PNG's dimensions, measured by hand against the mockup — to be retouched if the artwork changes, not derivable from other constants.*

### `initialize`, `draw`

```ruby
def initialize(pdf, form:)
  @pdf = pdf
  @form = form
end

def draw
  draw_background
  draw_zoning
  draw_month
  draw_year
end
```

> **IT:** `draw` orchestra quattro passaggi invece dei due della versione Attivi (`draw_background`, `draw_period`) — riflesso diretto dei tre box separati sopra. L'ordine non è arbitrario per la resa visiva (i tre testi non si sovrappongono, ognuno ha il proprio box), ma è comunque irrilevante per Prawn: `text_box` con `at:` esplicito disegna a coordinate assolute indipendenti, senza avanzare un cursore condiviso, quindi l'ordine tra `draw_zoning`/`draw_month`/`draw_year` potrebbe essere invertito senza effetti collaterali.
>
> *EN: `draw` orchestrates four steps instead of the Attivi version's two (`draw_background`, `draw_period`) — a direct reflection of the three separate boxes above. The order isn't arbitrary for the visual result (the three texts don't overlap, each has its own box), but it's irrelevant to Prawn either way: `text_box` with an explicit `at:` draws at independent absolute coordinates, without advancing a shared cursor, so the order among `draw_zoning`/`draw_month`/`draw_year` could be swapped with no side effects.*

### `draw_background`

```ruby
def draw_background
  @pdf.image BACKGROUND_IMAGE.to_s, at: [ 0, @pdf.bounds.top ], width: @pdf.bounds.width, height: @pdf.bounds.height
end
```

> **IT:** Identico, riga per riga, a `StatisticPrints::CoverPage#draw_background`. Funziona solo perché questo metodo viene sempre invocato dentro un blocco `pdf.canvas { ... }` in `ReportPdf#call` (`pdf.canvas { CoverPage.draw(pdf, form: @form) }`): `canvas` rimappa temporaneamente `pdf.bounds` a tutta la pagina fisica, ignorando il margine configurato del documento (15mm su tutti i lati), così l'immagine copre l'intera A4 orizzontale bordo a bordo (full-bleed) invece di fermarsi al margine. Senza quel `canvas`, `@pdf.bounds` qui restituirebbe l'area interna al margine, e lo sfondo non arriverebbe ai bordi della pagina stampata.
>
> *EN: Identical, line for line, to `StatisticPrints::CoverPage#draw_background`. It only works because this method is always invoked inside a `pdf.canvas { ... }` block in `ReportPdf#call` (`pdf.canvas { CoverPage.draw(pdf, form: @form) }`): `canvas` temporarily remaps `pdf.bounds` to the entire physical page, ignoring the document's configured margin (15mm on all sides), so the image covers the whole landscape A4 edge to edge (full-bleed) instead of stopping at the margin. Without that `canvas`, `@pdf.bounds` here would return the margin-inset area, and the background wouldn't reach the printed page's edges.*

### `draw_zoning`, `draw_month`, `draw_year`

```ruby
def draw_zoning
  @pdf.fill_color "FFFFFF"
  @pdf.font("AsapCondensed", size: 13) do
    @pdf.text_box @form.zoning.descrizione_azzonamento, **fractional_box(ZONING_BOX), align: :left
  end
end

def draw_month
  @pdf.fill_color "FFFFFF"
  @pdf.font("AsapCondensed", size: 20) do
    @pdf.text_box @form.mese, **fractional_box(MONTH_BOX), align: :center
  end
end

def draw_year
  @pdf.fill_color "FFFFFF"
  @pdf.font("AsapCondensed", size: 20) do
    @pdf.text_box @form.anno, **fractional_box(YEAR_BOX), align: :center
  end
end
```

> **IT:** Ogni metodo reimposta `@pdf.fill_color "FFFFFF"` prima di disegnare, anche se il colore era già bianco dal metodo precedente nella stessa `draw` — ridondante qui, ma deliberatamente difensivo: `fill_color` in Prawn è stato globale al documento (non scoped al blocco `font`/`text_box`), quindi se in futuro una quarta sezione venisse inserita tra due di queste senza reimpostare il colore, erediterebbe silenziosamente qualunque colore lasciato dall'ultima chiamata. La prossima pagina disegnata dopo la copertina (`LegendPage` o `ZoningDividerPage`, entrambe con testo nero) reimposta comunque il proprio `fill_color "000000"` a inizio `draw`, quindi il bianco lasciato qui non si propaga oltre — ma è comunque il primo punto della catena in cui va tenuto a mente questo comportamento "documento-wide" del colore. `align: :left` per l'azzonamento contro `align: :center` per mese/anno rispecchia semplicemente il mockup grafico: il campo azzonamento è più largo e allineato al bordo sinistro del suo box, mese/anno sono centrati in caselle strette.
>
> *EN: Each method resets `@pdf.fill_color "FFFFFF"` before drawing, even though the color was already white from the previous method in the same `draw` — redundant here, but deliberately defensive: `fill_color` in Prawn has been document-wide state (not scoped to the `font`/`text_box` block), so if a fourth section were ever inserted between two of these without resetting the color, it would silently inherit whatever color the last call left behind. The next page drawn after the cover (`LegendPage` or `ZoningDividerPage`, both with black text) resets its own `fill_color "000000"` at the start of `draw` regardless, so the white left here doesn't propagate further — but it's still the first link in the chain where this "document-wide" color behavior needs to be kept in mind. `align: :left` for the zoning label versus `align: :center` for month/year simply mirrors the artwork mockup: the zoning field is wider and left-aligned within its box, month/year are centered in narrow boxes.*

### `fractional_box`

```ruby
def fractional_box(box)
  width = @pdf.bounds.width
  height = @pdf.bounds.height
  {
    at: [ box[:left] * width, height - (box[:top] * height) ],
    width: box[:width] * width, height: box[:height] * height
  }
end
```

> **IT:** Identico, riga per riga, a `StatisticPrints::CoverPage#period_box` — stesso meccanismo di conversione da coordinate frazionarie (relative all'immagine, origine in alto a sinistra come in un editor grafico) a coordinate Prawn (origine in basso a sinistra, da cui `height - (box[:top] * height)`). L'unica differenza è di forma: qui è un metodo generico che accetta un box come parametro (riusato da tre chiamanti, `ZONING_BOX`/`MONTH_BOX`/`YEAR_BOX`), mentre la versione Attivi è specializzata su un solo box (`PERIOD_BOX`) e non ha bisogno di essere parametrizzata avendo un solo chiamante. Se una futura copertina (Attivi o SPI) avesse bisogno di più di un box frazionario, conviene generalizzare seguendo questa forma piuttosto che duplicare `period_box`.
>
> *EN: Identical, line for line, to `StatisticPrints::CoverPage#period_box` — same mechanism for converting fractional coordinates (relative to the image, origin top-left as in a graphics editor) into Prawn coordinates (origin bottom-left, hence `height - (box[:top] * height)`). The only difference is shape: here it's a generic method taking a box as a parameter (reused by three callers, `ZONING_BOX`/`MONTH_BOX`/`YEAR_BOX`), while the Attivi version is specialized to a single box (`PERIOD_BOX`) and doesn't need to be parameterized since it has only one caller. If a future cover page (Attivi or SPI) ever needs more than one fractional box, it's worth generalizing along these lines rather than duplicating `period_box`.*
