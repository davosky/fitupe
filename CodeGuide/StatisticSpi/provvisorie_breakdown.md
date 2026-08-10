# `StatisticSpi::ProvvisorieBreakdown`

**File:** `app/services/statistic_spi/provvisorie_breakdown.rb`

## Codice completo

```ruby
module StatisticSpi
  # Conta le pratiche provvisorie (colonna provvisoria = 'SI'), a livello
  # regionale e per comprensorio. Nessuna riconciliazione DISTINCT ON e'
  # necessaria (ogni provvisoria e' gia' un record additivo). Come
  # CessazioniBreakdown la percentuale e' calcolata sul totale deleghe del
  # periodo, non sul totale delle provvisorie stesse (sono un sottoinsieme
  # delle deleghe, non le esauriscono).
  class ProvvisorieBreakdown
    Row = Struct.new(:zoning, :totale, :deleghe_totale, :percentuale, keyword_init: true)
    Result = Struct.new(:totale, :comprensori, keyword_init: true)

    def self.call(...) = new(...).call

    def initialize(zoning:, anno:, mese:)
      @zoning = zoning
      @anno = anno
      @mese = mese
    end

    def call
      if @zoning.regionale?
        Result.new(totale: build_row(@zoning, counts_by_comprensorio.values.sum, deleghe_by_comprensorio.values.sum),
          comprensori: province_zonings.map { |zoning| build_row(zoning, counts_by_comprensorio[zoning.codice_azzonamento].to_i,
            deleghe_by_comprensorio[zoning.codice_azzonamento]) })
      else
        Result.new(totale: build_row(@zoning, counts_by_comprensorio[@zoning.codice_azzonamento].to_i,
          deleghe_by_comprensorio[@zoning.codice_azzonamento]), comprensori: [])
      end
    end

    private

    def build_row(zoning, totale, deleghe_totale)
      deleghe_totale ||= 0
      percentuale = deleghe_totale.zero? ? nil : (totale.to_f / deleghe_totale * 100)

      Row.new(zoning:, totale:, deleghe_totale:, percentuale:)
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
      @counts_by_comprensorio ||= regional_scope.where(provvisoria: "SI")
        .group("SUBSTRING(codice_azzonamento_completo FROM 1 FOR 2)").count
    end
  end
end
```

## Sezioni commentate

### Commento di classe

```ruby
# Conta le pratiche provvisorie (colonna provvisoria = 'SI'), a livello
# regionale e per comprensorio. Nessuna riconciliazione DISTINCT ON e'
# necessaria (ogni provvisoria e' gia' un record additivo). Come
# CessazioniBreakdown la percentuale e' calcolata sul totale deleghe del
# periodo, non sul totale delle provvisorie stesse (sono un sottoinsieme
# delle deleghe, non le esauriscono).
class ProvvisorieBreakdown
```

> **IT:** Il breakdown più semplice della cartella, e per questo il punto di partenza migliore per capire il pattern "un solo valore, percentuale su deleghe totali" (condiviso con `CessazioniBreakdown`, ma senza le più etichette e senza `CASE`). Conta una singola condizione booleana-di-fatto (`provvisoria = 'SI'`, colonna stringa, non un vero booleano), non una distribuzione su più categorie: non c'è `ETICHETTE`, non c'è hash `totali`/`percentuali`, solo un `totale` (intero) e una `percentuale` (float o `nil`).
>
> *EN: The simplest breakdown in the folder, and for that reason the best starting point for understanding the "single value, percentage of total delegations" pattern (shared with `CessazioniBreakdown`, but without the multiple labels and without a `CASE`). It counts a single de-facto boolean condition (`provvisoria = 'SI'`, a string column, not a real boolean), not a distribution across multiple categories: there's no `ETICHETTE`, no `totali`/`percentuali` hash, just a `totale` (integer) and a `percentuale` (float or `nil`).*

### `Row`, `Result` (Struct)

```ruby
Row = Struct.new(:zoning, :totale, :deleghe_totale, :percentuale, keyword_init: true)
Result = Struct.new(:totale, :comprensori, keyword_init: true)
```

> **IT:** `Row` è la versione "a valore singolo" di `CessazioniBreakdown::Row`: stessi due campi concettuali (`totale` + `deleghe_totale` come denominatore), ma senza plurale — `percentuale` (singolare, un float) al posto di `percentuali` (hash). `Result` è invece lo stesso identico Struct `totale`/`comprensori` di ogni altro breakdown della cartella.
>
> *EN: `Row` is the "single-value" version of `CessazioniBreakdown::Row`: the same two conceptual fields (`totale` + `deleghe_totale` as the denominator), but without the plural — `percentuale` (singular, a float) instead of `percentuali` (a hash). `Result` is instead the exact same `totale`/`comprensori` Struct as every other breakdown in the folder.*

### `call`

```ruby
def call
  if @zoning.regionale?
    Result.new(totale: build_row(@zoning, counts_by_comprensorio.values.sum, deleghe_by_comprensorio.values.sum),
      comprensori: province_zonings.map { |zoning| build_row(zoning, counts_by_comprensorio[zoning.codice_azzonamento].to_i,
        deleghe_by_comprensorio[zoning.codice_azzonamento]) })
  else
    Result.new(totale: build_row(@zoning, counts_by_comprensorio[@zoning.codice_azzonamento].to_i,
      deleghe_by_comprensorio[@zoning.codice_azzonamento]), comprensori: [])
  end
end
```

> **IT:** Stessa struttura `if @zoning.regionale?` di `CessazioniBreakdown#call`, ma con `counts_by_comprensorio.values.sum` al posto di `merge_counts(...)` per il totale regionale — equivalente in questo caso perché non c'è nulla da fondere per etichetta: `counts_by_comprensorio` è già un semplice hash `{ comprensorio => intero }` (da `.group(...).count` di ActiveRecord, vedi sotto), quindi sommarne i valori basta. Da notare `.to_i` esplicito su `counts_by_comprensorio[zoning.codice_azzonamento]` per i singoli comprensori: se un comprensorio non ha nessuna provvisoria, la chiave è assente dall'hash e l'accesso restituisce `nil`, che `.to_i` converte a `0` — un pattern diverso da `.fetch(chiave, 0)` usato altrove nella cartella per lo stesso scopo, ma con lo stesso effetto.
>
> *EN: Same `if @zoning.regionale?` structure as `CessazioniBreakdown#call`, but with `counts_by_comprensorio.values.sum` instead of `merge_counts(...)` for the regional total — equivalent here because there's nothing to merge per label: `counts_by_comprensorio` is already a plain `{ comprensorio => integer }` hash (from ActiveRecord's `.group(...).count`, see below), so summing its values is enough. Note the explicit `.to_i` on `counts_by_comprensorio[zoning.codice_azzonamento]` for individual comprensori: if a comprensorio has no provvisoria at all, the key is absent from the hash and the lookup returns `nil`, which `.to_i` converts to `0` — a different pattern from the `.fetch(key, 0)` used elsewhere in the folder for the same purpose, but with the same effect.*

### `build_row` *(privato)*

```ruby
def build_row(zoning, totale, deleghe_totale)
  deleghe_totale ||= 0
  percentuale = deleghe_totale.zero? ? nil : (totale.to_f / deleghe_totale * 100)

  Row.new(zoning:, totale:, deleghe_totale:, percentuale:)
end
```

> **IT:** La versione a valore singolo di `CessazioniBreakdown#build_row`: niente `ETICHETTE.index_with`, niente `.transform_values`, un solo calcolo di percentuale invece di sei. Stessa guardia sullo zero (`deleghe_totale.zero? ? nil : ...`), stesso principio: `percentuale` è la quota di deleghe del periodo che sono provvisorie, non una percentuale "interna" su un totale locale.
>
> *EN: The single-value version of `CessazioniBreakdown#build_row`: no `ETICHETTE.index_with`, no `.transform_values`, one percentage calculation instead of six. Same zero guard (`deleghe_totale.zero? ? nil : ...`), same principle: `percentuale` is the share of the period's delegations that are provisional, not an "internal" percentage over a local total.*

### `province_zonings`, `regional_zoning`, `regional_scope`, `deleghe_by_comprensorio` *(privati)*

> **IT:** Tutti e quattro identici, riga per riga, agli omonimi metodi di `CessazioniBreakdown` (`deleghe_by_comprensorio` incluso — stesso `.group(...).count` su `regional_scope`, nessuna CTE grezza). Vedi `CodeGuide/StatisticSpi/cessazioni_breakdown.md` per il dettaglio.
>
> *EN: All four identical, line for line, to the same-named methods in `CessazioniBreakdown` (`deleghe_by_comprensorio` included — same `.group(...).count` on `regional_scope`, no raw CTE). See `CodeGuide/StatisticSpi/cessazioni_breakdown.md` for the detail.*

### `counts_by_comprensorio` *(privato)*

```ruby
def counts_by_comprensorio
  @counts_by_comprensorio ||= regional_scope.where(provvisoria: "SI")
    .group("SUBSTRING(codice_azzonamento_completo FROM 1 FOR 2)").count
end
```

> **IT:** L'unico metodo davvero specifico di questa classe, ed è il più semplice di tutta la cartella `statistic_spi`: né una CTE grezza (come `AgeBreakdown`/`MultipleDelegationsBreakdown`/`TipologieDelegaBreakdown`/`CessazioniBreakdown`), né un `CASE`, solo `.where(provvisoria: "SI").group(...).count` puro ActiveRecord — perché il "raggruppamento" non è per una categoria calcolata, è un filtro booleano su un'unica condizione. `provvisoria: "SI"` (una stringa, non `true`) riflette il tipo di colonna così come arriva dall'importazione: nessuna conversione booleana è stata introdotta a livello di modello o migrazione.
>
> *EN: The one genuinely class-specific method, and the simplest in the entire `statistic_spi` folder: no raw CTE (like `AgeBreakdown`/`MultipleDelegationsBreakdown`/`TipologieDelegaBreakdown`/`CessazioniBreakdown`), no `CASE`, just plain ActiveRecord `.where(provvisoria: "SI").group(...).count` — because the "grouping" isn't over a computed category, it's a boolean filter on a single condition. `provvisoria: "SI"` (a string, not `true`) reflects the column type exactly as it arrives from the import: no boolean conversion was introduced at the model or migration level.*
