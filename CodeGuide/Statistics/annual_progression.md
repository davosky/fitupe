# `Statistics::AnnualProgression`

**File:** `app/services/statistics/annual_progression.rb`

## Codice completo

```ruby
module Statistics
  # Progressione mensile degli iscritti dell'anno scelto e del precedente, da
  # Gennaio fino all'ultimo mese disponibile dell'anno scelto, ricalibrata con
  # le integrazioni FILLEA/FLC come in Statistiche Con Integrazioni (un mese
  # senza dato di integrazione resta invariato, senza bloccare). La crescita %
  # di ciascun anno è (ultimo mese - Gennaio) / Gennaio.
  class AnnualProgression
    Result = Struct.new(:anno, :anno_precedente, :mesi, :rows_anno, :rows_precedente, :gaps, :error,
      keyword_init: true) do
      def success? = error.blank?
    end

    CORRECTIONS = [ StatisticWithIntegrations::FilleaCorrection, StatisticWithIntegrations::FlcCorrection ].freeze

    Row = Struct.new(:zoning, :counts, :crescita) { def label = zoning.descrizione_azzonamento }
    Gap = Struct.new(:zoning, :crescita_precedente, :crescita_anno, :differenza) { def label = zoning.descrizione_azzonamento }

    def self.call(...) = new(...).call

    def initialize(zoning:, anno:)
      @zoning = zoning
      @anno = anno
      @anno_precedente = (anno.to_i - 1).to_s
    end

    def call
      return error_result("Non ci sono dati per il #{@anno}") if mesi.empty?
      return error_result("Non ci sono dati per Gennaio e #{mesi.last} #{@anno_precedente}") unless previous_complete?

      Result.new(anno: @anno, anno_precedente: @anno_precedente, mesi:, rows_anno: rows(@anno),
        rows_precedente: rows(@anno_precedente), gaps:)
    end

    private

    def mesi
      @mesi ||= begin
        last = ImportForm::MESI.rindex { |mese| scope(@zoning, @anno, mese).exists? }
        last ? ImportForm::MESI.first(last + 1) : []
      end
    end

    def previous_complete?
      [ mesi.first, mesi.last ].all? { |mese| scope(@zoning, @anno_precedente, mese).exists? }
    end

    # ponytail: ~3s sui dati reali FVG (count + integrazioni per comprensorio/mese), raggruppare se serve
    def rows(anno)
      (@rows ||= {})[anno] ||= zonings.map do |zoning|
        by_mese = scope(zoning, anno, mesi).group(:mese_di_riferimento).count
        counts = mesi.map { |mese| by_mese.fetch(mese, 0) + integrazione(zoning, anno, mese) }
        Row.new(zoning:, counts:, crescita: crescita(counts.first, counts.last))
      end
    end

    def gaps
      precedente = rows(@anno_precedente).index_by(&:zoning)
      rows(@anno).filter_map do |row|
        next unless chart_zonings.include?(row.zoning)

        prev = precedente[row.zoning].crescita
        differenza = row.crescita - prev if row.crescita && prev
        Gap.new(zoning: row.zoning, crescita_precedente: prev, crescita_anno: row.crescita, differenza:)
      end
    end

    # La regione somma le correzioni dei comprensori, come FilleaCorrection/FlcCorrection a livello regionale.
    def integrazione(zoning, anno, mese)
      return chart_zonings.sum { |comprensorio| integrazione(comprensorio, anno, mese) } unless chart_zonings.include?(zoning)

      (@integrazioni ||= {})[[ zoning, anno, mese ]] ||= CORRECTIONS.sum do |correction|
        result = correction.call(zoning:, anno:, mese:)
        result.success? ? result.total_diff : 0
      end
    end

    def crescita(primo, ultimo)
      return nil if primo.zero?

      (ultimo - primo).to_f / primo * 100
    end

    def zonings
      @zonings ||= [ @zoning, *chart_zonings ].uniq
    end

    def chart_zonings
      @chart_zonings ||= @zoning.regionale? ? Zoning.comprensori_di(@zoning).to_a.presence || [ @zoning ] : [ @zoning ]
    end

    def scope(zoning, anno, mese)
      ZoningPeriodScope.call(zoning:, anno:, mese:)
    end

    def error_result(message)
      Result.new(anno: @anno, anno_precedente: @anno_precedente,
        error: "#{message} nell'azzonamento #{@zoning.descrizione_azzonamento}.")
    end
  end
end
```

## Sezioni commentate

### Commento di classe e `CORRECTIONS`

```ruby
# Progressione mensile degli iscritti dell'anno scelto e del precedente, da
# Gennaio fino all'ultimo mese disponibile dell'anno scelto, ricalibrata con
# le integrazioni FILLEA/FLC come in Statistiche Con Integrazioni (un mese
# senza dato di integrazione resta invariato, senza bloccare). La crescita %
# di ciascun anno è (ultimo mese - Gennaio) / Gennaio.
class AnnualProgression
  # ...
  CORRECTIONS = [ StatisticWithIntegrations::FilleaCorrection, StatisticWithIntegrations::FlcCorrection ].freeze
```

> **IT:** La pagina Progressione Annuale (`/statistics/progression`) vive nel namespace `Statistics`, ma i suoi numeri sono quelli di **Statistiche Con Integrazioni**, non quelli grezzi SinCGIL: è stato chiesto esplicitamente subito dopo la prima versione, che usava i conteggi grezzi. La conferma che fosse la scelta giusta è arrivata dai dati: con le correzioni FILLEA/FLC ogni cella coincide esattamente con il mockup di riferimento (`.ai/schermate/annuale.png`), senza invece non tornava nessun numero. Le due classi di correzione vengono riusate così come sono (vedi `CodeGuide/StatisticWithIntegrations/`), non reimplementate: `CORRECTIONS` è solo l'elenco su cui sommare.
>
> *EN: The Annual Progression page (`/statistics/progression`) lives in the `Statistics` namespace, but its numbers are the **Statistics With Integrations** ones, not raw SinCGIL counts: this was asked for explicitly right after the first version, which used raw counts. The data confirmed it was right: with the FILLEA/FLC corrections every cell matches the reference mockup (`.ai/schermate/annuale.png`) exactly, while without them no number matched. Both correction classes are reused as-is (see `CodeGuide/StatisticWithIntegrations/`), not reimplemented: `CORRECTIONS` is just the list to sum over.*

### `Result`, `Row`, `Gap`

```ruby
Result = Struct.new(:anno, :anno_precedente, :mesi, :rows_anno, :rows_precedente, :gaps, :error,
  keyword_init: true) do
  def success? = error.blank?
end

Row = Struct.new(:zoning, :counts, :crescita) { def label = zoning.descrizione_azzonamento }
Gap = Struct.new(:zoning, :crescita_precedente, :crescita_anno, :differenza) { def label = zoning.descrizione_azzonamento }
```

> **IT:** Stessa forma degli altri servizi della cartella (`Result` con `success?`/`error`, vedi `total_members_comparison.md`). `Row.counts` è un array allineato a `mesi` (indice 0 = Gennaio), non un hash per nome del mese: la vista itera sempre su tutti i 12 `ImportForm::MESI` e lascia vuote le celle oltre l'ultimo mese disponibile, come nel mockup. `Gap` esiste separato da `Row` perché la tabella "Differenza di Crescita" e i grafici mostrano solo i comprensori, mentre le tabelle mensili includono anche la riga regionale. `label` è l'unica cosa che il partial condiviso `_progression_year.html.erb` legge: così lo stesso partial serve anche `AnnualCategoryProgression`, le cui righe hanno `categoria` invece di `zoning`. `keyword_init: true` non serve (da Ruby 3.2 `Struct` accetta comunque argomenti per nome) ed è stato tolto per restare entro le 100 righe per classe.
>
> *EN: Same shape as the folder's other services (`Result` with `success?`/`error`, see `total_members_comparison.md`). `Row.counts` is an array aligned with `mesi` (index 0 = January), not a hash keyed by month name: the view always iterates over all 12 `ImportForm::MESI` and leaves cells past the last available month blank, as in the mockup. `Gap` is separate from `Row` because the "Growth Difference" table and the charts show only the comprensori, while the monthly tables also include the regional row. `label` is the only thing the shared `_progression_year.html.erb` partial reads: that way the same partial also serves `AnnualCategoryProgression`, whose rows carry `categoria` instead of `zoning`. `keyword_init: true` isn't needed (since Ruby 3.2 `Struct` accepts keyword arguments anyway) and was dropped to stay within the 100-lines-per-class limit.*

### `call`, `mesi`, `previous_complete?`

```ruby
def call
  return error_result("Non ci sono dati per il #{@anno}") if mesi.empty?
  return error_result("Non ci sono dati per Gennaio e #{mesi.last} #{@anno_precedente}") unless previous_complete?
  # ...
end

def mesi
  @mesi ||= begin
    last = ImportForm::MESI.rindex { |mese| scope(@zoning, @anno, mese).exists? }
    last ? ImportForm::MESI.first(last + 1) : []
  end
end

def previous_complete?
  [ mesi.first, mesi.last ].all? { |mese| scope(@zoning, @anno_precedente, mese).exists? }
end
```

> **IT:** Il form chiede solo azzonamento e anno, non il mese: il periodo è sempre "da Gennaio all'ultimo mese importato dell'anno scelto", e l'anno precedente viene **tagliato allo stesso mese** (nel mockup il 2025 si ferma ad Agosto come il 2026), così le due crescite sono confrontabili sullo stesso numero di mesi. Per l'anno precedente bastano Gennaio e l'ultimo mese, perché sono gli unici due che entrano nella formula della crescita; i mesi intermedi mancanti compaiono come 0 in tabella invece di bloccare. Come nel resto di Statistiche, la mancanza di dati SinCGIL produce un `alert-warning` esplicito, mai zeri silenziosi.
>
> *EN: The form only asks for zoning and year, not month: the period is always "January through the last imported month of the chosen year", and the previous year is **cut at the same month** (in the mockup 2025 stops at August like 2026), so both growth figures cover the same number of months. For the previous year only January and the last month are required, since they're the only two that enter the growth formula; missing intermediate months show as 0 in the table instead of blocking. As in the rest of Statistics, missing SinCGIL data yields an explicit `alert-warning`, never silent zeros.*

### `rows`

```ruby
# ponytail: ~3s sui dati reali FVG (count + integrazioni per comprensorio/mese), raggruppare se serve
def rows(anno)
  (@rows ||= {})[anno] ||= zonings.map do |zoning|
    by_mese = scope(zoning, anno, mesi).group(:mese_di_riferimento).count
    counts = mesi.map { |mese| by_mese.fetch(mese, 0) + integrazione(zoning, anno, mese) }
    Row.new(zoning:, counts:, crescita: crescita(counts.first, counts.last))
  end
end
```

> **IT:** `ZoningPeriodScope` riceve qui un **array** di mesi invece di un mese singolo: funziona senza modifiche perché `where(mese_di_riferimento: [...])` diventa un `IN`, e permette una sola `COUNT ... GROUP BY mese_di_riferimento` per azzonamento/anno invece di una query per mese (da ~2,2 s a ~1,5 s prima delle integrazioni). La memoizzazione per anno serve perché `gaps` rilegge le stesse righe già calcolate per le tabelle. Il commento `ponytail:` segna il limite noto: il costo dominante ora sono le correzioni FILLEA, che contano gli iscritti "Ordinaria Cassa Edile" comprensorio per comprensorio e mese per mese.
>
> *EN: `ZoningPeriodScope` receives an **array** of months here instead of a single one: it works unchanged because `where(mese_di_riferimento: [...])` becomes an `IN`, allowing a single `COUNT ... GROUP BY mese_di_riferimento` per zoning/year instead of one query per month (from ~2.2 s to ~1.5 s before integrations). Per-year memoization exists because `gaps` re-reads the same rows already computed for the tables. The `ponytail:` comment marks the known ceiling: the dominant cost is now the FILLEA corrections, which count "Ordinaria Cassa Edile" members per comprensorio per month.*

### `integrazione`

```ruby
# La regione somma le correzioni dei comprensori, come FilleaCorrection/FlcCorrection a livello regionale.
def integrazione(zoning, anno, mese)
  return chart_zonings.sum { |comprensorio| integrazione(comprensorio, anno, mese) } unless chart_zonings.include?(zoning)

  (@integrazioni ||= {})[[ zoning, anno, mese ]] ||= CORRECTIONS.sum do |correction|
    result = correction.call(zoning:, anno:, mese:)
    result.success? ? result.total_diff : 0
  end
end
```

> **IT:** Due scelte deliberate. **Mai bloccare**: in Statistiche Con Integrazioni un comprensorio senza dato di integrazione per il periodo corrente blocca la pagina, ma qui i periodi sono fino a 24 (12 mesi × 2 anni) e un singolo mese FLC mancante renderebbe la pagina inutilizzabile; un `result` non `success?` vale quindi 0 e quel mese resta col solo conteggio SinCGIL (è lo stesso comportamento che le correzioni hanno già a livello regionale). **La riga regionale non richiama le correzioni**: `FilleaCorrection`/`FlcCorrection` a livello regionale sommano già le province, quindi qui si sommano direttamente i risultati memoizzati dei comprensori invece di ricalcolarli (da ~3,9 s a ~2,9 s). Una conseguenza visibile: dove mancano dati FLC (es. Gennaio 2026 in sviluppo) la serie mostra un salto, e la crescita % ne risente — è un riflesso fedele dei dati, non un errore di calcolo.
>
> *EN: Two deliberate choices. **Never block**: in Statistics With Integrations a comprensorio without integration data for the current period blocks the page, but here there are up to 24 periods (12 months × 2 years) and a single missing FLC month would make the page unusable; so a non-`success?` `result` counts as 0 and that month keeps the plain SinCGIL count (the same behavior the corrections already have at regional level). **The regional row doesn't call the corrections again**: `FilleaCorrection`/`FlcCorrection` at regional level already sum the provinces, so here the memoized comprensorio results are summed directly instead of being recomputed (from ~3.9 s to ~2.9 s). A visible consequence: where FLC data is missing (e.g. January 2026 in development) the series shows a jump and the growth % is affected — a faithful reflection of the data, not a calculation bug.*

### `gaps` e `crescita`

```ruby
def gaps
  precedente = rows(@anno_precedente).index_by(&:zoning)
  rows(@anno).filter_map do |row|
    next unless chart_zonings.include?(row.zoning)

    prev = precedente[row.zoning].crescita
    differenza = row.crescita - prev if row.crescita && prev
    Gap.new(zoning: row.zoning, crescita_precedente: prev, crescita_anno: row.crescita, differenza:)
  end
end

def crescita(primo, ultimo)
  return nil if primo.zero?

  (ultimo - primo).to_f / primo * 100
end
```

> **IT:** La formula (ultimo mese − Gennaio) / Gennaio non era scritta nella specifica (`.ai/statistiche/progresso_annuale.md`): è stata ricavata dai numeri del mockup, dove le crescite 2026 tornano al centesimo. Il grafico 2025 del mockup ha invece le etichette spostate di un comprensorio (il 5,80% è la crescita FVG, non di Trieste): i valori corretti sono quelli calcolati qui, non quelli disegnati. La **differenza** è in punti percentuali (crescita anno − crescita anno precedente), non una variazione relativa tra le due crescite. `nil` (Gennaio a zero) si propaga fino alla vista, che lascia la cella vuota invece di mostrare una divisione per zero.
>
> *EN: The formula (last month − January) / January wasn't written in the spec (`.ai/statistiche/progresso_annuale.md`): it was derived from the mockup's numbers, where the 2026 growth figures match to the hundredth. The mockup's 2025 chart, however, has its labels shifted by one comprensorio (5.80% is FVG's growth, not Trieste's): the correct values are the ones computed here, not the drawn ones. The **difference** is in percentage points (this year's growth − last year's growth), not a relative change between the two. `nil` (zero January) propagates to the view, which leaves the cell blank instead of showing a division by zero.*

### `zonings`, `chart_zonings`, `scope`, `error_result`

```ruby
def zonings
  @zonings ||= [ @zoning, *chart_zonings ].uniq
end

def chart_zonings
  @chart_zonings ||= @zoning.regionale? ? Zoning.comprensori_di(@zoning).to_a.presence || [ @zoning ] : [ @zoning ]
end
```

> **IT:** Le tabelle mensili mostrano la regione più i comprensori; grafici e tabella delle differenze solo i comprensori (come nel mockup). Se l'azzonamento scelto è provinciale, o è regionale ma senza comprensori, `chart_zonings` ricade sull'azzonamento stesso e `uniq` evita di mostrare la stessa riga due volte. `scope` è un semplice alias su `ZoningPeriodScope` (vedi `zoning_period_scope.md`); `error_result` segue il formato di messaggio di `TotalMembersComparison`.
>
> *EN: Monthly tables show the region plus its comprensori; charts and the difference table only the comprensori (as in the mockup). If the chosen zoning is provincial, or regional without comprensori, `chart_zonings` falls back to the zoning itself and `uniq` avoids showing the same row twice. `scope` is a thin alias over `ZoningPeriodScope` (see `zoning_period_scope.md`); `error_result` follows `TotalMembersComparison`'s message format.*
