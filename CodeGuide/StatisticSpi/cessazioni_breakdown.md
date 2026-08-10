# `StatisticSpi::CessazioniBreakdown`

**File:** `app/services/statistic_spi/cessazioni_breakdown.rb`

## Codice completo

```ruby
module StatisticSpi
  # Conta le cessazioni (motivo_cessazione_iscrizione tra un elenco fisso di
  # motivi rilevanti, altri valori come "Scadenza versamento diretto" esclusi)
  # per motivo, a livello regionale e per comprensorio. Come
  # TipologieDelegaBreakdown nessuna riconciliazione DISTINCT ON e' necessaria
  # (ogni cessazione e' gia' un record additivo). A differenza sua pero' le
  # percentuali non sono calcolate sul totale delle cessazioni stesse, ma sul
  # totale deleghe del periodo: le cessazioni sono un sottoinsieme delle
  # deleghe, non le esauriscono.
  class CessazioniBreakdown
    ETICHETTE = [
      "Altra Motivazione Ente", "Cambio Situazione Pensionistica", "Cessazione Posizione Pensionistica",
      "Chiusura Iscrizione Provvisoria", "Decesso", "Revoca"
    ].freeze

    Row = Struct.new(:zoning, :totali, :totale, :deleghe_totale, :percentuali, keyword_init: true)
    Result = Struct.new(:totale, :comprensori, keyword_init: true)

    def self.call(...) = new(...).call

    def initialize(zoning:, anno:, mese:)
      @zoning = zoning
      @anno = anno
      @mese = mese
    end

    def call
      if @zoning.regionale?
        Result.new(totale: build_row(@zoning, merge_counts(counts_by_comprensorio.values), deleghe_by_comprensorio.values.sum),
          comprensori: province_zonings.map { |zoning| build_row(zoning, counts_by_comprensorio[zoning.codice_azzonamento],
            deleghe_by_comprensorio[zoning.codice_azzonamento]) })
      else
        Result.new(totale: build_row(@zoning, counts_by_comprensorio[@zoning.codice_azzonamento],
          deleghe_by_comprensorio[@zoning.codice_azzonamento]), comprensori: [])
      end
    end

    private

    def build_row(zoning, counts, deleghe_totale)
      counts ||= {}
      deleghe_totale ||= 0
      totali = ETICHETTE.index_with { |etichetta| counts.fetch(etichetta, 0) }
      percentuali = totali.transform_values { |valore| deleghe_totale.zero? ? nil : (valore.to_f / deleghe_totale * 100) }

      Row.new(zoning:, totali:, totale: totali.values.sum, deleghe_totale:, percentuali:)
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

    def deleghe_by_comprensorio
      @deleghe_by_comprensorio ||= regional_scope.group("SUBSTRING(codice_azzonamento_completo FROM 1 FOR 2)").count
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
          CASE motivo_cessazione_iscrizione
            WHEN 'Altra motivazione Ente' THEN 'Altra Motivazione Ente'
            WHEN 'Cambio situazione pensionistica' THEN 'Cambio Situazione Pensionistica'
            WHEN 'Cessazione posizione pensionistica' THEN 'Cessazione Posizione Pensionistica'
            WHEN 'Chiusura Iscrizione Provvisoria' THEN 'Chiusura Iscrizione Provvisoria'
            WHEN 'Decesso' THEN 'Decesso'
            WHEN 'Revoca' THEN 'Revoca'
          END AS etichetta,
          COUNT(*) AS totale
        FROM base
        WHERE motivo_cessazione_iscrizione IN (
          'Altra motivazione Ente', 'Cambio situazione pensionistica', 'Cessazione posizione pensionistica',
          'Chiusura Iscrizione Provvisoria', 'Decesso', 'Revoca'
        )
        GROUP BY comprensorio, etichetta
      SQL
    end
  end
end
```

## Sezioni commentate

### Commento di classe

```ruby
# Conta le cessazioni (motivo_cessazione_iscrizione tra un elenco fisso di
# motivi rilevanti, altri valori come "Scadenza versamento diretto" esclusi)
# per motivo, a livello regionale e per comprensorio. Come
# TipologieDelegaBreakdown nessuna riconciliazione DISTINCT ON e' necessaria
# (ogni cessazione e' gia' un record additivo). A differenza sua pero' le
# percentuali non sono calcolate sul totale delle cessazioni stesse, ma sul
# totale deleghe del periodo: le cessazioni sono un sottoinsieme delle
# deleghe, non le esauriscono.
class CessazioniBreakdown
```

> **IT:** Il primo breakdown SPI il cui `Row` porta un campo aggiuntivo, `deleghe_totale`, rispetto al pattern minimo `zoning`/`totali`/`totale`/`percentuali`. La ragione è nel commento di classe: le cessazioni **non esauriscono** le deleghe del periodo (una delega può essere attiva, oppure cessata per uno dei motivi elencati, oppure — implicitamente — esclusa perché il suo `motivo_cessazione_iscrizione` non è tra quelli rilevanti, es. "Scadenza versamento diretto"), quindi mostrare "che percentuale di cessazioni è per Decesso" richiede di sapere anche quante deleghe totali c'erano nel periodo, non solo quante cessazioni.
>
> *EN: The first SPI breakdown whose `Row` carries an extra field, `deleghe_totale`, beyond the minimal `zoning`/`totali`/`totale`/`percentuali` pattern. The reason is in the class comment: cessazioni **don't exhaust** the period's delegations (a delegation can be active, or ended for one of the listed reasons, or — implicitly — excluded because its `motivo_cessazione_iscrizione` isn't among the relevant ones, e.g. "Scadenza versamento diretto"), so showing "what percentage of cessazioni is due to Decesso" requires also knowing how many delegations existed in total for the period, not just how many cessazioni there were.*

### `ETICHETTE` (costante)

```ruby
ETICHETTE = [
  "Altra Motivazione Ente", "Cambio Situazione Pensionistica", "Cessazione Posizione Pensionistica",
  "Chiusura Iscrizione Provvisoria", "Decesso", "Revoca"
].freeze
```

> **IT:** Sei motivi di cessazione, normalizzati esattamente come `TipologieDelegaBreakdown::ETICHETTE` — nomi "puliti" (Title Case) diversi dai valori grezzi visti in `sql`. A differenza di `TipologieDelegaBreakdown`, qui **non c'è un `Altro` di raccolta**: un `motivo_cessazione_iscrizione` che non compare in questa lista non viene affatto contato come cessazione (vedi `WHERE ... IN (...)` in `sql`) — non finisce in una categoria residuale, semplicemente non è considerato "una cessazione rilevante" ai fini di questa sezione.
>
> *EN: Six cessation reasons, normalized exactly like `TipologieDelegaBreakdown::ETICHETTE` — "clean" (Title Case) names different from the raw values seen in `sql`. Unlike `TipologieDelegaBreakdown`, there is **no catch-all "Altro"** here: a `motivo_cessazione_iscrizione` not present in this list isn't counted as a cessation at all (see `WHERE ... IN (...)` in `sql`) — it doesn't land in a residual category, it's simply not considered "a relevant cessation" for this section's purposes.*

### `Row`, `Result` (Struct)

```ruby
Row = Struct.new(:zoning, :totali, :totale, :deleghe_totale, :percentuali, keyword_init: true)
Result = Struct.new(:totale, :comprensori, keyword_init: true)
```

> **IT:** Il campo aggiuntivo `deleghe_totale` (rispetto a `TipologieDelegaBreakdown::Row`) è il numero totale di deleghe del periodo per quella riga (regione o singolo comprensorio) — usato dalla vista se serve mostrarlo esplicitamente, e soprattutto usato dentro `build_row` come denominatore delle percentuali. `ProvvisorieBreakdown::Row` ha lo stesso campo, per lo stesso motivo.
>
> *EN: The extra `deleghe_totale` field (compared to `TipologieDelegaBreakdown::Row`) is the period's total delegation count for that row (region or single comprensorio) — used by the view if it needs to display it explicitly, and above all used inside `build_row` as the percentage denominator. `ProvvisorieBreakdown::Row` has the same field, for the same reason.*

### `call`

```ruby
def call
  if @zoning.regionale?
    Result.new(totale: build_row(@zoning, merge_counts(counts_by_comprensorio.values), deleghe_by_comprensorio.values.sum),
      comprensori: province_zonings.map { |zoning| build_row(zoning, counts_by_comprensorio[zoning.codice_azzonamento],
        deleghe_by_comprensorio[zoning.codice_azzonamento]) })
  else
    Result.new(totale: build_row(@zoning, counts_by_comprensorio[@zoning.codice_azzonamento],
      deleghe_by_comprensorio[@zoning.codice_azzonamento]), comprensori: [])
  end
end
```

> **IT:** Stessa struttura `if @zoning.regionale?` degli altri breakdown, ma ogni chiamata a `build_row` ora passa **due** fonti dati invece di una: `counts_by_comprensorio` (le cessazioni) e `deleghe_by_comprensorio` (il denominatore). Per il totale regionale, entrambe vengono aggregate allo stesso modo — `merge_counts` per il primo, `.values.sum` per il secondo — mantenendo lo stesso principio "il totale è la somma dei comprensori" visto ovunque nella cartella.
>
> *EN: Same `if @zoning.regionale?` structure as the other breakdowns, but each `build_row` call now passes **two** data sources instead of one: `counts_by_comprensorio` (the cessazioni) and `deleghe_by_comprensorio` (the denominator). For the regional total, both are aggregated the same way — `merge_counts` for the first, `.values.sum` for the second — keeping the same "the total is the sum of the comprensori" principle seen everywhere in this folder.*

### `build_row` *(privato)*

```ruby
def build_row(zoning, counts, deleghe_totale)
  counts ||= {}
  deleghe_totale ||= 0
  totali = ETICHETTE.index_with { |etichetta| counts.fetch(etichetta, 0) }
  percentuali = totali.transform_values { |valore| deleghe_totale.zero? ? nil : (valore.to_f / deleghe_totale * 100) }

  Row.new(zoning:, totali:, totale: totali.values.sum, deleghe_totale:, percentuali:)
end
```

> **IT:** La differenza chiave rispetto a `TipologieDelegaBreakdown#build_row`: `percentuali` è calcolato dividendo per `deleghe_totale` (un parametro esterno, passato da `call`), non per `totale` (la somma locale delle sei etichette). Questo significa che le sei percentuali mostrate **non sommano al 100%** — sommano alla quota di deleghe del periodo che sono cessate per uno dei sei motivi elencati, che è quasi sempre una minoranza. `deleghe_totale ||= 0` protegge dalla divisione per zero nello stesso modo del resto del progetto (guardia esplicita `.zero?`, non un `rescue`).
>
> *EN: The key difference from `TipologieDelegaBreakdown#build_row`: `percentuali` is computed by dividing by `deleghe_totale` (an external parameter, passed in from `call`), not by `totale` (the local sum of the six labels). This means the six displayed percentages **don't add up to 100%** — they add up to the share of the period's delegations that ended for one of the six listed reasons, which is almost always a minority. `deleghe_totale ||= 0` guards against division by zero the same way as the rest of the project (explicit `.zero?` check, not a `rescue`).*

### `deleghe_by_comprensorio` *(privato)*

```ruby
def deleghe_by_comprensorio
  @deleghe_by_comprensorio ||= regional_scope.group("SUBSTRING(codice_azzonamento_completo FROM 1 FOR 2)").count
end
```

> **IT:** Non serve una CTE grezza qui, a differenza di `counts_by_comprensorio`: è un semplice `.group(...).count` di ActiveRecord sull'intero `regional_scope`, perché la domanda ("quante deleghe in totale, per comprensorio") non richiede nessuna trasformazione del dato — solo un raggruppamento su un'espressione SQL. Esattamente lo stesso metodo compare, identico, in `ProvvisorieBreakdown`.
>
> *EN: No raw CTE is needed here, unlike `counts_by_comprensorio`: it's a plain ActiveRecord `.group(...).count` over the entire `regional_scope`, because the question ("how many delegations in total, per comprensorio") requires no data transformation — just a grouping on an SQL expression. The exact same method appears, identically, in `ProvvisorieBreakdown`.*

### `sql` *(privato)*

```ruby
def sql
  <<~SQL
    WITH base AS (#{regional_scope.to_sql})
    SELECT
      SUBSTRING(codice_azzonamento_completo FROM 1 FOR 2) AS comprensorio,
      CASE motivo_cessazione_iscrizione
        WHEN 'Altra motivazione Ente' THEN 'Altra Motivazione Ente'
        WHEN 'Cambio situazione pensionistica' THEN 'Cambio Situazione Pensionistica'
        WHEN 'Cessazione posizione pensionistica' THEN 'Cessazione Posizione Pensionistica'
        WHEN 'Chiusura Iscrizione Provvisoria' THEN 'Chiusura Iscrizione Provvisoria'
        WHEN 'Decesso' THEN 'Decesso'
        WHEN 'Revoca' THEN 'Revoca'
      END AS etichetta,
      COUNT(*) AS totale
    FROM base
    WHERE motivo_cessazione_iscrizione IN (
      'Altra motivazione Ente', 'Cambio situazione pensionistica', 'Cessazione posizione pensionistica',
      'Chiusura Iscrizione Provvisoria', 'Decesso', 'Revoca'
    )
    GROUP BY comprensorio, etichetta
  SQL
end
```

> **IT:** Struttura identica a `TipologieDelegaBreakdown#sql` (una CTE, `CASE` statico, `GROUP BY`), con una differenza cruciale: il `CASE` **non ha un `ELSE`**, e c'è un `WHERE motivo_cessazione_iscrizione IN (...)` esplicito prima del `GROUP BY`. Senza quel `WHERE`, il `CASE` senza `ELSE` produrrebbe `etichetta = NULL` per ogni valore non elencato (es. "Scadenza versamento diretto"), e quei record finirebbero comunque raggruppati sotto una chiave `NULL` — il `WHERE` li esclude invece prima ancora che raggiungano il `CASE`, così `NULL` non compare mai come chiave nel risultato. Da notare anche la duplicazione dell'elenco dei sei motivi, una volta nel `CASE` (con la mappatura al nome normalizzato) e una volta nel `WHERE` (solo i valori grezzi, come filtro): cambiare l'elenco dei motivi rilevanti richiede di aggiornare **tre punti** in questo file — `ETICHETTE`, il `CASE`, e il `WHERE` — non uno solo.
>
> *EN: Structurally identical to `TipologieDelegaBreakdown#sql` (one CTE, static `CASE`, `GROUP BY`), with one crucial difference: the `CASE` has **no `ELSE`**, and there's an explicit `WHERE motivo_cessazione_iscrizione IN (...)` before the `GROUP BY`. Without that `WHERE`, the `ELSE`-less `CASE` would produce `etichetta = NULL` for every unlisted value (e.g. "Scadenza versamento diretto"), and those records would still end up grouped under a `NULL` key — the `WHERE` instead excludes them before they even reach the `CASE`, so `NULL` never appears as a key in the result. Also note the duplication of the six reasons: once in the `CASE` (mapped to the normalized name) and once in the `WHERE` (raw values only, as a filter): changing the list of relevant reasons requires updating **three places** in this file — `ETICHETTE`, the `CASE`, and the `WHERE` — not just one.*
