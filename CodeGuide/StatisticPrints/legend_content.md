# `StatisticPrints::LegendContent`

**File:** `app/services/statistic_prints/legend_content.rb`

## Codice completo

```ruby
module StatisticPrints
  module LegendContent
    module_function

    def blocks(rich_text)
      fragment = Nokogiri::HTML::DocumentFragment.parse(rich_text.body.to_html)
      fragment.children.flat_map { |node| blocks_for(node) }
    end

    def blocks_for(node)
      case node.name
      when "div" then [ { type: :paragraph, text: inline(node) } ]
      when "p" then [ { type: :paragraph, text: inline(node), align: :justify } ]
      when "h1" then [ { type: :heading, text: inline(node) } ]
      when "ul", "ol" then list_blocks(node)
      when "blockquote" then [ { type: :quote, text: inline(node) } ]
      when "action-text-attachment" then attachment_blocks(node)
      when "text" then text_block(node)
      else []
      end
    end

    def attachment_blocks(node)
      node["content"].to_s.match?(%r{\A\s*<hr\s*/?>\s*\z}i) ? [ { type: :rule } ] : []
    end

    def list_blocks(node)
      ordered = node.name == "ol"
      node.css("> li").each_with_index.map { |li, i| list_item_block(li, ordered, i) }
    end

    def list_item_block(li, ordered, index)
      block = { type: :list_item, text: inline(li), prefix: ordered ? "#{index + 1}." : "•" }
      block[:align] = :justify if li.at_css("> p")
      block
    end

    def text_block(node)
      text = node.text.strip
      text.present? ? [ { type: :paragraph, text: escape(text) } ] : []
    end

    # Only the characters Prawn's inline_format tag parser treats as syntax
    # need escaping; CGI.escapeHTML also encodes quotes/apostrophes as
    # numeric entities (e.g. &#39;) that Prawn prints back out literally.
    def escape(text)
      text.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;")
    end

    def inline(node)
      node.children.map { |child| inline_node(child) }.join
    end

    def inline_node(node)
      case node.name
      when "text" then escape(node.text)
      when "strong", "b" then "<b>#{inline(node)}</b>"
      when "em", "i" then "<i>#{inline(node)}</i>"
      when "u" then "<u>#{inline(node)}</u>"
      when "a" then link_node(node)
      when "br" then "\n"
      else inline(node)
      end
    end

    def link_node(node)
      href = CGI.escapeHTML(node["href"].to_s)
      "<color rgb=\"0d6efd\"><link href=\"#{href}\">#{inline(node)}</link></color>"
    end
  end
end
```

## Sezioni commentate

### `module_function`

```ruby
module_function
```

> **IT:** `LegendContent` è l'unico modulo/classe di tutta la cartella `StatisticPrints` a non seguire il pattern `self.draw(...) = new(...).draw` + `initialize`. Non ha stato da portare tra chiamate — niente `@pdf`, niente `@form` — è una trasformazione pura, funzionale, da HTML di ActionText a un array di hash Ruby: `module_function` rende ogni metodo del modulo sia privato per l'`include` sia richiamabile come `LegendContent.metodo(...)`, il che è esattamente il contratto che serve qui (`LegendPage` chiama solo `LegendContent.blocks(...)`, mai istanzia nulla). Questa è anche la ragione per cui, a differenza degli altri file, non c'è bisogno di `self.draw(...) = new(...).draw`: non c'è nulla da istanziare.
>
> *EN: `LegendContent` is the only module/class in the entire `StatisticPrints` folder that doesn't follow the `self.draw(...) = new(...).draw` + `initialize` pattern. It has no state to carry between calls — no `@pdf`, no `@form` — it's a pure, functional transformation from ActionText HTML to an array of Ruby hashes: `module_function` makes every method in the module both private for `include` purposes and callable as `LegendContent.method(...)`, which is exactly the contract needed here (`LegendPage` only calls `LegendContent.blocks(...)`, never instantiates anything). This is also why, unlike the other files, there's no need for `self.draw(...) = new(...).draw`: there's nothing to instantiate.*

### `blocks`, `blocks_for`

```ruby
def blocks(rich_text)
  fragment = Nokogiri::HTML::DocumentFragment.parse(rich_text.body.to_html)
  fragment.children.flat_map { |node| blocks_for(node) }
end

def blocks_for(node)
  case node.name
  when "div" then [ { type: :paragraph, text: inline(node) } ]
  when "p" then [ { type: :paragraph, text: inline(node), align: :justify } ]
  when "h1" then [ { type: :heading, text: inline(node) } ]
  when "ul", "ol" then list_blocks(node)
  when "blockquote" then [ { type: :quote, text: inline(node) } ]
  when "action-text-attachment" then attachment_blocks(node)
  when "text" then text_block(node)
  else []
  end
end
```

> **IT:** `rich_text.body.to_html` è un `ActionText::RichText#body`, il cui `.to_html` risolve già gli `<action-text-attachment>` incorporati (in questa app, solo le righe orizzontali inserite come formato custom di Trix, vedi la nota in `.ai`/memoria di progetto sui formati custom underline/justify/hr). `flat_map`, non `map`, è la scelta che conta: alcuni nodi (`ul`/`ol` tramite `list_blocks`) producono **più** blocchi da un solo nodo HTML (un blocco per `<li>`), altri (nodi di testo vuoti, attachment non-`<hr>`) ne producono **zero** — un `map` semplice lascerebbe array annidati o `nil` da ripulire dopo. La distinzione `div` vs `p` non è arbitraria: riflette il modo in cui Trix (l'editor di ActionText) serializza i paragrafi di default come `<div>` e riserva `<p>` a un formato custom aggiunto apposta per i paragrafi giustificati (`align: :justify` qui è impostato solo per `p`, mai per `div`) — è l'unico punto in cui questa classe sa qualcosa di specifico sull'editor invece che sull'HTML generico.
>
> *EN: `rich_text.body.to_html` is an `ActionText::RichText#body`, whose `.to_html` already resolves embedded `<action-text-attachment>`s (in this app, only the horizontal rules inserted via a custom Trix format, see the project memory note on custom underline/justify/hr formats). `flat_map`, not `map`, is the choice that matters: some nodes (`ul`/`ol` via `list_blocks`) produce **multiple** blocks from a single HTML node (one block per `<li>`), others (empty text nodes, non-`<hr>` attachments) produce **zero** — a plain `map` would leave nested arrays or `nil`s to clean up afterward. The `div` vs `p` distinction isn't arbitrary: it reflects how Trix (ActionText's editor) serializes default paragraphs as `<div>` and reserves `<p>` for a custom format added specifically for justified paragraphs (`align: :justify` is set only for `p`, never for `div`) — it's the one place where this class knows something specific about the editor rather than about generic HTML.*

### `attachment_blocks`

```ruby
def attachment_blocks(node)
  node["content"].to_s.match?(%r{\A\s*<hr\s*/?>\s*\z}i) ? [ { type: :rule } ] : []
end
```

> **IT:** Trix rappresenta un `<hr>` inserito dall'utente non come tag `<hr>` diretto nel corpo, ma come `<action-text-attachment content="<hr>">` — un dettaglio dell'implementazione di ActionText, non una scelta di questa app. Il regex verifica che il contenuto dell'attachment sia **esattamente** un `<hr>` (con eventuale whitespace attorno, `/>`  opzionale), non semplicemente che lo contenga: qualunque altro tipo di allegato (in questa app la legenda è testo puro, ma il meccanismo `action-text-attachment` in teoria potrebbe portare immagini o file) viene scartato silenziosamente restituendo `[]` invece di generare un errore o un blocco malformato. Questo significa che, se un giorno qualcuno incollasse un'immagine nella legenda, sparirebbe silenziosamente dal PDF stampato senza alcun avviso — un limite noto, non gestito esplicitamente.
>
> *EN: Trix represents a user-inserted `<hr>` not as a direct `<hr>` tag in the body, but as `<action-text-attachment content="<hr>">` — an ActionText implementation detail, not a choice made by this app. The regex checks that the attachment's content is **exactly** an `<hr>` (with optional surrounding whitespace, optional `/>`), not merely that it contains one: any other kind of attachment (in this app the legend is plain text, but the `action-text-attachment` mechanism could in theory carry images or files) is silently discarded, returning `[]` instead of raising an error or producing a malformed block. This means that if someone ever pasted an image into the legend, it would silently disappear from the printed PDF with no warning — a known limitation, not explicitly handled.*

### `list_blocks`, `list_item_block`

```ruby
def list_blocks(node)
  ordered = node.name == "ol"
  node.css("> li").each_with_index.map { |li, i| list_item_block(li, ordered, i) }
end

def list_item_block(li, ordered, index)
  block = { type: :list_item, text: inline(li), prefix: ordered ? "#{index + 1}." : "•" }
  block[:align] = :justify if li.at_css("> p")
  block
end
```

> **IT:** `node.css("> li")`, non `node.css("li")`: il selettore `>` limita la ricerca ai `<li>` **figli diretti**, escludendo eventuali `<li>` di liste annidate — anche se, come notato in `legend_page.md`, Trix in questa app non produce liste annidate, il selettore è comunque scritto in modo difensivo, non ottimistico. Il numero del prefisso (`"#{index + 1}."`) usa l'indice locale della `each_with_index` su questa singola lista, non un contatore globale sull'intera legenda: due `<ol>` separati nello stesso documento ripartono entrambi da "1.". `block[:align] = :justify if li.at_css("> p")` rispecchia esattamente la stessa logica div-vs-p di `blocks_for`: se Trix ha avvolto il contenuto dell'elemento di lista in un `<p>` (paragrafo giustificato), l'allineamento giustificato si propaga anche al testo della lista.
>
> *EN: `node.css("> li")`, not `node.css("li")`: the `>` selector limits the search to **direct child** `<li>`s, excluding any `<li>`s from nested lists — even though, as noted in `legend_page.md`, Trix in this app doesn't produce nested lists, the selector is still written defensively, not optimistically. The prefix number (`"#{index + 1}."`) uses the local index from `each_with_index` on this single list, not a global counter across the whole legend: two separate `<ol>`s in the same document both restart from "1.". `block[:align] = :justify if li.at_css("> p")` mirrors the exact same div-vs-p logic as `blocks_for`: if Trix wrapped the list item's content in a `<p>` (justified paragraph), the justified alignment propagates to the list text too.*

### `text_block`, `escape`

```ruby
def text_block(node)
  text = node.text.strip
  text.present? ? [ { type: :paragraph, text: escape(text) } ] : []
end

# Only the characters Prawn's inline_format tag parser treats as syntax
# need escaping; CGI.escapeHTML also encodes quotes/apostrophes as
# numeric entities (e.g. &#39;) that Prawn prints back out literally.
def escape(text)
  text.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;")
end
```

> **IT:** `text_block` gestisce i nodi di testo che compaiono come **figli diretti** del `DocumentFragment` (fuori da qualunque `<div>`/`<p>`), tipicamente solo whitespace lasciato da Nokogiri tra un tag di blocco e l'altro — da qui `strip` seguito da `present?`, per evitare di generare paragrafi vuoti. Il commento inline nel codice spiega già il "cosa" e in parte il "perché" di `escape`, ma vale la pena rendere esplicito il collegamento con `LegendPage#draw_text`: `escape` viene applicato a **tutto** il testo prima di passarlo a `text_box`/`text` con `inline_format: true`, ma i tag che `LegendContent` stessa inserisce (`<b>`, `<i>`, `<u>`, `<color>`, `<link>` in `inline_node`/`link_node`) **non** passano da `escape` — sono costruiti come stringhe letterali già nella sintassi che Prawn si aspetta. Se `escape` venisse applicato anche a quei tag, Prawn li stamperebbe come testo letterale (`&lt;b&gt;`) invece di interpretarli come grassetto.
>
> *EN: `text_block` handles text nodes that appear as **direct children** of the `DocumentFragment` (outside any `<div>`/`<p>`), typically just whitespace Nokogiri leaves between one block tag and the next — hence `strip` followed by `present?`, to avoid generating empty paragraphs. The inline source comment already explains the "what" and part of the "why" of `escape`, but it's worth making the connection to `LegendPage#draw_text` explicit: `escape` is applied to **all** text before handing it to `text_box`/`text` with `inline_format: true`, but the tags `LegendContent` itself inserts (`<b>`, `<i>`, `<u>`, `<color>`, `<link>` in `inline_node`/`link_node`) do **not** go through `escape` — they're built as literal strings already in the syntax Prawn expects. If `escape` were applied to those tags too, Prawn would print them as literal text (`&lt;b&gt;`) instead of interpreting them as bold.*

### `inline`, `inline_node`, `link_node`

```ruby
def inline(node)
  node.children.map { |child| inline_node(child) }.join
end

def inline_node(node)
  case node.name
  when "text" then escape(node.text)
  when "strong", "b" then "<b>#{inline(node)}</b>"
  when "em", "i" then "<i>#{inline(node)}</i>"
  when "u" then "<u>#{inline(node)}</u>"
  when "a" then link_node(node)
  when "br" then "\n"
  else inline(node)
  end
end

def link_node(node)
  href = CGI.escapeHTML(node["href"].to_s)
  "<color rgb=\"0d6efd\"><link href=\"#{href}\">#{inline(node)}</link></color>"
end
```

> **IT:** `inline`/`inline_node` sono un mini-convertitore ricorsivo da alberi di tag inline HTML (`<strong>`, `<em>`, `<a>`, testo annidato dentro un `<a>`, ecc.) alla sottosintassi `inline_format` di Prawn, che riconosce solo una manciata di tag propri (`<b>`, `<i>`, `<u>`, `<color>`, `<link>`) — non l'HTML generico. Il ramo `else inline(node)` è il fallback deliberato per qualunque tag inline non riconosciuto (es. uno `<span>` che Trix o un copia-incolla potrebbero introdurre): invece di sollevare un errore o scartare il contenuto, scarta solo il tag "contenitore" e ricorre nei suoi figli, preservando il testo ma perdendo la formattazione sconosciuta — "non perdere mai il contenuto, perdi al più la formattazione non supportata". `link_node` hardcoda il colore del link a `0d6efd`: è il blu primario di Bootstrap di serie, che la variante Bootswatch Lumen usata in questa app **non** ridefinisce (`$primary: $blue !default` in `_variables.scss` di Lumen) — quindi, a differenza dei colori dei grafici altrove nella cartella (pull da valori compilati del tema perché Lumen *li* ridefinisce), qui il valore hardcoded coincide comunque con quello del tema per puro fatto che Lumen non tocca il primary. `CGI.escapeHTML` sull'`href` (non il gsub manuale di `escape`) è corretto qui perché l'`href` finisce dentro un **attributo** dell'XML/tag `<link href="...">`, dove anche le virgolette vanno propriamente escapate — l'esatto scenario per cui `escape` (usato per il testo visibile) evita deliberatamente `CGI.escapeHTML`.
>
> *EN: `inline`/`inline_node` are a small recursive converter from trees of inline HTML tags (`<strong>`, `<em>`, `<a>`, text nested inside an `<a>`, etc.) to Prawn's `inline_format` sub-syntax, which only recognizes a handful of its own tags (`<b>`, `<i>`, `<u>`, `<color>`, `<link>`) — not generic HTML. The `else inline(node)` branch is the deliberate fallback for any unrecognized inline tag (e.g. a `<span>` that Trix or a paste might introduce): instead of raising an error or dropping the content, it drops only the "wrapper" tag and recurses into its children, preserving the text but losing the unknown formatting — "never lose the content, at most lose unsupported formatting." `link_node` hardcodes the link color to `0d6efd`: this is stock Bootstrap's primary blue, which the Bootswatch Lumen variant used in this app does **not** override (`$primary: $blue !default` in Lumen's `_variables.scss`) — so, unlike the chart colors elsewhere in the folder (pulled from compiled theme values because Lumen *does* override those), the hardcoded value here happens to match the theme anyway, purely because Lumen leaves primary untouched. `CGI.escapeHTML` on the `href` (not `escape`'s manual gsub) is correct here because the `href` ends up inside an **attribute** of the `<link href="...">` tag, where quotes also need proper escaping — exactly the scenario `escape` (used for visible text) deliberately avoids `CGI.escapeHTML` for.*
