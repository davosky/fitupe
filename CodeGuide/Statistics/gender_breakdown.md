# `Statistics::GenderBreakdown`

**File:** `app/services/statistics/gender_breakdown.rb`

## Codice completo

```ruby
module Statistics
  # Distribuzione degli iscritti per sesso (FEMMINE, MASCHI) nell'anno
  # corrente, senza confronto con l'anno precedente. Riusa lo stesso
  # fallback sull'azzonamento superiore di ZoningPeriodScope.
  class GenderBreakdown
    SESSI = {
      "FEMMINE" => "F",
      "MASCHI" => "M"
    }.freeze

    Row = Struct.new(:sesso, :count, :percentuale, keyword_init: true)

    def self.call(...) = new(...).call

    def initialize(zoning:, anno:, mese:)
      @zoning = zoning
      @anno = anno
      @mese = mese
    end

    def call
      totale = counts.values.sum
      SESSI.keys.map { |sesso| build_row(sesso, totale) }
    end

    private

    def build_row(sesso, totale)
      count = counts.fetch(sesso, 0)
      percentuale = totale.zero? ? nil : (count.to_f / totale * 100)

      Row.new(sesso:, count:, percentuale:)
    end

    def counts
      @counts ||= SESSI.each_with_object({}) do |(sesso, valore), memo|
        memo[sesso] = scope.where(sesso: valore).count
      end
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
# Distribuzione degli iscritti per sesso (FEMMINE, MASCHI) nell'anno
# corrente, senza confronto con l'anno precedente. Riusa lo stesso
# fallback sull'azzonamento superiore di ZoningPeriodScope.
class GenderBreakdown
```

> **IT:** Uno dei breakdown "a distribuzione sul solo anno corrente" (nessun `anno_precedente`), pensato per un grafico a torta con solo 2 categorie. È il più semplice della cartella insieme a `NationalityBreakdown`, con cui condivide struttura quasi identica.
>
> *EN: One of the "current-year-only distribution" breakdowns (no `anno_precedente`), designed for a pie chart with just 2 categories. It's the simplest one in this folder, alongside `NationalityBreakdown`, with which it shares an almost identical structure.*

### `SESSI` (costante)

```ruby
SESSI = {
  "FEMMINE" => "F",
  "MASCHI" => "M"
}.freeze
```

> **IT:** Mappa "etichetta mostrata" ("FEMMINE"/"MASCHI") → "valore memorizzato nella colonna `sesso`" ("F"/"M"). L'ordine delle chiavi determina l'ordine delle fette nella torta.
>
> *EN: A map from "displayed label" ("FEMMINE"/"MASCHI") to "value stored in the `sesso` column" ("F"/"M"). The key order determines the order of the pie slices.*

### `Row` (Struct)

```ruby
Row = Struct.new(:sesso, :count, :percentuale, keyword_init: true)
```

> **IT:** Forma "distribuzione a un solo anno": niente `count_precedente`/`diff`, ma un campo `percentuale` che i breakdown a confronto anno su anno non hanno (a parte l'eccezione ibrida `EmploymentStatusBreakdown`).
>
> *EN: The "single-year distribution" shape: no `count_precedente`/`diff`, but a `percentuale` field that the year-over-year breakdowns don't have (aside from the hybrid exception, `EmploymentStatusBreakdown`).*

### `call`

```ruby
def call
  totale = counts.values.sum
  SESSI.keys.map { |sesso| build_row(sesso, totale) }
end
```

> **IT:** Punto importante da notare: `totale` qui è la **somma dei due conteggi mostrati** (`counts.values.sum`, cioè femmine + maschi), **non** `scope.count` come invece accade in `WorkStatusBreakdown`, `ProvisionalRevocationBreakdown` o `AgeBreakdown`. La differenza è intenzionale: `sesso` è un campo dove si presume che ogni iscritto sia o "F" o "M" (nessun terzo valore rilevante), quindi qui le due percentuali sommano sempre esattamente al 100%. Nei breakdown dove il campo può avere valori nulli o altre categorie non mostrate (es. `tipologia_status`), invece, si usa `scope.count` come denominatore — vedi la nota "Decisioni non ovvie dal codice" in `CodeGuide/Statistics/README.md`.
>
> *EN: An important thing to note: `totale` here is the **sum of the two displayed counts** (`counts.values.sum`, i.e. females + males), **not** `scope.count` as in `WorkStatusBreakdown`, `ProvisionalRevocationBreakdown`, or `AgeBreakdown`. The difference is intentional: `sesso` is a field where every member is assumed to be either "F" or "M" (no relevant third value), so the two percentages always sum exactly to 100%. In breakdowns where the field can be null or hold other, unshown categories (e.g. `tipologia_status`), `scope.count` is used as the denominator instead — see the "Decisions not obvious from the code" note in `CodeGuide/Statistics/README.md`.*

### `build_row` *(privato)*

```ruby
def build_row(sesso, totale)
  count = counts.fetch(sesso, 0)
  percentuale = totale.zero? ? nil : (count.to_f / totale * 100)

  Row.new(sesso:, count:, percentuale:)
end
```

> **IT:** `totale` viene passato come parametro da `call` (calcolato una sola volta), non ricalcolato qui — piccola ottimizzazione rispetto ad altri breakdown dove il totale è un metodo memoizzato a parte (es. `AgeBreakdown#totale`).
>
> *EN: `totale` is passed in as a parameter from `call` (computed just once), not recalculated here — a small optimization compared to other breakdowns where the total is a separately memoized method (e.g. `AgeBreakdown#totale`).*

### `counts` *(privato)*

```ruby
def counts
  @counts ||= SESSI.each_with_object({}) do |(sesso, valore), memo|
    memo[sesso] = scope.where(sesso: valore).count
  end
end
```

> **IT:** A differenza di `AgeBreakdown` o `CategoryBreakdown` (che usano un unico `GROUP BY`), qui viene eseguita **una query separata per ciascun sesso** (`scope.where(sesso: valore).count`), perché con solo due valori possibili il costo di due piccole query è trascurabile e il codice risulta più diretto.
>
> *EN: Unlike `AgeBreakdown` or `CategoryBreakdown` (which use a single `GROUP BY`), here **a separate query runs for each gender** (`scope.where(sesso: valore).count`), because with only two possible values the cost of two small queries is negligible and the code ends up more straightforward.*

### `scope` *(privato)*

```ruby
def scope
  @scope ||= ZoningPeriodScope.call(zoning: @zoning, anno: @anno, mese: @mese)
end
```

> **IT:** Memoizzato perché sia `counts` sia (indirettamente) `call` lo leggono più volte nello stesso ciclo di vita dell'oggetto.
>
> *EN: Memoized because both `counts` and (indirectly) `call` read it multiple times within the object's lifecycle.*
