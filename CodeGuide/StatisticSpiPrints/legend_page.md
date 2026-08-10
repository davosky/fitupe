# `StatisticSpiPrints::LegendPage`

**File:** `app/services/statistic_spi_prints/legend_page.rb`

## Codice completo

```ruby
module StatisticSpiPrints
  class LegendPage
    LIST_INDENT_MM = 5

    def self.draw(...) = new(...).draw

    def initialize(pdf, form:)
      @pdf = pdf
      @form = form
    end

    def draw
      @pdf.fill_color "000000"
      draw_heading
      draw_body
    end

    private

    def draw_heading
      @pdf.font("AsapCondensed", style: :bold, size: 16) { @pdf.text "Legenda" }
      @pdf.move_down 2
      @pdf.font("AsapCondensed", size: 10) { @pdf.text "Tesseramento #{@form.mese} #{@form.anno}", color: "666666" }
      @pdf.move_down 8
      @pdf.stroke_color "CCCCCC"
      @pdf.stroke_horizontal_rule
      @pdf.move_down 10
    end

    def draw_body
      @pdf.font("AsapCondensed", size: 11) do
        StatisticPrints::LegendContent.blocks(@form.legend_spi.description).each { |block| draw_block(block) }
      end
    end

    def draw_block(block)
      case block[:type]
      when :heading then draw_text(block[:text], size: 14, style: :bold)
      when :list_item then draw_list_item(block)
      when :quote then draw_quote(block)
      when :rule then draw_rule
      else draw_text(block[:text], align: block[:align] || :left)
      end
      @pdf.move_down 6
    end

    def draw_list_item(block)
      @pdf.indent(list_indent) { draw_text("#{block[:prefix]}  #{block[:text]}", align: block[:align] || :left) }
    end

    def draw_quote(block)
      @pdf.indent(list_indent) { draw_text(block[:text], style: :italic, color: "666666") }
    end

    def draw_rule
      @pdf.stroke_color "CCCCCC"
      @pdf.stroke_horizontal_rule
    end

    def draw_text(text, size: 11, style: :normal, color: "000000", align: :left)
      return if text.blank?

      @pdf.font("AsapCondensed", size: size, style: style) { @pdf.text text, inline_format: true, color: color, align: align }
    end

    def list_indent = LIST_INDENT_MM * 72 / 25.4
  end
end
```

## Sezioni commentate

### Panoramica della classe

> **IT:** Di tutte e cinque le pagine documentate in questa cartella, `LegendPage` è quella con la differenza più piccola e più facile da perdere rispetto al gemello Attivi (`StatisticPrints::LegendPage`): una sola riga cambia, dentro `draw_body`. Tutto il resto — `LIST_INDENT_MM`, `draw`, `draw_heading`, `draw_block`, `draw_list_item`, `draw_quote`, `draw_rule`, `draw_text`, `list_indent` — è identico, riga per riga, incluso il fatto che entrambe le classi si chiamano `LegendPage` in moduli diversi (`StatisticSpiPrints::LegendPage` qui, `StatisticPrints::LegendPage` nell'Attivi), quindi non c'è ambiguità di riferimento nonostante il nome uguale.
>
> *EN: Of all five pages documented in this folder, `LegendPage` has the smallest and easiest-to-miss difference from its Attivi twin (`StatisticPrints::LegendPage`): a single line changes, inside `draw_body`. Everything else — `LIST_INDENT_MM`, `draw`, `draw_heading`, `draw_block`, `draw_list_item`, `draw_quote`, `draw_rule`, `draw_text`, `list_indent` — is identical, line for line, including the fact that both classes are named `LegendPage` in different modules (`StatisticSpiPrints::LegendPage` here, `StatisticPrints::LegendPage` for Attivi), so there's no reference ambiguity despite the shared name.*

### `initialize`, `draw`, `draw_heading`

```ruby
def initialize(pdf, form:)
  @pdf = pdf
  @form = form
end

def draw
  @pdf.fill_color "000000"
  draw_heading
  draw_body
end

def draw_heading
  @pdf.font("AsapCondensed", style: :bold, size: 16) { @pdf.text "Legenda" }
  @pdf.move_down 2
  @pdf.font("AsapCondensed", size: 10) { @pdf.text "Tesseramento #{@form.mese} #{@form.anno}", color: "666666" }
  @pdf.move_down 8
  @pdf.stroke_color "CCCCCC"
  @pdf.stroke_horizontal_rule
  @pdf.move_down 10
end
```

> **IT:** `fill_color "000000"` a inizio `draw` ha lo stesso scopo difensivo visto in `ZoningDividerPage`: questa pagina, quando disegnata (solo se `@form.legend_spi` è presente, decisione presa a monte da `ReportPdf#draw_legend`), viene sempre subito dopo la copertina — stessa necessità di azzerare il bianco lasciato da `CoverPage`. `draw_heading` usa `@form.mese`/`@form.anno`, esattamente come in `ZoningDividerPage`, non `@form.legend_spi.mese`/`.anno`: il periodo mostrato in intestazione è sempre quello scelto nel form di stampa, non un campo del modello `LegendSpi`, che infatti non è coinvolto qui — entra in gioco solo dentro `draw_body`.
>
> *EN: `fill_color "000000"` at the start of `draw` serves the same defensive purpose seen in `ZoningDividerPage`: this page, when drawn (only if `@form.legend_spi` is present, a decision made upstream by `ReportPdf#draw_legend`), always immediately follows the cover — same need to zero out the white left by `CoverPage`. `draw_heading` uses `@form.mese`/`@form.anno`, exactly as in `ZoningDividerPage`, not `@form.legend_spi.mese`/`.anno`: the period shown in the heading is always the one chosen in the print form, not a field of the `LegendSpi` model, which in fact isn't involved here at all — it only comes into play inside `draw_body`.*

### `draw_body` — l'unica riga che cambia

```ruby
def draw_body
  @pdf.font("AsapCondensed", size: 11) do
    StatisticPrints::LegendContent.blocks(@form.legend_spi.description).each { |block| draw_block(block) }
  end
end
```

> **IT:** L'unica differenza reale del file, ed è doppia nella stessa riga: (1) `@form.legend_spi.description` invece di `@form.legend.description` — due modelli distinti (`LegendSpi` e `Legend`, in `app/models/`), con lo stesso campo `description` (probabilmente un campo Action Text, vedi `reference_fitupe_actiontext_trix_gotchas.md`), ciascuno gestito e compilato indipendentemente dall'amministratore per l'area Attivi o SPI; (2) `StatisticPrints::LegendContent.blocks(...)` — **non** `StatisticSpiPrints::LegendContent`, che non esiste. Il parser che spezza l'HTML di Action Text in blocchi tipizzati (`:heading`, `:list_item`, `:quote`, `:rule`, testo semplice) è condiviso, definito una sola volta nel modulo Attivi e riusato qui senza reimplementazione. È il punto di accoppiamento diretto tra `StatisticSpiPrints` e `StatisticPrints`, analogo a quanto già osservato per `BANDS`/`AGE_EXPR` condivisi tra `Statistics::AgeBreakdown` e `StatisticSpi::AgeBreakdown` (vedi `CodeGuide/StatisticSpi/README.md`): il parsing HTML→blocchi non ha nulla di specifico per Attivi o SPI, quindi non è stato duplicato. Attenzione se `StatisticPrints::LegendContent` viene mai spostato o rinominato: questo file smetterebbe silenziosamente di compilare (errore a runtime, non a caricamento, essendo Ruby) finché non viene aggiornato il riferimento qui.
>
> *EN: The file's one real difference, and it's twofold on the same line: (1) `@form.legend_spi.description` instead of `@form.legend.description` — two distinct models (`LegendSpi` and `Legend`, under `app/models/`), sharing the same `description` field (likely an Action Text field, see `reference_fitupe_actiontext_trix_gotchas.md`), each managed and authored independently by the admin for the Attivi or SPI area; (2) `StatisticPrints::LegendContent.blocks(...)` — **not** `StatisticSpiPrints::LegendContent`, which doesn't exist. The parser that splits the Action Text HTML into typed blocks (`:heading`, `:list_item`, `:quote`, `:rule`, plain text) is shared, defined once in the Attivi module and reused here without reimplementation. It's the direct coupling point between `StatisticSpiPrints` and `StatisticPrints`, analogous to the shared `BANDS`/`AGE_EXPR` already noted between `Statistics::AgeBreakdown` and `StatisticSpi::AgeBreakdown` (see `CodeGuide/StatisticSpi/README.md`): the HTML→blocks parsing has nothing Attivi- or SPI-specific about it, so it wasn't duplicated. Worth watching if `StatisticPrints::LegendContent` is ever moved or renamed: this file would silently stop working (a runtime error, not a load-time one, being Ruby) until the reference here is updated.*

### `draw_block`, `draw_list_item`, `draw_quote`, `draw_rule`, `draw_text`, `list_indent`

```ruby
def draw_block(block)
  case block[:type]
  when :heading then draw_text(block[:text], size: 14, style: :bold)
  when :list_item then draw_list_item(block)
  when :quote then draw_quote(block)
  when :rule then draw_rule
  else draw_text(block[:text], align: block[:align] || :left)
  end
  @pdf.move_down 6
end

def draw_list_item(block)
  @pdf.indent(list_indent) { draw_text("#{block[:prefix]}  #{block[:text]}", align: block[:align] || :left) }
end

def draw_quote(block)
  @pdf.indent(list_indent) { draw_text(block[:text], style: :italic, color: "666666") }
end

def draw_rule
  @pdf.stroke_color "CCCCCC"
  @pdf.stroke_horizontal_rule
end

def draw_text(text, size: 11, style: :normal, color: "000000", align: :left)
  return if text.blank?

  @pdf.font("AsapCondensed", size: size, style: style) { @pdf.text text, inline_format: true, color: color, align: align }
end

def list_indent = LIST_INDENT_MM * 72 / 25.4
```

> **IT:** Sei metodi identici, riga per riga, alla versione Attivi — nessuno interpreta `@form.legend_spi` o `@form.legend` direttamente, lavorano tutti sui blocchi già tipizzati restituiti da `LegendContent.blocks`, quindi non hanno nessuna ragione di differire tra le due aree: il rendering di un `:heading`/`:list_item`/`:quote`/`:rule` è puramente tipografico, indipendente dal contenuto Attivi o SPI. `list_indent` usa la stessa formula mm→pt inline (`LIST_INDENT_MM * 72 / 25.4`) vista in ogni altro file di questo pacchetto — nessun helper condiviso, coerente con la convenzione già osservata in `ReportPdf#mm_to_pt`.
>
> *EN: Six methods identical, line for line, to the Attivi version — none of them interprets `@form.legend_spi` or `@form.legend` directly, they all operate on the already-typed blocks returned by `LegendContent.blocks`, so they have no reason to differ between the two areas: rendering a `:heading`/`:list_item`/`:quote`/`:rule` is purely typographic, independent of Attivi or SPI content. `list_indent` uses the same inline mm→pt formula (`LIST_INDENT_MM * 72 / 25.4`) seen in every other file of this package — no shared helper, consistent with the convention already noted in `ReportPdf#mm_to_pt`.*
