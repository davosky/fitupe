# `StatisticSpiPrints::ProvvisoriePage`

**File:** `app/services/statistic_spi_prints/provvisorie_page.rb`

## Codice completo

```ruby
module StatisticSpiPrints
  # Pagina "Provvisorie": specchia app/views/statistic_spi/_provvisorie_card e
  # _provvisorie_comprensori_card. Totale (tabella + torta Provvisorie/Deleghe
  # Confermate) e Comprensori (tabella + torta "raw percentages", una fetta
  # per comprensorio piu' Deleghe Confermate) affiancati in colonne, come le
  # altre pagine SPI, per stare in una pagina sola.
  class ProvvisoriePage
    SECTION_GAP_MM = 8
    COLUMN_GAP_MM = 12
    CHART_HEIGHT_MM = 85
    COMPRENSORI_COLORS = %w[28B62C FF851B FF4136 158CBA 75CAEB].freeze

    def self.draw(...) = new(...).draw

    def initialize(pdf, form:, breakdown_service: StatisticSpi::ProvvisorieBreakdown)
      @pdf = pdf
      @form = form
      @breakdown_service = breakdown_service
    end

    def draw
      @pdf.fill_color "000000"
      draw_heading
      result = @breakdown_service.call(zoning: @form.zoning, anno: @form.anno, mese: @form.mese)
      if result.comprensori.present?
        draw_two_columns(result)
      else
        draw_totale_column(result, @pdf.bounds.left, @pdf.cursor, @pdf.bounds.width)
      end
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
      return "CGIL Provvisorie SPI – Regionale e Comprensori" if @form.zoning.regionale?

      "CGIL Provvisorie SPI – Comprensorio di #{@form.zoning.descrizione_azzonamento}"
    end

    def draw_two_columns(result)
      top = @pdf.cursor
      left = @pdf.bounds.left

      draw_totale_column(result, left, top, column_width)
      draw_comprensori_column(result, left + column_width + column_gap, top, column_width)
    end

    def draw_totale_column(result, x, top, width)
      @pdf.bounding_box([ x, top ], width: width, height: top) do
        ProvvisorieTable.draw(@pdf, title: result.totale.zoning.descrizione_azzonamento, rows: [ result.totale ])
        @pdf.move_down section_gap
        draw_totale_chart(result.totale, width)
      end
    end

    def draw_totale_chart(row, width)
      deleghe_confermate = row.deleghe_totale - row.totale
      StatisticPrints::PieChart.draw(
        @pdf, at: [ @pdf.bounds.left, @pdf.cursor ], width: width, height: chart_height,
        labels: [ "Provvisorie", "Deleghe Confermate" ], data: [ row.totale, deleghe_confermate ]
      )
    end

    def draw_comprensori_column(result, x, top, width)
      @pdf.bounding_box([ x, top ], width: width, height: top) do
        ProvvisorieTable.draw(@pdf, title: "Comprensori", rows: result.comprensori)
        @pdf.move_down section_gap
        draw_comprensori_chart(result.comprensori, width)
      end
    end

    def draw_comprensori_chart(comprensori, width)
      deleghe_confermate_percentuale = 100.0 - comprensori.sum { |row| row.percentuale || 0 }
      labels = comprensori.map { |row| row.zoning.descrizione_azzonamento } + [ "Deleghe Confermate" ]
      data = comprensori.map { |row| row.percentuale || 0 } + [ deleghe_confermate_percentuale ]

      StatisticPrints::PieChart.draw(
        @pdf, at: [ @pdf.bounds.left, @pdf.cursor ], width: width, height: chart_height, labels: labels, data: data,
        colors: COMPRENSORI_COLORS, label_formatter: ->(value, _fraction) { [ StatisticPrints::NumberFormatting.percent(value) ] }
      )
    end

    def column_width = (@pdf.bounds.width - column_gap) / 2
    def column_gap = COLUMN_GAP_MM * 72 / 25.4
    def section_gap = SECTION_GAP_MM * 72 / 25.4
    def chart_height = [ @pdf.cursor - 6, CHART_HEIGHT_MM * 72 / 25.4 ].min
  end
end
```

## Sezioni commentate

### Commento di classe

```ruby
# Pagina "Provvisorie": specchia app/views/statistic_spi/_provvisorie_card e
# _provvisorie_comprensori_card. Totale (tabella + torta Provvisorie/Deleghe
# Confermate) e Comprensori (tabella + torta "raw percentages", una fetta
# per comprensorio piu' Deleghe Confermate) affiancati in colonne, come le
# altre pagine SPI, per stare in una pagina sola.
class ProvvisoriePage
```

> **IT:** Praticamente gemella di `CessazioniPage` — stesso fork `draw`, stesso schema di due colonne, stessa coppia di torte (totale con due fette, comprensori con "percentuali grezze" più il residuo Deleghe Confermate). Vale quindi la stessa lettura fatta per `CessazioniPage` (vedi `CodeGuide/StatisticSpiPrints/cessazioni_page.md` per il dettaglio di `draw_totale_chart`/`draw_comprensori_chart` e del `label_formatter:` "raw percentages", non ripetuto qui). Le differenze reali si concentrano tutte nella forma del dato sorgente: `StatisticSpi::ProvvisorieBreakdown::Row` ha un **singolo** campo `percentuale` (non un hash `percentuali` per etichetta, vedi `CodeGuide/StatisticSpi/provvisorie_breakdown.md`), perché le pratiche provvisorie non hanno sotto-categorie da distinguere come i motivi di cessazione — sono un sì/no (`provvisoria = 'SI'`), non una tassonomia a cinque o sei voci.
>
> *EN: Practically a twin of `CessazioniPage` — same `draw` fork, same two-column scheme, same pair of pie charts (a two-slice total, and a "raw percentages" comprensori chart with the Deleghe Confermate residual). The same reading applies as for `CessazioniPage` (see `CodeGuide/StatisticSpiPrints/cessazioni_page.md` for the detail on `draw_totale_chart`/`draw_comprensori_chart` and the "raw percentages" `label_formatter:`, not repeated here). The real differences all concentrate in the shape of the source data: `StatisticSpi::ProvvisorieBreakdown::Row` has a **single** `percentuale` field (not a `percentuali` hash keyed by label, see `CodeGuide/StatisticSpi/provvisorie_breakdown.md`), because provisional cases have no sub-categories to distinguish the way cessation reasons do — they're a yes/no (`provvisoria = 'SI'`), not a five- or six-item taxonomy.*

### Assenza di `ETICHETTE`, `ProvvisorieTable`

```ruby
def draw_totale_column(result, x, top, width)
  @pdf.bounding_box([ x, top ], width: width, height: top) do
    ProvvisorieTable.draw(@pdf, title: result.totale.zoning.descrizione_azzonamento, rows: [ result.totale ])
    @pdf.move_down section_gap
    draw_totale_chart(result.totale, width)
  end
end
```

> **IT:** A differenza di `TipologieDelegaPage`/`CessazioniPage`, questa classe **non ha una costante `ETICHETTE`**: non c'è nessuna lista di categorie da passare a una tabella generica come `CategoryTable`, perché `Row#percentuale` è un valore scalare, non un hash. `ProvvisorieTable` (`app/services/statistic_spi_prints/provvisorie_table.rb`, documentata separatamente) è quindi, come `MultipleDelegationsTable`, una tabella costruita su misura per la forma minimale di questo `Row` (`zoning`/`totale`/`deleghe_totale`/`percentuale`) — non riceve `etichette:` perché non ne ha bisogno. Non c'è nemmeno l'equivalente di `CategoryPercentageTable`/`MotivoCessazionePercentageTable`: con un solo numero da mostrare, la percentuale sta già in una colonna di `ProvvisorieTable`, senza bisogno di una tabella dedicata.
>
> *EN: Unlike `TipologieDelegaPage`/`CessazioniPage`, this class has **no `ETICHETTE` constant**: there's no list of categories to pass to a generic table like `CategoryTable`, because `Row#percentuale` is a scalar value, not a hash. `ProvvisorieTable` (`app/services/statistic_spi_prints/provvisorie_table.rb`, documented separately) is therefore, like `MultipleDelegationsTable`, a table purpose-built for this `Row`'s minimal shape (`zoning`/`totale`/`deleghe_totale`/`percentuale`) — it takes no `etichette:` because it doesn't need one. There's also no equivalent of `CategoryPercentageTable`/`MotivoCessazionePercentageTable`: with just one number to show, the percentage already fits in a column of `ProvvisorieTable`, with no need for a dedicated table.*

### `draw_comprensori_chart` — stessa tecnica "raw percentages" con `row.percentuale` invece di `row.percentuali[etichetta]`

```ruby
def draw_comprensori_chart(comprensori, width)
  deleghe_confermate_percentuale = 100.0 - comprensori.sum { |row| row.percentuale || 0 }
  labels = comprensori.map { |row| row.zoning.descrizione_azzonamento } + [ "Deleghe Confermate" ]
  data = comprensori.map { |row| row.percentuale || 0 } + [ deleghe_confermate_percentuale ]

  StatisticPrints::PieChart.draw(
    @pdf, at: [ @pdf.bounds.left, @pdf.cursor ], width: width, height: chart_height, labels: labels, data: data,
    colors: COMPRENSORI_COLORS, label_formatter: ->(value, _fraction) { [ StatisticPrints::NumberFormatting.percent(value) ] }
  )
end
```

> **IT:** Stessa costruzione della torta comprensori di `CessazioniPage`, ma qui `row.percentuale` è già pronta (calcolata in `ProvvisorieBreakdown#build_row`, con lo stesso denominatore `deleghe_totale` del periodo), quindi non serve un metodo privato equivalente a `CessazioniPage#comprensorio_percentuale`: `|| 0` fa da guardia diretta sul possibile `nil` (denominatore zero) al posto di una chiamata di metodo dedicata. Il resto — `label_formatter:` "raw percentages", `COMPRENSORI_COLORS` duplicata, il residuo `100.0 - somma` per la fetta "Deleghe Confermate" — è identico a `CessazioniPage`, vedi quel file per il dettaglio del perché `default_label` di `PieChart` non andrebbe bene qui.
>
> *EN: The same comprensori pie-chart construction as `CessazioniPage`, but here `row.percentuale` is already computed (in `ProvvisorieBreakdown#build_row`, with the same period `deleghe_totale` denominator), so there's no need for a private method equivalent to `CessazioniPage#comprensorio_percentuale`: `|| 0` acts as a direct guard against the possible `nil` (zero denominator) instead of a dedicated method call. The rest — the "raw percentages" `label_formatter:`, the duplicated `COMPRENSORI_COLORS`, the `100.0 - sum` residual for the "Deleghe Confermate" slice — is identical to `CessazioniPage`, see that file for the detail on why `PieChart`'s `default_label` wouldn't work here.*

### `CHART_HEIGHT_MM = 85` — più spazio, meno elementi nella colonna

> **IT:** L'unica costante numerica che cambia rispetto a `CessazioniPage` (85mm invece di 60mm). La ragione è nel layout della colonna Totale: qui contiene solo due elementi impilati (`ProvvisorieTable` + torta), non tre come in `CessazioniPage` (tabella + tabella percentuali + torta) — niente equivalente di `MotivoCessazionePercentageTable` da fare spazio, quindi il grafico può permettersi di essere più alto senza rischiare di sforare lo spazio verticale del `bounding_box`.
>
> *EN: The only numeric constant that changes relative to `CessazioniPage` (85mm instead of 60mm). The reason lies in the Totale column's layout: here it stacks only two elements (`ProvvisorieTable` + pie chart), not three like in `CessazioniPage` (table + percentage table + pie) — no `MotivoCessazionePercentageTable` equivalent taking up room, so the chart can afford to be taller without risking overflowing the `bounding_box`'s vertical space.*
