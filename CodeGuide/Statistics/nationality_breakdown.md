# `Statistics::NationalityBreakdown`

**File:** `app/services/statistics/nationality_breakdown.rb`

## Codice completo

```ruby
module Statistics
  # Distribuzione degli iscritti per nazionalità (ITALIANA, UE, EXTRAUE)
  # nell'anno corrente, senza confronto con l'anno precedente. Riusa lo
  # stesso fallback sull'azzonamento superiore di ZoningPeriodScope.
  class NationalityBreakdown
    NAZIONALITA = {
      "ITALIANA" => "ITALIA",
      "UE" => "UE",
      "EXTRAUE" => "EXTRAUE"
    }.freeze

    Row = Struct.new(:nazionalita, :count, :percentuale, keyword_init: true)

    def self.call(...) = new(...).call

    def initialize(zoning:, anno:, mese:)
      @zoning = zoning
      @anno = anno
      @mese = mese
    end

    def call
      totale = counts.values.sum
      NAZIONALITA.keys.map { |nazionalita| build_row(nazionalita, totale) }
    end

    private

    def build_row(nazionalita, totale)
      count = counts.fetch(nazionalita, 0)
      percentuale = totale.zero? ? nil : (count.to_f / totale * 100)

      Row.new(nazionalita:, count:, percentuale:)
    end

    def counts
      @counts ||= NAZIONALITA.each_with_object({}) do |(nazionalita, valore), memo|
        memo[nazionalita] = scope.where(nazionalita: valore).count
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
# Distribuzione degli iscritti per nazionalità (ITALIANA, UE, EXTRAUE)
# nell'anno corrente, senza confronto con l'anno precedente. Riusa lo
# stesso fallback sull'azzonamento superiore di ZoningPeriodScope.
class NationalityBreakdown
```

> **IT:** Gemello strutturale di `GenderBreakdown`, con tre categorie invece di due (pensato per una torta a 3 fette invece che a 2). Vale la stessa nota su `totale`: qui è la somma dei tre conteggi, non `scope.count`.
>
> *EN: A structural twin of `GenderBreakdown`, with three categories instead of two (built for a 3-slice pie instead of a 2-slice one). The same note on `totale` applies: here it's the sum of the three counts, not `scope.count`.*

### `NAZIONALITA` (costante)

```ruby
NAZIONALITA = {
  "ITALIANA" => "ITALIA",
  "UE" => "UE",
  "EXTRAUE" => "EXTRAUE"
}.freeze
```

> **IT:** Mappa "etichetta mostrata" → "valore memorizzato nella colonna `nazionalita`". Da notare che l'etichetta "ITALIANA" non coincide col valore grezzo "ITALIA" — le altre due chiave/valore invece coincidono. L'ordine determina l'ordine delle fette nella torta.
>
> *EN: A map from "displayed label" to "value stored in the `nazionalita` column". Note that the "ITALIANA" label doesn't match the raw value "ITALIA" — the other two key/value pairs do match. The order determines the pie slice order.*

### `Row` (Struct)

```ruby
Row = Struct.new(:nazionalita, :count, :percentuale, keyword_init: true)
```

> **IT:** Forma "distribuzione a un solo anno", identica nella struttura a `GenderBreakdown::Row` — solo il nome del primo campo cambia (`nazionalita` invece di `sesso`).
>
> *EN: The "single-year distribution" shape, structurally identical to `GenderBreakdown::Row` — only the first field's name differs (`nazionalita` instead of `sesso`).*

### `call`, `build_row`, `counts`, `scope` *(privati)*

```ruby
def call
  totale = counts.values.sum
  NAZIONALITA.keys.map { |nazionalita| build_row(nazionalita, totale) }
end

private

def build_row(nazionalita, totale)
  count = counts.fetch(nazionalita, 0)
  percentuale = totale.zero? ? nil : (count.to_f / totale * 100)

  Row.new(nazionalita:, count:, percentuale:)
end

def counts
  @counts ||= NAZIONALITA.each_with_object({}) do |(nazionalita, valore), memo|
    memo[nazionalita] = scope.where(nazionalita: valore).count
  end
end

def scope
  @scope ||= ZoningPeriodScope.call(zoning: @zoning, anno: @anno, mese: @mese)
end
```

> **IT:** Questi quattro metodi sono, riga per riga, la stessa identica logica di `GenderBreakdown` (una query `.count` per categoria invece di un unico `GROUP BY`, `totale` come somma dei conteggi mostrati, memoizzazione di `scope`) — solo i nomi dei campi e la costante `NAZIONALITA` al posto di `SESSI` cambiano. Non è stata estratta un'astrazione comune per questi due servizi: è un'altra delle scelte di ripetizione deliberata già viste in `categoria_column`.
>
> *EN: These four methods are, line for line, the exact same logic as `GenderBreakdown` (one `.count` query per category instead of a single `GROUP BY`, `totale` as the sum of the displayed counts, memoized `scope`) — only the field names and the `NAZIONALITA` constant in place of `SESSI` change. No shared abstraction was extracted for these two services: it's another instance of the deliberate-repetition choice already seen with `categoria_column`.*
