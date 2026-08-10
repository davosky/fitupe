# `StatisticSpi::TipologieDelegaBreakdown`

**File:** `app/services/statistic_spi/tipologie_delega_breakdown.rb`

## Codice completo

```ruby
module StatisticSpi
  # Conta le deleghe (record, non codici fiscali distinti) per tipologia_delega,
  # sia a livello regionale che per comprensorio. A differenza di
  # MultipleDelegationsBreakdown non serve riconciliazione DISTINCT ON: ogni
  # delega e' gia' un record additivo, quindi il totale regionale coincide
  # sempre con la somma dei comprensori.
  class TipologieDelegaBreakdown
    ETICHETTE = [ "Ordinaria", "Concomitante", "Invalidi Civili", "BreviManu", "Altro" ].freeze

    Row = Struct.new(:zoning, :totali, :totale, :percentuali, keyword_init: true)
    Result = Struct.new(:totale, :comprensori, keyword_init: true)

    def self.call(...) = new(...).call

    def initialize(zoning:, anno:, mese:)
      @zoning = zoning
      @anno = anno
      @mese = mese
    end

    def call
      if @zoning.regionale?
        Result.new(totale: build_row(@zoning, merge_counts(counts_by_comprensorio.values)),
          comprensori: province_zonings.map { |zoning| build_row(zoning, counts_by_comprensorio[zoning.codice_azzonamento]) })
      else
        Result.new(totale: build_row(@zoning, counts_by_comprensorio[@zoning.codice_azzonamento]), comprensori: [])
      end
    end

    private

    def build_row(zoning, counts)
      counts ||= {}
      totali = ETICHETTE.index_with { |etichetta| counts.fetch(etichetta, 0) }
      totale = totali.values.sum
      percentuali = totali.transform_values { |valore| totale.zero? ? nil : (valore.to_f / totale * 100) }

      Row.new(zoning:, totali:, totale:, percentuali:)
    end

    def merge_counts(counts_list)
      counts_list.compact.each_with_object(Hash.new(0)) do |counts, merged|
        counts.each { |etichetta, valore| merged[etichetta] += valore }
      end
    end

    def province_zonings
      Zoning.comprensori_di(@zoning)
    end

    def regional_zoning
      @zoning.regionale? ? @zoning : Zoning.find_by(codice_azzonamento: @zoning.codice_azzonamento[0])
    end

    def regional_scope
      return ImportSpi.none if regional_zoning.nil?

      ZoningPeriodScope.call(zoning: regional_zoning, anno: @anno, mese: @mese)
    end

    def counts_by_comprensorio
      @counts_by_comprensorio ||= ActiveRecord::Base.connection.select_all(sql).each_with_object({}) do |row, counts|
        (counts[row["comprensorio"]] ||= {})[row["etichetta"]] = row["totale"].to_i
      end
    end

    def sql
      <<~SQL
        WITH base AS (#{regional_scope.to_sql})
        SELECT
          SUBSTRING(codice_azzonamento_completo FROM 1 FOR 2) AS comprensorio,
          CASE tipologia_delega
            WHEN 'Ordinaria' THEN 'Ordinaria'
            WHEN 'Concomitante' THEN 'Concomitante'
            WHEN 'Invalidi civili' THEN 'Invalidi Civili'
            WHEN 'Pagamento Diretto (Brevi Manu)' THEN 'BreviManu'
            ELSE 'Altro'
          END AS etichetta,
          COUNT(*) AS totale
        FROM base
        GROUP BY comprensorio, etichetta
      SQL
    end
  end
end
```

## Sezioni commentate

### Commento di classe

```ruby
# Conta le deleghe (record, non codici fiscali distinti) per tipologia_delega,
# sia a livello regionale che per comprensorio. A differenza di
# MultipleDelegationsBreakdown non serve riconciliazione DISTINCT ON: ogni
# delega e' gia' un record additivo, quindi il totale regionale coincide
# sempre con la somma dei comprensori.
class TipologieDelegaBreakdown
```

> **IT:** Il caso "semplice" di riferimento tra i breakdown SPI, ed è utile leggerlo proprio per contrasto con `AgeBreakdown`/`MultipleDelegationsBreakdown`: qui **non serve nessuna riconciliazione per persona**, perché la domanda a cui risponde ("quante deleghe di tipo X ci sono?") riguarda le deleghe stesse, non le persone che le detengono. Ogni riga `ImportSpi` è una delega, quindi contarle per comprensorio con un semplice `GROUP BY` dà già, per costruzione, un totale regionale uguale alla somma dei comprensori — nessun `DISTINCT ON`, nessuna CTE `comprensorio_primario`.
>
> *EN: The "simple" reference case among the SPI breakdowns, and it's worth reading precisely in contrast with `AgeBreakdown`/`MultipleDelegationsBreakdown`: **no per-person reconciliation is needed here**, because the question it answers ("how many type-X delegations are there?") is about the delegations themselves, not the people holding them. Every `ImportSpi` row is one delegation, so counting them per comprensorio with a plain `GROUP BY` already yields, by construction, a regional total equal to the sum of the comprensori — no `DISTINCT ON`, no `comprensorio_primario` CTE.*

### `ETICHETTE` (costante)

```ruby
ETICHETTE = [ "Ordinaria", "Concomitante", "Invalidi Civili", "BreviManu", "Altro" ].freeze
```

> **IT:** Le cinque etichette visualizzate, in ordine fisso (usato sia per l'iterazione in `build_row` sia implicitamente come "ordine canonico" della sezione nella vista). Da notare la mappatura tra questi nomi "puliti" e i valori grezzi del database, visibile solo dentro `sql` (es. "Invalidi civili" nel DB diventa "Invalidi Civili" qui, "Pagamento Diretto (Brevi Manu)" diventa "BreviManu"): `ETICHETTE` contiene i valori **già normalizzati**, non i valori grezzi di `tipologia_delega`.
>
> *EN: The five displayed labels, in a fixed order (used both for the iteration in `build_row` and implicitly as the section's "canonical order" in the view). Note the mapping between these "clean" names and the raw database values, visible only inside `sql` (e.g. "Invalidi civili" in the DB becomes "Invalidi Civili" here, "Pagamento Diretto (Brevi Manu)" becomes "BreviManu"): `ETICHETTE` holds the **already-normalized** values, not `tipologia_delega`'s raw values.*

### `Row`, `Result`, `call`, `build_row`, `merge_counts`, `province_zonings`, `regional_zoning`, `regional_scope`, `counts_by_comprensorio`

> **IT:** Tutti identici, struttura per struttura, a `AgeBreakdown` (con `etichetta`/`ETICHETTE` al posto di `fascia`/`BANDS`) — vedi `CodeGuide/StatisticSpi/age_breakdown.md` per il commento dettagliato di ciascuno. L'unica vera differenza tra le due classi è dentro `sql`, descritta di seguito.
>
> *EN: All identical, structure for structure, to `AgeBreakdown` (with `etichetta`/`ETICHETTE` instead of `fascia`/`BANDS`) — see `CodeGuide/StatisticSpi/age_breakdown.md` for the detailed commentary on each. The one real difference between the two classes is inside `sql`, described below.*

### `sql` *(privato)*

```ruby
def sql
  <<~SQL
    WITH base AS (#{regional_scope.to_sql})
    SELECT
      SUBSTRING(codice_azzonamento_completo FROM 1 FOR 2) AS comprensorio,
      CASE tipologia_delega
        WHEN 'Ordinaria' THEN 'Ordinaria'
        WHEN 'Concomitante' THEN 'Concomitante'
        WHEN 'Invalidi civili' THEN 'Invalidi Civili'
        WHEN 'Pagamento Diretto (Brevi Manu)' THEN 'BreviManu'
        ELSE 'Altro'
      END AS etichetta,
      COUNT(*) AS totale
    FROM base
    GROUP BY comprensorio, etichetta
  SQL
end
```

> **IT:** Una sola CTE (`base`), niente `DISTINCT ON`: la query più semplice tra tutti i breakdown SPI a livello di struttura, esattamente perché non serve riconciliare nulla per persona. Il `CASE tipologia_delega WHEN ... END`, a differenza del `CASE` calcolato di `AgeBreakdown` (`band_case_sql`, generato dinamicamente da `BANDS`), è una mappatura **statica e scritta a mano** valore-per-valore, con un `ELSE 'Altro'` che cattura qualunque valore di `tipologia_delega` non esplicitamente elencato — incluso `NULL`. Questo significa che questa sezione **non perde mai record**: a differenza di `AgeBreakdown` (dove `WHERE data_nascita IS NOT NULL` esclude esplicitamente i record senza data), qui ogni singola delega finisce in una categoria, "Altro" compreso, quindi `totale` (la somma delle cinque etichette) coincide sempre con il numero di deleghe della riga, senza eccezioni.
>
> Il perché dei nomi grezzi "strani" (es. maiuscole/minuscole incoerenti come "Invalidi civili" vs "Ordinaria") non è una scelta di design: riflette i valori esatti così come arrivano dall'importazione SinCGIL, che questa `CASE` normalizza per la visualizzazione senza modificare i dati sorgente.
>
> *EN: A single CTE (`base`), no `DISTINCT ON`: structurally the simplest query among all the SPI breakdowns, precisely because no per-person reconciliation is needed. The `CASE tipologia_delega WHEN ... END`, unlike `AgeBreakdown`'s computed `CASE` (`band_case_sql`, dynamically generated from `BANDS`), is a **static, hand-written**, value-by-value mapping, with an `ELSE 'Altro'` that catches any `tipologia_delega` value not explicitly listed — including `NULL`. This means this section **never loses records**: unlike `AgeBreakdown` (where `WHERE data_nascita IS NOT NULL` explicitly excludes records with no date), here every single delegation ends up in some category, "Altro" included, so `totale` (the sum of the five labels) always matches the row's delegation count, no exceptions.
>
> The "odd" raw names (e.g. inconsistent casing like "Invalidi civili" vs "Ordinaria") aren't a design choice: they reflect the exact values as they arrive from the SinCGIL import, which this `CASE` normalizes for display without altering the source data.*

### Perché le percentuali qui sono sul totale delle 5 etichette, non sul totale deleghe

> **IT:** A differenza di `CessazioniBreakdown` e `ProvvisorieBreakdown` — che calcolano la percentuale sul **totale deleghe del periodo** (`deleghe_by_comprensorio`), perché rappresentano un sottoinsieme delle deleghe — qui `build_row` calcola la percentuale sul `totale` locale (la somma delle cinque etichette). Questo è coerente perché, come spiegato sopra, ogni delega finisce sempre in una delle cinque etichette (`ELSE 'Altro'`): la somma delle cinque etichette **è** il totale deleghe, quindi le due basi di calcolo coincidono qui, mentre divergono per Cessazioni/Provvisorie, dove solo un sottoinsieme delle deleghe rientra nel conteggio.
>
> *EN: Unlike `CessazioniBreakdown` and `ProvvisorieBreakdown` — which compute their percentage against the **period's total delegations** (`deleghe_by_comprensorio`), because they represent a subset of delegations — `build_row` here computes the percentage against the local `totale` (the sum of the five labels). This is consistent because, as explained above, every delegation always lands in one of the five labels (`ELSE 'Altro'`): the sum of the five labels **is** the delegation total, so the two calculation bases coincide here, while they diverge for Cessazioni/Provvisorie, where only a subset of delegations enters the count.*
