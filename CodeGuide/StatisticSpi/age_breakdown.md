# `StatisticSpi::AgeBreakdown`

**File:** `app/services/statistic_spi/age_breakdown.rb`

## Codice completo

```ruby
module StatisticSpi
  # Distribuzione degli iscritti per fascia d'eta (classi per decine, es.
  # CINQUANTENNI/SESSANTENNI), a livello regionale e per comprensorio. Riusa
  # direttamente le fasce di Statistics::AgeBreakdown (generiche, non
  # specifiche degli Attivi) ma conta codice_fiscale distinti riconciliati per
  # comprensorio, come ReconciledIscrittiByComprensorio: un pensionato con piu'
  # deleghe in comprensori diversi non deve essere contato piu' volte.
  class AgeBreakdown
    BANDS = Statistics::AgeBreakdown::BANDS
    AGE_EXPR = Statistics::AgeBreakdown::AGE_EXPR

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
      totali = BANDS.to_h { |fascia, _upper| [ fascia, counts.fetch(fascia, 0) ] }
      totale = totali.values.sum
      percentuali = totali.transform_values { |valore| totale.zero? ? nil : (valore.to_f / totale * 100) }

      Row.new(zoning:, totali:, totale:, percentuali:)
    end

    def merge_counts(counts_list)
      counts_list.compact.each_with_object(Hash.new(0)) do |counts, merged|
        counts.each { |fascia, valore| merged[fascia] += valore }
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
        (counts[row["comprensorio"]] ||= {})[row["fascia"]] = row["totale"].to_i
      end
    end

    def sql
      <<~SQL
        WITH base AS (#{regional_scope.to_sql}),
        persona AS (
          SELECT DISTINCT ON (codice_fiscale)
            codice_fiscale, data_nascita,
            SUBSTRING(codice_azzonamento_completo FROM 1 FOR 2) AS comprensorio
          FROM base
          ORDER BY codice_fiscale, codice_azzonamento_completo
        )
        SELECT comprensorio, #{band_case_sql} AS fascia, COUNT(*) AS totale
        FROM persona
        WHERE data_nascita IS NOT NULL
        GROUP BY comprensorio, fascia
      SQL
    end

    def band_case_sql
      whens = BANDS.filter_map { |fascia, upper| "WHEN #{AGE_EXPR} < #{upper} THEN '#{fascia}'" if upper }
      "CASE #{whens.join(' ')} ELSE 'HIGHLANDERS' END"
    end
  end
end
```

## Sezioni commentate

### Commento di classe

```ruby
# Distribuzione degli iscritti per fascia d'eta (classi per decine, es.
# CINQUANTENNI/SESSANTENNI), a livello regionale e per comprensorio. Riusa
# direttamente le fasce di Statistics::AgeBreakdown (generiche, non
# specifiche degli Attivi) ma conta codice_fiscale distinti riconciliati per
# comprensorio, come ReconciledIscrittiByComprensorio: un pensionato con piu'
# deleghe in comprensori diversi non deve essere contato piu' volte.
class AgeBreakdown
```

> **IT:** Il caso più complesso della cartella `statistic_spi`, perché unisce tre esigenze che altrove sono separate: (1) le fasce d'età di `Statistics::AgeBreakdown`, (2) lo split regionale/comprensori comune a tutti i breakdown SPI, (3) la riconciliazione per persona di `ReconciledIscrittiByComprensorio`. Non conta deleghe (a differenza di `TipologieDelegaBreakdown`/`CessazioniBreakdown`/`ProvvisorieBreakdown`): conta **iscritti**, quindi eredita lo stesso problema di sovraconteggio descritto in `CodeGuide/StatisticSpi/reconciled_iscritti_by_comprensorio.md` e lo risolve con la propria CTE `persona`, invece di chiamare `ReconciledIscrittiByComprensorio` come classe separata — perché qui serve anche `data_nascita` nella stessa riga riconciliata, non solo il comprensorio.
>
> *EN: The most complex case in the `statistic_spi` folder, because it combines three needs that are kept separate elsewhere: (1) the age bands from `Statistics::AgeBreakdown`, (2) the regional/comprensori split common to every SPI breakdown, (3) the per-person reconciliation from `ReconciledIscrittiByComprensorio`. It doesn't count delegations (unlike `TipologieDelegaBreakdown`/`CessazioniBreakdown`/`ProvvisorieBreakdown`): it counts **members**, so it inherits the same over-counting problem described in `CodeGuide/StatisticSpi/reconciled_iscritti_by_comprensorio.md` and solves it with its own `persona` CTE, instead of calling `ReconciledIscrittiByComprensorio` as a separate class — because here `data_nascita` is also needed in the same reconciled row, not just the comprensorio.*

### `BANDS`, `AGE_EXPR` (costanti)

```ruby
BANDS = Statistics::AgeBreakdown::BANDS
AGE_EXPR = Statistics::AgeBreakdown::AGE_EXPR
```

> **IT:** Invece di ridefinire le nove fasce d'età (vedi `CodeGuide/Statistics/age_breakdown.md` per il dettaglio: GIOVANI < 30, TRENTENNI 30-39, ..., HIGHLANDERS ≥ 100) e l'espressione SQL `AGE(data_nascita)`, questa classe le importa direttamente dalla classe Attivi. È l'unico punto di accoppiamento diretto tra `StatisticSpi` e `Statistics` in tutta la sezione SPI — deliberato, perché "cos'è un cinquantenne" non dipende dal fatto che l'iscritto sia Attivo o Pensionato, è la stessa identica definizione. Se in futuro le fasce cambiassero per gli Attivi, cambierebbero automaticamente anche qui: un vantaggio finché resta vero che la definizione deve restare identica tra le due categorie, un rischio nascosto se un giorno smettesse di esserlo.
>
> *EN: Instead of redefining the nine age bands (see `CodeGuide/Statistics/age_breakdown.md` for the detail: GIOVANI < 30, TRENTENNI 30-39, ..., HIGHLANDERS ≥ 100) and the `AGE(data_nascita)` SQL expression, this class imports them directly from the Attivi class. It's the only point of direct coupling between `StatisticSpi` and `Statistics` in the whole SPI section — deliberate, because "what counts as fifty-something" doesn't depend on whether the member is Attivo or Pensionato, it's the exact same definition. If the bands ever changed for Attivi, they'd automatically change here too: a benefit as long as it stays true that the definition must remain identical across both categories, a hidden risk if that ever stops being the case.*

### `Row`, `Result` (Struct)

```ruby
Row = Struct.new(:zoning, :totali, :totale, :percentuali, keyword_init: true)
Result = Struct.new(:totale, :comprensori, keyword_init: true)
```

> **IT:** Stessa forma `Row`/`Result` di ogni altro breakdown SPI a distribuzione singola (`TipologieDelegaBreakdown`, e con un campo in più `CessazioniBreakdown`): `totali` è un hash `{ fascia => count }`, `percentuali` un hash parallelo `{ fascia => percentuale }`. `Result` separa sempre `totale` (una `Row` per l'intera regione o per l'azzonamento non-regionale scelto) da `comprensori` (un array di `Row`, una per provincia, vuoto se l'azzonamento scelto non è regionale).
>
> *EN: The same `Row`/`Result` shape as every other single-distribution SPI breakdown (`TipologieDelegaBreakdown`, and `CessazioniBreakdown` with one extra field): `totali` is a `{ fascia => count }` hash, `percentuali` a parallel `{ fascia => percentage }` hash. `Result` always separates `totale` (one `Row` for the whole region or for the chosen non-regional zoning) from `comprensori` (an array of `Row`s, one per province, empty if the chosen zoning isn't regional).*

### `call`

```ruby
def call
  if @zoning.regionale?
    Result.new(totale: build_row(@zoning, merge_counts(counts_by_comprensorio.values)),
      comprensori: province_zonings.map { |zoning| build_row(zoning, counts_by_comprensorio[zoning.codice_azzonamento]) })
  else
    Result.new(totale: build_row(@zoning, counts_by_comprensorio[@zoning.codice_azzonamento]), comprensori: [])
  end
end
```

> **IT:** Il ramo `if @zoning.regionale?` è identico, struttura per struttura, in tutti i breakdown SPI a distribuzione singola (`TipologieDelegaBreakdown`, `MultipleDelegationsBreakdown`): quando l'azzonamento scelto è regionale, il totale si ottiene **sommando** i conteggi di tutti i comprensori (`merge_counts(counts_by_comprensorio.values)`), non con una query separata sull'intera regione — un modo implicito per garantire che regionale = somma dei comprensori, per costruzione, invece di rischiare un disallineamento tra due query indipendenti. Quando l'azzonamento scelto è già un singolo comprensorio, non ha senso mostrare la sezione "Comprensori" (sarebbe una lista con un solo elemento uguale al totale), quindi resta `[]`.
>
> *EN: The `if @zoning.regionale?` branch is structurally identical across every single-distribution SPI breakdown (`TipologieDelegaBreakdown`, `MultipleDelegationsBreakdown`): when the chosen zoning is regional, the total is obtained by **summing** every comprensorio's counts (`merge_counts(counts_by_comprensorio.values)`), not via a separate region-wide query — an implicit way to guarantee that regional = sum of comprensori, by construction, instead of risking a mismatch between two independent queries. When the chosen zoning is already a single comprensorio, showing a "Comprensori" section wouldn't make sense (it'd be a one-item list equal to the total), so it stays `[]`.*

### `build_row`, `merge_counts` *(privati)*

```ruby
def build_row(zoning, counts)
  counts ||= {}
  totali = BANDS.to_h { |fascia, _upper| [ fascia, counts.fetch(fascia, 0) ] }
  totale = totali.values.sum
  percentuali = totali.transform_values { |valore| totale.zero? ? nil : (valore.to_f / totale * 100) }

  Row.new(zoning:, totali:, totale:, percentuali:)
end

def merge_counts(counts_list)
  counts_list.compact.each_with_object(Hash.new(0)) do |counts, merged|
    counts.each { |fascia, valore| merged[fascia] += valore }
  end
end
```

> **IT:** `build_row` itera su `BANDS` (non su `counts.keys`), esattamente come `Statistics::AgeBreakdown#call`: tutte e nove le fasce compaiono sempre, anche a zero. A differenza della versione Attivi, qui il denominatore delle percentuali è `totale` — cioè la somma delle sole nove fasce mostrate per quella riga — non uno `scope.count` calcolato separatamente: per costruzione (persone con `data_nascita` valorizzata, filtrate nella CTE SQL) qui i due valori coincidono comunque, ma concettualmente è un calcolo diverso da quello della versione Attivi. `merge_counts` somma i conteggi di più comprensori fascia per fascia, usando `Hash.new(0)` come accumulatore per evitare controlli espliciti di esistenza della chiave.
>
> *EN: `build_row` iterates over `BANDS` (not over `counts.keys`), exactly like `Statistics::AgeBreakdown#call`: all nine bands always appear, even at zero. Unlike the Attivi version, the percentage denominator here is `totale` — the sum of just the nine bands shown for that row — not a separately-computed `scope.count`: by construction (people with `data_nascita` set, filtered in the SQL CTE) the two values happen to coincide here anyway, but conceptually it's a different computation from the Attivi version. `merge_counts` sums multiple comprensori's counts band by band, using `Hash.new(0)` as the accumulator to avoid explicit key-existence checks.*

### `province_zonings`, `regional_zoning`, `regional_scope` *(privati)*

```ruby
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
```

> **IT:** Questi tre metodi si ripetono, identici, in ogni breakdown della cartella `statistic_spi` (eccetto `ReconciledIscrittiByComprensorio` e `ZoningPeriodScope` stessa). `regional_zoning` risolve sempre l'azzonamento regionale padre, **anche quando `@zoning` è già regionale** (in quel caso restituisce sé stesso): questo garantisce che `regional_scope` interroghi sempre l'intera regione, da cui poi `counts_by_comprensorio` estrae sia il totale (sommando) sia le righe per singolo comprensorio (filtrando l'hash). Vedi `CodeGuide/StatisticSpi/zoning_period_scope.md`, sezione finale, per il perché di questa scelta rispetto alla versione Attivi.
>
> *EN: These three methods repeat, identically, across every breakdown in the `statistic_spi` folder (except `ReconciledIscrittiByComprensorio` and `ZoningPeriodScope` itself). `regional_zoning` always resolves the parent regional zoning, **even when `@zoning` is already regional** (in that case it returns itself): this guarantees `regional_scope` always queries the whole region, from which `counts_by_comprensorio` then derives both the total (by summing) and the per-comprensorio rows (by filtering the hash). See `CodeGuide/StatisticSpi/zoning_period_scope.md`'s final section for why this differs from the Attivi version.*

### `counts_by_comprensorio` *(privato)*

```ruby
def counts_by_comprensorio
  @counts_by_comprensorio ||= ActiveRecord::Base.connection.select_all(sql).each_with_object({}) do |row, counts|
    (counts[row["comprensorio"]] ||= {})[row["fascia"]] = row["totale"].to_i
  end
end
```

> **IT:** Costruisce un hash annidato `{ comprensorio => { fascia => count } }` a partire dalle righe piatte restituite da `sql`. La memoizzazione (`||=`) è importante qui più che altrove: la query esegue una `DISTINCT ON` su tutta la regione, quindi è relativamente costosa, e sia il ramo `totale` sia il ramo `comprensori` di `call` la interrogano — senza memoizzazione verrebbe eseguita due volte per ogni richiesta quando l'azzonamento è regionale.
>
> *EN: Builds a nested hash `{ comprensorio => { fascia => count } }` from the flat rows returned by `sql`. Memoization (`||=`) matters more here than elsewhere: the query runs a region-wide `DISTINCT ON`, so it's relatively expensive, and both the `totale` and `comprensori` branches of `call` query it — without memoization it would run twice per request whenever the zoning is regional.*

### `sql` *(privato)*

```ruby
def sql
  <<~SQL
    WITH base AS (#{regional_scope.to_sql}),
    persona AS (
      SELECT DISTINCT ON (codice_fiscale)
        codice_fiscale, data_nascita,
        SUBSTRING(codice_azzonamento_completo FROM 1 FOR 2) AS comprensorio
      FROM base
      ORDER BY codice_fiscale, codice_azzonamento_completo
    )
    SELECT comprensorio, #{band_case_sql} AS fascia, COUNT(*) AS totale
    FROM persona
    WHERE data_nascita IS NOT NULL
    GROUP BY comprensorio, fascia
  SQL
end
```

> **IT:** Combina in un'unica query i due meccanismi documentati altrove: la riconciliazione `DISTINCT ON (codice_fiscale)` di `ReconciledIscrittiByComprensorio` (CTE `persona`: una sola riga per persona, assegnata al comprensorio "primario") e il calcolo della fascia d'età in SQL di `Statistics::AgeBreakdown` (`band_case_sql`, applicato *dopo* la riconciliazione, sulla CTE `persona` già deduplicata — non su `base`, altrimenti la stessa persona con più deleghe verrebbe contata più volte anche nella fascia d'età). L'ordine delle operazioni è quindi: prima una riga per persona con il suo comprensorio primario, **poi** il calcolo della fascia su quella riga unica. `WHERE data_nascita IS NOT NULL` esclude chi non ha data di nascita valorizzata dal conteggio delle fasce, ma quelle persone restano comunque nella CTE `persona` — non nel `SELECT` finale, però, quindi semplicemente non compaiono in nessuna fascia (coerente con `Statistics::AgeBreakdown`, dove lo stesso filtro esiste per lo stesso motivo).
>
> *EN: Combines two mechanisms documented elsewhere into a single query: the `DISTINCT ON (codice_fiscale)` reconciliation from `ReconciledIscrittiByComprensorio` (the `persona` CTE: one row per person, assigned to their "primary" comprensorio) and the in-SQL age-band computation from `Statistics::AgeBreakdown` (`band_case_sql`, applied *after* reconciliation, on the already-deduplicated `persona` CTE — not on `base`, otherwise the same person with multiple delegations would be counted multiple times in the age band too). The order of operations is therefore: first one row per person with their primary comprensorio, **then** the band computation on that single row. `WHERE data_nascita IS NOT NULL` excludes people with no birth date from the band count, but those people still exist in the `persona` CTE — just not in the final `SELECT`, so they simply don't appear in any band (consistent with `Statistics::AgeBreakdown`, where the same filter exists for the same reason).*

### `band_case_sql` *(privato)*

```ruby
def band_case_sql
  whens = BANDS.filter_map { |fascia, upper| "WHEN #{AGE_EXPR} < #{upper} THEN '#{fascia}'" if upper }
  "CASE #{whens.join(' ')} ELSE 'HIGHLANDERS' END"
end
```

> **IT:** Identico, riga per riga, a `Statistics::AgeBreakdown#band_case_sql` — stessa nota di sicurezza: `BANDS` è una costante hardcoded (per di più importata da `Statistics::AgeBreakdown`, non costruita qui), quindi nessun input utente entra nella stringa SQL nonostante l'interpolazione, e nessun rischio di SQL injection nonostante l'uso implicito di SQL grezzo nella CTE.
>
> *EN: Identical, line for line, to `Statistics::AgeBreakdown#band_case_sql` — same security note: `BANDS` is a hardcoded constant (imported from `Statistics::AgeBreakdown`, not even built here), so no user input ever reaches the SQL string despite the interpolation, and there's no SQL injection risk despite the raw SQL used implicitly in the CTE.*
