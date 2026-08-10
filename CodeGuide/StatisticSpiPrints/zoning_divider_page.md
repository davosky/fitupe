# `StatisticSpiPrints::ZoningDividerPage`

**File:** `app/services/statistic_spi_prints/zoning_divider_page.rb`

## Codice completo

```ruby
module StatisticSpiPrints
  # Come StatisticPrints::ZoningDividerPage ma con il logo CGIL+SPI e
  # l'etichetta "Sindacato Pensionati Italiani" al posto della dicitura
  # confederale generica.
  class ZoningDividerPage
    IMAGES_DIR = Rails.root.join("app/assets/images/statistic_prints")
    CGIL_SPI_LOGO = IMAGES_DIR.join("logo-cgil-spi.png")

    BLOCK_WIDTH_RATIO = 0.45
    ICON_HEIGHT = 56
    TITLE_SIZE = 26
    ICON_TITLE_GAP = 14
    RULE_GAP = 16
    FOOTER_GAP = 14
    FOOTER_ROW_HEIGHT = 16
    FOOTER_LOGO_HEIGHT = 14
    FOOTER_LABEL_SIZE = 9
    PERIOD_SIZE = 13

    def self.draw(...) = new(...).draw

    def initialize(pdf, zoning:, mese:, anno:)
      @pdf = pdf
      @zoning = zoning
      @mese = mese
      @anno = anno
    end

    def draw
      @pdf.fill_color "000000"
      draw_icon_and_title
      draw_rule
      draw_footer
    end

    private

    def block_width = @pdf.bounds.width * BLOCK_WIDTH_RATIO
    def block_left = @pdf.bounds.left + ((@pdf.bounds.width - block_width) / 2)
    def block_top = (@pdf.bounds.height / 2.0) + (block_height / 2.0)
    def block_height = ICON_HEIGHT + RULE_GAP + FOOTER_GAP + FOOTER_ROW_HEIGHT
    def rule_top = block_top - ICON_HEIGHT - RULE_GAP

    def draw_icon_and_title
      info = @pdf.image CGIL_SPI_LOGO.to_s, at: [ block_left, block_top ], height: ICON_HEIGHT
      title_left = block_left + info.scaled_width + ICON_TITLE_GAP
      @pdf.fill_color "000000"
      @pdf.font("AsapCondensed", style: :bold, size: TITLE_SIZE) do
        @pdf.text_box @zoning.descrizione_azzonamento, at: [ title_left, block_top - ((ICON_HEIGHT - TITLE_SIZE) / 2) ],
          width: block_left + block_width - title_left, height: ICON_HEIGHT, valign: :center
      end
    end

    def draw_rule
      @pdf.stroke_color "999999"
      @pdf.stroke_line [ block_left, rule_top ], [ block_left + block_width, rule_top ]
    end

    def draw_footer
      footer_top = rule_top - FOOTER_GAP
      info = @pdf.image CGIL_SPI_LOGO.to_s, at: [ block_left, footer_top ], height: FOOTER_LOGO_HEIGHT
      draw_footer_label(block_left + info.scaled_width + 6, footer_top)
      draw_footer_period(footer_top)
    end

    def draw_footer_label(left, top)
      @pdf.fill_color "000000"
      @pdf.font("AsapCondensed", size: FOOTER_LABEL_SIZE) do
        @pdf.text_box "Sindacato Pensionati Italiani", at: [ left, top ],
          width: block_left + block_width - left, height: FOOTER_ROW_HEIGHT, valign: :center
      end
    end

    def draw_footer_period(top)
      @pdf.fill_color "000000"
      @pdf.font("AsapCondensed", style: :italic, size: PERIOD_SIZE) do
        @pdf.text_box "Tesseramento #{@mese} #{@anno}", at: [ block_left, top ], width: block_width,
          height: FOOTER_ROW_HEIGHT, valign: :center, align: :right
      end
    end
  end
end
```

## Sezioni commentate

### Commento di classe

```ruby
# Come StatisticPrints::ZoningDividerPage ma con il logo CGIL+SPI e
# l'etichetta "Sindacato Pensionati Italiani" al posto della dicitura
# confederale generica.
class ZoningDividerPage
```

> **IT:** Il commento di classe dichiara onestamente cosa cambia, ed è tutto: questa classe è **byte-per-byte identica** a `StatisticPrints::ZoningDividerPage` in ogni riga di logica, layout, costanti geometriche (`BLOCK_WIDTH_RATIO`, `ICON_HEIGHT`, `TITLE_SIZE`, ecc. — nessuna diversa) e struttura dei metodi. Le uniche due differenze testuali sono: (1) la costante immagine, `CGIL_SPI_LOGO = IMAGES_DIR.join("logo-cgil-spi.png")` invece di `CGIL_LOGO = IMAGES_DIR.join("logo-cgil.png")`; (2) l'etichetta in `draw_footer_label`, `"Sindacato Pensionati Italiani"` invece di `"Confederazione Generale Italiana del Lavoro"`. È il file di questo pacchetto con la più alta percentuale di codice duplicato invariato rispetto al gemello Attivi — un candidato naturale, se mai si volesse ridurre la duplicazione, a diventare una singola classe parametrizzata su logo+etichetta, ma non lo è stata resa tale: la scelta stilistica in questo pacchetto (vedi anche `cover_page.md`, `back_cover_page.md`) è privilegiare due file paralleli e leggibili singolarmente piuttosto che un'astrazione condivisa con parametri.
>
> *EN: The class comment states honestly what changes, and that's everything: this class is **byte-for-byte identical** to `StatisticPrints::ZoningDividerPage` in every line of logic, layout, geometric constants (`BLOCK_WIDTH_RATIO`, `ICON_HEIGHT`, `TITLE_SIZE`, etc. — none differ) and method structure. The only two textual differences are: (1) the image constant, `CGIL_SPI_LOGO = IMAGES_DIR.join("logo-cgil-spi.png")` instead of `CGIL_LOGO = IMAGES_DIR.join("logo-cgil.png")`; (2) the label in `draw_footer_label`, `"Sindacato Pensionati Italiani"` instead of `"Confederazione Generale Italiana del Lavoro"`. It's the file in this package with the highest percentage of unchanged duplicated code relative to its Attivi twin — a natural candidate, if duplication were ever to be reduced, for becoming a single class parameterized on logo+label, but it hasn't been made so: the stylistic choice in this package (see also `cover_page.md`, `back_cover_page.md`) is to favor two parallel, individually readable files over a shared abstraction with parameters.*

### Costanti geometriche e `initialize`

```ruby
BLOCK_WIDTH_RATIO = 0.45
ICON_HEIGHT = 56
TITLE_SIZE = 26
ICON_TITLE_GAP = 14
RULE_GAP = 16
FOOTER_GAP = 14
FOOTER_ROW_HEIGHT = 16
FOOTER_LOGO_HEIGHT = 14
FOOTER_LABEL_SIZE = 9
PERIOD_SIZE = 13

def initialize(pdf, zoning:, mese:, anno:)
  @pdf = pdf
  @zoning = zoning
  @mese = mese
  @anno = anno
end
```

> **IT:** Tutte in punti PDF, non millimetri — a differenza di `CoverPage`/`LegendPage`, questa pagina non usa `mm_to_pt` da nessuna parte: le dimensioni sono state scelte direttamente in punti perché il layout è un blocco centrato di testo/icone (logo+titolo+riga+footer), non un posizionamento su un'immagine di sfondo misurata in millimetri. `initialize` accetta `zoning:` (l'oggetto, non l'id — stesso contratto visto in `StatisticSpi::ZoningPeriodScope`), `mese:` e `anno:` come stringhe separate, passate esplicitamente dal chiamante (`ReportPdf#draw_zoning_section`) invece che tramite un `form:` completo — a differenza di `CoverPage`/`LegendPage`, che ricevono `form:` intero. La ragione: questa pagina viene disegnata sia per l'azzonamento scelto sia, in un ciclo, per ogni comprensorio quando l'azzonamento è regionale (`ReportPdf#draw_province_sections`), con uno `zoning` diverso a ogni iterazione ma con lo stesso `mese`/`anno` del form originale — passare i tre valori separatamente evita di dover costruire un `form` completo (con `zoning_id`) per ogni comprensorio solo per disegnare questa pagina divisoria.
>
> *EN: All in PDF points, not millimeters — unlike `CoverPage`/`LegendPage`, this page uses `mm_to_pt` nowhere: the dimensions were chosen directly in points because the layout is a centered block of text/icons (logo+title+rule+footer), not positioning against a background image measured in millimeters. `initialize` accepts `zoning:` (the object, not its id — same contract seen in `StatisticSpi::ZoningPeriodScope`), `mese:` and `anno:` as separate strings, passed explicitly by the caller (`ReportPdf#draw_zoning_section`) rather than through a full `form:` — unlike `CoverPage`/`LegendPage`, which receive the whole `form:`. The reason: this page gets drawn both for the chosen zoning and, in a loop, for every comprensorio when the zoning is regional (`ReportPdf#draw_province_sections`), with a different `zoning` on each iteration but the same `mese`/`anno` from the original form — passing the three values separately avoids having to build a full `form` (with `zoning_id`) for every comprensorio just to draw this divider page.*

### `draw`, `block_width`/`block_left`/`block_top`/`block_height`/`rule_top`

```ruby
def draw
  @pdf.fill_color "000000"
  draw_icon_and_title
  draw_rule
  draw_footer
end

private

def block_width = @pdf.bounds.width * BLOCK_WIDTH_RATIO
def block_left = @pdf.bounds.left + ((@pdf.bounds.width - block_width) / 2)
def block_top = (@pdf.bounds.height / 2.0) + (block_height / 2.0)
def block_height = ICON_HEIGHT + RULE_GAP + FOOTER_GAP + FOOTER_ROW_HEIGHT
def rule_top = block_top - ICON_HEIGHT - RULE_GAP
```

> **IT:** `draw` imposta `fill_color "000000"` prima di tutto — necessario perché questa pagina è disegnata subito dopo `CoverPage` (via `pdf.start_new_page` in `ReportPdf#draw_zoning_section`), che lascia il colore attivo a `"FFFFFF"` (bianco, per il testo sulla copertina scura): senza questo reset, il titolo dell'azzonamento verrebbe disegnato in bianco su sfondo bianco, invisibile. È l'esempio concreto, in questo pacchetto, del gotcha "`fill_color` è stato documento-wide" citato in `cover_page.md`. I cinque metodi geometrici centrano il blocco (logo+titolo+riga+footer) sia orizzontalmente (`block_left`, a metà tra i due margini) sia verticalmente (`block_top`, calcolato da `block_height` per centrare l'intero blocco sul centro verticale della pagina) — nessuna `bounding_box`, tutto calcolato come coordinate assolute a partire da `@pdf.bounds`, che qui è l'area interna al margine configurato (15mm), non la pagina fisica intera come in `CoverPage`/`BackCoverPage` (questa pagina non è full-bleed, non è mai dentro un `pdf.canvas`).
>
> *EN: `draw` sets `fill_color "000000"` first thing — necessary because this page is drawn right after `CoverPage` (via `pdf.start_new_page` in `ReportPdf#draw_zoning_section`), which leaves the active color at `"FFFFFF"` (white, for the text over the dark cover): without this reset, the zoning title would be drawn white on white, invisible. It's the concrete example, in this package, of the "`fill_color` is document-wide state" gotcha mentioned in `cover_page.md`. The five geometry methods center the block (logo+title+rule+footer) both horizontally (`block_left`, midway between the two margins) and vertically (`block_top`, computed from `block_height` to center the whole block on the page's vertical center) — no `bounding_box`, everything computed as absolute coordinates from `@pdf.bounds`, which here is the margin-inset area (15mm), not the full physical page like in `CoverPage`/`BackCoverPage` (this page isn't full-bleed, never inside a `pdf.canvas`).*

### `draw_icon_and_title`, `draw_rule`

```ruby
def draw_icon_and_title
  info = @pdf.image CGIL_SPI_LOGO.to_s, at: [ block_left, block_top ], height: ICON_HEIGHT
  title_left = block_left + info.scaled_width + ICON_TITLE_GAP
  @pdf.fill_color "000000"
  @pdf.font("AsapCondensed", style: :bold, size: TITLE_SIZE) do
    @pdf.text_box @zoning.descrizione_azzonamento, at: [ title_left, block_top - ((ICON_HEIGHT - TITLE_SIZE) / 2) ],
      width: block_left + block_width - title_left, height: ICON_HEIGHT, valign: :center
  end
end

def draw_rule
  @pdf.stroke_color "999999"
  @pdf.stroke_line [ block_left, rule_top ], [ block_left + block_width, rule_top ]
end
```

> **IT:** `@pdf.image ... ` restituisce un oggetto `info` con `scaled_width`, usato per posizionare il titolo subito dopo il logo senza dover calcolare a mano la larghezza scalata dell'immagine (il logo CGIL+SPI ha un aspect ratio leggermente diverso dal logo CGIL puro, quindi `scaled_width` non è una costante fissa tra le due pagine gemelle). Il secondo `@pdf.fill_color "000000"` dentro `draw_icon_and_title` è ridondante rispetto a quello già impostato in `draw` — stessa difesa vista in `CoverPage`, per lo stesso motivo (stato documento-wide). Il titolo (`@zoning.descrizione_azzonamento`) è centrato verticalmente sull'altezza dell'icona tramite `valign: :center` più un offset manuale in `at:`; nessuna delle due tecniche da sola basterebbe: l'offset in `at:` posiziona il box, `valign: :center` centra il testo dentro il box una volta posizionato.
>
> *EN: `@pdf.image ...` returns an `info` object with `scaled_width`, used to position the title right after the logo without manually computing the image's scaled width (the CGIL+SPI logo has a slightly different aspect ratio than the plain CGIL logo, so `scaled_width` isn't a fixed constant shared between the two twin pages). The second `@pdf.fill_color "000000"` inside `draw_icon_and_title` is redundant given the one already set in `draw` — the same defensive pattern seen in `CoverPage`, for the same reason (document-wide state). The title (`@zoning.descrizione_azzonamento`) is vertically centered on the icon's height via `valign: :center` plus a manual offset in `at:`; neither technique alone would be enough: the `at:` offset positions the box, `valign: :center` centers the text within the box once positioned.*

### `draw_footer`, `draw_footer_label`, `draw_footer_period`

```ruby
def draw_footer
  footer_top = rule_top - FOOTER_GAP
  info = @pdf.image CGIL_SPI_LOGO.to_s, at: [ block_left, footer_top ], height: FOOTER_LOGO_HEIGHT
  draw_footer_label(block_left + info.scaled_width + 6, footer_top)
  draw_footer_period(footer_top)
end

def draw_footer_label(left, top)
  @pdf.fill_color "000000"
  @pdf.font("AsapCondensed", size: FOOTER_LABEL_SIZE) do
    @pdf.text_box "Sindacato Pensionati Italiani", at: [ left, top ],
      width: block_left + block_width - left, height: FOOTER_ROW_HEIGHT, valign: :center
  end
end

def draw_footer_period(top)
  @pdf.fill_color "000000"
  @pdf.font("AsapCondensed", style: :italic, size: PERIOD_SIZE) do
    @pdf.text_box "Tesseramento #{@mese} #{@anno}", at: [ block_left, top ], width: block_width,
      height: FOOTER_ROW_HEIGHT, valign: :center, align: :right
  end
end
```

> **IT:** Qui è dove compare la seconda (e ultima) differenza testuale rispetto alla versione Attivi: `"Sindacato Pensionati Italiani"` invece di `"Confederazione Generale Italiana del Lavoro"`. Il logo viene ridisegnato una seconda volta, più piccolo (`FOOTER_LOGO_HEIGHT = 14` contro `ICON_HEIGHT = 56` nell'header), non riutilizzando l'`info` di `draw_icon_and_title` — sono due chiamate `@pdf.image` indipendenti sulla stessa costante `CGIL_SPI_LOGO`, coerente con come Prawn richiede di ridisegnare un'immagine per ogni posizione/dimensione diversa (non c'è un concetto di "sprite" riutilizzabile). `draw_footer_period` usa `@mese`/`@anno` passati a `initialize`, non `@zoning` — è l'unico testo del blocco a non dipendere dal comprensorio corrente, motivo per cui rimane identico su tutte le pagine divisorie generate nel ciclo `draw_province_sections`.
>
> *EN: This is where the second (and last) textual difference from the Attivi version appears: `"Sindacato Pensionati Italiani"` instead of `"Confederazione Generale Italiana del Lavoro"`. The logo is redrawn a second time, smaller (`FOOTER_LOGO_HEIGHT = 14` versus `ICON_HEIGHT = 56` in the header), not reusing the `info` from `draw_icon_and_title` — these are two independent `@pdf.image` calls on the same `CGIL_SPI_LOGO` constant, consistent with how Prawn requires redrawing an image for every different position/size (there's no reusable "sprite" concept). `draw_footer_period` uses `@mese`/`@anno` passed to `initialize`, not `@zoning` — it's the one text in the block that doesn't depend on the current comprensorio, which is why it stays identical across every divider page generated in the `draw_province_sections` loop.*
