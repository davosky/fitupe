# `StatisticSpiPrints::AgeClassesPage`

**File:** `app/services/statistic_spi_prints/age_classes_page.rb`

## Codice completo

```ruby
module StatisticSpiPrints
  # Pagina "Classi di Età": specchia il grafico Fasce d'Età di
  # StatisticPrints::WorkStatusAgePage (SingleSeriesBarChart), ma solo il
  # grafico (nessuna tabella, non richiesta). A livello regionale mostra il
  # grafico regionale, prominente, seguito da una riga di grafici piu' piccoli
  # uno per comprensorio; a livello di comprensorio mostra solo il proprio.
  class AgeClassesPage
    include StatisticPrints::PageLayout

    SECTION_GAP_MM = 8
    COLUMN_GAP_MM = 10
    TITLE_GAP_PT = 6
    REGIONAL_CHART_HEIGHT_MM = 75
    COMPRENSORIO_CHART_HEIGHT_MM = 55
    SINGLE_CHART_HEIGHT_MM = 130
    BANDS = StatisticSpi::AgeBreakdown::BANDS
    # Etichette brevi per i grafici comprensoriali (regionale escluso): le
    # denominazioni per esteso (GIOVANI, TRENTENNI, ecc.) non ci stanno nella
    # larghezza ridotta delle colonne comprensoriali.
    SHORT_LABELS = {
      "GIOVANI" => "< 30", "TRENTENNI" => "30", "QUARANTENNI" => "40", "CINQUANTENNI" => "50",
      "SESSANTENNI" => "60", "SETTANTENNI" => "70", "OTTANTENNI" => "80", "NOVANTENNI" => "90",
      "HIGHLANDERS" => "> 90"
    }.freeze

    def self.draw(...) = new(...).draw

    def initialize(pdf, form:, breakdown_service: StatisticSpi::AgeBreakdown)
      @pdf = pdf
      @form = form
      @breakdown_service = breakdown_service
    end

    def draw
      @pdf.fill_color "000000"
      draw_heading
      result = @breakdown_service.call(zoning: @form.zoning, anno: @form.anno, mese: @form.mese)
      if result.comprensori.present?
        draw_regional_and_comprensori(result)
      else
        draw_chart_section(result.totale, @pdf.bounds.left, @pdf.bounds.width, mm(SINGLE_CHART_HEIGHT_MM),
          title_size: 14, top: @pdf.cursor)
      end
    end

    private

    def draw_heading = draw_page_heading(heading_title, subtitle: period_subtitle)

    def heading_title
      return "CGIL Classi di Età SPI – Regionale e Comprensori" if @form.zoning.regionale?

      "CGIL Classi di Età SPI – Comprensorio di #{@form.zoning.descrizione_azzonamento}"
    end

    # Niente bounding_box qui: un box con height pari a "tutto lo spazio
    # rimasto in pagina" (necessario altrove per non far traboccare tabelle
    # dal numero di righe variabile) fa sempre atterrare il cursore condiviso
    # della pagina a fondo pagina alla chiusura del blocco, a prescindere da
    # quanto contenuto sia stato davvero disegnato dentro. Con due sezioni in
    # sequenza (regionale poi riga comprensori) questo azzererebbe lo spazio
    # disponibile per la seconda. Titolo e grafico vengono quindi posizionati
    # con coordinate assolute, calcolate a partire da altezze note in anticipo.
    def draw_regional_and_comprensori(result)
      top = @pdf.cursor
      regional_height = mm(REGIONAL_CHART_HEIGHT_MM)
      draw_chart_section(result.totale, @pdf.bounds.left, @pdf.bounds.width, regional_height, title_size: 14, top: top)

      comprensori_top = top - title_block_height(14) - regional_height - section_gap
      draw_comprensori_row(result.comprensori, comprensori_top)
    end

    def draw_comprensori_row(comprensori, top)
      width = comprensorio_width(comprensori.size)
      comprensori.each_with_index do |row, index|
        x = @pdf.bounds.left + (index * (width + column_gap))
        draw_chart_section(row, x, width, mm(COMPRENSORIO_CHART_HEIGHT_MM), title_size: 11, top: top)
      end
    end

    def draw_chart_section(row, x, width, height, title_size:, top:)
      @pdf.font("AsapCondensed", style: :bold, size: title_size) do
        @pdf.draw_text row.zoning.descrizione_azzonamento, at: [ x, top - title_size ]
      end

      chart_top = top - title_block_height(title_size)
      StatisticPrints::SingleSeriesBarChart.draw(
        @pdf, at: [ x, chart_top ], width: width, height: height,
        labels: chart_labels(row.zoning), data: BANDS.map { |fascia, _| row.totali[fascia] },
        percentages: BANDS.map { |fascia, _| row.percentuali[fascia] }
      )
    end

    def chart_labels(zoning)
      return BANDS.map(&:first) if zoning.regionale?

      BANDS.map { |fascia, _| SHORT_LABELS.fetch(fascia) }
    end

    def title_block_height(title_size) = title_size + TITLE_GAP_PT

    def comprensorio_width(count) = ((@pdf.bounds.width - (column_gap * (count - 1))) / count)
  end
end
```

## Sezioni commentate

### Commento di classe

```ruby
# Pagina "Classi di Età": specchia il grafico Fasce d'Età di
# StatisticPrints::WorkStatusAgePage (SingleSeriesBarChart), ma solo il
# grafico (nessuna tabella, non richiesta). A livello regionale mostra il
# grafico regionale, prominente, seguito da una riga di grafici piu' piccoli
# uno per comprensorio; a livello di comprensorio mostra solo il proprio.
class AgeClassesPage
```

> **IT:** L'ultima e la più complessa delle sei pagine, sia per il layout (un grafico grande seguito da una **riga** di grafici piccoli, non due colonne affiancate come le altre cinque) sia perché è quella dove un bug reale in produzione ha lasciato una traccia diretta nel codice attuale: il commento sopra `draw_regional_and_comprensori` (vedi sotto) non descrive un'ipotesi teorica, descrive la correzione di un incidente già accaduto. Vale la pena leggerla per ultima proprio per questo: le altre cinque pagine usano tutte `bounding_box([x, top], width: ..., height: top)` per le colonne affiancate, ed è un uso legittimo e sicuro (vedi `CodeGuide/StatisticSpiPrints/totals_page.md`); questa pagina mostra cosa succede quando lo stesso pattern viene applicato al caso sbagliato — sezioni impilate verticalmente, non affiancate.
>
> *EN: The last and most complex of the six pages, both in layout (one large chart followed by a **row** of small charts, not two side-by-side columns like the other five) and because it's the one where a real production bug left a direct trace in the current code: the comment above `draw_regional_and_comprensori` (see below) doesn't describe a theoretical concern, it describes the fix for an incident that actually happened. It's worth reading last for exactly that reason: the other five pages all use `bounding_box([x, top], width: ..., height: top)` for side-by-side columns, and that's a legitimate, safe use (see `CodeGuide/StatisticSpiPrints/totals_page.md`); this page shows what happens when the same pattern is applied to the wrong case — vertically stacked sections, not side-by-side ones.*

### Il bug storico: 4 pagine bianche da un `bounding_box` riusato per sezioni impilate

```ruby
# Niente bounding_box qui: un box con height pari a "tutto lo spazio
# rimasto in pagina" (necessario altrove per non far traboccare tabelle
# dal numero di righe variabile) fa sempre atterrare il cursore condiviso
# della pagina a fondo pagina alla chiusura del blocco, a prescindere da
# quanto contenuto sia stato davvero disegnato dentro. Con due sezioni in
# sequenza (regionale poi riga comprensori) questo azzererebbe lo spazio
# disponibile per la seconda. Titolo e grafico vengono quindi posizionati
# con coordinate assolute, calcolate a partire da altezze note in anticipo.
def draw_regional_and_comprensori(result)
```

> **IT:** Questo commento documenta un incidente reale, non un rischio teorico: una prima versione di `AgeClassesPage` disegnava la sezione regionale (grafico grande) dentro un `bounding_box([left, top], width: ..., height: top)` — lo stesso pattern usato con successo in `TotalsPage`/`TipologieDelegaPage`/`CessazioniPage`/`ProvvisoriePage` — e poi tentava di disegnare la riga dei comprensori con un secondo `bounding_box` analogo, impilato **sotto** il primo. Il problema: Prawn fa sempre atterrare il cursore condiviso del documento a `top - height` quando un `bounding_box` si chiude, **indipendentemente da quanto contenuto sia stato effettivamente disegnato dentro** — con `height: top` (cioè "tutta la distanza dal punto di partenza fino al fondo pagina"), il cursore dopo il primo box atterra vicino a **zero**, quasi in fondo alla pagina fisica. Per due colonne affiancate (`TotalsPage` e simili) questo non è un problema, perché nessuna terza sezione dipende da quel cursore. Ma qui il secondo `bounding_box` (la riga dei comprensori) partiva da quel cursore quasi a zero: con pochissimo spazio verticale rimasto, il contenuto del secondo box andava in overflow, e **l'auto-impaginazione di Prawn** (che inserisce automaticamente nuove pagine quando un blocco non ci sta) generava pagine aggiuntive silenziose — quattro pagine bianche in coda a ogni sezione di comprensorio nel PDF reale, un difetto invisibile finché qualcuno non ha aperto il PDF e contato le pagine. I test RSpec esistenti non lo avevano intercettato perché verificavano solo `expect { ReportPdf.call(...) }.not_to raise_error` — un `bounding_box` che va in overflow e genera pagine extra **non solleva un'eccezione**, produce solo un PDF più lungo del previsto. La correzione (il codice attuale): **niente `bounding_box`** per le due sezioni impilate. Il metodo calcola `top` a mano, sottraendo esplicitamente le altezze note (`title_block_height(14)`, `regional_height`, `section_gap`) dal cursore di partenza, e passa quel `top` calcolato a `draw_comprensori_row` come coordinata assoluta — mai un `bounding_box` intermedio il cui side-effect sul cursore condiviso potrebbe interferire. La lezione generale, valida oltre questo file specifico: `bounding_box` con `height:` grande ("resto della pagina") è sicuro solo se non c'è nient'altro dopo che dipende dalla posizione del cursore del documento; per sezioni verticalmente sequenziali, servono coordinate assolute tracciate a mano.
>
> *EN: This comment documents a real incident, not a theoretical risk: an earlier version of `AgeClassesPage` drew the regional section (the large chart) inside a `bounding_box([left, top], width: ..., height: top)` — the same pattern used successfully in `TotalsPage`/`TipologieDelegaPage`/`CessazioniPage`/`ProvvisoriePage` — and then attempted to draw the comprensori row with a second, analogous `bounding_box`, stacked **below** the first. The problem: Prawn always lands the document's shared cursor at `top - height` when a `bounding_box` closes, **regardless of how much content was actually drawn inside it** — with `height: top` (i.e. "the full distance from the starting point down to the bottom of the page"), the cursor after the first box lands near **zero**, almost at the bottom of the physical page. For side-by-side columns (`TotalsPage` and similar), this isn't a problem, because no third section depends on that cursor. But here the second `bounding_box` (the comprensori row) started from that near-zero cursor: with almost no vertical space left, the second box's content overflowed, and **Prawn's own auto-pagination** (which silently inserts new pages when a block doesn't fit) generated extra, silent pages — four blank pages tacked onto the end of every comprensorio section in the real PDF, a defect invisible until someone actually opened the PDF and counted pages. The existing RSpec tests hadn't caught it because they only checked `expect { ReportPdf.call(...) }.not_to raise_error` — a `bounding_box` overflowing and generating extra pages **doesn't raise an exception**, it just produces a longer-than-expected PDF. The fix (the current code): **no `bounding_box`** for the two stacked sections. The method computes `top` by hand, explicitly subtracting known heights (`title_block_height(14)`, `regional_height`, `section_gap`) from the starting cursor, and passes that computed `top` to `draw_comprensori_row` as an absolute coordinate — never an intermediate `bounding_box` whose side effect on the shared cursor could interfere. The general lesson, valid beyond this specific file: a `bounding_box` with a large ("rest of the page") `height:` is safe only when nothing afterward depends on the document cursor's position; for vertically sequential sections, hand-tracked absolute coordinates are required instead.*

### `draw` — il terzo fork di layout della cartella

```ruby
def draw
  @pdf.fill_color "000000"
  draw_heading
  result = @breakdown_service.call(zoning: @form.zoning, anno: @form.anno, mese: @form.mese)
  if result.comprensori.present?
    draw_regional_and_comprensori(result)
  else
    draw_chart_section(result.totale, @pdf.bounds.left, @pdf.bounds.width, mm(SINGLE_CHART_HEIGHT_MM),
      title_size: 14, top: @pdf.cursor)
  end
end
```

> **IT:** Stesso fork `if result.comprensori.present?` di `TipologieDelegaPage`/`CessazioniPage`/`ProvvisoriePage`, ma qui il ramo "azzonamento singolo" **non** riusa `draw_chart_section` con `@pdf.bounds.width` intera in modo puramente cosmetico: lo riusa perché `draw_chart_section` non fa mai assunzioni su un `bounding_box` — lavora sempre per coordinate assolute (`x`, `top` passati esplicitamente), quindi funziona identicamente sia chiamato una volta sola (caso singolo comprensorio) sia chiamato N volte in riga (`draw_comprensori_row`) sia chiamato per la sezione regionale grande. È lo stesso metodo di disegno di base riusato in tutti e tre i contesti con parametri diversi (`title_size`, `height`, `width`), non tre implementazioni separate.
>
> *EN: The same `if result.comprensori.present?` fork as `TipologieDelegaPage`/`CessazioniPage`/`ProvvisoriePage`, but here the "single zoning" branch doesn't reuse `draw_chart_section` with the full `@pdf.bounds.width` merely for cosmetic reasons: it reuses it because `draw_chart_section` never makes assumptions about a `bounding_box` — it always works in absolute coordinates (`x`, `top` passed explicitly), so it works identically whether called once (single-comprensorio case), called N times in a row (`draw_comprensori_row`), or called for the large regional section. It's the same base drawing method reused in all three contexts with different parameters (`title_size`, `height`, `width`), not three separate implementations.*

### `draw_regional_and_comprensori`, `draw_comprensori_row` — il calcolo manuale di `top`

```ruby
def draw_regional_and_comprensori(result)
  top = @pdf.cursor
  regional_height = mm(REGIONAL_CHART_HEIGHT_MM)
  draw_chart_section(result.totale, @pdf.bounds.left, @pdf.bounds.width, regional_height, title_size: 14, top: top)

  comprensori_top = top - title_block_height(14) - regional_height - section_gap
  draw_comprensori_row(result.comprensori, comprensori_top)
end

def draw_comprensori_row(comprensori, top)
  width = comprensorio_width(comprensori.size)
  comprensori.each_with_index do |row, index|
    x = @pdf.bounds.left + (index * (width + column_gap))
    draw_chart_section(row, x, width, mm(COMPRENSORIO_CHART_HEIGHT_MM), title_size: 11, top: top)
  end
end
```

> **IT:** `comprensori_top` è il cuore della correzione descritta sopra: invece di leggere `@pdf.cursor` dopo aver disegnato la sezione regionale (che, non essendoci un `bounding_box` a chiuderne lo scope, non si sarebbe comunque mosso automaticamente — `draw_text`/i grafici disegnati per coordinate assolute non avanzano il cursore del documento), il metodo **calcola** dove deve iniziare la riga dei comprensori sottraendo, in ordine, l'altezza del blocco titolo (`title_block_height(14)`), l'altezza del grafico regionale (`regional_height`), e lo spazio tra sezioni (`section_gap`) dal `top` di partenza. Ogni componente di questa sottrazione è una costante nota in anticipo (mm convertiti in pt), non un valore letto a runtime dal cursore — l'esatto opposto della strategia "lascia che Prawn tracci il cursore per te" usata nelle colonne delle altre pagine. `draw_comprensori_row` poi posiziona ogni grafico comprensoriale in orizzontale con lo stesso `top` per tutti (`x` diverso, `top` costante), dividendo la larghezza disponibile in parti uguali (`comprensorio_width`).
>
> *EN: `comprensori_top` is the heart of the fix described above: instead of reading `@pdf.cursor` after drawing the regional section (which, with no `bounding_box` closing its scope, wouldn't have moved automatically anyway — `draw_text`/charts drawn via absolute coordinates don't advance the document cursor), the method **computes** where the comprensori row must start by subtracting, in order, the title block's height (`title_block_height(14)`), the regional chart's height (`regional_height`), and the gap between sections (`section_gap`) from the starting `top`. Every component of this subtraction is a constant known in advance (mm converted to pt), not a value read at runtime from the cursor — the exact opposite of the "let Prawn track the cursor for you" strategy used in the other pages' columns. `draw_comprensori_row` then lays out each comprensorio chart horizontally with the same `top` for all of them (different `x`, constant `top`), dividing the available width into equal parts (`comprensorio_width`).*

### `draw_chart_section` — `draw_text at:` invece di `@pdf.text`

```ruby
def draw_chart_section(row, x, width, height, title_size:, top:)
  @pdf.font("AsapCondensed", style: :bold, size: title_size) do
    @pdf.draw_text row.zoning.descrizione_azzonamento, at: [ x, top - title_size ]
  end

  chart_top = top - title_block_height(title_size)
  StatisticPrints::SingleSeriesBarChart.draw(
    @pdf, at: [ x, chart_top ], width: width, height: height,
    labels: chart_labels(row.zoning), data: BANDS.map { |fascia, _| row.totali[fascia] },
    percentages: BANDS.map { |fascia, _| row.percentuali[fascia] }
  )
end
```

> **IT:** Ogni altra pagina di questa cartella usa `@pdf.text "..."` per i titoli (che scrive alla posizione corrente del cursore e **avanza** il cursore) dentro un `bounding_box` o in sequenza semplice (`MultipleDelegationsPage`). Qui invece è `@pdf.draw_text "...", at: [x, y]` — la variante Prawn che scrive a una **coordinata assoluta esplicita** senza mai leggere né modificare il cursore del documento. È una conseguenza diretta di lavorare fuori da un `bounding_box`: senza un box che ridefinisca `@pdf.bounds`/`@pdf.cursor` in coordinate locali, e senza voler comunque toccare il cursore condiviso (che qui è gestito a mano dal chiamante, vedi sopra), `draw_text at:` è l'unico modo per posizionare testo in un punto preciso senza effetti collaterali. Lo stesso principio si applica al grafico: `SingleSeriesBarChart.draw(..., at: [x, chart_top], ...)` riceve una coordinata assoluta, non eredita una posizione da un `bounding_box` come fanno `CategoryBarChart`/`GroupedCategoryBarChart` nelle altre pagine (dove `at: [@pdf.bounds.left, @pdf.cursor]` è relativo al box corrente). `title_size:` è parametrizzato (14 per il grafico regionale, 11 per i comprensoriali) proprio perché questo unico metodo serve entrambi i contesti — vedi `chart_labels` sotto per l'altra differenza regionale/comprensorio.
>
> *EN: Every other page in this folder uses `@pdf.text "..."` for titles (which writes at the current cursor position and **advances** the cursor) inside a `bounding_box` or in plain sequence (`MultipleDelegationsPage`). Here it's `@pdf.draw_text "...", at: [x, y]` instead — the Prawn variant that writes at an **explicit absolute coordinate** without ever reading or modifying the document cursor. This is a direct consequence of working outside a `bounding_box`: with no box redefining `@pdf.bounds`/`@pdf.cursor` into local coordinates, and with no wish to touch the shared cursor anyway (which here is managed by hand by the caller, see above), `draw_text at:` is the only way to position text at a precise point with no side effects. The same principle applies to the chart: `SingleSeriesBarChart.draw(..., at: [x, chart_top], ...)` receives an absolute coordinate, it doesn't inherit a position from a `bounding_box` the way `CategoryBarChart`/`GroupedCategoryBarChart` do in the other pages (where `at: [@pdf.bounds.left, @pdf.cursor]` is relative to the current box). `title_size:` is parameterized (14 for the regional chart, 11 for the comprensorio ones) precisely because this one method serves both contexts — see `chart_labels` below for the other regional/comprensorio difference.*

### `BANDS`, `SHORT_LABELS`, `chart_labels` *(costanti e privato)*

```ruby
BANDS = StatisticSpi::AgeBreakdown::BANDS
SHORT_LABELS = {
  "GIOVANI" => "< 30", "TRENTENNI" => "30", "QUARANTENNI" => "40", "CINQUANTENNI" => "50",
  "SESSANTENNI" => "60", "SETTANTENNI" => "70", "OTTANTENNI" => "80", "NOVANTENNI" => "90",
  "HIGHLANDERS" => "> 90"
}.freeze
# ...
def chart_labels(zoning)
  return BANDS.map(&:first) if zoning.regionale?

  BANDS.map { |fascia, _| SHORT_LABELS.fetch(fascia) }
end
```

> **IT:** `BANDS` importata dal servizio, stesso principio di `ETICHETTE` nelle altre pagine. `SHORT_LABELS` è invece l'unico adattamento **puramente grafico** di questa cartella: un problema di spazio orizzontale, non di dominio. Il grafico regionale occupa l'intera larghezza della pagina e può permettersi le nove etichette per esteso (`GIOVANI`, `TRENTENNI`, ecc.); i grafici comprensoriali, affiancati in una riga stretta (`comprensorio_width`, larghezza pagina divisa per il numero di comprensori), non hanno spazio per lo stesso testo, quindi `chart_labels` sceglie tra le etichette lunghe o le abbreviazioni numeriche (`SHORT_LABELS`) in base a `zoning.regionale?` — la stessa condizione già usata per il titolo della pagina, riusata qui per una decisione di rendering diversa. Da notare che `SHORT_LABELS` è un hash indicizzato per nome di fascia (non per posizione), quindi resta corretto anche se l'ordine di `BANDS` cambiasse; ma richiede comunque un aggiornamento manuale in coppia con `BANDS` se una fascia venisse rinominata — un `.fetch` (non `[]`/`.fetch(fascia, fascia)`) qui è deliberato: se una nuova fascia venisse aggiunta a `Statistics::AgeBreakdown::BANDS` senza aggiornare `SHORT_LABELS`, la pagina solleverebbe un `KeyError` immediato invece di stampare silenziosamente un'etichetta lunga non abbreviata che sforerebbe la colonna stretta.
>
> *EN: `BANDS` imported from the service, same principle as `ETICHETTE` in the other pages. `SHORT_LABELS`, by contrast, is the only **purely graphical** adaptation in this folder: a horizontal-space problem, not a domain one. The regional chart spans the full page width and can afford the nine full-length labels (`GIOVANI`, `TRENTENNI`, etc.); the comprensorio charts, laid out side by side in a narrow row (`comprensorio_width`, page width divided by the number of comprensori), have no room for the same text, so `chart_labels` picks between the long labels or the numeric abbreviations (`SHORT_LABELS`) based on `zoning.regionale?` — the same condition already used for the page title, reused here for a different rendering decision. Note that `SHORT_LABELS` is a hash keyed by band name (not by position), so it stays correct even if `BANDS`'s order changed; but it still needs a manual update alongside `BANDS` if a band were ever renamed — a `.fetch` (not `[]`/`.fetch(fascia, fascia)`) here is deliberate: if a new band were added to `Statistics::AgeBreakdown::BANDS` without updating `SHORT_LABELS`, the page would raise an immediate `KeyError` instead of silently printing an unabbreviated long label that would overflow the narrow column.*

### `title_block_height`, `comprensorio_width`, `column_gap`, `section_gap`, `mm_to_pt` *(privati)*

```ruby
def title_block_height(title_size) = title_size + TITLE_GAP_PT

def comprensorio_width(count) = ((@pdf.bounds.width - (column_gap * (count - 1))) / count)

```

> **IT:** `title_block_height` è la funzione che rende possibile l'intera correzione: incapsula "quanto spazio verticale occupa un titolo di questa dimensione" (la dimensione del font in punti, più `TITLE_GAP_PT` fisso) in modo che sia riusabile sia per calcolare `chart_top` dentro `draw_chart_section` sia per calcolare `comprensori_top` dentro `draw_regional_and_comprensori` — le due sottrazioni manuali di `top` descritte sopra dipendono entrambe da questo singolo metodo, quindi un cambiamento a `TITLE_GAP_PT` si propaga coerentemente a entrambi i calcoli. `comprensorio_width` divide lo spazio orizzontale disponibile in `count` colonne uguali separate da `count - 1` gap (non `count` gap: nessun gap dopo l'ultima colonna) — la stessa aritmetica "N colonne, N-1 spazi" che in altre pagine è implicita nel fatto che ci sono sempre e solo due colonne (`column_width = (width - column_gap) / 2`), qui resa esplicitamente generica perché il numero di comprensori non è fisso a due. Le altre tre conversioni mm→pt sono identiche, nella forma, a ogni altra pagina della cartella.
>
> *EN: `title_block_height` is the function that makes the whole fix possible: it encapsulates "how much vertical space a title of this size takes up" (the font size in points, plus the fixed `TITLE_GAP_PT`) so it can be reused both to compute `chart_top` inside `draw_chart_section` and to compute `comprensori_top` inside `draw_regional_and_comprensori` — the two manual `top` subtractions described above both depend on this single method, so a change to `TITLE_GAP_PT` propagates consistently to both computations. `comprensorio_width` divides the available horizontal space into `count` equal columns separated by `count - 1` gaps (not `count` gaps: no gap after the last column) — the same "N columns, N-1 gaps" arithmetic that in other pages is implicit in there always being exactly two columns (`column_width = (width - column_gap) / 2`), made explicitly generic here because the number of comprensori isn't fixed at two. The other three mm→pt conversions are identical, in shape, to every other page in this folder.*

> **Nota 2026-10-05 / Note:** dove il testo cita `mm_to_pt` o la conversione `* 72 / 25.4` ripetuta nelle pagine, dal refactor si tratta dell'helper condiviso `mm` di `StatisticPrints::PageLayout` (vedi `CodeGuide/StatisticPrints/page_layout.md`). / Where the text mentions `mm_to_pt` or the `* 72 / 25.4` conversion repeated in pages, since the refactor that is the shared `mm` helper of `StatisticPrints::PageLayout`.
