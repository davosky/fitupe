# `StatisticPrints::LegendPage`

**File:** `app/services/statistic_prints/legend_page.rb`

## Codice completo

```ruby
module StatisticPrints
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
        LegendContent.blocks(@form.legend.description).each { |block| draw_block(block) }
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

### `LIST_INDENT_MM`, `initialize`

```ruby
LIST_INDENT_MM = 5

def self.draw(...) = new(...).draw

def initialize(pdf, form:)
  @pdf = pdf
  @form = form
end
```

> **IT:** `LegendPage` non riceve mai un oggetto legenda direttamente, ma `@form` — è `@form.legend.description` (dentro `draw_body`) a recuperare l'`ActionText::RichText`. Il chiamante, `ReportPdf#draw_legend`, ha già verificato `@form.legend.present?` prima di invocare questa classe (vedi `report_pdf.md`), quindi qui non c'è nessun guard su `nil`: è un contratto implicito, non imposto dal type system di Ruby, che vale la pena tenere a mente leggendo questo file da solo.
>
> *EN: `LegendPage` never receives a legend object directly, but `@form` — it's `@form.legend.description` (inside `draw_body`) that fetches the `ActionText::RichText`. The caller, `ReportPdf#draw_legend`, has already verified `@form.legend.present?` before invoking this class (see `report_pdf.md`), so there's no `nil` guard here: it's an implicit contract, not enforced by Ruby's type system, worth keeping in mind when reading this file in isolation.*

### `draw`, `draw_heading`

```ruby
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

> **IT:** `LegendPage` è quasi sempre la seconda pagina disegnata (dopo `CoverPage`, quando la legenda esiste), quindi il reset `@pdf.fill_color "000000"` all'inizio di `draw` difende esattamente dallo stesso problema documentato in `cover_page.md`/`zoning_divider_page.md`. `draw_heading` è quasi identico, struttura per struttura, a `RegionalPage#draw_heading` (titolo bold 16, sottotitolo grigio "Tesseramento mese anno", riga separatrice CCCCCC) — la differenza è nell'ultimo `move_down`: `RegionalPage` usa `section_gap` (10mm convertiti in punti), qui invece è un letterale `10` in punti puri, senza passare per `LIST_INDENT_MM` né alcuna conversione mm. È un'incoerenza minore rispetto alla convenzione "mm in costante, conversione al punto d'uso" seguita nel resto del file (vedi `list_indent`) — probabilmente un valore tarato a occhio in questo punto specifico invece di essere derivato da una misura in mm.
>
> *EN: `LegendPage` is almost always the second page drawn (after `CoverPage`, when a legend exists), so the `@pdf.fill_color "000000"` reset at the start of `draw` defends against exactly the same problem documented in `cover_page.md`/`zoning_divider_page.md`. `draw_heading` is nearly identical, structure for structure, to `RegionalPage#draw_heading` (bold 16 title, gray "Tesseramento month year" subtitle, CCCCCC divider rule) — the difference is in the final `move_down`: `RegionalPage` uses `section_gap` (10mm converted to points), whereas here it's a bare `10` in raw points, not routed through `LIST_INDENT_MM` or any mm conversion. It's a minor inconsistency against the "mm in a constant, converted at point of use" convention followed by the rest of the file (see `list_indent`) — likely a value tuned by eye at this specific spot rather than derived from an mm measurement.*

### `draw_body`, `draw_block`

```ruby
def draw_body
  @pdf.font("AsapCondensed", size: 11) do
    LegendContent.blocks(@form.legend.description).each { |block| draw_block(block) }
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
```

> **IT:** Questa è la giunzione tra le due classi della coppia parse/render: `LegendContent.blocks` (vedi `legend_content.md`) trasforma l'HTML di Trix/ActionText in un array piatto di hash `{ type:, text:, ... }`, e `draw_block` è l'unico punto che sa come disegnare ciascun `type` con Prawn. La separazione è netta e voluta: `LegendContent` non sa nulla di Prawn (nessun `@pdf` in vista), `LegendPage` non fa parsing HTML — se un giorno servisse un output diverso della stessa legenda (es. un'anteprima HTML nella pagina web), `LegendContent.blocks` sarebbe riusabile senza modifiche. `@pdf.move_down 6` fuori dal `case`, uguale per ogni tipo di blocco, è una scelta di semplicità: la spaziatura tra blocchi è uniforme indipendentemente dal tipo, invece di avere un gap diverso per titolo/paragrafo/lista/citazione.
>
> *EN: This is the joint between the pair's two classes, parse and render: `LegendContent.blocks` (see `legend_content.md`) turns Trix/ActionText HTML into a flat array of `{ type:, text:, ... }` hashes, and `draw_block` is the one place that knows how to render each `type` with Prawn. The separation is clean and deliberate: `LegendContent` knows nothing about Prawn (no `@pdf` in sight), `LegendPage` does no HTML parsing — if a different rendering of the same legend were ever needed (e.g. an HTML preview on the web page), `LegendContent.blocks` would be reusable unchanged. `@pdf.move_down 6` outside the `case`, the same for every block type, is a simplicity choice: spacing between blocks is uniform regardless of type, instead of a different gap per heading/paragraph/list/quote.*

### `draw_list_item`, `draw_quote`, `draw_rule`

```ruby
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
```

> **IT:** Liste (`ul`/`ol`) e citazioni (`blockquote`) sono semanticamente diverse ma condividono lo stesso indentation level (`list_indent`, 5mm), non due livelli separati — l'editor Trix usato per compilare la legenda non produce liste annidate né livelli multipli di citazione, quindi un solo livello di indentazione basta e non serve generalizzare. `draw_list_item` costruisce il prefisso (`•` o `1.`, deciso da `LegendContent#list_item_block`) concatenandolo al testo con due spazi letterali prima di passare tutto a `draw_text` — il prefisso non è un parametro separato di `text_box`/`text`, è testo semplice come il resto. `draw_rule` riusa lo stesso grigio `CCCCCC` della riga separatrice in `draw_heading`, per coerenza visiva tra l'intestazione della pagina e le righe `<hr>` inserite dall'utente nel corpo della legenda.
>
> *EN: Lists (`ul`/`ol`) and quotes (`blockquote`) are semantically different but share the same indentation level (`list_indent`, 5mm), not two separate levels — the Trix editor used to compile the legend doesn't produce nested lists or multiple quote levels, so a single indentation level is enough and generalizing further isn't needed. `draw_list_item` builds the prefix (`•` or `1.`, decided by `LegendContent#list_item_block`) by concatenating it to the text with two literal spaces before handing everything to `draw_text` — the prefix isn't a separate `text_box`/`text` parameter, it's plain text like the rest. `draw_rule` reuses the same `CCCCCC` gray as the divider rule in `draw_heading`, for visual consistency between the page header and any `<hr>` rules the user inserted in the legend body.*

### `draw_text`, `list_indent`

```ruby
def draw_text(text, size: 11, style: :normal, color: "000000", align: :left)
  return if text.blank?

  @pdf.font("AsapCondensed", size: size, style: style) { @pdf.text text, inline_format: true, color: color, align: align }
end

def list_indent = LIST_INDENT_MM * 72 / 25.4
```

> **IT:** `draw_text` è il punto d'appoggio comune di tutti i tipi di blocco (titoli, paragrafi, elementi di lista, citazioni) — centralizza sia il guard `return if text.blank?` (un blocco con testo vuoto, es. un `<div>` vuoto lasciato dall'editor, non produce comunque una riga vuota indesiderata) sia, soprattutto, `inline_format: true`. Quest'ultimo è ciò che permette al testo di contenere i tag `<b>`, `<i>`, `<u>`, `<color>`, `<link>` prodotti da `LegendContent#inline_node` (vedi `legend_content.md`) e di farli interpretare da Prawn come formattazione anziché stamparli come testo letterale — è il punto di accoppiamento diretto tra le due classi: se `LegendContent` producesse tag diversi da quelli che il parser `inline_format` di Prawn riconosce, comparirebbero come testo grezzo (es. `<b>` letterale) invece che come grassetto.
>
> *EN: `draw_text` is the common landing point for every block type (headings, paragraphs, list items, quotes) — it centralizes both the `return if text.blank?` guard (a block with empty text, e.g. an empty `<div>` left by the editor, still doesn't produce an unwanted blank line) and, more importantly, `inline_format: true`. The latter is what lets the text contain the `<b>`, `<i>`, `<u>`, `<color>`, `<link>` tags produced by `LegendContent#inline_node` (see `legend_content.md`) and has Prawn interpret them as formatting rather than printing them as literal text — it's the direct coupling point between the two classes: if `LegendContent` ever produced tags other than the ones Prawn's `inline_format` parser recognizes, they'd show up as raw text (e.g. a literal `<b>`) instead of bold.*
