# `Statistics::WorkStatusBreakdown`

**File:** `app/services/statistics/work_status_breakdown.rb`

## Codice completo

```ruby
module Statistics
  # Distribuzione degli iscritti per status lavorativo (valori dinamici dal
  # campo tipologia_status, es. Dipendente, Pensionato, ...) nell'anno
  # corrente, in ordine alfabetico, senza confronto con l'anno precedente.
  # La percentuale è calcolata sul totale iscritti dello stesso
  # azzonamento/anno/mese. Riusa lo stesso fallback sull'azzonamento
  # superiore di ZoningPeriodScope.
  class WorkStatusBreakdown
    Row = Struct.new(:tipologia_status, :count, :percentuale, keyword_init: true)

    def self.call(...) = new(...).call

    def initialize(zoning:, anno:, mese:)
      @zoning = zoning
      @anno = anno
      @mese = mese
    end

    def call
      counts.sort.map { |tipologia_status, count| build_row(tipologia_status, count) }
    end

    private

    def build_row(tipologia_status, count)
      percentuale = totale.zero? ? nil : (count.to_f / totale * 100)

      Row.new(tipologia_status:, count:, percentuale:)
    end

    def counts
      @counts ||= scope.where.not(tipologia_status: nil).group(:tipologia_status).count
    end

    def totale
      @totale ||= scope.count
    end

    def scope
      @scope ||= ZoningPeriodScope.call(zoning: @zoning, anno: @anno, mese: @mese)
    end
  end
end
```

## Sezioni commentate

### Commento di classe

```ruby
# Distribuzione degli iscritti per status lavorativo (valori dinamici dal
# campo tipologia_status, es. Dipendente, Pensionato, ...) nell'anno
# corrente, in ordine alfabetico, senza confronto con l'anno precedente.
# La percentuale è calcolata sul totale iscritti dello stesso
# azzonamento/anno/mese. Riusa lo stesso fallback sull'azzonamento
# superiore di ZoningPeriodScope.
class WorkStatusBreakdown
```

> **IT:** Il primo breakdown a **numero di righe realmente dinamico e con denominatore `scope.count`** (non la somma dei conteggi mostrati, a differenza di `GenderBreakdown`/`NationalityBreakdown`): il numero e i nomi delle categorie dipendono interamente da quali valori di `tipologia_status` compaiono nei dati importati, in ordine alfabetico. `AgeBreakdown` riusa esattamente questa stessa convenzione sul denominatore.
>
> *EN: The first breakdown with a **genuinely dynamic row count and a `scope.count` denominator** (not the sum of the displayed counts, unlike `GenderBreakdown`/`NationalityBreakdown`): the number and names of the categories depend entirely on which `tipologia_status` values appear in the imported data, in alphabetical order. `AgeBreakdown` reuses this exact same denominator convention.*

### `Row` (Struct)

```ruby
Row = Struct.new(:tipologia_status, :count, :percentuale, keyword_init: true)
```

> **IT:** Forma "distribuzione a un solo anno" standard.
>
> *EN: The standard "single-year distribution" shape.*

### `call`

```ruby
def call
  counts.sort.map { |tipologia_status, count| build_row(tipologia_status, count) }
end
```

> **IT:** `counts.sort` su un hash Ruby ordina per array `[chiave, valore]`, quindi di fatto ordina alfabeticamente per `tipologia_status` (la chiave viene confrontata per prima); il valore numerico entrerebbe in gioco solo in caso di chiavi identiche, cosa impossibile qui perché le chiavi di un hash sono uniche. Il risultato è passato direttamente a `build_row` con entrambi `tipologia_status` e `count` già noti, evitando una seconda lookup nell'hash.
>
> *EN: `counts.sort` on a Ruby hash sorts by `[key, value]` array comparison, so it effectively sorts alphabetically by `tipologia_status` (the key is compared first); the numeric value would only matter for identical keys, which can't happen here since hash keys are unique. The result is passed straight into `build_row` with both `tipologia_status` and `count` already known, avoiding a second hash lookup.*

### `build_row` *(privato)*

```ruby
def build_row(tipologia_status, count)
  percentuale = totale.zero? ? nil : (count.to_f / totale * 100)

  Row.new(tipologia_status:, count:, percentuale:)
end
```

> **IT:** A differenza di `GenderBreakdown#build_row`, qui `count` arriva già calcolato da `call` (non serve un secondo `counts.fetch`), perché `call` già itera direttamente sulle coppie chiave/valore dell'hash `counts`.
>
> *EN: Unlike `GenderBreakdown#build_row`, here `count` already arrives computed from `call` (no need for a second `counts.fetch`), because `call` already iterates directly over the `counts` hash's key/value pairs.*

### `counts` *(privato)*

```ruby
def counts
  @counts ||= scope.where.not(tipologia_status: nil).group(:tipologia_status).count
end
```

> **IT:** Un'unica query SQL raggruppata (come in `CategoryBreakdown`), con `.where.not(tipologia_status: nil)` per escludere i record con lo status non valorizzato — questi record **non spariscono dal totale**, restano conteggiati in `totale` (vedi sotto), semplicemente non generano una riga propria.
>
> *EN: A single grouped SQL query (like in `CategoryBreakdown`), with `.where.not(tipologia_status: nil)` to exclude records with no status set — these records **don't disappear from the total**, they stay counted in `totale` (see below), they simply don't generate their own row.*

### `totale` *(privato)*

```ruby
def totale
  @totale ||= scope.count
end
```

> **IT:** Questo è il punto chiave della sezione: il denominatore delle percentuali è `scope.count` — **tutti** gli iscritti del periodo, inclusi quelli senza `tipologia_status` — non la somma dei conteggi mostrati in tabella. Per questo le percentuali delle righe visibili possono sommare a meno del 100%. Questo comportamento è stato confermato esplicitamente con l'utente proprio per questa sezione (vedi test "calcola la percentuale sul totale iscritti del periodo, non solo sui record con status valorizzato").
>
> *EN: This is the key point of this section: the percentage denominator is `scope.count` — **every** member of the period, including those with no `tipologia_status` — not the sum of the counts shown in the table. That's why the visible rows' percentages can add up to less than 100%. This behavior was explicitly confirmed with the user precisely for this section (see the test "calcola la percentuale sul totale iscritti del periodo, non solo sui record con status valorizzato").*

### `scope` *(privato)*

```ruby
def scope
  @scope ||= ZoningPeriodScope.call(zoning: @zoning, anno: @anno, mese: @mese)
end
```

> **IT:** Memoizzato, come in ogni altro breakdown, perché sia `counts` sia `totale` lo consultano.
>
> *EN: Memoized, as in every other breakdown, because both `counts` and `totale` read it.*
