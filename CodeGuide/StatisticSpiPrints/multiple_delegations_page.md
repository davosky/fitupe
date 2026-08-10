# `StatisticSpiPrints::MultipleDelegationsPage`

**File:** `app/services/statistic_spi_prints/multiple_delegations_page.rb`

## Codice completo

```ruby
module StatisticSpiPrints
  # Pagina "Deleghe Multiple": specchia app/views/statistic_spi/_deleghe_multiple_card
  # e _multiple_delegations_comprensori_card. Niente confronto anno su anno
  # (MultipleDelegationsBreakdown lavora su un solo periodo) quindi niente
  # grafico, solo le due tabelle una sotto l'altra: ci stanno comode in una
  # pagina sola senza bisogno di colonne affiancate.
  class MultipleDelegationsPage
    SECTION_GAP_MM = 10

    def self.draw(...) = new(...).draw

    def initialize(pdf, form:, breakdown_service: StatisticSpi::MultipleDelegationsBreakdown)
      @pdf = pdf
      @form = form
      @breakdown_service = breakdown_service
    end

    def draw
      @pdf.fill_color "000000"
      draw_heading
      result = @breakdown_service.call(zoning: @form.zoning, anno: @form.anno, mese: @form.mese)
      draw_totale(result)
      draw_comprensori(result) if result.comprensori.present?
    end

    private

    def draw_heading
      @pdf.font("AsapCondensed", style: :bold, size: 16) { @pdf.text heading_title }
      @pdf.move_down 2
      @pdf.font("AsapCondensed", size: 10) { @pdf.text "Tesseramento #{@form.mese} #{@form.anno}", color: "666666" }
      @pdf.move_down 8
      @pdf.stroke_color "CCCCCC"
      @pdf.stroke_horizontal_rule
      @pdf.move_down section_gap
    end

    def heading_title
      return "CGIL Deleghe Multiple SPI – Regionale e Comprensori" if @form.zoning.regionale?

      "CGIL Deleghe Multiple SPI – Comprensorio di #{@form.zoning.descrizione_azzonamento}"
    end

    def draw_totale(result)
      MultipleDelegationsTable.draw(@pdf, title: result.totale.zoning.descrizione_azzonamento, rows: [ result.totale ])
    end

    def draw_comprensori(result)
      @pdf.move_down section_gap
      MultipleDelegationsTable.draw(@pdf, title: "Comprensori", rows: result.comprensori)
    end

    def section_gap = SECTION_GAP_MM * 72 / 25.4
  end
end
```

## Sezioni commentate

### Commento di classe e struttura generale

```ruby
# Pagina "Deleghe Multiple": specchia app/views/statistic_spi/_deleghe_multiple_card
# e _multiple_delegations_comprensori_card. Niente confronto anno su anno
# (MultipleDelegationsBreakdown lavora su un solo periodo) quindi niente
# grafico, solo le due tabelle una sotto l'altra: ci stanno comode in una
# pagina sola senza bisogno di colonne affiancate.
class MultipleDelegationsPage
```

> **IT:** La più semplice delle sei pagine, e non a caso: `StatisticSpi::MultipleDelegationsBreakdown` non ha una dimensione temporale (nessun `anno_precedente`, vedi `CodeGuide/StatisticSpi/multiple_delegations_breakdown.md`) e non ha bisogno di un grafico dedicato (i quattro conteggi doppia/tripla/quadrupla/quintupla sono già leggibili in una tabella compatta). Il risultato è l'unica pagina di questa cartella che **non usa mai `bounding_box`**: `draw_totale` e `draw_comprensori` disegnano semplicemente una tabella dopo l'altra, lasciando che il cursore del documento scorra naturalmente verso il basso — nessun bisogno di colonne affiancate né di coordinate assolute, perché non c'è nulla da posizionare in parallelo. È il caso base a cui contrapporre sia il pattern "due colonne" di `TotalsPage`/`TipologieDelegaPage`/`CessazioniPage`/`ProvvisoriePage`, sia il pattern "coordinate assolute" di `AgeClassesPage`.
>
> *EN: The simplest of the six pages, and not by accident: `StatisticSpi::MultipleDelegationsBreakdown` has no time dimension (no `anno_precedente`, see `CodeGuide/StatisticSpi/multiple_delegations_breakdown.md`) and needs no dedicated chart (the four doppia/tripla/quadrupla/quintupla counts are already readable in a compact table). The result is the only page in this folder that **never uses `bounding_box`**: `draw_totale` and `draw_comprensori` simply draw one table after another, letting the document cursor flow naturally downward — no need for side-by-side columns or absolute coordinates, because there's nothing to position in parallel. It's the base case to contrast against both the "two columns" pattern of `TotalsPage`/`TipologieDelegaPage`/`CessazioniPage`/`ProvvisoriePage` and the "absolute coordinates" pattern of `AgeClassesPage`.*

### `initialize`, `draw`

```ruby
def initialize(pdf, form:, breakdown_service: StatisticSpi::MultipleDelegationsBreakdown)
  @pdf = pdf
  @form = form
  @breakdown_service = breakdown_service
end

def draw
  @pdf.fill_color "000000"
  draw_heading
  result = @breakdown_service.call(zoning: @form.zoning, anno: @form.anno, mese: @form.mese)
  draw_totale(result)
  draw_comprensori(result) if result.comprensori.present?
end
```

> **IT:** Il parametro `breakdown_service:` iniettabile-ma-mai-iniettato-da-`ReportPdf`, il reset `fill_color`, e il flusso `draw_heading` → `call` sul servizio → `draw_totale` sono lo stesso schema di `TotalsPage` — vedi `CodeGuide/StatisticSpiPrints/totals_page.md` per il commento esteso, non ripetuto qui. Da notare `MultipleDelegationsBreakdown` non ha una `Result#success?`/`#error` (a differenza di `TotalMembersComparison`): non esiste un caso "dati mancanti" da segnalare, perché la query di questo breakdown non richiede due periodi da confrontare, solo quello corrente — se non ci sono deleghe multiple nel periodo, `build_row` produce comunque una `Row` valida con tutti i conteggi a zero, non un errore.
>
> *EN: The injectable-but-never-injected-by-`ReportPdf` `breakdown_service:` parameter, the `fill_color` reset, and the `draw_heading` → service `call` → `draw_totale` flow are the same scheme as `TotalsPage` — see `CodeGuide/StatisticSpiPrints/totals_page.md` for the extended commentary, not repeated here. Note that `MultipleDelegationsBreakdown` has no `Result#success?`/`#error` (unlike `TotalMembersComparison`): there's no "missing data" case to signal, because this breakdown's query doesn't need two periods to compare, only the current one — if there are no multiple delegations in the period, `build_row` still produces a valid `Row` with every count at zero, not an error.*

### `draw_totale`, `draw_comprensori` *(privati)*

```ruby
def draw_totale(result)
  MultipleDelegationsTable.draw(@pdf, title: result.totale.zoning.descrizione_azzonamento, rows: [ result.totale ])
end

def draw_comprensori(result)
  @pdf.move_down section_gap
  MultipleDelegationsTable.draw(@pdf, title: "Comprensori", rows: result.comprensori)
end
```

> **IT:** `MultipleDelegationsTable` (`app/services/statistic_spi_prints/multiple_delegations_table.rb`, documentata separatamente) è l'unica tabella di questo report costruita **su misura** per un `Row` SPI-specifico (`zoning`/`doppia`/`tripla`/`quadrupla`/`quintupla`/`totale`, vedi `CodeGuide/StatisticSpi/multiple_delegations_breakdown.md`) invece di riusare una tabella generica come `StatisticPrints::ComparisonTable` — coerente con la scelta, già documentata a livello di servizio, di usare campi nominati invece di un hash `totali`/`percentuali`: quei campi nominati impongono comunque una tabella dedicata, perché nessuna tabella generica del report Attivi si aspetta colonne fisse `doppia`/`tripla`/`quadrupla`/`quintupla`. `draw_comprensori` viene chiamato solo `if result.comprensori.present?` — quando l'azzonamento scelto non è regionale, la pagina mostra solo la tabella del comprensorio singolo, senza una sezione "Comprensori" vuota sotto, esattamente come in `TotalsPage`.
>
> *EN: `MultipleDelegationsTable` (`app/services/statistic_spi_prints/multiple_delegations_table.rb`, documented separately) is the only table in this report built **purpose-fit** for an SPI-specific `Row` (`zoning`/`doppia`/`tripla`/`quadrupla`/`quintupla`/`totale`, see `CodeGuide/StatisticSpi/multiple_delegations_breakdown.md`) instead of reusing a generic table like `StatisticPrints::ComparisonTable` — consistent with the choice, already documented at the service level, to use named fields instead of a `totali`/`percentuali` hash: those named fields require a dedicated table regardless, since no generic table from the Attivi report expects fixed `doppia`/`tripla`/`quadrupla`/`quintupla` columns. `draw_comprensori` is only called `if result.comprensori.present?` — when the chosen zoning isn't regional, the page shows only the single comprensorio's table, with no empty "Comprensori" section below it, exactly as in `TotalsPage`.*

### `heading_title`, `section_gap` *(privati)*

> **IT:** Identici, struttura per struttura, agli omonimi di `TotalsPage` (titolo che si ramifica su `@form.zoning.regionale?`, conversione mm→pt inline) — vedi `CodeGuide/StatisticSpiPrints/totals_page.md`. L'unica differenza è testuale (il nome della sezione, "Deleghe Multiple SPI" invece di "Totale Iscritti e Deleghe SPI"), non strutturale.
>
> *EN: Identical, structure for structure, to the same-named methods in `TotalsPage` (a title branching on `@form.zoning.regionale?`, an inline mm→pt conversion) — see `CodeGuide/StatisticSpiPrints/totals_page.md`. The only difference is textual (the section name, "Deleghe Multiple SPI" instead of "Totale Iscritti e Deleghe SPI"), not structural.*
