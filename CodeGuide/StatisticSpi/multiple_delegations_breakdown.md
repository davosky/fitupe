# `StatisticSpi::MultipleDelegationsBreakdown`

**File:** `app/services/statistic_spi/multiple_delegations_breakdown.rb`

## Codice completo

```ruby
module StatisticSpi
  # Raggruppa i codice_fiscale con piu' di una delega (2-5, reversibilita'/
  # invalidita', vedi .ai/Spi/pensionati.md) per numero di occorrenze,
  # riconciliate per comprensorio con la stessa tecnica DISTINCT ON di
  # ReconciledIscrittiByComprensorio: ogni codice_fiscale viene assegnato a UN
  # SOLO comprensorio "primario" (il primo alfabeticamente tra quelli in cui
  # compare), calcolato pero' sulle occorrenze TOTALI sull'intera regione
  # (non solo dentro il comprensorio), cosi' la somma dei comprensori torna
  # sempre esattamente uguale al totale regionale.
  class MultipleDelegationsBreakdown
    OCCORRENZE = (2..5)

    Row = Struct.new(:zoning, :doppia, :tripla, :quadrupla, :quintupla, :totale, keyword_init: true)
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
      doppia, tripla, quadrupla, quintupla = OCCORRENZE.map { |n| counts.fetch(n, 0) }

      Row.new(zoning:, doppia:, tripla:, quadrupla:, quintupla:, totale: doppia + tripla + quadrupla + quintupla)
    end

    def merge_counts(counts_list)
      counts_list.compact.each_with_object(Hash.new(0)) do |counts, merged|
        counts.each { |numero, valore| merged[numero] += valore }
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
        (counts[row["comprensorio"]] ||= {})[row["numero_deleghe"].to_i] = row["numero_di_codici"].to_i
      end
    end

    def sql
      <<~SQL
        WITH base AS (#{regional_scope.to_sql}),
        occorrenze AS (
          SELECT codice_fiscale, COUNT(*) AS numero_deleghe
          FROM base
          GROUP BY codice_fiscale
        ),
        comprensorio_primario AS (
          SELECT DISTINCT ON (codice_fiscale)
            codice_fiscale,
            SUBSTRING(codice_azzonamento_completo FROM 1 FOR 2) AS comprensorio
          FROM base
          ORDER BY codice_fiscale, codice_azzonamento_completo
        )
        SELECT
          COALESCE(cp.comprensorio, 'N/D') AS comprensorio,
          o.numero_deleghe,
          COUNT(*) AS numero_di_codici
        FROM occorrenze o
        LEFT JOIN comprensorio_primario cp ON cp.codice_fiscale = o.codice_fiscale
        WHERE o.numero_deleghe BETWEEN #{OCCORRENZE.min} AND #{OCCORRENZE.max}
        GROUP BY comprensorio, o.numero_deleghe
      SQL
    end
  end
end
```

## Sezioni commentate

### Commento di classe

```ruby
# Raggruppa i codice_fiscale con piu' di una delega (2-5, reversibilita'/
# invalidita', vedi .ai/Spi/pensionati.md) per numero di occorrenze,
# riconciliate per comprensorio con la stessa tecnica DISTINCT ON di
# ReconciledIscrittiByComprensorio: ogni codice_fiscale viene assegnato a UN
# SOLO comprensorio "primario" (il primo alfabeticamente tra quelli in cui
# compare), calcolato pero' sulle occorrenze TOTALI sull'intera regione
# (non solo dentro il comprensorio), cosi' la somma dei comprensori torna
# sempre esattamente uguale al totale regionale.
class MultipleDelegationsBreakdown
```

> **IT:** Questa è, in un certo senso, la sezione "sorgente" di tutto il problema che `ReconciledIscrittiByComprensorio` e `AgeBreakdown` risolvono: è quella che mostra direttamente quante persone hanno 2, 3, 4 o 5 deleghe (vedi `.ai/Spi/pensionati.md` per i casi reali — reversibilità, invalidità, o entrambe insieme). Il punto sottile, esplicitato nel commento di classe, è che il "comprensorio primario" qui è calcolato sul **numero totale di deleghe della persona nell'intera regione**, non sul numero di deleghe dentro il singolo comprensorio: una persona con 3 deleghe, di cui 2 nel comprensorio A e 1 nel comprensorio B, va contata come "tripla" **una sola volta**, nel comprensorio primario (che potrebbe essere A o B a seconda dell'ordine alfabetico), non split in "doppia in A" + "singola in B".
>
> *EN: This is, in a sense, the "source" section for the whole problem that `ReconciledIscrittiByComprensorio` and `AgeBreakdown` solve: it's the one that directly shows how many people have 2, 3, 4, or 5 delegations (see `.ai/Spi/pensionati.md` for the real-world cases — survivor's pension, disability, or both combined). The subtle point, made explicit in the class comment, is that the "primary comprensorio" here is computed from the **person's total delegation count across the whole region**, not the delegation count within a single comprensorio: a person with 3 delegations, 2 in comprensorio A and 1 in comprensorio B, must be counted as "tripla" **exactly once**, under their primary comprensorio (which could be A or B depending on alphabetical order), not split into "doppia in A" + "singola in B".*

### `OCCORRENZE` (costante)

```ruby
OCCORRENZE = (2..5)
```

> **IT:** Un `Range`, non un array — usato sia per generare le quattro colonne fisse (`doppia`, `tripla`, `quadrupla`, `quintupla`) in `build_row`, sia per filtrare la query SQL (`BETWEEN #{OCCORRENZE.min} AND #{OCCORRENZE.max}`). Il minimo è 2 (di proposito: chi ha una sola delega non è una "delega multipla" e non compare in questa sezione), il massimo è 5 perché, nella pratica, nessun caso reale supera le 5 deleghe per persona (vedi i casi combinatori in `.ai/Spi/pensionati.md`) — un limite empirico, non teorico, che andrebbe rivisto se un giorno comparissero dati con più di 5 occorrenze.
>
> *EN: A `Range`, not an array — used both to generate the four fixed columns (`doppia`, `tripla`, `quadrupla`, `quintupla`) in `build_row`, and to filter the SQL query (`BETWEEN #{OCCORRENZE.min} AND #{OCCORRENZE.max}`). The minimum is 2 (deliberately: someone with a single delegation isn't a "multiple delegation" and doesn't appear in this section), the maximum is 5 because, in practice, no real case exceeds 5 delegations per person (see the combined cases in `.ai/Spi/pensionati.md`) — an empirical limit, not a theoretical one, that would need revisiting if data with more than 5 occurrences ever showed up.*

### `Row`, `Result` (Struct)

```ruby
Row = Struct.new(:zoning, :doppia, :tripla, :quadrupla, :quintupla, :totale, keyword_init: true)
Result = Struct.new(:totale, :comprensori, keyword_init: true)
```

> **IT:** A differenza degli altri breakdown SPI (che usano un hash generico `totali`/`percentuali`), qui i quattro casi hanno **campi nominati espliciti** (`doppia`, `tripla`, `quadrupla`, `quintupla`) invece di un hash `{ 2 => n, 3 => n, ... }`. Scelta di leggibilità nella vista (`row.tripla` invece di `row.totali[3]`), possibile perché il numero di casi è fisso e piccolo — a differenza di `AgeBreakdown` (nove fasce) o `TipologieDelegaBreakdown` (cinque etichette), dove un hash è più pratico. Nessun campo `percentuali`: questa sezione mostra solo conteggi assoluti, non percentuali sul totale deleghe.
>
> *EN: Unlike the other SPI breakdowns (which use a generic `totali`/`percentuali` hash), the four cases here have **explicit named fields** (`doppia`, `tripla`, `quadrupla`, `quintupla`) instead of a `{ 2 => n, 3 => n, ... }` hash. A readability choice for the view (`row.tripla` instead of `row.totali[3]`), possible because the number of cases is fixed and small — unlike `AgeBreakdown` (nine bands) or `TipologieDelegaBreakdown` (five labels), where a hash is more practical. No `percentuali` field: this section shows only absolute counts, no percentages of the delegation total.*

### `call`, `build_row`, `merge_counts`, `province_zonings`, `regional_zoning`, `regional_scope`

> **IT:** Tutti e sei identici, struttura per struttura (a parte i nomi dei campi), a `AgeBreakdown` — vedi `CodeGuide/StatisticSpi/age_breakdown.md` per il commento dettagliato di `call` (il ramo regionale/comprensorio con `merge_counts` come somma, non query separata) e dei tre metodi di risoluzione dello scope. L'unica variazione reale è dentro `build_row`, descritta di seguito.
>
> *EN: All six identical, structure for structure (aside from field names), to `AgeBreakdown` — see `CodeGuide/StatisticSpi/age_breakdown.md` for the detailed commentary on `call` (the regional/comprensorio branch with `merge_counts` as a sum, not a separate query) and the three scope-resolution methods. The only real variation is inside `build_row`, described below.*

```ruby
def build_row(zoning, counts)
  counts ||= {}
  doppia, tripla, quadrupla, quintupla = OCCORRENZE.map { |n| counts.fetch(n, 0) }

  Row.new(zoning:, doppia:, tripla:, quadrupla:, quintupla:, totale: doppia + tripla + quadrupla + quintupla)
end
```

> **IT:** `OCCORRENZE.map { |n| counts.fetch(n, 0) }` scompatta i quattro valori nell'ordine di `OCCORRENZE` (2, 3, 4, 5) direttamente nelle quattro variabili locali via destructuring — una riga che dipende dal fatto che `OCCORRENZE` abbia esattamente quattro elementi e che l'ordine dei nomi (`doppia, tripla, quadrupla, quintupla`) corrisponda all'ordine numerico crescente. Se `OCCORRENZE` cambiasse ampiezza (es. `2..6`), questa riga andrebbe aggiornata insieme allo `Struct Row`, non è generica come `BANDS.to_h` in `AgeBreakdown`.
>
> *EN: `OCCORRENZE.map { |n| counts.fetch(n, 0) }` unpacks the four values in `OCCORRENZE`'s order (2, 3, 4, 5) directly into the four local variables via destructuring — a line that depends on `OCCORRENZE` having exactly four elements and the name order (`doppia, tripla, quadrupla, quintupla`) matching increasing numeric order. If `OCCORRENZE` ever changed size (e.g. `2..6`), this line would need updating together with the `Row` struct — it isn't generic like `BANDS.to_h` in `AgeBreakdown`.*

### `counts_by_comprensorio` *(privato)*

```ruby
def counts_by_comprensorio
  @counts_by_comprensorio ||= ActiveRecord::Base.connection.select_all(sql).each_with_object({}) do |row, counts|
    (counts[row["comprensorio"]] ||= {})[row["numero_deleghe"].to_i] = row["numero_di_codici"].to_i
  end
end
```

> **IT:** Stessa forma di `AgeBreakdown#counts_by_comprensorio`, hash annidato `{ comprensorio => { numero_deleghe => numero_di_codici } }`. La chiave interna qui è un intero (`numero_deleghe`, 2-5), non una stringa come `fascia` in `AgeBreakdown`.
>
> *EN: Same shape as `AgeBreakdown#counts_by_comprensorio`, a nested hash `{ comprensorio => { numero_deleghe => numero_di_codici } }`. The inner key here is an integer (`numero_deleghe`, 2-5), not a string like `fascia` in `AgeBreakdown`.*

### `sql` *(privato)*

```ruby
def sql
  <<~SQL
    WITH base AS (#{regional_scope.to_sql}),
    occorrenze AS (
      SELECT codice_fiscale, COUNT(*) AS numero_deleghe
      FROM base
      GROUP BY codice_fiscale
    ),
    comprensorio_primario AS (
      SELECT DISTINCT ON (codice_fiscale)
        codice_fiscale,
        SUBSTRING(codice_azzonamento_completo FROM 1 FOR 2) AS comprensorio
      FROM base
      ORDER BY codice_fiscale, codice_azzonamento_completo
    )
    SELECT
      COALESCE(cp.comprensorio, 'N/D') AS comprensorio,
      o.numero_deleghe,
      COUNT(*) AS numero_di_codici
    FROM occorrenze o
    LEFT JOIN comprensorio_primario cp ON cp.codice_fiscale = o.codice_fiscale
    WHERE o.numero_deleghe BETWEEN #{OCCORRENZE.min} AND #{OCCORRENZE.max}
    GROUP BY comprensorio, o.numero_deleghe
  SQL
end
```

> **IT:** La query più elaborata della cartella, con **tre** CTE invece di una o due:
>
> 1. `occorrenze` conta, per ogni `codice_fiscale`, quante righe (deleghe) ha in tutta la regione — questo è il conteggio "globale" richiamato nel commento di classe, calcolato **prima** di qualunque considerazione sul comprensorio.
> 2. `comprensorio_primario` è la stessa `DISTINCT ON (codice_fiscale)` vista in `ReconciledIscrittiByComprensorio` e `AgeBreakdown`, indipendente da `occorrenze`.
> 3. Il `SELECT` finale fa un `LEFT JOIN` (non `INNER JOIN`) tra le due, con `COALESCE(cp.comprensorio, 'N/D')` come rete di sicurezza — teoricamente ogni `codice_fiscale` in `occorrenze` ha sempre una riga corrispondente in `comprensorio_primario` (stessa CTE `base`), quindi il `LEFT JOIN` non dovrebbe mai produrre `NULL`, ma la scelta difensiva evita che un futuro edge case (es. un record con `codice_azzonamento_completo` nullo, escluso da `SUBSTRING`) faccia sparire silenziosamente quella persona dal conteggio invece di finire visibilmente sotto "N/D".
>
> Il filtro `WHERE o.numero_deleghe BETWEEN #{OCCORRENZE.min} AND #{OCCORRENZE.max}` è interpolato direttamente nella stringa SQL (non un bind parameter `?`), ma `OCCORRENZE.min`/`.max` sono interi Ruby derivati da una costante hardcoded (`2` e `5`), non input utente — stesso ragionamento di sicurezza fatto per `BANDS` in `AgeBreakdown`.
>
> *EN: The most elaborate query in the folder, with **three** CTEs instead of one or two:
>
> 1. `occorrenze` counts, for each `codice_fiscale`, how many rows (delegations) it has across the whole region — this is the "global" count referenced in the class comment, computed **before** any consideration of comprensorio.
> 2. `comprensorio_primario` is the same `DISTINCT ON (codice_fiscale)` seen in `ReconciledIscrittiByComprensorio` and `AgeBreakdown`, independent of `occorrenze`.
> 3. The final `SELECT` does a `LEFT JOIN` (not `INNER JOIN`) between the two, with `COALESCE(cp.comprensorio, 'N/D')` as a safety net — in theory every `codice_fiscale` in `occorrenze` always has a matching row in `comprensorio_primario` (same `base` CTE), so the `LEFT JOIN` should never produce `NULL`, but the defensive choice prevents a future edge case (e.g. a record with a null `codice_azzonamento_completo`, excluded by `SUBSTRING`) from silently dropping that person from the count instead of visibly landing under "N/D".
>
> The `WHERE o.numero_deleghe BETWEEN #{OCCORRENZE.min} AND #{OCCORRENZE.max}` filter is interpolated directly into the SQL string (not a `?` bind parameter), but `OCCORRENZE.min`/`.max` are Ruby integers derived from a hardcoded constant (`2` and `5`), not user input — the same security reasoning made for `BANDS` in `AgeBreakdown`.*
