# `StatisticPrints::ZoningDividerPage`

**File:** `app/services/statistic_prints/zoning_divider_page.rb`

## Codice completo

```ruby
module StatisticPrints
  class ZoningDividerPage
    IMAGES_DIR = Rails.root.join("app/assets/images/statistic_prints")
    CGIL_LOGO = IMAGES_DIR.join("logo-cgil.png")

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
      info = @pdf.image CGIL_LOGO.to_s, at: [ block_left, block_top ], height: ICON_HEIGHT
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
      info = @pdf.image CGIL_LOGO.to_s, at: [ block_left, footer_top ], height: FOOTER_LOGO_HEIGHT
      draw_footer_label(block_left + info.scaled_width + 6, footer_top)
      draw_footer_period(footer_top)
    end

    def draw_footer_label(left, top)
      @pdf.fill_color "000000"
      @pdf.font("AsapCondensed", size: FOOTER_LABEL_SIZE) do
        @pdf.text_box "Confederazione Generale Italiana del Lavoro", at: [ left, top ],
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

### Costanti di geometria

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
```

> **IT:** A differenza di quasi ogni altro file Prawn della cartella (`ReportPdf`, `LegendPage`, `RegionalPage`), queste costanti sono in **punti Prawn diretti**, non in millimetri convertiti con `mm * 72 / 25.4` al punto d'uso. Non è un'incoerenza casuale: questa pagina non ha bisogno di allinearsi a nessun margine "fisico" o griglia condivisa con le altre pagine — è un layout autonomo, centrato sulla pagina, i cui valori sono stati con ogni probabilità tarati a occhio direttamente in punti durante lo sviluppo (56pt un'icona, 26pt un titolo) piuttosto che pensati in millimetri da un brief grafico. `BLOCK_WIDTH_RATIO`, invece, è l'unica costante espressa come frazione (45% della larghezza pagina), lo stesso approccio "relativo, non assoluto" visto in `CoverPage::PERIOD_BOX` ma qui applicato a una sola dimensione.
>
> *EN: Unlike almost every other Prawn file in the folder (`ReportPdf`, `LegendPage`, `RegionalPage`), these constants are in **raw Prawn points**, not millimeters converted via `mm * 72 / 25.4` at the point of use. This isn't accidental inconsistency: this page doesn't need to align to any "physical" margin or grid shared with other pages — it's a self-contained, page-centered layout whose values were most likely tuned by eye directly in points during development (56pt for an icon, 26pt for a title) rather than thought out in millimeters from a design brief. `BLOCK_WIDTH_RATIO`, on the other hand, is the one constant expressed as a fraction (45% of page width), the same "relative, not absolute" approach seen in `CoverPage::PERIOD_BOX` but applied here to a single dimension.*

### `draw`

```ruby
def draw
  @pdf.fill_color "000000"
  draw_icon_and_title
  draw_rule
  draw_footer
end
```

> **IT:** Il reset esplicito `@pdf.fill_color "000000"` qui non è opzionale: `ZoningDividerPage` è quasi sempre la prima pagina disegnata dopo `CoverPage` (che lascia `fill_color` bianco, vedi `cover_page.md`) — sia per la sezione dell'azzonamento scelto sia per ogni sezione di comprensorio ripetuta (`ReportPdf#draw_zoning_section`). Senza questo reset, il titolo dell'azzonamento sarebbe invisibile (bianco su sfondo bianco).
>
> *EN: The explicit `@pdf.fill_color "000000"` reset here isn't optional: `ZoningDividerPage` is almost always the first page drawn after `CoverPage` (which leaves `fill_color` white, see `cover_page.md`) — both for the chosen zoning's section and for every repeated comprensorio section (`ReportPdf#draw_zoning_section`). Without this reset, the zoning title would be invisible (white on white).*

### Metodi geometrici privati a una riga (`block_width`, `block_left`, `block_top`, `block_height`, `rule_top`)

```ruby
def block_width = @pdf.bounds.width * BLOCK_WIDTH_RATIO
def block_left = @pdf.bounds.left + ((@pdf.bounds.width - block_width) / 2)
def block_top = (@pdf.bounds.height / 2.0) + (block_height / 2.0)
def block_height = ICON_HEIGHT + RULE_GAP + FOOTER_GAP + FOOTER_ROW_HEIGHT
def rule_top = block_top - ICON_HEIGHT - RULE_GAP
```

> **IT:** Questi cinque metodi calcolano un unico "blocco" di contenuto (icona+titolo, riga separatrice, footer) centrato orizzontalmente e **verticalmente** nella pagina — `block_top` è il punto chiave: parte dal centro verticale della pagina (`@pdf.bounds.height / 2.0`) e sale di metà dell'altezza del blocco, così l'intero blocco risulta centrato rispetto al punto medio, non ancorato all'alto o al basso. Questa pagina non usa `bounding_box` né si affida al cursore automatico di Prawn (`@pdf.cursor`) proprio perché il contenuto va centrato in un punto preciso della pagina, non impilato dall'alto — è il tipo di layout per cui posizionare tutto con coordinate assolute (`at:`) è più semplice che dover ingannare il sistema di bounding box "stretchy" documentato altrove nella cartella (vedi le pagine `CONTENT_PAGES` per un contrasto).
>
> *EN: These five methods compute a single "block" of content (icon+title, divider rule, footer) centered both horizontally and **vertically** on the page — `block_top` is the key one: it starts from the page's vertical center (`@pdf.bounds.height / 2.0`) and moves up by half the block's height, so the whole block ends up centered on the midpoint rather than anchored to the top or bottom. This page uses no `bounding_box` and doesn't rely on Prawn's automatic cursor (`@pdf.cursor`) precisely because the content needs to be centered at a precise page point, not stacked from the top — the kind of layout where positioning everything with absolute coordinates (`at:`) is simpler than fighting the "stretchy" bounding-box behavior documented elsewhere in this folder (see the `CONTENT_PAGES` for a contrast).*

### `draw_icon_and_title`

```ruby
def draw_icon_and_title
  info = @pdf.image CGIL_LOGO.to_s, at: [ block_left, block_top ], height: ICON_HEIGHT
  title_left = block_left + info.scaled_width + ICON_TITLE_GAP
  @pdf.fill_color "000000"
  @pdf.font("AsapCondensed", style: :bold, size: TITLE_SIZE) do
    @pdf.text_box @zoning.descrizione_azzonamento, at: [ title_left, block_top - ((ICON_HEIGHT - TITLE_SIZE) / 2) ],
      width: block_left + block_width - title_left, height: ICON_HEIGHT, valign: :center
  end
end
```

> **IT:** `@pdf.image` ritorna un oggetto `info` con `scaled_width` — la larghezza effettiva a cui l'immagine è stata scalata dopo aver fissato `height: ICON_HEIGHT` mantenendo le proporzioni originali del PNG. Questo è l'unico modo per sapere dove posizionare il titolo accanto al logo **senza** dover calcolare a mano il rapporto d'aspetto del file `logo-cgil.png`: se il logo venisse sostituito con uno di proporzioni diverse, `title_left` si adatterebbe automaticamente. Da notare il secondo `@pdf.fill_color "000000"`, ridondante rispetto a quello già fatto in `draw` — non è un errore ma il primo caso della convenzione, ripetuta in `draw_footer_label`/`draw_footer_period`, di ri-affermare il colore nero **immediatamente prima** di ogni `text_box`, invece di fidarsi che sia rimasto impostato dall'inizio pagina: la difesa più aggressiva contro lo stato globale di `fill_color` vista in tutta la cartella.
>
> *EN: `@pdf.image` returns an `info` object with `scaled_width` — the actual width the image was scaled to after fixing `height: ICON_HEIGHT` while preserving the PNG's original aspect ratio. This is the only way to know where to place the title next to the logo **without** hand-computing `logo-cgil.png`'s aspect ratio: if the logo were ever swapped for one with different proportions, `title_left` would adapt automatically. Note the second `@pdf.fill_color "000000"`, redundant with the one already done in `draw` — not a mistake, but the first instance of a convention, repeated in `draw_footer_label`/`draw_footer_period`, of re-asserting black **immediately before** every `text_box` rather than trusting it stayed set from page start: the most aggressive defense against `fill_color`'s global state seen anywhere in the folder.*

### `draw_rule`

```ruby
def draw_rule
  @pdf.stroke_color "999999"
  @pdf.stroke_line [ block_left, rule_top ], [ block_left + block_width, rule_top ]
end
```

> **IT:** `stroke_color` è uno stato Prawn indipendente da `fill_color` — colora le linee/bordi, non i riempimenti di testo o forme. Impostarlo qui non rischia di "sporcare" il testo disegnato subito dopo in `draw_footer`, perché quest'ultimo usa sempre `fill_color`, mai `stroke_color`. Le due proprietà di colore vanno quindi tracciate e resettate separatamente quando serve — un dettaglio facile da dimenticare guardando un solo metodo alla volta.
>
> *EN: `stroke_color` is a Prawn state independent from `fill_color` — it colors lines/borders, not text or shape fills. Setting it here can't "leak" into the text drawn right after in `draw_footer`, because that text always uses `fill_color`, never `stroke_color`. The two color properties therefore need to be tracked and reset separately when it matters — an easy detail to miss when looking at just one method at a time.*

### `draw_footer`, `draw_footer_label`, `draw_footer_period`

```ruby
def draw_footer
  footer_top = rule_top - FOOTER_GAP
  info = @pdf.image CGIL_LOGO.to_s, at: [ block_left, footer_top ], height: FOOTER_LOGO_HEIGHT
  draw_footer_label(block_left + info.scaled_width + 6, footer_top)
  draw_footer_period(footer_top)
end

def draw_footer_label(left, top)
  @pdf.fill_color "000000"
  @pdf.font("AsapCondensed", size: FOOTER_LABEL_SIZE) do
    @pdf.text_box "Confederazione Generale Italiana del Lavoro", at: [ left, top ],
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

> **IT:** Il footer ridisegna il logo CGIL una seconda volta, più piccolo (`FOOTER_LOGO_HEIGHT` 14pt contro `ICON_HEIGHT` 56pt in testa), invece di riusare l'`info` già ottenuto in `draw_icon_and_title` — è una scelta corretta e non uno spreco: `scaled_width` dipende dall'`height` richiesta, quindi un `info` calcolato per 56pt non sarebbe valido per posizionare un logo da 14pt; l'immagine va ridisegnata con la nuova altezza per ottenere il nuovo `scaled_width` corretto per `draw_footer_label`. `draw_footer_label` e `draw_footer_period` condividono lo stesso `top` (allineati sulla stessa riga orizzontale) ma sono allineati diversamente: l'etichetta a sinistra (`align:` di default, cioè `:left`), il periodo a destra (`align: :right`) nello stesso `block_width`, così i due testi occupano gli estremi opposti della riga senza sovrapporsi, un po' come un footer a due colonne senza usare `column_box`.
>
> *EN: The footer redraws the CGIL logo a second time, smaller (`FOOTER_LOGO_HEIGHT` 14pt versus `ICON_HEIGHT` 56pt up top), instead of reusing the `info` already obtained in `draw_icon_and_title` — that's the correct choice, not wasted work: `scaled_width` depends on the requested `height`, so an `info` computed for 56pt wouldn't be valid for positioning a 14pt logo; the image has to be redrawn at the new height to get the correct new `scaled_width` for `draw_footer_label`. `draw_footer_label` and `draw_footer_period` share the same `top` (aligned on the same horizontal row) but are aligned differently: the label to the left (default `align:`, i.e. `:left`), the period to the right (`align: :right`) within the same `block_width`, so the two texts sit at opposite ends of the row without overlapping — a bit like a two-column footer without using `column_box`.*
